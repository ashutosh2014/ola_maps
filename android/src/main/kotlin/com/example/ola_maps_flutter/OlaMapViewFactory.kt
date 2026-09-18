package com.example.ola_maps_flutter

import android.content.Context
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class OlaMapViewFactory(
    private val plugin: OlaMapViewFlutterPlugin,
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        val creationParams = args as? Map<String, Any?>
        plugin.setupMethodChannel(viewId)
        val view = OlaMapPlatformView(context, viewId, creationParams) { id ->
            plugin.removeMethodChannel(id)
        }
        plugin.attachViewEvents(viewId, view)
        return view
    }
}
