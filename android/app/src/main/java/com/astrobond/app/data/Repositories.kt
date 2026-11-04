package com.astrobond.app.data

import com.astrobond.app.astro.ChartEngine
import com.astrobond.app.domain.*
import io.github.jan.supabase.auth.auth
import io.github.jan.supabase.auth.providers.builtin.Email
import io.github.jan.supabase.postgrest.from
import io.github.jan.supabase.postgrest.postgrest
import io.github.jan.supabase.postgrest.query.Columns
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeoutOrNull
import kotlinx.serialization.json.*
import java.time.Instant
import java.time.LocalDate
import java.time.Period
import java.time.ZoneOffset

data class AppUser(val id: String, val email: String?)

class AppException(message: String) : Exception(message)

internal fun JsonObject.str(k: String): String? = (this[k] as? JsonPrimitive)?.takeIf { it !is JsonNull }?.content
internal fun JsonObject.dbl(k: String): Double? = str(k)?.toDoubleOrNull()
internal fun JsonObject.int(k: String): Int? = dbl(k)?.toInt()
internal fun JsonObject.bool(k: String): Boolean? = str(k)?.toBooleanStrictOrNull()

/** Port of Infrastructure/Auth/AuthService.swift. */
object AuthRepo {
    private val auth get() = Supabase.client.auth

    suspend fun currentUser(): AppUser? = withTimeoutOrNull(12_000) {
        runCatching {
            auth.awaitInitialization()
            auth.currentSessionOrNull()?.user?.let { AppUser(it.id.lowercase(), it.email) }
        }.getOrNull()
    }

    suspend fun signIn(email: String, password: String): AppUser = try {
        auth.signInWith(Email) { this.email = email; this.password = password }
        val u = auth.currentUserOrNull() ?: throw AppException("E-posta veya şifre hatalı.")
        AppUser(u.id.lowercase(), u.email)
    } catch (e: Exception) { throw AppException("E-posta veya şifre hatalı.") }

    suspend fun signUp(email: String, password: String): AppUser = try {
        auth.signUpWith(Email) { this.email = email; this.password = password }
        // Same as iOS: without an active session (e.g. email confirmation required) sign-up fails.
        val u = auth.currentSessionOrNull()?.user ?: throw AppException("E-posta veya şifre hatalı.")
        AppUser(u.id.lowercase(), u.email)
    } catch (e: AppException) { throw e } catch (e: Exception) { throw AppException(e.message ?: "Bağlantı hatası") }

    suspend fun signOut() { try { auth.signOut() } catch (e: Exception) { throw AppException(e.message ?: "Bağlantı hatası") } }

    suspend fun deleteAccount() {
        try { Supabase.client.postgrest.rpc("delete_own_account") } catch (e: Exception) { throw AppException(e.message ?: "Bağlantı hatası") }
    }
}

data class ProfileSnapshot(
    val userId: String, val displayName: String, val age: Int, val gender: Gender, val bio: String,
    val city: String?, val district: String?, val sunSign: ZodiacSign?, val moonSign: ZodiacSign?,
    val risingSign: ZodiacSign?, val photoURL: String?, val cartoonAvatarId: String?, val birthDate: LocalDate?,
    val hasBirthData: Boolean, val timeKnown: Boolean, val timeHour: Int, val timeMinute: Int,
    val latitude: Double?, val longitude: Double?, val utcOffset: Double?, val country: String?,
) {
    val placeLabel: String?
        get() = when {
            city != null && !district.isNullOrEmpty() && district != city -> "$city, $district"
            city != null -> city
            else -> district
        }
}

/** Port of Infrastructure/Profile/ProfileService.swift. Same tables/columns. */
object ProfileRepo {
    private fun err(e: Exception) = AppException(e.message ?: "Bağlantı hatası")

