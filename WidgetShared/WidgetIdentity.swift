import Foundation

enum WidgetIdentity {
    static let group = "group.com.candlelab.study"
    static let kind = "com.candlelab.study.progress"
    static let scheme = "candlelab"
    static let route = "practice"
    static let displayName = "Candle Lab"
    static let emptyHint = "Start a lesson in your chart lab."
    static let widgetName = "Practice lab"
    static let widgetDescription = "Your current synthetic chart and learning progress."
    static let icon = "chart.xyaxis.line"
    static let theme = "candles"
    static let accent: [Double] = [0.24, 0.65, 1]
    static let background: [Double] = [0.04, 0.07, 0.13]
    static let serif = false
    static var url: URL { URL(string: "\(scheme)://widget/\(route)")! }
    static func accepts(_ url: URL) -> Bool { url.scheme == scheme && url.host == "widget" && url.path == "/" + route }
}
