import SwiftUI

struct SettingsView: View {
    /// Public feedback form shown under About. Create a form at tally.so (or Google Forms),
    /// copy its share link, and paste it here. The row is hidden while this placeholder remains.
    static let feedbackFormURL = "https://tally.so/r/9qL6xE"

    @EnvironmentObject private var immichService: ImmichService
    @StateObject private var vm = SettingsViewModel()
    @AppStorage(AppAppearance.storageKey) private var appearanceRaw = AppAppearance.system.rawValue
    @AppStorage(WardrobeLayout.storageKey) private var layoutRaw = WardrobeLayout.detailed.rawValue
    @AppStorage(WelcomeView.completedKey) private var hasCompletedWelcome = false
    @AppStorage(ThemeColor.storageKey) private var themeRaw = ThemeColor.blue.rawValue

    var body: some View {
        NavigationStack {
            Form {
                appearanceSection
                viewingSection
                storageSection
                if vm.storageBackend.requiresImmich {
                    immichSection
                }
                aiSection
                aboutSection
            }
            .navigationTitle("Settings")
        }
    }

    // MARK: - Appearance

    private var appearanceSection: some View {
        Section {
            Picker("Theme", selection: $appearanceRaw) {
                ForEach(AppAppearance.allCases) { option in
                    Text(option.displayName).tag(option.rawValue)
                }
            }
            .pickerStyle(.segmented)

            // One row of swatches that stretches edge to edge: each circle takes an equal
            // share of the width (capped so they don't balloon on iPad).
            HStack(spacing: 10) {
                ForEach(ThemeColor.allCases) { theme in
                    let selected = themeRaw == theme.rawValue
                    Button {
                        themeRaw = theme.rawValue
                    } label: {
                        Circle()
                            .fill(theme.color)
                            .frame(maxWidth: 40)
                            .aspectRatio(1, contentMode: .fit)
                            .overlay {
                                if selected {
                                    Image(systemName: "checkmark")
                                        .font(.caption2.bold())
                                        .foregroundStyle(.white)
                                }
                            }
                            .overlay {
                                Circle()
                                    .strokeBorder(theme.color, lineWidth: 2)
                                    .padding(-4)
                                    .opacity(selected ? 1 : 0)
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(theme.displayName)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        } header: {
            Text("Appearance")
        }
    }

    // MARK: - Viewing options

    private var viewingSection: some View {
        Section {
            ForEach(WardrobeLayout.allCases) { layout in
                Button {
                    layoutRaw = layout.rawValue
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: layout.systemImage)
                            .font(.title3)
                            .foregroundStyle(Color.accentColor)
                            .frame(width: 28)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(layout.displayName).font(.body).foregroundStyle(.primary)
                            Text(layout.description).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        if layoutRaw == layout.rawValue {
                            Image(systemName: "checkmark")
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                    .padding(.vertical, 2)
                }
                .buttonStyle(.plain)
            }
        } header: {
            Text("Viewing Options")
        } footer: {
            Text("Changes how items are shown in the Wardrobe tab.")
        }
    }

    // MARK: - Storage

    private var storageSection: some View {
        Section {
            ForEach(StorageBackend.allCases) { backend in
                Button {
                    vm.storageBackend = backend
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: vm.storageBackend == backend ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(vm.storageBackend == backend ? Color.accentColor : Color.secondary)
                            .padding(.top, 2)
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Image(systemName: backend.systemImage)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(backend.displayName).font(.body).foregroundStyle(.primary)
                            }
                            Text(backend.description).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 2)
                }
                .buttonStyle(.plain)
            }

            Toggle(isOn: $vm.saveCopyToPhotos) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Also save to Photos app")
                    Text("Keeps a copy of each cutout in your photo library.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("Storage")
        } footer: {
            if vm.needsRestartForStorage {
                Label("Quit and reopen FitShelf to switch iCloud sync \(vm.storageBackend.usesICloud ? "on" : "off").",
                      systemImage: "arrow.counterclockwise")
                    .foregroundStyle(.orange)
            } else {
                Text("A copy always stays on this iPhone so the app works offline. iCloud needs you to be signed in to iCloud on this device.")
            }
        }
    }

    // MARK: - Immich

    private var immichSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 4) {
                Text("Server URL").font(.caption).foregroundStyle(.secondary)
                TextField("http://192.168.1.100:2283", text: $vm.immichBaseURL)
                    .keyboardType(.URL)
                    .autocorrectionDisabled()
                    .autocapitalization(.none)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("API Key").font(.caption).foregroundStyle(.secondary)
                SecureField("Paste your Immich API key", text: $vm.immichAPIKey)
                    .autocorrectionDisabled()
                    .autocapitalization(.none)
            }

            HStack {
                Button("Test Connection") {
                    Task { await vm.testImmich(service: immichService) }
                }
                Spacer()
                connectionBadge(vm.immichTestResult)
            }
        } header: {
            Text("Immich Server")
        } footer: {
            Text("Generate your API key in the Immich web UI under Account Settings → API Keys.")
        }
    }

    // MARK: - AI

    private var aiSection: some View {
        Section {
            Toggle("Use Ollama (local network)", isOn: $vm.useOllama)

            if vm.useOllama {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Ollama URL").font(.caption).foregroundStyle(.secondary)
                    TextField("http://192.168.1.100:11434", text: $vm.ollamaBaseURL)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                        .autocapitalization(.none)
                }

                Picker("Model", selection: $vm.ollamaModel) {
                    Text("llava").tag("llava")
                    Text("moondream").tag("moondream")
                    Text("bakllava").tag("bakllava")
                    Text("llava:13b").tag("llava:13b")
                }

                HStack {
                    Button("Test Ollama") {
                        Task { await vm.testOllama() }
                    }
                    Spacer()
                    connectionBadge(vm.ollamaTestResult)
                }
            }
        } header: {
            Text("Local AI")
        } footer: {
            Text("Apple Vision runs on-device for instant categorization. Enable Ollama for richer AI descriptions (color, brand, tags) using your Unraid server.")
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        Section {
            LabeledContent("Version", value: "1.0")
            LabeledContent("AI", value: "Apple Vision + Ollama (local)")
            LabeledContent("Storage", value: vm.storageBackend.displayName)
            // Reflects what the running data store was actually opened with,
            // so a silent fallback to local is visible without reading logs.
            LabeledContent("iCloud Sync", value: DataStore.activeBackend?.usesICloud == true ? "Active" : "Off")
            if !Self.feedbackFormURL.contains("REPLACE_ME"), let url = URL(string: Self.feedbackFormURL) {
                Link(destination: url) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Share a suggestion")
                                .foregroundStyle(.primary)
                            Text("FitShelf is always improving.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            Button("Show Welcome Screen") {
                hasCompletedWelcome = false
            }
        } header: {
            Text("About")
        } footer: {
            Text("FitShelf has no subscriptions, no in-app purchases and no ads. Every update is included. Your wardrobe stays on your iPhone, in your own iCloud, or on a server you run.")
        }
    }

    @ViewBuilder
    private func connectionBadge(_ state: ConnectionState) -> some View {
        switch state {
        case .untested: EmptyView()
        case .testing: ProgressView().scaleEffect(0.8)
        case .success:
            Label("Connected", systemImage: "checkmark.circle.fill")
                .font(.caption)
                .foregroundStyle(.green)
        case .failure(let msg):
            Label(msg, systemImage: "xmark.circle.fill")
                .font(.caption)
                .foregroundStyle(.red)
                .lineLimit(1)
        }
    }
}
