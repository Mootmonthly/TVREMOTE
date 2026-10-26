import Foundation

/// Talks to a Samsung Smart TV (2016+ Tizen models) over its local WebSocket remote API.
final class SamsungRemote: NSObject, ObservableObject, URLSessionWebSocketDelegate {
    enum State: Equatable {
        case disconnected, connecting, connected
        case failed(String)
    }

    @Published var state: State = .disconnected
    @Published var ip: String = UserDefaults.standard.string(forKey: "tvIP") ?? ""

    private var session: URLSession!
    private var task: URLSessionWebSocketTask?
    // 9 characters -> base64 with no "=" padding, which keeps the URL clean.
    private let appName = "TV Remote"

    override init() {
        super.init()
        session = URLSession(configuration: .default, delegate: self, delegateQueue: .main)
    }

    private var tokenKey: String { "token-\(ip)" }

    // MARK: Connection

    func connect() {
        disconnect()
        let host = ip.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !host.isEmpty else { return }
        ip = host
        UserDefaults.standard.set(host, forKey: "tvIP")

        var comps = URLComponents()
        comps.scheme = "wss"
        comps.host = host
        comps.port = 8002
        comps.path = "/api/v2/channels/samsung.remote.control"
        var items = [URLQueryItem(name: "name", value: Data(appName.utf8).base64EncodedString())]
        if let token = UserDefaults.standard.string(forKey: tokenKey) {
            items.append(URLQueryItem(name: "token", value: token))
        }
        comps.queryItems = items

        guard let url = comps.url else {
            state = .failed("That doesn't look like a valid IP address.")
            return
        }
        state = .connecting
        task = session.webSocketTask(with: url)
        task?.resume()
        listen()
    }

    func disconnect() {
        task?.cancel(with: .goingAway, reason: nil)
        task = nil
        state = .disconnected
    }

    private func listen() {
        task?.receive { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                switch result {
                case .success(let message):
                    if case .string(let text) = message { self.handle(text) }
                    self.listen()
                case .failure(let error):
                    if self.state != .disconnected {
                        self.state = .failed(error.localizedDescription)
                    }
                }
            }
        }
    }

    private func handle(_ text: String) {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let event = json["event"] as? String else { return }

        switch event {
        case "ms.channel.connect":
            // The TV hands back a token after you tap "Allow" once; saving it skips the prompt next time.
            if let payload = json["data"] as? [String: Any], let token = payload["token"] as? String {
                UserDefaults.standard.set(token, forKey: tokenKey)
            }
            state = .connected
        case "ms.channel.unauthorized":
            state = .failed("The TV denied access. Allow \"TV Remote\" on the TV and try again.")
        default:
            break
        }
    }

    // MARK: Keys

    func send(_ key: SamsungKey) {
        guard state == .connected else { return }
        let payload: [String: Any] = [
            "method": "ms.remote.control",
            "params": [
                "Cmd": "Click",
                "DataOfCmd": key.rawValue,
                "Option": "false",
                "TypeOfRemote": "SendRemoteKey"
            ]
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: payload),
              let string = String(data: data, encoding: .utf8) else { return }
        task?.send(.string(string)) { _ in }
    }

    // MARK: URLSession delegate

    /// Samsung TVs use a self-signed certificate on port 8002; trust it only for the TV's own IP.
    func urlSession(_ session: URLSession,
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
           challenge.protectionSpace.host == ip,
           let trust = challenge.protectionSpace.serverTrust {
            completionHandler(.useCredential, URLCredential(trust: trust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }

    func urlSession(_ session: URLSession,
                    webSocketTask: URLSessionWebSocketTask,
                    didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
                    reason: Data?) {
        if state == .connected { state = .disconnected }
    }
}

enum SamsungKey: String {
    case back = "KEY_RETURN"
    case home = "KEY_HOME"
    case power = "KEY_POWER"
    case up = "KEY_UP", down = "KEY_DOWN", left = "KEY_LEFT", right = "KEY_RIGHT"
    case ok = "KEY_ENTER"
    case volUp = "KEY_VOLUP", volDown = "KEY_VOLDOWN", mute = "KEY_MUTE"
    case chUp = "KEY_CHUP", chDown = "KEY_CHDOWN"
}
