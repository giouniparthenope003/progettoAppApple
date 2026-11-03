import SwiftUI

@main
struct PippoApp: App {
    @StateObject private var progresso = Progresso()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(progresso)
                .preferredColorScheme(.light)
        }
    }
}

/// All'avvio chiede chi sta usando l'app, poi apre la parte giusta.
/// Un'unica navigazione: si torna indietro con il pulsante o con lo swipe da sinistra.
struct RootView: View {
    @State private var schermate: [Utente] = []

    var body: some View {
        NavigationStack(path: $schermate) {
            SceltaUtenteView { scelto in schermate = [scelto] }
                .navigationTitle("Inizio")
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(for: Utente.self) { utente in
                    switch utente {
                    case .genitore:    HomeView()
                    case .logopedista: LogopedistaView()
                    }
                }
        }
    }
}
