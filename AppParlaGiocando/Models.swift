import SwiftUI

// MARK: - Parole e percorsi

struct Parola: Identifiable {
    let id = UUID()
    let testo: String      // parola che il bambino deve dire
    let gemella: String    // l'altra parola della coppia minima
    let emoji: String      // immagine mostrata al bambino
    let frase: String      // frasetta che contiene la parola (per la sfida 4)
    /// Disegno della gemella: serve per la sfida "Quale hai sentito?" (nil = non disegnabile)
    var emojiGemella: String? = nil
}

struct Percorso: Identifiable {
    let titolo: String
    let coppia: String
    let emoji: String
    let colore: Color
    let parole: [Parola]
    /// Banca di coppie in più: a ogni avvio Pippo ne pesca alcune nuove (vedi GestoreParole)
    var riserva: [Parola] = []
    /// Le parole nuove pescate a questo avvio, da proporre per prime nelle partite
    var novita: Set<String> = []
    /// Le coppie con due disegni, per la sfida "Quale hai sentito?" (vedi GestoreParole)
    var coppieIllustrate: [Parola] = []

    var id: String { titolo }   // stabile: serve per salvare i progressi
}

// MARK: - Sottolivelli (sempre più difficili)

enum Sfida: Int, CaseIterable, Identifiable {
    case ascoltaERipeti   // 1: Pippo dice la parola, si vede disegno + parola scritta
    case indovina         // 2: solo il disegno, il bambino deve trovare la parola
    case coppia           // 3: "Quale hai sentito?": Pippo dice una delle due parole, il bambino tocca il disegno
    case frase            // 4: dire una frasetta che contiene la parola

    var id: Int { rawValue }

    var titolo: String {
        switch self {
        case .ascoltaERipeti: "Ascolta e ripeti"
        case .indovina:       "Indovina e dì"
        case .coppia:         "Quale hai sentito?"
        case .frase:          "La frasetta"
        }
    }

    var descrizione: String {
        switch self {
        case .ascoltaERipeti: "Pippo parla, tu ripeti"
        case .indovina:       "Guarda il disegno e dì cos'è"
        case .coppia:         "Ascolta Pippo e tocca il disegno giusto"
        case .frase:          "Ripeti la frase di Pippo"
        }
    }

