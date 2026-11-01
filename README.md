# RespringSlide

A minimal iOS respring experiment with a full-screen, power-off-style slider and two selectable visual modes.

## Interface modes

Use the top-right `…` menu to switch between the two interfaces. The selection is persisted with `AppStorage`.

- **Liquid Glass — app attuale:** the slider track, its thumb, the upper respring capsule, the cancel button, and the `…` selector use the same native interactive SwiftUI Liquid Glass treatment (`.glassEffect(.regular.interactive())`). The main controls are hosted in a `GlassEffectContainer` so the system can render their material together. The moving highlight on “Scorri per spegnere” follows the slider thumb.
- **OldOS — iOS 6:** a dark skeuomorphic recreation of the iOS 6-style power slider, with a graphite shell, beveled silver arrow thumb, and the original OldOS-style animated grey-to-white text sheen. Its dark palette reuses the blue-grey chrome tones shown in the supplied OldOS/Safari source. The interface remains full-screen on current iPhone layouts and keeps the modern top-right mode selector.

The Liquid Glass mode uses Apple's public SwiftUI `glassEffect` API. The actual refraction, highlights, and touch response are system-rendered; the app does not draw a static imitation over the glass.

## App identity

- **Display name:** `RespringSlide`
- **Bundle identifier:** `com.iamgasgass.respringslide`
- **Version:** `1.0`
- **Build:** `1`

## Respring engine and limitations

The local `WKWebView` document reproduces the iframe / `backdrop-filter` / WebKit pressure technique associated with `jailbreak.party/respring` and the publicly attributed WebKit research implementation.

This is an experimental WebKit-triggered respring attempt, **not an Apple-supported API**. iOS does not expose a public API that lets an ordinary app restart SpringBoard. Depending on the exact iOS build, device, WebKit process policy, and memory pressure, this technique may only terminate the WebContent process or app, may do nothing, or may cause SpringBoard to restart. It is not guaranteed on iOS 27.0.1 or any other release. The embedded loop starts only after the user completes the slider and explicitly confirms. Save open documents and data before testing.

The IPA produced by GitHub Actions is **unsigned**. It cannot be installed directly on a stock iPhone until signed with a valid certificate or an appropriate sideloading workflow. This repository contains no certificates, provisioning profiles, or signing secrets.

## Build locally

Requirements: Xcode 27, iOS 26+ SDK, and [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```sh
brew install xcodegen
xcodegen generate --spec project.yml
xcodebuild \
  -project RespringSlide.xcodeproj \
  -scheme RespringSlide \
  -configuration Release \
  -sdk iphoneos \
  -destination 'generic/platform=iOS' \
  -derivedDataPath build \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY='' \
  clean build
```

Package the app into an unsigned IPA:

```sh
mkdir -p staging/Payload
cp -R build/Build/Products/Release-iphoneos/RespringSlide.app staging/Payload/
(cd staging && zip -qry ../RespringSlide-unsigned.ipa Payload)
```

## Build on GitHub Actions

1. Push the repository to `main`, create a pull request, or run **Actions → Build unsigned IPA → Run workflow**.
2. Download the `RespringSlide-unsigned-ipa` artifact from the completed workflow.
3. Push a tag such as `v1.0.0` to attach the IPA to a GitHub Release automatically.

## Project structure

```text
.
├── .github/workflows/build.yml
├── RespringSlide/
│   ├── Assets.xcassets/AppIcon.appiconset/
│   ├── Respring/RespringPayloadView.swift
│   ├── RespringSlideApp.swift
│   └── Views/PowerOffView.swift
└── project.yml
```

## References and attribution

- Apple, [Applying Liquid Glass to custom views](https://developer.apple.com/documentation/swiftui/applying-liquid-glass-to-custom-views).
- Original respring technique reference: <https://jailbreak.party/respring>.
- Public Swift implementation documenting the WebKit technique: <https://github.com/rooootdev/mond/blob/main/mond/helpers/utils.swift>.
- **OldOS visual reference:** Zane Kleinberg (`@zzanehip`), [The OldOS Project](https://github.com/zzanehip/The-OldOS-Project), especially `OldOS/OldOS/LockScreen.swift` (the metallic iOS 6-era slide control and animated “slide to unlock” sheen) and `OldOS/OldOS/Safari.swift` (blue-grey chrome palette). The upstream README states Creative Commons Attribution 4.0; see <https://creativecommons.org/licenses/by/4.0/>. RespringSlide contains an independent SwiftUI adaptation of these visual details, not the OldOS source files or its bundled assets.

The app UI is a SwiftUI recreation and is not Apple's original SpringBoard source code. The OldOS mode is an adaptation of the design language and slider treatment in the cited project, not a claim that it is Apple's original iOS 6 source.
