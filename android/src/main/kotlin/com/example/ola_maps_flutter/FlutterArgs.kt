package com.example.ola_maps_flutter

import com.ola.mapsdk.model.LineType
import com.ola.mapsdk.model.OlaLatLng
import io.flutter.plugin.common.MethodCall

internal object FlutterArgs {
    fun asDouble(value: Any?): Double? = (value as? Number)?.toDouble()

    fun asFloat(value: Any?): Float? = (value as? Number)?.toFloat()

    fun asInt(value: Any?): Int? = (value as? Number)?.toInt()

    fun asBool(value: Any?, default: Boolean = false): Boolean = value as? Boolean ?: default

    fun asString(value: Any?): String? = value as? String

    fun callDouble(call: MethodCall, key: String): Double? = asDouble(call.argument(key))

    fun callFloat(call: MethodCall, key: String): Float? = asFloat(call.argument(key))

    fun callInt(call: MethodCall, key: String): Int? = asInt(call.argument(key))

    fun callBool(call: MethodCall, key: String, default: Boolean = false): Boolean =
        asBool(call.argument(key), default)

    fun mapDouble(map: Map<*, *>?, key: String): Double? = asDouble(map?.get(key))

    fun mapBool(map: Map<*, *>?, key: String, default: Boolean): Boolean =
        asBool(map?.get(key), default)

    fun mapString(map: Map<*, *>?, key: String): String? = asString(map?.get(key))

    fun points(value: Any?): ArrayList<OlaLatLng> {
        val list = value as? List<*> ?: return ArrayList()
        val result = ArrayList<OlaLatLng>(list.size)
        for (item in list) {
            val map = item as? Map<*, *> ?: continue
            val lat = asDouble(map["latitude"]) ?: continue
            val lng = asDouble(map["longitude"]) ?: continue
            result.add(OlaLatLng(lat, lng))
        }
        return result
    }

    fun floatArray(value: Any?): Array<Float>? {
        val list = value as? List<*> ?: return null
        if (list.size < 2) return null
        val first = asFloat(list[0]) ?: return null
        val second = asFloat(list[1]) ?: return null
        return arrayOf(first, second)
    }

    fun resolveLineType(value: String?): String? {
        if (value == null) return null
        return when (value.uppercase()) {
            "SOLID", "LINE_SOLID" -> LineType.LINE_SOLID
            "DOTTED", "LINE_DOTTED" -> LineType.LINE_DOTTED
            else -> value
        }
    }
}
