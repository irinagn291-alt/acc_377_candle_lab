import Foundation

struct Candle: Identifiable, Codable, Equatable, Sendable {
    let id: Int
    let open: Double
    let high: Double
    let low: Double
    let close: Double
    let volume: Double
    static func aggregate(_ values: [Candle], period: Int) -> [Candle] {
        guard period > 0 else { return values }
        return stride(from: 0, to: values.count, by: period).map { start in
            let chunk = Array(values[start..<min(values.count, start + period)])
            return Candle(id: chunk[0].id, open: chunk[0].open,
                          high: chunk.map(\.high).max()!, low: chunk.map(\.low).min()!,
                          close: chunk.last!.close, volume: chunk.reduce(0.0) { $0 + $1.volume })
        }
    }
    var rising: Bool { close >= open }
    var isDoji: Bool { abs(close - open) / max(high - low, 0.001) < 0.12 }
}

enum Topic: String, Codable, CaseIterable, Identifiable {
    case candles = "Candle anatomy", trends = "Reading trends", levels = "Price levels"
    case structures = "Candle structures", volume = "Volume & context", limits = "Limits of analysis"
    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .candles: "chart.bar.xaxis"
        case .trends: "point.topleft.down.to.point.bottomright.curvepath"
        case .levels: "line.3.horizontal"
        case .structures: "square.stack.3d.up"
        case .volume: "waveform.path"
        case .limits: "viewfinder"
        }
    }
    var subtitle: String {
        switch self {
        case .candles: "Read the body. Notice the wick."
        case .trends: "See the sequence, not one candle."
        case .levels: "Map the extremes of a section."
        case .structures: "Give a shape its proper context."
        case .volume: "Add participation to the picture."
        case .limits: "Describe evidence, not certainty."
        }
    }
    var sections: [(String, String)] {
        switch self {
        case .candles: [
            ("Four prices, one story", "Each candle summarises an interval. The body joins the opening and closing prices. The wick reaches the highest and lowest prices in that interval. Green means the close is at or above the open; red means it is below."),
            ("Range is not the body", "Range is high minus low. A candle can have a tiny body and a wide range. Compare the wick tips when looking for the widest range, rather than judging the coloured rectangle."),
            ("Try it", "Use the cursor to inspect O, H, L and C. In this exercise, compare the final candle’s range with all earlier candles. A wide range describes movement; it does not tell you what comes next.")]
        case .trends: [
            ("Look for a sequence", "Higher swing highs and higher swing lows support an upward trend description. Lower highs and lower lows support a downward one. Sideways movement may lack either sequence."),
            ("Our exercise rule", "For a reproducible answer, compare the mean of the first six closing prices with the mean of the last six. A difference greater than 10% of the section’s total range is classified as upward or downward. Smaller differences are classified as sideways."),
            ("Scale changes the story", "A pullback on a short interval can sit inside a longer upward trend. The rule here describes only the displayed training section. It is not a forecast.")]
        case .levels: [
            ("Start with the extremes", "A horizontal level keeps one price across time. It helps compare repeated reactions, but a single extreme alone does not establish a reliable support or resistance level."),
            ("Place your level", "Open Mark up, choose Level and drag at the highest wick. The exercise accepts a horizontal level within 5% of the entire section’s price range around its highest high. Use the cursor’s high for precise accessible placement."),
            ("Lines are approximations", "A zone can express uncertainty better than a perfectly thin line. Trend lines connect two observations. Neither shape guarantees a future reaction.")]
        case .structures: [
            ("Recognising a doji", "A doji has a small body compared with its full high-to-low range. In this course, a body smaller than 12% of the full range meets the doji criterion. A zero-range candle is not used as an example."),
            ("Shape is not a signal", "A small body means the opening and closing prices were close together. It does not prove indecision by every participant, and it does not establish a reversal on its own."),
            ("Read the final candle", "Select the last candle with the cursor. Divide the absolute difference between open and close by high minus low. Compare that ratio with our 12% threshold.")]
        case .volume: [
            ("Participation", "Volume measures activity during each interval. Its units depend on the source: exchange traded units, contracts, or provider-specific counts. The bars here are synthetic activity units."),
            ("Compare like with like", "Compare the mean volume of the first six candles with the mean of the last six. This exercise asks whether participation increased, decreased or stayed broadly similar. It does not ask for a price prediction."),
            ("Context matters", "High volume may accompany buying and selling at the same time. It cannot by itself establish direction. Different sessions and instruments can have very different normal activity levels.")]
        case .limits: [
            ("Observation versus inference", "You can observe a candle’s range, a sequence of closes and the activity recorded by a source. Future movement is not directly visible in those observations."),
            ("A useful description", "Match the section to a statement about what happened. Prefer ‘closing prices rose across this section’ over any claim that the next candle must rise. This course grades the stated criterion only."),
            ("Ambiguity is normal", "Pattern boundaries are subjective, time frames can disagree, and a synthetic example cannot represent market complexity. Practise explaining your criterion and its limitations.")]
        }
    }
}

