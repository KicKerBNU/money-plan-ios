import SwiftUI
import UIKit

/// Stable XCUITest hook: a real `UIView` accessibility leaf (type Other) that does not
/// steal identifiers from child text fields the way SwiftUI container modifiers can.
struct UITestPageAnchor: UIViewRepresentable {
    let identifier: String

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.isUserInteractionEnabled = false
        view.isAccessibilityElement = true
        view.accessibilityIdentifier = identifier
        view.accessibilityLabel = identifier
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        uiView.accessibilityIdentifier = identifier
        uiView.accessibilityLabel = identifier
    }
}

extension View {
    /// Attaches a findable page marker for UI tests (`app.otherElements["…"]`).
    func uiTestPage(_ identifier: String) -> some View {
        background(alignment: .topLeading) {
            UITestPageAnchor(identifier: identifier)
                .frame(width: 1, height: 1)
                .accessibilityHidden(false)
        }
    }
}
