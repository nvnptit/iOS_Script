extension RichTextController : WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let cssString = "@media (prefers-color-scheme: dark) {body {color: white;}a:link {color: #0096e2;}a:visited {color: #9d57df;}}"
        let jsString = "var style = document.createElement('style'); style.innerHTML = '\(cssString)'; document.head.appendChild(style);"
        webView.evaluateJavaScript(jsString, completionHandler: nil)
    }
}
https://stackoverflow.com/questions/69830561/wkwebview-dark-and-light-mode-with-dynamic-url-in-swift-5
