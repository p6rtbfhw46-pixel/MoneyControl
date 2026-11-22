//
//  AccountsViews.swift
//  MoneyControl
//

import SwiftData
import SwiftUI

struct AccountsSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var accounts: [SpendAccount]
    @Query(sort: \AccountMovement.date, order: .reverse) private var movements: [AccountMovement]

    @State private var showsAccountEditor = false
    @State private var showsTransferEditor = false
    @State private var showsQuickActions = false
    @State private var showsIncomeEditor = false
    @State private var selectedAccount: SpendAccount?

    private var orderedAccounts: [SpendAccount] {
        accounts.sorted { first, second in
            return first.name.localizedCaseInsensitiveCompare(second.name) == .orderedAscending
        }
    }

    private var totalBalance: Double {
        accounts.reduce(0) { $0 + $1.balance(with: movements) }
    }

    private func insertAuditLog(action: AuditLogAction, title: String, amount: Double = 0, balanceAfter: Double? = nil, accountID: UUID? = nil) {
        modelContext.insert(AuditLogEntry(
            action: action.rawValue,
            title: title,
            amount: amount,
            balanceAfter: balanceAfter ?? totalBalance,
            accountID: accountID
        ))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                accountsHeroImage
                summaryCard

                Button {
                    showsTransferEditor = true
                } label: {
                    Label(AppStrings.text(.moveMoney), systemImage: "arrow.left.arrow.right")
                        .font(.headline)
                        .foregroundStyle(AppPalette.surface)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppPalette.background, in: RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
                .disabled(accounts.count < 2)
                .opacity(accounts.count < 2 ? 0.45 : 1)

                VStack(alignment: .leading, spacing: 10) {
                    Text(AppStrings.text(.accounts))
                        .font(.headline.bold())
                        .foregroundStyle(AppPalette.background)

                    if orderedAccounts.isEmpty {
                        ContentUnavailableView(AppStrings.text(.noAccounts), systemImage: "wallet.pass")
                            .foregroundStyle(AppPalette.background)
                            .frame(maxWidth: .infinity, minHeight: 180)
                    } else {
                        ForEach(orderedAccounts) { account in
                            accountListRow(account)
                        }
                    }
                }

                Button {
                    selectedAccount = nil
                    showsAccountEditor = true
                } label: {
                    Label(AppStrings.text(.addAccount), systemImage: "plus")
                        .font(.headline)
                        .foregroundStyle(AppPalette.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 16))
                        .overlay {
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(AppPalette.separator, lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)

                if accounts.count == 1 {
                    Text(AppStrings.text(.accountsMigrationHint))
                        .font(.caption)
                        .foregroundStyle(AppPalette.mutedText)
                        .padding(.horizontal, 4)
                }
            }
            .padding()
            .padding(.bottom, 96)
        }
        .overlay(alignment: .bottomTrailing) {
            accountsFloatingAddButton
                .padding(.trailing, 16)
                .padding(.bottom, 18)
        }
        .background(AppPalette.appBackground)
        .navigationTitle(AppStrings.text(.accounts))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showsAccountEditor) {
            AccountEditorView(account: selectedAccount)
        }
        .sheet(isPresented: $showsTransferEditor) {
            AccountTransferEditorView()
        }
        .sheet(isPresented: $showsIncomeEditor) {
            TransactionEditor(
                request: TransactionEditorRequest(mode: .income, month: Date().monthStart),
                onSaved: presentSaveNoticeAfterEditorCloses
            )
        }
    }

    private func presentSaveNoticeAfterEditorCloses(_ notice: SaveResultNotice) {
        SaveResultNoticeCenter.shared.show(notice)
        showsIncomeEditor = false
    }

    private var accountsFloatingAddButton: some View {
        VStack(alignment: .trailing, spacing: 10) {
            if showsQuickActions {
                Button {
                    showsIncomeEditor = true
                    withAnimation(.snappy) {
                        showsQuickActions = false
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text(AppStrings.text(.income))
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(AppPalette.background)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                            .frame(width: 124, height: 34)
                            .background(AppPalette.surface.opacity(0.98), in: Capsule())
                            .shadow(color: AppPalette.background.opacity(0.12), radius: 8, y: 4)

                        Image("QuickActionReceita")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 58, height: 58)
                            .shadow(color: AppPalette.background.opacity(0.18), radius: 12, y: 7)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(AppStrings.text(.income))
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            Button {
                withAnimation(.snappy) {
                    showsQuickActions.toggle()
                }
            } label: {
                Image(systemName: showsQuickActions ? "xmark" : "plus")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(AppPalette.background)
                    .frame(width: 50, height: 50)
                    .background(AppPalette.surface.opacity(0.98), in: Circle())
                    .overlay {
                        Circle()
                            .strokeBorder(AppPalette.separator.opacity(0.85), lineWidth: 1)
                    }
                    .shadow(color: AppPalette.background.opacity(0.14), radius: 12, y: 6)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(AppStrings.text(.add))
        }
    }

    private var accountsHeroImage: some View {
        Image(AppStrings.currentLanguage == .portuguese ? "AccountsHero" : "AccountsHeroEnglish")
            .resizable()
            .scaledToFill()
            .aspectRatio(1334.0 / 360.0, contentMode: .fill)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .shadow(color: AppPalette.background.opacity(0.10), radius: 12, y: 6)
    }

    private var summaryCard: some View {
        HStack(spacing: 14) {
            SpendWiseIcon(systemName: "wallet.pass.fill", color: AppPalette.mediumBlue, background: AppPalette.mediumBlue.opacity(0.12), size: 50)

            VStack(alignment: .leading, spacing: 4) {
                Text(AppStrings.text(.totalInAccounts))
                    .font(.subheadline)
                    .foregroundStyle(AppPalette.mutedText)

                Text(totalBalance.currencyText)
                    .font(.title.bold())
                    .foregroundStyle(AppPalette.background)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text(AppStrings.text(.totalInAccountsDescription))
                    .font(.caption)
                    .foregroundStyle(AppPalette.mutedText)
                    .lineLimit(2)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 22))
        .shadow(color: AppPalette.background.opacity(0.08), radius: 12, y: 6)
    }

    private func accountListRow(_ account: SpendAccount) -> some View {
        HStack(spacing: 14) {
            NavigationLink {
                AccountDetailView(account: account)
            } label: {
                accountRowContent(account)
            }
            .buttonStyle(.plain)

            Button {
                setPrimary(account)
            } label: {
                Image(systemName: account.isPrimary ? "star.fill" : "star")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(account.isPrimary ? AppPalette.savings : AppPalette.mutedText)
                    .frame(width: 44, height: 44)
                    .background(
                        (account.isPrimary ? AppPalette.savings : AppPalette.mutedText).opacity(0.12),
                        in: Circle()
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(AppStrings.text(.setPrimaryAccount))
        }
        .padding(16)
        .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 18))
        .shadow(color: AppPalette.background.opacity(0.06), radius: 9, y: 4)
    }

    private func accountRowContent(_ account: SpendAccount) -> some View {
        HStack(spacing: 14) {
            SpendWiseIcon(systemName: account.accountIcon.systemName, color: account.tint, background: account.tint.opacity(0.12), size: 50)

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Text(account.displayName)
                        .font(.headline.bold())
                        .foregroundStyle(AppPalette.background)
                    if account.isPrimary {
                        Text("⭐ \(AppStrings.text(.primaryAccountBadge))")
                            .font(.caption.bold())
                            .foregroundStyle(AppPalette.primary)
                    }
                }

                Text(account.balance(with: movements).currencyText)
                    .font(.title3.bold())
                    .foregroundStyle(AppPalette.background)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(AppPalette.mutedText)
        }
        .contentShape(Rectangle())
    }

    private func setPrimary(_ account: SpendAccount) {
        accounts.forEach { $0.isPrimary = $0.id == account.id }
        insertAuditLog(action: .accountUpdated, title: account.displayName, accountID: account.id)
    }
}

private struct AccountDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var accounts: [SpendAccount]
    @Query(sort: \AccountMovement.date, order: .reverse) private var movements: [AccountMovement]
    @Query private var transactions: [MoneyTransaction]
    @Query private var paymentHistory: [PaymentHistoryEntry]

    let account: SpendAccount

    @State private var showsEditor = false
    @State private var showsAdjustBalance = false
    @State private var deleteAlertMessage: String?

    private var balance: Double {
        account.balance(with: movements)
    }

    private var accountMovements: [AccountMovement] {
        movements.filter { $0.accountID == account.id }
    }

    private var totalBalance: Double {
        accounts.reduce(0) { $0 + $1.balance(with: movements) }
    }

    private func insertAuditLog(action: AuditLogAction, title: String, amount: Double = 0, balanceAfter: Double? = nil, accountID: UUID? = nil) {
        modelContext.insert(AuditLogEntry(
            action: action.rawValue,
            title: title,
            amount: amount,
            balanceAfter: balanceAfter ?? totalBalance,
            accountID: accountID
        ))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    SpendWiseIcon(systemName: account.accountIcon.systemName, color: account.tint, background: account.tint.opacity(0.12), size: 58)
                    Text(account.displayName)
                        .font(.title2.bold())
                        .foregroundStyle(AppPalette.background)
                    Text(balance.currencyText)
                        .font(.largeTitle.bold())
                        .foregroundStyle(AppPalette.background)
                    if account.isPrimary {
                        Text("⭐ \(AppStrings.text(.primaryAccountBadge))")
                            .font(.caption.bold())
                            .foregroundStyle(AppPalette.primary)
                    }
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 22))

                VStack(spacing: 10) {
                    accountActionButton(
                        title: AppStrings.text(.editAccount),
                        systemImage: "pencil",
                        tint: AppPalette.mediumBlue
                    ) {
                        showsEditor = true
                    }
                    accountActionButton(
                        title: AppStrings.text(.adjustBalance),
                        systemImage: "slider.horizontal.3",
                        tint: AppPalette.mediumBlue
                    ) {
                        showsAdjustBalance = true
                    }
                    if !account.isPrimary {
                        accountActionButton(
                            title: AppStrings.text(.setPrimaryAccount),
                            systemImage: "star.fill",
                            tint: AppPalette.savings
                        ) {
                            setPrimary()
                        }
                    }
                    accountActionButton(
                        title: AppStrings.text(.deleteAccount),
                        systemImage: "trash.fill",
                        tint: AppPalette.primary
                    ) {
                        deleteAccount()
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text(AppStrings.text(.accountHistory))
                        .font(.headline.bold())
                        .foregroundStyle(AppPalette.background)

                    if accountMovements.isEmpty {
                        ContentUnavailableView(AppStrings.text(.noAccountMovements), systemImage: "clock.arrow.circlepath")
                            .foregroundStyle(AppPalette.background)
                            .frame(maxWidth: .infinity, minHeight: 150)
                    } else {
                        ForEach(accountMovements) { movement in
                            AccountMovementRow(movement: movement, accounts: accounts)
                        }
                    }
                }
            }
            .padding()
        }
        .background(AppPalette.appBackground)
        .navigationTitle(account.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showsEditor) {
            AccountEditorView(account: account)
        }
        .sheet(isPresented: $showsAdjustBalance) {
            AccountBalanceAdjustmentView(account: account, currentBalance: balance)
        }
        .alert(AppStrings.text(.deleteAccountBlockedTitle), isPresented: showsDeleteBlockedAlert) {
            Button(AppStrings.text(.ok), role: .cancel) {}
        } message: {
            Text(deleteAlertMessage ?? "")
        }
    }

    private var showsDeleteBlockedAlert: Binding<Bool> {
        Binding(
            get: { deleteAlertMessage != nil },
            set: { if !$0 { deleteAlertMessage = nil } }
        )
    }

    private func setPrimary() {
        accounts.forEach { $0.isPrimary = $0.id == account.id }
        insertAuditLog(action: .accountUpdated, title: account.displayName, accountID: account.id)
    }

    private func accountActionButton(title: String, systemImage: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(tint)
                    .frame(width: 42, height: 42)
                    .background(tint.opacity(0.12), in: Circle())

                Text(title)
                    .font(.headline)
                    .foregroundStyle(AppPalette.background)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppPalette.mutedText)
            }
            .padding(14)
            .frame(maxWidth: .infinity)
            .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 18))
            .shadow(color: AppPalette.background.opacity(0.06), radius: 9, y: 4)
        }
        .buttonStyle(.plain)
    }

    private func deleteAccount() {
        deleteAlertMessage = nil
        if account.isPrimary {
            deleteAlertMessage = AppStrings.text(.deletePrimaryAccountMessage)
            return
        }
        if hasRecurringIncomeLinkedToAccount {
            deleteAlertMessage = AppStrings.text(.deleteAccountWithRecurringIncomeMessage)
            return
        }
        if abs(balance) > 0.005 {
            deleteAlertMessage = String(format: AppStrings.text(.deleteAccountWithBalanceMessage), balance.currencyText)
            return
        }
        let fallbackAccountID = accounts.first { $0.id != account.id && $0.isPrimary }?.id
            ?? accounts.first { $0.id != account.id }?.id
        transactions
            .filter { $0.accountID == account.id }
            .forEach { $0.accountID = fallbackAccountID }
        paymentHistory
            .filter { $0.accountID == account.id }
            .forEach { $0.accountID = fallbackAccountID }
        insertAuditLog(
            action: .accountDeleted,
            title: account.displayName,
            amount: -balance,
            balanceAfter: totalBalance - balance,
            accountID: account.id
        )
        accountMovements.forEach(modelContext.delete)
        modelContext.delete(account)
        dismiss()
    }

    private var hasRecurringIncomeLinkedToAccount: Bool {
        transactions.contains { transaction in
            transaction.accountID == account.id
                && transaction.kind == TransactionKind.income.rawValue
                && transaction.isRecurring
        }
    }
}

