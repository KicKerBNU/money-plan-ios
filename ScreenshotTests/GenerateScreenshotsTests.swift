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
            ("01-expenses", AnyView(MarketingExpensesScreenshot())),
            ("02-income", AnyView(MarketingIncomeScreenshot())),
            ("03-chatbot", AnyView(MarketingChatbotScreenshot())),
            ("04-accounts", AnyView(MarketingAccountsScreenshot())),
            ("05-login", AnyView(MarketingLoginScreenshot())),
            ("06-add-expense", AnyView(MarketingAddExpenseScreenshot())),
            ("07-overview", AnyView(MarketingOverviewScreenshot())),
            ("08-stats", AnyView(MarketingStatsScreenshot())),
            ("09-expenses-by-category", AnyView(MarketingExpensesByCategoryScreenshot())),
            ("10-settings", AnyView(MarketingSettingsScreenshot())),
        ]

        let iPhone65 = ScreenshotSpec(
            folder: "iPhone-6.5",
            width: 428,
            height: 926,
            scale: 3
        )
        let iPhone67 = ScreenshotSpec(
            folder: "iPhone-6.7",
            width: 430,
            height: 932,
            scale: 3
        )
        let iPad = ScreenshotSpec(
            folder: "iPad-12.9",
            width: 1024,
            height: 1366,
            scale: 2
        )

        for spec in [iPhone65, iPhone67, iPad] {
            let dir = outputRoot.appendingPathComponent(spec.folder, isDirectory: true)
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
    }
}
