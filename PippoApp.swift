import SwiftUI

@main
struct PippoApp: App {
    @StateObject private var progresso = Progresso()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(progresso)
                .preferredColorScheme(.light)   // colori sempre vivaci, anche con il tema scuro
        }
    }
}

/// All'avvio chiede chi sta usando l'app, poi mostra la parte giusta
struct RootView: View {
    @State private var utente: Utente?

    var body: some View {
        ZStack {
            if let utente {
                switch utente {
                case .genitore:
                    HomeView(cambiaUtente: esci)
                case .logopedista:
                    LogopedistaView(cambiaUtente: esci)
                }
            } else {
                SceltaUtenteView { scelto in
                    withAnimation { utente = scelto }
                }
            }
        }
    }

    private func esci() {
        withAnimation { utente = nil }
    }
}
