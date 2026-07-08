import SwiftUI

/// Trailing toolbar used on finance list screens: add (+) then settings (gear).
struct AddAndSettingsToolbar: View {
    let addAccessibilityLabel: LocalizedStringKey
    let onAdd: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Button(action: onAdd) {
                Image(systemName: "plus")
            }
            .accessibilityLabel(addAccessibilityLabel)

            SettingsToolbar()
        }
    }
}
