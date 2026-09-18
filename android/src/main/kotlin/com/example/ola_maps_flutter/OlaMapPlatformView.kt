package com.example.ola_maps_flutter

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Bundle
import android.view.View
import android.widget.FrameLayout
import com.ola.mapsdk.camera.MapControlSettings
import com.ola.mapsdk.interfaces.MarkerEventListener
import com.ola.mapsdk.interfaces.OlaMapCallback
import com.ola.mapsdk.listeners.OlaMapsCameraListenerManager
import com.ola.mapsdk.listeners.OlaMapsListenerManager
import com.ola.mapsdk.model.BezierCurveOptions
import com.ola.mapsdk.model.BorderOptions
import com.ola.mapsdk.model.OlaCircleOptions
import com.ola.mapsdk.model.OlaLatLng
import com.ola.mapsdk.model.OlaMarkerClusterOptions
import com.ola.mapsdk.model.OlaMarkerOptions
import com.ola.mapsdk.model.OlaPolygonOptions
import com.ola.mapsdk.model.OlaPolylineOptions
import com.ola.mapsdk.view.BezierCurve
import com.ola.mapsdk.view.Circle
import com.ola.mapsdk.view.ClusteredMarkers
import com.ola.mapsdk.view.Marker
import com.ola.mapsdk.view.OlaMap
import com.ola.mapsdk.view.OlaMapView
import com.ola.mapsdk.view.Polygon
import com.ola.mapsdk.view.Polyline
import io.flutter.FlutterInjector
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView

