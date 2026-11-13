# Candle Lab

English-only native SwiftUI chart-reading course. iOS 17+, Swift 6. No external Swift packages, server, credentials or network connection required.

Open `CandleLab.xcodeproj`, select CandleLab and an iOS simulator. The checked-in Xcode project is generated from `project.yml` using the factory's `.local/tools/xcodegen/bin/xcodegen`.

## What works

- 24 deterministic exercises across six topics; first launch opens an interactive lesson.
- Candlesticks, price/volume grid, OHLC cursor, pan mode, pinch and button zoom, 1H/3H/6H aggregation, step-by-step replay.
- Full-screen levels, trend lines and zones, undo, accessible precise level placement; annotations stored in data coordinates.
- Answer feedback and a reference-overlay breakdown with explicit criteria and limitations.
- Searchable lesson library, reading completion, accuracy, unique mastery, error history, weak-topic repeat.
- Atomic on-device storage, save/load error recovery and corrupt-save protection. All datasets explicitly synthetic, offline, versioned.
- iPhone/iPad, landscape, Dynamic Type, VoiceOver descriptions and Reduce Motion support.

The teaching instrument names identify synthetic learning series. Displayed prices are arbitrary study units, not actual exchange quotes. No live feed is included.

## Build / QA

Use the factory build shim with `GF_BUILD_LOCK` and a separate DerivedData directory. Run all device commands inside `gf/genesis/simulator_pool.py TEMPLATE_UDID bash qa.sh`; use `GF_SIMULATOR_UDID` inside the script. The reproducible app-specific QA scripts and evidence live at `/Users/belzephyrus/Documents/gambling_factory/output/CandleLab-implementation`.

The unit suite tests all course answers, trend and doji boundaries, annotation grading, replay bounds, persistence, mastery counting and corrupt-save recovery. The UI suite performs answer/review navigation, library completion, relaunch persistence, drawing/undo and replay.

Physical-device installation requires an Apple development signing team; code signing is disabled in the local simulator configuration. No App Store, shipping or production deployment has been performed.

## Factory identity

Local bundle: `com.candlelab.study`. Imported account: `377` (`acc_377`). Request: `cmwc7vio900eyfdftglujbefn`. Localisations set to `en-GB` per the user's later English-only instruction.