private struct AccountMovementRow: View {
    let movement: AccountMovement
    let accounts: [SpendAccount]

    private var relatedAccountName: String? {
        guard let relatedAccountID = movement.relatedAccountID else { return nil }
        return accounts.first { $0.id == relatedAccountID }?.displayName
    }

    var body: some View {
        HStack(spacing: 12) {
            SpendWiseIcon(systemName: movement.kind.iconName, color: movement.kind.tint, background: movement.kind.tint.opacity(0.12), size: 42)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundStyle(AppPalette.background)
                Text(movement.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(AppPalette.mutedText)
                if !movement.note.isEmpty {
                    Text(movement.note)
                        .font(.caption2)
                        .foregroundStyle(AppPalette.mutedText)
                }
            }

            Spacer()

            Text(movement.signedAmountText)
                .font(.subheadline.bold())
                .foregroundStyle(movement.amount >= 0 ? AppPalette.positive : AppPalette.primary)
        }
        .padding(12)
        .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 16))
    }

    private var title: String {
        if let relatedAccountName {
            switch movement.kind {
            case .transferIn:
                return String(format: AppStrings.text(.transferInAccountTitle), relatedAccountName)
            case .transferOut:
                return String(format: AppStrings.text(.transferOutAccountTitle), relatedAccountName)
            default:
                break
            }
        }
        return movement.kind.title
    }
}

