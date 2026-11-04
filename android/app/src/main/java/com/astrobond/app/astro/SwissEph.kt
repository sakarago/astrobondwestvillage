package com.astrobond.app.astro

import android.content.Context
import java.io.File

/** Thin JNI wrapper over the Swiss Ephemeris C library (same sources as the iOS package). */
object SwissEph {
    private var ready = false

    init { System.loadLibrary("astrobond_swe") }

    private external fun nativeSetPath(path: String)
    private external fun nativeCalcUt(jd: Double, body: Int, flags: Int): DoubleArray
    private external fun nativeHouses(jd: Double, lat: Double, lon: Double, hsys: Int): DoubleArray

    const val SEFLG_SPEED = 256

    /** Copies the bundled ephemeris files from assets to filesDir/ephe once and points the library at it. */
    @Synchronized
    fun init(context: Context) {
        if (ready) return
        val dir = File(context.filesDir, "ephe").apply { mkdirs() }
        context.assets.list("ephe")?.forEach { name ->
            val out = File(dir, name)
            if (!out.exists() || out.length() == 0L) {
                context.assets.open("ephe/$name").use { i -> out.outputStream().use { o -> i.copyTo(o) } }
            }
        }
        nativeSetPath(dir.absolutePath)
        ready = true
    }

    class Body(val longitude: Double, val speedLongitude: Double)

    fun calc(jdUt: Double, planetId: Int): Body {
        check(ready) { "SwissEph.init not called" }
        val r = nativeCalcUt(jdUt, planetId, SEFLG_SPEED)
        return Body(r[0], r[3])
    }

    /** Placidus ('P'). Returns cusps[1..12] mapped to 0..11, asc, mc. */
    class Houses(val cusps: DoubleArray, val asc: Double, val mc: Double)

    fun placidus(jdUt: Double, lat: Double, lon: Double): Houses {
        check(ready) { "SwissEph.init not called" }
        val r = nativeHouses(jdUt, lat, lon, 'P'.code)
        return Houses(DoubleArray(12) { r[it + 1] }, r[13], r[14])
    }
}