    suspend fun fetchSnapshot(userId: String): ProfileSnapshot? = try {
        val p = Supabase.client.from("profiles")
            .select(Columns.raw("id,display_name,age,gender,bio,city,sun_sign,moon_sign,rising_sign,profile_photo_url,cartoon_avatar_id")) {
                filter { eq("id", userId) }
            }.decodeList<JsonObject>().firstOrNull()
        if (p == null) null else {
            val b = Supabase.client.from("birth_data")
                .select(Columns.raw("user_id,date_of_birth,city,country,time_hour,time_minute,time_known,latitude,longitude,utc_offset")) {
                    filter { eq("user_id", userId) }
                }.decodeList<JsonObject>().firstOrNull()
            val name = p.str("display_name") ?: ""
            ProfileSnapshot(
                userId = (p.str("id") ?: userId).lowercase(), displayName = name, age = p.int("age") ?: 18,
                gender = Gender.fromStableName(p.str("gender")), bio = p.str("bio") ?: "", city = p.str("city"),
                district = b?.str("city"),
                sunSign = ZodiacSign.fromEnglishName(p.str("sun_sign")), moonSign = ZodiacSign.fromEnglishName(p.str("moon_sign")),
                risingSign = ZodiacSign.fromEnglishName(p.str("rising_sign")),
                photoURL = p.str("profile_photo_url"), cartoonAvatarId = p.str("cartoon_avatar_id"),
                birthDate = b?.str("date_of_birth")?.take(10)?.let { runCatching { LocalDate.parse(it) }.getOrNull() },
                hasBirthData = b != null && name.isNotBlank(),
                timeKnown = b?.bool("time_known") ?: false, timeHour = b?.int("time_hour") ?: 12, timeMinute = b?.int("time_minute") ?: 0,
                latitude = b?.dbl("latitude"), longitude = b?.dbl("longitude"), utcOffset = b?.dbl("utc_offset"), country = b?.str("country"),
            )
        }
    } catch (e: Exception) { throw err(e) }

    private fun ageOf(birth: LocalDate) = maxOf(18, Period.between(birth, LocalDate.now()).years)

    suspend fun completeOnboarding(
        userId: String, displayName: String, gender: Gender, birthDate: LocalDate, timeKnown: Boolean,
        hour: Int, minute: Int, city: CityOption, district: District, genderPrefs: List<Gender>, cartoonAvatarId: String,
    ): NatalChart = try {
        val sun = ZodiacSign.sunSign(birthDate.monthValue, birthDate.dayOfMonth)
        Supabase.client.from("profiles").upsert(buildJsonObject {
            put("id", userId); put("display_name", displayName); put("age", ageOf(birthDate)); put("gender", gender.stableName)
            put("bio", ""); put("city", city.name); put("sun_sign", sun.englishName); put("moon_sign", sun.englishName)
            put("rising_sign", sun.englishName); put("cartoon_avatar_id", cartoonAvatarId)
        })
        Supabase.client.from("birth_data").upsert(buildJsonObject {
            put("user_id", userId); put("date_of_birth", birthDate.toString())
            put("time_hour", if (timeKnown) hour else 12); put("time_minute", if (timeKnown) minute else 0)
            put("time_known", timeKnown); put("city", district.name); put("country", city.country)
            put("latitude", district.latitude); put("longitude", district.longitude); put("utc_offset", city.utcOffset)
            putJsonObject("match_preferences") {
                putJsonArray("genderPreferences") { genderPrefs.forEach { add(it.stableName) } }
                put("ageMin", 18); put("ageMax", 99)
            }
        })
        val birth = BirthData(birthDate, if (timeKnown) BirthTime.known(hour, minute) else BirthTime.UNKNOWN,
            BirthLocation(district.name, city.country, district.latitude, district.longitude, city.utcOffset))
        ChartRepo.calculateAndSave(userId, birth)
    } catch (e: AppException) { throw e } catch (e: Exception) { throw err(e) }

    suspend fun updateProfile(
        userId: String, displayName: String, bio: String, city: CityOption, district: District,
        birthDate: LocalDate?, cartoonAvatarId: String? = null,
    ) {
        try {
            val sun = birthDate?.let { ZodiacSign.sunSign(it.monthValue, it.dayOfMonth) } ?: ZodiacSign.ARIES
            Supabase.client.from("profiles").update(buildJsonObject {
                put("display_name", displayName); put("age", birthDate?.let(::ageOf) ?: 18); put("bio", bio)
                put("city", city.name); put("sun_sign", sun.englishName)
                if (cartoonAvatarId != null) put("cartoon_avatar_id", cartoonAvatarId)
            }) { filter { eq("id", userId) } }
            Supabase.client.from("birth_data").update(buildJsonObject {
                put("city", district.name); put("country", city.country); put("latitude", district.latitude)
                put("longitude", district.longitude); put("utc_offset", city.utcOffset)
                if (birthDate != null) put("date_of_birth", birthDate.toString())
            }) { filter { eq("user_id", userId) } }
            if (birthDate != null) {
                val time = runCatching { ChartRepo.fetchBirthData(userId)?.time }.getOrNull() ?: BirthTime.UNKNOWN
                ChartRepo.calculateAndSave(userId, BirthData(birthDate, time,
                    BirthLocation(district.name, city.country, district.latitude, district.longitude, city.utcOffset)))
            }
        } catch (e: AppException) { throw e } catch (e: Exception) { throw err(e) }
    }

