import SwiftUI
import UIKit

/// Swipe-to-delete for rows in our custom (non-`List`) cards.
///
/// Right-to-left swipe reveals a trash button; tapping it calls `onDelete`
/// (callers show a confirmation dialog). Full-swipe past the threshold snaps
/// open to the same trash button — it does **not** delete without confirm
/// (matches recurring lists' `allowsFullSwipe: false` behavior).
///
/// Tapping the row runs `onTap` when closed, or just closes a revealed row.
struct SwipeToDeleteRow<Content: View>: View {
    var backgroundColor: Color = AppColors.surface
    var onTap: (() -> Void)? = nil
    let onDelete: () -> Void
    @ViewBuilder let content: () -> Content

    @State private var offset: CGFloat = 0
    @State private var isOpen = false
    @State private var isPastCommit = false
    @State private var rowWidth: CGFloat = 0

    private let actionWidth: CGFloat = 72
    private let animation = Animation.spring(response: 0.3, dampingFraction: 0.85)

    /// Visual feedback threshold (haptic) while dragging — does not auto-delete.
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

    // MARK: - Delete background

    private var deleteBackground: some View {
        HStack {
            Spacer()
            Image(systemName: "trash.fill")
                .font(.body.weight(.semibold))
                .foregroundStyle(.white)
                .scaleEffect(isPastCommit ? 1.25 : 1.0)
                .animation(.spring(response: 0.25, dampingFraction: 0.6), value: isPastCommit)
                .padding(.trailing, (actionWidth - 20) / 2)
                .accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.danger)
        .opacity(offset < 0 ? 1 : 0)
        .accessibilityElement()
        .accessibilityIdentifier("row-swipe-delete")
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(Text("common.delete"))
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
                // Ignore mostly-vertical drags so scrolling stays untouched.
                guard isOpen || abs(value.translation.width) > abs(value.translation.height) else { return }

                let base: CGFloat = isOpen ? -actionWidth : 0
                var proposed = base + value.translation.width
                // Slight resistance when dragging right past the resting point.
                if proposed > 0 { proposed = proposed * 0.15 }
                // Cap at reveal width — never slide the row fully away without confirm.
                offset = max(min(proposed, 0), -actionWidth * 1.15)

                let nowPastCommit = offset < -commitThreshold || offset <= -actionWidth
                if nowPastCommit != isPastCommit {
                    isPastCommit = nowPastCommit
                    if nowPastCommit {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }
                }
            }
            .onEnded { _ in
                withAnimation(animation) {
                    if offset < -actionWidth * 0.45 {
                        offset = -actionWidth
                        isOpen = true
                        isPastCommit = false
                    } else {
                        offset = 0
                        isOpen = false
                        isPastCommit = false
                    }
                }
            }
    }

    // MARK: - Actions

    private func close() {
        withAnimation(animation) {
            offset = 0
            isOpen = false
            isPastCommit = false
        }
    }
}
