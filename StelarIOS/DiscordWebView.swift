import SwiftUI
import UIKit
import WebKit

struct DiscordWebScreen: View {
    var body: some View {
        DiscordWebView()
            .background(Color(uiColor: .systemBackground))
            .ignoresSafeArea()
    }
}

private struct DiscordWebView: UIViewRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> WKWebView {
        let contentController = WKUserContentController()
        do {
            contentController.addUserScript(try StelarBootstrap.makeUserScript())
        } catch {
            NSLog("[Stelar iOS] Could not prepare the bundled extension: %@", String(describing: error))
        }

        let configuration = WKWebViewConfiguration()
        configuration.userContentController = contentController
        configuration.websiteDataStore = .default()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        configuration.defaultWebpagePreferences.preferredContentMode = .mobile
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = true

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.isOpaque = false
        webView.backgroundColor = .systemBackground
        webView.scrollView.backgroundColor = .systemBackground
        context.coordinator.webView = webView

        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        }

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(context.coordinator, action: #selector(Coordinator.handleRefreshControl(_:)), for: .valueChanged)
        webView.scrollView.refreshControl = refreshControl

        if let url = URL(string: "https://discord.com/channels/@me") {
            webView.load(URLRequest(url: url))
        }
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}

    @MainActor
    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        weak var webView: WKWebView?

        @objc func handleRefreshControl(_ sender: UIRefreshControl) {
            webView?.reload()
            sender.endRefreshing()
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.cancel)
                return
            }

            let scheme = url.scheme?.lowercased() ?? ""
            let host = url.host?.lowercased() ?? ""

            if ["mailto", "tel"].contains(scheme) {
                UIApplication.shared.open(url)
                decisionHandler(.cancel)
                return
            }

            if navigationAction.navigationType == .linkActivated {
                let isDiscordHost = host == "discord.com" || host.hasSuffix(".discord.com") ||
                                    host == "discord.gg" || host.hasSuffix(".discord.gg") ||
                                    host == "discordapp.com" || host.hasSuffix(".discordapp.com")
                if !isDiscordHost && (scheme == "http" || scheme == "https") {
                    UIApplication.shared.open(url)
                    decisionHandler(.cancel)
                    return
                }
            }

            if scheme == "https" || url.absoluteString == "about:blank" {
                decisionHandler(.allow)
                return
            }

            decisionHandler(.cancel)
        }

        func webView(
            _ webView: WKWebView,
            createWebViewWith configuration: WKWebViewConfiguration,
            for navigationAction: WKNavigationAction,
            windowFeatures: WKWindowFeatures
        ) -> WKWebView? {
            guard let url = navigationAction.request.url else { return nil }
            let host = url.host?.lowercased() ?? ""
            let scheme = url.scheme?.lowercased() ?? ""

            if scheme == "https",
               (host == "discord.com" || host.hasSuffix(".discord.com") ||
                host == "discordapp.com" || host.hasSuffix(".discordapp.com")) {
                webView.load(navigationAction.request)
            } else if ["https", "http", "mailto", "tel"].contains(scheme) {
                UIApplication.shared.open(url)
            }
            return nil
        }

        func webView(
            _ webView: WKWebView,
            requestMediaCapturePermissionFor origin: WKSecurityOrigin,
            initiatedByFrame frame: WKFrameInfo,
            type: WKMediaCaptureType,
            decisionHandler: @escaping (WKPermissionDecision) -> Void
        ) {
            let host = origin.host.lowercased()
            let isSecureDiscordOrigin = origin.`protocol`.lowercased() == "https" &&
                (host == "discord.com" || host.hasSuffix(".discord.com"))
            decisionHandler(isSecureDiscordOrigin ? .prompt : .deny)
        }
    }
}
