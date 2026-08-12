# SpendWise

SpendWise is an iPhone app for personal budget control. It helps users register monthly income, expenses, recurring payments, credit/debt balances, payments, and simple financial analyses using the 50/30/20 budgeting method.

## Functional Overview

The app is organized around three main areas:

- Current account
- Analyses
- Settings

### Current Account

The Current Account screen shows the user's budget for the selected month.

It includes:

- Available balance
- Amount still unpaid this month
- Amount still available to spend this month
- Monthly list of income and expenses
- Payment state for each expense
- Filters for paid/unpaid items, 50/30/20 category, expense type, and free text
- Help popups explaining how the main values are calculated
- Budget status card with automatic messages based on the current month

Expenses can be paid partially or in full. The paid amount affects the available balance immediately, even if the expense date has not yet arrived.

### Income And Expenses

Users can register:

- Monthly income
- Monthly recurring expenses
- Single-month annual expenses
- One-off monthly expenses and income from the current account

Each expense can have:

- 50/30/20 category
- Expense type
- Free text description
- Day of the month
- Amount
- Paid/unpaid state
- Optional connection to a credit/debt when the expense is a debt payment

Recurring expenses use the configured recurrence rules to appear in future months. When a recurring expense is created on a day that does not exist in a given month, the app uses the last valid day of that month.

### 50/30/20 Budget Method

SpendWise uses the 50/30/20 method as a reference:

- 50% Needs
- 30% Wants
- 20% Savings and debt payments

The app uses these categories in expenses, charts, filters, analysis, and budget status messages.

### Analyses

The Analyses screen includes:

- A "Where spent" chart by expense type
- A 50/30/20 chart comparing actual spending against the reference split
- Month navigation for previous months
- Annual summary mode
- Monthly insight cards when enough previous data exists
- Lists for subscriptions, savings, and income vs expenses
- A rotating carousel with financial tips

The analysis area uses registered user data and updates when transactions, payments, or settings change.

### Credits

Credits are managed from Settings.

Users can create credits/debts such as:

- Credit card
- Loan
- Installment purchase
- Other

Each credit stores:

- Name
- Type
- Current debt at creation
- Optional credit limit
- Status: active or settled

Credits have their own movement history:

- Debt increase
- Payment
- Fee/commission
- Adjustment

The current debt is calculated from the initial debt plus all movements. Credit totals are not automatically counted as monthly expenses. Only actual payments registered in the current account count toward the monthly budget.

When a current account expense is registered as a debt payment and linked to a credit, the app creates or updates the corresponding credit payment movement.

### Backup And Import

The app can export and import user data as a JSON backup file.

The backup includes:

- Transactions
- Payments
- Recurrence exclusions
- Credit accounts
- Credit movements
- Links between current account debt-payment expenses and credit movements

Import replaces the current local data with the data from the selected backup.

### Localization And Currency

The app supports Portuguese and English texts.

It uses Portuguese when the device language is Portuguese or Brazilian Portuguese. Otherwise, it falls back to English.

Currency formatting is based on the device region by default, but the user can choose a different currency in Settings. Amounts are formatted using the selected currency, locale rules, and decimal separators.

### Notifications

SpendWise can schedule local device notifications for upcoming unpaid expenses. The notification text prioritizes the free text entered by the user, followed by the expense type.

## Technical Overview

SpendWise is built with SwiftUI and SwiftData.

### Main Technologies

- SwiftUI for the interface
- SwiftData for local persistence
- Charts for visual analysis
- UserNotifications for local reminders
- FileDocument and JSON encoding for backup export/import
- XCTest/Testing for validation

The app is local-first. User data is stored on the device and is not sent to a server by the app.

### Data Models

The SwiftData schema is defined in `MoneyControlApp.swift` and currently includes:

- `MoneyTransaction`
- `ExpensePayment`
- `RecurrenceExclusion`
- `CreditAccount`
- `CreditMovement`

`MoneyTransaction` represents income and expenses. It stores recurrence metadata, payment links, category, type, free text, and optional credit linkage.

`ExpensePayment` stores the paid amount for an expense in a specific month.

`RecurrenceExclusion` marks a recurring transaction as excluded for a specific month.

`CreditAccount` represents a credit/debt account.

`CreditMovement` represents the movement history that changes a credit balance.

### Calculation Layer

Budget and analysis calculations are separated into `MoneyCalculationService.swift`.

This service centralizes logic for:

- Visible transactions in a month
- Paid amount calculation
- Available balance
- Monthly income, expenses, unpaid amount, and remaining budget
- Category totals
- Expense type totals
- Annual balance points
- Savings totals
- Analysis insights

This keeps calculation rules away from SwiftUI views and makes the logic easier to test.

### Domain Layer

`MoneyDomain.swift` contains domain concepts and helpers such as:

- Transaction kinds
- Recurrence types
- Expense categories
- Expense type definitions
- Date helpers
- Formatting helpers

`CreditDomain.swift` contains credit-specific concepts:

- Credit types
- Credit status
- Credit movement types
- Credit strings
- Credit balance helpers

### UI Structure

The UI is split across several files:

- `ContentView.swift`: main app shell, current account, analyses, navigation, filters, and payment interactions
- `MoneyComponents.swift`: reusable visual components
- `TransactionEditor.swift`: create/edit income and expenses
- `SettingsEditor.swift`: settings, budget lists, backup/import, app settings, and credits access
- `CreditViews.swift`: credit list, credit detail, forms, movements, and charts
- `OnboardingView.swift`: onboarding screens
- `InitialSetupWizardView.swift`: first setup wizard
- `AppPalette.swift`: visual identity and colors
- `AppStrings.swift`: app text and translations

### Backup Format

Backups are JSON files encoded with ISO 8601 dates.

The backup model is versioned through `SpendWiseBackup.currentVersion`. Credit fields are decoded with `decodeIfPresent`, so older backups without credit data can still be imported.

### Testing

The unit tests cover the core calculation behavior, including:

- Available balance
- Monthly remaining amount
- Recurrences
- Currency formatting behavior
- Analysis totals

Run tests from Xcode using the active scheme.

## Development Notes

The app is designed for iPhone in portrait orientation.

The interface forces light mode to preserve the SpendWise visual identity regardless of the device theme.

Generated Xcode user data under `MoneyControl.xcodeproj/xcuserdata/` should not be committed.
