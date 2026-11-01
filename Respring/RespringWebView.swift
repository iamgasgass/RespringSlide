import SwiftUI
import WebKit

struct RespringScreen: View {
    var onClose: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()
            RespringWebView()
                .ignoresSafeArea()
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(.white.opacity(0.14), in: Circle())
            }
            .padding(.top, 12)
            .padding(.trailing, 16)
            .accessibilityLabel("Chiudi")
        }
    }
}

struct RespringWebView: UIViewRepresentable {
    func makeUIView(context: Context) -> WKWebView {
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences = preferences
        let web = WKWebView(frame: .zero, configuration: config)
        web.isOpaque = false
        web.backgroundColor = .black
        web.scrollView.backgroundColor = .black
        web.scrollView.isScrollEnabled = false
        if let url = Bundle.main.url(forResource: "respring", withExtension: "html"),
           let html = try? String(contentsOf: url, encoding: .utf8) {
            web.loadHTMLString(html, baseURL: url.deletingLastPathComponent())
        }
        return web
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
