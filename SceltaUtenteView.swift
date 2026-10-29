
import SwiftUI

/// Chi sta usando l'app in questo momento
enum Utente: String, CaseIterable, Identifiable {
    case genitore
    case logopedista

    var id: String { rawValue }
}

// MARK: - Schermata iniziale

/// Schermata iniziale: il genitore entra a giocare, il logopedista va ai progressi
struct SceltaUtenteView: View {
    let scegli: (Utente) -> Void

    @Environment(\.accessibilityReduceMotion) private var riduciMovimento
    @State private var saltella = false

    var body: some View {
        ZStack {
            SfondoIsola()

            VStack(spacing: 0) {
                Spacer(minLength:8)

                // Pippo sulla sua isoletta, con il fumetto
                ZStack(alignment: .bottom) {
                    Ellipse()
                        .fill(LinearGradient(colors: [Color(red: 1.0, green: 0.86, blue: 0.45),
                                                      Color(red: 0.96, green: 0.72, blue: 0.30)],
                                             startPoint: .top, endPoint: .bottom))
                        .frame(width: 230, height: 50)
                        .shadow(color: .black.opacity(0.12), radius: 6, y: 4)
                        .offset(y: 18)

                    PippoView(altezza: 190)
                        .offset(y: saltella ? -8 : 2)
                }
                .overlay(alignment: .topTrailing) {
                    FumettoPippo()
                        .offset(x: 55, y: -54)
                }
                .padding(.top, 60)
                .padding(.bottom, 40)

                BottoneGenitore { scegli(.genitore) }
                    .padding(.horizontal, 20)

                BottoneLogopedista { scegli(.logopedista) }
                    .padding(.top, 18)

                Spacer(minLength: 16)
            }
        }
        .onAppear {
            guard !riduciMovimento else { return }
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                saltella = true
            }
        }
    }
}

// MARK: - Pulsanti

/// Il pulsante principale, grande e invitante: si entra a giocare
struct BottoneGenitore: View {
    let azione: () -> Void

    @Environment(\.accessibilityReduceMotion) private var riduciMovimento
    @State private var pulsa = false

    private let arancio = Color(red: 1.0, green: 0.58, blue: 0.16)
    private let arancioScuro = Color(red: 0.98, green: 0.36, blue: 0.18)

    var body: some View {
        Button(action: azione) {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("👨‍👩‍👧  GENITORE")
                        .font(Tema.titolo(15, .heavy))
                        .tracking(1)
                        .foregroundStyle(.white.opacity(0.9))

                    Text("Giochiamo!")
                        .font(Tema.titolo(40))
                        .foregroundStyle(.white)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                        .shadow(color: arancioScuro.opacity(0.6), radius: 0, y: 2)

                    Text("Allena le parole insieme al tuo bambino")
                        .font(Tema.titolo(16, .semibold))
                        .foregroundStyle(.white.opacity(0.95))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)


ZStack {
                    Circle()
                        .fill(.white.opacity(0.35))
                        .frame(width: 96, height: 96)
                        .scaleEffect(pulsa ? 1.15 : 0.9)
                        .opacity(pulsa ? 0 : 1)
                    Circle()
                        .fill(.white)
                        .frame(width: 80, height: 80)
                        .shadow(color: arancioScuro.opacity(0.4), radius: 6, y: 4)
                    Image(systemName: "play.fill")
                        .font(.system(size: 34, weight: .heavy))
                        .foregroundStyle(arancioScuro)
                        .offset(x: 3)
                }
                .scaleEffect(pulsa ? 1.06 : 1)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 26)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 36, style: .continuous)
                    .fill(LinearGradient(colors: [arancio, arancioScuro],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
            )
            // decorazioni: stelline
            .overlay(alignment: .topTrailing) {
                Image(systemName: "sparkles")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(14)
            }
            .overlay(alignment: .bottomLeading) {
                Image(systemName: "star.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(.yellow.opacity(0.9))
                    .offset(x: 150, y: -12)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 36, style: .continuous)
                    .stroke(.white.opacity(0.7), lineWidth: 3)
            )
            .shadow(color: arancioScuro.opacity(0.45), radius: 16, y: 10)
        }
        .buttonStyle(StilePremuto())
        .accessibilityLabel("Genitore. Giochiamo! Allena le parole insieme al tuo bambino")
        .onAppear {
            guard !riduciMovimento else { return }
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: false)) {
                pulsa = true
            }
        }
    }
}

/// Il pulsante secondario, più piccolo e discreto
struct BottoneLogopedista: View {
    let azione: () -> Void

