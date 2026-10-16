import Foundation
import WebKit

enum StelarBootstrap {
    private static let unguardedFactory = "return t===\"toString\"?r.bind(n):r"
    private static let guardedFactory = "return t===\"toString\"&&typeof r===\"function\"?r.bind(n):r"
    private static let bundleEntry = "return bo(Wut);})();"
    private static let mobileBundleEntry = "var __stelarApi=bo(Wut);window.__stelarVencordPluginCount=__stelarApi&&__stelarApi.Plugins&&__stelarApi.Plugins.plugins?Object.keys(__stelarApi.Plugins.plugins).length:-1;return __stelarApi;})();"

    static func makeUserScript() throws -> WKUserScript {
        let extensionSource = try loadResource("extension", extension: "js")
        let baseStyles = try loadResource("extension", extension: "css")
        let mobileStyles = try loadResource("extension-mobile", extension: "css")
        let patchedExtension = try patchBundle(extensionSource)
        let cssLiteral = try javascriptString(baseStyles + "\n" + mobileStyles)
        let quickCssMarkup = try javascriptString(
            "<section class=\"stelar-mobile-quickcss-dialog\" role=\"dialog\" aria-modal=\"true\" aria-label=\"QuickCSS\"><header class=\"stelar-mobile-quickcss-header\"><span>QuickCSS</span></header><textarea class=\"stelar-mobile-quickcss-input\" aria-label=\"Código QuickCSS\" spellcheck=\"false\"></textarea><footer class=\"stelar-mobile-quickcss-actions\"><button class=\"stelar-mobile-quickcss-cancel\" type=\"button\">Cancelar</button><button class=\"stelar-mobile-quickcss-save\" type=\"button\">Guardar</button></footer></section>"
        )

        let prefix = """
        (() => {
            if (window.top !== window || location.hostname !== "discord.com" || window.__stelarVencordInjected) return;
            window.__stelarVencordInjected = true;
            window.addEventListener("error", event => {
                const message = String(event.message || "");
                if (message.includes("reading 'bind'")) {
                    const stack = event.error && event.error.stack ? event.error.stack : message;
                    console.error("[Stelar iOS] runtime error stack: " + stack);
                }
            }, true);
            const mediaDevices = navigator.mediaDevices;
            if (mediaDevices && typeof mediaDevices.getDisplayMedia !== "function") {
                Object.defineProperty(mediaDevices, "getDisplayMedia", {
                    configurable: true,
                    value: () => Promise.reject(Object.assign(
                        new Error("Screen capture is unavailable in this iOS WebView"),
                        { name: "NotSupportedError" }
                    ))
                });
            }
            const extensionCss = \(cssLiteral);
            const cssUrl = location.origin + "/__stelar_mobile__/extension.css";
            const originalFetch = window.fetch.bind(window);
            window.fetch = (resource, options) => {
                const requestedUrl = typeof resource === "string"
                    ? new URL(resource, location.href).href
                    : resource && resource.url;
                if (requestedUrl === cssUrl) {
                    return Promise.resolve(new Response(extensionCss, {
                        status: 200,
                        headers: { "Content-Type": "text/css; charset=utf-8" }
                    }));
                }
                return originalFetch(resource, options);
            };
        })();
        """

        let suffix = """
        (() => {
            const pluginCount = window.__stelarVencordPluginCount;
            const countLabel = typeof pluginCount === "number" && pluginCount >= 0 ? pluginCount : "pending";
            console.info("[Stelar iOS] extension bundle loaded; web plugin entries: " + countLabel);
            const quickCss = window.VencordNative && window.VencordNative.quickCss;
            if (quickCss && typeof quickCss.get === "function" && typeof quickCss.set === "function") {
                quickCss.openEditor = async () => {
                    const editorId = "stelar-mobile-quickcss-editor";
                    if (document.getElementById(editorId)) return;
                    let css;
                    try {
                        css = await quickCss.get();
                    } catch (error) {
                        console.error("[Stelar iOS] could not read QuickCSS", error);
                        return;
                    }
                    const backdrop = document.createElement("div");
                    backdrop.id = editorId;
                    backdrop.className = "stelar-mobile-quickcss-backdrop";
                    backdrop.innerHTML = \(quickCssMarkup);
                    const input = backdrop.querySelector("textarea");
                    const cancel = backdrop.querySelector(".stelar-mobile-quickcss-cancel");
                    const save = backdrop.querySelector(".stelar-mobile-quickcss-save");
                    let closed = false;
                    input.value = css || "";
                    const close = () => {
                        if (closed) return;
                        closed = true;
                        backdrop.remove();
                        window.removeEventListener("keydown", onKeyDown, true);
                    };
                    const onKeyDown = event => {
                        if (event.key !== "Escape") return;
                        event.preventDefault();
                        event.stopPropagation();
                        close();
                    };
                    cancel.addEventListener("click", close);
                    backdrop.addEventListener("click", event => {
                        if (event.target === backdrop) close();
                    });
                    save.addEventListener("click", async () => {
                        save.disabled = true;
                        try {
                            await quickCss.set(input.value);
                            close();
                        } catch (error) {
                            console.error("[Stelar iOS] could not save QuickCSS", error);
                            save.disabled = false;
                        }
                    });
                    window.addEventListener("keydown", onKeyDown, true);
                    document.body.appendChild(backdrop);
                    input.focus();
                };
            }
            window.postMessage({
                type: "vencord:meta",
                meta: {
                    EXTENSION_BASE_URL: location.origin + "/__stelar_mobile__/",
                    EXTENSION_VERSION: "mobile",
                    RENDERER_CSS_URL: location.origin + "/__stelar_mobile__/extension.css"
                }
            }, location.origin);
        })();
        """

        let source = prefix + "\n" + patchedExtension + "\n" + suffix
        return WKUserScript(source: source, injectionTime: .atDocumentStart, forMainFrameOnly: true)
    }

