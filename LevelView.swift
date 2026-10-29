import SwiftUI

struct LevelView: View {
    @EnvironmentObject private var progresso: Progresso
    @StateObject private var livello: LivelloViewModel
    @StateObject private var speech = SpeechToTextViewModel()
    @StateObject private var speaker = Speaker()

    init(percorso: Percorso, sfida: Sfida) {
        _livello = StateObject(wrappedValue: LivelloViewModel(percorso: percorso, sfida: sfida))
    }

    var body: some View {
        ZStack {
            Tema.sfondo(livello.percorso.colore).ignoresSafeArea()

            if livello.completato {
                CompletatoView(livello: livello)
            } else {
                gioco
            }

            if livello.feedback == .bravo {
                ConfettiView()
            }
        }
        .navigationTitle(livello.sfida.titolo)
        .navigationBarTitleDisplayMode(.inline)

        // Fermiamo l'ascolto appena il bambino ha finito di rispondere
        .onChange(of: speech.transcript) { _, nuovo in
            if livello.feedback == .ascolto, livello.rispostaCompleta(nuovo) {
                speech.stopRecording()
            }
        }
        // Quando l'ascolto finisce, valutiamo
        .onChange(of: speech.isRecording) { _, inRegistrazione in
            if !inRegistrazione { livello.valuta(speech.transcript) }
        }
        // Se sbaglia, Pippo ripete la parola giusta
        .onChange(of: livello.feedback) { _, nuovo in
            if nuovo == .quasi || nuovo == .riprova { speaker.di(livello.daAscoltare) }
        }
        // Salviamo le stelle a fine sfida
        .onChange(of: livello.completato) { _, finito in
            if finito { progresso.registraSessione(livello) }
        }
        // Pippo dice la parola da solo (tranne in "Indovina")
        .task(id: livello.indice) {
            guard livello.sfida != .indovina, !livello.completato else { return }
            try? await Task.sleep(for: .seconds(0.6))
            if !Task.isCancelled { speaker.di(livello.daAscoltare) }
        }
        // Stop automatico se il bambino resta in silenzio
        .task(id: speech.isRecording) {
            guard speech.isRecording else { return }
            try? await Task.sleep(for: .seconds(livello.secondiMax))
            if !Task.isCancelled { speech.stopRecording() }
        }
        .onDisappear {
            speaker.ferma()
            speech.stopRecording()
        }
        .sensoryFeedback(trigger: livello.feedback) { _, nuovo in
            nuovo == .bravo ? SensoryFeedback.success : nil
        }
    }

    // MARK: - Schermata di gioco

    private var gioco: some View {
        VStack(spacing: 16) {
            PippoTrack(totale: livello.totale,
                       corrente: livello.indice,
                       colore: livello.percorso.colore)
                .frame(height: 64)

            carta
            bolla

            Spacer(minLength: 0)

            micButton

            // Utile in fase di prototipo: vedere cosa capisce il riconoscimento vocale
            Text(speech.transcript.isEmpty ? " " : "Ho sentito: \(speech.transcript)")
                .font(.system(size: 16, design: .rounded))
                .foregroundStyle(.secondary)

            if let errore = speech.errorMessage {
                Text(errore)
                    .font(.system(size: 16, design: .rounded))
                    .foregroundStyle(.red)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }

    private var carta: some View {
        VStack(spacing: 8) {
            Text(livello.parola.emoji)
                .font(.system(size: 150))
                .scaleEffect(livello.feedback == .bravo ? 1.2 : 1)
                .rotationEffect(.degrees(livello.feedback == .bravo ? 8 : 0))
                .animation(.spring(response: 0.4, dampingFraction: 0.35), value: livello.feedback)

            Text(livello.testoVisibile)
                .font(.system(size: livello.sfida == .frase ? 38 : 60, weight: .heavy, design: .rounded))
                .minimumScaleFactor(0.5)
                .lineLimit(2)
                .multilineTextAlignment(.center)

            Button {
                speaker.di(livello.sfida == .indovina ? livello.parola.testo : livello.daAscoltare)
            } label: {
                Label(livello.sfida == .indovina ? "Aiutino" : "Ascolta",
                      systemImage: livello.sfida == .indovina ? "lightbulb.fill" : "speaker.wave.3.fill")
            }
            .buttonStyle(PillolaStile(colore: livello.percorso.colore))
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
        .background(.white, in: RoundedRectangle(cornerRadius: 40))
        .shadow(color: livello.percorso.colore.opacity(0.35), radius: 16, y: 8)
    }

    private var bolla: some View {
        HStack(spacing: 12) {
            Text("🦜").font(.system(size: 44))
            Text(livello.messaggio)
                .font(Tema.titolo(26, .bold))
                .minimumScaleFactor(0.7)
                .multilineTextAlignment(.leading)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, minHeight: 90)
        .background(livello.coloreMessaggio.opacity(0.22), in: RoundedRectangle(cornerRadius: 28))
        .animation(.easeInOut(duration: 0.2), value: livello.feedback)
    }

    private var micButton: some View {
        ZStack {
            if speech.isRecording { OndePulsanti() }

            Button {
                if speech.isRecording {
                    speech.stopRecording()
                } else {
                    speaker.ferma()
                    livello.feedback = .ascolto
                    speech.startRecording(contextualStrings: livello.parolePerRiconoscimento)
                }
            } label: {
                Image(systemName: speech.isRecording ? "stop.fill" : "mic.fill")
                    .font(.system(size: 56, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 140, height: 140)
                    .background(speech.isRecording ? Color.red : livello.percorso.colore, in: Circle())
                    .overlay(Circle().stroke(.white, lineWidth: 6))
                    .shadow(color: .black.opacity(0.2), radius: 10, y: 6)
            }
            .buttonStyle(.plain)
            .disabled(livello.feedback == .bravo || livello.feedback == .passiamo)
        }
        .frame(height: 170)
    }
}

// MARK: - Schermata finale

struct CompletatoView: View {
    @ObservedObject var livello: LivelloViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var apparso = false

    var body: some View {
        ZStack {
            VStack(spacing: 22) {
                Text("🦜").font(.system(size: 130))
                Text("Evviva!").font(Tema.titolo(56))
                Text("Pippo è più vicino a casa!")
                    .font(Tema.titolo(26, .bold))
                    .multilineTextAlignment(.center)

                HStack(spacing: 10) {
                    ForEach(0..<3) { i in
                        Image(systemName: i < livello.stelle ? "star.fill" : "star")
                            .font(.system(size: 64))
                            .foregroundStyle(.yellow)
                            .scaleEffect(apparso ? 1 : 0.1)
                            .animation(.spring(response: 0.5, dampingFraction: 0.5).delay(Double(i) * 0.3),
                                       value: apparso)
                    }
                }

                if livello.confusioniConGemella > 0 {
                    Text("Da riguardare insieme: i suoni \(livello.percorso.coppia)")
                        .font(Tema.titolo(20, .semibold))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                Button("Gioca ancora 🔁") { livello.ricomincia() }
                    .buttonStyle(PillolaStile(colore: livello.percorso.colore))

                Button("Torna ai livelli ➡️") { dismiss() }
                    .buttonStyle(PillolaStile(colore: .orange))
            }
            .padding()

            ConfettiView()
        }
        .onAppear { apparso = true }
    }
}
