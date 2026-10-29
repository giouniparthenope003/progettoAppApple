import SwiftUI

/// Elenco delle 4 sfide di un percorso: si sbloccano una dopo l'altra
struct PercorsoView: View {
    let percorso: Percorso
    @EnvironmentObject private var progresso: Progresso

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Text(percorso.emoji).font(.system(size: 90))
                Text("Scegli la sfida!")
                    .font(Tema.titolo(34))

                ForEach(Sfida.allCases) { sfida in
                    let sbloccata = progresso.sbloccata(percorso, sfida)
                    NavigationLink {
                        LevelView(percorso: percorso, sfida: sfida)
                    } label: {
                        SfidaCard(
                            sfida: sfida,
                            colore: percorso.colore,
                            sbloccata: sbloccata,
                            stelle: progresso.stelleOttenute(percorso, sfida)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(!sbloccata)
                }
            }
            .padding()
        }
        .background(Tema.sfondo(percorso.colore).ignoresSafeArea())
        .navigationTitle(percorso.titolo)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SfidaCard: View {
    let sfida: Sfida
    let colore: Color
    let sbloccata: Bool
    let stelle: Int

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().fill(colore.opacity(0.2)).frame(width: 76, height: 76)
                Text(sbloccata ? sfida.emoji : "🔒").font(.system(size: 40))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("\(sfida.rawValue + 1). \(sfida.titolo)")
                    .font(Tema.titolo(26))
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                Text(sfida.descrizione)
                    .font(Tema.titolo(19, .semibold))
                    .foregroundStyle(.secondary)
                    .minimumScaleFactor(0.7)
                    .lineLimit(2)
            }

            Spacer(minLength: 4)

            if sbloccata {
                HStack(spacing: 2) {
                    ForEach(0..<3) { i in
                        Image(systemName: i < stelle ? "star.fill" : "star")
                            .font(.system(size: 20))
                            .foregroundStyle(.yellow)
                    }
                }
            }
        }
        .padding(18)
        .background(.white, in: RoundedRectangle(cornerRadius: 30))
        .shadow(color: colore.opacity(0.3), radius: 8, y: 5)
        .opacity(sbloccata ? 1 : 0.55)
    }
}
