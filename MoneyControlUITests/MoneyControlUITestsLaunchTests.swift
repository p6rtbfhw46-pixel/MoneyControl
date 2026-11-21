//
//  MoneyControlUITestsLaunchTests.swift
//  MoneyControlUITests
//
//  Created by Paulo Gaio on 29/07/2026.
//

import XCTest

final class MoneyControlUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "-hasSeenOnboarding", "YES",
            "-hasCompletedInitialSetup", "YES",
            "-appLockEnabled", "NO",
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US"
        ]
        app.launch()

        // Insert steps here to perform after app launch but before taking a screenshot,
        // such as logging into a test account or navigating somewhere in the app
        // XCUIAutomation Documentation
        // https://developer.apple.com/documentation/xcuiautomation

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