private struct AccountEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var accounts: [SpendAccount]
    @Query private var movements: [AccountMovement]

    let account: SpendAccount?

    @State private var name = ""
    @State private var initialBalance = 0.0
    @State private var selectedIcon: SpendAccountIcon = .wallet
    @State private var selectedColor: SpendAccountColor = .blue
    @State private var isPrimary = false
    @State private var validationMessage: String?
    @State private var saveNotice: SaveResultNotice?

    private var totalBalance: Double {
        accounts.reduce(0) { $0 + $1.balance(with: movements) }
    }

    private func insertAuditLog(action: AuditLogAction, title: String, amount: Double = 0, balanceAfter: Double? = nil, accountID: UUID? = nil) {
        modelContext.insert(AuditLogEntry(
            action: action.rawValue,
            title: title,
            amount: amount,
            balanceAfter: balanceAfter ?? totalBalance,
            accountID: accountID
        ))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(AppStrings.text(.account)) {
                    TextField(AppStrings.text(.accountNamePlaceholder), text: $name)
                        .foregroundStyle(AppPalette.background)
                        .tint(AppPalette.primary)
                        .onSubmit(save)
                    if account == nil {
                        MoneyAmountPicker(title: AppStrings.text(.initialBalance), amount: $initialBalance, maximumAmount: 999_999_999, onConfirm: save)
                    }
                }
                .listRowBackground(AppPalette.surface)

                Section(AppStrings.text(.icon)) {
                    Picker(AppStrings.text(.icon), selection: $selectedIcon) {
                        ForEach(SpendAccountIcon.allCases) { icon in
                            Label(icon.title, systemImage: icon.systemName).tag(icon)
                        }
                    }
                    .tint(AppPalette.background)
                }
                .listRowBackground(AppPalette.surface)

                Section(AppStrings.text(.color)) {
                    ForEach(SpendAccountColor.allCases) { color in
                        Button {
                            selectedColor = color
                        } label: {
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(color.color)
                                    .frame(width: 18, height: 18)

                                Text(color.title)
                                    .foregroundStyle(AppPalette.background)

                                Spacer()

                                if selectedColor == color {
                                    Image(systemName: "checkmark")
                                        .font(.headline.weight(.semibold))
                                        .foregroundStyle(AppPalette.primary)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .listRowBackground(AppPalette.surface)

                if let validationMessage {
                    Text(validationMessage)
                        .foregroundStyle(AppPalette.primary)
                }
            }
            .scrollContentBackground(.hidden)
            .foregroundStyle(AppPalette.background)
            .tint(AppPalette.background)
            .background(AppPalette.appBackground)
            .navigationTitle(account == nil ? AppStrings.text(.newAccount) : AppStrings.text(.editAccountTitle))
            .toolbarBackground(AppPalette.appBackground, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(AppStrings.text(.cancel)) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(AppStrings.text(.save)) { save() }
                }
            }
            .onAppear(perform: load)
            .saveResultAlert($saveNotice, onDismiss: dismiss.callAsFunction)
        }
    }

    private func load() {
        guard name.isEmpty, let account else { return }
        name = account.displayName
        selectedIcon = account.accountIcon
        selectedColor = SpendAccountColor(rawValue: account.colorName) ?? .blue
        isPrimary = account.isPrimary
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            validationMessage = AppStrings.text(.accountNameValidation)
            return
        }

        let target = account ?? SpendAccount(
            name: trimmedName,
            iconName: selectedIcon.systemName,
            colorName: selectedColor.rawValue,
            initialBalance: initialBalance,
            isPrimary: accounts.isEmpty
        )

        target.name = trimmedName
        target.iconName = selectedIcon.systemName
        target.colorName = selectedColor.rawValue

        let isNewAccount = account == nil
        if isNewAccount {
            modelContext.insert(target)
        }

        if account != nil && isPrimary {
            (accounts + [target]).forEach { $0.isPrimary = $0.id == target.id }
        } else if account == nil && !accounts.contains(where: \.isPrimary) {
            target.isPrimary = true
        }

        insertAuditLog(
            action: isNewAccount ? .accountCreated : .accountUpdated,
            title: target.displayName,
            amount: isNewAccount ? initialBalance : 0,
            balanceAfter: totalBalance + (isNewAccount ? initialBalance : 0),
            accountID: target.id
        )

        SaveResultNoticeCenter.shared.show(.saved(String(
            format: AppStrings.text(isNewAccount ? .accountCreatedMessage : .accountUpdatedMessage),
            target.displayName
        )))
        dismiss()
    }
}

