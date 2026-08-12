//
//  MoneyControlApp.swift
//  MoneyControl
//
//  Created by Paulo Gaio on 29/07/2026.
//

import SwiftUI
import SwiftData

#if os(iOS)
final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        .portrait
    }
}
#endif

@main
struct MoneyControlApp: App {
#if os(iOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
#endif

    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @AppStorage("hasCompletedInitialSetup") private var hasCompletedInitialSetup = false

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            MoneyTransaction.self,
            ExpensePayment.self,
            RecurrenceExclusion.self,
            CreditAccount.self,
            CreditMovement.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            Group {
                if hasSeenOnboarding && hasCompletedInitialSetup {
                    ContentView()
                } else if hasSeenOnboarding {
                    InitialSetupWizardView {
                        hasCompletedInitialSetup = true
                    }
                } else {
                    OnboardingView {
                        hasCompletedInitialSetup = false
                        hasSeenOnboarding = true
                    }
                }
            }
            .tint(AppPalette.primary)
            .preferredColorScheme(.light)
        }
        .modelContainer(sharedModelContainer)
    }
}
