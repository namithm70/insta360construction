import Flutter
import UIKit

final class Insta360PreviewView: NSObject, FlutterPlatformView {
  private let container: UIView
  private let cameraController: Insta360CameraController

  init(frame: CGRect, viewId: Int64, args: Any?, cameraController: Insta360CameraController) {
    self.container = UIView(frame: frame)
    self.cameraController = cameraController
    super.init()
    container.backgroundColor = UIColor.black
    cameraController.setPreviewContainer(container)
  }

  func view() -> UIView {
    return container
  }

  deinit {
    cameraController.clearPreviewContainer(container)
  }
}
