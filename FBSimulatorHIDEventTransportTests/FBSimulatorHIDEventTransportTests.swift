/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSimulatorControl
import XCTest

final class FBSimulatorHIDEventTransportTests: XCTestCase {

  func testApplePayBecomesTwoSideButtonPressesOnDTUHID() {
    XCTAssertEqual(
      FBSimulatorHIDEvent.shortButtonPress(.applePay).event(for: .dtuhid),
      .composite([
        .button(direction: .down, button: .sideButton),
        .button(direction: .up, button: .sideButton),
        .delay(0.15),
        .button(direction: .down, button: .sideButton),
        .button(direction: .up, button: .sideButton),
      ]))
  }

  func testApplePaySplitsCommandDurationAcrossSideButtonPresses() {
    let event = FBSimulatorHIDEvent.composite([
      .button(direction: .down, button: .applePay),
      .delay(2),
      .button(direction: .up, button: .applePay),
    ])

    let transportEvent = event.event(for: .dtuhid)
    XCTAssertEqual(
      transportEvent,
      .composite([
        .button(direction: .down, button: .sideButton),
        .delay(1),
        .button(direction: .up, button: .sideButton),
        .delay(0.15),
        .button(direction: .down, button: .sideButton),
        .delay(1),
        .button(direction: .up, button: .sideButton),
      ]))
    XCTAssertEqual(totalDelay(in: transportEvent), 2.15, accuracy: 1e-9)
  }

  func testIndigoPreservesApplePayEvent() {
    let event = FBSimulatorHIDEvent.shortButtonPress(.applePay)
    XCTAssertEqual(event.event(for: .indigo), event)
  }

  func testUnmatchedApplePayPrimitiveRemainsUnsupported() {
    let event = FBSimulatorHIDEvent.button(direction: .down, button: .applePay)
    XCTAssertEqual(event.event(for: .dtuhid), event)
  }

  func testApplePayRewritePreservesNestedDurationBudget() {
    let event = FBSimulatorHIDEvent.composite([
      .button(direction: .down, button: .applePay),
      .composite([.delay(1), .delay(1)]),
      .button(direction: .up, button: .applePay),
    ])

    let transportEvent = event.event(for: .dtuhid)
    XCTAssertEqual(totalDelay(in: transportEvent), 2.15, accuracy: 1e-9)
  }

  func testApplePayRewriteDoesNotDuplicateMixedEvents() {
    let event = FBSimulatorHIDEvent.composite([
      .button(direction: .down, button: .applePay),
      .touch(direction: .down, x: 10, y: 20),
      .button(direction: .up, button: .applePay),
    ])

    XCTAssertEqual(event.event(for: .dtuhid), event)
  }

  func testDTUHIDPacesKeyboardCompositeBeforeFlush() {
    XCTAssertEqual(
      FBSimulatorHIDEvent.shortKeyPress(4).event(for: .dtuhid),
      .composite([
        .composite([
          .keyboard(direction: .down, keyCode: 4),
          .delay(0.01),
          .keyboard(direction: .up, keyCode: 4),
          .delay(0.01),
        ]),
        .delay(0.05),
      ]))
  }

  func testDTUHIDPacesDirectKeyboardEventBeforeFlush() {
    XCTAssertEqual(
      FBSimulatorHIDEvent.keyboard(direction: .down, keyCode: 4).event(for: .dtuhid),
      .composite([
        .composite([
          .keyboard(direction: .down, keyCode: 4),
          .delay(0.01),
        ]),
        .delay(0.05),
      ]))
  }

  func testDTUHIDPreservesNonKeyboardEvent() {
    let event = FBSimulatorHIDEvent.tapAt(x: 10, y: 20)
    XCTAssertEqual(event.event(for: .dtuhid), event)
  }

  private func totalDelay(in event: FBSimulatorHIDEvent) -> TimeInterval {
    switch event {
    case let .delay(duration):
      return duration
    case let .composite(events):
      return events.reduce(0) { $0 + totalDelay(in: $1) }
    default:
      return 0
    }
  }
}
