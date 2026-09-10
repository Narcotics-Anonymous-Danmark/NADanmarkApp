import Flutter
import UIKit
import WebKit

public class LegacyStorePlugin: NSObject, FlutterPlugin {
  static let channelName = "dk.nadanmark.app/legacy_store"

  private let registrar: FlutterPluginRegistrar
  private var reader: LegacyStoreReader?

  init(registrar: FlutterPluginRegistrar) {
    self.registrar = registrar
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: registrar.messenger())
    let instance = LegacyStorePlugin(registrar: registrar)
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "readAll":
      let reader = LegacyStoreReader(registrar: registrar) { [weak self] in self?.reader = nil }
      self.reader = reader
      reader.start(result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}

final class LegacyStoreReader: NSObject, WKScriptMessageHandler, WKURLSchemeHandler {
  static let scheme = "ionic"
  static let pageURL = URL(string: "ionic://localhost/na_migrate.html")!
  static let timeoutSeconds = 5.0

  private let registrar: FlutterPluginRegistrar
  private let onFinished: () -> Void
  private var webView: WKWebView?
  private var result: FlutterResult?

  init(registrar: FlutterPluginRegistrar, onFinished: @escaping () -> Void) {
    self.registrar = registrar
    self.onFinished = onFinished
  }

  func start(result: @escaping FlutterResult) {
    self.result = result
    let configuration = WKWebViewConfiguration()
    configuration.websiteDataStore = WKWebsiteDataStore.default()
    configuration.setURLSchemeHandler(self, forURLScheme: LegacyStoreReader.scheme)
    configuration.userContentController.add(self, name: "naMigrate")
    let view = WKWebView(frame: .zero, configuration: configuration)
    webView = view
    view.load(URLRequest(url: LegacyStoreReader.pageURL))
    DispatchQueue.main.asyncAfter(deadline: .now() + LegacyStoreReader.timeoutSeconds) { [weak self] in
      self?.finish { $0(FlutterError(code: "legacy_store", message: "timed out", details: nil)) }
    }
  }

  private func finish(_ deliver: (FlutterResult) -> Void) {
    guard let pending = result else { return }
    result = nil
    deliver(pending)
    webView?.configuration.userContentController.removeScriptMessageHandler(forName: "naMigrate")
    webView = nil
    onFinished()
  }

  func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
    guard let body = message.body as? [String: Any], let type = body["type"] as? String else {
      finish { $0(FlutterError(code: "legacy_store", message: "unexpected message", details: nil)) }
      return
    }
    let payload = body["payload"] as? String ?? ""
    switch type {
    case "done":
      finish { $0(payload) }
    case "absent":
      finish { $0(nil) }
    default:
      finish { $0(FlutterError(code: "legacy_store", message: payload, details: nil)) }
    }
  }

  func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
    guard let url = urlSchemeTask.request.url, url.host == "localhost", url.path == "/na_migrate.html" else {
      urlSchemeTask.didFailWithError(NSError(domain: "legacy_store", code: 404, userInfo: nil))
      return
    }
    let key = registrar.lookupKey(forAsset: "assets/na_migrate.html", fromPackage: "adapter_legacy_store")
    guard let path = Bundle.main.path(forResource: key, ofType: nil),
          let data = FileManager.default.contents(atPath: path) else {
      urlSchemeTask.didFailWithError(NSError(domain: "legacy_store", code: 500, userInfo: nil))
      return
    }
    let response = URLResponse(url: url, mimeType: "text/html", expectedContentLength: data.count, textEncodingName: "utf-8")
    urlSchemeTask.didReceive(response)
    urlSchemeTask.didReceive(data)
    urlSchemeTask.didFinish()
  }

  func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {}
}
