import SwiftUI

struct FirebaseSetupView: View {
    let status: FirebaseConfiguration.Status

    private var title: String {
        switch status {
        case .missingPlist: "Firebase config missing"
        case .invalidPlist: "Firebase config invalid"
        case .configured: "Firebase ready"
        }
    }

    private var message: String {
        switch status {
        case .missingPlist:
            return """
            Add GoogleService-Info.plist to MoneyPlan/Resources/.

            1. Open Firebase Console → Project money-plan-23efb
            2. Project settings → Your apps → Add app → iOS
            3. Bundle ID: com.moneyplann.app
            4. Download GoogleService-Info.plist
            5. Drag it into MoneyPlan/Resources/ in Xcode (copy if needed)
            6. Add URL scheme: copy REVERSED_CLIENT_ID from the plist → Target → Info → URL Types
            7. Clean build folder and run again
            """
        case .invalidPlist(let reason):
            return """
            \(reason)

            Replace MoneyPlan/Resources/GoogleService-Info.plist with the file downloaded from Firebase Console (not the .example template).

            Bundle ID must be com.moneyplann.app.
            """
        case .configured:
            return ""
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.orange)

                    Text(title)
                        .font(.title2.weight(.bold))

                    Text(message)
                        .font(.body)
                        .foregroundStyle(.secondary)

                    Link("Open Firebase Console", destination: URL(string: "https://console.firebase.google.com/project/money-plan-23efb/settings/general")!)
                        .font(.headline)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
            .navigationTitle("Setup required")
        }
    }
}
