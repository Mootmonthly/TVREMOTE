import SwiftUI

struct ContentView: View {
    @StateObject private var tv = SamsungRemote()

    var body: some View {
        VStack(spacing: 24) {
            connectionBar

            HStack {
                RemoteButton(icon: "power", tint: .red) { tv.send(.power) }
                Spacer()
                RemoteButton(icon: "speaker.slash.fill") { tv.send(.mute) }
            }

            dPad

            HStack(spacing: 40) {
                RemoteButton(icon: "arrow.uturn.backward", label: "Back") { tv.send(.back) }
                RemoteButton(icon: "house.fill", label: "Home") { tv.send(.home) }
            }

            HStack(spacing: 60) {
                rocker(title: "VOL", up: .volUp, down: .volDown)
                rocker(title: "CH", up: .chUp, down: .chDown)
            }

            Spacer(minLength: 0)
        }
        .padding()
        .onAppear { if !tv.ip.isEmpty { tv.connect() } }
    }

    // MARK: Pieces

    private var connectionBar: some View {
        VStack(spacing: 8) {
            HStack {
                TextField("TV IP address (e.g. 192.168.1.50)", text: $tv.ip)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                Button(tv.state == .connected ? "Reconnect" : "Connect") { tv.connect() }
                    .buttonStyle(.borderedProminent)
            }
            Text(statusText)
                .font(.footnote)
                .foregroundStyle(statusColor)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var dPad: some View {
        VStack(spacing: 8) {
            RemoteButton(icon: "chevron.up") { tv.send(.up) }
            HStack(spacing: 8) {
                RemoteButton(icon: "chevron.left") { tv.send(.left) }
                Button { tv.send(.ok); haptic() } label: {
                    Text("OK").font(.title2.bold())
                        .frame(width: 80, height: 80)
                        .background(Circle().fill(Color.accentColor))
                        .foregroundStyle(.white)
                }
                RemoteButton(icon: "chevron.right") { tv.send(.right) }
            }
            RemoteButton(icon: "chevron.down") { tv.send(.down) }
        }
    }

    private func rocker(title: String, up: SamsungKey, down: SamsungKey) -> some View {
        VStack(spacing: 6) {
            RemoteButton(icon: "plus") { tv.send(up) }
            Text(title).font(.caption.bold()).foregroundStyle(.secondary)
            RemoteButton(icon: "minus") { tv.send(down) }
        }
    }

    private var statusText: String {
        switch tv.state {
        case .disconnected: return "Not connected"
        case .connecting: return "Connecting… check your TV for an \"Allow\" prompt the first time."
        case .connected: return "Connected"
        case .failed(let message): return message
        }
    }

    private var statusColor: Color {
        switch tv.state {
        case .connected: return .green
        case .failed: return .red
        default: return .secondary
        }
    }
}

struct RemoteButton: View {
    let icon: String
    var label: String? = nil
    var tint: Color = .primary
    let action: () -> Void

    var body: some View {
        Button { action(); haptic() } label: {
            VStack(spacing: 4) {
                Image(systemName: icon).font(.title2)
                    .frame(width: 64, height: 64)
                    .background(Circle().fill(Color(.secondarySystemBackground)))
                    .foregroundStyle(tint)
                if let label {
                    Text(label).font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

func haptic() {
    UIImpactFeedbackGenerator(style: .light).impactOccurred()
}

#Preview { ContentView() }
