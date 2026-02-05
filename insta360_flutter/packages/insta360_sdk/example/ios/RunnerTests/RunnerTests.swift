import Flutter
import UIKit
import XCTest


@testable import insta360_sdk

// This demonstrates a simple unit test of the Swift portion of this plugin's implementation.
//
// See https://developer.apple.com/documentation/xctest for more information about using XCTest.

class RunnerTests: XCTestCase {

  func testGetCameraState() {
    let plugin = Insta360SdkPlugin()

    let call = FlutterMethodCall(methodName: "getCameraState", arguments: nil)

    let resultExpectation = expectation(description: "result block must be called.")
    plugin.handle(call) { result in
      let map = result as? [String: Int]
      XCTAssertNotNil(map)
      XCTAssertNotNil(map?["socket"])
      XCTAssertNotNil(map?["usb"])
      XCTAssertNotNil(map?["external"])
      resultExpectation.fulfill()
    }
    waitForExpectations(timeout: 1)
  }

}
