package com.astrobond.app.ui.profile

import com.astrobond.app.domain.*

/** Port of `AstralReadings` (Features/Profile/ProfileHomeView.swift). */
object AstralReadings {
    private val domain = mapOf(
        Planet.SUN to "Güneş; öz benliğini, yaşam gücünü ve içindeki ışığı temsil eder",
        Planet.MOON to "Ay; duygusal dünyanı, içgüdülerini ve güvende hissettiğin yeri temsil eder",
        Planet.MERCURY to "Merkür; düşünme ve iletişim biçimini, zihninin ritmini temsil eder",
        Planet.VENUS to "Venüs; sevme biçimini, estetik anlayışını ve neye değer verdiğini temsil eder",
        Planet.MARS to "Mars; arzunu, irade gücünü ve harekete geçiş tarzını temsil eder",
        Planet.JUPITER to "Jüpiter; büyüme alanlarını, inancını ve şansının aktığı yönü temsil eder",
        Planet.SATURN to "Satürn; sorumluluklarını, sınırlarını ve olgunlaşma derslerini temsil eder",
        Planet.URANUS to "Uranüs; özgünlüğünü, ani uyanışlarını ve özgürlük ihtiyacını temsil eder",
        Planet.NEPTUNE to "Neptün; hayal gücünü, sezgini ve ruhsal özlemini temsil eder",
        Planet.PLUTO to "Plüton; dönüşüm gücünü, gölgeni ve yeniden doğuş kapasiteni temsil eder",
    )

    private val voice = mapOf(
        ZodiacSign.ARIES to "Koç burcunda bu enerji cesur, doğrudan ve başlatıcıdır; beklemeyi sevmez, önce hamle yapar. İçindeki kıvılcım seni öncülüğe ve cesur risklere çağırır.",
        ZodiacSign.TAURUS to "Boğa burcunda bu enerji sabırlı, kararlı ve duyusaldır; aceleye gelmez, sağlam temeller kurar. İstikrar ve gerçek değer arayışı seni dengeye taşır.",
        ZodiacSign.GEMINI to "İkizler burcunda bu enerji meraklı, çevik ve iletişimcidir; fikirler arasında hızla gezinir. Çok yönlülüğün, öğrenme ve bağ kurma yeteneğini besler.",
        ZodiacSign.CANCER to "Yengeç burcunda bu enerji derin duygusal, koruyucu ve sezgiseldir; kalpten hareket eder. Güven ve aidiyet ihtiyacın seni şefkatli bir limana dönüştürür.",
        ZodiacSign.LEO to "Aslan burcunda bu enerji ışıltılı, cömert ve yaratıcıdır; görünmek ve ilham vermek ister. İçindeki sıcaklık ve gurur, sahneyi doğal biçimde sana açar.",
        ZodiacSign.VIRGO to "Başak burcunda bu enerji analitik, titiz ve hizmet odaklıdır; detayda mükemmeli arar. Pratik zekân, kaosu düzene çeviren sessiz bir güç taşır.",
        ZodiacSign.LIBRA to "Terazi burcunda bu enerji uyumlu, estetik ve adildir; denge ve ilişki üzerinden var olur. Diplomatik inceliğin, karşındakini görme yeteneğinden doğar.",
        ZodiacSign.SCORPIO to "Akrep burcunda bu enerji yoğun, tutkulu ve dönüştürücüdür; yüzeyle yetinmez, derine iner. Sezgilerin ve kararlılığın, gölgeyi güce çevirme kapasitesi verir.",
        ZodiacSign.SAGITTARIUS to "Yay burcunda bu enerji iyimser, maceracı ve felsefidir; ufuklar seni çağırır. Özgürlük ve anlam arayışın, hayata geniş bir vizyonla bakmanı sağlar.",
        ZodiacSign.CAPRICORN to "Oğlak burcunda bu enerji disiplinli, hedef odaklı ve dayanıklıdır; uzun vadeyi görür. Sabrın ve sorumluluk duygun, zamanla sağlam bir otorite inşa eder.",
        ZodiacSign.AQUARIUS to "Kova burcunda bu enerji yenilikçi, bağımsız ve insancıldır; alışılmışın dışında düşünür. Özgün bakışın, geleceği bugünden sezme yeteneğiyle birleşir.",
        ZodiacSign.PISCES to "Balık burcunda bu enerji sezgisel, empatik ve hayalperesttir; sınırlar onda yumuşar. Sanatsal ve ruhsal derinliğin, dünyayı kalbinle hissetmeni sağlar.",
    )

