import CoreImage.CIFilterBuiltins
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var remote: RemoteStore
    @State private var accessibilityTrusted = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("i-mac-key").font(.largeTitle.bold())
                    Text("iPhoneのブラウザでQRコードを開くと、9マスのリモコンになります。")
                    Text(remote.status).foregroundStyle(.secondary)
                    if let url = remote.localURL { Text(url.absoluteString).font(.caption).textSelection(.enabled) }
                }
                Spacer()
                if let url = remote.localURL { QRCode(url: url.absoluteString).frame(width: 170, height: 170) }
            }
            Divider()
            HStack {
                Text("アクセシビリティ: \(remote.isAccessibilityTrusted ? "許可済み" : "未許可")")
                Button("キー入力を許可") { remote.requestAccessibilityPermission() }
                Spacer()
                Text("タップと長押しを個別に設定できます").foregroundStyle(.secondary)
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                ForEach($remote.cells) { $cell in
                    GroupBox("セル \(cell.id + 1)") {
                        VStack(alignment: .leading) {
                            Picker("タップ", selection: $cell.tap) { ForEach(KeyAction.allCases) { Text($0.title).tag($0) } }
                            Picker("長押し", selection: $cell.hold) { ForEach(KeyAction.allCases) { Text($0.title).tag($0) } }
                        }.pickerStyle(.menu)
                    }
                }
            }
        }
        .padding(24)
        .onAppear { accessibilityTrusted = remote.isAccessibilityTrusted }
    }
}

private struct QRCode: View {
    let url: String
    private let context = CIContext()
    private let filter = CIFilter.qrCodeGenerator()
    var body: some View {
        if let image = makeImage() { Image(nsImage: image).interpolation(.none).resizable().scaledToFit().padding(6).background(.white).clipShape(RoundedRectangle(cornerRadius: 12)) }
    }
    private func makeImage() -> NSImage? {
        filter.message = Data(url.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage?.transformed(by: .init(scaleX: 10, y: 10)), let cg = context.createCGImage(output, from: output.extent) else { return nil }
        return NSImage(cgImage: cg, size: output.extent.size)
    }
}
