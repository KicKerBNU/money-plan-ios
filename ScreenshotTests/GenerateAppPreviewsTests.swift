import SwiftUI
import XCTest
@testable import MoneyPlan

/// Renders App Preview frames (886×1920) then `scripts/encode-app-previews.sh` muxes to H.264 `.mov`.
@MainActor
final class GenerateAppPreviewsTests: XCTestCase {
    private var outputRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("AppStorePreviews", isDirectory: true)
            .appendingPathComponent("iPhone-6.5", isDirectory: true)
    }

    func testGenerateAppPreviewFrames() throws {
        ThemeManager.shared.preference = .light
        MoneyPreferences.shared.setCurrency("EUR")

        for preview in AppPreviewID.allCases {
            let framesDir = outputRoot
                .appendingPathComponent("frames", isDirectory: true)
                .appendingPathComponent(preview.outputFilename, isDirectory: true)

            try? FileManager.default.removeItem(at: framesDir)
            try FileManager.default.createDirectory(at: framesDir, withIntermediateDirectories: true)

            for frame in 0 ..< AppPreviewSpec.frameCount {
                let view = MarketingAppPreviewFrame(preview: preview, frameIndex: frame)
                    .environment(MoneyPreferences.shared)
                    .environment(ThemeManager.shared)

                let renderer = ImageRenderer(content: view)
                renderer.scale = 1
                renderer.isOpaque = true

                guard let image = renderer.uiImage, let data = image.pngData() else {
                    XCTFail("Failed to render frame \(frame) for \(preview.outputFilename)")
                    continue
                }

                let url = framesDir.appendingPathComponent(String(format: "frame_%05d.png", frame))
                try data.write(to: url, options: .atomic)
            }

            XCTAssertEqual(
                try frameFiles(in: framesDir).count,
                AppPreviewSpec.frameCount,
                "Frame count mismatch for \(preview.outputFilename)"
            )
        }
    }

    private func frameFiles(in directory: URL) throws -> [URL] {
        try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "png" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
    }
}
