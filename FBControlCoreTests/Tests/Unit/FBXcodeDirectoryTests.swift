/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBControlCore
import XCTest

final class FBXcodeDirectoryTests: XCTestCase {
  func testResolveUsesProcessDeveloperDirectoryEnvironment() throws {
    guard let directory = ProcessInfo.processInfo.environment["DEVELOPER_DIR"] else {
      throw XCTSkip("DEVELOPER_DIR is not set")
    }

    XCTAssertEqual(
      try FBXcodeDirectory.resolveDeveloperDirectory(),
      (directory as NSString).resolvingSymlinksInPath)
  }

  func testDeveloperDirectoryEnvironmentTakesPrecedence() throws {
    let directory = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: false)
    defer { try? FileManager.default.removeItem(at: directory) }

    let resolved = try FBXcodeDirectory.resolveDeveloperDirectory(
      environment: ["DEVELOPER_DIR": directory.path])

    XCTAssertEqual(resolved, directory.path)
  }

  func testResolveWithoutEnvironmentRetainsLegacyPrecedence() throws {
    let expected: String
    do {
      expected = try FBXcodeDirectory.symlinkedDeveloperDirectory()
    } catch {
      expected = try FBXcodeDirectory.xcodeSelectDeveloperDirectory()
    }
    let fallback = try FBXcodeDirectory.resolveDeveloperDirectory(environment: [:])

    XCTAssertEqual(fallback, expected)
  }

  func testXcodeSelect() throws {
    let directory = try FBXcodeDirectory.xcodeSelectDeveloperDirectory()
    assertDirectory(directory)
  }

  func testFromSymlink() throws {
    let directory = try FBXcodeDirectory.symlinkedDeveloperDirectory()
    assertDirectory(directory)
  }

  func assertDirectory(_ directory: String) {
    var isDirectory: ObjCBool = false
    let exists = FileManager.default.fileExists(atPath: directory, isDirectory: &isDirectory)
    XCTAssertTrue(exists)
    XCTAssertTrue(isDirectory.boolValue)

    // `Platforms` is the stable marker of a Developer directory across Xcode versions.
    // Xcode 27 moved `Applications` out of Contents/Developer (to Contents/Applications,
    // where the renamed DeviceHub.app now lives), so it is no longer a reliable marker.
    let expectedContents = NSSet(array: ["Platforms"])
    let actualContents = try? FileManager.default.contentsOfDirectory(atPath: directory)
    let intersection = NSMutableSet(array: actualContents ?? [])
    intersection.intersect(expectedContents as! Set<AnyHashable>)

    XCTAssertEqual(intersection.copy() as! NSSet, expectedContents)
  }
}
