//
//  AppPalette.swift
//  MoneyControl
//

import SwiftUI

enum AppAppearanceMode: String, CaseIterable, Identifiable {
    static let storageKey = "selectedAppearanceMode"

    case system
    case light
    case dark

    var id: String { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }

    var title: String {
        switch (self, AppStrings.currentLanguage) {
        case (.system, .portuguese): "Automático"
        case (.system, .english): "Automatic"
        case (.light, .portuguese): "Claro"
        case (.light, .english): "Light"
        case (.dark, .portuguese): "Escuro"
        case (.dark, .english): "Dark"
        }
    }
}

enum AppColorPalette: String, CaseIterable, Identifiable {
    static let storageKey = "selectedColorPalette"

    case original
    case ocean
    case forest
    case sunset
    case lavender
    case impact

    var id: String { rawValue }

    static var current: AppColorPalette {
        guard
            let storedValue = UserDefaults.standard.string(forKey: storageKey),
            let palette = AppColorPalette(rawValue: storedValue)
        else {
            return .original
        }
        return palette
    }

    var title: String {
        switch self {
        case .original:
            AppStrings.text(.paletteOriginal)
        case .ocean:
            AppStrings.text(.paletteOcean)
        case .forest:
            AppStrings.text(.paletteForest)
        case .sunset:
            AppStrings.text(.paletteSunset)
        case .lavender:
            AppStrings.text(.paletteLavender)
        case .impact:
            AppStrings.text(.paletteImpact)
        }
    }

    var previewColors: [Color] {
        let colors = AppPalette.colors(for: self)
        return [colors.primary, colors.secondary, colors.background, colors.savings, colors.accent]
    }
}

enum AppPalette {
    struct Colors {
        let primary: Color
        let secondary: Color
        let accent: Color
        let background: Color
        let surface: Color
        let appBackground: Color
        let separator: Color
        let darkBlue: Color
        let mediumBlue: Color
        let mediumGreen: Color
        let mintSurface: Color
        let paleOrange: Color
        let warning: Color
        let purple: Color
        let bodyText: Color
        let secondaryText: Color
        let income: Color
        let savings: Color
    }

    static var primary: Color { current.primary }
    static var secondary: Color { current.secondary }
    static var accent: Color { current.accent }
    static var background: Color { adaptive(light: current.background, dark: .label) }
    static var surface: Color { adaptive(light: current.surface, dark: .secondarySystemBackground) }
    static var appBackground: Color { adaptive(light: current.appBackground, dark: .systemBackground) }
    static var separator: Color { adaptive(light: current.separator, dark: .separator) }
    static var darkBlue: Color { current.darkBlue }
    static var mediumBlue: Color { current.mediumBlue }
    static var mediumGreen: Color { current.mediumGreen }
    static var mintSurface: Color { current.mintSurface }
    static var paleOrange: Color { current.paleOrange }
    static var warning: Color { current.warning }
    static var purple: Color { current.purple }
    static var bodyText: Color { adaptive(light: current.bodyText, dark: .secondaryLabel) }
    static var secondaryText: Color { adaptive(light: current.secondaryText, dark: .tertiaryLabel) }
    static var income: Color { current.income }
    static var savings: Color { current.savings }

    static var destructive: Color { primary }
    static var positive: Color { income }
    static var mutedText: Color { bodyText }

