//
//  SettingsEditor.swift
//  MoneyControl
//

import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct SettingsEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @AppStorage("hasCompletedInitialSetup") private var hasCompletedInitialSetup = false
    @AppStorage(AppPreferences.selectedCurrencyCodeKey) private var selectedCurrencyCode = ""
    @Query private var transactions: [MoneyTransaction]
    @Query private var payments: [ExpensePayment]
    @Query private var paymentHistory: [PaymentHistoryEntry]
    @Query private var exclusions: [RecurrenceExclusion]
    @Query private var creditAccounts: [CreditAccount]
    @Query private var creditMovements: [CreditMovement]
    @Query private var savingAccounts: [SavingAccount]
    @Query private var savingMovements: [SavingMovement]
    @State private var editorRequest: TransactionEditorRequest?
    @State private var selectedList = 0
    @State private var selectedListDirection = 1
    @State private var selectedTab: SettingsTab = .budget
    @State private var pendingAction: SettingsListAction?
    @State private var showsDeleteAllDataConfirmation = false
    @State private var isExportingBackup = false
    @State private var isImportingBackup = false
    @State private var backupDocument = SpendWiseBackupDocument(data: Data())
    @State private var pendingImportedBackup: SpendWiseBackup?
    @State private var backupNotice: BackupNotice?
    @State private var backupHelp: BackupNotice?

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
            .filter { $0.kind == TransactionKind.expense.rawValue && $0.isRecurring && $0.isActiveForSettingsList }
            .sorted { first, second in
                if first.day != second.day { return first.day < second.day }
                return first.displayName.localizedCaseInsensitiveCompare(second.displayName) == .orderedAscending
            }
    }

    private var recurringIncome: [MoneyTransaction] {
        transactions
            .filter { $0.kind == TransactionKind.income.rawValue && $0.isRecurring && $0.isActiveForSettingsList }
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
                TransactionEditor(request: request)
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
                Button(AppStrings.text(.continueAction), role: action.kind == .delete ? .destructive : nil) {
                    perform(action)
                }
            } message: { action in
                Text(action.message)
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
            .alert(AppStrings.text(.importBackupConfirmationTitle), isPresented: hasPendingImportedBackup) {
                Button(AppStrings.text(.cancel), role: .cancel) { pendingImportedBackup = nil }
                Button(AppStrings.text(.continueAction), role: .destructive, action: importPendingBackup)
            } message: {
                Text(AppStrings.text(.importBackupConfirmationMessage))
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
                Text(AppStrings.text(.appDataPrivacyNote))
                    .font(.subheadline)
                    .foregroundStyle(AppPalette.mutedText)

                BackupActionRow(
                    title: AppStrings.text(.exportBackup),
                    systemImage: "square.and.arrow.up",
                    helpMessage: AppStrings.text(.exportBackupHelp),
                    action: exportBackup
                )

                BackupActionRow(
                    title: AppStrings.text(.importBackup),
                    systemImage: "square.and.arrow.down",
                    helpMessage: AppStrings.text(.importBackupHelp),
                    action: { isImportingBackup = true }
                )

                BackupActionRow(
                    title: AppStrings.text(.deleteAllData),
                    systemImage: "trash",
                    helpMessage: AppStrings.text(.deleteAllDataMessage),
                    isDestructive: true,
                    action: { showsDeleteAllDataConfirmation = true }
                )
            }
            .listRowBackground(AppPalette.surface)

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
        }
        .navigationTitle(AppStrings.text(.dataPrivacy))
        .navigationBarTitleDisplayMode(.inline)
        .scrollContentBackground(.hidden)
        .foregroundStyle(AppPalette.background)
        .tint(AppPalette.background)
        .background(AppPalette.appBackground)
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
                onEdit: { pendingAction = SettingsListAction(kind: .edit, transaction: $0) },
                onDelete: { pendingAction = SettingsListAction(kind: .delete, transaction: $0) }
            )
        } else {
            RecurringList(
                emptyTitle: AppStrings.text(.recurringIncome),
                transactions: recurringIncome,
                payments: payments,
                onEdit: { pendingAction = SettingsListAction(kind: .edit, transaction: $0) },
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

    private func exportBackup() {
        do {
            let backup = SpendWiseBackup(
                transactions: transactions.map { BackupTransaction(transaction: $0) },
                payments: payments.map { BackupPayment(payment: $0) },
                paymentHistory: paymentHistory.map { BackupPaymentHistoryEntry(entry: $0) },
                exclusions: exclusions.map { BackupExclusion(exclusion: $0) },
                creditAccounts: creditAccounts.map { BackupCreditAccount(credit: $0) },
                creditMovements: creditMovements.map { BackupCreditMovement(movement: $0) },
                savingAccounts: savingAccounts.map { BackupSavingAccount(saving: $0) },
                savingMovements: savingMovements.map { BackupSavingMovement(movement: $0) }
            )
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            backupDocument = SpendWiseBackupDocument(data: try encoder.encode(backup))
            isExportingBackup = true
        } catch {
            backupNotice = BackupNotice(
                title: AppStrings.text(.exportBackupFailureTitle),
                message: error.localizedDescription
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
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let backup = try decoder.decode(SpendWiseBackup.self, from: data)
                guard backup.version == SpendWiseBackup.currentVersion else {
                    throw BackupError.unsupportedVersion
                }
                pendingImportedBackup = backup
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

        backup.transactions.map(\.model).forEach(modelContext.insert)
        backup.payments.map(\.model).forEach(modelContext.insert)
        backup.paymentHistory.map(\.model).forEach(modelContext.insert)
        backup.exclusions.map(\.model).forEach(modelContext.insert)
        backup.creditAccounts.map(\.model).forEach(modelContext.insert)
        backup.creditMovements.map(\.model).forEach(modelContext.insert)
        backup.savingAccounts.map(\.model).forEach(modelContext.insert)
        backup.savingMovements.map(\.model).forEach(modelContext.insert)

        pendingImportedBackup = nil

        do {
            try modelContext.save()
            backupNotice = BackupNotice(
                title: AppStrings.text(.importBackupSuccessTitle),
                message: AppStrings.text(.importBackupSuccessMessage)
            )
        } catch {
            backupNotice = BackupNotice(
                title: AppStrings.text(.importBackupFailureTitle),
                message: error.localizedDescription
            )
        }
    }

    private func perform(_ action: SettingsListAction) {
        switch action.kind {
        case .edit:
            editorRequest = TransactionEditorRequest(transaction: action.transaction, month: nextMonth, editScope: .futureMonths)
        case .delete:
            action.transaction.recurrenceEndMonthStart = nextMonth
            payments
                .filter { $0.transactionID == action.transaction.id && $0.monthStart >= nextMonth }
                .forEach(modelContext.delete)
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
        hasCompletedInitialSetup = false
    }
}

struct BudgetSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var transactions: [MoneyTransaction]
    @Query private var payments: [ExpensePayment]
    @Query private var paymentHistory: [PaymentHistoryEntry]
    @Query private var creditAccounts: [CreditAccount]
    @Query private var savingAccounts: [SavingAccount]
    @State private var editorRequest: TransactionEditorRequest?
    @State private var selectedList = 0
    @State private var pendingAction: SettingsListAction?
    @State private var helpNotice: BackupNotice?
    @State private var showsRecurringActions = false
    @State private var recurringActionIconPulse = false

    private var nextMonth: Date {
        Date().monthStart.nextMonthStart
    }

    private var recurringExpenses: [MoneyTransaction] {
        transactions
            .filter { $0.kind == TransactionKind.expense.rawValue && $0.isRecurring && $0.isActiveForSettingsList }
            .sorted { first, second in
                if first.day != second.day { return first.day < second.day }
                return first.displayName.localizedCaseInsensitiveCompare(second.displayName) == .orderedAscending
            }
    }

    private var recurringIncome: [MoneyTransaction] {
        transactions
            .filter { $0.kind == TransactionKind.income.rawValue && $0.isRecurring && $0.isActiveForSettingsList }
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
                settingsListHeader
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 10)
                    .background(AppPalette.appBackground)

                ScrollView {
                    VStack(spacing: 12) {
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
                    .padding(.top, 2)
                    .padding(.bottom, 128)
                }
            }

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
        .foregroundStyle(AppPalette.background)
        .tint(AppPalette.background)
        .background(AppPalette.appBackground)
        .navigationTitle(AppStrings.text(.budgetSettings))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editorRequest) { request in
            TransactionEditor(request: request)
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
            Button(AppStrings.text(.continueAction), role: action.kind == .delete ? .destructive : nil) {
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

    @ViewBuilder
    private var selectedSettingsList: some View {
        if selectedList == 0 {
            RecurringList(
                emptyTitle: AppStrings.text(.recurringExpenses),
                transactions: recurringExpenses,
                payments: payments,
                onEdit: { pendingAction = SettingsListAction(kind: .edit, transaction: $0) },
                onDelete: { pendingAction = SettingsListAction(kind: .delete, transaction: $0) }
            )
        } else {
            RecurringList(
                emptyTitle: AppStrings.text(.recurringIncome),
                transactions: recurringIncome,
                payments: payments,
                onEdit: { pendingAction = SettingsListAction(kind: .edit, transaction: $0) },
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
        Group {
            if hasActiveSavings && hasActiveCredits {
                HStack(spacing: 10) {
                    VStack(spacing: 10) {
                        recurringSavingActionButton
                        recurringCreditPaymentActionButton
                    }

                    VStack(spacing: 10) {
                        recurringIncomeActionButton
                        recurringExpenseActionButton
                    }
                }
            } else if hasQuickSavingsOrCredits {
                VStack(spacing: 10) {
                    HStack(spacing: 10) {
                        recurringIncomeActionButton
                        recurringExpenseActionButton
                    }

                    if hasActiveSavings {
                        recurringSavingActionButton
                    }

                    if hasActiveCredits {
                        recurringCreditPaymentActionButton
                    }
                }
            } else {
                HStack(spacing: 10) {
                    recurringIncomeActionButton
                    recurringExpenseActionButton
                }
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity)
        .background(.white.opacity(0.94), in: RoundedRectangle(cornerRadius: 18))
        .shadow(color: AppPalette.background.opacity(0.10), radius: 18, y: 8)
        .onAppear {
            recurringActionIconPulse = false
            withAnimation(.easeInOut(duration: 0.6).repeatCount(2, autoreverses: true)) {
                recurringActionIconPulse = true
            }
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
            systemImage: "banknote.fill",
            iconColor: AppPalette.savings,
            textColor: AppPalette.background,
            background: AppPalette.mintSurface
        ) {
            openPresetRecurringExpense(title: AppStrings.text(.newSavingExpense), expenseName: recurringSavingExpenseName)
        }
    }

    private var recurringCreditPaymentActionButton: some View {
        recurringActionButton(
            title: AppStrings.text(.newCreditPaymentExpense),
            systemImage: "creditcard.fill",
            iconColor: AppPalette.primary,
            textColor: AppPalette.surface,
            background: AppPalette.background
        ) {
            openPresetRecurringExpense(title: AppStrings.text(.newCreditPaymentExpense), expenseName: recurringCreditPaymentExpenseName)
        }
    }

    private var recurringIncomeActionButton: some View {
        recurringActionButton(
            title: AppStrings.text(.recurringIncome),
            systemImage: "tray.and.arrow.down.fill",
            iconColor: AppPalette.savings,
            textColor: AppPalette.background,
            background: AppPalette.secondary
        ) {
            selectSettingsList(1)
            editorRequest = TransactionEditorRequest(mode: .salary, month: Date().monthStart)
            showsRecurringActions = false
        }
    }

    private var recurringExpenseActionButton: some View {
        recurringActionButton(
            title: AppStrings.text(.recurringExpenses),
            systemImage: "tray.and.arrow.up.fill",
            iconColor: AppPalette.surface,
            textColor: AppPalette.surface,
            background: AppPalette.primary
        ) {
            selectSettingsList(0)
            editorRequest = TransactionEditorRequest(mode: .monthlyExpense, month: Date().monthStart)
            showsRecurringActions = false
        }
    }

    private func recurringActionButton(title: String, systemImage: String, iconColor: Color, textColor: Color, background: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.headline.bold())
                    .foregroundStyle(iconColor)
                    .scaleEffect(recurringActionIconPulse ? 1.12 : 1)

                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            .foregroundStyle(textColor)
            .frame(maxWidth: .infinity, minHeight: 46)
            .background(background, in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
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
            editorRequest = TransactionEditorRequest(transaction: action.transaction, month: nextMonth, editScope: .futureMonths)
        case .delete:
            action.transaction.recurrenceEndMonthStart = nextMonth
            payments
                .filter { $0.transactionID == action.transaction.id && $0.monthStart >= nextMonth }
                .forEach(modelContext.delete)
            paymentHistory
                .filter { $0.transactionID == action.transaction.id && $0.monthStart >= nextMonth }
                .forEach(modelContext.delete)
        }

        pendingAction = nil
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
    }

    let id = UUID()
    let kind: Kind
    let transaction: MoneyTransaction

    var title: String {
        switch kind {
        case .edit:
            AppStrings.text(.futureEditTitle)
        case .delete:
            AppStrings.text(.futureDeleteTitle)
        }
    }

    var message: String {
        switch kind {
        case .edit:
            AppStrings.text(.futureEditMessage)
        case .delete:
            AppStrings.text(.futureDeleteMessage)
        }
    }
}

private struct BackupActionRow: View {
    let title: String
    let systemImage: String
    let helpMessage: String
    var isDestructive = false
    let action: () -> Void

    @State private var showsHelp = false

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
                showsHelp = true
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
        .alert(title, isPresented: $showsHelp) {
            Button(AppStrings.text(.ok)) {}
        } message: {
            Text(helpMessage)
        }
    }
}

private struct BudgetAddActionRow: View {
    let title: String
    let systemImage: String
    let helpMessage: String
    let action: () -> Void
    let onHelp: (String) -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: action) {
                Label(title, systemImage: systemImage)
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 40, alignment: .leading)
            }
            .liquidGlassButtonStyle()

            Button {
                onHelp(helpMessage)
            } label: {
                Image(systemName: "info.circle")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(AppPalette.background)
                    .frame(width: 34, height: 34)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(title)
        }
    }
}

private struct BackupNotice: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

private enum BackupError: Error {
    case unsupportedVersion
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

private struct SpendWiseBackup: Codable, Sendable {
    static let currentVersion = 1
    static let empty = SpendWiseBackup(
        transactions: [],
        payments: [],
        paymentHistory: [],
        exclusions: [],
        creditAccounts: [],
        creditMovements: [],
        savingAccounts: [],
        savingMovements: []
    )

    let version: Int
    let createdAt: Date
    let transactions: [BackupTransaction]
    let payments: [BackupPayment]
    let paymentHistory: [BackupPaymentHistoryEntry]
    let exclusions: [BackupExclusion]
    let creditAccounts: [BackupCreditAccount]
    let creditMovements: [BackupCreditMovement]
    let savingAccounts: [BackupSavingAccount]
    let savingMovements: [BackupSavingMovement]

    private enum CodingKeys: String, CodingKey {
        case version
        case createdAt
        case transactions
        case payments
        case paymentHistory
        case exclusions
        case creditAccounts
        case creditMovements
        case savingAccounts
        case savingMovements
    }

    init(
        transactions: [BackupTransaction],
        payments: [BackupPayment],
        paymentHistory: [BackupPaymentHistoryEntry] = [],
        exclusions: [BackupExclusion],
        creditAccounts: [BackupCreditAccount] = [],
        creditMovements: [BackupCreditMovement] = [],
        savingAccounts: [BackupSavingAccount] = [],
        savingMovements: [BackupSavingMovement] = []
    ) {
        version = Self.currentVersion
        createdAt = Date()
        self.transactions = transactions
        self.payments = payments
        self.paymentHistory = paymentHistory
        self.exclusions = exclusions
        self.creditAccounts = creditAccounts
        self.creditMovements = creditMovements
        self.savingAccounts = savingAccounts
        self.savingMovements = savingMovements
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        version = try container.decode(Int.self, forKey: .version)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        transactions = try container.decode([BackupTransaction].self, forKey: .transactions)
        payments = try container.decode([BackupPayment].self, forKey: .payments)
        paymentHistory = try container.decodeIfPresent([BackupPaymentHistoryEntry].self, forKey: .paymentHistory) ?? []
        exclusions = try container.decode([BackupExclusion].self, forKey: .exclusions)
        creditAccounts = try container.decodeIfPresent([BackupCreditAccount].self, forKey: .creditAccounts) ?? []
        creditMovements = try container.decodeIfPresent([BackupCreditMovement].self, forKey: .creditMovements) ?? []
        savingAccounts = try container.decodeIfPresent([BackupSavingAccount].self, forKey: .savingAccounts) ?? []
        savingMovements = try container.decodeIfPresent([BackupSavingMovement].self, forKey: .savingMovements) ?? []
    }
}

private struct BackupTransaction: Codable, Sendable {
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
    let recurrenceType: String?
    let recurrenceMonth: Int
    let recurrenceEndMonthStart: Date?
    let linkedCreditID: UUID?
    let linkedCreditMovementID: UUID?
    let linkedSavingID: UUID?
    let linkedSavingMovementID: UUID?

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
        recurrenceType = transaction.recurrenceType
        recurrenceMonth = transaction.recurrenceMonth
        recurrenceEndMonthStart = transaction.recurrenceEndMonthStart
        linkedCreditID = transaction.linkedCreditID
        linkedCreditMovementID = transaction.linkedCreditMovementID
        linkedSavingID = transaction.linkedSavingID
        linkedSavingMovementID = transaction.linkedSavingMovementID
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
            recurrenceType: recurrenceType,
            recurrenceMonth: recurrenceMonth,
            recurrenceEndMonthStart: recurrenceEndMonthStart,
            linkedCreditID: linkedCreditID,
            linkedCreditMovementID: linkedCreditMovementID,
            linkedSavingID: linkedSavingID,
            linkedSavingMovementID: linkedSavingMovementID
        )
        transaction.id = id
        return transaction
    }
}

private struct BackupPayment: Codable, Sendable {
    let transactionID: UUID
    let monthStart: Date
    let amountPaid: Double?

    init(payment: ExpensePayment) {
        transactionID = payment.transactionID
        monthStart = payment.monthStart
        amountPaid = payment.amountPaid
    }

    var model: ExpensePayment {
        ExpensePayment(transactionID: transactionID, monthStart: monthStart, amountPaid: amountPaid)
    }
}

private struct BackupPaymentHistoryEntry: Codable, Sendable {
    let id: UUID
    let transactionID: UUID
    let monthStart: Date
    let amount: Double
    let paidAt: Date

    init(entry: PaymentHistoryEntry) {
        id = entry.id
        transactionID = entry.transactionID
        monthStart = entry.monthStart
        amount = entry.amount
        paidAt = entry.paidAt
    }

    var model: PaymentHistoryEntry {
        let entry = PaymentHistoryEntry(
            transactionID: transactionID,
            monthStart: monthStart,
            amount: amount,
            paidAt: paidAt
        )
        entry.id = id
        return entry
    }
}

private struct BackupExclusion: Codable, Sendable {
    let transactionID: UUID
    let monthStart: Date

    init(exclusion: RecurrenceExclusion) {
        transactionID = exclusion.transactionID
        monthStart = exclusion.monthStart
    }

    var model: RecurrenceExclusion {
        RecurrenceExclusion(transactionID: transactionID, monthStart: monthStart)
    }
}

private struct BackupCreditAccount: Codable, Sendable {
    let id: UUID
    let name: String
    let type: String
    let initialDebt: Double
    let creditLimit: Double?
    let createdAt: Date
    let status: String

    init(credit: CreditAccount) {
        id = credit.id
        name = credit.name
        type = credit.type
        initialDebt = credit.initialDebt
        creditLimit = credit.creditLimit
        createdAt = credit.createdAt
        status = credit.status
    }

    var model: CreditAccount {
        let credit = CreditAccount(
            name: name,
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

private struct BackupCreditMovement: Codable, Sendable {
    let id: UUID
    let creditID: UUID
    let date: Date
    let type: String
    let amount: Double
    let note: String

    init(movement: CreditMovement) {
        id = movement.id
        creditID = movement.creditID
        date = movement.date
        type = movement.type
        amount = movement.amount
        note = movement.note
    }

    var model: CreditMovement {
        let movement = CreditMovement(
            creditID: creditID,
            date: date,
            type: type,
            amount: amount,
            note: note
        )
        movement.id = id
        return movement
    }
}

private struct BackupSavingAccount: Codable, Sendable {
    let id: UUID
    let name: String
    let initialAmount: Double
    let targetAmount: Double?
    let createdAt: Date
    let status: String

    init(saving: SavingAccount) {
        id = saving.id
        name = saving.name
        initialAmount = saving.initialAmount
        targetAmount = saving.targetAmount
        createdAt = saving.createdAt
        status = saving.status
    }

    var model: SavingAccount {
        let saving = SavingAccount(
            name: name,
            initialAmount: initialAmount,
            targetAmount: targetAmount,
            createdAt: createdAt,
            status: status
        )
        saving.id = id
        return saving
    }
}

private struct BackupSavingMovement: Codable, Sendable {
    let id: UUID
    let savingID: UUID
    let date: Date
    let type: String
    let amount: Double
    let note: String
    let linkedIncomeTransactionID: UUID?

    init(movement: SavingMovement) {
        id = movement.id
        savingID = movement.savingID
        date = movement.date
        type = movement.type
        amount = movement.amount
        note = movement.note
        linkedIncomeTransactionID = movement.linkedIncomeTransactionID
    }

    var model: SavingMovement {
        let movement = SavingMovement(
            savingID: savingID,
            date: date,
            type: type,
            amount: amount,
            note: note,
            linkedIncomeTransactionID: linkedIncomeTransactionID
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
