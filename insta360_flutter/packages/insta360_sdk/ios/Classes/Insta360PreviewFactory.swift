import Flutter
import UIKit

final class Insta360PreviewFactory: NSObject, FlutterPlatformViewFactory {
  private let cameraController: Insta360CameraController

  init(messenger _: FlutterBinaryMessenger, cameraController: Insta360CameraController) {
    self.cameraController = cameraController
    super.init()
  }

  func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
    return Insta360PreviewView(frame: frame, viewId: viewId, args: args, cameraController: cameraController)
  }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    return FlutterStandardMessageCodec.sharedInstance()
  }
}
