@MainActor
enum APIConfig {
    private static let host = "https://api.candlelab.space"
    private static let path = "/api/v1/users/register"

    static func apply() {
        AppConfiguration.configure(host: host, path: path)
    }
}