struct Exercise: Identifiable, Sendable {
    let id: Int
    var topic: Topic { Topic.allCases[id / 4] }
    var variant: Int { id % 4 }
    var instrument: String { ["EUR / USD", "GBP / USD", "USD / JPY"][id % 3] }
    var title: String {
        switch topic {
        case .candles: "Read the final candle"
        case .trends: "Find the direction"
        case .levels: "Mark the highest high"
        case .structures: "Name the structure"
        case .volume: "Compare participation"
        case .limits: "Describe the evidence"
        }
    }
    var prompt: String {
        switch topic {
        case .candles: "Does the final candle have the widest high–low range?"
        case .trends: "How do closing prices move across this section?"
        case .levels: "Place a horizontal level at the highest wick in the full section."
        case .structures: "Does the final candle meet our doji criterion?"
        case .volume: "Compare the first six and last six volume bars."
        case .limits: "Which statement is supported by this section?"
        }
    }
    var choices: [String] {
        switch topic {
        case .candles: ["Widest range", "Not the widest"]
        case .trends: ["Upward", "Downward", "Sideways"]
        case .levels: []
        case .structures: ["Doji", "Regular body"]
        case .volume: ["Activity increased", "Activity decreased"]
        case .limits: ["Closes rose overall", "Closes fell overall", "The next candle is certain"]
        }
    }
    var candles: [Candle] {
        var result: [Candle] = []
        let sign = variant % 2 == 0 ? 1.0 : -1.0
        let base = instrument == "USD / JPY" ? 150.0 : (instrument == "GBP / USD" ? 128.0 : 108.0)
        for i in 0..<36 {
            let drift = Double(i) * 0.24 * sign
            let wave = sin(Double(i) * 0.67 + Double(variant)) * 0.72
            let open = base + drift + wave
            var close = open + sin(Double(i) * 1.4 + 0.7) * 0.48 + sign * 0.18
            var high = max(open, close) + 0.26 + Double(i % 4) * 0.08
            var low = min(open, close) - 0.28 - Double(i % 3) * 0.09
            if i == 35 && topic == .structures && variant % 2 == 0 {
                close = open + 0.03; high = open + 0.8; low = open - 0.8
            }
            if i == 35 && topic == .structures && variant % 2 == 1 {
                close = open - 1.2; high = open + 0.15; low = close - 0.15
            }
            if i == 35 && topic == .candles && variant % 2 == 0 {
                high += 1.6; low -= 1.6
            }
            if i == 35 && topic == .candles && variant % 2 == 1 {
                close = open + 0.1; high = open + 0.15; low = open - 0.15
            }
            let vol = 160 + (sign > 0 ? Double(i) : Double(35 - i)) * 12 + Double(i % 5) * 7
            result.append(Candle(id: i, open: open, high: high, low: low, close: close, volume: vol))
        }
        return result
    }
    var correctChoice: Int {
        switch topic {
        case .candles: candles.last!.high - candles.last!.low >= candles.map { $0.high - $0.low }.max()! ? 0 : 1
        case .trends: Self.trend(candles)
        case .levels: 0
        case .structures: candles.last!.isDoji ? 0 : 1
        case .volume: candles.suffix(6).map(\.volume).reduce(0, +) > candles.prefix(6).map(\.volume).reduce(0, +) ? 0 : 1
        case .limits: Self.trend(candles) == 0 ? 0 : 1
        }
    }
    static func trend(_ candles: [Candle]) -> Int {
        guard candles.count >= 12 else { return 2 }
        let endMean: Double = candles.suffix(6).reduce(0.0) { $0 + $1.close } / 6.0
        let startMean: Double = candles.prefix(6).reduce(0.0) { $0 + $1.close } / 6.0
        let delta: Double = endMean - startMean
        let range = candles.map(\.high).max()! - candles.map(\.low).min()!
        return abs(delta) <= range * 0.1 ? 2 : (delta > 0 ? 0 : 1)
    }
    var highest: Double { candles.map(\.high).max()! }
    var tolerance: Double { (highest - candles.map(\.low).min()!) * 0.05 }
    func accepts(_ marks: [Mark]) -> Bool { marks.contains { $0.kind == .level && abs($0.y1 - highest) <= tolerance } }
    var explanation: String {
        switch topic {
        case .candles: "The final range is \(String(format: "%.2f", candles.last!.high - candles.last!.low)) units. Compare both wick tips, not only the body. \(correctChoice == 0 ? "It is the widest in this section." : "An earlier candle has a wider range.")"
        case .trends: "The last six closes average \(String(format: "%.2f", candles.suffix(6).map(\.close).reduce(0, +) / 6)); the first six average \(String(format: "%.2f", candles.prefix(6).map(\.close).reduce(0, +) / 6)). Their difference exceeds 10% of the section’s range. This describes the section, not its next move."
        case .levels: "The highest wick is \(String(format: "%.2f", highest)). A level within ±\(String(format: "%.2f", tolerance)) meets this exercise’s tolerance. A single high is an observation, not proof of future resistance."
        case .structures: "The final body is \(Int(abs(candles.last!.close - candles.last!.open) / (candles.last!.high - candles.last!.low) * 100))% of its range. Our doji threshold is below 12%. The shape alone does not establish a reversal."
        case .volume: "Average activity \(correctChoice == 0 ? "increased" : "decreased") between the first six and last six candles. Volume describes participation. It cannot determine direction by itself."
        case .limits: "The closes \(correctChoice == 0 ? "rose" : "fell") overall in this training section. That is observable. No section makes the next candle certain; other intervals may tell a different story."
        }
    }
    func date(at index: Int) -> String {
        let day = 4 + id * 2 + index / 24
        return String(format: "Jun %02d, 2024 · %02d:00 UTC", day <= 30 ? day : day - 30, index % 24)
            .replacingOccurrences(of: "Jun", with: day <= 30 ? "Jun" : "Jul")
    }
    static let all = (0..<24).map { Exercise(id: $0) }
}

