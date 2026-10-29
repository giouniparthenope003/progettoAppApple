import SwiftUI
import Combine

/// Salva le stelle guadagnate per ogni (percorso, sfida) e decide cosa è sbloccato
@MainActor
final class Progresso: ObservableObject {
    @Published private(set) var salvate: [String: Int] = [:]
    private let chiaveDefaults = "progresso.stelle"

    init() {
        if let data = UserDefaults.standard.data(forKey: chiaveDefaults),
           let decoded = try? JSONDecoder().decode([String: Int].self, from: data) {
            salvate = decoded
        }
    }

    private func chiave(_ p: Percorso, _ s: Sfida) -> String { "\(p.id).\(s.rawValue)" }

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
        if let data = try? JSONEncoder().encode(salvate) {
            UserDefaults.standard.set(data, forKey: chiaveDefaults)
        }
    }
}
