extension RichTextController : WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let cssString = "@media (prefers-color-scheme: dark) {body {color: white;}a:link {color: #0096e2;}a:visited {color: #9d57df;}}"
        let jsString = "var style = document.createElement('style'); style.innerHTML = '\(cssString)'; document.head.appendChild(style);"
        webView.evaluateJavaScript(jsString, completionHandler: nil)
    }
}
