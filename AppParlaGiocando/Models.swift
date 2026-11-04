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
    /// In alternativa all'emoji: nome di una foto o di un disegno in Assets.xcassets
    /// (es. "gemella-panca"). Se c'è, ha la precedenza sull'emoji.
    var immagineGemella: String? = nil

    /// La coppia si può usare in "Quale hai sentito?" (la gemella ha un'emoji o un'immagine)
    var haDisegnoGemella: Bool { emojiGemella != nil || immagineGemella != nil }
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
        Percorso(titolo: "Isola", coppia: "B / P", emoji: "🏝️", colore: .blue, parole: [
            Parola(testo: "palla",  gemella: "balla",  emoji: "⚽️", frase: "La palla rotola", emojiGemella: "💃"),
            Parola(testo: "pasta",  gemella: "basta",  emoji: "🍝", frase: "La pasta è buona", emojiGemella: "✋"),
            Parola(testo: "pere",   gemella: "bere",   emoji: "🍐", frase: "Le pere sono dolci", emojiGemella: "🥤"),
            Parola(testo: "barca",  gemella: "parca",  emoji: "⛵️", frase: "La barca va sul mare"),
            Parola(testo: "banca",  gemella: "panca",  emoji: "🏦", frase: "La banca è chiusa", immagineGemella: "gemella-panca"),
            Parola(testo: "pollo",  gemella: "bollo",  emoji: "🍗", frase: "Il pollo è caldo", immagineGemella: "gemella-francobollo"),
            Parola(testo: "panda",  gemella: "banda",  emoji: "🐼", frase: "Il panda mangia", immagineGemella: "gemella-banda"),
            Parola(testo: "pizza",  gemella: "bizza",  emoji: "🍕", frase: "Che buona la pizza")
        ], riserva: [
            Parola(testo: "bacca",    gemella: "pacca",    emoji: "🫐", frase: "La bacca è blu"),
            Parola(testo: "bolla",    gemella: "polla",    emoji: "🫧", frase: "La bolla vola"),
            Parola(testo: "pacco",    gemella: "bacco",    emoji: "📦", frase: "Apro il pacco"),
            Parola(testo: "bici",     gemella: "pici",     emoji: "🚲", frase: "Vado in bici"),
            Parola(testo: "porta",    gemella: "borta",    emoji: "🚪", frase: "Apro la porta"),
            Parola(testo: "pesca",    gemella: "besca",    emoji: "🍑", frase: "La pesca è dolce"),
            Parola(testo: "bocca",    gemella: "pocca",    emoji: "👄", frase: "Apro la bocca"),
            Parola(testo: "banana",   gemella: "panana",   emoji: "🍌", frase: "Mangio la banana"),
            Parola(testo: "polpo",    gemella: "bolpo",    emoji: "🐙", frase: "Il polpo nuota"),
            Parola(testo: "pinguino", gemella: "binguino", emoji: "🐧", frase: "Il pinguino scivola"),
            Parola(testo: "pane",     gemella: "bane",     emoji: "🍞", frase: "Il pane è caldo"),
            Parola(testo: "burro",    gemella: "purro",    emoji: "🧈", frase: "Il burro è giallo"),
            Parola(testo: "batti",    gemella: "patti",    emoji: "👏", frase: "Batti le mani", emojiGemella: "🤝")
        ]),
        Percorso(titolo: "Bosco", coppia: "T / D", emoji: "🌲", colore: .green, parole: [
            Parola(testo: "topo",  gemella: "dopo",  emoji: "🐭", frase: "Il topo corre"),
            Parola(testo: "dono",  gemella: "tono",  emoji: "🎁", frase: "Un dono per te"),
            Parola(testo: "dino",  gemella: "tino",  emoji: "🦖", frase: "Il dino è grande"),
            Parola(testo: "torta", gemella: "dorta", emoji: "🎂", frase: "La torta è buona"),
            Parola(testo: "dito",  gemella: "tito",  emoji: "👆", frase: "Muovo il dito"),
            Parola(testo: "moto",  gemella: "modo",  emoji: "🏍️", frase: "La moto va forte"),
            Parola(testo: "tata",  gemella: "data",  emoji: "👩‍🍼", frase: "La tata gioca con me", emojiGemella: "📅")
        ], riserva: [
            Parola(testo: "dado",    gemella: "dato",    emoji: "🎲", frase: "Tiro il dado"),
            Parola(testo: "nodo",    gemella: "noto",    emoji: "🪢", frase: "Faccio un nodo"),
            Parola(testo: "vento",   gemella: "vendo",   emoji: "🌬️", frase: "Il vento soffia"),
            Parola(testo: "tenda",   gemella: "tenta",   emoji: "⛺️", frase: "La tenda è verde"),
            Parola(testo: "mondo",   gemella: "monto",   emoji: "🌍", frase: "Il mondo è grande", emojiGemella: "🏇"),
            Parola(testo: "onda",    gemella: "onta",    emoji: "🌊", frase: "L'onda è alta"),
            Parola(testo: "dente",   gemella: "tente",   emoji: "🦷", frase: "Mi dondola un dente"),
            Parola(testo: "tigre",   gemella: "digre",   emoji: "🐯", frase: "La tigre corre"),
            Parola(testo: "delfino", gemella: "telfino", emoji: "🐬", frase: "Il delfino salta"),
            Parola(testo: "doccia",  gemella: "toccia",  emoji: "🚿", frase: "Faccio la doccia"),
            Parola(testo: "carota",  gemella: "caroda",  emoji: "🥕", frase: "Il coniglio mangia la carota"),
            Parola(testo: "patata",  gemella: "padata",  emoji: "🥔", frase: "La patata è calda"),
            Parola(testo: "gatto",   gemella: "gaddo",   emoji: "🐱", frase: "Il gatto dorme")
        ]),
        Percorso(titolo: "Montagna", coppia: "S / Z", emoji: "🏔️", colore: .orange, parole: [
            Parola(testo: "tazza", gemella: "tassa", emoji: "☕️", frase: "La tazza è piena"),
            Parola(testo: "razzo", gemella: "rasso", emoji: "🚀", frase: "Il razzo vola"),
            Parola(testo: "pazzo", gemella: "passo", emoji: "🤪", frase: "Il pagliaccio è pazzo", emojiGemella: "👣"),
            Parola(testo: "zucca", gemella: "succa", emoji: "🎃", frase: "La zucca è arancione"),
            Parola(testo: "zebra", gemella: "sebra", emoji: "🦓", frase: "La zebra ha le strisce"),
            Parola(testo: "zaino", gemella: "saino", emoji: "🎒", frase: "Il mio zaino è pesante"),
            Parola(testo: "calza", gemella: "calsa", emoji: "🧦", frase: "Metto la calza")
        ], riserva: [
            Parola(testo: "orso",    gemella: "orzo",    emoji: "🐻", frase: "L'orso dorme", emojiGemella: "🌾"),
            Parola(testo: "terzo",   gemella: "terso",   emoji: "🥉", frase: "Arrivo terzo"),
            Parola(testo: "mazzo",   gemella: "masso",   emoji: "💐", frase: "Un mazzo di fiori", emojiGemella: "🪨"),
            Parola(testo: "mazza",   gemella: "massa",   emoji: "🏏", frase: "La mazza colpisce la palla"),
            Parola(testo: "spazzo",  gemella: "spasso",  emoji: "🧹", frase: "Spazzo il pavimento", emojiGemella: "🥳"),
            Parola(testo: "zampa",   gemella: "sampa",   emoji: "🐾", frase: "Il cane dà la zampa"),
            Parola(testo: "zanzara", gemella: "sanzara", emoji: "🦟", frase: "La zanzara punge"),
            Parola(testo: "sedia",   gemella: "zedia",   emoji: "🪑", frase: "Mi siedo sulla sedia"),
            Parola(testo: "sale",    gemella: "zale",    emoji: "🧂", frase: "Metto il sale"),
            Parola(testo: "sole",    gemella: "zole",    emoji: "☀️", frase: "Il sole splende")
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
