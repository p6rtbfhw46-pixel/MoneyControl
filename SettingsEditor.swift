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
    @Query private var exclusions: [RecurrenceExclusion]
    @State private var editorRequest: TransactionEditorRequest?
    @State private var selectedList = 0
    @State private var selectedTab: SettingsTab = .budget
    @State private var pendingAction: SettingsListAction?
    @State private var showsDeleteAllDataConfirmation = false
    @State private var isExportingBackup = false
    @State private var isImportingBackup = false
    @State private var backupDocument = SpendWiseBackupDocument(data: Data())
    @State private var pendingImportedBackup: SpendWiseBackup?
    @State private var backupNotice: BackupNotice?
    @State private var backupHelp: BackupNotice?

    private var nextMonth: Date {
        Date().monthStart.nextMonthStart
    }

    private var monthlyExpenses: [MoneyTransaction] {
        transactions
            .filter { $0.kind == TransactionKind.expense.rawValue && $0.recurrence == .monthly && $0.isActiveForSettingsList }
            .sorted { $0.day == $1.day ? $0.displayName < $1.displayName : $0.day < $1.day }
    }

    private var periodicExpenses: [MoneyTransaction] {
        transactions
            .filter { $0.kind == TransactionKind.expense.rawValue && $0.recurrence == .yearlyMonth && $0.isActiveForSettingsList }
            .sorted { $0.recurrenceMonth == $1.recurrenceMonth ? $0.day < $1.day : $0.recurrenceMonth < $1.recurrenceMonth }
    }

    private var salaries: [MoneyTransaction] {
        transactions
            .filter { $0.kind == TransactionKind.income.rawValue && $0.recurrence == .monthly && $0.isActiveForSettingsList }
            .sorted { $0.day == $1.day ? $0.title < $1.title : $0.day < $1.day }
    }

    private var selectedListTitle: String {
        switch selectedList {
        case 0:
            AppStrings.text(.salariesList)
        case 1:
            AppStrings.text(.monthlyExpensesList)
        default:
            AppStrings.text(.periodicExpensesList)
        }
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
            VStack(spacing: 0) {
                Picker("", selection: $selectedTab) {
                    Text(AppStrings.text(.budgetSettings)).tag(SettingsTab.budget)
                    Text(AppStrings.text(.appSettings)).tag(SettingsTab.app)
                }
                .pickerStyle(.segmented)
                .tint(AppPalette.background)
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 6)

                switch selectedTab {
                case .app:
                    appSettingsView
                case .budget:
                    budgetSettingsView
                }
            }
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
                BackupActionRow(
                    title: AppStrings.text(.exportBackup),
                    systemImage: "square.and.arrow.up",
                    helpMessage: AppStrings.text(.exportBackupHelp),
                    action: exportBackup,
                    onHelp: { backupHelp = BackupNotice(title: AppStrings.text(.exportBackup), message: $0) }
                )

                BackupActionRow(
                    title: AppStrings.text(.importBackup),
                    systemImage: "square.and.arrow.down",
                    helpMessage: AppStrings.text(.importBackupHelp),
                    action: { isImportingBackup = true },
                    onHelp: { backupHelp = BackupNotice(title: AppStrings.text(.importBackup), message: $0) }
                )

                BackupActionRow(
                    title: AppStrings.text(.deleteAllData),
                    systemImage: "trash",
                    helpMessage: AppStrings.text(.deleteAllDataMessage),
                    isDestructive: true,
                    action: { showsDeleteAllDataConfirmation = true },
                    onHelp: { backupHelp = BackupNotice(title: AppStrings.text(.deleteAllData), message: $0) }
                )
            }
            .listRowBackground(AppPalette.surface)
        }
        .listSectionSpacing(15)
        .scrollContentBackground(.hidden)
        .foregroundStyle(AppPalette.background)
        .tint(AppPalette.background)
        .background(AppPalette.appBackground)
    }

    private var budgetSettingsView: some View {
        ScrollView {
            VStack(spacing: 15) {
                VStack(spacing: 15) {
                    Button {
                        selectedList = 0
                        editorRequest = TransactionEditorRequest(mode: .salary, month: Date().monthStart)
                    } label: {
                        Label(AppStrings.text(.salary), systemImage: "banknote")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity, minHeight: 40, alignment: .leading)
                    }
                    .liquidGlassButtonStyle()

                    Button {
                        selectedList = 1
                        editorRequest = TransactionEditorRequest(mode: .monthlyExpense, month: Date().monthStart)
                    } label: {
                        Label(AppStrings.text(.monthlyExpense), systemImage: "calendar.badge.clock")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity, minHeight: 40, alignment: .leading)
                    }
                    .liquidGlassButtonStyle()

                    Button {
                        selectedList = 2
                        editorRequest = TransactionEditorRequest(mode: .periodicExpense, month: Date().monthStart)
                    } label: {
                        Label(AppStrings.text(.periodicExpense), systemImage: "calendar.badge.plus")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity, minHeight: 40, alignment: .leading)
                    }
                    .liquidGlassButtonStyle()
                }
                .padding(20)
                .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 28))

                VStack(alignment: .leading, spacing: 12) {
                    settingsListHeader

                    TabView(selection: $selectedList) {
                        RecurringList(
                            emptyTitle: AppStrings.text(.salariesList),
                            transactions: salaries,
                            payments: payments,
                            onEdit: { pendingAction = SettingsListAction(kind: .edit, transaction: $0) },
                            onDelete: { pendingAction = SettingsListAction(kind: .delete, transaction: $0) }
                        )
                        .tag(0)

                        RecurringList(
                            emptyTitle: AppStrings.text(.monthlyExpensesList),
                            transactions: monthlyExpenses,
                            payments: payments,
                            onEdit: { pendingAction = SettingsListAction(kind: .edit, transaction: $0) },
                            onDelete: { pendingAction = SettingsListAction(kind: .delete, transaction: $0) }
                        )
                        .tag(1)

                        RecurringList(
                            emptyTitle: AppStrings.text(.periodicExpensesList),
                            transactions: periodicExpenses,
                            payments: payments,
                            onEdit: { pendingAction = SettingsListAction(kind: .edit, transaction: $0) },
                            onDelete: { pendingAction = SettingsListAction(kind: .delete, transaction: $0) }
                        )
                        .tag(2)
                    }
                    .frame(minHeight: 320)
                    .monthPagerStyle()
                }
                .padding(20)
                .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 28))
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom)
        }
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

    private var settingsListHeader: some View {
        HStack(spacing: 12) {
            settingsListArrow(systemImage: "chevron.left") {
                selectedList = max(selectedList - 1, 0)
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
                selectedList = min(selectedList + 1, 2)
            }
            .disabled(selectedList >= 2)
            .opacity(selectedList >= 2 ? 0.35 : 1)
        }
    }

    private func settingsListArrow(systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.headline)
                .foregroundStyle(AppPalette.primary)
                .frame(width: 44, height: 42)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func exportBackup() {
        do {
            let backup = SpendWiseBackup(
                transactions: transactions.map { BackupTransaction(transaction: $0) },
                payments: payments.map { BackupPayment(payment: $0) },
                exclusions: exclusions.map { BackupExclusion(exclusion: $0) }
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
        exclusions.forEach(modelContext.delete)
        transactions.forEach(modelContext.delete)

        backup.transactions.map(\.model).forEach(modelContext.insert)
        backup.payments.map(\.model).forEach(modelContext.insert)
        backup.exclusions.map(\.model).forEach(modelContext.insert)

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
        }

        pendingAction = nil
    }

    private func deleteAllData() {
        payments.forEach(modelContext.delete)
        exclusions.forEach(modelContext.delete)
        transactions.forEach(modelContext.delete)
        hasCompletedInitialSetup = false
    }
}

private enum SettingsTab {
    case app
    case budget
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
    let onHelp: (String) -> Void

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
                Text("?")
                    .font(.headline.bold())
                    .foregroundStyle(AppPalette.background)
                    .frame(width: 34, height: 34)
                    .background(AppPalette.accent, in: Circle())
                    .overlay(Circle().stroke(AppPalette.background.opacity(0.18), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(AppStrings.text(.backupInfoTitle))
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
        exclusions: []
    )

    let version: Int
    let createdAt: Date
    let transactions: [BackupTransaction]
    let payments: [BackupPayment]
    let exclusions: [BackupExclusion]

    init(
        transactions: [BackupTransaction],
        payments: [BackupPayment],
        exclusions: [BackupExclusion]
    ) {
        version = Self.currentVersion
        createdAt = Date()
        self.transactions = transactions
        self.payments = payments
        self.exclusions = exclusions
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
            recurrenceEndMonthStart: recurrenceEndMonthStart
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

private extension Date {
    var backupFilenameDate: String {
        formatted(.dateTime.year().month(.twoDigits).day(.twoDigits).hour(.twoDigits(amPM: .omitted)).minute(.twoDigits))
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: " ", with: "-")
    }
}