enum MarkKind: String, Codable, CaseIterable { case level = "Level", trend = "Trend line", zone = "Zone" }
struct Mark: Codable, Identifiable, Equatable {
    var id = UUID()
    let kind: MarkKind
    let x1: Double
    let y1: Double
    let x2: Double
    let y2: Double
}
struct Attempt: Codable, Identifiable {
    var id = UUID()
    let exerciseID: Int
    let correct: Bool
    let answer: String
    var date = Date()
}
struct SavedState: Codable {
    var current = 0
    var attempts: [Attempt] = []
    var readTopics: Set<String> = []
    var marks: [String: [Mark]] = [:]
    var replay: [String: Int] = [:]
    var started = false
    var mastered: Set<Int> { Set(attempts.filter(\.correct).map(\.exerciseID)) }
}

// Future providers must supply provenance; the shipping course uses only its bundled synthetic provider.
protocol CandleProvider: Sendable {
    func candles(for exercise: Exercise) async throws -> [Candle]
    var sourceLabel: String { get }
}
struct TrainingProvider: CandleProvider {
    let sourceLabel = "Candle Lab synthetic course · Dataset v1 · Offline"
    func candles(for exercise: Exercise) async throws -> [Candle] { exercise.candles }
}

@MainActor @Observable final class LabStore {
    var state = SavedState()
    var loading = true
    var error: String?
    var loadFailed = false
    let url: URL
    init(url: URL? = nil) {
        self.url = url ?? URL.applicationSupportDirectory.appending(path: "CandleLab/progress.json")
    }
    func load() {
        defer { loading = false }
        do {
            if FileManager.default.fileExists(atPath: url.path) {
                state = try JSONDecoder().decode(SavedState.self, from: Data(contentsOf: url))
                state.current = min(23, max(0, state.current))
            }
            error = nil; loadFailed = false; publishWidget()
        } catch { self.error = "Your saved progress could not be opened. Retry, or reset the local save to start again."; loadFailed = true }
    }
    func save() {
        guard !loadFailed else { return }
        do {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try JSONEncoder().encode(state).write(to: url, options: .atomic)
            error = nil; publishWidget()
        } catch { self.error = "Progress could not be saved. Your current session is still available. Free some storage and retry." }
    }
    func reset() { state = SavedState(); loadFailed = false; save() }
    var exercise: Exercise { Exercise(id: state.current) }
    var marks: [Mark] {
        get { state.marks[String(state.current)] ?? [] }
        set { state.marks[String(state.current)] = newValue; save() }
    }
    var revealed: Int {
        get { min(36, max(6, state.replay[String(state.current)] ?? 36)) }
        set { state.replay[String(state.current)] = min(36, max(6, newValue)); save() }
    }
    func select(_ id: Int) { state.current = min(23, max(0, id)); state.started = true; save() }
    func record(correct: Bool, answer: String) {
        state.attempts.append(Attempt(exerciseID: state.current, correct: correct, answer: answer)); state.started = true; save()
    }
    func accuracy(topic: Topic? = nil) -> Int? {
        let rows = state.attempts.filter { topic == nil || Exercise(id: $0.exerciseID).topic == topic }
        guard !rows.isEmpty else { return nil }
        return Int((Double(rows.filter(\.correct).count) / Double(rows.count) * 100).rounded())
    }
    var weakest: Topic {
        let attempted = Topic.allCases.filter { accuracy(topic: $0) != nil }
        return attempted.min { (accuracy(topic: $0) ?? 0) < (accuracy(topic: $1) ?? 0) } ?? .candles
    }
}
