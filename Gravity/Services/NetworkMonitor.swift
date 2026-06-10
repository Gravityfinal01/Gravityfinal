import Foundation
import Network

@MainActor
class NetworkMonitor: ObservableObject {
    @Published var isConnected = false
    @Published var isOnLocalNetwork = false

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.wardrobe.network")

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            let connected = path.status == .satisfied
            let local = connected && (
                path.usesInterfaceType(.wifi) ||
                path.usesInterfaceType(.wiredEthernet) ||
                path.usesInterfaceType(.loopback)
            )
            Task { @MainActor [weak self] in
                self?.isConnected = connected
                self?.isOnLocalNetwork = local
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}
