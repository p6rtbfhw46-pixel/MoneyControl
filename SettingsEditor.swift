//
//  SettingsEditor.swift
//  MoneyControl
//

import CryptoKit
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct SettingsEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @AppStorage("hasCompletedInitialSetup") private var hasCompletedInitialSetup = false
    @AppStorage(AppPreferences.selectedCurrencyCodeKey) private var selectedCurrencyCode = ""
    @AppStorage(AppColorPalette.storageKey) private var selectedColorPalette = AppColorPalette.original.rawValue
    @AppStorage(AppPreferences.appLockEnabledKey) private var appLockEnabled = false
    @AppStorage(AppPreferences.appLockBiometricsEnabledKey) private var appLockBiometricsEnabled = false
    @AppStorage(AppPreferences.notificationsEnabledKey) private var notificationsEnabled = true
    @AppStorage(AppPreferences.launchPaymentReminderEnabledKey) private var launchPaymentReminderEnabled = true
    @AppStorage(AppPreferences.showsCurrentAccountBalanceCardKey) private var showsCurrentAccountBalanceCard = true
    @AppStorage(AppPreferences.showsCurrentAccountPlanningCardsKey) private var showsCurrentAccountPlanningCards = true
    @Query private var transactions: [MoneyTransaction]
    @Query private var payments: [ExpensePayment]
    @Query private var paymentHistory: [PaymentHistoryEntry]
    @Query private var exclusions: [RecurrenceExclusion]
    @Query private var creditAccounts: [CreditAccount]
    @Query private var creditMovements: [CreditMovement]
    @Query private var savingAccounts: [SavingAccount]
    @Query private var savingMovements: [SavingMovement]
    @Query private var spendAccounts: [SpendAccount]
    @Query private var accountMovements: [AccountMovement]
    @Query private var auditLogEntries: [AuditLogEntry]
    @Query private var plannings: [Planning]
    @Query private var planningItemTypes: [PlanningItemType]
    @Query private var planningItems: [PlanningItem]
    @Query private var planningMovements: [PlanningMovement]
    @State private var editorRequest: TransactionEditorRequest?
    @State private var saveNotice: SaveResultNotice?
    @State private var selectedList = 0
    @State private var selectedListDirection = 1
    @State private var selectedTab: SettingsTab = .budget
    @State private var pendingAction: SettingsListAction?
    @State private var showsDeleteAllDataConfirmation = false
    @State private var isExportingBackup = false
    @State private var isImportingBackup = false
    @State private var backupDocument = SpendWiseBackupDocument(data: Data())
    @State private var pendingImportedBackup: SpendWiseBackup?
    @State private var pendingEncryptedBackup: EncryptedSpendWiseBackup?
    @State private var backupNotice: BackupNotice?
    @State private var backupHelp: BackupNotice?
    @State private var showsExportPasswordPrompt = false
    @State private var showsImportPasswordPrompt = false
    @State private var exportPassword = ""
    @State private var exportPasswordConfirmation = ""
    @State private var importPassword = ""
    @State private var showsAppLockSetup = false
    @State private var showsDisableAppLockConfirmation = false

    init(openingTab: SettingsTab = .budget) {
        _selectedTab = State(initialValue: openingTab)
    }

    init(openingCredits: Bool) {
        _selectedTab = State(initialValue: openingCredits ? .credits : .budget)
    }

    private var nextMonth: Date {
        Date().monthStart.nextMonthStart
    }

    private var recurringExpenses: [MoneyTransaction] {
        transactions
            .filter { $0.kind == TransactionKind.expense.rawValue && $0.isRecurring && $0.isVisibleInSettingsList }
            .sorted { first, second in
                if first.day != second.day { return first.day < second.day }
                return first.displayName.localizedCaseInsensitiveCompare(second.displayName) == .orderedAscending
            }
    }

    private var recurringIncome: [MoneyTransaction] {
        transactions
            .filter { $0.kind == TransactionKind.income.rawValue && $0.isRecurring && $0.isVisibleInSettingsList }
            .sorted { first, second in
                if first.day != second.day { return first.day < second.day }
                return first.title.localizedCaseInsensitiveCompare(second.title) == .orderedAscending
            }
    }

    private var selectedListTitle: String {
        selectedList == 0 ? AppStrings.text(.recurringExpenses) : AppStrings.text(.recurringIncome)
    }

    private var backupFilename: String {
        "spendwise-backup-\(Date().backupFilenameDate).json"
    }

    private var currencyCodes: [String] {
        Locale.commonISOCurrencyCodes.sorted()
    }

    private var showsBackupHelp: Binding<Bool> {
        Binding(
            get: { backupHelp != nil },
            set: { if !$0 { backupHelp = nil } }
        )
    }

    private var hasPendingImportedBackup: Binding<Bool> {
        Binding(
            get: { pendingImportedBackup != nil },
            set: { if !$0 { pendingImportedBackup = nil } }
        )
    }

    private var showsBackupNotice: Binding<Bool> {
        Binding(
            get: { backupNotice != nil },
            set: { if !$0 { backupNotice = nil } }
        )
    }

    var body: some View {
        NavigationStack {
            appSettingsView
                .background(AppPalette.appBackground)
                .navigationTitle(AppStrings.text(.settings))
            .toolbarBackground(AppPalette.appBackground, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(AppStrings.text(.ok)) { dismiss() }
                        .liquidGlassButtonStyle()
                }
            }
            .sheet(item: $editorRequest) { request in
                TransactionEditor(request: request, onSaved: presentSaveNoticeAfterEditorCloses)
            }
            .overlay {
                if let saveNotice {
                    SaveResultNoticeOverlay(notice: saveNotice) {
                        self.saveNotice = nil
                    }
                }
            }
            .alert(
                pendingAction?.title ?? "",
                isPresented: Binding(
                    get: { pendingAction != nil },
                    set: { if !$0 { pendingAction = nil } }
                ),
                presenting: pendingAction
            ) { action in
                Button(AppStrings.text(.cancel), role: .cancel) {}
                Button(action.confirmationButtonTitle, role: action.isDestructive ? .destructive : nil) {
                    perform(action)
                }
            } message: { action in
                Text(action.message)
            }
        }
    }

    private var appSettingsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text(AppStrings.text(.applicationSection).uppercased())
                    .font(.caption.bold())
                    .foregroundStyle(AppPalette.background)
                    .padding(.horizontal, 4)

                VStack(spacing: 0) {
                    appSettingsNavigationRow(
                        title: AppStrings.text(.preferences),
                        subtitle: "",
                        systemImage: "gearshape",
                        destination: appPreferencesView
                    )

                    Divider().padding(.leading, 74)

                    appSettingsNavigationRow(
                        title: AppStrings.text(.dataPrivacy),
                        subtitle: AppStrings.text(.dataPrivacySubtitle),
                        systemImage: "lock.shield",
                        destination: appDataPrivacyView
                    )

                    Divider().padding(.leading, 74)

                    appSettingsNavigationRow(
                        title: AppStrings.text(.aboutSpendWise),
                        subtitle: AppStrings.text(.aboutSpendWiseSubtitle),
                        systemImage: "info.circle",
                        destination: appAboutView
                    )
                }
                .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 22))
                .shadow(color: AppPalette.background.opacity(0.06), radius: 14, y: 8)
            }
            .padding()
        }
        .foregroundStyle(AppPalette.background)
        .tint(AppPalette.background)
        .background(AppPalette.appBackground)
    }

    private func presentSaveNoticeAfterEditorCloses(_ notice: SaveResultNotice) {
        saveNotice = notice
        editorRequest = nil
    }

    private func appSettingsNavigationRow<Destination: View>(
        title: String,
        subtitle: String,
        systemImage: String,
        destination: Destination
    ) -> some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 16) {
                Image(systemName: systemImage)
                    .font(.title2.weight(.medium))
                    .foregroundStyle(AppPalette.background)
                    .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline.bold())
                        .foregroundStyle(AppPalette.background)
                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(AppPalette.mutedText)
                            .multilineTextAlignment(.leading)
                    }
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppPalette.mutedText)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var appPreferencesView: some View {
        Form {
            Section {
                Picker(selection: $selectedCurrencyCode) {
                    Text("\(AppStrings.text(.deviceRegionCurrency)) (\(AppPreferences.deviceCurrencyCode))")
                        .tag("")
                    ForEach(currencyCodes, id: \.self) { code in
                        Text(currencyOptionTitle(for: code))
                            .tag(code)
                    }
                } label: {
                    Label(AppStrings.text(.currency), systemImage: "coloncurrencysign.circle")
                }

                Text(AppStrings.text(.currencyFormatHelp))
                    .font(.caption)
                    .foregroundStyle(AppPalette.mutedText)
            }
            .listRowBackground(AppPalette.surface)

            Section {
                Toggle(isOn: $notificationsEnabled) {
                    Label("Notificações", systemImage: notificationsEnabled ? "bell.fill" : "bell.slash")
                        .font(.headline.bold())
                        .foregroundStyle(AppPalette.background)
                }
                .tint(AppPalette.primary)

                Text("A app pode usar notificações para avisos importantes, como despesas por pagar e lembretes relacionados com o orçamento.")
                    .font(.caption)
                    .foregroundStyle(AppPalette.mutedText)
                    .fixedSize(horizontal: false, vertical: true)

                Toggle(isOn: $launchPaymentReminderEnabled) {
                    Label("Aviso ao abrir a app", systemImage: "exclamationmark.circle")
                        .font(.headline.bold())
                        .foregroundStyle(AppPalette.background)
                }
                .tint(AppPalette.primary)

                Text("Mostra um aviso no início ao abrir a app quando existir algo a pagar.")
                    .font(.caption)
                    .foregroundStyle(AppPalette.mutedText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .listRowBackground(AppPalette.surface)

            Section {
                Toggle(isOn: $showsCurrentAccountBalanceCard) {
                    Label(
                        AppStrings.currentLanguage == .portuguese
                            ? "Mostrar saldo disponível"
                            : "Show available balance",
                        systemImage: "creditcard"
                    )
                    .font(.headline.bold())
                    .foregroundStyle(AppPalette.background)
                }
                .tint(AppPalette.primary)

                Text(
                    AppStrings.currentLanguage == .portuguese
                        ? "O cartão apresenta o saldo disponível nas contas. Desative esta opção para ocultá-lo da Conta Corrente."
                        : "This card shows the balance available in your accounts. Turn this option off to hide it from the Current Account."
                )
                .font(.caption)
                .foregroundStyle(AppPalette.mutedText)
                .fixedSize(horizontal: false, vertical: true)

                Toggle(isOn: $showsCurrentAccountPlanningCards) {
                    Label(
                        AppStrings.currentLanguage == .portuguese
                            ? "Mostrar cartões do mês"
                            : "Show monthly cards",
                        systemImage: "rectangle.grid.2x2"
                    )
                    .font(.headline.bold())
                    .foregroundStyle(AppPalette.background)
                }
                .tint(AppPalette.primary)

                Text(
                    AppStrings.currentLanguage == .portuguese
                        ? "Ainda por Pagar apresenta as despesas pendentes. Disponível no mês mostra quanto poderá ficar disponível depois das receitas e despesas previstas. Desative esta opção para ocultar os dois cartões."
                        : "Unpaid shows pending expenses. Available this month shows what may remain after expected income and expenses. Turn this option off to hide both cards."
                )
                .font(.caption)
                .foregroundStyle(AppPalette.mutedText)
                .fixedSize(horizontal: false, vertical: true)
            } header: {
                Text(
                    AppStrings.currentLanguage == .portuguese
                        ? "Conta Corrente"
                        : "Current Account"
                )
            }
            .listRowBackground(AppPalette.surface)

            Section(AppStrings.text(.appearance)) {
                Text(AppStrings.text(.colorPalette))
                    .font(.headline.bold())
                    .foregroundStyle(AppPalette.background)

                ForEach(AppColorPalette.allCases) { palette in
                    Button {
                        selectedColorPalette = palette.rawValue
                    } label: {
                        HStack(spacing: 12) {
                            HStack(spacing: 0) {
                                ForEach(palette.previewColors.indices, id: \.self) { index in
                                    palette.previewColors[index]
                                        .frame(width: 22, height: 34)
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                            Text(palette.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppPalette.background)

                            Spacer()

                            Image(systemName: selectedColorPalette == palette.rawValue ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundStyle(
                                    selectedColorPalette == palette.rawValue
                                        ? AppPalette.primary
                                        : AppPalette.secondaryText
                                )
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }

                Text(AppStrings.text(.colorPaletteHelp))
                    .font(.caption)
                    .foregroundStyle(AppPalette.mutedText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .listRowBackground(AppPalette.surface)

        }
        .navigationTitle(AppStrings.text(.preferences))
        .navigationBarTitleDisplayMode(.inline)
        .scrollContentBackground(.hidden)
        .foregroundStyle(AppPalette.background)
        .tint(AppPalette.background)
        .background(AppPalette.appBackground)
    }

    private var appDataPrivacyView: some View {
        Form {
            Section {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "shield.checkered")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(AppPalette.savings)
                        .frame(width: 34, height: 34)
                        .background(AppPalette.mintSurface, in: Circle())

                    VStack(alignment: .leading, spacing: 6) {
                        Text(AppStrings.text(.appSecurityTitle))
                            .font(.headline.bold())
                            .foregroundStyle(AppPalette.background)

                        Text(AppStrings.text(.appSecurityMessage))
                            .font(.subheadline)
                            .foregroundStyle(AppPalette.mutedText)
                            .fixedSize(horizontal: false, vertical: true)

                    }
                }
                .padding(.vertical, 4)
            }
            .listRowBackground(AppPalette.surface)

            Section {
                Button {
                    if appLockEnabled {
                        showsDisableAppLockConfirmation = true
                    } else {
                        showsAppLockSetup = true
                    }
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: appLockEnabled ? "lock.fill" : "lock.open")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(appLockEnabled ? AppPalette.background : AppPalette.mutedText)
                            .frame(width: 30, height: 30)

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Bloquear app com código")
                                .font(.headline.bold())
                                .foregroundStyle(AppPalette.background)

                            Text(appLockEnabled ? "A SpendWise pede autenticação ao voltar à app." : "Crie um código de 4 dígitos para proteger o acesso à app.")
                                .font(.subheadline)
                                .foregroundStyle(AppPalette.mutedText)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer()

                        Image(systemName: appLockEnabled ? "checkmark.circle.fill" : "circle")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(appLockEnabled ? AppPalette.positive : AppPalette.secondaryText)
                    }
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Button {
                    appLockBiometricsEnabled.toggle()
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: appLockBiometricsEnabled ? "checkmark.square.fill" : "square")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(appLockBiometricsEnabled ? AppPalette.primary : AppPalette.mutedText)
                            .frame(width: 30, height: 30)

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Usar \(AppLockService.biometricTypeName)")
                                .font(.headline.bold())
                                .foregroundStyle(AppPalette.background)

                            Text("Permite desbloquear com biometria e manter o código como alternativa.")
                                .font(.subheadline)
                                .foregroundStyle(AppPalette.mutedText)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(!appLockEnabled || !AppLockService.biometricsAvailable)
                .opacity(appLockEnabled && AppLockService.biometricsAvailable ? 1 : 0.45)
            }
            .listRowBackground(AppPalette.surface)

            Section {
                Text(AppStrings.text(.appDataPrivacyNote))
                    .font(.subheadline)
                    .foregroundStyle(AppPalette.mutedText)

                BackupActionRow(
                    title: AppStrings.text(.exportBackup),
                    systemImage: "square.and.arrow.up",
                    helpMessage: AppStrings.text(.exportBackupHelp),
                    onHelp: { backupHelp = BackupNotice(title: AppStrings.text(.exportBackup), message: $0) },
                    action: {
                        exportPassword = ""
                        exportPasswordConfirmation = ""
                        showsExportPasswordPrompt = true
                    }
                )

                BackupActionRow(
                    title: AppStrings.text(.importBackup),
                    systemImage: "square.and.arrow.down",
                    helpMessage: AppStrings.text(.importBackupHelp),
                    onHelp: { backupHelp = BackupNotice(title: AppStrings.text(.importBackup), message: $0) },
                    action: { isImportingBackup = true }
                )

                BackupActionRow(
                    title: AppStrings.text(.deleteAllData),
                    systemImage: "trash",
                    helpMessage: AppStrings.text(.deleteAllDataMessage),
                    isDestructive: true,
                    onHelp: { backupHelp = BackupNotice(title: AppStrings.text(.deleteAllData), message: $0) },
                    action: { showsDeleteAllDataConfirmation = true }
                )
            }
            .listRowBackground(AppPalette.surface)
        }
        .navigationTitle(AppStrings.text(.dataPrivacy))
        .navigationBarTitleDisplayMode(.inline)
        .scrollContentBackground(.hidden)
        .foregroundStyle(AppPalette.background)
        .tint(AppPalette.background)
        .background(AppPalette.appBackground)
        .sheet(isPresented: $showsAppLockSetup) {
            AppLockView(mode: .setup, allowsBiometrics: false) {
                appLockEnabled = true
                appLockBiometricsEnabled = AppLockService.biometricsAvailable
                showsAppLockSetup = false
            }
        }
        .alert("Remover bloqueio da app?", isPresented: $showsDisableAppLockConfirmation) {
            Button(AppStrings.text(.cancel), role: .cancel) {}
            Button("Remover", role: .destructive) {
                AppLockService.deletePIN()
                appLockEnabled = false
                appLockBiometricsEnabled = false
            }
        } message: {
            Text("A app deixará de pedir código ou biometria ao abrir.")
        }
        .alert(AppStrings.text(.deleteAllDataTitle), isPresented: $showsDeleteAllDataConfirmation) {
            Button(AppStrings.text(.cancel), role: .cancel) {}
            Button(AppStrings.text(.delete), role: .destructive, action: deleteAllData)
        } message: {
            Text(AppStrings.text(.deleteAllDataMessage))
        }
        .alert(backupHelp?.title ?? "", isPresented: showsBackupHelp) {
            Button(AppStrings.text(.ok)) { backupHelp = nil }
        } message: {
            Text(backupHelp?.message ?? "")
        }
        .alert("Encriptar backup", isPresented: $showsExportPasswordPrompt) {
            SecureField("Palavra-passe", text: $exportPassword)
            SecureField("Confirmar palavra-passe", text: $exportPasswordConfirmation)
            Button(AppStrings.text(.cancel), role: .cancel) {
                exportPassword = ""
                exportPasswordConfirmation = ""
            }
            Button(AppStrings.text(.exportBackup)) {
                exportEncryptedBackup()
            }
        } message: {
            Text("Defina uma palavra-passe para proteger o ficheiro. Vai precisar dela para importar este backup.")
        }
        .alert(AppStrings.text(.importBackupConfirmationTitle), isPresented: hasPendingImportedBackup) {
            Button(AppStrings.text(.cancel), role: .cancel) { pendingImportedBackup = nil }
            Button(AppStrings.text(.continueAction), role: .destructive, action: importPendingBackup)
        } message: {
            Text(AppStrings.text(.importBackupConfirmationMessage))
        }
        .alert("Backup encriptado", isPresented: $showsImportPasswordPrompt) {
            SecureField("Palavra-passe", text: $importPassword)
            Button(AppStrings.text(.cancel), role: .cancel) {
                pendingEncryptedBackup = nil
                importPassword = ""
            }
            Button(AppStrings.text(.importBackup)) {
                decryptPendingBackup()
            }
        } message: {
            Text("Introduza a palavra-passe usada ao exportar este backup.")
        }
        .alert(backupNotice?.title ?? "", isPresented: showsBackupNotice) {
            Button(AppStrings.text(.ok)) { backupNotice = nil }
        } message: {
            Text(backupNotice?.message ?? "")
        }
        .fileExporter(
            isPresented: $isExportingBackup,
            document: backupDocument,
            contentType: .json,
            defaultFilename: backupFilename
        ) { result in
            handleExportResult(result)
        }
        .fileImporter(isPresented: $isImportingBackup, allowedContentTypes: [.json]) { result in
            handleImportResult(result)
        }
    }

    private var appAboutView: some View {
        Form {
            Section {
                LabeledContent(AppStrings.text(.appName), value: AppStrings.text(.appName))
                LabeledContent(AppStrings.text(.appVersion), value: appVersionText)
            }
            .listRowBackground(AppPalette.surface)

            Section {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(AppPalette.background)
                        .frame(width: 34, height: 34)
                        .background(AppPalette.mintSurface, in: Circle())

                    VStack(alignment: .leading, spacing: 6) {
                        Text(AppStrings.text(.aboutSpendWisePurposeTitle))
                            .font(.headline.bold())
                            .foregroundStyle(AppPalette.background)

                        Text(AppStrings.text(.aboutSpendWisePurposeMessage))
                            .font(.subheadline)
                            .foregroundStyle(AppPalette.mutedText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.vertical, 4)
            }
            .listRowBackground(AppPalette.surface)
        }
        .navigationTitle(AppStrings.text(.aboutSpendWise))
        .navigationBarTitleDisplayMode(.inline)
        .scrollContentBackground(.hidden)
        .foregroundStyle(AppPalette.background)
        .tint(AppPalette.background)
        .background(AppPalette.appBackground)
    }

    private var appVersionText: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? ""
        return build.isEmpty ? version : "\(version) (\(build))"
    }

    private var budgetSettingsView: some View {
        VStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 12) {
                settingsListHeader

                selectedSettingsList
                    .id(selectedList)
                    .transition(settingsListTransition)
                    .animation(.snappy, value: selectedList)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 28))

            VStack(alignment: .leading, spacing: 12) {
                Text(AppStrings.text(.add))
                    .font(.headline.bold())
                    .foregroundStyle(AppPalette.background)

                BudgetAddActionRow(
                    title: AppStrings.text(.monthlyExpense),
                    systemImage: "calendar.badge.clock",
                    helpMessage: AppStrings.text(.monthlyExpenseHelp),
                    action: {
                    selectSettingsList(0)
                    editorRequest = TransactionEditorRequest(mode: .monthlyExpense, month: Date().monthStart)
                    },
                    onHelp: { backupHelp = BackupNotice(title: AppStrings.text(.monthlyExpense), message: $0) }
                )

                BudgetAddActionRow(
                    title: AppStrings.text(.salary),
                    systemImage: "banknote",
                    helpMessage: AppStrings.text(.salaryHelp),
                    action: {
                    selectSettingsList(1)
                    editorRequest = TransactionEditorRequest(mode: .salary, month: Date().monthStart)
                    },
                    onHelp: { backupHelp = BackupNotice(title: AppStrings.text(.salary), message: $0) }
                )

                BudgetAddActionRow(
                    title: AppStrings.text(.periodicExpense),
                    systemImage: "calendar.badge.plus",
                    helpMessage: AppStrings.text(.periodicExpenseHelp),
                    action: {
                    selectSettingsList(2)
                    editorRequest = TransactionEditorRequest(mode: .periodicExpense, month: Date().monthStart)
                    },
                    onHelp: { backupHelp = BackupNotice(title: AppStrings.text(.periodicExpense), message: $0) }
                )
            }
            .padding(16)
            .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 28))

        }
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom)
        .foregroundStyle(AppPalette.background)
        .tint(AppPalette.background)
        .background(AppPalette.appBackground)
    }

    private func currencyOptionTitle(for code: String) -> String {
        if let currencyName = Locale.autoupdatingCurrent.localizedString(forCurrencyCode: code) {
            return "\(code) · \(currencyName)"
        }
        return code
    }

    @ViewBuilder
    private var selectedSettingsList: some View {
        if selectedList == 0 {
            RecurringList(
                emptyTitle: AppStrings.text(.recurringExpenses),
                transactions: recurringExpenses,
                payments: payments,
                onEdit: editRecurringTransaction,
                onSetEnabled: { pendingAction = SettingsListAction(kind: $1 ? .activate : .deactivate, transaction: $0) },
                onDelete: { pendingAction = SettingsListAction(kind: .delete, transaction: $0) }
            )
        } else {
            RecurringList(
                emptyTitle: AppStrings.text(.recurringIncome),
                transactions: recurringIncome,
                payments: payments,
                onEdit: editRecurringTransaction,
                onSetEnabled: { pendingAction = SettingsListAction(kind: $1 ? .activate : .deactivate, transaction: $0) },
                onDelete: { pendingAction = SettingsListAction(kind: .delete, transaction: $0) }
            )
        }
    }

    private var settingsListTransition: AnyTransition {
        let insertionEdge: Edge = selectedListDirection > 0 ? .trailing : .leading
        let removalEdge: Edge = selectedListDirection > 0 ? .leading : .trailing

        return .asymmetric(
            insertion: .move(edge: insertionEdge).combined(with: .opacity),
            removal: .move(edge: removalEdge).combined(with: .opacity)
        )
    }

    private var settingsListHeader: some View {
        HStack(spacing: 12) {
            settingsListArrow(systemImage: "chevron.left") {
                moveSelectedList(by: -1)
            }
            .disabled(selectedList <= 0)
            .opacity(selectedList <= 0 ? 0.35 : 1)

            Text(selectedListTitle)
                .font(.headline)
                .foregroundStyle(AppPalette.background)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
                .frame(maxWidth: .infinity, alignment: .center)

            settingsListArrow(systemImage: "chevron.right") {
                moveSelectedList(by: 1)
            }
            .disabled(selectedList >= 1)
            .opacity(selectedList >= 1 ? 0.35 : 1)
        }
    }

    private func moveSelectedList(by value: Int) {
        selectedListDirection = value
        selectedList = min(max(selectedList + value, 0), 1)
    }

    private func selectSettingsList(_ index: Int) {
        guard index != selectedList else { return }
        selectedListDirection = index > selectedList ? 1 : -1
        selectedList = min(max(index, 0), 1)
    }

    private func editRecurringTransaction(_ transaction: MoneyTransaction) {
        if let editStartMonth = confirmedEditStartMonth(for: transaction) {
            pendingAction = SettingsListAction(kind: .edit, transaction: transaction, editStartMonth: editStartMonth)
        } else {
            editorRequest = TransactionEditorRequest(transaction: transaction, month: nextMonth, editScope: .futureMonths)
        }
    }

    private func confirmedEditStartMonth(for transaction: MoneyTransaction) -> Date? {
        let currentMonth = Date().monthStart
        guard transaction.kind == TransactionKind.expense.rawValue,
              transaction.occurs(in: currentMonth, exclusions: exclusions) else {
            return nil
        }

        let payment = payments.first {
            $0.transactionID == transaction.id &&
            Calendar.current.isDate($0.monthStart, equalTo: currentMonth, toGranularity: .month)
        }
        let paidAmount = payment?.amountPaid ?? (payment == nil ? 0 : transaction.amount)
        if paidAmount <= 0 {
            return currentMonth
        }
        if paidAmount < transaction.amount {
            return nextMonth
        }
        return nil
    }

    private func settingsListArrow(systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.headline)
                .foregroundStyle(AppPalette.primary)
                .frame(width: 38, height: 38)
                .background {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.white, AppPalette.surface],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay {
                            Circle()
                                .stroke(.white.opacity(0.9), lineWidth: 1)
                        }
                        .shadow(color: AppPalette.background.opacity(0.12), radius: 10, y: 5)
                        .shadow(color: .white.opacity(0.85), radius: 2, x: -1, y: -1)
                }
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
    }

    private func exportEncryptedBackup() {
        do {
            guard !exportPassword.isEmpty else {
                throw BackupError.emptyPassword
            }
            guard exportPassword == exportPasswordConfirmation else {
                throw BackupError.passwordMismatch
            }

            let backupData = try encodedBackupData()
            let encryptedBackup = try EncryptedSpendWiseBackup(backupData: backupData, password: exportPassword)
            backupDocument = SpendWiseBackupDocument(data: try encodedData(for: encryptedBackup))
            exportPassword = ""
            exportPasswordConfirmation = ""
            isExportingBackup = true
        } catch {
            backupNotice = BackupNotice(
                title: AppStrings.text(.exportBackupFailureTitle),
                message: backupErrorMessage(error)
            )
        }
    }

    private func handleExportResult(_ result: Result<URL, Error>) {
        switch result {
        case .success:
            backupNotice = BackupNotice(
                title: AppStrings.text(.exportBackupSuccessTitle),
                message: AppStrings.text(.exportBackupSuccessMessage)
            )
        case .failure(let error):
            backupNotice = BackupNotice(
                title: AppStrings.text(.exportBackupFailureTitle),
                message: error.localizedDescription
            )
        }
    }

    private func handleImportResult(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            do {
                let canAccess = url.startAccessingSecurityScopedResource()
                defer {
                    if canAccess {
                        url.stopAccessingSecurityScopedResource()
                    }
                }

                let data = try Data(contentsOf: url)
                if let backup = try? decodedBackup(from: data) {
                    pendingImportedBackup = backup
                } else if let encryptedBackup = try? JSONDecoder().decode(EncryptedSpendWiseBackup.self, from: data) {
                    pendingEncryptedBackup = encryptedBackup
                    importPassword = ""
                    showsImportPasswordPrompt = true
                } else {
                    throw BackupError.invalidBackup
                }
            } catch {
                backupNotice = BackupNotice(
                    title: AppStrings.text(.importBackupFailureTitle),
                    message: AppStrings.text(.importBackupFailureMessage)
                )
            }
        case .failure(let error):
            backupNotice = BackupNotice(
                title: AppStrings.text(.importBackupFailureTitle),
                message: error.localizedDescription
            )
        }
    }

    private func decryptPendingBackup() {
        do {
            guard let pendingEncryptedBackup else {
                throw BackupError.invalidBackup
            }
            guard !importPassword.isEmpty else {
                throw BackupError.emptyPassword
            }

            let backupData = try pendingEncryptedBackup.decrypt(password: importPassword)
            pendingImportedBackup = try decodedBackup(from: backupData)
            self.pendingEncryptedBackup = nil
            importPassword = ""
        } catch {
            backupNotice = BackupNotice(
                title: AppStrings.text(.importBackupFailureTitle),
                message: backupErrorMessage(error)
            )
        }
    }

    private func encodedBackupData() throws -> Data {
        let backup = SpendWiseBackup(
            transactions: transactions.map { BackupTransaction(transaction: $0) },
            payments: payments.map { BackupPayment(payment: $0) },
            paymentHistory: paymentHistory.map { BackupPaymentHistoryEntry(entry: $0) },
            exclusions: exclusions.map { BackupExclusion(exclusion: $0) },
            creditAccounts: creditAccounts.map { BackupCreditAccount(credit: $0) },
            creditMovements: creditMovements.map { BackupCreditMovement(movement: $0) },
            savingAccounts: savingAccounts.map { BackupSavingAccount(saving: $0) },
            savingMovements: savingMovements.map { BackupSavingMovement(movement: $0) },
            spendAccounts: spendAccounts.map { BackupSpendAccount(account: $0) },
            accountMovements: accountMovements.map { BackupAccountMovement(movement: $0) },
            auditLogEntries: auditLogEntries.map { BackupAuditLogEntry(entry: $0) },
            plannings: plannings.map { BackupPlanning(planning: $0) },
            planningItemTypes: planningItemTypes.map { BackupPlanningItemType(itemType: $0) },
            planningItems: planningItems.map { BackupPlanningItem(item: $0) },
            planningMovements: planningMovements.map { BackupPlanningMovement(movement: $0) }
        )
        return try encodedData(for: backup)
    }

    private func encodedData<T: Encodable>(for value: T) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(value)
    }

    private func decodedBackup(from data: Data) throws -> SpendWiseBackup {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let backup = try decoder.decode(SpendWiseBackup.self, from: data)
        guard backup.version == SpendWiseBackup.currentVersion,
              backup.structureIdentifier == SpendWiseBackup.currentStructureIdentifier else {
            throw BackupError.unsupportedVersion
        }
        try backup.validateIntegrity()
        return backup
    }

    private func backupErrorMessage(_ error: Error) -> String {
        switch error {
        case BackupError.emptyPassword:
            return "Introduza uma palavra-passe para proteger o backup."
        case BackupError.passwordMismatch:
            return "As palavras-passe não coincidem."
        case BackupError.invalidBackup:
            return AppStrings.text(.importBackupFailureMessage)
        case BackupError.unsupportedVersion:
            return "Este backup pertence a uma versão com uma estrutura de dados diferente e não pode ser restaurado nesta versão da app."
        case BackupError.invalidPassword:
            return "Não foi possível desencriptar o backup. Confirme a palavra-passe."
        default:
            return error.localizedDescription
        }
    }

    private func importPendingBackup() {
        guard let backup = pendingImportedBackup else { return }

        payments.forEach(modelContext.delete)
        paymentHistory.forEach(modelContext.delete)
        exclusions.forEach(modelContext.delete)
        transactions.forEach(modelContext.delete)
        creditMovements.forEach(modelContext.delete)
        creditAccounts.forEach(modelContext.delete)
        savingMovements.forEach(modelContext.delete)
        savingAccounts.forEach(modelContext.delete)
        accountMovements.forEach(modelContext.delete)
        spendAccounts.forEach(modelContext.delete)
        auditLogEntries.forEach(modelContext.delete)
        planningMovements.forEach(modelContext.delete)
        planningItems.forEach(modelContext.delete)
        planningItemTypes.forEach(modelContext.delete)
        plannings.forEach(modelContext.delete)

        let importedTransactions = backup.transactions.map(\.model)
        let importedPayments = backup.payments.map(\.model)
        let importedPaymentHistory = backup.paymentHistory.map(\.model)
        let importedExclusions = backup.exclusions.map(\.model)
        let importedSpendAccounts = backup.spendAccounts.map(\.model)
        let importedAccountMovements = backup.accountMovements.map(\.model)
        let importedAuditLogEntries = backup.auditLogEntries.map(\.model)

        importedTransactions.forEach(modelContext.insert)
        importedPayments.forEach(modelContext.insert)
        importedPaymentHistory.forEach(modelContext.insert)
        importedExclusions.forEach(modelContext.insert)
        backup.creditAccounts.map(\.model).forEach(modelContext.insert)
        backup.creditMovements.map(\.model).forEach(modelContext.insert)
        backup.savingAccounts.map(\.model).forEach(modelContext.insert)
        backup.savingMovements.map(\.model).forEach(modelContext.insert)
        importedSpendAccounts.forEach(modelContext.insert)
        importedAccountMovements.forEach(modelContext.insert)
        importedAuditLogEntries.forEach(modelContext.insert)
        backup.plannings.map(\.model).forEach(modelContext.insert)
        backup.planningItemTypes.map(\.model).forEach(modelContext.insert)
        backup.planningItems.map(\.model).forEach(modelContext.insert)
        backup.planningMovements.map(\.model).forEach(modelContext.insert)
        BackupAccountMigration.normalizeImportedAccounts(
            modelContext: modelContext,
            transactions: importedTransactions,
            payments: importedPayments,
            paymentHistory: importedPaymentHistory,
            exclusions: importedExclusions,
            spendAccounts: importedSpendAccounts,
            accountMovements: importedAccountMovements
        )

        pendingImportedBackup = nil

        do {
            try modelContext.save()
            backupNotice = BackupNotice(
                title: AppStrings.text(.importBackupSuccessTitle),
                message: AppStrings.text(.importBackupSuccessMessage)
            )
        } catch {
            modelContext.rollback()
            backupNotice = BackupNotice(
                title: AppStrings.text(.importBackupFailureTitle),
                message: error.localizedDescription
            )
        }
    }

    private func perform(_ action: SettingsListAction) {
        switch action.kind {
        case .edit:
            editorRequest = TransactionEditorRequest(transaction: action.transaction, month: action.editStartMonth ?? nextMonth, editScope: .futureMonths)
        case .delete:
            action.transaction.recurrenceEndMonthStart = nextMonth
            payments
                .filter { $0.transactionID == action.transaction.id && $0.monthStart >= nextMonth }
                .forEach(modelContext.delete)
        case .deactivate:
            action.transaction.recurrenceDisabledFromMonthStart = nextMonth
        case .activate:
            action.transaction.recurrenceDisabledFromMonthStart = nil
            paymentHistory
                .filter { $0.transactionID == action.transaction.id && $0.monthStart >= nextMonth }
                .forEach(modelContext.delete)
        }

        pendingAction = nil
    }

    private func deleteAllData() {
        payments.forEach(modelContext.delete)
        paymentHistory.forEach(modelContext.delete)
        exclusions.forEach(modelContext.delete)
        transactions.forEach(modelContext.delete)
        creditMovements.forEach(modelContext.delete)
        creditAccounts.forEach(modelContext.delete)
        savingMovements.forEach(modelContext.delete)
        savingAccounts.forEach(modelContext.delete)
        accountMovements.forEach(modelContext.delete)
        spendAccounts.forEach(modelContext.delete)
        auditLogEntries.forEach(modelContext.delete)
        hasCompletedInitialSetup = false
    }
}

