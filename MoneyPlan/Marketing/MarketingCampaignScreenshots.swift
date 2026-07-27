import SwiftUI

// MARK: - Pan continuity (01 + 02 = one phone, perfectly aligned)

/// Shared oversized phone used by both pan frames — same size, rotation, and Y.
struct MarketingPanPhoneScene: View {
    let phoneWidth: CGFloat
    let isPad: Bool

    var body: some View {
        MarketingPhoneChrome(phoneWidth: phoneWidth, isPad: isPad, bezelExtra: 1) {
            MarketingScreenshotShell(tab: .expenses) {
                MarketingExpensesContent()
            }
        }
        .rotationEffect(.degrees(MarketingScreenshotMetrics.panRotationDegrees))
    }
}

enum MarketingPanSide {
    case left
    case right
}

/// Frame 01 / 02 — one device split across two App Store screenshots.
/// Phone center sits on the shared seam so the pair lines up when viewed side-by-side.
struct MarketingPanScreenshot: View {
    let side: MarketingPanSide
    let headline: String

    var body: some View {
        GeometryReader { geo in
            let isPad = MarketingLayout.usesPadLayout(width: geo.size.width)
            let headerH = MarketingScreenshotMetrics.headerHeight(isPad: isPad)
            let phoneW = MarketingScreenshotMetrics.panPhoneWidth(
                canvasWidth: geo.size.width,
                isPad: isPad
            )
            // Seam = right edge of 01 / left edge of 02. Same Y on both.
            let phoneCenterX: CGFloat = side == .left ? geo.size.width : 0
            let phoneCenterY = MarketingScreenshotMetrics.panPhoneCenterY(
                canvasHeight: geo.size.height,
                isPad: isPad
            )

            ZStack {
                MarketingCanvasBackground(isPad: isPad)

                VStack(spacing: 0) {
                    VStack(spacing: 0) {
                        MarketingBrandLockup(isPad: isPad)
                            .padding(.top, isPad ? 44 : 28)

                        Text(headline)
                            .font(.system(size: isPad ? 40 : 26, weight: .bold, design: .rounded))
                            .foregroundStyle(MarketingBrandPalette.headline)
                            .multilineTextAlignment(side == .left ? .leading : .trailing)
                            .lineSpacing(isPad ? 4 : 2)
                            .minimumScaleFactor(0.78)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: side == .left ? .leading : .trailing)
                            .padding(.horizontal, isPad ? 48 : 26)
                            .padding(.top, isPad ? 18 : 14)
                    }
                    .frame(height: headerH, alignment: .top)

                    Spacer(minLength: 0)
                }

                MarketingPanPhoneScene(phoneWidth: phoneW, isPad: isPad)
                    .position(x: phoneCenterX, y: phoneCenterY)

                if side == .left {
                    MarketingPanCornerLogo(isPad: isPad)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                        .padding(.leading, isPad ? 48 : 28)
                        .padding(.bottom, isPad ? 56 : 44)
                }
            }
            .clipped()
        }
    }
}

/// Large app icon badge for the bottom-left of the pan-left screenshot.
private struct MarketingPanCornerLogo: View {
    let isPad: Bool

    var body: some View {
        let size: CGFloat = isPad ? 96 : 72
        Image("MarketingAppIcon")
            .resizable()
            .interpolation(.high)
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
            .shadow(color: .black.opacity(0.28), radius: 16, y: 10)
            .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
            .overlay {
                RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.35), lineWidth: 1.5)
            }
    }
}

struct MarketingPanLeftScreenshot: View {
    var body: some View {
        MarketingPanScreenshot(
            side: .left,
            headline: MarketingScreenshotCopy.panLeft.headline
        )
    }
}

struct MarketingPanRightScreenshot: View {
    var body: some View {
        MarketingPanScreenshot(
            side: .right,
            headline: MarketingScreenshotCopy.panRight.headline
        )
    }
}
