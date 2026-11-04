package com.astrobond.app.domain

/** Port of Infrastructure/Messaging/ConversationQuestions.swift (hand-written bank; no on-device AI on Android yet). */
enum class QuestionCategory(val title: String, val subtitle: String, val emoji: String) {
    LOVE("Aşk & İlişki", "Duygular, bağ, romantizm", "♡"),
    PERSONAL("Kişisel", "Kendini tanıma, hayata bakış", "☾"),
    LIFESTYLE("Yaşam Tarzı", "Günlük yaşam, alışkanlıklar", "☀"),
    VALUES("Değerler", "İnançlar, öncelikler", "❦"),
    FUN("Eğlenceli", "Hafif ve keyifli sorular", "◍"),
    ALL("Hepsi", "Sürpriz soru", "✦");
}

object ConversationQuestions {
    val bank: Map<QuestionCategory, List<String>> = mapOf(
        QuestionCategory.LOVE to listOf(
            "Bir ilişkide kendini en çok ne zaman güvende hissedersin?",
            "Sence aşkta en önemli şey nedir: tutku mu, güven mi?",
            "İlk buluşmada seni en çok ne etkiler?",
            "Sevgini en çok nasıl gösterirsin?",
            "Bir ilişkide asla taviz vermeyeceğin şey ne?",
            "İlk bakışta aşka inanır mısın?",
            "Romantik bir akşam senin için nasıl geçer?",
            "Bir ilişkide en çok neyi özlersin: ilgiyi mi, zamanı mı?",
            "Hayatındaki en güzel sürpriz ne oldu?",
            "Kıskançlık sende nasıl görünür?",
            "Birini gerçekten tanımak için sence ne kadar zaman gerekir?",
            "Aşkta ilk adımı atan taraf olmak sana nasıl hissettirir?",
        ),
        QuestionCategory.PERSONAL to listOf(
            "Seni en iyi anlatan üç kelime ne olurdu?",
            "Son zamanlarda kendinle ilgili öğrendiğin bir şey ne?",
            "Zor bir günde seni ne toparlar?",
            "Geçmişteki kendine ne söylemek isterdin?",
            "Seni en çok ne korkutur, en çok ne cesaretlendirir?",
            "Yalnız kalmak sana iyi gelir mi, yoksa yorar mı?",
            "Hayatında dönüm noktası dediğin an hangisiydi?",
            "Başkalarının seni yanlış anladığı yön ne?",
            "Kendinle gurur duyduğun son an neydi?",
            "Beş yıl sonra kendini nerede görüyorsun?",
            "Hangi huyunu değiştirmek isterdin?",
            "Seni en çok ne düşündürür?",
        ),
        QuestionCategory.LIFESTYLE to listOf(
            "Mükemmel bir hafta sonu senin için nasıl geçer?",
            "Sabah insanı mısın, gece kuşu mu?",
            "Evde mi, dışarıda mı daha mutlusun?",
            "Günün en sevdiğin saati hangisi?",
            "Vazgeçemediğin bir alışkanlığın var mı?",
            "Tatilde plan mı yaparsın, akışa mı bırakırsın?",
            "Yemek yapmayı sever misin? En iyi yaptığın yemek ne?",
            "Müzik açmadan yola çıkabilir misin?",
            "Son izlediğin ve etkilendiğin film ya da dizi neydi?",
            "Doğada vakit geçirmek senin için ne ifade eder?",
            "Hayalindeki ev nasıl bir yer?",
            "Haftanın en sevdiğin günü hangisi, neden?",
        ),
        QuestionCategory.VALUES to listOf(
            "Hayatta senin için vazgeçilmez olan değer nedir?",
            "Dürüstlük mü, nezaket mi? Biri seçilmek zorunda kalsa?",
            "Sence insanı insan yapan şey ne?",
            "Aile senin için ne kadar önemli?",
            "Para mı, zaman mı daha değerli?",
            "Bir arkadaşlıkta en çok neye değer verirsin?",
            "Affetmek sence güç müdür, zayıflık mı?",
            "Hayatta pişman olmamak için ne yaparsın?",
            "Sana göre başarı nedir?",
            "Kaderin varlığına inanır mısın?",
            "Bir insanda gördüğün anda uzaklaştıran şey ne?",
            "Başkaları için yaptığın en anlamlı şey neydi?",
        ),
        QuestionCategory.FUN to listOf(
            "Bir süper gücün olsa hangisini seçerdin?",
            "Dünyanın herhangi bir yerinde bir hafta geçirebilsen nereye giderdin?",
            "Tarihten biriyle yemek yeseydin kim olurdu?",
            "Seni en çok güldüren şey nedir?",
            "Hayvan olsaydın hangisi olurdun?",
            "Ücretsiz sınırsız bir şey yiyebilseydin ne olurdu?",
            "Çocukken en sevdiğin çizgi film hangisiydi?",
            "Sadece bir şarkıyla yaşasan hangisi olurdu?",
            "En komik utanç anın ne?",
            "Burcunun sana en çok uyan özelliği hangisi?",
            "Yarın tatil ilan edilse ilk ne yaparsın?",
            "Bir günlüğüne başka biri olsan kim olurdun?",
        ),
    )

    fun random(category: QuestionCategory, excluding: String? = null): String {
        val pool = if (category == QuestionCategory.ALL) bank.values.flatten() else bank[category].orEmpty()
        return pool.filter { it != excluding }.randomOrNull() ?: pool.firstOrNull() ?: ""
    }
}
