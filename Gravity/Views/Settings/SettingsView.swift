import SwiftUI

struct SettingsView: View {
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

            HStack(spacing: 14) {
                ForEach(ThemeColor.allCases) { theme in
                    let selected = themeRaw == theme.rawValue
                    Button {
                        themeRaw = theme.rawValue
                    } label: {
                        Circle()
                            .fill(theme.color)
                            .frame(width: 30, height: 30)
                            .overlay {
                                if selected {
                                    Image(systemName: "checkmark")
                                        .font(.caption.bold())
                                        .foregroundStyle(.white)
                                }
                            }
                            .overlay {
                                Circle()
                                    .strokeBorder(theme.color, lineWidth: 2)
                                    .frame(width: 38, height: 38)
                                    .opacity(selected ? 1 : 0)
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(theme.displayName)
                }
                Spacer(minLength: 0)
            }
            .padding(.vertical, 6)
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
                Label("Quit and reopen Gravity to switch iCloud sync \(vm.storageBackend.usesICloud ? "on" : "off").",
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
            Button("Show Welcome Screen") {
                hasCompletedWelcome = false
            }
        } header: {
            Text("About")
        } footer: {
            Text("Gravity is free forever with no subscriptions or in-app purchases. Your wardrobe stays on your iPhone, in your own iCloud, or on a server you run.")
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