    var body: some View {
        Button(action: azione) {
            HStack(spacing: 10) {
                Image(systemName: "stethoscope")
                    .font(.system(size: 18, weight: .bold))
                Text("Sono il logopedista")
                    .font(Tema.titolo(18, .bold))
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .heavy))
                    .opacity(0.6)
            }
            .foregroundStyle(.purple)
            .padding(.horizontal, 22)
            .padding(.vertical, 14)
            .background(.white.opacity(0.9), in: Capsule())
            .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
        }
        .buttonStyle(StilePremuto())
    }
}

/// Il pulsante si rimpicciolisce un po' quando lo si tocca
struct StilePremuto: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Fumetto


struct FumettoPippo: View {
    var body: some View {
        let ciao = Text("Ciao!").foregroundStyle(Color(red: 0.36, green: 0.68, blue: 0.13))
        let giochiamo = Text("Giochiamo?").foregroundStyle(Color(red: 0.98, green: 0.42, blue: 0.16))
        return Text("\(ciao)\n\(giochiamo)")
            .font(Tema.titolo(24, .heavy))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(alignment: .bottomLeading) {
                Triangolo()
                    .fill(.white)
                    .frame(width: 22, height: 20)
                    .rotationEffect(.degrees(20))
                    .offset(x: 14, y: 14)
            }
            .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
    }
}

struct Triangolo: Shape {
    func path(in r: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: r.minX, y: r.minY))
            p.addLine(to: CGPoint(x: r.maxX, y: r.minY))
            p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
            p.closeSubpath()
        }
    }
}

// MARK: - Sfondo: cielo, nuvole e mare

struct SfondoIsola: View {
    @Environment(\.accessibilityReduceMotion) private var riduciMovimento
    @State private var muovi = false

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                LinearGradient(colors: [Color(red: 0.29, green: 0.70, blue: 0.97),
                                        Color(red: 0.62, green: 0.87, blue: 1.0)],
                               startPoint: .top, endPoint: .bottom)

                Nuvola(scala: 1.0)
                    .position(x: geo.size.width * 0.18 + (muovi ? 18 : -10), y: geo.size.height * 0.10)
                Nuvola(scala: 0.75)
                    .position(x: geo.size.width * 0.85 + (muovi ? -14 : 12), y: geo.size.height * 0.20)
                Nuvola(scala: 0.6)
                    .position(x: geo.size.width * 0.12 + (muovi ? 10 : -8), y: geo.size.height * 0.38)

                // Mare
                ZStack(alignment: .top) {
                    Onda(fase: muovi ? 1 : 0)
                        .fill(Color(red: 0.55, green: 0.85, blue: 0.95))
                        .offset(y: -10)
                    Onda(fase: muovi ? 0.5 : 1.5)
                        .fill(LinearGradient(colors: [Color(red: 0.13, green: 0.62, blue: 0.86),
                                                      Color(red: 0.05, green: 0.47, blue: 0.75)],
                                             startPoint: .top, endPoint: .bottom))
                }
                .frame(height: geo.size.height * 0.30)
            }
            .ignoresSafeArea()
        }
        .ignoresSafeArea()
        .onAppear {
            guard !riduciMovimento else { return }
            withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true)) {
                muovi = true
            }
        }
    }
}

struct Nuvola: View {
    var scala: CGFloat

    var body: some View {
        ZStack {
            Capsule().frame(width: 130, height: 40).offset(y: 14)
            Circle().frame(width: 56, height: 56).offset(x: -26, y: 2)
            Circle().frame(width: 70, height: 70).offset(x: 14, y: -6)
        }
        .foregroundStyle(.white.opacity(0.95))
        .scaleEffect(scala)
        .allowsHitTesting(false)
    }
}

/// Onda del mare, animabile
struct Onda: Shape {
    var fase: CGFloat
    var animatableData: CGFloat {
        get { fase }
        set { fase = newValue }
    }


func path(in r: CGRect) -> Path {
        Path { p in
            let ampiezza: CGFloat = 9
            let lunghezza = r.width / 1.3
            p.move(to: CGPoint(x: 0, y: ampiezza))
            for x in stride(from: CGFloat(0), through: r.width, by: 3) {
                let y = ampiezza + sin((x / lunghezza + fase) * 2 * .pi) * ampiezza
                p.addLine(to: CGPoint(x: x, y: y))
            }
            p.addLine(to: CGPoint(x: r.width, y: r.height))
            p.addLine(to: CGPoint(x: 0, y: r.height))
            p.closeSubpath()
        }
    }
}

#Preview {
    SceltaUtenteView { _ in }
}