private struct AccountTransferEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var accounts: [SpendAccount]
    @Query private var movements: [AccountMovement]

    @State private var fromAccountID: UUID?
    @State private var toAccountID: UUID?
    @State private var amount = 0.0
    @State private var note = ""
    @State private var validationMessage: String?
    @State private var saveNotice: SaveResultNotice?

    private var orderedAccounts: [SpendAccount] {
        accounts.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private var totalBalance: Double {
        accounts.reduce(0) { $0 + $1.balance(with: movements) }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(AppStrings.text(.moveMoney)) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(AppStrings.text(.fromAccount))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppPalette.background)

                        SpendAccountSelectionStrip(
                            accounts: orderedAccounts,
                            accountMovements: movements,
                            selectedAccountID: normalizedFromAccountID
                        )
                    }

                    Button {
                        let currentFrom = normalizedFromAccountID.wrappedValue
                        fromAccountID = normalizedToAccountID.wrappedValue
                        toAccountID = currentFrom
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(AppPalette.primary)
                            .frame(maxWidth: .infinity, minHeight: 38)
                            .background(AppPalette.paleOrange.opacity(0.7), in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(AppStrings.text(.swapAccounts))

                    VStack(alignment: .leading, spacing: 10) {
                        Text(AppStrings.text(.toAccount))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppPalette.background)

                        SpendAccountSelectionStrip(
                            accounts: orderedAccounts,
                            accountMovements: movements,
                            selectedAccountID: normalizedToAccountID
                        )
                    }
                    MoneyAmountPicker(title: AppStrings.text(.value), amount: $amount, maximumAmount: 999_999_999)
                    TextField(AppStrings.text(.note), text: $note)
                }

                if let validationMessage {
                    Text(validationMessage)
                        .foregroundStyle(AppPalette.primary)
                }
            }
            .navigationTitle(AppStrings.text(.moveMoney))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(AppStrings.text(.cancel)) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(AppStrings.text(.ok)) { save() }
                }
            }
            .onAppear {
                normalizeAccountSelections()
            }
            .saveResultAlert($saveNotice, onDismiss: dismiss.callAsFunction)
        }
    }

    private var normalizedFromAccountID: Binding<UUID?> {
        Binding(
            get: {
                validAccountID(fromAccountID) ?? orderedAccounts.first(where: \.isPrimary)?.id ?? orderedAccounts.first?.id
            },
            set: { fromAccountID = $0 }
        )
    }

    private var normalizedToAccountID: Binding<UUID?> {
        Binding(
            get: {
                let sourceID = validAccountID(fromAccountID) ?? orderedAccounts.first(where: \.isPrimary)?.id ?? orderedAccounts.first?.id
                return validAccountID(toAccountID).flatMap { $0 == sourceID ? nil : $0 }
                    ?? orderedAccounts.first(where: { $0.id != sourceID })?.id
            },
            set: { toAccountID = $0 }
        )
    }

    private func validAccountID(_ id: UUID?) -> UUID? {
        guard let id, accounts.contains(where: { $0.id == id }) else { return nil }
        return id
    }

    private func normalizeAccountSelections() {
        fromAccountID = normalizedFromAccountID.wrappedValue
        toAccountID = normalizedToAccountID.wrappedValue
    }

    private func save() {
        guard let fromAccountID, let toAccountID, fromAccountID != toAccountID else {
            validationMessage = AppStrings.text(.chooseDifferentAccounts)
            return
        }
        guard amount > 0 else {
            validationMessage = AppStrings.text(.fillValue)
            return
        }
        guard let fromAccount = accounts.first(where: { $0.id == fromAccountID }) else { return }
        let currentBalance = fromAccount.balance(with: movements)
        guard currentBalance + 0.005 >= amount else {
            validationMessage = AppStrings.text(.sourceAccountInsufficientBalance)
            return
        }

        let cleanNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        modelContext.insert(AccountMovement(
            accountID: fromAccountID,
            relatedAccountID: toAccountID,
            type: AccountMovementKind.transferOut.rawValue,
            amount: -abs(amount),
            note: cleanNote
        ))
        modelContext.insert(AccountMovement(
            accountID: toAccountID,
            relatedAccountID: fromAccountID,
            type: AccountMovementKind.transferIn.rawValue,
            amount: abs(amount),
            note: cleanNote
        ))
        let toAccountName = accounts.first(where: { $0.id == toAccountID })?.displayName ?? ""
        modelContext.insert(AuditLogEntry(
            action: AuditLogAction.accountTransfer.rawValue,
            title: fromAccount.displayName,
            details: toAccountName.isEmpty ? "" : "\(fromAccount.displayName) -> \(toAccountName)",
            note: cleanNote,
            amount: abs(amount),
            balanceAfter: totalBalance,
            accountID: fromAccountID,
            relatedAccountID: toAccountID
        ))
        SaveResultNoticeCenter.shared.show(.saved(String(format: AppStrings.text(.accountTransferCreatedMessage), amount.currencyText)))
        dismiss()
    }
}

