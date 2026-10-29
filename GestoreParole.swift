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

    private let chiavePersonalizzate = "parole.personalizzate"
    private let chiaveEscluse = "parole.escluse"

    private init() {
        let defaults = UserDefaults.standard
        if let data = defaults.data(forKey: chiavePersonalizzate),
           let decoded = try? JSONDecoder().decode([ParolaPersonalizzata].self, from: data) {
            personalizzate = decoded
        }
        if let lista = defaults.stringArray(forKey: chiaveEscluse) {
            escluse = Set(lista)
        }
    }

    // MARK: Lettura

    func personalizzate(di p: Percorso) -> [ParolaPersonalizzata] {
        personalizzate.filter { $0.percorsoId == p.id }
    }

    /// Tutte le parole del percorso: quelle di base più quelle aggiunte
    func tutteLeParole(_ p: Percorso) -> [Parola] {
        p.parole + personalizzate(di: p).map(\.parola)
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
        Percorso(titolo: p.titolo, coppia: p.coppia, emoji: p.emoji,
                 colore: p.colore, parole: paroleAttive(p))
    }

    func gemella(di testo: String, in p: Percorso) -> String {
        tutteLeParole(p).first { $0.testo == testo }?.gemella ?? "?"
    }

    func esiste(_ testo: String, in p: Percorso) -> Bool {
        let t = testo.normalizzata
        return tutteLeParole(p).contains { $0.testo.normalizzata == t }
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

    private func salva() {
        let defaults = UserDefaults.standard
        if let data = try? JSONEncoder().encode(personalizzate) {
            defaults.set(data, forKey: chiavePersonalizzate)
        }
        defaults.set(Array(escluse), forKey: chiaveEscluse)
    }
}
