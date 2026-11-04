package com.astrobond.app

import com.astrobond.app.discover.DailyNoteEngine
import com.astrobond.app.domain.ZodiacSign
import org.junit.Assert.assertEquals
import org.junit.Test
import java.time.LocalDate

/** Expected values were produced by running the iOS `DailyNoteEngine` seed/RNG recipe in Swift. */
class DailyNoteParityTest {
    @Test
    fun matchesSwiftOutput() {
        // 2026-11-04 is day-of-year 308.
        val n = DailyNoteEngine.note(LocalDate.of(2026, 11, 4), "u1", ZodiacSign.LEO, ZodiacSign.CANCER, ZodiacSign.VIRGO)
        assertEquals("İçe Dönüş", n.focus)
        assertEquals("Gümüş", n.luckyHue)
        assertEquals(58, n.energyScore)
    }
}
