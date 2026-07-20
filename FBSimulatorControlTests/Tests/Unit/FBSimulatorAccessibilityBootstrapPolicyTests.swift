import Foundation
@testable import FBSimulatorControl
import XCTest

final class FBSimulatorAccessibilityBootstrapPolicyTests: XCTestCase {
  func testRuntimeBeforeIOS27DoesNotRequireBootstrap() {
    let version = OperatingSystemVersion(majorVersion: 26, minorVersion: 5, patchVersion: 0)

    XCTAssertFalse(FBSimulatorAccessibilityCommands.requiresAccessibilityBootstrap(for: version))
  }

  func testIOS27RuntimeRequiresBootstrap() {
    let version = OperatingSystemVersion(majorVersion: 27, minorVersion: 0, patchVersion: 0)

    XCTAssertTrue(FBSimulatorAccessibilityCommands.requiresAccessibilityBootstrap(for: version))
  }

  func testFutureRuntimeRequiresBootstrap() {
    let version = OperatingSystemVersion(majorVersion: 28, minorVersion: 0, patchVersion: 0)

    XCTAssertTrue(FBSimulatorAccessibilityCommands.requiresAccessibilityBootstrap(for: version))
  }
}
