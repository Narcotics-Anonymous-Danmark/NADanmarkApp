package dk.nadanmark.adapter_legacy_store

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.webkit.JavascriptInterface
import android.webkit.WebResourceRequest
import android.webkit.WebResourceResponse
import android.webkit.WebView
import android.webkit.WebViewClient
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.ByteArrayInputStream

class LegacyStorePlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private lateinit var assets: FlutterPlugin.FlutterAssets

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        assets = binding.flutterAssets
        channel = MethodChannel(binding.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "readAll" -> LegacyStoreReader(context, assets, result).start()
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    companion object {
        const val CHANNEL = "dk.nadanmark.app/legacy_store"
        const val ORIGIN_HOST = "localhost"
        const val PAGE_PATH = "/na_migrate.html"
        const val PAGE_URL = "https://localhost/na_migrate.html"
        const val TIMEOUT_MS = 5_000L
    }
}

private class LegacyStoreReader(
    private val context: Context,
    private val assets: FlutterPlugin.FlutterAssets,
    private val result: Result,
) {
    private val handler = Handler(Looper.getMainLooper())
    private var settled = false
    private var webView: WebView? = null

    fun start() {
        handler.post {
            try {
                val view = WebView(context)
                webView = view
                view.settings.javaScriptEnabled = true
                view.settings.domStorageEnabled = true
                view.settings.databaseEnabled = true
                view.addJavascriptInterface(Bridge(), "NaMigrate")
                view.webViewClient = PageServer()
                handler.postDelayed({ finish { result.error("legacy_store", "timed out", null) } }, LegacyStorePlugin.TIMEOUT_MS)
                view.loadUrl(LegacyStorePlugin.PAGE_URL)
            } catch (error: Throwable) {
                finish { result.error("legacy_store", error.message ?: error.toString(), null) }
            }
        }
    }

    private fun finish(block: () -> Unit) {
        if (settled) return
        settled = true
        block()
        webView?.destroy()
        webView = null
    }

    private inner class Bridge {
        @JavascriptInterface
        fun done(json: String) {
            handler.post { finish { result.success(json) } }
        }

        @JavascriptInterface
        fun absent() {
            handler.post { finish { result.success(null) } }
        }

        @JavascriptInterface
        fun fail(message: String) {
            handler.post { finish { result.error("legacy_store", message, null) } }
        }
    }

    private inner class PageServer : WebViewClient() {
        override fun shouldInterceptRequest(view: WebView, request: WebResourceRequest): WebResourceResponse {
            val url = request.url
            if (url.host == LegacyStorePlugin.ORIGIN_HOST && url.path == LegacyStorePlugin.PAGE_PATH) {
                val key = assets.getAssetFilePathByName("assets/na_migrate.html", "adapter_legacy_store")
                return WebResourceResponse("text/html", "utf-8", context.assets.open(key))
            }
            return WebResourceResponse(
                "text/plain",
                "utf-8",
                404,
                "Not found",
                emptyMap(),
                ByteArrayInputStream(ByteArray(0)),
            )
        }
    }
}
