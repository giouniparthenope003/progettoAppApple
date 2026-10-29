import SwiftUI

/// Area riservata al logopedista: riepilogo dei progressi del bambino
struct LogopedistaView: View {
    @EnvironmentObject private var progresso: Progresso
    @ObservedObject private var gestore = GestoreParole.shared
    var cambiaUtente: () -> Void = {}
    @State private var confermaAzzera = false

    var body: some View {
        NavigationStack {
            List {
                if progresso.sessioni.isEmpty {
                    Section {
                        ContentUnavailableView(
                            "Ancora nessuna sessione",
                            systemImage: "chart.bar.xaxis",
                            description: Text("I risultati compariranno qui quando il bambino avrà completato la prima sfida.")
                        )
                    }
                } else {
                    Section("Riepilogo") {
                        LabeledContent("Sfide completate", value: "\(progresso.sessioni.count)")
                        LabeledContent("Confusioni con la parola gemella",
                                       value: "\(progresso.sessioni.reduce(0) { $0 + $1.confusioni })")
                        LabeledContent("Altri errori",
                                       value: "\(progresso.sessioni.reduce(0) { $0 + $1.altriErrori })")
                        if let ultima = progresso.sessioni.map(\.data).max() {
                            LabeledContent("Ultima attività",
                                           value: ultima.formatted(date: .abbreviated, time: .shortened))
                        }
                    }
                }

                ForEach(Percorso.tutti) { percorso in
                    Section {
                        NavigationLink {
                            GestioneParoleView(percorso: percorso)
                        } label: {
                            Label("Gestisci parole (\(gestore.paroleAttive(percorso).count) attive)",
                                  systemImage: "text.badge.plus")
                                .foregroundStyle(percorso.colore)
                        }

                        ForEach(Sfida.allCases) { sfida in
                            SfidaRiepilogoRow(percorso: percorso, sfida: sfida)
                        }

                        let confuse = progresso.paroleConfuse(percorso)
                        if !confuse.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Parole confuse più spesso")
                                    .font(.subheadline.weight(.semibold))
                                ForEach(confuse.prefix(5), id: \.parola) { voce in
                                    HStack {
                                        Text("\(voce.parola) → \(gestore.gemella(di: voce.parola, in: percorso))")
                                        Spacer()
                                        Text("×\(voce.volte)")
                                            .foregroundStyle(.secondary)
                                    }
                                    .font(.subheadline)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    } header: {
                        Text("\(percorso.emoji) \(percorso.titolo) · \(percorso.coppia)")
                    }
                }


if !progresso.sessioni.isEmpty {
                    Section {
                        NavigationLink("Storico delle sessioni (\(progresso.sessioni.count))") {
                            StoricoSessioniView()
                        }
                    }
                }
            }
            .navigationTitle("Area logopedista")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Indietro", systemImage: "chevron.left", action: cambiaUtente)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Azzera progressi", systemImage: "trash", role: .destructive) {
                            confermaAzzera = true
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .confirmationDialog("Azzerare tutti i progressi?",
                                isPresented: $confermaAzzera,
                                titleVisibility: .visible) {
                Button("Azzera", role: .destructive) { progresso.azzera() }
            } message: {
                Text("Stelle e storico delle sessioni verranno cancellati definitivamente.")
            }
        }
    }
}

/// Una riga per ogni sfida di un percorso
struct SfidaRiepilogoRow: View {
    @EnvironmentObject private var progresso: Progresso
    let percorso: Percorso
    let sfida: Sfida

    var body: some View {
        let sessioni = progresso.sessioniDi(percorso, sfida)
        let stelle = progresso.stelleOttenute(percorso, sfida)

        HStack(spacing: 12) {
            Text(progresso.sbloccata(percorso, sfida) ? sfida.emoji : "🔒")
                .font(.title2)

            VStack(alignment: .leading, spacing: 2) {
                Text(sfida.titolo)
                    .font(.body.weight(.medium))
                if sessioni.isEmpty {
                    Text("Non ancora giocata")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    let confusioni = sessioni.reduce(0) { $0 + $1.confusioni }
                    let errori = sessioni.reduce(0) { $0 + $1.altriErrori }
                    Text("\(sessioni.count) \(sessioni.count == 1 ? "partita" : "partite") · \(confusioni) confusioni · \(errori) altri errori")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            HStack(spacing: 1) {
                ForEach(0..<3) { i in
                    Image(systemName: i < stelle ? "star.fill" : "star")
                        .font(.caption)
                        .foregroundStyle(.yellow)
                }
            }
        }
    }
}

/// Elenco di tutte le sfide completate, dalla più recente
struct StoricoSessioniView: View {
    @EnvironmentObject private var progresso: Progresso

    var body: some View {
        List(progresso.sessioni.sorted { $0.data > $1.data }) { sessione in
            let percorso = Percorso.tutti.first { $0.id == sessione.percorsoId }
            let sfida = Sfida(rawValue: sessione.sfida)


VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("\(percorso?.emoji ?? "❓") \(percorso?.titolo ?? sessione.percorsoId)")
                        .font(.body.weight(.medium))
                    Spacer()
                    Text(String(repeating: "⭐️", count: sessione.stelle))
                        .font(.caption)
                }
                Text(sfida?.titolo ?? "Sfida \(sessione.sfida + 1)")
                    .font(.subheadline)
                Text("\(sessione.confusioni) confusioni · \(sessione.altriErrori) altri errori")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if !sessione.paroleConfuse.isEmpty {
                    Text("Confuse: \(sessione.paroleConfuse.joined(separator: ", "))")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
                Text(sessione.data.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 2)
        }
        .navigationTitle("Storico")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    LogopedistaView()
        .environmentObject(Progresso())
}
