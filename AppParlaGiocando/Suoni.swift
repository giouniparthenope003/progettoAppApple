import UIKit
import AVFoundation

/// Piccoli suoni e vibrazioni per i pulsanti e per la fine di una sfida.
/// Si possono spegnere dall'area logopedista (impostazione "Suoni e vibrazioni").
/// Il microfono non fa suoni: il riconoscimento vocale li catturerebbe.
final class Suoni {
    static let shared = Suoni()

    enum Effetto: String {
        case tocco      // "pop" leggero sui pulsanti
        case vittoria   // tre campanelle, una per stella
    }

    /// Chiave per @AppStorage: attivi di default
    static let chiaveAttivi = "suoniAttivi"

    private var player: [Effetto: AVAudioPlayer] = [:]

    private init() {}

    var attivi: Bool {
        UserDefaults.standard.object(forKey: Self.chiaveAttivi) as? Bool ?? true
    }

    func suona(_ effetto: Effetto) {
        guard attivi else { return }

        if let player = player[effetto] ?? carica(effetto) {
            player.currentTime = 0
            player.play()
        }

        switch effetto {
        case .tocco:    UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .vittoria: UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    /// Solo la vibrazione, per i pulsanti che non devono fare rumore (il microfono)
    func vibra() {
        guard attivi else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    /// I suoni sono nel catalogo Assets come "suono-tocco" e "suono-vittoria"
    private func carica(_ effetto: Effetto) -> AVAudioPlayer? {
        guard let asset = NSDataAsset(name: "suono-\(effetto.rawValue)"),
              let nuovo = try? AVAudioPlayer(data: asset.data, fileTypeHint: AVFileType.wav.rawValue)
        else { return nil }
        nuovo.volume = effetto == .tocco ? 0.45 : 0.8
        nuovo.prepareToPlay()
        player[effetto] = nuovo
        return nuovo
    }
}
