import SwiftUI

@main
struct AstroBondWestVillageApp: App {
    @State private var session = SessionStore()

    init() {
        SimplifiedAstronomyCalculator.configureEphemerisIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(session)
        }
    }
}
