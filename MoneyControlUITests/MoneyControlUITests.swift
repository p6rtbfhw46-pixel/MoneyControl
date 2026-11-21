//
//  MoneyControlUITests.swift
//  MoneyControlUITests
//
//  Created by Paulo Gaio on 29/07/2026.
//

import XCTest

final class MoneyControlUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false

        app = XCUIApplication()
        app.launchArguments = [
            "-hasSeenOnboarding", "YES",
            "-hasCompletedInitialSetup", "YES",
            "-appLockEnabled", "NO",
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US"
        ]
    }

    override func tearDownWithError() throws {
        app.terminate()
        app = nil
    }

    @MainActor
    func testLaunchesMainInterface() throws {
        app.launch()

        XCTAssertTrue(
            element(identifier: "app.main").waitForExistence(timeout: 10),
            "The main interface should appear after launch."
        )
        XCTAssertEqual(app.state, .runningForeground)
    }

    @MainActor
    func testOpensAccountsFromManagement() throws {
        app.launch()
        XCTAssertTrue(element(identifier: "app.main").waitForExistence(timeout: 10))
        dismissLaunchNoticeIfNeeded()

        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))
        XCTAssertGreaterThanOrEqual(tabBar.buttons.count, 3)

        let managementTab = tabBar.buttons.element(boundBy: 2)
        XCTAssertTrue(managementTab.exists)
        managementTab.tap()

        let accountsCard = app.buttons
            .containing(.staticText, identifier: "Accounts")
            .firstMatch
        if !accountsCard.waitForExistence(timeout: 2) {
            app.swipeUp()
        }
        XCTAssertTrue(accountsCard.waitForExistence(timeout: 5))
        accountsCard.tap()

        XCTAssertTrue(
            app.navigationBars["Accounts"].waitForExistence(timeout: 5),
            "Selecting Accounts from Management should open the accounts screen."
        )
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            app.launch()
            app.terminate()
        }
    }

    private func dismissLaunchNoticeIfNeeded() {
        let overdueNotice = app.navigationBars["Expenses to pay"]
        guard overdueNotice.waitForExistence(timeout: 2) else { return }

        app.buttons["OK"].tap()
        XCTAssertFalse(overdueNotice.waitForExistence(timeout: 2))
    }

    private func element(identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier].firstMatch
    }
}