private struct RecurringSaveProgressCurtain: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.32)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                ProgressView()
                    .controlSize(.large)
                    .tint(AppPalette.background)

                Text("A atualizar recorrentes…")
                    .font(.headline)
                    .foregroundStyle(AppPalette.background)

                Text("A aplicar a alteração aos planeamentos futuros.")
                    .font(.subheadline)
                    .foregroundStyle(AppPalette.mutedText)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 18))
            .shadow(color: .black.opacity(0.2), radius: 18, y: 8)
            .padding(.horizontal, 32)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isModal)
        .zIndex(4000)
    }
}

@MainActor
@Observable
private final class RecurringSavePresentation {
    var isProcessing = false
    var notice: SaveResultNotice?
    private var pendingNotice: SaveResultNotice?

    func begin(with notice: SaveResultNotice) {
        pendingNotice = notice
        isProcessing = true
    }

    func finish() {
        notice = pendingNotice
        pendingNotice = nil
        isProcessing = false

        guard let notice else { return }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(10))
            guard self.notice?.id == notice.id else { return }
            self.notice = nil
        }
    }

    func dismissNotice() {
        notice = nil
    }
}

private struct RecurringSavePresentationOverlay: View {
    let presentation: RecurringSavePresentation

    var body: some View {
        ZStack(alignment: .top) {
            if presentation.isProcessing {
                RecurringSaveProgressCurtain()
            } else if let notice = presentation.notice {
                SaveResultToast(notice: notice, onDismiss: presentation.dismissNotice)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

struct BudgetSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var transactions: [MoneyTransaction]
    @Query private var payments: [ExpensePayment]
    @Query private var paymentHistory: [PaymentHistoryEntry]
    @Query private var exclusions: [RecurrenceExclusion]
    @Query private var creditAccounts: [CreditAccount]
    @Query private var savingAccounts: [SavingAccount]
    @State private var editorRequest: TransactionEditorRequest?
    @State private var savePresentation = RecurringSavePresentation()
    @State private var selectedList = 0
    @State private var pendingAction: SettingsListAction?
    @State private var helpNotice: BackupNotice?
    @State private var showsRecurringActions = false
    @State private var isPreparingRecurringBudgetBreakdown = false
    @State private var pendingRecurringBudgetBreakdownRequest: RecurringBudgetBreakdownRequest?
    @State private var recurringBudgetBreakdownRequest: RecurringBudgetBreakdownRequest?
    private let showsListControls: Bool

    init(openingList: Int = 0, showsListControls: Bool = true) {
        _selectedList = State(initialValue: min(max(openingList, 0), 1))
        self.showsListControls = showsListControls
    }

    private var nextMonth: Date {
        Date().monthStart.nextMonthStart
    }

    private var recurringExpenses: [MoneyTransaction] {
        transactions
            .filter { $0.kind == TransactionKind.expense.rawValue && $0.isRecurring && $0.isVisibleInSettingsList }
            .sorted { first, second in
                if first.day != second.day { return first.day < second.day }
                return first.displayName.localizedCaseInsensitiveCompare(second.displayName) == .orderedAscending
            }
    }

    private var recurringIncome: [MoneyTransaction] {
        transactions
            .filter { $0.kind == TransactionKind.income.rawValue && $0.isRecurring && $0.isVisibleInSettingsList }
            .sorted { first, second in
                if first.day != second.day { return first.day < second.day }
                return first.title.localizedCaseInsensitiveCompare(second.title) == .orderedAscending
            }
    }

    private var selectedListTitle: String {
        selectedList == 0 ? AppStrings.text(.recurringExpenses) : AppStrings.text(.recurringIncome)
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 12) {
                        recurringHeroImage

                        recurringBudgetSummaryCard

                        if showsListControls {
                            settingsListHeader
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            selectedSettingsList
                                .id(selectedList)
                                .transition(.opacity.combined(with: .move(edge: selectedList == 0 ? .leading : .trailing)))
                                .animation(.snappy, value: selectedList)
                                .frame(maxWidth: .infinity, minHeight: 360)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity)
                        .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 28))
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 128)
                }
            }

            if showsListControls && showsRecurringActions {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .opacity(0.82)
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.snappy) {
                            showsRecurringActions = false
                        }
                    }
                    .transition(.opacity)
            }

            if showsListControls {
                VStack(alignment: .trailing, spacing: 10) {
                    if showsRecurringActions {
                        recurringActionsBar
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    recurringAddButton
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .animation(.snappy, value: showsRecurringActions)
            }
        }
        .foregroundStyle(AppPalette.background)
        .tint(AppPalette.background)
        .background(AppPalette.appBackground)
        .navigationTitle(AppStrings.text(.budgetSettings))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editorRequest) { request in
            TransactionEditor(request: request, onSaved: presentSaveNoticeAfterEditorCloses)
        }
        .overlay {
            RecurringSavePresentationOverlay(presentation: savePresentation)
        }
        .sheet(item: $recurringBudgetBreakdownRequest) { request in
            RecurringBudgetBreakdownView(months: request.months)
        }
        .fullScreenCover(isPresented: $isPreparingRecurringBudgetBreakdown, onDismiss: {
            recurringBudgetBreakdownRequest = pendingRecurringBudgetBreakdownRequest
            pendingRecurringBudgetBreakdownRequest = nil
        }) {
            ZStack {
                Color.black.opacity(0.24)
                    .ignoresSafeArea()

                HStack(spacing: 10) {
                    ProgressView()
                    Text(AppStrings.text(.updatingAnalysis))
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(AppPalette.background)
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .background(AppPalette.surface, in: Capsule())
                .shadow(color: .black.opacity(0.18), radius: 18, y: 8)
            }
            .presentationBackground(.clear)
            .interactiveDismissDisabled()
        }
        .alert(
            pendingAction?.title ?? "",
            isPresented: Binding(
                get: { pendingAction != nil },
                set: { if !$0 { pendingAction = nil } }
            ),
            presenting: pendingAction
        ) { action in
            Button(AppStrings.text(.cancel), role: .cancel) {}
            Button(action.confirmationButtonTitle, role: action.isDestructive ? .destructive : nil) {
                perform(action)
            }
        } message: { action in
            Text(action.message)
        }
        .alert(helpNotice?.title ?? "", isPresented: Binding(
            get: { helpNotice != nil },
            set: { if !$0 { helpNotice = nil } }
        )) {
            Button(AppStrings.text(.ok)) { helpNotice = nil }
        } message: {
            Text(helpNotice?.message ?? "")
        }
    }

    private func presentSaveNoticeAfterEditorCloses(_ notice: SaveResultNotice) {
        savePresentation.begin(with: notice)

        Task { @MainActor in
            // Keep the progress curtain mounted while SwiftData publishes the
            // recurring changes and the settings list rebuilds its projections.
            try? await Task.sleep(for: .milliseconds(80))
            editorRequest = nil
            try? await Task.sleep(for: .milliseconds(120))
            savePresentation.finish()
        }
    }

    private var recurringHeroName: String {
        let suffix = AppStrings.currentLanguage == .portuguese ? "" : "English"

        if showsListControls {
            return "RecurringCombinedHero\(suffix)"
        }

        return selectedList == 0 ? "RecurringExpensesHero\(suffix)" : "RecurringIncomeHero\(suffix)"
    }

    private var recurringHeroImage: some View {
        Image(recurringHeroName)
            .resizable()
            .scaledToFit()
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: AppPalette.background.opacity(0.10), radius: 14, y: 6)
    }

    private var recurringBudgetSummaryCard: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Total mensal de despesas recorrentes")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AppPalette.mutedText)

                    Text("Soma das despesas recorrentes mensais")
                        .font(.caption)
                        .foregroundStyle(AppPalette.secondaryText)
                }

                Button {
                    prepareRecurringBudgetBreakdown()
                } label: {
                    Image(systemName: "info.circle")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(AppPalette.background)
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Detalhe do orçamento por mês")

                Spacer(minLength: 6)

                Text(recurringBudgetedTotal.currencyText)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(AppPalette.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            recurringSummaryRow(
                title: "Rendimentos recorrentes mensais",
                value: recurringIncomeTotal.currencyText,
                color: AppPalette.income
            )

            recurringSummaryRow(
                title: "Margem mensal disponível",
                value: recurringRemainingAvailable.currencyText,
                color: recurringRemainingAvailable >= 0 ? AppPalette.background : AppPalette.primary
            )
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity)
        .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 18))
        .shadow(color: AppPalette.background.opacity(0.06), radius: 14, y: 6)
    }

    private func recurringSummaryRow(title: String, value: String, color: Color) -> some View {
        HStack {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(AppPalette.mutedText)
                .lineLimit(2)
                .minimumScaleFactor(0.82)

            Spacer(minLength: 10)

            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
    }

    private var recurringBudgetedTotal: Double {
        recurringExpenses.filter { $0.isRecurrenceEnabled && $0.recurrence == .monthly }.reduce(0) { total, transaction in
            total + transaction.scheduledAmount(in: Date().monthStart)
        }
    }

    private func prepareRecurringBudgetBreakdown() {
        guard !isPreparingRecurringBudgetBreakdown else { return }
        isPreparingRecurringBudgetBreakdown = true

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(250))
            pendingRecurringBudgetBreakdownRequest = RecurringBudgetBreakdownRequest(
                months: recurringBudgetBreakdownMonths
            )
            isPreparingRecurringBudgetBreakdown = false
        }
    }

    private var recurringIncomeTotal: Double {
        recurringIncome.filter { $0.isRecurrenceEnabled && $0.recurrence == .monthly }.reduce(0) { total, transaction in
            total + transaction.scheduledAmount(in: Date().monthStart)
        }
    }

    private var recurringRemainingAvailable: Double {
        recurringIncomeTotal - recurringBudgetedTotal
    }

    private var recurringBudgetBreakdownMonths: [RecurringBudgetMonthBreakdown] {
        let calculator = MoneyCalculationService(transactions: transactions, payments: payments, exclusions: exclusions)
        var month = Date().monthStart

        return (0..<12).map { _ in
            defer { month = month.nextMonthStart }
            let expenses = calculator.visibleTransactions(in: month)
                .filter { $0.kind == TransactionKind.expense.rawValue && $0.isRecurring }
            let income = calculator.incomeOccurrences(budgetedIn: month)
                .filter { $0.isRecurring }
                .reduce(0) { $0 + $1.scheduledAmount(in: month) }

            return RecurringBudgetMonthBreakdown(
                month: month,
                income: income,
                weeklyExpenses: recurringExpenseTotal(expenses, in: month, recurrence: .weekly),
                monthlyExpenses: recurringExpenseTotal(expenses, in: month, recurrence: .monthly),
                quarterlyExpenses: recurringExpenseTotal(expenses, in: month, recurrence: .quarterly),
                semiannualExpenses: recurringExpenseTotal(expenses, in: month, recurrence: .semiannual),
                annualExpenses: expenses
                    .filter { $0.recurrence == .annual || $0.recurrence == .yearlyMonth }
                    .reduce(0) { $0 + $1.scheduledAmount(in: month) }
            )
        }
    }

    private func recurringExpenseTotal(_ expenses: [MoneyTransaction], in month: Date, recurrence: RecurrenceType) -> Double {
        expenses
            .filter { $0.recurrence == recurrence }
            .reduce(0) { $0 + $1.scheduledAmount(in: month) }
    }

    @ViewBuilder
    private var selectedSettingsList: some View {
        if selectedList == 0 {
            RecurringList(
                emptyTitle: AppStrings.text(.recurringExpenses),
                transactions: recurringExpenses,
                payments: payments,
                onEdit: editRecurringTransaction,
                onSetEnabled: { pendingAction = SettingsListAction(kind: $1 ? .activate : .deactivate, transaction: $0) },
                onDelete: { pendingAction = SettingsListAction(kind: .delete, transaction: $0) }
            )
        } else {
            RecurringList(
                emptyTitle: AppStrings.text(.recurringIncome),
                transactions: recurringIncome,
                payments: payments,
                onEdit: editRecurringTransaction,
                onSetEnabled: { pendingAction = SettingsListAction(kind: $1 ? .activate : .deactivate, transaction: $0) },
                onDelete: { pendingAction = SettingsListAction(kind: .delete, transaction: $0) }
            )
        }
    }

    private var settingsListHeader: some View {
        HStack(spacing: 10) {
            recurringNavigatorButton(
                title: AppStrings.text(.recurringExpenses),
                systemImage: "arrow.triangle.2.circlepath",
                index: 0
            )

            recurringNavigatorButton(
                title: AppStrings.text(.recurringIncome),
                systemImage: "banknote",
                index: 1
            )
        }
    }

    private func selectSettingsList(_ index: Int) {
        guard index != selectedList else { return }
        withAnimation(.snappy) {
            selectedList = min(max(index, 0), 1)
        }
    }

    private func editRecurringTransaction(_ transaction: MoneyTransaction) {
        if let editStartMonth = confirmedEditStartMonth(for: transaction) {
            pendingAction = SettingsListAction(kind: .edit, transaction: transaction, editStartMonth: editStartMonth)
        } else {
            editorRequest = TransactionEditorRequest(transaction: transaction, month: nextMonth, editScope: .futureMonths)
        }
    }

    private func confirmedEditStartMonth(for transaction: MoneyTransaction) -> Date? {
        let currentMonth = Date().monthStart
        guard transaction.kind == TransactionKind.expense.rawValue,
              transaction.occurs(in: currentMonth, exclusions: exclusions) else {
            return nil
        }

        let payment = payments.first {
            $0.transactionID == transaction.id &&
            Calendar.current.isDate($0.monthStart, equalTo: currentMonth, toGranularity: .month)
        }
        let paidAmount = payment?.amountPaid ?? (payment == nil ? 0 : transaction.amount)
        if paidAmount <= 0 {
            return currentMonth
        }
        if paidAmount < transaction.amount {
            return nextMonth
        }
        return nil
    }

    private func recurringNavigatorButton(title: String, systemImage: String, index: Int) -> some View {
        Button {
            selectSettingsList(index)
        } label: {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(selectedList == index ? .white : AppPalette.bodyText)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .frame(maxWidth: .infinity, minHeight: 42)
        }
        .tint(selectedList == index ? AppPalette.background : AppPalette.bodyText)
        .liquidGlassButtonStyle(prominent: selectedList == index)
    }

    private var recurringAddButton: some View {
        Button {
            withAnimation(.snappy) {
                showsRecurringActions.toggle()
            }
        } label: {
            Image(systemName: showsRecurringActions ? "xmark" : "plus")
                .font(.title2)
                .frame(width: 52, height: 52)
                .foregroundStyle(AppPalette.background)
                .background(AppPalette.secondary, in: Circle())
                .shadow(color: AppPalette.background.opacity(0.16), radius: 14, y: 8)
        }
        .buttonStyle(.plain)
    }

    private var recurringActionsBar: some View {
        VStack(alignment: .trailing, spacing: 10) {
            recurringExpenseActionButton
            recurringIncomeActionButton
        }
    }

    private var hasActiveSavings: Bool {
        savingAccounts.contains { $0.savingStatus == .active }
    }

    private var hasActiveCredits: Bool {
        creditAccounts.contains { $0.creditStatus == .active }
    }

    private var hasQuickSavingsOrCredits: Bool {
        hasActiveSavings || hasActiveCredits
    }

    private var recurringSavingActionButton: some View {
        recurringActionButton(
            title: SavingsStrings.text(.saving),
            imageName: "QuickActionPoupanca"
        ) {
            openPresetRecurringExpense(title: AppStrings.text(.newRecurringSavingExpense), expenseName: recurringSavingExpenseName)
        }
    }

    private var recurringCreditPaymentActionButton: some View {
        recurringActionButton(
            title: CreditStrings.text(.credit),
            imageName: "QuickActionCredito"
        ) {
            openPresetRecurringExpense(title: AppStrings.text(.newRecurringCreditPaymentExpense), expenseName: recurringCreditPaymentExpenseName)
        }
    }

    private var recurringIncomeActionButton: some View {
        recurringActionButton(
            title: AppStrings.text(.recurringIncome),
            imageName: "QuickActionReceita"
        ) {
            selectSettingsList(1)
            editorRequest = TransactionEditorRequest(mode: .salary, month: Date().monthStart)
            showsRecurringActions = false
        }
    }

    private var recurringExpenseActionButton: some View {
        recurringActionButton(
            title: AppStrings.text(.recurringExpenses),
            imageName: "QuickActionDespesa"
        ) {
            selectSettingsList(0)
            editorRequest = TransactionEditorRequest(mode: .monthlyExpense, month: Date().monthStart)
            showsRecurringActions = false
        }
    }

    private func recurringActionButton(title: String, imageName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AppPalette.background)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .frame(width: 124, height: 34)
                    .background(AppPalette.surface.opacity(0.98), in: Capsule())
                    .shadow(color: AppPalette.background.opacity(0.12), radius: 8, y: 4)

                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 58, height: 58)
                    .shadow(color: AppPalette.background.opacity(0.18), radius: 12, y: 7)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }

    private var recurringSavingExpenseName: String {
        ExpenseCategory.savingsAndDebt.names.first { name in
            let normalizedName = normalizedExpenseName(name)
            return normalizedName.contains("poup") || normalizedName.contains("saving")
        } ?? ""
    }

    private var recurringCreditPaymentExpenseName: String {
        ExpenseCategory.savingsAndDebt.names.first { name in
            let normalizedName = normalizedExpenseName(name)
            return normalizedName.contains("amort") || normalizedName.contains("divida") || normalizedName.contains("debt")
        } ?? ""
    }

    private func openPresetRecurringExpense(title: String, expenseName: String) {
        selectSettingsList(0)
        editorRequest = TransactionEditorRequest(
            mode: .monthlyExpense,
            month: Date().monthStart,
            titleOverride: title,
            initialExpenseCategory: .savingsAndDebt,
            initialExpenseName: expenseName
        )
        showsRecurringActions = false
    }

    private func normalizedExpenseName(_ value: String) -> String {
        value.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current).lowercased()
    }

    private func perform(_ action: SettingsListAction) {
        switch action.kind {
        case .edit:
            editorRequest = TransactionEditorRequest(transaction: action.transaction, month: action.editStartMonth ?? nextMonth, editScope: .futureMonths)
        case .delete:
            action.transaction.recurrenceEndMonthStart = nextMonth
            payments
                .filter { $0.transactionID == action.transaction.id && $0.monthStart >= nextMonth }
                .forEach(modelContext.delete)
        case .deactivate:
            action.transaction.recurrenceDisabledFromMonthStart = nextMonth
        case .activate:
            action.transaction.recurrenceDisabledFromMonthStart = nil
            paymentHistory
                .filter { $0.transactionID == action.transaction.id && $0.monthStart >= nextMonth }
                .forEach(modelContext.delete)
        }

        pendingAction = nil
    }
}

