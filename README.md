# Parla Giocando 🦜

App iOS (SwiftUI) per aiutare i bambini con **disturbo fonologico** ad allenarsi sulle **coppie minime**: parole che cambiano per un solo suono, come *palla / balla* o *topo / dopo*.

Il bambino aiuta il pappagallo **Pippo** a tornare a casa pronunciando le parole. L'app ascolta con il riconoscimento vocale e capisce se ha detto la parola giusta o la sua "gemella".

## Chi la usa

- **Genitore**: gioca insieme al bambino. Tre percorsi (B/P, T/D, S/Z), ognuno con quattro sfide di difficoltà crescente:
  1. Ascolta e ripeti
  2. Indovina e dì
  3. Le due parole
  4. La frasetta
- **Logopedista**: controlla i progressi e adatta gli esercizi:
  - stelle, partite ed errori per ogni sfida
  - le parole confuse più spesso con la gemella
  - lo storico delle sessioni
  - aggiunta di nuove coppie minime e scelta delle parole attive in ogni percorso

## Struttura

```
AppParlaGiocando.xcodeproj    progetto Xcode
AppParlaGiocando/
  AppParlaGiocandoApp.swift   avvio dell'app e scelta utente
  SceltaUtenteView.swift      schermata iniziale (genitore / logopedista)
  HomeView.swift              percorsi di gioco
  PercorsoView.swift          sfide di un percorso
  LevelView.swift             schermata di gioco
  LivelloViewModel.swift      logica di una sfida e voce di Pippo
  SpeechToTextService.swift   riconoscimento vocale (Speech framework)
  Progresso.swift             stelle e storico delle sessioni
  LogopedistaView.swift       area logopedista
  GestoreParole.swift         parole personalizzate
  GestioneParoleView.swift    gestione delle parole
  Models.swift                parole, percorsi e sfide
  Tema.swift                  colori, stili e componenti grafici
  Assets.xcassets             icona dell'app e immagine di Pippo
```

## Requisiti

- Xcode 27
- iPhone o iPad con microfono. La prima volta l'app chiede il permesso per **microfono** e **riconoscimento vocale**.
