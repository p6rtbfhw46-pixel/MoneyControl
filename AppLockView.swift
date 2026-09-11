//
//  AppLockView.swift
//  MoneyControl
//

import Foundation
import LocalAuthentication
import Security
import SwiftUI

enum AppLockMode {
    case setup
    case unlock
}

enum AppLockService {
    private static let service = "SpendWise.AppLock"
    private static let account = "AppPIN"

    static var hasPIN: Bool {
        storedPIN() != nil
    }

    static var biometricsAvailable: Bool {
        var error: NSError?
        return LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    static var biometricTypeName: String {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        switch context.biometryType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        case .opticID:
            return "Optic ID"
        default:
            return "biometria"
        }
    }

    static func validate(pin: String) -> Bool {
        storedPIN() == pin
    }

    static func save(pin: String) -> Bool {
        guard let data = pin.data(using: .utf8) else { return false }
        deletePIN()

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            kSecValueData as String: data
        ]

        return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
    }

    static func deletePIN() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }

    static func authenticateWithBiometrics(reason: String) async -> Bool {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return false
        }

        do {
            return try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)
        } catch {
            return false
        }
    }

    private static func storedPIN() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }
}

struct AppLockView: View {
    let mode: AppLockMode
    var allowsBiometrics = true
    let onUnlocked: () -> Void

    @AppStorage(AppPreferences.appLockBiometricsEnabledKey) private var biometricsEnabled = false
    @State private var pin = ""
    @State private var confirmationPIN = ""
    @State private var isConfirmingPIN = false
    @State private var message: String?
    @State private var isAuthenticating = false

    private let pinLength = 4

    private var title: String {
        switch mode {
        case .setup:
            isConfirmingPIN ? "Confirmar código" : "Criar código"
        case .unlock:
            "SpendWise bloqueada"
        }
    }

    private var subtitle: String {
        switch mode {
        case .setup:
            isConfirmingPIN ? "Volte a introduzir o código para confirmar." : "Escolha um código de 4 dígitos para proteger a app."
        case .unlock:
            "Introduza o código ou use \(AppLockService.biometricTypeName)."
        }
    }

    private var activePIN: String {
        isConfirmingPIN ? confirmationPIN : pin
    }

    var body: some View {
        ZStack {
            AppPalette.appBackground.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Image("SpendWiseIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 82, height: 82)
                    .shadow(color: AppPalette.background.opacity(0.14), radius: 18, y: 10)

                VStack(spacing: 8) {
                    Text(title)
                        .font(.largeTitle.bold())
                        .foregroundStyle(AppPalette.background)
                        .multilineTextAlignment(.center)

                    Text(subtitle)
                        .font(.body)
                        .foregroundStyle(AppPalette.bodyText)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                pinDots

                if let message {
                    Text(message)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppPalette.primary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                keypad

                if mode == .unlock, biometricsEnabled, allowsBiometrics, AppLockService.biometricsAvailable {
                    Button {
                        authenticateWithBiometrics()
                    } label: {
                        Label("Usar \(AppLockService.biometricTypeName)", systemImage: biometricIconName)
                            .font(.headline)
                            .foregroundStyle(AppPalette.surface)
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .background(AppPalette.background, in: RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                    .disabled(isAuthenticating)
                }

                Spacer()
            }
            .padding(24)
        }
        .preferredColorScheme(.light)
        .task {
            if mode == .unlock, biometricsEnabled, allowsBiometrics {
                authenticateWithBiometrics()
            }
        }
    }

    private var pinDots: some View {
        HStack(spacing: 14) {
            ForEach(0..<pinLength, id: \.self) { index in
                Circle()
                    .fill(index < activePIN.count ? AppPalette.background : AppPalette.separator)
                    .frame(width: 16, height: 16)
                    .overlay {
                        Circle().stroke(AppPalette.background.opacity(0.18), lineWidth: 1)
                    }
            }
        }
        .padding(.vertical, 6)
    }

    private var keypad: some View {
        VStack(spacing: 12) {
            ForEach([["1", "2", "3"], ["4", "5", "6"], ["7", "8", "9"], ["", "0", "delete.left"]], id: \.self) { row in
                HStack(spacing: 12) {
                    ForEach(row, id: \.self) { item in
                        keypadButton(item)
                    }
                }
            }
        }
    }

    private func keypadButton(_ item: String) -> some View {
        Button {
            handleKey(item)
        } label: {
            Group {
                if item == "delete.left" {
                    Image(systemName: item)
                        .font(.title2.weight(.semibold))
                } else {
                    Text(item)
                        .font(.title2.bold())
                }
            }
            .foregroundStyle(item.isEmpty ? Color.clear : AppPalette.background)
            .frame(maxWidth: .infinity, minHeight: 58)
            .background(item.isEmpty ? Color.clear : AppPalette.surface, in: RoundedRectangle(cornerRadius: 18))
            .shadow(color: item.isEmpty ? Color.clear : AppPalette.background.opacity(0.06), radius: 10, y: 5)
        }
        .buttonStyle(.plain)
        .disabled(item.isEmpty)
    }

    private var biometricIconName: String {
        AppLockService.biometricTypeName == "Face ID" ? "faceid" : "touchid"
    }

    private func handleKey(_ item: String) {
        message = nil
        if item == "delete.left" {
            if isConfirmingPIN {
                confirmationPIN = String(confirmationPIN.dropLast())
            } else {
                pin = String(pin.dropLast())
            }
            return
        }

        guard item.count == 1, activePIN.count < pinLength else { return }

        if isConfirmingPIN {
            confirmationPIN.append(item)
            if confirmationPIN.count == pinLength {
                completeSetupIfPossible()
            }
        } else {
            pin.append(item)
            if pin.count == pinLength {
                switch mode {
                case .setup:
                    isConfirmingPIN = true
                    message = nil
                case .unlock:
                    unlockIfPossible()
                }
            }
        }
    }

    private func completeSetupIfPossible() {
        guard confirmationPIN == pin else {
            message = "Os códigos não coincidem. Tente novamente."
            pin = ""
            confirmationPIN = ""
            isConfirmingPIN = false
            return
        }

        guard AppLockService.save(pin: pin) else {
            message = "Não foi possível guardar o código. Tente novamente."
            pin = ""
            confirmationPIN = ""
            isConfirmingPIN = false
            return
        }

        onUnlocked()
    }

    private func unlockIfPossible() {
        if AppLockService.validate(pin: pin) {
            onUnlocked()
        } else {
            message = "Código incorreto."
            pin = ""
        }
    }

    private func authenticateWithBiometrics() {
        guard !isAuthenticating else { return }
        isAuthenticating = true
        Task {
            let success = await AppLockService.authenticateWithBiometrics(reason: "Desbloquear a SpendWise")
            await MainActor.run {
                isAuthenticating = false
                if success {
                    onUnlocked()
                }
            }
        }
    }
}

#Preview {
    AppLockView(mode: .setup) {}
}
