import SwiftUI

/// Horizontal tap-to-select chip row for a category's subcategories.
/// Tapping the selected chip again clears the selection.
struct SubcategoryChips: View {
    let category: ClothingCategory
    @Binding var selection: ClothingSubcategory?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(category.subcategories) { sub in
                    let selected = selection == sub
                    Button {
                        selection = selected ? nil : sub
                    } label: {
                        Text(sub.displayName)
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selected ? Color.accentColor : Color(.systemGray6))
                            .foregroundStyle(selected ? Color.white : Color.primary)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
    }
}