private struct RecurringBudgetMonthBreakdown: Identifiable {
    let month: Date
    let income: Double
    let weeklyExpenses: Double
    let monthlyExpenses: Double
    let quarterlyExpenses: Double
    let semiannualExpenses: Double
    let annualExpenses: Double

    var id: Date { month }

    var totalExpenses: Double {
        weeklyExpenses + monthlyExpenses + quarterlyExpenses + semiannualExpenses + annualExpenses
    }

    var balance: Double {
        income - totalExpenses
    }
}

private struct RecurringBudgetBreakdownRequest: Identifiable {
    let id = UUID()
    let months: [RecurringBudgetMonthBreakdown]
}

private struct RecurringBudgetBreakdownView: View {
    @Environment(\.dismiss) private var dismiss
    let months: [RecurringBudgetMonthBreakdown]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    budgetBreakdownIntroCard

                    ForEach(months) { month in
                        monthCard(month)
                    }
                }
                .padding()
            }
            .background(AppPalette.appBackground)
            .navigationTitle("Orçamento por mês")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(AppStrings.text(.ok)) { dismiss() }
                        .liquidGlassButtonStyle()
                }
            }
        }
        .foregroundStyle(AppPalette.background)
        .tint(AppPalette.background)
    }

    private var budgetBreakdownIntroCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Valores calculados com base nos recorrentes registados.")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppPalette.background)

            Text("A lista abaixo mostra a previsão por mês considerando apenas despesas e rendimentos recorrentes configurados na Gestão. Movimentos adicionados diretamente na Conta Corrente não estão refletidos nestes valores.")
                .font(.footnote)
                .foregroundStyle(AppPalette.mutedText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 18))
        .shadow(color: AppPalette.background.opacity(0.06), radius: 12, y: 6)
    }

    private func monthCard(_ month: RecurringBudgetMonthBreakdown) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(month.month.monthTitle)
                    .font(.headline.bold())
                    .foregroundStyle(AppPalette.background)

                Spacer()

                Text(month.totalExpenses.currencyText)
                    .font(.headline.bold())
                    .foregroundStyle(AppPalette.primary)
            }

            Divider()

            recurringBudgetRow("Rendimentos", value: month.income, color: AppPalette.income)
            recurringBudgetRow("Despesas semanais", value: month.weeklyExpenses, color: AppPalette.primary)
            recurringBudgetRow("Despesas mensais", value: month.monthlyExpenses, color: AppPalette.primary)
            recurringBudgetRow("Despesas trimestrais", value: month.quarterlyExpenses, color: AppPalette.primary)
            recurringBudgetRow("Despesas semestrais", value: month.semiannualExpenses, color: AppPalette.primary)
            recurringBudgetRow("Despesas anuais", value: month.annualExpenses, color: AppPalette.primary)

            Divider()

            recurringBudgetRow(
                "Disponível",
                value: month.balance,
                color: month.balance >= 0 ? AppPalette.background : AppPalette.primary,
                isStrong: true
            )
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 18))
        .shadow(color: AppPalette.background.opacity(0.06), radius: 12, y: 6)
    }

    private func recurringBudgetRow(_ title: String, value: Double, color: Color, isStrong: Bool = false) -> some View {
        HStack(spacing: 10) {
            Text(title)
                .font(isStrong ? .subheadline.bold() : .subheadline)
                .foregroundStyle(isStrong ? AppPalette.background : AppPalette.mutedText)

            Spacer()

            Text(value.currencyText)
                .font(isStrong ? .subheadline.bold() : .subheadline.weight(.semibold))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }
}

