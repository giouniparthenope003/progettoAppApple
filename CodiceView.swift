import SwiftUI
import CryptoKit

/// Il codice di 4 cifre che protegge l'area logopedista.
/// Viene salvato solo come impronta (hash), mai in chiaro.
enum CodiceLogopedista {
    static let lunghezza = 4
    private static let chiave = "logopedista.codice"

    static var impostato: Bool {
        UserDefaults.standard.string(forKey: chiave) != nil
    }

    static func verifica(_ codice: String) -> Bool {
        UserDefaults.standard.string(forKey: chiave) == impronta(codice)
    }

    static func imposta(_ codice: String) {
        UserDefaults.standard.set(impronta(codice), forKey: chiave)
    }

    static func rimuovi() {
        UserDefaults.standard.removeObject(forKey: chiave)
    }

    private static func impronta(_ codice: String) -> String {
        SHA256.hash(data: Data(codice.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
    }
}

/// Tastierino per inserire, creare o cambiare il codice
struct CodiceView: View {
    private enum Fase: Equatable {
        case inserisci
        case nuovo
        case conferma(primo: String)
    }

    let annulla: () -> Void
    let sblocca: () -> Void

    @State private var fase: Fase
    @State private var cifre = ""
    @State private var errore: String?
    @State private var scosse = 0

    @State private var mostraRecupero = false
    @State private var rispostaRecupero = ""
    @State private var domanda = (a: 7, b: 8)

    /// - Parameter cambio: true per impostare un nuovo codice (dall'area logopedista)
    init(cambio: Bool = false, annulla: @escaping () -> Void, sblocca: @escaping () -> Void) {
        self.annulla = annulla
        self.sblocca = sblocca
        let iniziale: Fase = (cambio || !CodiceLogopedista.impostato) ? .nuovo : .inserisci
        _fase = State(initialValue: iniziale)
    }

    private var titolo: String {
        switch fase {
        case .inserisci: "Inserisci il codice"
        case .nuovo:     "Crea un codice"
        case .conferma:  "Conferma il codice"
        }
    }

    private var sottotitolo: String {
        switch fase {
        case .inserisci: "Area riservata al logopedista"
        case .nuovo:     "Scegli \(CodiceLogopedista.lunghezza) cifre: serviranno per entrare nell'area logopedista"
        case .conferma:  "Inserisci di nuovo le stesse cifre"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: annulla) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.primary)
                        .frame(width: 44, height: 44)
                        .background(Color(.secondarySystemBackground), in: Circle())
                }
                .accessibilityLabel("Indietro")
                Spacer()
            }
            .padding(.horizontal)

            Spacer(minLength: 12)

            Image(systemName: "lock.fill")
                .font(.system(size: 44))
                .foregroundStyle(.purple)
                .padding(.bottom, 16)

            Text(titolo)
                .font(.title2.weight(.bold))
            Text(sottotitolo)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.top, 4)

            // Pallini
            HStack(spacing: 20) {
                ForEach(0..<CodiceLogopedista.lunghezza, id: \.self) { i in
                    Circle()
                        .fill(i < cifre.count ? Color.purple : Color.clear)
                        .overlay(Circle().stroke(Color.purple, lineWidth: 2))
                        .frame(width: 16, height: 16)
                }
            }
            .modifier(Scuoti(quantita: CGFloat(scosse)))
            .padding(.top, 28)

            Text(errore ?? " ")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.red)
                .padding(.top, 12)

            Spacer(minLength: 12)

            tastierino

            Button("Hai dimenticato il codice?") {
                domanda = (Int.random(in: 6...9), Int.random(in: 6...9))
                rispostaRecupero = ""
                mostraRecupero = true
            }
            .font(.footnote)
            .opacity(fase == .inserisci ? 1 : 0)
            .disabled(fase != .inserisci)
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .sensoryFeedback(.error, trigger: scosse)
        .alert("Domanda per adulti", isPresented: $mostraRecupero) {
            TextField("Risposta", text: $rispostaRecupero)
                .keyboardType(.numberPad)
            Button("Annulla", role: .cancel) {}
            Button("Conferma") { verificaRecupero() }
        } message: {
            Text("Quanto fa \(domanda.a) × \(domanda.b)? Se rispondi correttamente potrai creare un nuovo codice.")
        }
    }

    // MARK: Tastierino

    private var tastierino: some View {
        let righe = [["1", "2", "3"], ["4", "5", "6"], ["7", "8", "9"], ["", "0", "⌫"]]
        return VStack(spacing: 16) {
            ForEach(righe, id: \.self) { riga in
                HStack(spacing: 24) {
                    ForEach(riga, id: \.self) { tasto in
                        TastoCodice(tasto: tasto) { premi(tasto) }
                    }
                }
            }
        }
    }

    private func premi(_ tasto: String) {
        switch tasto {
        case "":
            return
        case "⌫":
            if !cifre.isEmpty { cifre.removeLast() }
        default:
            guard cifre.count < CodiceLogopedista.lunghezza else { return }
            errore = nil
            cifre.append(tasto)
            if cifre.count == CodiceLogopedista.lunghezza {
                completato()
            }
        }
    }

    private func completato() {
        switch fase {
        case .inserisci:
            if CodiceLogopedista.verifica(cifre) {
                sblocca()
            } else {
                sbagliato("Codice errato, riprova")
            }
        case .nuovo:
            fase = .conferma(primo: cifre)
            cifre = ""
        case .conferma(let primo):
            if cifre == primo {
                CodiceLogopedista.imposta(cifre)
                sblocca()
            } else {
                fase = .nuovo
                sbagliato("I codici non coincidono, ricomincia")
            }
        }
    }

    private func sbagliato(_ messaggio: String) {
        errore = messaggio
        withAnimation(.default) { scosse += 1 }
        Task {
            try? await Task.sleep(for: .seconds(0.3))
            cifre = ""
        }
    }

    private func verificaRecupero() {
        if Int(rispostaRecupero.trimmingCharacters(in: .whitespaces)) == domanda.a * domanda.b {
            CodiceLogopedista.rimuovi()
            cifre = ""
            errore = nil
            fase = .nuovo
        } else {
            sbagliato("Risposta sbagliata")
        }
    }
}

/// Un tasto rotondo del tastierino
private struct TastoCodice: View {
    let tasto: String
    let azione: () -> Void

    var body: some View {
        Button(action: azione) {
            Group {
                if tasto == "⌫" {
                    Image(systemName: "delete.left")
                        .font(.system(size: 24))
                } else {
                    Text(tasto)
                        .font(.system(size: 32, weight: .medium, design: .rounded))
                }
            }
            .foregroundStyle(.primary)
            .frame(width: 78, height: 78)
            .background(
                Circle().fill(tasto.isEmpty || tasto == "⌫" ? Color.clear : Color(.secondarySystemBackground))
            )
        }
        .buttonStyle(.plain)
        .disabled(tasto.isEmpty)
        .accessibilityLabel(tasto == "⌫" ? "Cancella" : tasto)
    }
}

/// Fa tremare i pallini quando il codice è sbagliato
private struct Scuoti: GeometryEffect {
    var quantita: CGFloat
    var animatableData: CGFloat {
        get { quantita }
        set { quantita = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: 10 * sin(quantita * .pi * 4), y: 0))
    }
}

#Preview {
    CodiceView(annulla: {}, sblocca: {})
}
