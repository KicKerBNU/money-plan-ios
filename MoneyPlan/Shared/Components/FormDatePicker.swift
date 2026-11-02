import SwiftUI

/// Form date field that expands a calendar and collapses when a day is tapped
/// (matches UIKit / system compact date picker behavior).
struct FormDatePicker: View {
    let title: LocalizedStringKey
    @Binding var date: Date

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(title)
                Spacer()
                Button {
                    withAnimation(.snappy) { isExpanded.toggle() }
                } label: {
                    Text(date, format: .dateTime.month(.abbreviated).day().year())
                        .foregroundStyle(Color.accentColor)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(title)
                .accessibilityValue(Text(date, format: .dateTime.month().day().year()))
            }

            if isExpanded {
                DatePicker(
                    title,
                    selection: Binding(
                        get: { date },
                        set: { newValue in
                            date = newValue
                            withAnimation(.snappy) { isExpanded = false }
                        }
                    ),
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .labelsHidden()
                .padding(.top, 8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}
