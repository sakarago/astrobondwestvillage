package com.astrobond.app

import android.app.Application
import android.util.Log
import com.astrobond.app.astro.SwissEph

class AstroBondApp : Application() {
    override fun onCreate() {
        super.onCreate()
        SwissEph.init(this)
        if (BuildConfig.DEBUG) {
            // Sanity check: at J2000.0 (JD 2451545.0) the Sun is at ~280.37° and the Moon at ~223.32°.
            Log.d("AstroBond", "J2000 sun=${SwissEph.calc(2451545.0, 0).longitude} moon=${SwissEph.calc(2451545.0, 1).longitude}")
        }
    }
}
