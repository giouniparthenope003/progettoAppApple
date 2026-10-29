import SwiftUI

// MARK: - Parole e percorsi

struct Parola: Identifiable {
    let id = UUID()
    let testo: String      // parola che il bambino deve dire
    let gemella: String    // l'altra parola della coppia minima
    let emoji: String      // immagine mostrata al bambino
    let frase: String      // frasetta che contiene la parola (per la sfida 4)
}

struct Percorso: Identifiable {
    let titolo: String
    let coppia: String
    let emoji: String
    let colore: Color
    let parole: [Parola]

    var id: String { titolo }   // stabile: serve per salvare i progressi
}

// MARK: - Sottolivelli (sempre più difficili)

enum Sfida: Int, CaseIterable, Identifiable {
    case ascoltaERipeti   // 1: Pippo dice la parola, si vede disegno + parola scritta
    case indovina         // 2: solo il disegno, il bambino deve trovare la parola
    case coppia           // 3: ripetere le DUE parole della coppia minima
    case frase            // 4: dire una frasetta che contiene la parola

    var id: Int { rawValue }

    var titolo: String {
        switch self {
        case .ascoltaERipeti: "Ascolta e ripeti"
        case .indovina:       "Indovina e dì"
        case .coppia:         "Le due parole"
        case .frase:          "La frasetta"
        }
    }

    var descrizione: String {
        switch self {
        case .ascoltaERipeti: "Pippo parla, tu ripeti"
        case .indovina:       "Guarda il disegno e dì cos'è"
        case .coppia:         "Ripeti le due parole gemelle"
        case .frase:          "Ripeti la frase di Pippo"
        }
    }

    var emoji: String {
        switch self {
        case .ascoltaERipeti: "👂"
        case .indovina:       "🤔"
        case .coppia:         "👯"
        case .frase:          "💬"
        }
    }

    /// Secondi massimi di ascolto prima dello stop automatico
    var secondiMax: Double {
        switch self {
        case .ascoltaERipeti, .indovina: 5
        case .coppia: 7
        case .frase: 9
        }
    }
}

// MARK: - Dati

extension Percorso {
    static let tutti: [Percorso] = [
        Percorso(titolo: "Isola B/P", coppia: "B / P", emoji: "🏝️", colore: .blue, parole: [
            Parola(testo: "palla", gemella: "balla", emoji: "⚽️", frase: "La palla rotola"),
            Parola(testo: "pasta", gemella: "basta", emoji: "🍝", frase: "La pasta è buona"),
            Parola(testo: "pere",  gemella: "bere",  emoji: "🍐", frase: "Le pere sono dolci"),
            Parola(testo: "barca", gemella: "parca", emoji: "⛵️", frase: "La barca va sul mare"),
            Parola(testo: "banca", gemella: "panca", emoji: "🏦", frase: "La banca è chiusa"),
            Parola(testo: "pollo", gemella: "bollo", emoji: "🍗", frase: "Il pollo è caldo"),
            Parola(testo: "panda", gemella: "banda", emoji: "🐼", frase: "Il panda mangia"),
            Parola(testo: "pizza", gemella: "bizza", emoji: "🍕", frase: "Che buona la pizza")
        ]),
        Percorso(titolo: "Bosco T/D", coppia: "T / D", emoji: "🌲", colore: .green, parole: [
            Parola(testo: "topo",  gemella: "dopo",  emoji: "🐭", frase: "Il topo corre"),
            Parola(testo: "dono",  gemella: "tono",  emoji: "🎁", frase: "Un dono per te"),
            Parola(testo: "dardi", gemella: "tardi", emoji: "🎯", frase: "I dardi volano"),
            Parola(testo: "dino",  gemella: "tino",  emoji: "🦖", frase: "Il dino è grande"),
            Parola(testo: "tetto", gemella: "detto", emoji: "🏠", frase: "Il tetto è rosso"),
            Parola(testo: "dito",  gemella: "tito",  emoji: "👆", frase: "Muovo il dito"),
            Parola(testo: "moto",  gemella: "modo",  emoji: "🏍️", frase: "La moto va forte")
        ]),
        Percorso(titolo: "Montagna S/Z", coppia: "S / Z", emoji: "🏔️", colore: .orange, parole: [
            Parola(testo: "tazza", gemella: "tassa", emoji: "☕️", frase: "La tazza è piena"),
            Parola(testo: "razzo", gemella: "rasso", emoji: "🚀", frase: "Il razzo vola"),
            Parola(testo: "pozzo", gemella: "posso", emoji: "🕳️", frase: "Nel pozzo c'è acqua"),
            Parola(testo: "pazzo", gemella: "passo", emoji: "🤪", frase: "Il pagliaccio è pazzo"),
            Parola(testo: "rosa",  gemella: "rossa", emoji: "🌹", frase: "La rosa profuma"),
            Parola(testo: "casa",  gemella: "cassa", emoji: "🏡", frase: "La casa è grande"),
            Parola(testo: "gazza", gemella: "gassa", emoji: "🐦", frase: "La gazza vola")
        ])
    ]
}

// MARK: - Normalizzazione del testo

extension String {
    /// minuscolo, senza accenti
    var normalizzata: String {
        folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "it_IT"))
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Le parole della frase, normalizzate e senza punteggiatura
    var paroleNormalizzate: [String] {
        normalizzata
            .components(separatedBy: CharacterSet.letters.inverted)
            .filter { !$0.isEmpty }
    }
}
