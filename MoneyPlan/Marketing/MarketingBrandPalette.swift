import SwiftUI

/// Money Plan App Store marketing palette — matches app icon & `Primary` asset colors.
enum MarketingBrandPalette {
    // Icon gradient: warm yellow → mint → teal (light-mode Primary #2F7F73)
    static let canvasTop = Color(red: 0.98, green: 0.86, blue: 0.42)
    static let canvasMid = Color(red: 0.52, green: 0.84, blue: 0.72)
    static let canvasBottom = Color(red: 0.18, green: 0.50, blue: 0.45)

    static let blobLight = Color(red: 0.99, green: 0.93, blue: 0.58)
    static let blobDark = Color(red: 0.10, green: 0.40, blue: 0.36)
    static let accentGold = Color(red: 0.98, green: 0.84, blue: 0.38)

    static let headline = Color(red: 0.07, green: 0.09, blue: 0.11)
    static let label = Color(red: 0.12, green: 0.38, blue: 0.34)
    static let subheadline = Color(red: 0.14, green: 0.42, blue: 0.38)
    static let bezel = Color(red: 0.11, green: 0.12, blue: 0.14)

    static var canvasGradient: LinearGradient {
        LinearGradient(
            colors: [canvasTop, canvasMid, canvasBottom],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

/// Phone vs iPad marketing layout. App Previews (886pt wide) must use phone layout.
enum MarketingLayout {
    static func usesPadLayout(width: CGFloat) -> Bool { width >= 1024 }
}

/// Logical phone canvas + safe areas for marketing mockups (matches iPhone 15-class devices).
enum MarketingPhoneMetrics {
    static let contentWidth: CGFloat = 393
    static let contentHeight: CGFloat = 852
    static let topSafeArea: CGFloat = 59
    static let aspect: CGFloat = contentHeight / contentWidth
}

/// Shared gradient background for screenshots and App Previews.
struct MarketingCanvasBackground: View {
    let isPad: Bool

    var body: some View {
        ZStack {
            MarketingBrandPalette.canvasGradient

            Circle()
                .fill(MarketingBrandPalette.blobLight.opacity(0.65))
                .frame(width: isPad ? 520 : 340)
                .blur(radius: isPad ? 8 : 4)
                .offset(x: isPad ? -220 : -150, y: isPad ? -280 : -200)

            Circle()
                .fill(MarketingBrandPalette.blobDark.opacity(0.35))
                .frame(width: isPad ? 440 : 300)
                .blur(radius: isPad ? 6 : 3)
                .offset(x: isPad ? 240 : 160, y: isPad ? 360 : 280)

            Ellipse()
                .fill(MarketingBrandPalette.accentGold.opacity(0.35))
                .frame(width: isPad ? 280 : 200, height: isPad ? 160 : 120)
                .rotationEffect(.degrees(-24))
                .offset(x: isPad ? 180 : 120, y: isPad ? -120 : -80)

            RoundedRectangle(cornerRadius: isPad ? 120 : 80, style: .continuous)
                .fill(Color.white.opacity(0.14))
                .frame(width: isPad ? 360 : 240, height: isPad ? 200 : 140)
                .rotationEffect(.degrees(18))
                .offset(x: isPad ? -200 : -130, y: isPad ? 420 : 320)
        }
    }
}
