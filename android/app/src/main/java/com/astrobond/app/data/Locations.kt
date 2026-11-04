package com.astrobond.app.data

import android.content.Context
import kotlinx.serialization.json.*

/** Port of Domain/TurkeyLocations.swift; data lives in assets/locations.json (generated from the Swift source). */
data class District(val id: String, val name: String, val latitude: Double, val longitude: Double)

data class CityOption(val id: String, val name: String, val country: String, val utcOffset: Double, val districts: List<District>) {
    override fun equals(other: Any?) = other is CityOption && other.id == id
    override fun hashCode() = id.hashCode()

    companion object {
        private var cache: List<CityOption>? = null

        fun presets(context: Context): List<CityOption> = cache ?: synchronized(this) {
            cache ?: load(context).also { cache = it }
        }

        private fun load(context: Context): List<CityOption> {
            val text = context.assets.open("locations.json").bufferedReader().use { it.readText() }
            return Json.parseToJsonElement(text).jsonArray.map { e ->
                val o = e.jsonObject
                val id = o["id"]!!.jsonPrimitive.content
                CityOption(
                    id, o["name"]!!.jsonPrimitive.content, o["country"]!!.jsonPrimitive.content,
                    o["utc"]!!.jsonPrimitive.double,
                    o["d"]!!.jsonArray.map { d ->
                        val dd = d.jsonObject
                        val n = dd["name"]!!.jsonPrimitive.content
                        District("$id|$n", n, dd["lat"]!!.jsonPrimitive.double, dd["lon"]!!.jsonPrimitive.double)
                    },
                )
            }
        }

        fun default(context: Context) = presets(context).first { it.id == "istanbul" }

        /** Reverse-maps a stored `birth_data.city` (district name) to a city (prefers `metropolitan`). */
        fun containing(context: Context, district: String, metropolitan: String? = null): CityOption? {
            val all = presets(context)
            if (metropolitan != null) all.firstOrNull { it.name == metropolitan }?.let { return it }
            return all.firstOrNull { c -> c.districts.any { it.name == district } }
        }
    }
}
