import SwiftUI
import XCTest
@testable import MoneyPlan

/// Renders marketing screenshots with `ImageRenderer` and writes PNGs to `AppStoreScreenshots/`.
@MainActor
final class GenerateScreenshotsTests: XCTestCase {
    private var outputRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("AppStoreScreenshots", isDirectory: true)
    }

    func testGenerateAppStoreScreenshots() throws {
        ThemeManager.shared.preference = .light
        MoneyPreferences.shared.setCurrency("EUR")

        let screens: [(String, AnyView)] = [
            ("01-expenses", AnyView(MarketingPanLeftScreenshot())),
            ("02-expenses-continue", AnyView(MarketingPanRightScreenshot())),
            ("03-chatbot", AnyView(MarketingChatbotScreenshot())),
            ("04-income", AnyView(MarketingIncomeScreenshot())),
            ("05-accounts", AnyView(MarketingAccountsScreenshot())),
            ("06-overview", AnyView(MarketingOverviewScreenshot())),
            ("07-stats", AnyView(MarketingStatsScreenshot())),
            ("08-add-expense", AnyView(MarketingAddExpenseScreenshot())),
            ("09-categories", AnyView(MarketingCategoriesScreenshot())),
            ("10-settings", AnyView(MarketingSettingsScreenshot())),
            ("11-login", AnyView(MarketingLoginScreenshot())),
        ]

        let iPhone65 = ScreenshotSpec(
            folder: "iPhone-6.5",
            width: 428,
            height: 926,
            scale: 3,
            expectedPixelWidth: 1284,
            expectedPixelHeight: 2778
        )
        let iPhone65Legacy = ScreenshotSpec(
            folder: "iPhone-6.5-legacy",
            width: 414,
            height: 896,
            scale: 3,
            expectedPixelWidth: 1242,
            expectedPixelHeight: 2688
        )
        let iPhone67 = ScreenshotSpec(
            folder: "iPhone-6.7",
            width: 430,
            height: 932,
            scale: 3,
            expectedPixelWidth: 1290,
            expectedPixelHeight: 2796
        )
        let iPhone69 = ScreenshotSpec(
            folder: "iPhone-6.9",
            width: 440,
            height: 956,
            scale: 3,
            expectedPixelWidth: 1320,
            expectedPixelHeight: 2868
        )
        let iPad = ScreenshotSpec(
            folder: "iPad-12.9",
            width: 1024,
            height: 1366,
            scale: 2,
            expectedPixelWidth: 2048,
            expectedPixelHeight: 2732
        )

        for spec in [iPhone65, iPhone65Legacy, iPhone67, iPhone69, iPad] {
            let dir = outputRoot.appendingPathComponent(spec.folder, isDirectory: true)
            if FileManager.default.fileExists(atPath: dir.path) {
                try FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
                    .filter { $0.pathExtension == "png" }
                    .forEach { try FileManager.default.removeItem(at: $0) }
            }
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

            for (name, view) in screens {
                let url = dir.appendingPathComponent("\(name).png")
                try render(view, spec: spec, to: url)
                XCTAssertTrue(FileManager.default.fileExists(atPath: url.path), "Missing \(url.path)")
            }
        }
    }

    private struct ScreenshotSpec {
        let folder: String
        let width: CGFloat
        let height: CGFloat
        let scale: CGFloat
        let expectedPixelWidth: Int
        let expectedPixelHeight: Int
    }

    private func render<V: View>(_ content: V, spec: ScreenshotSpec, to url: URL) throws {
        let framed = content
            .environment(MoneyPreferences.shared)
            .environment(ThemeManager.shared)
            .frame(width: spec.width, height: spec.height)
            .clipped()

        let renderer = ImageRenderer(content: framed)
        renderer.scale = spec.scale
        renderer.isOpaque = true

        guard let image = renderer.uiImage, let data = image.pngData() else {
            throw NSError(domain: "ScreenshotTests", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "ImageRenderer failed for \(url.lastPathComponent)",
            ])
        }
        try data.write(to: url, options: .atomic)

        XCTAssertEqual(image.size.width * spec.scale, CGFloat(spec.expectedPixelWidth), accuracy: 0.5)
        XCTAssertEqual(image.size.height * spec.scale, CGFloat(spec.expectedPixelHeight), accuracy: 0.5)
    }
}