enum SettingsTab {
    case app
    case budget
    case credits
    case savings
}

private struct SettingsListAction: Identifiable {
    enum Kind {
        case edit
        case delete
        case deactivate
        case activate
    }

    let id = UUID()
    let kind: Kind
    let transaction: MoneyTransaction
    var editStartMonth: Date? = nil

    private var editsCurrentMonth: Bool {
        guard let editStartMonth else { return false }
        return Calendar.current.isDate(editStartMonth, equalTo: Date().monthStart, toGranularity: .month)
    }

    var title: String {
        switch kind {
        case .edit:
            editsCurrentMonth ? AppStrings.text(.currentAndFutureEditTitle) : AppStrings.text(.futureEditTitle)
        case .delete:
            AppStrings.text(.futureDeleteTitle)
        case .deactivate:
            AppStrings.currentLanguage == .portuguese ? "Desativar recorrente?" : "Deactivate recurring item?"
        case .activate:
            AppStrings.currentLanguage == .portuguese ? "Ativar recorrente?" : "Activate recurring item?"
        }
    }

    var message: String {
        switch kind {
        case .edit:
            editsCurrentMonth ? AppStrings.text(.currentAndFutureEditMessage) : AppStrings.text(.futureEditMessage)
        case .delete:
            AppStrings.text(.futureDeleteMessage)
        case .deactivate:
            AppStrings.currentLanguage == .portuguese
                ? "Os planeamentos a partir do próximo mês deixarão de aparecer. O mês atual, o histórico e a configuração serão mantidos, para que possa voltar a ativar este recorrente mais tarde."
                : "Plans from next month onward will no longer appear. The current month, history, and configuration will be kept so you can activate this recurring item again later."
        case .activate:
            AppStrings.currentLanguage == .portuguese
                ? "Os planeamentos futuros voltarão a ser criados com base nesta configuração e na data de fim definida, caso exista."
                : "Future plans will be created again from this configuration and its end date, if one is set."
        }
    }

