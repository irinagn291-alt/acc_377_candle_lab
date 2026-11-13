import Foundation

extension LabStore {
    var widgetSnapshot: WidgetSnapshot {
        let bars = exercise.candles.suffix(12).map { WidgetCandle(open:$0.open,high:$0.high,low:$0.low,close:$0.close) }
        return WidgetSnapshot(title: exercise.topic.rawValue, value: "\(state.mastered.count) / 24", label: "lessons mastered",
            detail: "Lesson \(state.current+1) · \(exercise.title)", footnote: "Synthetic charts · for learning", progress: Double(state.mastered.count)/24, candles: bars)
    }
    func publishWidget() { WidgetStore.publish(widgetSnapshot) }
}

#if DEBUG && targetEnvironment(simulator)
extension LabStore {
    /// Only explicit UI-test launches in disposable simulators can mutate this fixture.
    func applyWidgetQA(_ url: URL) {
        guard ProcessInfo.processInfo.arguments.contains("-WidgetQA"),
              URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.contains(where: { $0.name == "qa" && ["1", "2"].contains($0.value ?? "") }) == true else { return }
        let secondUpdate = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.contains(where: { $0.name == "qa" && $0.value == "2" }) == true
        if secondUpdate { state.current = 1 }
        record(correct: true, answer: "Widget QA completed the criterion")
    }
}
#endif
