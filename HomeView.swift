import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var progresso: Progresso
    @ObservedObject private var gestore = GestoreParole.shared
    var cambiaUtente: () -> Void = {}

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    // Torna alla scelta tra genitore e logopedista
                    HStack {
                        Button(action: cambiaUtente) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(.primary)
                                .frame(width: 44, height: 44)
                                .background(.white.opacity(0.8), in: Circle())
                                .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                        }
                        .accessibilityLabel("Indietro")
                        Spacer()
                    }

                    HStack(spacing: 12) {
                        PippoView(altezza: 110)
                        Text("Ciao! Sono Pippo.\nAiutami a tornare a casa!")
                            .font(Tema.titolo(28))
                            .minimumScaleFactor(0.7)
                    }
                    .padding(.top, 8)

                    ForEach(Percorso.tutti) { percorso in
                        NavigationLink {
                            PercorsoView(percorso: gestore.perIlGioco(percorso))
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