    var confirmationButtonTitle: String {
        switch kind {
        case .activate, .deactivate:
            return AppStrings.text(.ok)
        case .edit, .delete:
            return AppStrings.text(.continueAction)
        }
    }

    var isDestructive: Bool {
        kind == .delete || kind == .deactivate
    }
}

private struct BackupActionRow: View {
    let title: String
    let systemImage: String
    let helpMessage: String
    var isDestructive = false
    let onHelp: (String) -> Void
    let action: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: action) {
                Label(title, systemImage: systemImage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(isDestructive ? AppPalette.surface : AppPalette.background)
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            }
            .tint(isDestructive ? AppPalette.primary : AppPalette.secondary)
            .liquidGlassButtonStyle(prominent: isDestructive)

            Button {
                onHelp(helpMessage)
            } label: {
                Image(systemName: "info.circle")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(AppPalette.background)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(AppStrings.text(.backupInfoTitle))
        }
    }
}

private struct BudgetAddActionRow: View {
    let title: String
    let systemImage: String
    let helpMessage: String
    let action: () -> Void
    let onHelp: (String) -> Void

    @State private var showsHelp = false

    var body: some View {
        HStack(spacing: 10) {
            Button(action: action) {
                Label(title, systemImage: systemImage)
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 40, alignment: .leading)
            }
            .liquidGlassButtonStyle()

            Button {
                showsHelp = true
            } label: {
                Image(systemName: "info.circle")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(AppPalette.background)
                    .frame(width: 34, height: 34)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(title)
            .popover(isPresented: $showsHelp, attachmentAnchor: .point(.center), arrowEdge: .trailing) {
                InformationBubble(title: title, message: helpMessage)
            }
        }
    }
}