    var emoji: String {
        switch self {
        case .ascoltaERipeti: "👂"
        case .indovina:       "🤔"
        case .coppia:         "🎧"
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
            Parola(testo: "palla", gemella: "balla", emoji: "⚽️", frase: "La palla rotola", emojiGemella: "💃"),
            Parola(testo: "pasta", gemella: "basta", emoji: "🍝", frase: "La pasta è buona"),
            Parola(testo: "pere",  gemella: "bere",  emoji: "🍐", frase: "Le pere sono dolci", emojiGemella: "🥤"),
            Parola(testo: "barca", gemella: "parca", emoji: "⛵️", frase: "La barca va sul mare"),
            Parola(testo: "banca", gemella: "panca", emoji: "🏦", frase: "La banca è chiusa", emojiGemella: "🪑"),
            Parola(testo: "pollo", gemella: "bollo", emoji: "🍗", frase: "Il pollo è caldo"),
            Parola(testo: "panda", gemella: "banda", emoji: "🐼", frase: "Il panda mangia", emojiGemella: "🎺"),
            Parola(testo: "pizza", gemella: "bizza", emoji: "🍕", frase: "Che buona la pizza")
        ], riserva: [
            Parola(testo: "bacca", gemella: "pacca", emoji: "🫐", frase: "La bacca è blu", emojiGemella: "🤚"),
            Parola(testo: "bolla", gemella: "polla", emoji: "🫧", frase: "La bolla vola"),
            Parola(testo: "passo", gemella: "basso", emoji: "👣", frase: "Faccio un passo"),
            Parola(testo: "becco", gemella: "pecco", emoji: "🐤", frase: "Il pulcino apre il becco"),
            Parola(testo: "polo",  gemella: "bolo",  emoji: "🧊", frase: "Al polo fa freddo"),
            Parola(testo: "pacco", gemella: "bacco", emoji: "📦", frase: "Apro il pacco", emojiGemella: "🍇"),
            Parola(testo: "batto", gemella: "patto", emoji: "🥁", frase: "Batto il tamburo")
        ]),
        Percorso(titolo: "Bosco T/D", coppia: "T / D", emoji: "🌲", colore: .green, parole: [
            Parola(testo: "topo",  gemella: "dopo",  emoji: "🐭", frase: "Il topo corre"),
            Parola(testo: "dono",  gemella: "tono",  emoji: "🎁", frase: "Un dono per te"),
            Parola(testo: "dardi", gemella: "tardi", emoji: "🎯", frase: "I dardi volano", emojiGemella: "⏰"),
            Parola(testo: "dino",  gemella: "tino",  emoji: "🦖", frase: "Il dino è grande"),
            Parola(testo: "tetto", gemella: "detto", emoji: "🏠", frase: "Il tetto è rosso"),
            Parola(testo: "dito",  gemella: "tito",  emoji: "👆", frase: "Muovo il dito"),
            Parola(testo: "moto",  gemella: "modo",  emoji: "🏍️", frase: "La moto va forte"),
            Parola(testo: "tata",  gemella: "data",  emoji: "👩‍🍼", frase: "La tata gioca con me", emojiGemella: "📅")
        ], riserva: [
            Parola(testo: "dado",  gemella: "dato",  emoji: "🎲", frase: "Tiro il dado", emojiGemella: "📊"),
            Parola(testo: "tondo", gemella: "tonto", emoji: "⚪️", frase: "Il cerchio è tondo"),
            Parola(testo: "nodo",  gemella: "noto",  emoji: "🪢", frase: "Faccio un nodo"),
            Parola(testo: "vento", gemella: "vendo", emoji: "🌬️", frase: "Il vento soffia"),
            Parola(testo: "tenda", gemella: "tenta", emoji: "⛺️", frase: "La tenda è verde"),
            Parola(testo: "sete",  gemella: "sede",  emoji: "🥤", frase: "Ho tanta sete"),
            Parola(testo: "mondo", gemella: "monto", emoji: "🌍", frase: "Il mondo è grande"),
            Parola(testo: "onda",  gemella: "onta",  emoji: "🌊", frase: "L'onda è alta")
        ]),
        Percorso(titolo: "Montagna S/Z", coppia: "S / Z", emoji: "🏔️", colore: .orange, parole: [
            Parola(testo: "tazza", gemella: "tassa", emoji: "☕️", frase: "La tazza è piena", emojiGemella: "💶"),
            Parola(testo: "razzo", gemella: "rasso", emoji: "🚀", frase: "Il razzo vola"),
            Parola(testo: "pozzo", gemella: "posso", emoji: "🕳️", frase: "Nel pozzo c'è acqua"),
            Parola(testo: "pazzo", gemella: "passo", emoji: "🤪", frase: "Il pagliaccio è pazzo", emojiGemella: "👣"),
            Parola(testo: "rosa",  gemella: "rossa", emoji: "🌹", frase: "La rosa profuma", emojiGemella: "🔴"),
            Parola(testo: "casa",  gemella: "cassa", emoji: "🏡", frase: "La casa è grande", emojiGemella: "💰"),
            Parola(testo: "gazza", gemella: "gassa", emoji: "🐦", frase: "La gazza vola")
        ], riserva: [
            Parola(testo: "orso",   gemella: "orzo",   emoji: "🐻", frase: "L'orso dorme", emojiGemella: "🌾"),
            Parola(testo: "terzo",  gemella: "terso",  emoji: "🥉", frase: "Arrivo terzo"),
            Parola(testo: "mazzo",  gemella: "masso",  emoji: "💐", frase: "Un mazzo di fiori", emojiGemella: "🪨"),
            Parola(testo: "mazza",  gemella: "massa",  emoji: "🏏", frase: "La mazza colpisce la palla"),
            Parola(testo: "lasso",  gemella: "lazzo",  emoji: "🤠", frase: "Il cowboy lancia il lasso"),
            Parola(testo: "pozza",  gemella: "possa",  emoji: "💧", frase: "Salto nella pozza"),
            Parola(testo: "spazzo", gemella: "spasso", emoji: "🧹", frase: "Spazzo il pavimento")
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
