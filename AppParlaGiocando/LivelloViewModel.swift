import SwiftUI
import AVFoundation
import Combine

enum Feedback: Equatable {
    case nessuno, ascolto, bravo, quasi, riprova, nonSentito, passiamo
}

/// Logica di gioco di una sfida (un percorso + un sottolivello)
@MainActor
final class LivelloViewModel: ObservableObject {
    let percorso: Percorso
    let sfida: Sfida

    @Published private(set) var parole: [Parola]
    @Published private(set) var indice = 0
    @Published var feedback: Feedback = .nessuno
    @Published private(set) var confusioniConGemella = 0
    @Published private(set) var altriErrori = 0
    /// Parole su cui il bambino ha detto la gemella (per il logopedista)
    @Published private(set) var paroleConfuse: [String] = []
    /// Il complimento che Pippo dice quando il bambino indovina
    @Published private(set) var complimento = "Bravissimo!"

    /// Complimenti adatti sia ai bambini che alle bambine
    static let complimenti = [
        "Grande!", "Evviva!", "Fantastico!", "Perfetto!", "Esatto!",
        "Super!", "Che bello!", "Ce l'hai fatta!", "Ottimo lavoro!", "Wow, giusto!"
    ]

    private var tentativiParola = 0
    private var pausa: Task<Void, Never>?
    private let paroleAPartita = 6

    init(percorso: Percorso, sfida: Sfida) {
        self.percorso = percorso
        self.sfida = sfida
        self.parole = Array(percorso.parole.shuffled().prefix(paroleAPartita))
    }

    // MARK: Stato

    var totale: Int { parole.count }
    var completato: Bool { indice >= parole.count }
    var parola: Parola { parole[min(indice, parole.count - 1)] }
    var secondiMax: Double { sfida.secondiMax }

    var stelle: Int {
        let errori = confusioniConGemella + altriErrori
        return errori == 0 ? 3 : (errori <= 2 ? 2 : 1)
    }

    // MARK: Cosa mostrare e dire

    /// Quello che Pippo pronuncia ad alta voce
    var daAscoltare: String {
        switch sfida {
        case .ascoltaERipeti, .indovina: parola.testo
        case .coppia:                    "\(parola.testo)... \(parola.gemella)"
        case .frase:                     parola.frase
        }
    }

    /// Il testo grande mostrato nella carta
    var testoVisibile: String {
        switch sfida {
        case .ascoltaERipeti: parola.testo.uppercased()
        case .indovina:       "Che cos'è?"
        case .coppia:         "\(parola.testo.uppercased()) · \(parola.gemella.uppercased())"
        case .frase:          parola.frase
        }
    }

    /// Aiuta il riconoscimento vocale
    var parolePerRiconoscimento: [String] {
        var lista = [parola.testo, parola.gemella]
        if sfida == .frase { lista.append(parola.frase) }
        return lista
    }

    var messaggio: String {
        switch feedback {
        case .nessuno:
            switch sfida {
            case .indovina: "Che cos'è? Dimmelo!"
            case .coppia:   "Ripeti le due parole!"
            case .frase:    "Ripeti la frase!"
            default:        "Premi il microfono e parla!"
            }
        case .ascolto:    "Ti ascolto… 👂"
        case .bravo:      "\(complimento) 🎉"
        case .quasi:
            sfida == .coppia ? "Quasi! Dimmi tutte e due!" : "Quasi! Ascolta bene: \(parola.testo)"
        case .riprova:    "Riproviamo! Ascolta bene 👂"
        case .nonSentito: "Non ti ho sentito. Riprova! 🎤"
        case .passiamo:   "Non fa niente, andiamo avanti! 💪"
        }
    }

    var coloreMessaggio: Color {
        switch feedback {
        case .bravo:             .green
        case .quasi, .riprova:   .orange
        case .passiamo:          .blue
        case .ascolto:           .red
        default:                 percorso.colore
        }
    }

    // MARK: Valutazione

    /// Serve per fermare l'ascolto appena il bambino ha finito di rispondere
    func rispostaCompleta(_ testo: String) -> Bool {
        let s = testo.paroleNormalizzate
        let target = parola.testo.normalizzata
        switch sfida {
        case .coppia:
            return s.contains(target) && s.contains(parola.gemella.normalizzata)
        case .frase:
            guard let ultima = parola.frase.paroleNormalizzate.last else { return false }
            return s.contains(target) && s.contains(ultima)
        default:
            return s.contains(target)
        }
    }

