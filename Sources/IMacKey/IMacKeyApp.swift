import SwiftUI

@main
struct IMacKeyApp: App {
    @StateObject private var remote = RemoteStore()

    var body: some Scene {
        WindowGroup("i-mac-key") {
            ContentView()
                .environmentObject(remote)
                .frame(minWidth: 720, minHeight: 620)
        }
    }
}
