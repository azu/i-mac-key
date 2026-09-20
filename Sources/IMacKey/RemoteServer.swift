import Foundation
import Network

final class RemoteServer: @unchecked Sendable {
    private let token: String
    private let onTrigger: (Int, Gesture) -> Void
    private var listener: NWListener?
    var configurationJSON = Data("{\"cells\":[]}".utf8)

    init(token: String, onTrigger: @escaping (Int, Gesture) -> Void) {
        self.token = token
        self.onTrigger = onTrigger
    }

    func start(completion: @escaping (Result<UInt16, Error>) -> Void) {
        do {
            let listener = try NWListener(using: .tcp, on: .any)
            listener.newConnectionHandler = { [weak self] in self?.receive($0) }
            listener.stateUpdateHandler = { state in
                switch state {
                case .ready: completion(.success(listener.port?.rawValue ?? 0))
                case .failed(let error): completion(.failure(error))
                default: break
                }
            }
            self.listener = listener
            listener.start(queue: .global(qos: .userInitiated))
        } catch { completion(.failure(error)) }
    }

    private func receive(_ connection: NWConnection) {
        connection.start(queue: .global(qos: .userInitiated))
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65_536) { [weak self] data, _, _, _ in
            guard let self, let data, let request = String(data: data, encoding: .utf8) else { connection.cancel(); return }
            self.respond(to: request, connection: connection)
        }
    }

    private func respond(to request: String, connection: NWConnection) {
        let firstLine = request.split(separator: "\n", maxSplits: 1).first.map(String.init) ?? ""
        let parts = firstLine.split(separator: " ")
        let path = parts.count > 1 ? String(parts[1]) : "/"
        let components = URLComponents(string: "http://remote\(path)")
        let query = Dictionary(uniqueKeysWithValues: (components?.queryItems ?? []).map { ($0.name, $0.value ?? "") })
        let valid = query["token"] == token
        var type = "text/plain; charset=utf-8"
        var body = Data("Forbidden".utf8)
        if valid, components?.path == "/" { type = "text/html; charset=utf-8"; body = Data(RemotePage.html.utf8) }
        if valid, components?.path == "/config" { type = "application/json"; body = configurationJSON }
        if valid, components?.path == "/trigger", let cell = Int(query["cell"] ?? ""), (0..<9).contains(cell), let gesture = Gesture(rawValue: query["gesture"] ?? "") {
            onTrigger(cell, gesture); body = Data("OK".utf8)
        }
        let header = "HTTP/1.1 \(valid ? "200 OK" : "403 Forbidden")\r\nContent-Type: \(type)\r\nContent-Length: \(body.count)\r\nCache-Control: no-store\r\nConnection: close\r\n\r\n"
        connection.send(content: Data(header.utf8) + body, completion: .contentProcessed { _ in connection.cancel() })
    }
}

enum LocalNetworkAddress {
    static func primaryIPv4() -> String? {
        var interfaces: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&interfaces) == 0, let first = interfaces else { return nil }
        defer { freeifaddrs(interfaces) }
        for pointer in sequence(first: first, next: { $0.pointee.ifa_next }) {
            let interface = pointer.pointee
            guard interface.ifa_addr.pointee.sa_family == UInt8(AF_INET),
                  let name = String(validatingUTF8: interface.ifa_name), name != "lo0" else { continue }
            var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            guard getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len), &host, socklen_t(host.count), nil, 0, NI_NUMERICHOST) == 0 else { continue }
            let address = String(cString: host)
            if !address.hasPrefix("127.") { return address }
        }
        return nil
    }
}