    suspend fun setFrozen(userId: String, frozen: Boolean) {
        try {
            Supabase.client.from("profiles").update(buildJsonObject {
                if (frozen) put("frozen_at", java.time.format.DateTimeFormatter.ISO_INSTANT.format(Instant.now()))
                else put("frozen_at", JsonNull)
            }) { filter { eq("id", userId) } }
        } catch (e: Exception) { throw err(e) }
    }
}

/** Port of Infrastructure/Astrology/ChartService.swift. Rows live in `charts` (public) + `birth_data` (owner only). */
object ChartRepo {
    const val ENGINE_VERSION = "swiss-ephemeris-v5"

    private fun isFull(c: NatalChart) = c.planets.size >= 10 && c.aspects.isNotEmpty()

    suspend fun fetch(userId: String): NatalChart? = try {
        val row = Supabase.client.from("charts").select(Columns.raw("user_id,chart_json,engine_version")) {
            filter { eq("user_id", userId) }
        }.decodeList<JsonObject>().firstOrNull()
        val json = row?.get("chart_json") as? JsonObject
        if (row == null || json == null || row.str("engine_version") != ENGINE_VERSION) null
        else ChartJson.decode(json).takeIf(::isFull)
    } catch (e: Exception) { null }

    suspend fun ensureOwnChart(userId: String): NatalChart? {
        fetch(userId)?.let { return it }
        val birth = fetchBirthData(userId) ?: return null
        return calculateAndSave(userId, birth)
    }

    suspend fun calculateAndSave(userId: String, birth: BirthData): NatalChart {
        val chart = withContext(Dispatchers.Default) { ChartEngine.calculateNatalChart(birth, userId) }
        save(chart)
        return chart
    }

    private suspend fun save(chart: NatalChart) {
        try {
            Supabase.client.from("charts").upsert(buildJsonObject {
                put("user_id", chart.userId)
                put("chart_json", ChartJson.encodeStripped(chart))
                put("engine_version", ENGINE_VERSION)
            })
            val signs = buildJsonObject {
                put("sun_sign", chart.sunSign.englishName); put("moon_sign", chart.moonSign.englishName)
                put("rising_sign", chart.risingSign.englishName)
            }
            try {
                Supabase.client.from("profiles").update(JsonObject(signs + ("dominant_element" to JsonPrimitive(chart.dominantElement.labelTR)))) {
                    filter { eq("id", chart.userId) }
                }
            } catch (e: Exception) {
                Supabase.client.from("profiles").update(signs) { filter { eq("id", chart.userId) } }
            }
        } catch (e: Exception) { throw AppException("Kayıt hatası: ${e.message}") }
    }

    suspend fun fetchBirthData(userId: String): BirthData? {
        val r = Supabase.client.from("birth_data")
            .select(Columns.raw("date_of_birth,time_hour,time_minute,time_known,city,country,latitude,longitude,utc_offset")) {
                filter { eq("user_id", userId) }
            }.decodeList<JsonObject>().firstOrNull() ?: return null
        val date = r.str("date_of_birth")?.take(10)?.let { runCatching { LocalDate.parse(it) }.getOrNull() } ?: return null
        val known = r.bool("time_known") ?: false
        return BirthData(date, if (known) BirthTime.known(r.int("time_hour") ?: 12, r.int("time_minute") ?: 0) else BirthTime.UNKNOWN,
            BirthLocation(r.str("city") ?: "", r.str("country") ?: "", r.dbl("latitude") ?: 0.0, r.dbl("longitude") ?: 0.0, r.dbl("utc_offset") ?: 0.0))
    }
}