    private static func loadResource(_ name: String, extension fileExtension: String) throws -> String {
        let url = Bundle.main.url(forResource: name, withExtension: fileExtension)
            ?? Bundle.main.url(forResource: name, withExtension: fileExtension, subdirectory: "Stelar")
            ?? Bundle.main.url(forResource: name, withExtension: fileExtension, subdirectory: "Resources/Stelar")
        guard let validUrl = url else {
            throw BootstrapError.missingResource("\(name).\(fileExtension)")
        }
        return try String(contentsOf: validUrl, encoding: .utf8)
    }

    private static func javascriptString(_ value: String) throws -> String {
        let data = try JSONSerialization.data(withJSONObject: value, options: [.fragmentsAllowed])
        return String(decoding: data, as: UTF8.self)
    }

    private static func patchBundle(_ source: String) throws -> String {
        var patched = source
        if patched.contains(unguardedFactory) {
            guard occurrenceCount(of: unguardedFactory, in: patched) == 1 else {
                throw BootstrapError.unexpectedBundle("Webpack factory guard was not unique")
            }
            patched = patched.replacingOccurrences(of: unguardedFactory, with: guardedFactory)
        } else if !patched.contains(guardedFactory) {
            throw BootstrapError.unexpectedBundle("Webpack factory guard pattern was not found")
        }

        if patched.contains(bundleEntry) {
            guard occurrenceCount(of: bundleEntry, in: patched) == 1 else {
                throw BootstrapError.unexpectedBundle("Bundle entry was not unique")
            }
            patched = patched.replacingOccurrences(of: bundleEntry, with: mobileBundleEntry)
        } else if !patched.contains("window.__stelarVencordPluginCount=") {
            throw BootstrapError.unexpectedBundle("Bundle plugin count entry was not found")
        }
        return patched
    }

    private static func occurrenceCount(of value: String, in source: String) -> Int {
        source.components(separatedBy: value).count - 1
    }

    private enum BootstrapError: LocalizedError {
        case missingResource(String)
        case unexpectedBundle(String)

        var errorDescription: String? {
            switch self {
            case .missingResource(let name): return "Missing bundled resource: \(name)"
            case .unexpectedBundle(let reason): return "Could not patch the mobile extension bundle: \(reason)"
            }
        }
    }
}