private struct AccountBalanceAdjustmentView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var accounts: [SpendAccount]
    @Query private var movements: [AccountMovement]

    let account: SpendAccount
    let currentBalance: Double

    @State private var newBalance = 0.0
    @State private var note = ""
    @State private var saveNotice: SaveResultNotice?

    private var totalBalance: Double {
        accounts.reduce(0) { $0 + $1.balance(with: movements) }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(AppStrings.text(.adjustBalance)) {
                    Text("\(AppStrings.text(.currentBalance)): \(currentBalance.currencyText)")
                    MoneyAmountPicker(title: AppStrings.text(.newBalance), amount: $newBalance, maximumAmount: 999_999_999)
                    TextField(AppStrings.text(.note), text: $note)
                }
            }
            .navigationTitle(AppStrings.text(.adjustBalance))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(AppStrings.text(.cancel)) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(AppStrings.text(.ok)) { save() }
                }
            }
            .onAppear {
                newBalance = currentBalance
            }
            .saveResultAlert($saveNotice, onDismiss: dismiss.callAsFunction)
        }
    }

    private func save() {
        let difference = newBalance - currentBalance
        guard abs(difference) > 0.005 else {
            dismiss()
            return
        }

        modelContext.insert(AccountMovement(
            accountID: account.id,
            type: AccountMovementKind.adjustment.rawValue,
            amount: difference,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines)
        ))
        modelContext.insert(AuditLogEntry(
            action: AuditLogAction.accountBalanceAdjusted.rawValue,
            title: account.displayName,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines),
            amount: difference,
            balanceAfter: totalBalance + difference,
            accountID: account.id
        ))
        SaveResultNoticeCenter.shared.show(.saved(String(
            format: AppStrings.text(.accountBalanceAdjustedMessage),
            account.displayName,
            newBalance.currencyText
        )))
        dismiss()
    }
}