    private val flavor = mapOf(
        ZodiacSign.ARIES to "atılgan ve öncü",
        ZodiacSign.TAURUS to "sabırlı ve istikrarlı",
        ZodiacSign.GEMINI to "meraklı ve çok yönlü",
        ZodiacSign.CANCER to "duygusal ve koruyucu",
        ZodiacSign.LEO to "gururlu ve cömert",
        ZodiacSign.VIRGO to "titiz ve çözüm odaklı",
        ZodiacSign.LIBRA to "dengeli ve uyumlu",
        ZodiacSign.SCORPIO to "yoğun ve dönüştürücü",
        ZodiacSign.SAGITTARIUS to "özgür ve idealist",
        ZodiacSign.CAPRICORN to "disiplinli ve hırslı",
        ZodiacSign.AQUARIUS to "yenilikçi ve bağımsız",
        ZodiacSign.PISCES to "sezgisel ve şefkatli",
    )

    private val houseBase = mapOf(
        1 to "Birinci ev kimliğini, dış görünüşünü ve dünyaya verdiğin ilk izlenimi yönetir.",
        2 to "İkinci ev değerlerini, maddi kaynaklarını ve kendine biçtiğin değeri yönetir.",
        3 to "Üçüncü ev iletişim tarzını, öğrenme biçimini ve yakın çevrenle bağını yönetir.",
        4 to "Dördüncü ev evini, aile köklerini ve içsel güvenlik ihtiyacını yönetir.",
        5 to "Beşinci ev yaratıcılığını, romantik ifadeni ve hayattan aldığın hazzı yönetir.",
        6 to "Altıncı ev günlük rutinlerini, sağlığını ve çalışma disiplinini yönetir.",
        7 to "Yedinci ev ilişkilerini, ortaklıklarını ve bir partnerde aradıklarını yönetir.",
        8 to "Sekizinci ev dönüşümünü, paylaşılan kaynakları ve duygusal derinliğini yönetir.",
        9 to "Dokuzuncu ev inanç sistemini, uzak ufukları ve hayata bakış açını yönetir.",
        10 to "Onuncu ev kariyerini, toplumsal kimliğini ve otoriteyle ilişkini yönetir.",
        11 to "On birinci ev dostluklarını, topluluk içindeki yerini ve gelecek vizyonunu yönetir.",
        12 to "On ikinci ev bilinçaltını, gizli güçlerini ve ruhsal dünyanı yönetir.",
    )

    fun planet(p: Planet, sign: ZodiacSign) = "${domain.getValue(p)}. ${voice.getValue(sign)}"
    fun house(house: Int, sign: ZodiacSign) = "${houseBase[house] ?: ""} ${sign.labelTR} burcunun yönetiminde, bu alana ${flavor.getValue(sign)} bir nitelik katarsın."

    fun aspect(a: AspectEntity): String {
        val p1 = a.planet1.tr; val p2 = a.planet2.tr
        return when (a.type) {
            AspectType.CONJUNCTION -> "$p1 ve $p2 gökyüzünde aynı noktada birleşir; bu iki gücün enerjisi ayrılmaz biçimde harmanlanır. Hayatında bu temalar birlikte hareket eder, biri uyandığında diğeri de devreye girer. Bu birleşimi bilinçli yönetmek, onu en parlak gücüne dönüştürür."
            AspectType.TRINE -> "$p1 ile $p2 arasında doğal ve akıcı bir uyum vardır; bu yetenek sana neredeyse çaba harcamadan gelir. İki gezegenin enerjisi birbirini besler ve zorlanmadan akar. Bu armağanı bilinçli kullandığında gerçek bir üstünlüğe dönüşür."
            AspectType.SEXTILE -> "$p1 ile $p2 sana fırsat kapıları açan destekleyici bir açı kurar. Uyum kendiliğinden gelmez ama küçük bir adımla harekete geçer. İnisiyatif aldığında bu potansiyel somut sonuçlara evrilir."
            AspectType.SQUARE -> "$p1 ile $p2 arasında yaratıcı bir gerilim vardır; bu sürtünme seni rahatsız ettiği kadar büyütür de. İki güç birbirini zorlar ve bu içsel çekişme, üzerinde çalıştıkça olgunlaşır. Direncini ustalığa çevirmek bu açının asıl dersidir."
            AspectType.OPPOSITION -> "$p1 ile $p2 karşı kutuplarda durur ve senden bir denge bulmanı ister. Bu eksen çoğu zaman ilişkiler üzerinden, başkalarının aynasında belirginleşir. İki ucu birbirine düşman değil tamamlayıcı görmek, bu açıyı bilgeliğe taşır."
        }
    }
}
