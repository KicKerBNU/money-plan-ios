import SwiftUI
import UIKit

extension View {
    /// Expands the interactive hit area to at least 44×44 pt (HIG minimum).
    /// Visual content can stay smaller; the frame / content shape grows the tap target.
    func minHitTarget(_ size: CGFloat = 44) -> some View {
        frame(minWidth: size, minHeight: size)
            .contentShape(Rectangle())
    }

    /// Keyboard accessory with Done for `.decimalPad` fields (no return key).
    func decimalPadDoneToolbar() -> some View {
        toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("common.done") {
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder),
                        to: nil,
                        from: nil,
                        for: nil
                    )
                }
                .fontWeight(.semibold)
            }
        }
    }
}
