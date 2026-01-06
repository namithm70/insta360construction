import Flutter
import UIKit

final class Insta360PlaybackFactory: NSObject, FlutterPlatformViewFactory {
  private let playbackController: Insta360PlaybackController

  init(messenger _: FlutterBinaryMessenger, playbackController: Insta360PlaybackController) {
    self.playbackController = playbackController
    super.init()
  }

  func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
    return Insta360PlaybackView(frame: frame, viewId: viewId, args: args, playbackController: playbackController)
  }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    return FlutterStandardMessageCodec.sharedInstance()
  }
}
