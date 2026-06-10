import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var immichService: ImmichService
    @StateObject private var vm = SettingsViewModel()

    var body: some View {
        NavigationStack {
            Form {
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

    // MARK: - Storage

    private var storageSection: some View {
        Section {
            ForEach(StorageBackend.allCases) { backend in
                Button {
                    vm.storageBackend = backend
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: vm.storageBackend == backend ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(vm.storageBackend == backend ? .accentColor : .secondary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(backend.displayName).font(.body).foregroundStyle(.primary)
                            Text(backend.description).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 2)
                }
                .buttonStyle(.plain)
            }
        } header: {
            Text("Photo Storage")
        } footer: {
            Text("iCloud Photos requires no server setup — photos sync automatically across your Apple devices.")
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
        Section("About") {
            LabeledContent("Version", value: "1.0")
            LabeledContent("AI", value: "Apple Vision + Ollama (local)")
            LabeledContent("Storage", value: vm.storageBackend.displayName)
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
