import SwiftUI

/// App icon + wordmark for App Store marketing frames.
struct MarketingBrandLockup: View {
    let isPad: Bool

    var body: some View {
        HStack(spacing: isPad ? 12 : 9) {
            Image("MarketingAppIcon")
                .resizable()
                .interpolation(.high)
                .frame(width: isPad ? 34 : 26, height: isPad ? 34 : 26)
                .clipShape(RoundedRectangle(cornerRadius: isPad ? 8 : 6, style: .continuous))
                .shadow(color: .black.opacity(0.18), radius: 6, y: 3)

            Text("MONEY PLANN")
                .font(.system(size: isPad ? 16 : 13, weight: .bold, design: .rounded))
                .tracking(isPad ? 3 : 2.2)
                .foregroundStyle(MarketingBrandPalette.label)
        }
    }
}
