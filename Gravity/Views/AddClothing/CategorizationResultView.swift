import SwiftUI

struct CategorizationResultView: View {
    @ObservedObject var vm: AddClothingViewModel

    var body: some View {
        HStack(spacing: 12) {
            stateIcon
            VStack(alignment: .leading, spacing: 2) {
                stateLabel
                if let result = vm.result, vm.categorizationState == .complete {
                    Text(detailText(result))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding(12)
        .background(stateBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    @ViewBuilder
    private var stateIcon: some View {
        switch vm.categorizationState {
        case .idle:
            EmptyView()
        case .classifying:
            ProgressView().scaleEffect(0.8)
        case .enriching:
            ProgressView().scaleEffect(0.8)
        case .complete:
            Image(systemName: aiSourceIcon)
                .foregroundStyle(.green)
        case .error:
            Image(systemName: "exclamationmark.triangle")
                .foregroundStyle(.orange)
        }
    }

    @ViewBuilder
    private var stateLabel: some View {
        switch vm.categorizationState {
        case .idle: EmptyView()
        case .classifying:
            Text("Detecting clothing type…").font(.subheadline)
        case .enriching:
            Text("Enhancing with AI…").font(.subheadline)
        case .complete:
            Text("AI categorized: \(vm.editableCategory.displayName)").font(.subheadline.weight(.medium))
        case .error(let msg):
            Text("Error: \(msg)").font(.subheadline).foregroundStyle(.red)
        }
    }

    private var aiSourceIcon: String {
        switch vm.result?.source {
        case .hybrid: return "cpu"
        case .ollama: return "server.rack"
        default: return "checkmark.circle"
        }
    }

    private var stateBackground: Color {
        switch vm.categorizationState {
        case .complete: return Color.green.opacity(0.1)
        case .error: return Color.orange.opacity(0.1)
        default: return Color(.systemGray6)
        }
    }

    private func detailText(_ result: CategorizationResult) -> String {
        var parts: [String] = []
        if let color = result.color { parts.append(color.capitalized) }
        let sourceLabel: String = switch result.source {
        case .vision: "On-device"
        case .ollama: "Ollama"
        case .hybrid: "On-device + Ollama"
        }
        parts.append("· \(sourceLabel)")
        return parts.joined(separator: " ")
    }
}
