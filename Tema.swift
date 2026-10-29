import SwiftUI

enum Tema {
    static func sfondo(_ colore: Color) -> LinearGradient {
        LinearGradient(
            colors: [colore.opacity(0.55), colore.opacity(0.18), .white],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static func titolo(_ size: CGFloat, _ weight: Font.Weight = .heavy) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

/// Pippo, il pappagallo dell'app (immagine "Pippo" negli Assets)
struct PippoView: View {
    var altezza: CGFloat

    var body: some View {
        Image("Pippo")
            .resizable()
            .interpolation(.high)
            .scaledToFit()
            .frame(height: altezza)
            .accessibilityLabel("Pippo il pappagallo")
    }
}

/// Pulsante grande e rotondo
struct PillolaStile: ButtonStyle {
    let colore: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Tema.titolo(26, .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 28)
            .padding(.vertical, 14)
            .background(colore, in: Capsule())
            .shadow(color: colore.opacity(0.4), radius: 6, y: 4)
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.spring(response: 0.25), value: configuration.isPressed)
    }
}

/// Onde che pulsano attorno al microfono mentre registra
struct OndePulsanti: View {
    @State private var anima = false

    var body: some View {
        ZStack {
            ForEach(0..<2) { i in
                Circle()
                    .stroke(Color.red.opacity(0.5), lineWidth: 6)
                    .frame(width: 140, height: 140)
                    .scaleEffect(anima ? 1.7 : 1)
                    .opacity(anima ? 0 : 0.8)
                    .animation(
                        .easeOut(duration: 1.2).repeatForever(autoreverses: false).delay(Double(i) * 0.5),
                        value: anima
                    )
            }
        }
        .onAppear { anima = true }
    }
}

/// Coriandoli di emoji che cadono
struct ConfettiView: View {
    private struct Pezzo: Identifiable {
        let id = UUID()
        let x: CGFloat
        let ritardo: Double
        let durata: Double
        let emoji: String
        let size: CGFloat
    }

    @State private var pezzi: [Pezzo] = (0..<26).map { _ in
        Pezzo(x: .random(in: 0...1),
              ritardo: .random(in: 0...0.6),
              durata: .random(in: 1.4...2.4),
              emoji: ["🎉", "⭐️", "✨", "🎈", "💛"].randomElement()!,
              size: .random(in: 26...44))
    }
    @State private var cade = false

    var body: some View {
        GeometryReader { geo in
            ForEach(pezzi) { p in
                Text(p.emoji)
                    .font(.system(size: p.size))
                    .position(x: p.x * geo.size.width, y: cade ? geo.size.height + 60 : -60)
                    .animation(.easeIn(duration: p.durata).delay(p.ritardo), value: cade)
            }
        }
        .allowsHitTesting(false)
        .onAppear { cade = true }
    }
}

/// Pippo che cammina verso casa
struct PippoTrack: View {
    let totale: Int
    let corrente: Int
    let colore: Color

    var body: some View {
        GeometryReader { geo in
            let margine: CGFloat = 34
            let larghezza = geo.size.width - margine * 2
            let passo = larghezza / CGFloat(max(totale, 1))
            let y = geo.size.height / 2

            ZStack {
                Capsule()
                    .fill(Color.white.opacity(0.8))
                    .frame(width: larghezza, height: 18)
                    .position(x: margine + larghezza / 2, y: y)

                Capsule()
                    .fill(colore)
                    .frame(width: max(CGFloat(corrente) * passo, 0), height: 18)
                    .position(x: margine + CGFloat(corrente) * passo / 2, y: y)

                ForEach(1..<max(totale, 2), id: \.self) { i in
                    Circle()
                        .fill(i <= corrente ? Color.yellow : Color.white)
                        .overlay(Circle().stroke(colore, lineWidth: 3))
                        .frame(width: 18, height: 18)
                        .position(x: margine + CGFloat(i) * passo, y: y)
                }

                Text("🏠")
                    .font(.system(size: 40))
                    .position(x: margine + larghezza, y: y)

                PippoView(altezza: 54)
                    .position(x: margine + CGFloat(corrente) * passo, y: y - 6)
            }
            .animation(.spring(response: 0.6, dampingFraction: 0.6), value: corrente)
        }
    }
}
