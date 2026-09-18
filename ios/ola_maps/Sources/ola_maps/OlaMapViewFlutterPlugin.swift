import Flutter
import UIKit

public class OlaMapViewFlutterPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let factory = OlaMapViewFactory(messenger: registrar.messenger(), registrar: registrar)
    registrar.register(factory, withId: "ola_map_view_flutter")
  }
}

final class OlaMapViewFactory: NSObject, FlutterPlatformViewFactory {
  private let messenger: FlutterBinaryMessenger
  private let registrar: FlutterPluginRegistrar

  init(messenger: FlutterBinaryMessenger, registrar: FlutterPluginRegistrar) {
    self.messenger = messenger
    self.registrar = registrar
    super.init()
  }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    FlutterStandardMessageCodec.sharedInstance()
  }

  func create(
    withFrame frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?
  ) -> FlutterPlatformView {
    OlaMapPlatformView(
      frame: frame,
      viewId: viewId,
      args: args as? [String: Any],
      messenger: messenger,
      registrar: registrar
    )
  }
}
