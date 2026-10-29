import SwiftUI

/// Il logopedista sceglie quali parole usare in un percorso e ne aggiunge di nuove
struct GestioneParoleView: View {
    let percorso: Percorso
    @ObservedObject private var gestore = GestoreParole.shared
    @EnvironmentObject private var progresso: Progresso
    @State private var mostraNuova = false

    var body: some View {
        let confusioni = Dictionary(uniqueKeysWithValues:
            progresso.paroleConfuse(percorso).map { ($0.parola, $0.volte) })
        let attive = gestore.tutteLeParole(percorso).filter { gestore.attiva(percorso, $0.testo) }.count
        let aggiunte = gestore.personalizzate(di: percorso)

        List {
            Section {
                Label {
                    Text("\(attive) parole attive. In ogni partita Pippo ne sceglie fino a 6 a caso: spegni quelle già consolidate per concentrare l'allenamento sulle coppie più difficili.")
                        .font(.subheadline)
                } icon: {
                    Image(systemName: "info.circle")
                        .foregroundStyle(percorso.colore)
                }
            }

            Section {
                if aggiunte.isEmpty {
                    Text("Nessuna parola aggiunta. Tocca + per aggiungerne una.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(aggiunte) { p in
                        RigaParola(percorso: percorso, parola: p.parola, confusioni: confusioni[p.testo] ?? 0)
                    }
                    .onDelete { indici in
                        indici.map { aggiunte[$0] }.forEach(gestore.elimina)
                    }
                }
            } header: {
                Text("Parole aggiunte")
            } footer: {
                if !aggiunte.isEmpty {
                    Text("Scorri verso sinistra su una parola per eliminarla.")
                }
            }

            Section("Parole di base") {
                ForEach(percorso.parole) { p in
                    RigaParola(percorso: percorso, parola: p, confusioni: confusioni[p.testo] ?? 0)
                }
            }
        }
        .navigationTitle("\(percorso.emoji) \(percorso.coppia)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Aggiungi parola", systemImage: "plus") { mostraNuova = true }
            }
        }
        .sheet(isPresented: $mostraNuova) {
            NuovaParolaView(percorso: percorso)
        }
    }
}

/// Una parola con il suo interruttore e le volte in cui è stata confusa
struct RigaParola: View {
    let percorso: Percorso
    let parola: Parola
    let confusioni: Int
    @ObservedObject private var gestore = GestoreParole.shared

    var body: some View {
        let attiva = Binding(
            get: { gestore.attiva(percorso, parola.testo) },
            set: { gestore.imposta(attiva: $0, percorso, parola.testo) }
        )

        Toggle(isOn: attiva) {
            HStack(spacing: 12) {
                Text(parola.emoji).font(.title)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(parola.testo) ↔ \(parola.gemella)")
                        .font(.body.weight(.medium))
                    Text(parola.frase)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if confusioni > 0 {
                        Text("Confusa con la gemella \(confusioni) \(confusioni == 1 ? "volta" : "volte")")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.orange)
                    }
                }
            }
        }
        .tint(percorso.colore)
    }
}

/// Modulo per aggiungere una nuova coppia minima a un percorso
struct NuovaParolaView: View {
    let percorso: Percorso
    @ObservedObject private var gestore = GestoreParole.shared
    @Environment(\.dismiss) private var dismiss

    @State private var testo = ""
    @State private var gemella = ""
    @State private var emoji = ""
    @State private var frase = ""

    private var testoPulito: String { testo.trimmingCharacters(in: .whitespaces).lowercased() }
    private var gemellaPulita: String { gemella.trimmingCharacters(in: .whitespaces).lowercased() }
    private var frasePulita: String { frase.trimmingCharacters(in: .whitespaces) }

    /// Il primo problema da risolvere prima di salvare (nil = tutto ok)
    private var problema: String? {
        if testoPulito.isEmpty || gemellaPulita.isEmpty {
            return "Inserisci la parola e la sua gemella."
        }
        if testoPulito.contains(" ") || gemellaPulita.contains(" ") {
            return "Parola e gemella devono essere una sola parola."
        }
        if testoPulito.normalizzata == gemellaPulita.normalizzata {
            return "La gemella deve essere diversa dalla parola."
        }
        if gestore.esiste(testoPulito, in: percorso) {
            return "\"\(testoPulito)\" è già presente in questo percorso."
        }
        if !frasePulita.isEmpty,
           !frasePulita.paroleNormalizzate.contains(testoPulito.normalizzata) {
            return "La frase deve contenere la parola \"\(testoPulito)\"."
        }
        return nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Parola da dire (es. palla)", text: $testo)
                    TextField("Parola gemella (es. balla)", text: $gemella)
                } header: {
                    Text("Coppia minima")
                } footer: {
                    Text("Percorso \(percorso.coppia): la parola gemella cambia solo il suono su cui il bambino lavora.")
                }

                Section {
                    TextField("Emoji (es. ⚽️)", text: $emoji)
                } header: {
                    Text("Immagine")
                } footer: {
                    Text("Il disegno che il bambino vede, soprattutto nella sfida \"Indovina e dì\". Usa la tastiera emoji 🌐.")
                }

                Section {
                    TextField("Frase (es. La palla rotola)", text: $frase, axis: .vertical)
                } header: {
                    Text("Frasetta")
                } footer: {
                    Text("Usata nella sfida \"La frasetta\". Se la lasci vuota, Pippo dirà \"Guarda, \(testoPulito.isEmpty ? "…" : testoPulito)!\".")
                }

                if let problema {
                    Section {
                        Label(problema, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                            .font(.subheadline)
                    }
                }
            }
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .navigationTitle("Nuova parola")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva", action: salva)
                        .disabled(problema != nil)
                }
            }
        }
    }

    private func salva() {
        let simbolo = emoji.trimmingCharacters(in: .whitespaces).first.map(String.init) ?? "⭐️"
        gestore.aggiungi(ParolaPersonalizzata(
            percorsoId: percorso.id,
            testo: testoPulito,
            gemella: gemellaPulita,
            emoji: simbolo,
            frase: frasePulita.isEmpty ? "Guarda, \(testoPulito)!" : frasePulita
        ))
        dismiss()
    }
}

#Preview {
    NavigationStack {
        GestioneParoleView(percorso: Percorso.tutti[0])
            .environmentObject(Progresso())
    }
}
