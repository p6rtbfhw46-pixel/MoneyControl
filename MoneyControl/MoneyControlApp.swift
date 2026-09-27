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

private enum ModelContainerLoadState {
    case loaded(ModelContainer)
    case failed(String)
}

@main
struct MoneyControlApp: App {
#if os(iOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
#endif

    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @AppStorage("hasCompletedInitialSetup") private var hasCompletedInitialSetup = false
    @AppStorage(AppPreferences.appLockEnabledKey) private var appLockEnabled = false
    @Environment(\.scenePhase) private var scenePhase
    @State private var isShowingLaunchLoading = true
    @State private var isAppUnlocked = false

    @State private var modelContainerState = MoneyControlApp.makeModelContainerState()

    private var shouldRequireUnlock: Bool {
        hasSeenOnboarding && hasCompletedInitialSetup && appLockEnabled && AppLockService.hasPIN && !isAppUnlocked
    }

    private static func makeModelContainerState() -> ModelContainerLoadState {
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
            Planning.self,
            PlanningItemType.self,
            PlanningItem.self,
            PlanningMovement.self,
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none
        )

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            return .loaded(container)
        } catch {
            return .failed(String(describing: error))
        }
    }

    var body: some Scene {
        WindowGroup {
            switch modelContainerState {
            case .loaded(let container):
                appRoot
                    .modelContainer(container)
            case .failed(let errorMessage):
                ModelContainerErrorView(errorMessage: errorMessage) {
                    modelContainerState = MoneyControlApp.makeModelContainerState()
                }
                .tint(AppPalette.primary)
                .preferredColorScheme(.light)
            }
        }
    }

    private var appRoot: some View {
        ZStack {
            Group {
                if hasSeenOnboarding && hasCompletedInitialSetup {
                    authenticatedAppContent
                } else if hasSeenOnboarding {
                    InitialSetupWizardView {
                        hasCompletedInitialSetup = true
                    }
                    .transition(.opacity)
                    .onAppear(perform: markLaunchContentReady)
                } else {
                    OnboardingView {
                        hasCompletedInitialSetup = false
                        hasSeenOnboarding = true
                    }
                    .transition(.opacity)
                    .onAppear(perform: markLaunchContentReady)
                }
            }

            if isShowingLaunchLoading && !shouldRequireUnlock {
                SpendWiseLoadingView()
                    .transition(.opacity)
                    .zIndex(2)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: isShowingLaunchLoading)
        .animation(.easeInOut(duration: 0.2), value: isAppUnlocked)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase != .active, hasCompletedInitialSetup, appLockEnabled {
                isAppUnlocked = false
            }
        }
        .tint(AppPalette.primary)
        .preferredColorScheme(.light)
    }

    private var authenticatedAppContent: some View {
        ZStack {
            if shouldRequireUnlock {
                AppLockView(mode: .unlock) {
                    isShowingLaunchLoading = true
                    isAppUnlocked = true
                }
                .transition(.opacity)
                .onAppear(perform: markLaunchContentReady)
                .zIndex(1)
            } else {
                ContentView()
                    .onAppear(perform: markLaunchContentReady)
            }
        }
    }

    private func markLaunchContentReady() {
        guard isShowingLaunchLoading else { return }
        Task { @MainActor in
            await Task.yield()
            isShowingLaunchLoading = false
        }
    }
}

private struct ModelContainerErrorView: View {
    let errorMessage: String
    let retry: () -> Void

    var body: some View {
        ZStack {
            AppPalette.appBackground
                .ignoresSafeArea()

            VStack(spacing: 18) {
                Image(systemName: "externaldrive.badge.exclamationmark")
                    .font(.system(size: 46, weight: .semibold))
                    .foregroundStyle(AppPalette.primary)
                    .frame(width: 86, height: 86)
                    .background(AppPalette.paleOrange, in: Circle())

                VStack(spacing: 8) {
                    Text(AppStrings.text(.dataStoreErrorTitle))
                        .font(.title2.bold())
                        .foregroundStyle(AppPalette.background)
                        .multilineTextAlignment(.center)

                    Text(AppStrings.text(.dataStoreErrorMessage))
                        .font(.body)
                        .foregroundStyle(AppPalette.secondaryText)
                        .multilineTextAlignment(.center)
                }

                ScrollView {
                    Text(errorMessage)
                        .font(.caption.monospaced())
                        .foregroundStyle(AppPalette.secondaryText)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                }
                .frame(maxHeight: 160)
                .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                Button(action: retry) {
                    Label(AppStrings.text(.tryAgain), systemImage: "arrow.clockwise")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding(24)
        }
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
