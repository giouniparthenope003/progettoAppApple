import SwiftUI

/// Chi sta usando l'app in questo momento
enum Utente: String, CaseIterable, Identifiable {
    case genitore
    case logopedista

    var id: String { rawValue }

    var titolo: String {
        switch self {
        case .genitore:    "Genitore"
        case .logopedista: "Logopedista"
        }
    }

    var descrizione: String {
        switch self {
        case .genitore:    "Gioca insieme al bambino"
        case .logopedista: "Guarda i progressi del bambino"
        }
    }

    var emoji: String {
        switch self {
        case .genitore:    "👨‍👩‍👧"
        case .logopedista: "🩺"
        }
    }

    var colore: Color {
        switch self {
        case .genitore:    .orange
        case .logopedista: .purple
        }
    }
}

/// Schermata iniziale: chi sta usando Pippo?
struct SceltaUtenteView: View {
    let scegli: (Utente) -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                PippoView(altezza: 150)
                    .padding(.top, 30)

                Text("Chi sta usando Pippo?")
                    .font(Tema.titolo(32))
                    .multilineTextAlignment(.center)

                ForEach(Utente.allCases) { utente in
                    Button {
                        scegli(utente)
                    } label: {
                        UtenteCard(utente: utente)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .background(
            LinearGradient(colors: [Color.cyan.opacity(0.4), Color.yellow.opacity(0.15), .white],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        )
    }
}

struct UtenteCard: View {
    let utente: Utente

    var body: some View {
        HStack(spacing: 16) {
            Text(utente.emoji).font(.system(size: 60))
            VStack(alignment: .leading, spacing: 6) {
                Text(utente.titolo)
                    .font(Tema.titolo(30))
                    .minimumScaleFactor(0.7)
                Text(utente.descrizione)
                    .font(Tema.titolo(19, .semibold))
                    .foregroundStyle(.secondary)
                    .minimumScaleFactor(0.7)
            }
            Spacer()
            Image(systemName: "chevron.right.circle.fill")
                .font(.system(size: 38))
                .foregroundStyle(utente.colore)
        }
        .padding(20)
        .background(.white, in: RoundedRectangle(cornerRadius: 32))
        .shadow(color: utente.colore.opacity(0.35), radius: 10, y: 6)
    }
}

#Preview {
    SceltaUtenteView { _ in }
}