class OlaMapPlatformView(
    private val context: Context,
    private val id: Int,
    creationParams: Map<String, Any?>?,
    private val onDisposed: (Int) -> Unit,
) : PlatformView {
    private val mapView: OlaMapView = OlaMapView(context)
    private var olaMap: OlaMap? = null

    var cameraIdleListener: ((Map<String, Double>?) -> Unit)? = null
    var nativeEvents: ((String, Any?) -> Unit)? = null

    @Volatile
    private var isMapReady = false
    @Volatile
    private var mapError: String? = null
    private var pendingReadyResult: MethodChannel.Result? = null

    private val markers = mutableMapOf<String, Marker>()
    private val polylines = mutableMapOf<String, Polyline>()
    private val circles = mutableMapOf<String, Circle>()
    private val polygons = mutableMapOf<String, Polygon>()
    private val bezierCurves = mutableMapOf<String, BezierCurve>()
    private val clusteredMarkers = mutableMapOf<String, ClusteredMarkers>()

    companion object {
        val mapInstances = mutableMapOf<Int, OlaMapPlatformView>()

        fun getInstance(id: Int): OlaMapPlatformView? = mapInstances[id]
    }

    init {
        mapInstances[id] = this

        val apiKey = FlutterArgs.mapString(creationParams, "apiKey") ?: ""

        mapView.layoutParams = FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT,
            FrameLayout.LayoutParams.MATCH_PARENT,
        )

        val zoomGesturesEnabled = FlutterArgs.mapBool(creationParams, "zoomGesturesEnabled", true)
        val scrollGesturesEnabled = FlutterArgs.mapBool(creationParams, "scrollGesturesEnabled", true)
        val tiltGesturesEnabled = FlutterArgs.mapBool(creationParams, "tiltGesturesEnabled", true)
        val rotateGesturesEnabled = FlutterArgs.mapBool(creationParams, "rotateGesturesEnabled", true)
        val doubleTapGesturesEnabled =
            FlutterArgs.mapBool(creationParams, "doubleTapGesturesEnabled", true)
        val showCompass = FlutterArgs.mapBool(creationParams, "showCompass", true)
        val myLocationEnabled = FlutterArgs.mapBool(creationParams, "myLocationEnabled", true)

        val initialLatitude = FlutterArgs.mapDouble(creationParams, "initialLatitude")
        val initialLongitude = FlutterArgs.mapDouble(creationParams, "initialLongitude")
        val initialZoom = FlutterArgs.mapDouble(creationParams, "initialZoom") ?: 15.0

        val mapControlSettings = MapControlSettings.Builder()
            .setRotateGesturesEnabled(rotateGesturesEnabled)
            .setScrollGesturesEnabled(scrollGesturesEnabled)
            .setZoomGesturesEnabled(zoomGesturesEnabled)
            .setCompassEnabled(showCompass)
            .setTiltGesturesEnabled(tiltGesturesEnabled)
            .setDoubleTapGesturesEnabled(doubleTapGesturesEnabled)
            .build()

        mapView.getMap(
            apiKey = apiKey,
            olaMapCallback = object : OlaMapCallback {
                override fun onMapReady(olaMap: OlaMap) {
                    this@OlaMapPlatformView.olaMap = olaMap
                    bindListeners(olaMap)

                    if (myLocationEnabled) {
                        try {
                            olaMap.showCurrentLocation()
                        } catch (e: Exception) {
                            println("OlaMap Error enabling MyLocation: ${e.message}")
                        }
                    }

                    if (initialLatitude != null && initialLongitude != null) {
                        try {
                            olaMap.zoomToLocation(
                                OlaLatLng(initialLatitude, initialLongitude),
                                initialZoom,
                            )
                        } catch (e: Exception) {
                            println("OlaMap Error setting initial camera: ${e.message}")
                        }
                    }

                    notifyMapReady()
                }

                override fun onMapError(error: String) {
                    println("OlaMap Error: $error")
                    notifyMapError(error)
                }
            },
            mapControlSettings = mapControlSettings,
        )
    }

    private fun bindListeners(olaMap: OlaMap) {
        try {
            olaMap.setOnOlaMapsCameraIdleListener(
                object : OlaMapsCameraListenerManager.OnOlaMapsCameraIdleListener {
                    override fun onOlaMapsCameraIdle() {
                        cameraIdleListener?.invoke(getCameraPosition())
                    }
                },
            )
        } catch (e: Exception) {
            println("OlaMap Error setting camera idle listener: ${e.message}")
        }

        try {
            olaMap.setOnMapClickedListener(
                object : OlaMapsListenerManager.OnOlaMapClickedListener {
                    override fun onOlaMapClicked(latLng: OlaLatLng) {
                        nativeEvents?.invoke(
                            "onMapClick",
                            mapOf(
                                "latitude" to latLng.latitude,
                                "longitude" to latLng.longitude,
                            ),
                        )
                    }
                },
            )
        } catch (e: Exception) {
            println("OlaMap Error setting map click listener: ${e.message}")
        }

        try {
            olaMap.setOnMapLongClickedListener(
                object : OlaMapsListenerManager.OnOlaMapsLongClickedListener {
                    override fun onOlaMapsLongClicked(latLng: OlaLatLng) {
                        nativeEvents?.invoke(
                            "onMapLongClick",
                            mapOf(
                                "latitude" to latLng.latitude,
                                "longitude" to latLng.longitude,
                            ),
                        )
                    }
                },
            )
        } catch (e: Exception) {
            println("OlaMap Error setting map long-click listener: ${e.message}")
        }

        try {
            olaMap.setMarkerListener(
                object : MarkerEventListener {
                    override fun onMarkerClicked(markerId: String) {
                        nativeEvents?.invoke("onMarkerClick", mapOf("markerId" to markerId))
                    }
                },
            )
        } catch (e: Exception) {
            println("OlaMap Error setting marker click listener: ${e.message}")
        }
    }

    @Synchronized
    fun waitUntilMapReady(result: MethodChannel.Result) {
        when {
            isMapReady -> result.success(true)
            mapError != null -> result.error("MAP_ERROR", mapError, null)
            else -> pendingReadyResult = result
        }
    }

    @Synchronized
    private fun notifyMapReady() {
        isMapReady = true
        pendingReadyResult?.success(true)
        pendingReadyResult = null
        nativeEvents?.invoke("onMapReady", null)
    }

    @Synchronized
    private fun notifyMapError(error: String) {
        mapError = error
        pendingReadyResult?.error("MAP_ERROR", error, null)
        pendingReadyResult = null
        nativeEvents?.invoke("onMapError", error)
    }

    fun addMarker(
        markerId: String,
        latitude: Double,
        longitude: Double,
        isClickable: Boolean,
        iconRotation: Float,
        isAnimationEnabled: Boolean,
        snippet: String?,
        subSnippet: String?,
        isInfoWindowDismissOnClick: Boolean,
        iconPath: String?,
        iconAnchor: String?,
        iconSize: Float?,
        iconOffset: Array<Float>?,
    ): String? {
        return try {
            val builder = OlaMarkerOptions.Builder()
                .setMarkerId(markerId)
                .setPosition(OlaLatLng(latitude, longitude))
                .setIsIconClickable(isClickable)
                .setIconRotation(iconRotation)
                .setIsAnimationEnable(isAnimationEnabled)
                .setIsInfoWindowDismissOnClick(isInfoWindowDismissOnClick)

            snippet?.let { builder.setSnippet(it) }
            subSnippet?.let { builder.setSubSnippet(it) }
            iconAnchor?.let { builder.setIconAnchor(it) }
            iconSize?.let { builder.setIconSize(it) }
            iconOffset?.let { builder.setIconOffset(it) }
            iconPath?.let { path ->
                getBitmapFromAsset(path)?.let { builder.setIconBitmap(it) }
            }

            olaMap?.addMarker(builder.build())?.let { marker ->
                markers[markerId] = marker
                markerId
            }
        } catch (e: Exception) {
            println("OlaMap Error adding marker: ${e.message}")
            null
        }
    }

    fun removeMarker(markerId: String) {
        try {
            markers[markerId]?.removeMarker()
            markers.remove(markerId)
        } catch (e: Exception) {
            println("OlaMap Error removing marker: ${e.message}")
        }
    }

    private fun getBitmapFromAsset(assetName: String): Bitmap? {
        return try {
            val loader = FlutterInjector.instance().flutterLoader()
            val key = loader.getLookupKeyForAsset(assetName)
            context.assets.open(key).use { BitmapFactory.decodeStream(it) }
        } catch (e: Exception) {
            println("OlaMap Error loading asset: $assetName, ${e.message}")
            try {
                context.assets.open(assetName).use { BitmapFactory.decodeStream(it) }
            } catch (e2: Exception) {
                println("OlaMap Error loading asset (fallback): $assetName, ${e2.message}")
                null
            }
        }
    }

    fun updateMarker(
        markerId: String,
        latitude: Double?,
        longitude: Double?,
        iconRotation: Float?,
        iconAnchor: String?,
        iconPath: String?,
        iconOffset: Array<Float>?,
        iconSize: Float?,
        snippet: String?,
        subSnippet: String?,
    ) {
        try {
            val marker = markers[markerId] ?: return
            val bitmap = iconPath?.let { getBitmapFromAsset(it) }
            val position =
                if (latitude != null && longitude != null) OlaLatLng(latitude, longitude) else null
            marker.updateMarker(
                position,
                iconAnchor,
                bitmap,
                null,
                iconOffset,
                iconRotation,
                iconSize,
                snippet,
                subSnippet,
            )
        } catch (e: Exception) {
            println("OlaMap Error updating marker: ${e.message}")
        }
    }

    fun showInfoWindow(markerId: String) {
        try {
            markers[markerId]?.showInfoWindow()
        } catch (e: Exception) {
            println("OlaMap Error showing info window: ${e.message}")
        }
    }

    fun hideInfoWindow(markerId: String) {
        try {
            markers[markerId]?.hideInfoWindow()
        } catch (e: Exception) {
            println("OlaMap Error hiding info window: ${e.message}")
        }
    }

    fun updateInfoWindow(markerId: String, text: String) {
        try {
            markers[markerId]?.updateInfoWindow(text)
        } catch (e: Exception) {
            println("OlaMap Error updating info window: ${e.message}")
        }
    }

    fun addPolyline(
        polylineId: String,
        points: ArrayList<OlaLatLng>,
        color: String?,
        lineType: String?,
        width: Float?,
    ): String? {
        return try {
            val builder = OlaPolylineOptions.Builder()
                .setPolylineId(polylineId)
                .setPoints(points)

            color?.let { builder.setColor(it) }
            FlutterArgs.resolveLineType(lineType)?.let { builder.setLineType(it) }
            width?.let { builder.setWidth(it) }

            olaMap?.addPolyline(builder.build())?.let { polyline ->
                polylines[polylineId] = polyline
                polylineId
            }
        } catch (e: Exception) {
            println("OlaMap Error adding polyline: ${e.message}")
            null
        }
    }

    fun removePolyline(polylineId: String) {
        try {
            polylines[polylineId]?.removePolyline()
            polylines.remove(polylineId)
        } catch (e: Exception) {
            println("OlaMap Error removing polyline: ${e.message}")
        }
    }

    fun updatePolyline(
        polylineId: String,
        points: ArrayList<OlaLatLng>?,
        color: String?,
        width: Float?,
        lineType: String?,
    ) {
        try {
            val polyline = polylines[polylineId] ?: return
            points?.let { polyline.setPoints(it) }
            color?.let { polyline.setColor(it) }
            width?.let { polyline.setWidth(it) }
            FlutterArgs.resolveLineType(lineType)?.let { polyline.setLineType(it) }
        } catch (e: Exception) {
            println("OlaMap Error updating polyline: ${e.message}")
        }
    }

    fun addCircle(
        circleId: String,
        latitude: Double,
        longitude: Double,
        radius: Float,
        color: String?,
        blur: Float?,
        opacity: Float?,
        borderColor: String?,
        borderWidth: Float?,
        borderLineType: String?,
    ): String? {
        return try {
            val builder = OlaCircleOptions.Builder()
                .setOlaLatLng(OlaLatLng(latitude, longitude))
                .setRadius(radius)

            color?.let { builder.setColorHexCode(it) }
            blur?.let { builder.setCircleBlur(it) }
            opacity?.let { builder.setCircleOpacity(it) }
            buildBorder(borderColor, borderWidth, borderLineType)?.let {
                builder.setBorderOptions(it)
            }

            olaMap?.addCircle(builder.build())?.let { circle ->
                circles[circleId] = circle
                circleId
            }
        } catch (e: Exception) {
            println("OlaMap Error adding circle: ${e.message}")
            null
        }
    }

    fun removeCircle(circleId: String) {
        try {
            circles[circleId]?.removeCircle()
            circles.remove(circleId)
        } catch (e: Exception) {
            println("OlaMap Error removing circle: ${e.message}")
        }
    }

    fun updateCircle(
        circleId: String,
        latitude: Double?,
        longitude: Double?,
        radius: Float?,
        color: String?,
        opacity: Float?,
        blur: Float?,
        borderColor: String?,
        borderWidth: Float?,
        borderLineType: String?,
    ) {
        try {
            val circle = circles[circleId] ?: return
            if (latitude != null && longitude != null) {
                circle.setCenter(OlaLatLng(latitude, longitude))
            }
            radius?.let { circle.setRadius(it) }
            color?.let { circle.setColor(it) }
            opacity?.let { circle.setOpacity(it) }
            blur?.let { circle.setBlur(it) }
            buildBorder(borderColor, borderWidth, borderLineType)?.let {
                circle.setBorderOptions(it)
            }
        } catch (e: Exception) {
            println("OlaMap Error updating circle: ${e.message}")
        }
    }

    fun addPolygon(
        polygonId: String,
        points: ArrayList<OlaLatLng>,
        color: String?,
        borderColor: String?,
        borderWidth: Float?,
        borderLineType: String?,
    ): String? {
        return try {
            val builder = OlaPolygonOptions.Builder()
                .setPolygonId(polygonId)
                .setPoints(points)

            color?.let { builder.setColor(it) }
            buildBorder(borderColor, borderWidth, borderLineType)?.let {
                builder.setBorderOptions(it)
            }

            olaMap?.addPolygon(builder.build())?.let { polygon ->
                polygons[polygonId] = polygon
                polygonId
            }
        } catch (e: Exception) {
            println("OlaMap Error adding polygon: ${e.message}")
            null
        }
    }

    fun removePolygon(polygonId: String) {
        try {
            polygons[polygonId]?.removePolygon()
            polygons.remove(polygonId)
        } catch (e: Exception) {
            println("OlaMap Error removing polygon: ${e.message}")
        }
    }

    fun updatePolygon(
        polygonId: String,
        points: ArrayList<OlaLatLng>?,
        color: String?,
        borderColor: String?,
        borderWidth: Float?,
        borderLineType: String?,
    ) {
        try {
            val polygon = polygons[polygonId] ?: return
            points?.let { polygon.setPoints(it) }
            color?.let { polygon.setColor(it) }
            buildBorder(borderColor, borderWidth, borderLineType)?.let {
                polygon.setBorderOptions(it)
            }
        } catch (e: Exception) {
            println("OlaMap Error updating polygon: ${e.message}")
        }
    }

    fun addBezierCurve(
        curveId: String,
        startLatitude: Double,
        startLongitude: Double,
        endLatitude: Double,
        endLongitude: Double,
        color: String?,
        lineType: String?,
        width: Float?,
    ): String? {
        return try {
            val builder = BezierCurveOptions.Builder()
                .setCurveId(curveId)
                .setStartPoint(OlaLatLng(startLatitude, startLongitude))
                .setEndPoint(OlaLatLng(endLatitude, endLongitude))

            color?.let { builder.setColor(it) }
            FlutterArgs.resolveLineType(lineType)?.let { builder.setLineType(it) }
            width?.let { builder.setWidth(it) }

            olaMap?.addBezierCurve(builder.build())?.let { curve ->
                bezierCurves[curveId] = curve
                curveId
            }
        } catch (e: Exception) {
            println("OlaMap Error adding bezier curve: ${e.message}")
            null
        }
    }

    fun removeBezierCurve(curveId: String) {
        try {
            bezierCurves[curveId]?.removeBezierCurve()
            bezierCurves.remove(curveId)
        } catch (e: Exception) {
            println("OlaMap Error removing bezier curve: ${e.message}")
        }
    }

    fun updateBezierCurve(
        curveId: String,
        startLatitude: Double?,
        startLongitude: Double?,
        endLatitude: Double?,
        endLongitude: Double?,
        color: String?,
        lineType: String?,
        width: Float?,
    ) {
        try {
            val curve = bezierCurves[curveId] ?: return
            if (startLatitude != null && startLongitude != null &&
                endLatitude != null && endLongitude != null
            ) {
                curve.setPoints(
                    OlaLatLng(startLatitude, startLongitude),
                    OlaLatLng(endLatitude, endLongitude),
                )
            }
            color?.let { curve.setColor(it) }
            FlutterArgs.resolveLineType(lineType)?.let { curve.setLineType(it) }
            width?.let { curve.setWidth(it) }
        } catch (e: Exception) {
            println("OlaMap Error updating bezier curve: ${e.message}")
        }
    }

    fun zoomToLocation(latitude: Double, longitude: Double, zoomLevel: Double) {
        try {
            olaMap?.zoomToLocation(OlaLatLng(latitude, longitude), zoomLevel)
        } catch (e: Exception) {
            println("OlaMap Error zooming to location: ${e.message}")
        }
    }

    fun zoomBy(delta: Double) {
        try {
            val position = olaMap?.getCurrentOlaCameraPosition() ?: return
            val target = position.target ?: return
            olaMap?.zoomToLocation(target, position.zoomLevel + delta)
        } catch (e: Exception) {
            println("OlaMap Error changing zoom: ${e.message}")
        }
    }

    fun moveCamera(latitude: Double, longitude: Double, zoomLevel: Double, durationMs: Int) {
        try {
            olaMap?.moveCameraToLatLong(OlaLatLng(latitude, longitude), zoomLevel, durationMs)
        } catch (e: Exception) {
            println("OlaMap Error moving camera: ${e.message}")
        }
    }

    fun getCurrentLocation(): Map<String, Double>? {
        return try {
            olaMap?.getCurrentLocation()?.let {
                mapOf(
                    "latitude" to it.latitude,
                    "longitude" to it.longitude,
                )
            }
        } catch (e: Exception) {
            println("OlaMap Error getting current location: ${e.message}")
            null
        }
    }

    fun getCameraPosition(): Map<String, Double>? {
        return try {
            val position = olaMap?.getCurrentOlaCameraPosition()
            val target = position?.target ?: return null
            mapOf(
                "latitude" to target.latitude,
                "longitude" to target.longitude,
                "zoom" to position.zoomLevel,
                "bearing" to position.bearing,
                "tilt" to position.tilt,
            )
        } catch (e: Exception) {
            println("OlaMap Error getting camera position: ${e.message}")
            null
        }
    }

    fun showCurrentLocation() {
        try {
            olaMap?.showCurrentLocation()
        } catch (e: Exception) {
            println("OlaMap Error showing current location: ${e.message}")
        }
    }

    fun hideCurrentLocation() {
        try {
            olaMap?.hideCurrentLocation()
        } catch (e: Exception) {
            println("OlaMap Error hiding current location: ${e.message}")
        }
    }

    fun addClusteredMarkers(
        geoJson: String,
        clusterRadius: Int?,
        defaultMarkerColor: String?,
        defaultClusterColor: String?,
        textSize: Float?,
        textColor: String?,
        stop1Color: String?,
        stop2Color: String?,
        iconPath: String?,
    ): String? {
        return try {
            val clusterId = "cluster_${System.currentTimeMillis()}"
            val options = buildClusterOptions(
                clusterRadius,
                defaultMarkerColor,
                defaultClusterColor,
                textSize,
                textColor,
                stop1Color,
                stop2Color,
                iconPath,
            )
            olaMap?.addClusteredMarkers(options, geoJson)?.let { clustered ->
                clusteredMarkers[clusterId] = clustered
                clusterId
            }
        } catch (e: Exception) {
            println("OlaMap Error adding clustered markers: ${e.message}")
            null
        }
    }

    fun updateClusteredMarkers(
        clusterId: String,
        geoJson: String,
        clusterRadius: Int?,
        defaultMarkerColor: String?,
        defaultClusterColor: String?,
        textSize: Float?,
        textColor: String?,
        stop1Color: String?,
        stop2Color: String?,
        iconPath: String?,
    ) {
        try {
            val clustered = clusteredMarkers[clusterId] ?: return
            val options = buildClusterOptions(
                clusterRadius,
                defaultMarkerColor,
                defaultClusterColor,
                textSize,
                textColor,
                stop1Color,
                stop2Color,
                iconPath,
            )
            clustered.updateClusteredMarkers(geoJson, options)
        } catch (e: Exception) {
            println("OlaMap Error updating clustered markers: ${e.message}")
        }
    }

    fun removeClusteredMarkers(clusterId: String) {
        try {
            clusteredMarkers.remove(clusterId)?.removeClusteredMarkers()
        } catch (e: Exception) {
            println("OlaMap Error removing clustered markers: ${e.message}")
        }
    }

    private fun buildClusterOptions(
        clusterRadius: Int?,
        defaultMarkerColor: String?,
        defaultClusterColor: String?,
        textSize: Float?,
        textColor: String?,
        stop1Color: String?,
        stop2Color: String?,
        iconPath: String?,
    ): OlaMarkerClusterOptions {
        val builder = OlaMarkerClusterOptions.Builder()
        clusterRadius?.let { builder.setClusterRadius(it) }
        defaultMarkerColor?.let { builder.setDefaultMarkerColor(it) }
        defaultClusterColor?.let { builder.setDefaultClusterColor(it) }
        textSize?.let { builder.setTextSize(it) }
        textColor?.let { builder.setTextColor(it) }
        stop1Color?.let { builder.setStop1Color(it) }
        stop2Color?.let { builder.setStop2Color(it) }
        iconPath?.let { path ->
            getBitmapFromAsset(path)?.let { builder.setDefaultMarkerIcon(it) }
        }
        return builder.build()
    }

    private fun buildBorder(
        color: String?,
        width: Float?,
        lineType: String?,
    ): BorderOptions? {
        if (color == null && width == null && lineType == null) return null
        val builder = BorderOptions.Builder()
        color?.let { builder.setBorderColor(it) }
        width?.let { builder.setBorderWidth(it) }
        FlutterArgs.resolveLineType(lineType)?.let { builder.setBorderLineType(it) }
        return builder.build()
    }

    fun onStart() {
        try {
            mapView.onStart()
        } catch (e: Exception) {
            println("OlaMap Error onStart: ${e.message}")
        }
    }

    fun onResume() {
        try {
            mapView.onResume()
        } catch (e: Exception) {
            println("OlaMap Error onResume: ${e.message}")
        }
    }

    fun onPause() {
        try {
            mapView.onPause()
        } catch (e: Exception) {
            println("OlaMap Error onPause: ${e.message}")
        }
    }

    fun onStop() {
        try {
            mapView.onStop()
        } catch (e: Exception) {
            println("OlaMap Error onStop: ${e.message}")
        }
    }

    fun onDestroy() {
        try {
            mapView.onDestroy()
        } catch (e: Exception) {
            println("OlaMap Error onDestroy: ${e.message}")
        }
    }

    fun onLowMemory() {
        try {
            mapView.onLowMemory()
        } catch (e: Exception) {
            println("OlaMap Error onLowMemory: ${e.message}")
        }
    }

    fun onSaveInstanceState(outState: Bundle) {
        try {
            mapView.onSaveInstanceState(outState)
        } catch (e: Exception) {
            println("OlaMap Error onSaveInstanceState: ${e.message}")
        }
    }

    override fun getView(): View = mapView

    override fun dispose() {
        synchronized(this) {
            pendingReadyResult?.error("DISPOSED", "Map view disposed", null)
            pendingReadyResult = null
        }
        mapInstances.remove(id)
        markers.clear()
        polylines.clear()
        circles.clear()
        polygons.clear()
        bezierCurves.clear()
        clusteredMarkers.clear()
        cameraIdleListener = null
        nativeEvents = null
        onPause()
        onStop()
        onDestroy()
        onDisposed(id)
    }
}
