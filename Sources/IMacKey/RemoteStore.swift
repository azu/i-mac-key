import AppKit
import ApplicationServices
import Combine
import CoreGraphics
import Foundation

enum Gesture: String, Codable { case tap, hold }

enum KeyAction: String, CaseIterable, Codable, Identifiable {
    case none, left, right, up, down, space, escape, enter, tab
    case commandLeft, commandRight

    var id: String { rawValue }
    var title: String {
        switch self {
        case .none: "なし"
        case .left: "←"
        case .right: "→"
        case .up: "↑"
        case .down: "↓"
        case .space: "Space"
        case .escape: "Esc"
        case .enter: "Enter"
        case .tab: "Tab"
        case .commandLeft: "⌘←"
        case .commandRight: "⌘→"
        }
    }

    var keyCode: CGKeyCode? {
        switch self {
        case .none: nil
        case .left, .commandLeft: 123
        case .right, .commandRight: 124
        case .down: 125
        case .up: 126
        case .space: 49
        case .escape: 53
        case .enter: 36
        case .tab: 48
        }
    }

    var usesCommand: Bool { self == .commandLeft || self == .commandRight }
}

struct CellAssignment: Codable, Identifiable {
    var id: Int
    var tap: KeyAction
    var hold: KeyAction
}

@MainActor
final class RemoteStore: ObservableObject {
    @Published var cells: [CellAssignment] {
        didSet { save(); updateServerConfiguration() }
    }
    @Published private(set) var server: RemoteServer?
    @Published private(set) var localURL: URL?
    @Published private(set) var status = "起動準備中"

    private let defaultsKey = "cellAssignments.v1"
    private let token = UUID().uuidString.replacingOccurrences(of: "-", with: "")

    init() {
        if let data = UserDefaults.standard.data(forKey: defaultsKey),
           let decoded = try? JSONDecoder().decode([CellAssignment].self, from: data), decoded.count == 9 {
            cells = decoded
        } else {
            cells = (0..<9).map { CellAssignment(id: $0, tap: $0 == 3 ? .left : ($0 == 5 ? .right : .none), hold: .none) }
        }
        startServer()
    }

    func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    var isAccessibilityTrusted: Bool { AXIsProcessTrusted() }

    func action(for cell: Int, gesture: Gesture) -> KeyAction? {
        guard let assignment = cells.first(where: { $0.id == cell }) else { return nil }
        return gesture == .tap ? assignment.tap : assignment.hold
    }

    func trigger(cell: Int, gesture: Gesture) {
        guard let action = action(for: cell, gesture: gesture), let keyCode = action.keyCode else { return }
        guard AXIsProcessTrusted() else {
            status = "キーを送るにはアクセシビリティを許可してください"
            return
        }
        let source = CGEventSource(stateID: .hidSystemState)
        let down = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true)
        let up = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false)
        if action.usesCommand {
            down?.flags = .maskCommand
            up?.flags = .maskCommand
        }
        down?.post(tap: .cghidEventTap)
        up?.post(tap: .cghidEventTap)
        status = "セル \(cell + 1): \(gesture == .tap ? "タップ" : "長押し") → \(action.title)"
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(cells) else { return }
        UserDefaults.standard.set(data, forKey: defaultsKey)
    }

    private func startServer() {
        let server = RemoteServer(token: token) { [weak self] cell, gesture in
            DispatchQueue.main.async { self?.trigger(cell: cell, gesture: gesture) }
        }
        self.server = server
        server.start { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let port):
                    guard let host = LocalNetworkAddress.primaryIPv4() else {
                        self?.status = "Wi-FiまたはEthernetに接続してください"
                        return
                    }
                    self?.localURL = URL(string: "http://\(host):\(port)/?token=\(self?.token ?? "")")
                    self?.status = "iPhoneでQRコードを読み取ってください"
                    self?.updateServerConfiguration()
                case .failure(let error): self?.status = "サーバーを起動できません: \(error.localizedDescription)"
                }
            }
        }
    }

    private func updateServerConfiguration() {
        let labels = cells.map { ["tap": $0.tap.title, "hold": $0.hold.title] }
        server?.configurationJSON = (try? JSONSerialization.data(withJSONObject: ["cells": labels])) ?? Data("{}".utf8)
    }
}
