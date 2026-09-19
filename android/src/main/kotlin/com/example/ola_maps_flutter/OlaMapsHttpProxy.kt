package com.example.ola_maps_flutter

import android.content.Context
import android.util.Log
import okhttp3.HttpUrl.Companion.toHttpUrlOrNull
import okhttp3.Interceptor
import okhttp3.OkHttpClient
import okhttp3.Response
import org.maplibre.android.module.http.HttpRequestUtil

/**
 * The Android Ola SDK always loads `api.olamaps.io` and appends `api_key`.
 * Domain-restricted dashboard keys then fail with HTTP 401/403 on native apps.
 *
 * When [tileUrl] points at a backend `/ola-maps/` proxy, rewrite those SDK
 * requests to the proxy (OAuth stays server-side; `api_key` is stripped).
 *
 * Must run **after** OlaMapView.getMap(), which calls MapLibre.getInstance.
 * Calling [HttpRequestUtil.setOkHttpClient] before that crashes with
 * MapLibreConfigurationException.
 */
internal object OlaMapsHttpProxy {
    private const val TAG = "OlaMapsHttpProxy"

    fun install(context: Context, tileUrl: String?) {
        val proxyBase = proxyBaseFromTileUrl(tileUrl) ?: return
        try {
            ensureMapLibre(context)
            val rewrite = RewriteInterceptor(proxyBase)
            val existing = currentCallFactory()
            if (existing is OkHttpClient &&
                existing.interceptors.any { it is RewriteInterceptor }
            ) {
                return
            }
            val client = if (existing is OkHttpClient) {
                existing.newBuilder().addInterceptor(rewrite).build()
            } else {
                OkHttpClient.Builder().addInterceptor(rewrite).build()
            }
            HttpRequestUtil.setOkHttpClient(client)
        } catch (error: Throwable) {
            Log.e(TAG, "Failed to install Ola Maps HTTP proxy", error)
        }
    }

    fun usesBackendProxy(tileUrl: String?): Boolean = proxyBaseFromTileUrl(tileUrl) != null

    fun proxyBaseFromTileUrl(tileUrl: String?): String? {
        val url = tileUrl?.trim().orEmpty()
        if (url.isEmpty()) return null
        val marker = "/ola-maps/"
        val idx = url.indexOf(marker)
        if (idx < 0) return null
        return url.substring(0, idx) + "/ola-maps/proxy"
    }

    private fun ensureMapLibre(context: Context) {
        val app = context.applicationContext
        val clazz = Class.forName("org.maplibre.android.MapLibre")
        val methods = clazz.methods.filter { it.name == "getInstance" }
        val oneArg = methods.firstOrNull { it.parameterTypes.size == 1 }
        if (oneArg != null) {
            oneArg.invoke(null, app)
            return
        }
        val threeArg = methods.firstOrNull { it.parameterTypes.size == 3 }
        if (threeArg != null) {
            val serverClass = Class.forName("org.maplibre.android.WellKnownTileServer")
            val mapLibreServer = serverClass.enumConstants?.firstOrNull {
                it.toString().equals("MapLibre", ignoreCase = true)
            }
            threeArg.invoke(null, app, null, mapLibreServer)
        }
    }

    private fun currentCallFactory(): okhttp3.Call.Factory? {
        return try {
            val method = HttpRequestUtil::class.java.methods.firstOrNull {
                it.name == "getOkHttpClient" && it.parameterCount == 0
            }
            method?.invoke(null) as? okhttp3.Call.Factory
        } catch (_: Throwable) {
            null
        }
    }

    private class RewriteInterceptor(
        proxyBase: String,
    ) : Interceptor {
        private val proxyBaseUrl = proxyBase.trimEnd('/').toHttpUrlOrNull()

        override fun intercept(chain: Interceptor.Chain): Response {
            val request = chain.request()
            val base = proxyBaseUrl
            if (base == null || request.url.host != "api.olamaps.io") {
                return chain.proceed(request)
            }

            val rewritten = base.newBuilder()
            for (segment in request.url.pathSegments) {
                rewritten.addPathSegment(segment)
            }
            for (i in 0 until request.url.querySize) {
                val name = request.url.queryParameterName(i)
                if (name.equals("api_key", ignoreCase = true)) continue
                rewritten.addQueryParameter(name, request.url.queryParameterValue(i))
            }
            return chain.proceed(request.newBuilder().url(rewritten.build()).build())
        }
    }
}
