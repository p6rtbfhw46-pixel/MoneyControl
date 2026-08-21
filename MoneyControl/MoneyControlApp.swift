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
    @State private var isShowingLaunchLoading = true

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            MoneyTransaction.self,
            ExpensePayment.self,
            PaymentHistoryEntry.self,
            RecurrenceExclusion.self,
            CreditAccount.self,
            CreditMovement.self,
            SavingAccount.self,
            SavingMovement.self,
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
                if isShowingLaunchLoading {
                    SpendWiseLoadingView()
                        .transition(.opacity)
                } else if hasSeenOnboarding && hasCompletedInitialSetup {
                    ContentView()
                        .transition(.opacity)
                } else if hasSeenOnboarding {
                    InitialSetupWizardView {
                        hasCompletedInitialSetup = true
                    }
                    .transition(.opacity)
                } else {
                    OnboardingView {
                        hasCompletedInitialSetup = false
                        hasSeenOnboarding = true
                    }
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.25), value: isShowingLaunchLoading)
            .task {
                try? await Task.sleep(for: .milliseconds(650))
                isShowingLaunchLoading = false
            }
            .tint(AppPalette.primary)
            .preferredColorScheme(.light)
        }
        .modelContainer(sharedModelContainer)
    }
}

private struct SpendWiseLoadingView: View {
    var body: some View {
        ZStack {
            AppPalette.appBackground
                .ignoresSafeArea()

            VStack(spacing: 18) {
                Image("SpendWiseIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 86, height: 86)
                    .shadow(color: AppPalette.background.opacity(0.14), radius: 18, y: 10)

                Text(AppStrings.text(.appName))
                    .font(.largeTitle.bold())
                    .foregroundStyle(AppPalette.background)

                ProgressView()
                    .tint(AppPalette.primary)
                    .padding(.top, 4)
            }
        }
    }
}
