import SwiftUI
import UIKit

/// Gmail-style swipe-to-delete for rows in our custom (non-`List`) cards.
///
/// Two stages, right-to-left:
/// - Short swipe: reveals a trash button; tapping it calls `onDelete`
///   (callers usually show a confirmation dialog there).
/// - Long swipe past the commit threshold: haptic tick, the row slides away
///   and `onFullSwipe` fires immediately — the fast path, like Gmail.
///
/// Tapping the row runs `onTap` when closed, or just closes a revealed row.
struct SwipeToDeleteRow<Content: View>: View {
    var backgroundColor: Color = AppColors.surface
    var onTap: (() -> Void)? = nil
    let onDelete: () -> Void
    /// Immediate delete on full swipe. Defaults to `onDelete` when nil.
    var onFullSwipe: (() -> Void)? = nil
    @ViewBuilder let content: () -> Content

    @State private var offset: CGFloat = 0
    @State private var isOpen = false
    @State private var isPastCommit = false
    @State private var isDeleting = false
    @State private var rowWidth: CGFloat = 0

    private let actionWidth: CGFloat = 72
    private let animation = Animation.spring(response: 0.3, dampingFraction: 0.85)

    /// Swiping past this point commits the delete on release.
    private var commitThreshold: CGFloat {
        max(rowWidth * 0.55, actionWidth * 2)
    }

    var body: some View {
        content()
            .contentShape(Rectangle())
            .background(backgroundColor)
            .offset(x: offset)
            .background { deleteBackground }
            .clipped()
            .onTapGesture {
                if isOpen {
                    close()
                } else {
                    onTap?()
                }
            }
            .gesture(dragGesture)
            .background(
                GeometryReader { geo in
                    Color.clear
                        .onAppear { rowWidth = geo.size.width }
                        .onChange(of: geo.size.width) { _, newValue in rowWidth = newValue }
                }
            )
            .accessibilityAction(named: Text("common.delete")) { onDelete() }
    }

    // MARK: - Delete background (full-bleed red, Gmail style)

    private var deleteBackground: some View {
        HStack {
            Spacer()
            Image(systemName: "trash.fill")
                .font(.body.weight(.semibold))
                .foregroundStyle(.white)
                .scaleEffect(isPastCommit ? 1.25 : 1.0)
                .animation(.spring(response: 0.25, dampingFraction: 0.6), value: isPastCommit)
                .padding(.trailing, (actionWidth - 20) / 2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.danger)
        .opacity(offset < 0 ? 1 : 0)
        .onTapGesture {
            if isOpen {
                close()
                onDelete()
            }
        }
    }

    // MARK: - Gesture

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 20)
            .onChanged { value in
                guard !isDeleting else { return }
                // Ignore mostly-vertical drags so scrolling stays untouched.
                guard isOpen || abs(value.translation.width) > abs(value.translation.height) else { return }

                let base: CGFloat = isOpen ? -actionWidth : 0
                var proposed = base + value.translation.width
                // Slight resistance when dragging right past the resting point.
                if proposed > 0 { proposed = proposed * 0.15 }
                offset = max(proposed, -rowWidth)

                let nowPastCommit = offset < -commitThreshold
                if nowPastCommit != isPastCommit {
                    isPastCommit = nowPastCommit
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }
            }
            .onEnded { _ in
                guard !isDeleting else { return }

                if isPastCommit {
                    commitDelete()
                } else {
                    withAnimation(animation) {
                        if offset < -actionWidth * 0.55 {
                            offset = -actionWidth
                            isOpen = true
                        } else {
                            offset = 0
                            isOpen = false
                        }
                    }
                }
            }
    }

    // MARK: - Actions

    private func commitDelete() {
        isDeleting = true
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        withAnimation(.easeIn(duration: 0.2)) {
            offset = -rowWidth
        } completion: {
            (onFullSwipe ?? onDelete)()
            // Reset so the row is usable again if the delete fails and rolls back.
            withAnimation(animation.delay(0.4)) {
                offset = 0
                isOpen = false
                isPastCommit = false
                isDeleting = false
            }
        }
    }

    private func close() {
        withAnimation(animation) {
            offset = 0
            isOpen = false
            isPastCommit = false
        }
    }
}
