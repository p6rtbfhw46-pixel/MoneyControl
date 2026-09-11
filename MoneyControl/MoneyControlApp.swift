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

    // ICLOUD_DISABLED_FOR_LOCAL_RESET_TEST: CloudKit disabled while validating clean local installs.
    // private static let cloudKitContainerIdentifier = "iCloud.com.skyIsTheLimit.MoneyControl"

    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @AppStorage("hasCompletedInitialSetup") private var hasCompletedInitialSetup = false
    @AppStorage(AppPreferences.appLockEnabledKey) private var appLockEnabled = false
    @Environment(\.scenePhase) private var scenePhase
    @State private var isShowingLaunchLoading = true
    @State private var isAppUnlocked = false

    @State private var sharedModelContainer = MoneyControlApp.makeModelContainer()

    private static func prepareLocalResetTestStateIfNeeded() {
        // ICLOUD_DISABLED_FOR_LOCAL_RESET_TEST: prevent restored preferences from re-enabling sync.
        UserDefaults.standard.set(false, forKey: AppPreferences.iCloudSyncEnabledKey)

        let resetMarkerKey = "didPrepareLocalResetTestState"
        guard !UserDefaults.standard.bool(forKey: resetMarkerKey) else { return }

        AppLockService.deletePIN()
        UserDefaults.standard.removeObject(forKey: AppPreferences.appLockEnabledKey)
        UserDefaults.standard.removeObject(forKey: AppPreferences.appLockBiometricsEnabledKey)
        UserDefaults.standard.set(true, forKey: resetMarkerKey)
    }

    private static func makeModelContainer() -> ModelContainer {
        prepareLocalResetTestStateIfNeeded()

        let schema = Schema([
            MoneyTransaction.self,
            ExpensePayment.self,
            PaymentHistoryEntry.self,
            RecurrenceExclusion.self,
            CreditAccount.self,
            CreditMovement.self,
            SavingAccount.self,
            SavingMovement.self,
            SpendAccount.self,
            AccountMovement.self,
            AuditLogEntry.self,
        ])
        // ICLOUD_DISABLED_FOR_LOCAL_RESET_TEST: force local-only SwiftData storage.
        /*
        let isICloudSyncEnabled = UserDefaults.standard.bool(forKey: AppPreferences.iCloudSyncEnabledKey)
        let cloudKitDatabase: ModelConfiguration.CloudKitDatabase = isICloudSyncEnabled
            ? .private(cloudKitContainerIdentifier)
            : .none
        */
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // ICLOUD_DISABLED_FOR_LOCAL_RESET_TEST: CloudKit fallback path disabled with local-only storage.
            /*
            if isICloudSyncEnabled {
                UserDefaults.standard.set(false, forKey: AppPreferences.iCloudSyncEnabledKey)
                let fallbackConfiguration = ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: false,
                    cloudKitDatabase: .none
                )

                if let fallbackContainer = try? ModelContainer(for: schema, configurations: [fallbackConfiguration]) {
                    return fallbackContainer
                }
            }
            */

            fatalError("Could not create local ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if isShowingLaunchLoading {
                    SpendWiseLoadingView()
                        .transition(.opacity)
                } else if hasSeenOnboarding && hasCompletedInitialSetup && appLockEnabled && AppLockService.hasPIN && !isAppUnlocked {
                    AppLockView(mode: .unlock) {
                        isAppUnlocked = true
                    }
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
            .animation(.easeInOut(duration: 0.2), value: isAppUnlocked)
            .task {
                try? await Task.sleep(for: .milliseconds(650))
                isShowingLaunchLoading = false
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase != .active, hasCompletedInitialSetup, appLockEnabled {
                    isAppUnlocked = false
                }
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
