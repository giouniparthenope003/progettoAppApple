import SwiftUI
import Combine

/// Una parola aggiunta dal logopedista a un percorso
struct ParolaPersonalizzata: Codable, Identifiable, Hashable {
    var id = UUID()
    let percorsoId: String
    let testo: String
    let gemella: String
    let emoji: String
    let frase: String

    var parola: Parola {
        Parola(testo: testo, gemella: gemella, emoji: emoji, frase: frase)
    }
}

/// Gestisce le parole aggiunte dal logopedista e quali parole sono attive nel gioco
@MainActor
final class GestoreParole: ObservableObject {
    static let shared = GestoreParole()

    @Published private(set) var personalizzate: [ParolaPersonalizzata] = []
    /// Parole spente, salvate come "percorso|parola"
    @Published private(set) var escluse: Set<String> = []
    /// Le parole nuove pescate dalla banca a questo avvio, per percorso
    @Published private(set) var nuoveDiOggi: [String: [String]] = [:]

    /// Quante parole nuove Pippo pesca dalla banca di ogni percorso a ogni avvio
    static let nuovePerAvvio = 4

    private let chiavePersonalizzate = "parole.personalizzate"
    private let chiaveEscluse = "parole.escluse"
    private let chiaveUscite = "parole.giaUscite"

    private init() {
        let defaults = UserDefaults.standard
        if let data = defaults.data(forKey: chiavePersonalizzate),
           let decoded = try? JSONDecoder().decode([ParolaPersonalizzata].self, from: data) {
            personalizzate = decoded
        }
        if let lista = defaults.stringArray(forKey: chiaveEscluse) {
            escluse = Set(lista)
        }
        pescaNuoveParole()
    }

    // MARK: Lettura

    func personalizzate(di p: Percorso) -> [ParolaPersonalizzata] {
        personalizzate.filter { $0.percorsoId == p.id }
    }

    /// Le parole nuove di questo avvio per il percorso
    func nuove(di p: Percorso) -> [Parola] {
        let testi = nuoveDiOggi[p.id] ?? []
        return banca(p).filter { testi.contains($0.testo) }
    }

    /// Tutte le parole del percorso in gioco oggi: base, nuove di oggi e aggiunte
    func tutteLeParole(_ p: Percorso) -> [Parola] {
        p.parole + nuove(di: p) + personalizzate(di: p).map(\.parola)
    }

    /// Tutte le parole conosciute del percorso, anche quelle della banca non uscite oggi
    private func catalogo(_ p: Percorso) -> [Parola] {
        p.parole + banca(p) + personalizzate(di: p).map(\.parola)
    }

    /// La banca del percorso (cercata per id, così funziona con qualunque copia del percorso)
    private func banca(_ p: Percorso) -> [Parola] {
        Percorso.tutti.first { $0.id == p.id }?.riserva ?? p.riserva
    }

    func attiva(_ p: Percorso, _ testo: String) -> Bool {
        !escluse.contains(chiave(p, testo))
    }

    /// Le parole da usare nel gioco. Se fossero tutte spente, usa quelle di base.
    func paroleAttive(_ p: Percorso) -> [Parola] {
        let attive = tutteLeParole(p).filter { attiva(p, $0.testo) }
        return attive.isEmpty ? p.parole : attive
    }

    /// Il percorso con le sole parole attive, pronto per il gioco
    func perIlGioco(_ p: Percorso) -> Percorso {
        let novita = Set(nuove(di: p).map(\.testo).filter { attiva(p, $0) })
        return Percorso(titolo: p.titolo, coppia: p.coppia, emoji: p.emoji,
                        colore: p.colore, parole: paroleAttive(p), novita: novita)
    }

    func gemella(di testo: String, in p: Percorso) -> String {
        catalogo(p).first { $0.testo == testo }?.gemella ?? "?"
    }

    func esiste(_ testo: String, in p: Percorso) -> Bool {
        let t = testo.normalizzata
        return catalogo(p).contains { $0.testo.normalizzata == t }
    }

    // MARK: Modifica

    func aggiungi(_ parola: ParolaPersonalizzata) {
        personalizzate.append(parola)
        salva()
    }

    func elimina(_ parola: ParolaPersonalizzata) {
        personalizzate.removeAll { $0.id == parola.id }
        if let p = Percorso.tutti.first(where: { $0.id == parola.percorsoId }) {
            escluse.remove(chiave(p, parola.testo))
        }
        salva()
    }

    func imposta(attiva: Bool, _ p: Percorso, _ testo: String) {
        let k = chiave(p, testo)
        if attiva { escluse.remove(k) } else { escluse.insert(k) }
        salva()
    }

    // MARK: Interni

    private func chiave(_ p: Percorso, _ testo: String) -> String { "\(p.id)|\(testo)" }

    /// A ogni avvio pesca alcune parole nuove dalla banca di ogni percorso.
    /// Prima di ripetere una parola già uscita, fa girare tutta la banca.
    /// Le parole spente dal logopedista non vengono più pescate.
    private func pescaNuoveParole() {
        let defaults = UserDefaults.standard
        var uscite = (defaults.dictionary(forKey: chiaveUscite) as? [String: [String]]) ?? [:]
        let quante = Self.nuovePerAvvio

        for p in Percorso.tutti where !p.riserva.isEmpty {
            let disponibili = p.riserva.map(\.testo).filter { attiva(p, $0) }
            var giaUscite = Set(uscite[p.id] ?? [])

            var scelte = Array(disponibili.filter { !giaUscite.contains($0) }.shuffled().prefix(quante))
            if scelte.count < quante {
                // Banca finita: ricomincia il giro con le parole che mancano
                giaUscite = []
                let altre = disponibili.filter { !scelte.contains($0) }.shuffled()
                scelte += altre.prefix(quante - scelte.count)
            }

            giaUscite.formUnion(scelte)
            nuoveDiOggi[p.id] = scelte
            uscite[p.id] = Array(giaUscite)
        }
        defaults.set(uscite, forKey: chiaveUscite)
    }

    private func salva() {
        let defaults = UserDefaults.standard
        if let data = try? JSONEncoder().encode(personalizzate) {
            defaults.set(data, forKey: chiavePersonalizzate)
        }
        defaults.set(Array(escluse), forKey: chiaveEscluse)
    }
}
