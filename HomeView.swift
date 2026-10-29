import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var progresso: Progresso
    var cambiaUtente: () -> Void = {}

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    // Torna alla scelta tra genitore e logopedista
                    HStack {
                        Spacer()
                        Button(action: cambiaUtente) {
                            Label("Cambia utente", systemImage: "person.2.circle.fill")
                                .font(Tema.titolo(16, .semibold))
                                .foregroundStyle(.secondary)
                        }
                    }

                    HStack(spacing: 12) {
                        Text("🦜").font(.system(size: 90))
                        Text("Ciao! Sono Pippo.\nAiutami a tornare a casa!")
                            .font(Tema.titolo(28))
                            .minimumScaleFactor(0.7)
                    }
                    .padding(.top, 8)

                    ForEach(Percorso.tutti) { percorso in
                        NavigationLink {
                            PercorsoView(percorso: percorso)
                        } label: {
                            PercorsoCard(
                                percorso: percorso,
                                stelle: progresso.totaleStelle(percorso)
                            )
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
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

struct PercorsoCard: View {
    let percorso: Percorso
    let stelle: Int

    var body: some View {
        HStack(spacing: 16) {
            Text(percorso.emoji).font(.system(size: 70))
            VStack(alignment: .leading, spacing: 6) {
                Text(percorso.titolo)
                    .font(Tema.titolo(30))
                    .minimumScaleFactor(0.7)
                Text(percorso.coppia)
                    .font(Tema.titolo(24, .bold))
                    .foregroundStyle(percorso.colore)
                Label("\(stelle)/\(Sfida.allCases.count * 3)", systemImage: "star.fill")
                    .font(Tema.titolo(22, .bold))
                    .foregroundStyle(.orange)
            }
            Spacer()
            Image(systemName: "chevron.right.circle.fill")
                .font(.system(size: 38))
                .foregroundStyle(percorso.colore)
        }
        .padding(20)
        .background(.white, in: RoundedRectangle(cornerRadius: 32))
        .shadow(color: percorso.colore.opacity(0.35), radius: 10, y: 6)
    }
}
