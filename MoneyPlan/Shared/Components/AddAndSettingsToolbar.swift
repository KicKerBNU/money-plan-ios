import SwiftUI

/// Trailing toolbar used on finance list screens: add (+) then settings (gear).
/// Each control is its own bar button. One grouped item leaves the gear with an
/// empty hit frame, so UI tests record a tap at {-1, -1} and the screen never opens.
struct AddAndSettingsToolbar: ToolbarContent {
    let addAccessibilityLabel: LocalizedStringKey
    let onAdd: () -> Void

    var body: some ToolbarContent {
        // Trailing items are placed from the outer edge inward, so the gear stays
        // on the right and the add button sits just to its left.
        ToolbarItem(placement: .topBarTrailing) {
            SettingsToolbar()
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button(action: onAdd) {
                Image(systemName: "plus")
            }
            .accessibilityLabel(addAccessibilityLabel)
        }
    }
}