    private static func adaptive(light: Color, dark: UIColor) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : UIColor(light)
        })
    }

    private static var current: Colors {
        colors(for: AppColorPalette.current)
    }

    static func colors(for palette: AppColorPalette) -> Colors {
        switch palette {
        case .original:
            Colors(
                primary: Color(red: 0.949, green: 0.400, blue: 0.153),
                secondary: Color(red: 0.608, green: 0.843, blue: 0.820),
                accent: Color(red: 0.976, green: 0.635, blue: 0.424),
                background: Color(red: 0.137, green: 0.294, blue: 0.404),
                surface: .white,
                appBackground: Color(red: 0.973, green: 0.965, blue: 0.949),
                separator: Color(red: 0.925, green: 0.925, blue: 0.925),
                darkBlue: Color(red: 0.090, green: 0.204, blue: 0.302),
                mediumBlue: Color(red: 0.227, green: 0.420, blue: 0.525),
                mediumGreen: Color(red: 0.486, green: 0.776, blue: 0.745),
                mintSurface: Color(red: 0.804, green: 0.929, blue: 0.918),
                paleOrange: Color(red: 1.000, green: 0.894, blue: 0.831),
                warning: Color(red: 0.961, green: 0.541, blue: 0.365),
                purple: Color(red: 0.529, green: 0.345, blue: 0.710),
                bodyText: Color(red: 0.369, green: 0.416, blue: 0.451),
                secondaryText: Color(red: 0.557, green: 0.596, blue: 0.631),
                income: Color(red: 0.239, green: 0.710, blue: 0.545),
                savings: Color(red: 0.176, green: 0.686, blue: 0.541)
            )
        case .ocean:
            Colors(
                primary: Color(red: 0.157, green: 0.471, blue: 0.647),
                secondary: Color(red: 0.655, green: 0.855, blue: 0.863),
                accent: Color(red: 0.949, green: 0.651, blue: 0.353),
                background: Color(red: 0.090, green: 0.231, blue: 0.341),
                surface: .white,
                appBackground: Color(red: 0.957, green: 0.976, blue: 0.984),
                separator: Color(red: 0.867, green: 0.910, blue: 0.929),
                darkBlue: Color(red: 0.063, green: 0.173, blue: 0.251),
                mediumBlue: Color(red: 0.239, green: 0.471, blue: 0.592),
                mediumGreen: Color(red: 0.408, green: 0.710, blue: 0.675),
                mintSurface: Color(red: 0.843, green: 0.937, blue: 0.925),
                paleOrange: Color(red: 1.000, green: 0.910, blue: 0.816),
                warning: Color(red: 0.914, green: 0.471, blue: 0.314),
                purple: Color(red: 0.424, green: 0.353, blue: 0.655),
                bodyText: Color(red: 0.314, green: 0.404, blue: 0.451),
                secondaryText: Color(red: 0.478, green: 0.557, blue: 0.596),
                income: Color(red: 0.184, green: 0.616, blue: 0.471),
                savings: Color(red: 0.149, green: 0.561, blue: 0.459)
            )
        case .forest:
            Colors(
                primary: Color(red: 0.776, green: 0.416, blue: 0.208),
                secondary: Color(red: 0.686, green: 0.784, blue: 0.643),
                accent: Color(red: 0.890, green: 0.639, blue: 0.365),
                background: Color(red: 0.161, green: 0.286, blue: 0.212),
                surface: .white,
                appBackground: Color(red: 0.969, green: 0.961, blue: 0.929),
                separator: Color(red: 0.886, green: 0.890, blue: 0.835),
                darkBlue: Color(red: 0.102, green: 0.204, blue: 0.145),
                mediumBlue: Color(red: 0.286, green: 0.443, blue: 0.337),
                mediumGreen: Color(red: 0.475, green: 0.659, blue: 0.451),
                mintSurface: Color(red: 0.847, green: 0.910, blue: 0.804),
                paleOrange: Color(red: 0.984, green: 0.886, blue: 0.753),
                warning: Color(red: 0.851, green: 0.400, blue: 0.259),
                purple: Color(red: 0.455, green: 0.361, blue: 0.565),
                bodyText: Color(red: 0.337, green: 0.400, blue: 0.349),
                secondaryText: Color(red: 0.514, green: 0.565, blue: 0.522),
                income: Color(red: 0.255, green: 0.580, blue: 0.365),
                savings: Color(red: 0.220, green: 0.522, blue: 0.329)
            )
        case .sunset:
            Colors(
                primary: Color(red: 0.902, green: 0.310, blue: 0.322),
                secondary: Color(red: 0.953, green: 0.690, blue: 0.549),
                accent: Color(red: 0.984, green: 0.557, blue: 0.278),
                background: Color(red: 0.353, green: 0.180, blue: 0.259),
                surface: .white,
                appBackground: Color(red: 0.996, green: 0.953, blue: 0.925),
                separator: Color(red: 0.941, green: 0.851, blue: 0.820),
                darkBlue: Color(red: 0.251, green: 0.118, blue: 0.184),
                mediumBlue: Color(red: 0.596, green: 0.310, blue: 0.384),
                mediumGreen: Color(red: 0.573, green: 0.694, blue: 0.514),
                mintSurface: Color(red: 0.878, green: 0.929, blue: 0.820),
                paleOrange: Color(red: 1.000, green: 0.843, blue: 0.690),
                warning: Color(red: 0.902, green: 0.271, blue: 0.235),
                purple: Color(red: 0.529, green: 0.302, blue: 0.596),
                bodyText: Color(red: 0.427, green: 0.310, blue: 0.337),
                secondaryText: Color(red: 0.620, green: 0.490, blue: 0.510),
                income: Color(red: 0.282, green: 0.627, blue: 0.412),
                savings: Color(red: 0.251, green: 0.565, blue: 0.400)
            )
        case .lavender:
            Colors(
                primary: Color(red: 0.467, green: 0.333, blue: 0.698),
                secondary: Color(red: 0.780, green: 0.714, blue: 0.902),
                accent: Color(red: 0.788, green: 0.482, blue: 0.749),
                background: Color(red: 0.224, green: 0.184, blue: 0.337),
                surface: .white,
                appBackground: Color(red: 0.969, green: 0.953, blue: 0.992),
                separator: Color(red: 0.886, green: 0.851, blue: 0.929),
                darkBlue: Color(red: 0.153, green: 0.125, blue: 0.243),
                mediumBlue: Color(red: 0.420, green: 0.365, blue: 0.596),
                mediumGreen: Color(red: 0.455, green: 0.690, blue: 0.631),
                mintSurface: Color(red: 0.843, green: 0.929, blue: 0.902),
                paleOrange: Color(red: 0.984, green: 0.878, blue: 0.835),
                warning: Color(red: 0.878, green: 0.431, blue: 0.396),
                purple: Color(red: 0.596, green: 0.365, blue: 0.769),
                bodyText: Color(red: 0.376, green: 0.337, blue: 0.455),
                secondaryText: Color(red: 0.565, green: 0.518, blue: 0.635),
                income: Color(red: 0.255, green: 0.635, blue: 0.490),
                savings: Color(red: 0.235, green: 0.573, blue: 0.467)
            )
        case .impact:
            Colors(
                primary: Color(red: 1.000, green: 0.176, blue: 0.216),
                secondary: Color(red: 0.000, green: 0.820, blue: 0.922),
                accent: Color(red: 1.000, green: 0.745, blue: 0.000),
                background: Color(red: 0.055, green: 0.067, blue: 0.125),
                surface: .white,
                appBackground: Color(red: 0.949, green: 0.957, blue: 0.976),
                separator: Color(red: 0.820, green: 0.835, blue: 0.875),
                darkBlue: Color(red: 0.027, green: 0.035, blue: 0.078),
                mediumBlue: Color(red: 0.000, green: 0.478, blue: 0.745),
                mediumGreen: Color(red: 0.000, green: 0.745, blue: 0.573),
                mintSurface: Color(red: 0.745, green: 1.000, blue: 0.910),
                paleOrange: Color(red: 1.000, green: 0.859, blue: 0.596),
                warning: Color(red: 1.000, green: 0.176, blue: 0.216),
                purple: Color(red: 0.620, green: 0.247, blue: 0.922),
                bodyText: Color(red: 0.208, green: 0.227, blue: 0.310),
                secondaryText: Color(red: 0.424, green: 0.451, blue: 0.557),
                income: Color(red: 0.000, green: 0.690, blue: 0.376),
                savings: Color(red: 0.000, green: 0.620, blue: 0.471)
            )
        }
    }
}
