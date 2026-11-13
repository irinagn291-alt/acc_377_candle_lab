# Candle Lab

Native offline candle-reading course. iOS 17+, Swift 6, SwiftUI. English-only, explicitly confirmed by user on 13 November 2026. Account acc_377 is factory account 377, not a bundle identifier. Local development bundle: com.candlelab.study.

## Product
Four preserved tabs: Overview, Practice, Lessons, Progress. First launch opens the first interactive exercise. Twenty-four exercises in six topics: candle anatomy, trends, levels, structures, volume, and interpretation limits. Each exercise uses a deterministic, explicitly synthetic set of 36 one-hour candles, with dates and source visible. No live market claims or external data key required.

## Screens and mechanics
- Overview: course progress, resume, instrument mini charts, topic collection.
- Practice: instrument and period selectors; candle chart, price axis, volume, cursor OHLC, pan and pinch zoom plus accessible controls; replay one candle at a time; tasks and checked answers.
- Markup: full-screen horizontal level, trend line, rectangular zone, undo; data-coordinate annotations persist per exercise. Accessible level placement at the selected candle high.
- Review: reference overlays vs saved own annotations; criterion, explanation and ambiguity; replay comparison.
- Lessons: six substantial short lessons with four practice activities each, reading completion.
- Progress: accuracy by topic, unique exercise mastery, read lessons, recent error history and weak-topic repeat.

Learning criteria are deterministic: compare first/last groups of closing prices, recognise final doji by body/range ratio, identify largest range candle or increasing volume, and place a horizontal line within 5% of the full price range around the highest high. Wrong attempts remain in history; mastery counts unique correct exercises, never spendable points.

## Visual system
Background #101522, panels #1A2233, raised #263147, blue #438BFF, candles #28C991/#EF5968, text #F2F5FA, muted #8F9CB2. Eight-point spacing, 16-point horizontal margins, 44-point controls, compact terminal typography. Custom vector candle brand, thin grid, small corners. Adaptive iPhone/iPad and landscape. VoiceOver descriptions, Dynamic Type, Reduce Motion. English left-to-right chart chronology.

## State
Atomic JSON in Application Support saves attempts, readings, active exercise, replay position and annotations. Loading state and recoverable read/write errors. Corrupt save remains intact until explicit reset; no silent data deletion. Entire course works offline. No remote feed in this release; provider boundary included for future labelled datasets.

## Isolation and QA
Only this app and output/CandleLab-implementation are authored. Shared factory build locks and simulator_pool required. Separate DerivedData, test results and screenshots. No shipping, submission, production deployment or monetisation.
