//
//  AppPalette.swift
//  MoneyControl
//

import SwiftUI

enum AppPalette {
    /// #F26627
    static let primary = Color(red: 0.949, green: 0.400, blue: 0.153)
    /// #9BD7D1
    static let secondary = Color(red: 0.608, green: 0.843, blue: 0.820)
    /// #F9A26C
    static let accent = Color(red: 0.976, green: 0.635, blue: 0.424)
    /// #234B67
    static let background = Color(red: 0.137, green: 0.294, blue: 0.404)
    /// #FFFFFF
    static let surface = Color.white

    /// #F8F6F2
    static let appBackground = Color(red: 0.973, green: 0.965, blue: 0.949)
    /// #ECECEC
    static let separator = Color(red: 0.925, green: 0.925, blue: 0.925)
    /// #17344D
    static let darkBlue = Color(red: 0.090, green: 0.204, blue: 0.302)
    /// #3A6B86
    static let mediumBlue = Color(red: 0.227, green: 0.420, blue: 0.525)
    /// #7CC6BE
    static let mediumGreen = Color(red: 0.486, green: 0.776, blue: 0.745)
    /// #CDEDEA
    static let mintSurface = Color(red: 0.804, green: 0.929, blue: 0.918)
    /// #FFE4D4
    static let paleOrange = Color(red: 1.000, green: 0.894, blue: 0.831)
    /// #F58A5D
    static let warning = Color(red: 0.961, green: 0.541, blue: 0.365)
    static let purple = Color(red: 0.529, green: 0.345, blue: 0.710)
    /// #5E6A73
    static let bodyText = Color(red: 0.369, green: 0.416, blue: 0.451)
    /// #8E98A1
    static let secondaryText = Color(red: 0.557, green: 0.596, blue: 0.631)
    /// #3DB58B
    static let income = Color(red: 0.239, green: 0.710, blue: 0.545)
    /// #2DAF8A
    static let savings = Color(red: 0.176, green: 0.686, blue: 0.541)

    static let destructive = primary
    static let positive = income
    static let mutedText = bodyText
}
