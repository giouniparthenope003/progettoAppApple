import SwiftUI

@main
struct PippoApp: App {
    @StateObject private var progresso = Progresso()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(progresso)
                .preferredColorScheme(.light)   // colori sempre vivaci, anche con il tema scuro
        }
    }
}
