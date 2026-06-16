import SwiftUI

enum ToastKind {
    case success, error
}

struct ToastItem: Identifiable, Equatable {
    let id = UUID()
    var kind: ToastKind
    var message: String
}

@MainActor
@Observable
final class ToastCenter {
    static let shared = ToastCenter()

    var items: [ToastItem] = []

    func show(_ kind: ToastKind, _ message: String) {
        let item = ToastItem(kind: kind, message: message)
        items.append(item)
        if items.count > 5 { items.removeFirst(items.count - 5) }

        Task {
            try? await Task.sleep(for: .seconds(3))
            items.removeAll { $0.id == item.id }
        }
    }
}

struct ToastOverlay: View {
    @Environment(ToastCenter.self) private var toastCenter

    var body: some View {
        VStack(spacing: 8) {
            ForEach(toastCenter.items) { item in
                HStack(spacing: 10) {
                    Image(systemName: item.kind == .success ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    Text(item.message)
                        .font(.subheadline)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(item.kind == .success ? AppColors.positive.opacity(0.5) : AppColors.danger.opacity(0.5))
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 8)
        .padding(.horizontal)
        .allowsHitTesting(false)
        .animation(.easeInOut, value: toastCenter.items)
    }
}