    /// Valuta cosa ha detto il bambino (da chiamare quando l'ascolto finisce)
    func valuta(_ testo: String) {
        guard feedback == .ascolto, !completato else { return }
        let s = testo.paroleNormalizzate

        if s.isEmpty {
            feedback = .nonSentito
            return
        }

        let haTarget = s.contains(parola.testo.normalizzata)
        let haGemella = s.contains(parola.gemella.normalizzata)

        switch sfida {
        case .coppia:
            if haTarget && haGemella {
                successo()
            } else if haTarget || haGemella {
                feedback = .quasi
                fallito(confusione: false)
            } else {
                feedback = .riprova
                fallito(confusione: false)
            }
        default:
            if haTarget {
                successo()
            } else if haGemella {
                feedback = .quasi          // ha detto la gemella: è il dato diagnostico!
                fallito(confusione: true)
            } else {
                feedback = .riprova
                fallito(confusione: false)
            }
        }
    }

    func ricomincia() {
        pausa?.cancel()
        parole = Array(percorso.parole.shuffled().prefix(paroleAPartita))
        indice = 0
        confusioniConGemella = 0
        altriErrori = 0
        paroleConfuse = []
        tentativiParola = 0
        feedback = .nessuno
    }

    // MARK: Interni

    private func successo() {
        // Mai lo stesso complimento due volte di fila
        complimento = Self.complimenti.filter { $0 != complimento }.randomElement() ?? "Bravissimo!"
        feedback = .bravo
        avanzaDopoPausa(secondi: 2.3)   // il tempo di godersi il complimento
    }

    private func fallito(confusione: Bool) {
        if confusione {
            confusioniConGemella += 1
            paroleConfuse.append(parola.testo)
        } else {
            altriErrori += 1
        }
        tentativiParola += 1
        // dopo 3 tentativi si passa oltre, senza frustrare il bambino
        if tentativiParola >= 3 {
            feedback = .passiamo
            avanzaDopoPausa()
        }
    }

    private func avanzaDopoPausa(secondi: Double = 1.8) {
        pausa?.cancel()
        pausa = Task {
            try? await Task.sleep(for: .seconds(secondi))
            guard !Task.isCancelled else { return }
            tentativiParola = 0
            indice += 1
            feedback = .nessuno
        }
    }
}

/// Legge ad alta voce le parole (voce italiana)
final class Speaker: ObservableObject {
    private let synthesizer = AVSpeechSynthesizer()

    /// La migliore voce italiana installata sull'iPhone (premium > migliorata > base)
    private static let voce: AVSpeechSynthesisVoice? = {
        let italiane = AVSpeechSynthesisVoice.speechVoices().filter { $0.language == "it-IT" }
        return italiane.max { $0.quality.rawValue < $1.quality.rawValue }
            ?? AVSpeechSynthesisVoice(language: "it-IT")
    }()

    /// - Parameter allegro: voce un po' più acuta e vivace, per i complimenti
    func di(_ testo: String, allegro: Bool = false) {
        synthesizer.stopSpeaking(at: .immediate)
        Self.preparaAudio()

        let utterance = AVSpeechUtterance(string: Self.conPunto(testo))
        utterance.voice = Self.voce
        utterance.rate = allegro ? 0.48 : 0.42
        utterance.pitchMultiplier = allegro ? 1.3 : 1.15
        // Un attimo di respiro prima e dopo: l'altoparlante fa in tempo ad accendersi
        // e l'ultima vocale non viene tagliata
        utterance.preUtteranceDelay = 0.15
        utterance.postUtteranceDelay = 0.3
        synthesizer.speak(utterance)
    }

    func ferma() {
        synthesizer.stopSpeaking(at: .immediate)
    }

    /// Una parola senza punteggiatura viene chiusa di colpo dalla sintesi vocale:
    /// con il punto finale l'ultima vocale viene pronunciata per intero ("palla." invece di "pall")
    private static func conPunto(_ testo: String) -> String {
        let pulito = testo.trimmingCharacters(in: .whitespaces)
        guard let ultimo = pulito.last, !".!?".contains(ultimo) else { return pulito }
        return pulito + "."
    }

    /// Senza questa impostazione la voce non si sente con l'iPhone in modalità silenziosa.
    /// Usa la stessa configurazione del microfono, così l'audio non cambia tra ascolto e parlato.
    /// La sessione si configura una sola volta: riattivarla a ogni parola taglia l'audio.
    private static var audioPronto = false

    private static func preparaAudio() {
        let sessione = AVAudioSession.sharedInstance()
        if !audioPronto || sessione.category != .playAndRecord {
            try? sessione.setCategory(.playAndRecord, mode: .default,
                                      options: [.defaultToSpeaker, .duckOthers, .allowBluetoothA2DP])
            audioPronto = true
        }
        try? sessione.setActive(true)
    }
}
