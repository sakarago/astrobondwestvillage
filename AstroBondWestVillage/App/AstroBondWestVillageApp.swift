import SwiftUI

@main
struct AstroBondWestVillageApp: App {
    @State private var session = SessionStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(session)
        }
    }
}