struct BackupNotice: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

enum BackupError: Error {
    case unsupportedVersion
    case invalidBackup
    case emptyPassword
    case passwordMismatch
    case invalidPassword
}

enum BackupAccountMigration {
    static func normalizeImportedAccounts(
        modelContext: ModelContext,
        transactions: [MoneyTransaction],
        payments: [ExpensePayment],
        paymentHistory: [PaymentHistoryEntry],
        exclusions: [RecurrenceExclusion],
        spendAccounts: [SpendAccount],
        accountMovements: [AccountMovement]
    ) {
        if spendAccounts.isEmpty {
            let accountSummary = MoneyCalculationService(
                transactions: transactions,
                payments: payments,
                exclusions: exclusions
            ).accountSummary(until: Date())
            let primaryAccount = SpendAccount(
                name: AppStrings.text(.currentAccount),
                iconName: "wallet.pass.fill",
                colorName: SpendAccountColor.blue.rawValue,
                initialBalance: accountSummary.availableBalance,
                isPrimary: true
            )
            modelContext.insert(primaryAccount)
            transactions.forEach { $0.accountID = primaryAccount.id }
            paymentHistory.forEach { $0.accountID = primaryAccount.id }
            return
        }

        let primaryAccount = normalizedPrimaryAccount(in: spendAccounts)
        let validAccountIDs = Set(spendAccounts.map(\.id))

        transactions
            .filter { $0.accountID.map { !validAccountIDs.contains($0) } ?? true }
            .forEach { $0.accountID = primaryAccount.id }

        paymentHistory
            .filter { $0.accountID.map { !validAccountIDs.contains($0) } ?? true }
            .forEach { $0.accountID = primaryAccount.id }

        accountMovements
            .filter { !validAccountIDs.contains($0.accountID) }
            .forEach(modelContext.delete)
    }

    private static func normalizedPrimaryAccount(in accounts: [SpendAccount]) -> SpendAccount {
        let primaryAccounts = accounts.filter(\.isPrimary)
        let selectedPrimary = primaryAccounts.first ?? accounts[0]

        accounts.forEach { account in
            account.isPrimary = account.id == selectedPrimary.id
        }

        return selectedPrimary
    }
}

private struct SpendWiseBackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    var data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.data = data
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

struct EncryptedSpendWiseBackup: Codable, Sendable {
    static let currentVersion = 2
    private static let envelopeFormat = "spendwise.encrypted-backup"
    private static let keyInfo = Data("SpendWiseBackupEncryptionV1".utf8)
    private static let passwordIterations = 100_000

    let format: String
    let version: Int
    let algorithm: String
    let iterations: Int?
    let salt: String
    let sealedData: String

    init(backupData: Data, password: String) throws {
        let saltData = Self.randomData(byteCount: 32)
        let key = Self.passwordDerivedKey(
            password: password,
            salt: saltData,
            iterations: Self.passwordIterations
        )
        let sealedBox = try AES.GCM.seal(backupData, using: key)

        guard let combinedData = sealedBox.combined else {
            throw BackupError.invalidBackup
        }

        format = Self.envelopeFormat
        version = Self.currentVersion
        algorithm = "AES.GCM.PBKDF2.HMAC.SHA256"
        iterations = Self.passwordIterations
        salt = saltData.base64EncodedString()
        sealedData = combinedData.base64EncodedString()
    }

    func decrypt(password: String) throws -> Data {
        guard format == Self.envelopeFormat, [1, Self.currentVersion].contains(version),
              let saltData = Data(base64Encoded: salt),
              let combinedData = Data(base64Encoded: sealedData) else {
            throw BackupError.invalidBackup
        }

        do {
            let key: SymmetricKey
            switch version {
            case 1 where algorithm == "AES.GCM.HKDF.SHA256":
                key = Self.legacyEncryptionKey(password: password, salt: saltData)
            case Self.currentVersion where algorithm == "AES.GCM.PBKDF2.HMAC.SHA256":
                guard let iterations,
                      iterations >= Self.passwordIterations,
                      iterations <= 1_000_000 else {
                    throw BackupError.invalidBackup
                }
                key = Self.passwordDerivedKey(password: password, salt: saltData, iterations: iterations)
            default:
                throw BackupError.invalidBackup
            }
            let sealedBox = try AES.GCM.SealedBox(combined: combinedData)
            return try AES.GCM.open(sealedBox, using: key)
        } catch {
            throw BackupError.invalidPassword
        }
    }

    private static func legacyEncryptionKey(password: String, salt: Data) -> SymmetricKey {
        let passwordKey = SymmetricKey(data: Data(password.utf8))
        return HKDF<SHA256>.deriveKey(
            inputKeyMaterial: passwordKey,
            salt: salt,
            info: keyInfo,
            outputByteCount: 32
        )
    }

    private static func passwordDerivedKey(password: String, salt: Data, iterations: Int) -> SymmetricKey {
        let passwordKey = SymmetricKey(data: Data(password.utf8))
        var blockIndex = UInt32(1).bigEndian
        var initialInput = salt
        withUnsafeBytes(of: &blockIndex) { initialInput.append(contentsOf: $0) }

        var previous = Array(HMAC<SHA256>.authenticationCode(for: initialInput, using: passwordKey))
        var derived = previous

        if iterations > 1 {
            for _ in 1..<iterations {
                previous = Array(HMAC<SHA256>.authenticationCode(for: Data(previous), using: passwordKey))
                for index in derived.indices {
                    derived[index] ^= previous[index]
                }
            }
        }

        return SymmetricKey(data: Data(derived))
    }

    private static func randomData(byteCount: Int) -> Data {
        var generator = SystemRandomNumberGenerator()
        return Data((0..<byteCount).map { _ in UInt8.random(in: .min ... .max, using: &generator) })
    }
}

struct SpendWiseBackup: Codable, Sendable {
    static let currentVersion = 4
    static let currentStructureIdentifier = "spendwise-custom-transaction-icons-v4"
    static let empty = SpendWiseBackup(
        transactions: [],
        payments: [],
        paymentHistory: [],
        exclusions: [],
        creditAccounts: [],
        creditMovements: [],
        savingAccounts: [],
        savingMovements: [],
        spendAccounts: [],
        accountMovements: [],
        auditLogEntries: [],
        plannings: [],
        planningItemTypes: [],
        planningItems: [],
        planningMovements: []
    )

    let version: Int
    let structureIdentifier: String
    let createdAt: Date
    let transactions: [BackupTransaction]
    let payments: [BackupPayment]
    let paymentHistory: [BackupPaymentHistoryEntry]
    let exclusions: [BackupExclusion]
    let creditAccounts: [BackupCreditAccount]
    let creditMovements: [BackupCreditMovement]
    let savingAccounts: [BackupSavingAccount]
    let savingMovements: [BackupSavingMovement]
    let spendAccounts: [BackupSpendAccount]
    let accountMovements: [BackupAccountMovement]
    let auditLogEntries: [BackupAuditLogEntry]
    let plannings: [BackupPlanning]
    let planningItemTypes: [BackupPlanningItemType]
    let planningItems: [BackupPlanningItem]
    let planningMovements: [BackupPlanningMovement]

