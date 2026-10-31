import SwiftUI
import Combine

/// Una sfida completata dal bambino: serve al logopedista per seguire l'andamento
struct SessioneSalvata: Codable, Identifiable {
    var id = UUID()
    let percorsoId: String
    let sfida: Int
    let data: Date
    let stelle: Int
    let confusioni: Int          // volte in cui ha detto la parola gemella
    let altriErrori: Int
    let paroleConfuse: [String]  // parole su cui ha detto la gemella
}

/// Salva le stelle guadagnate per ogni (percorso, sfida), lo storico delle sessioni
/// e decide cosa è sbloccato
@MainActor
final class Progresso: ObservableObject {
    @Published private(set) var salvate: [String: Int] = [:]
    @Published private(set) var sessioni: [SessioneSalvata] = []

    private let chiaveDefaults = "progresso.stelle"
    private let chiaveSessioni = "progresso.sessioni"
    private static let maxSessioni = 1000

    init() {
        if let data = UserDefaults.standard.data(forKey: chiaveDefaults),
           let decoded = try? JSONDecoder().decode([String: Int].self, from: data) {
            salvate = decoded
        }
        if let data = UserDefaults.standard.data(forKey: chiaveSessioni),
           let decoded = try? JSONDecoder().decode([SessioneSalvata].self, from: data) {
            sessioni = decoded
        }
    }

    private func chiave(_ p: Percorso, _ s: Sfida) -> String { "\(p.id).\(s.rawValue)" }

    // MARK: Stelle

    func stelleOttenute(_ p: Percorso, _ s: Sfida) -> Int {
        salvate[chiave(p, s)] ?? 0
    }

    func totaleStelle(_ p: Percorso) -> Int {
        Sfida.allCases.reduce(0) { $0 + stelleOttenute(p, $1) }
    }

    /// La prima sfida è sempre aperta; le altre si aprono completando la precedente
    func sbloccata(_ p: Percorso, _ s: Sfida) -> Bool {
        guard let precedente = Sfida(rawValue: s.rawValue - 1) else { return true }
        return stelleOttenute(p, precedente) > 0
    }

    func registra(_ p: Percorso, _ s: Sfida, stelle n: Int) {
        let k = chiave(p, s)
        guard n > (salvate[k] ?? 0) else { return }
        salvate[k] = n
        salvaStelle()
    }

    // MARK: Storico per il logopedista

    /// Da chiamare a fine sfida: salva le stelle e aggiunge la sessione allo storico
    func registraSessione(_ livello: LivelloViewModel) {
        registra(livello.percorso, livello.sfida, stelle: livello.stelle)
        sessioni.append(SessioneSalvata(
            percorsoId: livello.percorso.id,
            sfida: livello.sfida.rawValue,
            data: .now,
            stelle: livello.stelle,
            confusioni: livello.confusioniConGemella,
            altriErrori: livello.altriErrori,
            paroleConfuse: livello.paroleConfuse
        ))
        if sessioni.count > Self.maxSessioni {
            sessioni.removeFirst(sessioni.count - Self.maxSessioni)
        }
        salvaSessioni()
    }

    func sessioniDi(_ p: Percorso, _ s: Sfida) -> [SessioneSalvata] {
        sessioni.filter { $0.percorsoId == p.id && $0.sfida == s.rawValue }
    }

    /// Le parole di un percorso confuse con la gemella, dalla più frequente
    func paroleConfuse(_ p: Percorso) -> [(parola: String, volte: Int)] {
        let tutte = sessioni
            .filter { $0.percorsoId == p.id }
            .flatMap(\.paroleConfuse)
        return Dictionary(grouping: tutte, by: { $0 })
            .map { (parola: $0.key, volte: $0.value.count) }
            .sorted { $0.volte > $1.volte }
    }

    /// Cancella stelle e storico
    func azzera() {
        salvate = [:]
        sessioni = []
        salvaStelle()
        salvaSessioni()
    }

    // MARK: Salvataggio

    private func salvaStelle() {
        if let data = try? JSONEncoder().encode(salvate) {
            UserDefaults.standard.set(data, forKey: chiaveDefaults)
        }
    }

    private func salvaSessioni() {
        if let data = try? JSONEncoder().encode(sessioni) {
            UserDefaults.standard.set(data, forKey: chiaveSessioni)
        }
    }
}

