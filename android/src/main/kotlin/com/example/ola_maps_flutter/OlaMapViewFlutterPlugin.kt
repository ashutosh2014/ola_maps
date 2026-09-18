package com.example.ola_maps_flutter

import android.app.Activity
import android.app.Application
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.Result

/** OlaMapViewFlutterPlugin */
class OlaMapViewFlutterPlugin : FlutterPlugin, ActivityAware {
    private lateinit var binaryMessenger: BinaryMessenger
    private val methodChannels = mutableMapOf<Int, MethodChannel>()
    private val eventChannels = mutableMapOf<Int, EventChannel>()
    private val mainHandler = Handler(Looper.getMainLooper())
    private var activityBinding: ActivityPluginBinding? = null

    private val lifecycleCallbacks = object : Application.ActivityLifecycleCallbacks {
        override fun onActivityCreated(activity: Activity, savedInstanceState: Bundle?) {}

        override fun onActivityStarted(activity: Activity) {
            OlaMapPlatformView.mapInstances.values.forEach { it.onStart() }
        }

        override fun onActivityResumed(activity: Activity) {
            OlaMapPlatformView.mapInstances.values.forEach { it.onResume() }
        }

        override fun onActivityPaused(activity: Activity) {
            OlaMapPlatformView.mapInstances.values.forEach { it.onPause() }
        }

        override fun onActivityStopped(activity: Activity) {
            OlaMapPlatformView.mapInstances.values.forEach { it.onStop() }
        }

        override fun onActivitySaveInstanceState(activity: Activity, outState: Bundle) {
            OlaMapPlatformView.mapInstances.values.forEach { it.onSaveInstanceState(outState) }
        }

        override fun onActivityDestroyed(activity: Activity) {
            OlaMapPlatformView.mapInstances.values.forEach { it.onDestroy() }
        }
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        binaryMessenger = flutterPluginBinding.binaryMessenger
        flutterPluginBinding.platformViewRegistry.registerViewFactory(
            "ola_map_view_flutter",
            OlaMapViewFactory(this),
        )
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityBinding = binding
        binding.activity.application.registerActivityLifecycleCallbacks(lifecycleCallbacks)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        onDetachedFromActivity()
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivity() {
        activityBinding?.activity?.application?.unregisterActivityLifecycleCallbacks(lifecycleCallbacks)
        activityBinding = null
    }

    fun setupMethodChannel(id: Int) {
        val channel = MethodChannel(binaryMessenger, "ola_map_view_flutter_$id")
        channel.setMethodCallHandler { call, result ->
            handleMethodCall(id, call, result)
        }
        methodChannels[id] = channel

        val eventChannel = EventChannel(binaryMessenger, "ola_map_view_flutter_camera_$id")
        eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                OlaMapPlatformView.getInstance(id)?.cameraIdleListener = { position ->
                    mainHandler.post {
                        events?.success(position)
                    }
                }
            }

            override fun onCancel(arguments: Any?) {
                OlaMapPlatformView.getInstance(id)?.cameraIdleListener = null
            }
        })
        eventChannels[id] = eventChannel
    }

    fun attachViewEvents(id: Int, view: OlaMapPlatformView) {
        view.nativeEvents = { method, args ->
            mainHandler.post {
                methodChannels[id]?.invokeMethod(method, args)
            }
        }
    }

    private fun handleMethodCall(id: Int, call: MethodCall, result: Result) {
        val mapView = OlaMapPlatformView.getInstance(id)
        if (mapView == null) {
            result.error("MAP_NOT_FOUND", "Map instance not found for id: $id", null)
            return
        }

        when (call.method) {
            "waitUntilMapReady" -> mapView.waitUntilMapReady(result)
            "addMarker" -> {
                val markerId = call.argument<String>("markerId")
                val latitude = FlutterArgs.callDouble(call, "latitude")
                val longitude = FlutterArgs.callDouble(call, "longitude")
                if (markerId != null && latitude != null && longitude != null) {
                    result.success(
                        mapView.addMarker(
                            markerId,
                            latitude,
                            longitude,
                            FlutterArgs.callBool(call, "isClickable", true),
                            FlutterArgs.callFloat(call, "iconRotation") ?: 0f,
                            FlutterArgs.callBool(call, "isAnimationEnabled", true),
                            call.argument("snippet"),
                            call.argument("subSnippet"),
                            FlutterArgs.callBool(call, "isInfoWindowDismissOnClick", true),
                            call.argument("iconPath"),
                            call.argument("iconAnchor"),
                            FlutterArgs.callFloat(call, "iconSize"),
                            FlutterArgs.floatArray(call.argument("iconOffset")),
                        ),
                    )
                } else {
                    result.error("INVALID_ARGUMENTS", "Missing required arguments", null)
                }
            }
            "removeMarker" -> {
                val markerId = call.argument<String>("markerId")
                if (markerId != null) {
                    mapView.removeMarker(markerId)
                    result.success(null)
                } else {
                    result.error("INVALID_ARGUMENTS", "Missing markerId", null)
                }
            }
            "updateMarker" -> {
                val markerId = call.argument<String>("markerId")
                if (markerId != null) {
                    mapView.updateMarker(
                        markerId,
                        FlutterArgs.callDouble(call, "latitude"),
                        FlutterArgs.callDouble(call, "longitude"),
                        FlutterArgs.callFloat(call, "iconRotation"),
                        call.argument("iconAnchor"),
                        call.argument("iconPath"),
                        FlutterArgs.floatArray(call.argument("iconOffset")),
                        FlutterArgs.callFloat(call, "iconSize"),
                        call.argument("snippet"),
                        call.argument("subSnippet"),
                    )
                    result.success(null)
                } else {
                    result.error("INVALID_ARGUMENTS", "Missing markerId", null)
                }
            }
            "showInfoWindow" -> {
                val markerId = call.argument<String>("markerId")
                if (markerId != null) {
                    mapView.showInfoWindow(markerId)
                    result.success(null)
                } else {
                    result.error("INVALID_ARGUMENTS", "Missing markerId", null)
                }
            }
            "hideInfoWindow" -> {
                val markerId = call.argument<String>("markerId")
                if (markerId != null) {
                    mapView.hideInfoWindow(markerId)
                    result.success(null)
                } else {
                    result.error("INVALID_ARGUMENTS", "Missing markerId", null)
                }
            }
            "updateInfoWindow" -> {
                val markerId = call.argument<String>("markerId")
                val text = call.argument<String>("text")
                if (markerId != null && text != null) {
                    mapView.updateInfoWindow(markerId, text)
                    result.success(null)
                } else {
                    result.error("INVALID_ARGUMENTS", "Missing markerId or text", null)
                }
            }
            "addPolyline" -> {
                val polylineId = call.argument<String>("polylineId")
                val points = FlutterArgs.points(call.argument("points"))
                if (polylineId != null && points.isNotEmpty()) {
                    result.success(
                        mapView.addPolyline(
                            polylineId,
                            points,
                            call.argument("color"),
                            call.argument("lineType"),
                            FlutterArgs.callFloat(call, "width"),
                        ),
                    )
                } else {
                    result.error("INVALID_ARGUMENTS", "Missing required arguments", null)
                }
            }
            "removePolyline" -> {
                val polylineId = call.argument<String>("polylineId")
                if (polylineId != null) {
                    mapView.removePolyline(polylineId)
                    result.success(null)
                } else {
                    result.error("INVALID_ARGUMENTS", "Missing polylineId", null)
                }
            }
            "updatePolyline" -> {
                val polylineId = call.argument<String>("polylineId")
                if (polylineId != null) {
                    val rawPoints = call.argument<Any>("points")
                    mapView.updatePolyline(
                        polylineId,
                        if (rawPoints != null) FlutterArgs.points(rawPoints) else null,
                        call.argument("color"),
                        FlutterArgs.callFloat(call, "width"),
                        call.argument("lineType"),
                    )
                    result.success(null)
                } else {
                    result.error("INVALID_ARGUMENTS", "Missing polylineId", null)
                }
            }
            "addCircle" -> {
                val circleId = call.argument<String>("circleId")
                val latitude = FlutterArgs.callDouble(call, "latitude")
                val longitude = FlutterArgs.callDouble(call, "longitude")
                val radius = FlutterArgs.callFloat(call, "radius")
                if (circleId != null && latitude != null && longitude != null && radius != null) {
                    result.success(
                        mapView.addCircle(
                            circleId,
                            latitude,
                            longitude,
                            radius,
                            call.argument("color"),
                            FlutterArgs.callFloat(call, "blur"),
                            FlutterArgs.callFloat(call, "opacity"),
                            call.argument("borderColor"),
                            FlutterArgs.callFloat(call, "borderWidth"),
                            call.argument("borderLineType"),
                        ),
                    )
                } else {
                    result.error("INVALID_ARGUMENTS", "Missing required arguments", null)
                }
            }
            "removeCircle" -> {
                val circleId = call.argument<String>("circleId")
                if (circleId != null) {
                    mapView.removeCircle(circleId)
                    result.success(null)
                } else {
                    result.error("INVALID_ARGUMENTS", "Missing circleId", null)
                }
            }
            "updateCircle" -> {
                val circleId = call.argument<String>("circleId")
                if (circleId != null) {
                    mapView.updateCircle(
                        circleId,
                        FlutterArgs.callDouble(call, "latitude"),
                        FlutterArgs.callDouble(call, "longitude"),
                        FlutterArgs.callFloat(call, "radius"),
                        call.argument("color"),
                        FlutterArgs.callFloat(call, "opacity"),
                        FlutterArgs.callFloat(call, "blur"),
                        call.argument("borderColor"),
                        FlutterArgs.callFloat(call, "borderWidth"),
                        call.argument("borderLineType"),
                    )
                    result.success(null)
                } else {
                    result.error("INVALID_ARGUMENTS", "Missing circleId", null)
                }
            }
            "addPolygon" -> {
                val polygonId = call.argument<String>("polygonId")
                val points = FlutterArgs.points(call.argument("points"))
                if (polygonId != null && points.isNotEmpty()) {
                    result.success(
                        mapView.addPolygon(
                            polygonId,
                            points,
                            call.argument("color"),
                            call.argument("borderColor"),
                            FlutterArgs.callFloat(call, "borderWidth"),
                            call.argument("borderLineType"),
                        ),
                    )
                } else {
                    result.error("INVALID_ARGUMENTS", "Missing required arguments", null)
                }
            }
            "removePolygon" -> {
                val polygonId = call.argument<String>("polygonId")
                if (polygonId != null) {
                    mapView.removePolygon(polygonId)
                    result.success(null)
                } else {
                    result.error("INVALID_ARGUMENTS", "Missing polygonId", null)
                }
            }
            "updatePolygon" -> {
                val polygonId = call.argument<String>("polygonId")
                if (polygonId != null) {
                    val rawPoints = call.argument<Any>("points")
                    mapView.updatePolygon(
                        polygonId,
                        if (rawPoints != null) FlutterArgs.points(rawPoints) else null,
                        call.argument("color"),
                        call.argument("borderColor"),
                        FlutterArgs.callFloat(call, "borderWidth"),
                        call.argument("borderLineType"),
                    )
                    result.success(null)
                } else {
                    result.error("INVALID_ARGUMENTS", "Missing polygonId", null)
                }
            }
            "addBezierCurve" -> {
                val curveId = call.argument<String>("curveId")
                val startLatitude = FlutterArgs.callDouble(call, "startLatitude")
                val startLongitude = FlutterArgs.callDouble(call, "startLongitude")
                val endLatitude = FlutterArgs.callDouble(call, "endLatitude")
                val endLongitude = FlutterArgs.callDouble(call, "endLongitude")
                if (curveId != null && startLatitude != null && startLongitude != null &&
                    endLatitude != null && endLongitude != null
                ) {
                    result.success(
                        mapView.addBezierCurve(
                            curveId,
                            startLatitude,
                            startLongitude,
                            endLatitude,
                            endLongitude,
                            call.argument("color"),
                            call.argument("lineType"),
                            FlutterArgs.callFloat(call, "width"),
                        ),
                    )
                } else {
                    result.error("INVALID_ARGUMENTS", "Missing required arguments", null)
                }
            }
            "removeBezierCurve" -> {
                val curveId = call.argument<String>("curveId")
                if (curveId != null) {
                    mapView.removeBezierCurve(curveId)
                    result.success(null)
                } else {
                    result.error("INVALID_ARGUMENTS", "Missing curveId", null)
                }
            }
            "updateBezierCurve" -> {
                val curveId = call.argument<String>("curveId")
                if (curveId != null) {
                    mapView.updateBezierCurve(
                        curveId,
                        FlutterArgs.callDouble(call, "startLatitude"),
                        FlutterArgs.callDouble(call, "startLongitude"),
                        FlutterArgs.callDouble(call, "endLatitude"),
                        FlutterArgs.callDouble(call, "endLongitude"),
                        call.argument("color"),
                        call.argument("lineType"),
                        FlutterArgs.callFloat(call, "width"),
                    )
                    result.success(null)
                } else {
                    result.error("INVALID_ARGUMENTS", "Missing curveId", null)
                }
            }
            "zoomToLocation" -> {
                val latitude = FlutterArgs.callDouble(call, "latitude")
                val longitude = FlutterArgs.callDouble(call, "longitude")
                val zoomLevel = FlutterArgs.callDouble(call, "zoomLevel")
                if (latitude != null && longitude != null && zoomLevel != null) {
                    mapView.zoomToLocation(latitude, longitude, zoomLevel)
                    result.success(null)
                } else {
                    result.error("INVALID_ARGUMENTS", "Missing required arguments", null)
                }
            }
            "zoomIn" -> {
                mapView.zoomBy(1.0)
                result.success(null)
            }
            "zoomOut" -> {
                mapView.zoomBy(-1.0)
                result.success(null)
            }
            "moveCamera" -> {
                val latitude = FlutterArgs.callDouble(call, "latitude")
                val longitude = FlutterArgs.callDouble(call, "longitude")
                val zoomLevel = FlutterArgs.callDouble(call, "zoomLevel") ?: 15.0
                val durationMs = FlutterArgs.callInt(call, "durationMs") ?: 500
                if (latitude != null && longitude != null) {
                    mapView.moveCamera(latitude, longitude, zoomLevel, durationMs)
                    result.success(null)
                } else {
                    result.error("INVALID_ARGUMENTS", "Missing required arguments", null)
                }
            }
            "getCurrentLocation" -> result.success(mapView.getCurrentLocation())
            "getCameraPosition" -> result.success(mapView.getCameraPosition())
            "showCurrentLocation" -> {
                mapView.showCurrentLocation()
                result.success(null)
            }
            "hideCurrentLocation" -> {
                mapView.hideCurrentLocation()
                result.success(null)
            }
            "addClusteredMarkers" -> {
                val geoJson = call.argument<String>("geoJson")
                if (geoJson != null) {
                    result.success(
                        mapView.addClusteredMarkers(
                            geoJson,
                            FlutterArgs.callInt(call, "clusterRadius"),
                            call.argument("defaultMarkerColor"),
                            call.argument("defaultClusterColor"),
                            FlutterArgs.callFloat(call, "textSize"),
                            call.argument("textColor"),
                            call.argument("stop1Color"),
                            call.argument("stop2Color"),
                            call.argument("iconPath"),
                        ),
                    )
                } else {
                    result.error("INVALID_ARGUMENTS", "Missing geoJson", null)
                }
            }
            "updateClusteredMarkers" -> {
                val clusterId = call.argument<String>("clusterId")
                val geoJson = call.argument<String>("geoJson")
                if (clusterId != null && geoJson != null) {
                    mapView.updateClusteredMarkers(
                        clusterId,
                        geoJson,
                        FlutterArgs.callInt(call, "clusterRadius"),
                        call.argument("defaultMarkerColor"),
                        call.argument("defaultClusterColor"),
                        FlutterArgs.callFloat(call, "textSize"),
                        call.argument("textColor"),
                        call.argument("stop1Color"),
                        call.argument("stop2Color"),
                        call.argument("iconPath"),
                    )
                    result.success(null)
                } else {
                    result.error("INVALID_ARGUMENTS", "Missing required arguments", null)
                }
            }
            "removeClusteredMarkers" -> {
                val clusterId = call.argument<String>("clusterId")
                if (clusterId != null) {
                    mapView.removeClusteredMarkers(clusterId)
                    result.success(null)
                } else {
                    result.error("INVALID_ARGUMENTS", "Missing clusterId", null)
                }
            }
            else -> result.notImplemented()
        }
    }

    fun removeMethodChannel(id: Int) {
        methodChannels.remove(id)?.setMethodCallHandler(null)
        eventChannels.remove(id)?.setStreamHandler(null)
        OlaMapPlatformView.getInstance(id)?.cameraIdleListener = null
        OlaMapPlatformView.getInstance(id)?.nativeEvents = null
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannels.values.forEach { it.setMethodCallHandler(null) }
        methodChannels.clear()
        eventChannels.values.forEach { it.setStreamHandler(null) }
        eventChannels.clear()
    }
}