    private enum CodingKeys: String, CodingKey {
        case version
        case structureIdentifier
        case createdAt
        case transactions
        case payments
        case paymentHistory
        case exclusions
        case creditAccounts
        case creditMovements
        case savingAccounts
        case savingMovements
        case spendAccounts
        case accountMovements
        case auditLogEntries
        case plannings
        case planningItemTypes
        case planningItems
        case planningMovements
    }

    init(
        transactions: [BackupTransaction],
        payments: [BackupPayment],
        paymentHistory: [BackupPaymentHistoryEntry] = [],
        exclusions: [BackupExclusion],
        creditAccounts: [BackupCreditAccount] = [],
        creditMovements: [BackupCreditMovement] = [],
        savingAccounts: [BackupSavingAccount] = [],
        savingMovements: [BackupSavingMovement] = [],
        spendAccounts: [BackupSpendAccount] = [],
        accountMovements: [BackupAccountMovement] = [],
        auditLogEntries: [BackupAuditLogEntry] = [],
        plannings: [BackupPlanning] = [],
        planningItemTypes: [BackupPlanningItemType] = [],
        planningItems: [BackupPlanningItem] = [],
        planningMovements: [BackupPlanningMovement] = []
    ) {
        version = Self.currentVersion
        structureIdentifier = Self.currentStructureIdentifier
        createdAt = Date()
        self.transactions = transactions
        self.payments = payments
        self.paymentHistory = paymentHistory
        self.exclusions = exclusions
        self.creditAccounts = creditAccounts
        self.creditMovements = creditMovements
        self.savingAccounts = savingAccounts
        self.savingMovements = savingMovements
        self.spendAccounts = spendAccounts
        self.accountMovements = accountMovements
        self.auditLogEntries = auditLogEntries
        self.plannings = plannings
        self.planningItemTypes = planningItemTypes
        self.planningItems = planningItems
        self.planningMovements = planningMovements
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        version = try container.decode(Int.self, forKey: .version)
        structureIdentifier = try container.decodeIfPresent(String.self, forKey: .structureIdentifier) ?? ""
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        transactions = try container.decode([BackupTransaction].self, forKey: .transactions)
        payments = try container.decode([BackupPayment].self, forKey: .payments)
        paymentHistory = try container.decodeIfPresent([BackupPaymentHistoryEntry].self, forKey: .paymentHistory) ?? []
        exclusions = try container.decode([BackupExclusion].self, forKey: .exclusions)
        creditAccounts = try container.decodeIfPresent([BackupCreditAccount].self, forKey: .creditAccounts) ?? []
        creditMovements = try container.decodeIfPresent([BackupCreditMovement].self, forKey: .creditMovements) ?? []
        savingAccounts = try container.decodeIfPresent([BackupSavingAccount].self, forKey: .savingAccounts) ?? []
        savingMovements = try container.decodeIfPresent([BackupSavingMovement].self, forKey: .savingMovements) ?? []
        spendAccounts = try container.decodeIfPresent([BackupSpendAccount].self, forKey: .spendAccounts) ?? []
        accountMovements = try container.decodeIfPresent([BackupAccountMovement].self, forKey: .accountMovements) ?? []
        auditLogEntries = try container.decodeIfPresent([BackupAuditLogEntry].self, forKey: .auditLogEntries) ?? []
        if structureIdentifier == Self.currentStructureIdentifier {
            plannings = try container.decode([BackupPlanning].self, forKey: .plannings)
            planningItemTypes = try container.decode([BackupPlanningItemType].self, forKey: .planningItemTypes)
            planningItems = try container.decode([BackupPlanningItem].self, forKey: .planningItems)
            planningMovements = try container.decode([BackupPlanningMovement].self, forKey: .planningMovements)
        } else {
            plannings = []
            planningItemTypes = []
            planningItems = []
            planningMovements = []
        }
    }

    func validateIntegrity() throws {
        func hasUniqueIDs<T>(_ values: [T], id: (T) -> UUID) -> Bool {
            Set(values.map(id)).count == values.count
        }

        guard hasUniqueIDs(transactions, id: \.id),
              hasUniqueIDs(paymentHistory, id: \.id),
              hasUniqueIDs(creditAccounts, id: \.id),
              hasUniqueIDs(creditMovements, id: \.id),
              hasUniqueIDs(savingAccounts, id: \.id),
              hasUniqueIDs(savingMovements, id: \.id),
              hasUniqueIDs(spendAccounts, id: \.id),
              hasUniqueIDs(accountMovements, id: \.id),
              hasUniqueIDs(auditLogEntries, id: \.id),
              hasUniqueIDs(plannings, id: \.id),
              hasUniqueIDs(planningItemTypes, id: \.id),
              hasUniqueIDs(planningItems, id: \.id),
              hasUniqueIDs(planningMovements, id: \.id) else {
            throw BackupError.invalidBackup
        }

        let transactionIDs = Set(transactions.map(\.id))
        let creditIDs = Set(creditAccounts.map(\.id))
        let savingIDs = Set(savingAccounts.map(\.id))
        let accountIDs = Set(spendAccounts.map(\.id))
        let planningIDs = Set(plannings.map(\.id))
        let planningItemTypeIDs = Set(planningItemTypes.map(\.id))
        let planningItemIDs = Set(planningItems.map(\.id))

        guard !spendAccounts.isEmpty,
              spendAccounts.filter(\.isPrimary).count == 1,
              payments.allSatisfy({ transactionIDs.contains($0.transactionID) }),
              paymentHistory.allSatisfy({
                  transactionIDs.contains($0.transactionID)
                      && $0.accountID.map(accountIDs.contains) ?? true
              }),
              exclusions.allSatisfy({ transactionIDs.contains($0.transactionID) }),
              creditMovements.allSatisfy({ creditIDs.contains($0.creditID) }),
              savingMovements.allSatisfy({ savingIDs.contains($0.savingID) }),
              accountMovements.allSatisfy({ accountIDs.contains($0.accountID) }),
              transactions.allSatisfy({ $0.accountID.map(accountIDs.contains) ?? true }),
              planningItemTypes.allSatisfy({ planningIDs.contains($0.planningId) }),
              planningItems.allSatisfy({
                  planningIDs.contains($0.planningId)
                      && $0.itemTypeId.map(planningItemTypeIDs.contains) ?? true
              }),
              planningMovements.allSatisfy({
                  planningIDs.contains($0.planningId)
                      && planningItemIDs.contains($0.itemId)
              }) else {
            throw BackupError.invalidBackup
        }
    }
}

struct BackupTransaction: Codable, Sendable {
    let id: UUID
    let title: String
    let day: Int
    let monthStart: Date
    let amount: Double
    let kind: String
    let repeatsEveryMonth: Bool
    let isPaid: Bool
    let expenseCategory: String?
    let expenseName: String?
    let incomeDescription: String?
    let recurrenceType: String?
    let recurrenceMonth: Int
    let recurrenceEndMonthStart: Date?
    let recurrenceDisabledFromMonthStart: Date?
    let budgetAllocationType: String?
    let budgetMonthStart: Date?
    let linkedCreditID: UUID?
    let linkedCreditMovementID: UUID?
    let linkedSavingID: UUID?
    let linkedSavingMovementID: UUID?
    let autoMarkPaidOnDay: Bool?
    let accountID: UUID?
    let customIconBrandName: String?
    let customIconBrandDomain: String?
    let customIconURL: String?

    init(transaction: MoneyTransaction) {
        id = transaction.id
        title = transaction.title
        day = transaction.day
        monthStart = transaction.monthStart
        amount = transaction.amount
        kind = transaction.kind
        repeatsEveryMonth = transaction.repeatsEveryMonth
        isPaid = transaction.isPaid
        expenseCategory = transaction.expenseCategory
        expenseName = transaction.expenseName
        incomeDescription = transaction.incomeDescription
        recurrenceType = transaction.recurrenceType
        recurrenceMonth = transaction.recurrenceMonth
        recurrenceEndMonthStart = transaction.recurrenceEndMonthStart
        recurrenceDisabledFromMonthStart = transaction.recurrenceDisabledFromMonthStart
        budgetAllocationType = transaction.budgetAllocationType
        budgetMonthStart = transaction.budgetMonthStart
        linkedCreditID = transaction.linkedCreditID
        linkedCreditMovementID = transaction.linkedCreditMovementID
        linkedSavingID = transaction.linkedSavingID
        linkedSavingMovementID = transaction.linkedSavingMovementID
        autoMarkPaidOnDay = transaction.autoMarkPaidOnDay
        accountID = transaction.accountID
        customIconBrandName = transaction.customIconBrandName
        customIconBrandDomain = transaction.customIconBrandDomain
        customIconURL = transaction.customIconURL
    }

    var model: MoneyTransaction {
        let transaction = MoneyTransaction(
            title: title,
            day: day,
            monthStart: monthStart,
            amount: amount,
            kind: kind,
            repeatsEveryMonth: repeatsEveryMonth,
            isPaid: isPaid,
            expenseCategory: expenseCategory,
            expenseName: expenseName,
            incomeDescription: incomeDescription,
            recurrenceType: recurrenceType,
            recurrenceMonth: recurrenceMonth,
            recurrenceEndMonthStart: recurrenceEndMonthStart,
            recurrenceDisabledFromMonthStart: recurrenceDisabledFromMonthStart,
            budgetAllocationType: budgetAllocationType,
            budgetMonthStart: budgetMonthStart,
            linkedCreditID: linkedCreditID,
            linkedCreditMovementID: linkedCreditMovementID,
            linkedSavingID: linkedSavingID,
            linkedSavingMovementID: linkedSavingMovementID,
            autoMarkPaidOnDay: autoMarkPaidOnDay ?? false,
            accountID: accountID,
            customIconBrandName: customIconBrandName,
            customIconBrandDomain: customIconBrandDomain,
            customIconURL: customIconURL
        )
        transaction.id = id
        return transaction
    }
}

struct BackupPayment: Codable, Sendable {
    let transactionID: UUID
    let monthStart: Date
    let amountPaid: Double?
    let occurrenceDay: Int?

    init(payment: ExpensePayment) {
        transactionID = payment.transactionID
        monthStart = payment.monthStart
        amountPaid = payment.amountPaid
        occurrenceDay = payment.occurrenceDay
    }

    var model: ExpensePayment {
        ExpensePayment(transactionID: transactionID, monthStart: monthStart, amountPaid: amountPaid, occurrenceDay: occurrenceDay)
    }
}

struct BackupPaymentHistoryEntry: Codable, Sendable {
    let id: UUID
    let transactionID: UUID
    let monthStart: Date
    let occurrenceDay: Int?
    let amount: Double
    let paidAt: Date
    let note: String?
    let accountID: UUID?

    init(entry: PaymentHistoryEntry) {
        id = entry.id
        transactionID = entry.transactionID
        monthStart = entry.monthStart
        occurrenceDay = entry.occurrenceDay
        amount = entry.amount
        paidAt = entry.paidAt
        note = entry.note
        accountID = entry.accountID
    }

    var model: PaymentHistoryEntry {
        let entry = PaymentHistoryEntry(
            transactionID: transactionID,
            monthStart: monthStart,
            occurrenceDay: occurrenceDay,
            amount: amount,
            paidAt: paidAt,
            note: note,
            accountID: accountID
        )
        entry.id = id
        return entry
    }
}

