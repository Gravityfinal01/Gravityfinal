import SwiftUI
import PhotosUI
import SwiftData

struct AddClothingView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var aiService: AICategorizationService

    @StateObject private var vm = AddClothingViewModel()
    @State private var photoItem: PhotosPickerItem?
    @State private var showCamera = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    imageSection
                    if vm.selectedImage != nil {
                        CategorizationResultView(vm: vm)
                        formSection
                        saveButton
                    }
                }
                .padding()
            }
            .navigationTitle("Add Clothing")
            .sheet(isPresented: $showCamera) {
                CameraView { image in
                    showCamera = false
                    Task { await vm.processImage(image, aiService: aiService) }
                }
            }
            .onChange(of: photoItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        await vm.processImage(image, aiService: aiService)
                    }
                }
            }
            .onChange(of: vm.didSave) { _, saved in
                if saved { vm.reset() }
            }
        }
    }

    private var imageSection: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
                .frame(height: 280)

            if let image = vm.selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 280)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("Add a photo of your clothing")
                        .foregroundStyle(.secondary)
                    HStack(spacing: 12) {
                        Button {
                            showCamera = true
                        } label: {
                            Label("Camera", systemImage: "camera")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)

                        PhotosPicker(selection: $photoItem, matching: .images) {
                            Label("Library", systemImage: "photo.on.rectangle")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.horizontal)
                }
            }

            if vm.selectedImage != nil {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        PhotosPicker(selection: $photoItem, matching: .images) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .padding(8)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                        .padding(12)
                    }
                }
            }
        }
    }

    private var formSection: some View {
        VStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Name").font(.caption).foregroundStyle(.secondary)
                TextField("e.g. Blue Denim Jacket", text: $vm.editableName)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Category").font(.caption).foregroundStyle(.secondary)
                Picker("Category", selection: $vm.editableCategory) {
                    ForEach(ClothingCategory.allCases) { cat in
                        Text(cat.displayName).tag(cat)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 8)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Brand (optional)").font(.caption).foregroundStyle(.secondary)
                TextField("e.g. Nike, Zara", text: $vm.editableBrand)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }

    private var saveButton: some View {
        Button {
            Task { await vm.saveItem(context: modelContext) }
        } label: {
            Group {
                if vm.isSaving {
                    ProgressView()
                } else {
                    Text("Save to Wardrobe")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.accentColor)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(vm.isSaving || vm.editableName.isEmpty)
    }
}
