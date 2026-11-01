# Respring

App iOS che riavvia SpringBoard con **lo stesso metodo** di [jailbreak.party/respring](https://jailbreak.party/respring): la pagina web pubblica di [neonmodder123](https://github.com/neonmodder123/neonmodder123.github.io) (MIT).

Non è un jailbreak e non scrive file di sistema. Chiude e riavvia SpringBoard, così un tweak o un font già applicato torna visibile. Se il dispositivo è jailbroken, il jailbreak resta attivo: è un respring, non un reboot.

Funziona da iOS 26 in poi (Liquid Glass), iPhone e iPad. L’interfaccia è lo slider di spegnimento di iOS 27: a fine corsa non spegne il telefono, avvia il respring. Su alcune versioni la pagina in Safari è più efficace della web view interna.

## Cosa contiene la repo

| File | Ruolo |
| --- | --- |
| `project.yml` | Progetto XcodeGen |
| `.github/workflows/build.yml` | Build su GitHub Actions, IPA **non firmata** da Apple |
| `Respring/` | App SwiftUI + `respring.html` |

## IPA non firmata, da GitHub

1. Crea un repository vuoto (branch `main`).
2. Carica **il contenuto** di questa cartella, non una cartella annidata. `project.yml` deve stare nella root.
3. Apri **Actions**. Il workflow *Build unsigned IPA* parte al push. Puoi anche lanciarlo a mano con *Run workflow*.
4. A fine build scarica l’artifact **Respring-unsigned** (`Respring-unsigned.ipa`).

Il runner è `macos-26` (Xcode 26, serve per `glassEffect`) con XcodeGen e `xcodebuild` in Release, `CODE_SIGNING_ALLOWED=NO`. L’IPA è uno zip `Payload/Respring.app` senza firma Apple.

## Installazione

L’IPA va rifirmata dal tool che usi sul tuo dispositivo:

- Sideloadly, Feather, Esign, GBox, LiveContainer
- TrollStore, se la tua versione di iOS lo supporta

Bundle id: `local.respring.app`. Se il sideloader chiede un id libero, cambialo in `project.yml` (`PRODUCT_BUNDLE_IDENTIFIER`) e rifai la build.

## Credito

Il metodo di respring è di **neonmodder123**, licenza MIT. Va mantenuto il credito nel file `Respring/respring.html` se lo modifichi.