struct BackupExclusion: Codable, Sendable {
    let transactionID: UUID
    let monthStart: Date
    let occurrenceDay: Int?

    init(exclusion: RecurrenceExclusion) {
        transactionID = exclusion.transactionID
        monthStart = exclusion.monthStart
        occurrenceDay = exclusion.occurrenceDay
    }

    var model: RecurrenceExclusion {
        RecurrenceExclusion(transactionID: transactionID, monthStart: monthStart, occurrenceDay: occurrenceDay)
    }
}

struct BackupCreditAccount: Codable, Sendable {
    let id: UUID
    let name: String
    let details: String?
    let type: String
    let initialDebt: Double
    let creditLimit: Double?
    let createdAt: Date
    let status: String

    init(credit: CreditAccount) {
        id = credit.id
        name = credit.name
        details = credit.details
        type = credit.type
        initialDebt = credit.initialDebt
        creditLimit = credit.creditLimit
        createdAt = credit.createdAt
        status = credit.status
    }

    var model: CreditAccount {
        let credit = CreditAccount(
            name: name,
            details: details ?? "",
            type: type,
            initialDebt: initialDebt,
            creditLimit: creditLimit,
            createdAt: createdAt,
            status: status
        )
        credit.id = id
        return credit
    }
}

struct BackupCreditMovement: Codable, Sendable {
    let id: UUID
    let creditID: UUID
    let date: Date
    let type: String
    let amount: Double
    let note: String
    let expenseCategory: String?
    let expenseName: String?
    let linkedTransactionID: UUID?
    let linkedTransactionMonthStart: Date?
    let linkedTransactionOccurrenceDay: Int?

    init(movement: CreditMovement) {
        id = movement.id
        creditID = movement.creditID
        date = movement.date
        type = movement.type
        amount = movement.amount
        note = movement.note
        expenseCategory = movement.expenseCategory
        expenseName = movement.expenseName
        linkedTransactionID = movement.linkedTransactionID
        linkedTransactionMonthStart = movement.linkedTransactionMonthStart
        linkedTransactionOccurrenceDay = movement.linkedTransactionOccurrenceDay
    }

    var model: CreditMovement {
        let movement = CreditMovement(
            creditID: creditID,
            date: date,
            type: type,
            amount: amount,
            note: note,
            expenseCategory: expenseCategory,
            expenseName: expenseName,
            linkedTransactionID: linkedTransactionID,
            linkedTransactionMonthStart: linkedTransactionMonthStart,
            linkedTransactionOccurrenceDay: linkedTransactionOccurrenceDay
        )
        movement.id = id
        return movement
    }
}

struct BackupSavingAccount: Codable, Sendable {
    let id: UUID
    let name: String
    let details: String?
    let initialAmount: Double
    let targetAmount: Double?
    let createdAt: Date
    let status: String

    init(saving: SavingAccount) {
        id = saving.id
        name = saving.name
        details = saving.details
        initialAmount = saving.initialAmount
        targetAmount = saving.targetAmount
        createdAt = saving.createdAt
        status = saving.status
    }

    var model: SavingAccount {
        let saving = SavingAccount(
            name: name,
            details: details ?? "",
            initialAmount: initialAmount,
            targetAmount: targetAmount,
            createdAt: createdAt,
            status: status
        )
        saving.id = id
        return saving
    }
}

struct BackupSavingMovement: Codable, Sendable {
    let id: UUID
    let savingID: UUID
    let date: Date
    let type: String
    let amount: Double
    let note: String
    let linkedIncomeTransactionID: UUID?
    let linkedTransactionID: UUID?
    let linkedTransactionMonthStart: Date?
    let linkedTransactionOccurrenceDay: Int?

    init(movement: SavingMovement) {
        id = movement.id
        savingID = movement.savingID
        date = movement.date
        type = movement.type
        amount = movement.amount
        note = movement.note
        linkedIncomeTransactionID = movement.linkedIncomeTransactionID
        linkedTransactionID = movement.linkedTransactionID
        linkedTransactionMonthStart = movement.linkedTransactionMonthStart
        linkedTransactionOccurrenceDay = movement.linkedTransactionOccurrenceDay
    }

    var model: SavingMovement {
        let movement = SavingMovement(
            savingID: savingID,
            date: date,
            type: type,
            amount: amount,
            note: note,
            linkedIncomeTransactionID: linkedIncomeTransactionID,
            linkedTransactionID: linkedTransactionID,
            linkedTransactionMonthStart: linkedTransactionMonthStart,
            linkedTransactionOccurrenceDay: linkedTransactionOccurrenceDay
        )
        movement.id = id
        return movement
    }
}

struct BackupSpendAccount: Codable, Sendable {
    let id: UUID
    let name: String
    let iconName: String
    let colorName: String
    let initialBalance: Double
    let isPrimary: Bool
    let createdAt: Date

    init(account: SpendAccount) {
        id = account.id
        name = account.name
        iconName = account.iconName
        colorName = account.colorName
        initialBalance = account.initialBalance
        isPrimary = account.isPrimary
        createdAt = account.createdAt
    }

    var model: SpendAccount {
        let account = SpendAccount(
            name: name,
            iconName: iconName,
            colorName: colorName,
            initialBalance: initialBalance,
            isPrimary: isPrimary,
            createdAt: createdAt
        )
        account.id = id
        return account
    }
}

struct BackupAccountMovement: Codable, Sendable {
    let id: UUID
    let accountID: UUID
    let relatedAccountID: UUID?
    let transactionID: UUID?
    let paymentHistoryID: UUID?
    let date: Date
    let type: String
    let amount: Double
    let note: String

    init(movement: AccountMovement) {
        id = movement.id
        accountID = movement.accountID
        relatedAccountID = movement.relatedAccountID
        transactionID = movement.transactionID
        paymentHistoryID = movement.paymentHistoryID
        date = movement.date
        type = movement.type
        amount = movement.amount
        note = movement.note
    }

    var model: AccountMovement {
        let movement = AccountMovement(
            accountID: accountID,
            relatedAccountID: relatedAccountID,
            transactionID: transactionID,
            paymentHistoryID: paymentHistoryID,
            date: date,
            type: type,
            amount: amount,
            note: note
        )
        movement.id = id
        return movement
    }
}

struct BackupAuditLogEntry: Codable, Sendable {
    let id: UUID
    let date: Date
    let action: String
    let title: String
    let details: String
    let note: String
    let amount: Double
    let balanceAfter: Double
    let accountID: UUID?
    let relatedAccountID: UUID?
    let transactionID: UUID?
    let paymentHistoryID: UUID?
    let creditID: UUID?
    let savingID: UUID?

    init(entry: AuditLogEntry) {
        id = entry.id
        date = entry.date
        action = entry.action
        title = entry.title
        details = entry.details
        note = entry.note
        amount = entry.amount
        balanceAfter = entry.balanceAfter
        accountID = entry.accountID
        relatedAccountID = entry.relatedAccountID
        transactionID = entry.transactionID
        paymentHistoryID = entry.paymentHistoryID
        creditID = entry.creditID
        savingID = entry.savingID
    }

    var model: AuditLogEntry {
        let entry = AuditLogEntry(
            date: date,
            action: action,
            title: title,
            details: details,
            note: note,
            amount: amount,
            balanceAfter: balanceAfter,
            accountID: accountID,
            relatedAccountID: relatedAccountID,
            transactionID: transactionID,
            paymentHistoryID: paymentHistoryID,
            creditID: creditID,
            savingID: savingID
        )
        entry.id = id
        return entry
    }
}

struct BackupPlanning: Codable, Sendable {
    let id: UUID
    let name: String
    let type: String
    let totalBudget: Double
    let startDate: Date?
    let endDate: Date?
    let status: String
    let createdAt: Date

    init(planning: Planning) {
        id = planning.id
        name = planning.name
        type = planning.type
        totalBudget = planning.totalBudget
        startDate = planning.startDate
        endDate = planning.endDate
        status = planning.status
        createdAt = planning.createdAt
    }

    var model: Planning {
        let planning = Planning(
            name: name,
            type: type,
            totalBudget: totalBudget,
            startDate: startDate,
            endDate: endDate,
            status: status,
            createdAt: createdAt
        )
        planning.id = id
        return planning
    }
}

struct BackupPlanningItemType: Codable, Sendable {
    let id: UUID
    let name: String
    let icon: String?
    let colorIdentifier: String?
    let planningId: UUID
    let isCustom: Bool
    let createdAt: Date

    init(itemType: PlanningItemType) {
        id = itemType.id
        name = itemType.name
        icon = itemType.icon
        colorIdentifier = itemType.colorIdentifier
        planningId = itemType.planningId
        isCustom = itemType.isCustom
        createdAt = itemType.createdAt
    }

    var model: PlanningItemType {
        let itemType = PlanningItemType(
            name: name,
            icon: icon,
            colorIdentifier: colorIdentifier,
            planningId: planningId,
            isCustom: isCustom,
            createdAt: createdAt
        )
        itemType.id = id
        return itemType
    }
}

struct BackupPlanningItem: Codable, Sendable {
    let id: UUID
    let planningId: UUID
    let itemTypeId: UUID?
    let name: String
    let details: String
    let plannedAmount: Double
    let icon: String?
    let colorIdentifier: String?
    let sortOrder: Double?
    let createdAt: Date

    init(item: PlanningItem) {
        id = item.id
        planningId = item.planningId
        itemTypeId = item.itemTypeId
        name = item.name
        details = item.details
        plannedAmount = item.plannedAmount
        icon = item.icon
        colorIdentifier = item.colorIdentifier
        sortOrder = item.sortOrder
        createdAt = item.createdAt
    }

    var model: PlanningItem {
        let item = PlanningItem(
            planningId: planningId,
            itemTypeId: itemTypeId,
            name: name,
            details: details,
            plannedAmount: plannedAmount,
            icon: icon,
            colorIdentifier: colorIdentifier,
            sortOrder: sortOrder,
            createdAt: createdAt
        )
        item.id = id
        return item
    }
}

struct BackupPlanningMovement: Codable, Sendable {
    let id: UUID
    let planningId: UUID
    let itemId: UUID
    let date: Date
    let title: String
    let amount: Double
    let note: String
    let affectModeRawValue: String
    let linkedAccountID: UUID?
    let linkedSavingID: UUID?
    let linkedAccountMovementID: UUID?
    let linkedSavingMovementID: UUID?
    let createdAt: Date

    init(movement: PlanningMovement) {
        id = movement.id
        planningId = movement.planningId
        itemId = movement.itemId
        date = movement.date
        title = movement.title
        amount = movement.amount
        note = movement.note
        affectModeRawValue = movement.affectModeRawValue
        linkedAccountID = movement.linkedAccountID
        linkedSavingID = movement.linkedSavingID
        linkedAccountMovementID = movement.linkedAccountMovementID
        linkedSavingMovementID = movement.linkedSavingMovementID
        createdAt = movement.createdAt
    }

    var model: PlanningMovement {
        let movement = PlanningMovement(
            planningId: planningId,
            itemId: itemId,
            date: date,
            title: title,
            amount: amount,
            note: note,
            affectModeRawValue: affectModeRawValue,
            linkedAccountID: linkedAccountID,
            linkedSavingID: linkedSavingID,
            linkedAccountMovementID: linkedAccountMovementID,
            linkedSavingMovementID: linkedSavingMovementID,
            createdAt: createdAt
        )
        movement.id = id
        return movement
    }
}

private extension Date {
    var backupFilenameDate: String {
        formatted(.dateTime.year().month(.twoDigits).day(.twoDigits).hour(.twoDigits(amPM: .omitted)).minute(.twoDigits))
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: " ", with: "-")
    }
}
