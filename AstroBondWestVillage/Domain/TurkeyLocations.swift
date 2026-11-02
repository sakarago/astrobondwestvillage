import Foundation

extension CityOption {
    static let turkey: [CityOption] = [
        .init(id: "adana", name: "Adana", country: "Türkiye", utcOffset: 3, districts: [
            d("adana", "Aladağ", 37.5468, 35.3951), d("adana", "Ceyhan", 37.0289, 35.8178),
            d("adana", "Çukurova", 37.0485, 35.2805), d("adana", "Feke", 37.8149, 35.9125),
            d("adana", "İmamoğlu", 37.2571, 35.6620), d("adana", "Karaisalı", 37.2571, 35.0587),
            d("adana", "Karataş", 36.5627, 35.3851), d("adana", "Kozan", 37.4635, 35.8256),
            d("adana", "Pozantı", 37.4231, 34.8724), d("adana", "Saimbeyli", 37.9914, 36.0901),
            d("adana", "Sarıçam", 37.0332, 35.4124), d("adana", "Seyhan", 36.9976, 35.3013),
            d("adana", "Tufanbeyli", 38.2613, 36.2213), d("adana", "Yumurtalık", 36.7674, 35.7917),
            d("adana", "Yüreğir", 36.9971, 35.3581)
        ]),
        .init(id: "adiyaman", name: "Adıyaman", country: "Türkiye", utcOffset: 3, districts: [
            d("adiyaman", "Merkez", 37.7636, 38.2772), d("adiyaman", "Besni", 37.6940, 37.8616),
            d("adiyaman", "Çelikhan", 38.0332, 38.2423), d("adiyaman", "Gerger", 38.0294, 39.0332),
            d("adiyaman", "Gölbaşı", 37.7847, 37.6437), d("adiyaman", "Kahta", 37.7860, 38.6215),
            d("adiyaman", "Samsat", 37.5794, 38.4826), d("adiyaman", "Sincik", 38.0292, 38.6194),
            d("adiyaman", "Tut", 37.7953, 37.9137)
        ]),
        .init(id: "afyonkarahisar", name: "Afyonkarahisar", country: "Türkiye", utcOffset: 3, districts: [
            d("afyonkarahisar", "Merkez", 38.7568, 30.5387), d("afyonkarahisar", "Başmakçı", 37.8974, 30.0100),
            d("afyonkarahisar", "Bayat", 38.9841, 30.9240), d("afyonkarahisar", "Bolvadin", 38.7105, 31.0478),
            d("afyonkarahisar", "Çay", 38.5925, 31.0273), d("afyonkarahisar", "Çobanlar", 38.7015, 30.7815),
            d("afyonkarahisar", "Dazkırı", 37.9193, 29.8606), d("afyonkarahisar", "Dinar", 38.0670, 30.1678),
            d("afyonkarahisar", "Emirdağ", 39.0196, 31.1503), d("afyonkarahisar", "Evciler", 38.0389, 29.8884),
            d("afyonkarahisar", "Hocalar", 38.5728, 29.9669), d("afyonkarahisar", "İhasaniye", 39.0320, 30.4168),
            d("afyonkarahisar", "İscehisar", 38.8620, 30.7509), d("afyonkarahisar", "Kızılören", 38.2578, 30.1491),
            d("afyonkarahisar", "Sandıklı", 38.4649, 30.2693), d("afyonkarahisar", "Sinanpaşa", 38.7452, 30.2455),
            d("afyonkarahisar", "Şuhut", 38.5357, 30.5503), d("afyonkarahisar", "Sultandağı", 38.5302, 31.2294)
        ]),
        .init(id: "agri", name: "Ağrı", country: "Türkiye", utcOffset: 3, districts: [
            d("agri", "Merkez", 39.7078, 43.0494), d("agri", "Diyadin", 39.5398, 43.6712),
            d("agri", "Doğubayazit", 39.5484, 44.0811), d("agri", "Eleşkirt", 39.7983, 42.6773),
            d("agri", "Hamur", 39.6094, 42.9883), d("agri", "Patnos", 39.2395, 42.8629),
            d("agri", "Taşlıçay", 39.6348, 43.3761), d("agri", "Tutak", 39.5394, 42.7729)
        ]),
        .init(id: "amasya", name: "Amasya", country: "Türkiye", utcOffset: 3, districts: [
            d("amasya", "Merkez", 40.6518, 35.8345), d("amasya", "Göynücek", 40.3976, 35.5237),
            d("amasya", "Gümüşhacıköy", 40.8737, 35.2157), d("amasya", "Hamamözü", 40.7829, 35.0231),
            d("amasya", "Merzifon", 40.8725, 35.4636), d("amasya", "Suluova", 40.8345, 35.6452),
            d("amasya", "Taşova", 40.7604, 36.3219)
        ]),
        .init(id: "ankara", name: "Ankara", country: "Türkiye", utcOffset: 3, districts: [
            d("ankara", "Akyurt", 40.1309, 33.0865), d("ankara", "Altındağ", 39.9351, 32.8517),
            d("ankara", "Ayaş", 40.0196, 32.3326), d("ankara", "Bala", 39.5531, 33.1239),
            d("ankara", "Beypazarı", 40.1680, 31.9207), d("ankara", "Çamlıdere", 40.4914, 32.4760),
            d("ankara", "Çankaya", 39.9200, 32.8534), d("ankara", "Çubuk", 40.2387, 33.0326),
            d("ankara", "Elmadağ", 39.9227, 33.2265), d("ankara", "Etimesgut", 39.9471, 32.6600),
            d("ankara", "Evren", 39.0226, 33.8070), d("ankara", "Gölbaşı", 39.7899, 32.8036),
            d("ankara", "Güdül", 40.2102, 32.2433), d("ankara", "Haymana", 39.4341, 32.5014),
            d("ankara", "Kahramankazan", 40.2053, 32.6806), d("ankara", "Kalecik", 40.0970, 33.4090),
            d("ankara", "Keçiören", 39.9778, 32.8678), d("ankara", "Kızılcahamam", 40.4719, 32.6482),
            d("ankara", "Mamak", 39.9349, 32.8953), d("ankara", "Nallıhan", 40.1887, 31.3503),
            d("ankara", "Polatlı", 39.5848, 32.1421), d("ankara", "Pursaklar", 40.1052, 32.8839),
            d("ankara", "Şereflikoçhisar", 38.9389, 33.5439), d("ankara", "Sincan", 39.9624, 32.5802),
            d("ankara", "Yenimahalle", 39.9623, 32.8102)
        ]),
        .init(id: "antalya", name: "Antalya", country: "Türkiye", utcOffset: 3, districts: [
            d("antalya", "Akseki", 37.0458, 31.7900), d("antalya", "Aksu", 36.9486, 30.8474),
            d("antalya", "Alanya", 36.5365, 31.9987), d("antalya", "Demre", 36.2419, 29.9858),
            d("antalya", "Döşemealtı", 37.0229, 30.6012), d("antalya", "Elmalı", 36.7377, 29.9167),
            d("antalya", "Finike", 36.2984, 30.1468), d("antalya", "Gazipaşa", 36.2684, 32.3145),
            d("antalya", "Gündoğmuş", 36.8129, 31.9996), d("antalya", "İbradı", 37.0957, 31.5955),
            d("antalya", "Kaş", 36.1993, 29.6413), d("antalya", "Kemer", 36.6019, 30.5592),
            d("antalya", "Kepez", 36.9152, 30.7158), d("antalya", "Konyaaltı", 36.8649, 30.6422),
            d("antalya", "Korkuteli", 37.0652, 30.1961), d("antalya", "Kumluca", 36.3669, 30.2858),
            d("antalya", "Manavgat", 36.7865, 31.4468), d("antalya", "Muratpaşa", 36.8520, 30.7573),
            d("antalya", "Serik", 36.9172, 31.1044)
        ]),
        .init(id: "artvin", name: "Artvin", country: "Türkiye", utcOffset: 3, districts: [
            d("artvin", "Merkez", 41.1824, 41.8158), d("artvin", "Ardanuç", 41.1214, 42.0670),
            d("artvin", "Arhavi", 41.3500, 41.3054), d("artvin", "Borçka", 41.3584, 41.6765),
            d("artvin", "Hopa", 41.3923, 41.4229), d("artvin", "Kemalpaşa", 41.4813, 41.5263),
            d("artvin", "Murgul", 41.2783, 41.5617), d("artvin", "Şavşat", 41.2528, 42.3556),
            d("artvin", "Yusufeli", 40.8107, 41.5271)
        ]),
        .init(id: "aydin", name: "Aydın", country: "Türkiye", utcOffset: 3, districts: [
            d("aydin", "Bozdağan", 37.6711, 28.3087), d("aydin", "Buharkent", 37.9649, 28.7425),
            d("aydin", "Çine", 37.6105, 28.0594), d("aydin", "Didim", 37.3552, 27.2771),
            d("aydin", "Efeler", 37.8676, 27.9004), d("aydin", "Germencik", 37.8728, 27.5982),
            d("aydin", "İncirliova", 37.8534, 27.7235), d("aydin", "Karacasu", 37.7265, 28.6037),
            d("aydin", "Karpuzlu", 37.5614, 27.8367), d("aydin", "Koçarlı", 37.7607, 27.7064),
            d("aydin", "Köşk", 37.8535, 28.0522), d("aydin", "Kuşadası", 37.8695, 27.2645),
            d("aydin", "Kuyucak", 37.9141, 28.4602), d("aydin", "Nazilli", 37.9097, 28.3242),
            d("aydin", "Söke", 37.7504, 27.4113), d("aydin", "Sultanhisar", 37.8900, 28.1542),
            d("aydin", "Yenipazar", 37.8233, 28.1957)
        ]),
        .init(id: "balikesir", name: "Balıkesir", country: "Türkiye", utcOffset: 3, districts: [
            d("balikesir", "Altıeylül", 39.6316, 27.8879), d("balikesir", "Ayvalık", 39.3180, 26.6915),
            d("balikesir", "Balya", 39.7498, 27.5788), d("balikesir", "Bandırma", 40.2885, 27.9624),
            d("balikesir", "Bigadiç", 39.3929, 28.1312), d("balikesir", "Burhaniye", 39.5028, 26.9804),
            d("balikesir", "Dursunbey", 39.5850, 28.6268), d("balikesir", "Edremit", 39.5920, 27.0202),
            d("balikesir", "Erdek", 40.3953, 27.7912), d("balikesir", "Gömeç", 39.3650, 26.8686),
            d("balikesir", "Gönen", 40.1046, 27.6523), d("balikesir", "Havran", 39.5590, 27.0970),
            d("balikesir", "İvrindi", 39.5819, 27.4853), d("balikesir", "Karesi", 39.6609, 27.8849),
            d("balikesir", "Kepsut", 39.6853, 28.1599), d("balikesir", "Manyas", 40.0467, 27.9697),
            d("balikesir", "Marmara", 40.5871, 27.5534), d("balikesir", "Savaştepe", 39.3826, 27.6502),
            d("balikesir", "Sındırgı", 39.2391, 28.1749), d("balikesir", "Susurluk", 39.9189, 28.1578)
        ]),
        .init(id: "bilecik", name: "Bilecik", country: "Türkiye", utcOffset: 3, districts: [
            d("bilecik", "Merkez", 40.1392, 29.9763), d("bilecik", "Bozüyük", 39.9068, 30.0346),
            d("bilecik", "Gölpazarı", 40.2836, 30.3155), d("bilecik", "İnhisar", 40.0498, 30.3854),
            d("bilecik", "Osmaneli", 40.3581, 30.0155), d("bilecik", "Pazaryeri", 39.9954, 29.9034),
            d("bilecik", "Söğüt", 40.0151, 30.1819), d("bilecik", "Yenipazar", 40.1771, 30.5192)
        ]),
        .init(id: "bingol", name: "Bingöl", country: "Türkiye", utcOffset: 3, districts: [
            d("bingol", "Merkez", 38.8846, 40.4977), d("bingol", "Adaklı", 39.2287, 40.4828),
            d("bingol", "Genç", 38.7483, 40.5533), d("bingol", "Karlıova", 39.2945, 41.0101),
            d("bingol", "Kiğı", 39.3100, 40.3490), d("bingol", "Solhan", 38.9669, 41.0542),
            d("bingol", "Yayladere", 39.2275, 40.0685), d("bingol", "Yedisu", 39.4339, 40.5452)
        ]),
        .init(id: "bitlis", name: "Bitlis", country: "Türkiye", utcOffset: 3, districts: [
            d("bitlis", "Merkez", 38.3972, 42.1071), d("bitlis", "Adilcevaz", 38.7947, 42.7514),
            d("bitlis", "Ahlat", 38.7524, 42.4937), d("bitlis", "Güroymak", 38.5741, 42.0253),
            d("bitlis", "Hizan", 38.2215, 42.4236), d("bitlis", "Mutki", 38.4097, 41.9184),
            d("bitlis", "Tatvan", 38.5044, 42.2800)
        ]),
        .init(id: "bolu", name: "Bolu", country: "Türkiye", utcOffset: 3, districts: [
            d("bolu", "Merkez", 40.7328, 31.6085), d("bolu", "Dörtdivan", 40.7207, 32.0626),
            d("bolu", "Gerede", 40.7974, 32.2017), d("bolu", "Göynük", 40.3988, 30.7859),
            d("bolu", "Kıbrıscık", 40.4099, 31.8480), d("bolu", "Mengen", 40.9389, 32.0733),
            d("bolu", "Mudurnu", 40.4661, 31.2113), d("bolu", "Seben", 40.4116, 31.5735),
            d("bolu", "Yeniçağa", 40.7713, 32.0298)
        ]),
        .init(id: "burdur", name: "Burdur", country: "Türkiye", utcOffset: 3, districts: [
            d("burdur", "Merkez", 37.7146, 30.2827), d("burdur", "Ağlasun", 37.6493, 30.5339),
            d("burdur", "Altınyayla", 36.9983, 29.5468), d("burdur", "Bucak", 37.4565, 30.5880),
            d("burdur", "Çavdır", 37.1555, 29.6906), d("burdur", "Çeltikçi", 37.5338, 30.4826),
            d("burdur", "Gölhisar", 37.1511, 29.5107), d("burdur", "Karamanlı", 37.3726, 29.8279),
            d("burdur", "Kemer", 37.3533, 30.0611), d("burdur", "Tefenni", 37.3078, 29.7721),
            d("burdur", "Yeşilova", 37.5061, 29.7533)
        ]),
        .init(id: "bursa", name: "Bursa", country: "Türkiye", utcOffset: 3, districts: [
            d("bursa", "Büyükorhan", 39.7708, 28.8861), d("bursa", "Gemlik", 40.4344, 29.1521),
            d("bursa", "Gürsu", 40.2182, 29.1921), d("bursa", "Harmancık", 39.6768, 29.1547),
            d("bursa", "İnegöl", 40.0800, 29.5096), d("bursa", "İznik", 40.4294, 29.7197),
            d("bursa", "Karacabey", 40.2160, 28.3586), d("bursa", "Keles", 39.9125, 29.2335),
            d("bursa", "Kestel", 40.2006, 29.2126), d("bursa", "Mudanya", 40.3734, 28.8884),
            d("bursa", "Mustafakemalpaşa", 40.0377, 28.4083), d("bursa", "Nilüfer", 40.2164, 28.9771),
            d("bursa", "Orhaneli", 39.9038, 28.9867), d("bursa", "Orhangazi", 40.4906, 29.3085),
            d("bursa", "Osmangazi", 40.1961, 29.0602), d("bursa", "Yenişehir", 40.2642, 29.6506),
            d("bursa", "Yıldırım", 40.1915, 29.1272)
        ]),
        .init(id: "canakkale", name: "Çanakkale", country: "Türkiye", utcOffset: 3, districts: [
            d("canakkale", "Merkez", 40.1466, 26.4086), d("canakkale", "Ayvacık", 39.6019, 26.3996),
            d("canakkale", "Bayramiç", 39.8094, 26.6118), d("canakkale", "Biga", 40.2259, 27.2465),
            d("canakkale", "Bozcaada", 39.8223, 26.0325), d("canakkale", "Çan", 40.0282, 27.0491),
            d("canakkale", "Eceabat", 40.1843, 26.3592), d("canakkale", "Ezine", 39.7872, 26.3351),
            d("canakkale", "Gelibolu", 40.4141, 26.6703), d("canakkale", "Gökçeada", 40.1614, 25.8397),
            d("canakkale", "Lapseki", 40.3441, 26.6835), d("canakkale", "Yenice", 39.9296, 27.2594)
        ]),
        .init(id: "cankiri", name: "Çankırı", country: "Türkiye", utcOffset: 3, districts: [
            d("cankiri", "Merkez", 40.5972, 33.6153), d("cankiri", "Atkaracalar", 40.8161, 33.0754),
            d("cankiri", "Bayramören", 40.9431, 33.2040), d("cankiri", "Çerkeş", 40.8122, 32.8918),
            d("cankiri", "Eldivan", 40.5303, 33.4971), d("cankiri", "Ilgaz", 40.9249, 33.6253),
            d("cankiri", "Kızılırmak", 40.3445, 33.9850), d("cankiri", "Korgun", 40.7346, 33.5184),
            d("cankiri", "Kurşunlu", 40.8430, 33.2634), d("cankiri", "Orta", 40.6270, 33.1077),
            d("cankiri", "Şabanözü", 40.4833, 33.2825), d("cankiri", "Yapraklı", 40.7572, 33.7787)
        ]),
        .init(id: "corum", name: "Çorum", country: "Türkiye", utcOffset: 3, districts: [
            d("corum", "Merkez", 40.5499, 34.9536), d("corum", "Alaca", 40.1684, 34.8412),
            d("corum", "Bayat", 40.6425, 34.2585), d("corum", "Boğazkale", 40.0220, 34.6080),
            d("corum", "Dodurga", 40.8576, 34.8107), d("corum", "İskilip", 40.7286, 34.4748),
            d("corum", "Kargı", 41.1345, 34.4871), d("corum", "Laçin", 40.7717, 34.8865),
            d("corum", "Mecitözü", 40.5206, 35.2953), d("corum", "Oğuzlar", 40.7560, 34.7036),
            d("corum", "Ortaköy", 40.2729, 35.2510), d("corum", "Osmancık", 40.9714, 34.8009),
            d("corum", "Sungurlu", 40.1666, 34.3754), d("corum", "Uğurludağ", 40.4455, 34.4516)
        ]),
        .init(id: "denizli", name: "Denizli", country: "Türkiye", utcOffset: 3, districts: [
            d("denizli", "Acıpayam", 37.4272, 29.3494), d("denizli", "Babadağ", 37.8078, 28.8572),
            d("denizli", "Baklan", 37.9767, 29.6068), d("denizli", "Bekilli", 38.2267, 29.4218),
            d("denizli", "Beyağaç", 37.2356, 28.8960), d("denizli", "Bozkurt", 37.8237, 29.6081),
            d("denizli", "Buldan", 38.0466, 28.8260), d("denizli", "Çal", 38.0823, 29.3973),
            d("denizli", "Çameli", 37.0757, 29.3440), d("denizli", "Çardak", 37.8290, 29.6620),
            d("denizli", "Çivril", 38.3013, 29.7387), d("denizli", "Güney", 38.1540, 29.0642),
            d("denizli", "Honaz", 37.7550, 29.2674), d("denizli", "Kale", 37.4434, 28.8451),
            d("denizli", "Merkezefendi", 37.7874, 29.0371), d("denizli", "Pamukkale", 37.7625, 29.1033),
            d("denizli", "Sarayköy", 37.9241, 28.9254), d("denizli", "Serinhisar", 37.5807, 29.2636),
            d("denizli", "Tavas", 37.5729, 29.0712)
        ]),
        .init(id: "diyarbakir", name: "Diyarbakır", country: "Türkiye", utcOffset: 3, districts: [
            d("diyarbakir", "Bağlar", 37.9234, 40.1935), d("diyarbakir", "Bismil", 37.8517, 40.6639),
            d("diyarbakir", "Çermik", 38.1358, 39.4501), d("diyarbakir", "Çınar", 37.7241, 40.4135),
            d("diyarbakir", "Çüngüş", 38.2123, 39.2884), d("diyarbakir", "Dicle", 38.3678, 40.0722),
            d("diyarbakir", "Eğil", 38.2575, 40.0844), d("diyarbakir", "Ergani", 38.2648, 39.7592),
            d("diyarbakir", "Hani", 38.4095, 40.3981), d("diyarbakir", "Hazro", 38.2540, 40.7815),
            d("diyarbakir", "Kayapınar", 37.9398, 40.1807), d("diyarbakir", "Kocaköy", 38.2900, 40.5028),
            d("diyarbakir", "Kulp", 38.5018, 41.0122), d("diyarbakir", "Lice", 38.4602, 40.6476),
            d("diyarbakir", "Silvan", 38.1423, 41.0005), d("diyarbakir", "Sur", 37.9110, 40.2367),
            d("diyarbakir", "Yenişehir", 37.9409, 40.2260)
        ]),
        .init(id: "edirne", name: "Edirne", country: "Türkiye", utcOffset: 3, districts: [
            d("edirne", "Merkez", 41.6771, 26.5556), d("edirne", "Enez", 40.7250, 26.0845),
            d("edirne", "Havsa", 41.5492, 26.8217), d("edirne", "İpsala", 40.9220, 26.3841),
            d("edirne", "Keşan", 40.8554, 26.6301), d("edirne", "Lalapaşa", 41.8390, 26.7360),
            d("edirne", "Meriç", 41.1915, 26.4201), d("edirne", "Süloğlu", 41.7647, 26.9074),
            d("edirne", "Uzunköprü", 41.2669, 26.6877)
        ]),
        .init(id: "elzig", name: "Elâzığ", country: "Türkiye", utcOffset: 3, districts: [
            d("elzig", "Merkez", 38.6750, 39.2125), d("elzig", "Ağın", 38.9437, 38.7143),
            d("elzig", "Alacakaya", 38.4527, 39.8510), d("elzig", "Arıcak", 38.5643, 40.1389),
            d("elzig", "Baskil", 38.5689, 38.8248), d("elzig", "Karakoçan", 38.9540, 40.0373),
            d("elzig", "Keban", 38.7943, 38.7404), d("elzig", "Kovancılar", 38.7206, 39.8723),
            d("elzig", "Maden", 38.3937, 39.6736), d("elzig", "Palu", 38.6946, 39.9310),
            d("elzig", "Sivrice", 38.4485, 39.3075)
        ]),
        .init(id: "erzincan", name: "Erzincan", country: "Türkiye", utcOffset: 3, districts: [
            d("erzincan", "Merkez", 39.7463, 39.4904), d("erzincan", "Çayırlı", 39.8041, 40.0368),
            d("erzincan", "İliç", 39.4563, 38.5645), d("erzincan", "Kemah", 39.6022, 39.0349),
            d("erzincan", "Kemaliye", 39.2619, 38.4965), d("erzincan", "Otlukbeli", 39.9740, 40.0233),
            d("erzincan", "Refahiye", 39.8996, 38.7680), d("erzincan", "Tercan", 39.7765, 40.3829),
            d("erzincan", "Üzümlü", 39.7099, 39.7010)
        ]),
        .init(id: "erzurum", name: "Erzurum", country: "Türkiye", utcOffset: 3, districts: [
            d("erzurum", "Aşkale", 39.9207, 40.6975), d("erzurum", "Aziziye", 39.9432, 41.1120),
            d("erzurum", "Çat", 39.6119, 40.9774), d("erzurum", "Hınıs", 39.3577, 41.7017),
            d("erzurum", "Horasan", 40.0427, 42.1738), d("erzurum", "İspir", 40.4831, 40.9998),
            d("erzurum", "Karaçoban", 39.3468, 42.1026), d("erzurum", "Karayazı", 39.7027, 42.1455),
            d("erzurum", "Köprüköy", 39.9020, 41.9204), d("erzurum", "Narman", 40.3451, 41.8711),
            d("erzurum", "Oltu", 40.5459, 41.9961), d("erzurum", "Olur", 40.8277, 42.1285),
            d("erzurum", "Palandöken", 39.8887, 41.2716), d("erzurum", "Pasinler", 39.9789, 41.6733),
            d("erzurum", "Pazaryolu", 40.4173, 40.7717), d("erzurum", "Şenkaya", 40.5601, 42.3420),
            d("erzurum", "Tekman", 39.6457, 41.5050), d("erzurum", "Tortum", 40.2972, 41.5508),
            d("erzurum", "Uzundere", 40.5328, 41.5480), d("erzurum", "Yakutiye", 39.9065, 41.2729)
        ]),
        .init(id: "eskisehir", name: "Eskişehir", country: "Türkiye", utcOffset: 3, districts: [
            d("eskisehir", "Alpu", 39.7657, 30.9586), d("eskisehir", "Beylikova", 39.6872, 31.2074),
            d("eskisehir", "Çifteler", 39.3771, 31.0383), d("eskisehir", "Günyüzü", 39.3841, 31.8093),
            d("eskisehir", "Han", 39.1586, 30.8619), d("eskisehir", "İnönü", 39.8164, 30.1430),
            d("eskisehir", "Mahmudiye", 39.4943, 30.9863), d("eskisehir", "Mihalgazi", 40.0262, 30.5770),
            d("eskisehir", "Mihalıççık", 39.8661, 31.4952), d("eskisehir", "Odunpazarı", 39.7665, 30.5433),
            d("eskisehir", "Sarıcakaya", 40.0376, 30.6207), d("eskisehir", "Seyitgazi", 39.4437, 30.6961),
            d("eskisehir", "Sivrihisar", 39.4475, 31.5362), d("eskisehir", "Tepebaşı", 39.7836, 30.5013)
        ]),
        .init(id: "gaziantep", name: "Gaziantep", country: "Türkiye", utcOffset: 3, districts: [
            d("gaziantep", "Araban", 37.4252, 37.6885), d("gaziantep", "İslahiye", 37.0225, 36.6301),
            d("gaziantep", "Karkamış", 36.8337, 37.9979), d("gaziantep", "Nizip", 37.0101, 37.7971),
            d("gaziantep", "Nurdağı", 37.1756, 36.7407), d("gaziantep", "Oğuzeli", 36.9624, 37.5150),
            d("gaziantep", "Şahinbey", 37.0457, 37.3697), d("gaziantep", "Şehitkamil", 37.0881, 37.3912),
            d("gaziantep", "Yavuzeli", 37.3160, 37.5664)
        ]),
        .init(id: "giresun", name: "Giresun", country: "Türkiye", utcOffset: 3, districts: [
            d("giresun", "Merkez", 40.9166, 38.3817), d("giresun", "Alucra", 40.3202, 38.7641),
            d("giresun", "Bulancak", 40.9382, 38.2317), d("giresun", "Çamoluk", 40.1344, 38.7348),
            d("giresun", "Çanakçı", 40.9167, 39.0095), d("giresun", "Dereli", 40.7379, 38.4507),
            d("giresun", "Doğankent", 40.8100, 38.9164), d("giresun", "Espiye", 40.9493, 38.7064),
            d("giresun", "Eynesil", 41.0638, 39.1401), d("giresun", "Görele", 41.0316, 39.0019),
            d("giresun", "Güce", 40.8931, 38.8075), d("giresun", "Keşap", 40.9171, 38.5129),
            d("giresun", "Piraziz", 40.9527, 38.1247), d("giresun", "Şebinkarahisar", 40.2883, 38.4208),
            d("giresun", "Tirebolu", 41.0073, 38.8138), d("giresun", "Yağlıdere", 40.8617, 38.6254)
        ]),
        .init(id: "gumushane", name: "Gümüşhane", country: "Türkiye", utcOffset: 3, districts: [
            d("gumushane", "Merkez", 40.4585, 39.4782), d("gumushane", "Kelkit", 40.1294, 39.4363),
            d("gumushane", "Köse", 40.2115, 39.6528), d("gumushane", "Kürtün", 40.7019, 39.0862),
            d("gumushane", "Şiran", 40.1895, 39.1265), d("gumushane", "Torul", 40.5566, 39.2927)
        ]),
        .init(id: "hakkari", name: "Hakkari", country: "Türkiye", utcOffset: 3, districts: [
            d("hakkari", "Merkez", 37.5738, 43.7352), d("hakkari", "Çukurca", 37.2468, 43.6110),
            d("hakkari", "Derecik", 37.0817, 44.3113), d("hakkari", "Şemdinli", 37.3042, 44.5746),
            d("hakkari", "Yüksekova", 37.5730, 44.2807)
        ]),
        .init(id: "hatay", name: "Hatay", country: "Türkiye", utcOffset: 3, districts: [
            d("hatay", "Altınözü", 36.1156, 36.2480), d("hatay", "Antakya", 36.2025, 36.1602),
            d("hatay", "Arsuz", 36.4163, 35.8973), d("hatay", "Belen", 36.4914, 36.1955),
            d("hatay", "Defne", 36.1953, 36.1477), d("hatay", "Dörtyol", 36.8400, 36.2218),
            d("hatay", "Erzin", 36.9524, 36.1979), d("hatay", "Hassa", 36.7986, 36.5220),
            d("hatay", "İskenderun", 36.5846, 36.1756), d("hatay", "Kırıkhan", 36.4982, 36.3622),
            d("hatay", "Kumlu", 36.3647, 36.4541), d("hatay", "Payas", 36.7612, 36.2272),
            d("hatay", "Reyhanlı", 36.2685, 36.5674), d("hatay", "Samandağ", 36.0837, 35.9770),
            d("hatay", "Yayladağı", 35.9025, 36.0638)
        ]),
        .init(id: "isparta", name: "Isparta", country: "Türkiye", utcOffset: 3, districts: [
            d("isparta", "Merkez", 37.7635, 30.5551), d("isparta", "Aksu", 37.7990, 31.0711),
            d("isparta", "Atabey", 37.9509, 30.6374), d("isparta", "Eğirdir", 37.8739, 30.8482),
            d("isparta", "Gelendost", 38.1212, 31.0150), d("isparta", "Gönen", 37.9548, 30.5146),
            d("isparta", "Keçiborlu", 37.9463, 30.2970), d("isparta", "Şarkikaraağaç", 38.0792, 31.3583),
            d("isparta", "Senirkent", 38.1084, 30.5505), d("isparta", "Sütçüler", 37.4955, 30.9811),
            d("isparta", "Uluborlu", 38.0782, 30.4485), d("isparta", "Yalvaç", 38.2972, 31.1788),
            d("isparta", "Yenişarbademli", 37.7097, 31.3896)
        ]),
        .init(id: "mersin", name: "Mersin", country: "Türkiye", utcOffset: 3, districts: [
            d("mersin", "Akdeniz", 36.8226, 34.6550), d("mersin", "Anamur", 36.0702, 32.8667),
            d("mersin", "Aydıncık", 36.1525, 33.3383), d("mersin", "Bozyazı", 36.1017, 32.9757),
            d("mersin", "Çamlıyayla", 37.1669, 34.5934), d("mersin", "Erdemli", 36.6058, 34.3101),
            d("mersin", "Gülnar", 36.3381, 33.4015), d("mersin", "Mezitli", 36.7459, 34.5235),
            d("mersin", "Mut", 36.6453, 33.4370), d("mersin", "Silifke", 36.3763, 33.9255),
            d("mersin", "Tarsus", 36.9166, 34.8956), d("mersin", "Toroslar", 36.8290, 34.6100),
            d("mersin", "Yenişehir", 36.7858, 34.5651)
        ]),
        .init(id: "istanbul", name: "İstanbul", country: "Türkiye", utcOffset: 3, districts: [
            d("istanbul", "Adalar", 40.8733, 29.1274), d("istanbul", "Arnavutköy", 41.1831, 28.7397),
            d("istanbul", "Ataşehir", 40.9974, 29.0988), d("istanbul", "Avcılar", 40.9796, 28.7218),
            d("istanbul", "Bağcılar", 41.0344, 28.8565), d("istanbul", "Bahçelievler", 40.9984, 28.8583),
            d("istanbul", "Bakırköy", 40.9810, 28.8741), d("istanbul", "Başakşehir", 41.1179, 28.8073),
            d("istanbul", "Bayrampaşa", 41.0354, 28.9109), d("istanbul", "Beşiktaş", 41.0432, 29.0063),
            d("istanbul", "Beykoz", 41.1262, 29.0978), d("istanbul", "Beylikdüzü", 40.9996, 28.6451),
            d("istanbul", "Beyoğlu", 41.0369, 28.9851), d("istanbul", "Büyükçekmece", 41.0170, 28.5888),
            d("istanbul", "Çatalca", 41.1437, 28.4608), d("istanbul", "Çekmeköy", 41.0157, 29.1906),
            d("istanbul", "Esenler", 41.0380, 28.8821), d("istanbul", "Esenyurt", 41.0349, 28.6794),
            d("istanbul", "Eyüpsultan", 41.0477, 28.9340), d("istanbul", "Fatih", 41.0204, 28.9491),
            d("istanbul", "Gaziosmanpaşa", 41.0570, 28.9155), d("istanbul", "Güngören", 41.0157, 28.8773),
            d("istanbul", "Kadıköy", 40.9904, 29.0291), d("istanbul", "Kağıthane", 41.0855, 28.9816),
            d("istanbul", "Kartal", 40.8877, 29.1862), d("istanbul", "Küçükçekmece", 41.0063, 28.7970),
            d("istanbul", "Maltepe", 40.9246, 29.1310), d("istanbul", "Pendik", 40.8760, 29.2343),
            d("istanbul", "Sancaktepe", 40.9904, 29.2288), d("istanbul", "Sarıyer", 41.1667, 29.0573),
            d("istanbul", "Şile", 41.1775, 29.6128), d("istanbul", "Silivri", 41.0725, 28.2556),
            d("istanbul", "Şişli", 41.0611, 28.9876), d("istanbul", "Sultanbeyli", 40.9690, 29.2552),
            d("istanbul", "Sultangazi", 41.0940, 28.9033), d("istanbul", "Tuzla", 40.8125, 29.3085),
            d("istanbul", "Ümraniye", 41.0258, 29.0970), d("istanbul", "Üsküdar", 41.0261, 29.0138),
            d("istanbul", "Zeytinburnu", 40.9945, 28.9110)
        ]),
        .init(id: "izmir", name: "İzmir", country: "Türkiye", utcOffset: 3, districts: [
            d("izmir", "Aliağa", 38.8011, 26.9728), d("izmir", "Balçova", 38.3944, 27.0464),
            d("izmir", "Bayındır", 38.2223, 27.6493), d("izmir", "Bayraklı", 38.4653, 27.1681),
            d("izmir", "Bergama", 39.1189, 27.1773), d("izmir", "Beydağ", 38.0865, 28.2102),
            d("izmir", "Bornova", 38.4667, 27.2198), d("izmir", "Buca", 38.3880, 27.1742),
            d("izmir", "Çeşme", 38.3229, 26.3024), d("izmir", "Çiğli", 38.4903, 27.0677),
            d("izmir", "Dikili", 39.0749, 26.8892), d("izmir", "Foça", 38.6687, 26.7548),
            d("izmir", "Gaziemir", 38.3229, 27.1306), d("izmir", "Güzelbahçe", 38.3773, 26.8838),
            d("izmir", "Karabağlar", 38.3827, 27.1203), d("izmir", "Karaburun", 38.6472, 26.5154),
            d("izmir", "Karşıyaka", 38.4630, 27.1083), d("izmir", "Kemalpaşa", 38.4275, 27.4164),
            d("izmir", "Kınık", 39.0887, 27.3849), d("izmir", "Kiraz", 38.2316, 28.2059),
            d("izmir", "Konak", 38.4235, 27.1422), d("izmir", "Menderes", 38.2515, 27.1329),
            d("izmir", "Menemen", 38.6090, 27.0717), d("izmir", "Narlıdere", 38.3959, 26.9968),
            d("izmir", "Ödemiş", 38.2281, 27.9747), d("izmir", "Seferihisar", 38.1949, 26.8342),
            d("izmir", "Selçuk", 37.9479, 27.3685), d("izmir", "Tire", 38.0894, 27.7324),
            d("izmir", "Torbalı", 38.1553, 27.3612), d("izmir", "Urla", 38.3235, 26.7647)
        ]),
        .init(id: "kars", name: "Kars", country: "Türkiye", utcOffset: 3, districts: [
            d("kars", "Merkez", 40.6010, 43.1000), d("kars", "Akyaka", 40.7425, 43.6239),
            d("kars", "Arpaçay", 40.8483, 43.3313), d("kars", "Digor", 40.3780, 43.4152),
            d("kars", "Kağızman", 40.1407, 43.1205), d("kars", "Sarıkamış", 40.3337, 42.5895),
            d("kars", "Selim", 40.4641, 42.7906), d("kars", "Susuz", 40.7801, 43.1278)
        ]),
        .init(id: "kastamonu", name: "Kastamonu", country: "Türkiye", utcOffset: 3, districts: [
            d("kastamonu", "Merkez", 41.3764, 33.7773), d("kastamonu", "Abana", 41.9787, 34.0078),
            d("kastamonu", "Ağlı", 41.6869, 33.5539), d("kastamonu", "Araç", 41.2451, 33.3292),
            d("kastamonu", "Azdavay", 41.6419, 33.3017), d("kastamonu", "Bozkurt", 41.9575, 34.0108),
            d("kastamonu", "Çatalzeytin", 41.9532, 34.2171), d("kastamonu", "Cide", 41.8976, 32.9846),
            d("kastamonu", "Daday", 41.4765, 33.4635), d("kastamonu", "Devrekani", 41.5995, 33.8380),
            d("kastamonu", "Doğanyurt", 42.0042, 33.4604), d("kastamonu", "Hanönü", 41.6255, 34.4627),
            d("kastamonu", "İhsangazi", 41.2041, 33.5544), d("kastamonu", "İnebolu", 41.9791, 33.7599),
            d("kastamonu", "Küre", 41.8059, 33.7102), d("kastamonu", "Pınarbaşı", 41.6038, 33.1109),
            d("kastamonu", "Şenpazar", 41.8084, 33.2328), d("kastamonu", "Seydiler", 41.6194, 33.7175),
            d("kastamonu", "Taşköprü", 41.5047, 34.2131), d("kastamonu", "Tosya", 41.0165, 34.0385)
        ]),
        .init(id: "kayseri", name: "Kayseri", country: "Türkiye", utcOffset: 3, districts: [
            d("kayseri", "Akkışla", 39.0017, 36.1719), d("kayseri", "Bünyan", 38.8458, 35.8577),
            d("kayseri", "Develi", 38.3886, 35.4924), d("kayseri", "Felahiye", 39.0906, 35.5664),
            d("kayseri", "Hacılar", 38.6438, 35.4512), d("kayseri", "İncesu", 38.6234, 35.1841),
            d("kayseri", "Kocasinan", 38.7500, 35.4710), d("kayseri", "Melikgazi", 38.7118, 35.4994),
            d("kayseri", "Özvatan", 39.1021, 35.6980), d("kayseri", "Pınarbaşı", 38.7249, 36.3941),
            d("kayseri", "Sarıoğlan", 39.0732, 35.9643), d("kayseri", "Sarız", 38.4795, 36.4978),
            d("kayseri", "Talas", 38.6929, 35.5495), d("kayseri", "Tomarza", 38.4479, 35.7976),
            d("kayseri", "Yahyalı", 38.1085, 35.3606), d("kayseri", "Yeşilhisar", 38.3489, 35.0932)
        ]),
        .init(id: "kirklareli", name: "Kırklareli", country: "Türkiye", utcOffset: 3, districts: [
            d("kirklareli", "Merkez", 41.7346, 27.2255), d("kirklareli", "Babaeski", 41.4302, 27.0916),
            d("kirklareli", "Demirköy", 41.8249, 27.7662), d("kirklareli", "Kofçaz", 41.9429, 27.1570),
            d("kirklareli", "Lüleburgaz", 41.4020, 27.3550), d("kirklareli", "Pehlivanköy", 41.3472, 26.9241),
            d("kirklareli", "Pınarhisar", 41.6239, 27.5187), d("kirklareli", "Vize", 41.5730, 27.7671)
        ]),
        .init(id: "kirsehir", name: "Kırşehir", country: "Türkiye", utcOffset: 3, districts: [
            d("kirsehir", "Merkez", 39.1460, 34.1605), d("kirsehir", "Akçakent", 39.6249, 34.0962),
            d("kirsehir", "Akpınar", 39.4512, 33.9633), d("kirsehir", "Boztepe", 39.2687, 34.2614),
            d("kirsehir", "Çiçekdağı", 39.6035, 34.4168), d("kirsehir", "Kaman", 39.3588, 33.7244),
            d("kirsehir", "Mucur", 39.0605, 34.3781)
        ]),
        .init(id: "kocaeli", name: "Kocaeli", country: "Türkiye", utcOffset: 3, districts: [
            d("kocaeli", "Başiskele", 40.7168, 29.9206), d("kocaeli", "Çayırova", 40.8305, 29.3801),
            d("kocaeli", "Darıca", 40.7808, 29.3853), d("kocaeli", "Derince", 40.7576, 29.8307),
            d("kocaeli", "Dilovası", 40.7854, 29.5416), d("kocaeli", "Gebze", 40.7992, 29.4322),
            d("kocaeli", "Gölcük", 40.6640, 29.7920), d("kocaeli", "İzmit", 40.7663, 29.9411),
            d("kocaeli", "Kandıra", 41.0694, 30.1527), d("kocaeli", "Karamürsel", 40.6917, 29.6168),
            d("kocaeli", "Kartepe", 40.7433, 30.0219), d("kocaeli", "Körfez", 40.7685, 29.7683)
        ]),
        .init(id: "konya", name: "Konya", country: "Türkiye", utcOffset: 3, districts: [
            d("konya", "Ahırlı", 37.2389, 32.1204), d("konya", "Akören", 37.4512, 32.3700),
            d("konya", "Akşehir", 38.3590, 31.4115), d("konya", "Altınekin", 38.3081, 32.8687),
            d("konya", "Beyşehir", 37.6795, 31.7277), d("konya", "Bozkır", 37.1888, 32.2455),
            d("konya", "Çeltik", 39.0237, 31.7905), d("konya", "Cihanbeyli", 38.6559, 32.9228),
            d("konya", "Çumra", 37.5732, 32.7803), d("konya", "Derbent", 38.0156, 32.0186),
            d("konya", "Derebucak", 37.3913, 31.5106), d("konya", "Doğanhisar", 38.1450, 31.6775),
            d("konya", "Emirgazi", 37.9037, 33.8354), d("konya", "Ereğli", 37.5174, 34.0462),
            d("konya", "Güneysınır", 37.2979, 32.7177), d("konya", "Hadim", 36.9862, 32.4558),
            d("konya", "Halkapınar", 37.4337, 34.1867), d("konya", "Hüyük", 37.9519, 31.5982),
            d("konya", "Ilgın", 38.2802, 31.9148), d("konya", "Kadınhanı", 38.2393, 32.2131),
            d("konya", "Karapınar", 37.7159, 33.5506), d("konya", "Karatay", 37.8700, 32.5260),
            d("konya", "Kulu", 39.0904, 33.0802), d("konya", "Meram", 37.8606, 32.4735),
            d("konya", "Sarayönü", 38.2642, 32.4069), d("konya", "Selçuklu", 37.8923, 32.4770),
            d("konya", "Seydişehir", 37.4187, 31.8525), d("konya", "Taşkent", 36.9236, 32.4929),
            d("konya", "Tuzlukçu", 38.4746, 31.6289), d("konya", "Yalıhüyük", 37.3005, 32.0854),
            d("konya", "Yunak", 38.8144, 31.7348)
        ]),
        .init(id: "kutahya", name: "Kütahya", country: "Türkiye", utcOffset: 3, districts: [
            d("kutahya", "Merkez", 39.4192, 29.9852), d("kutahya", "Altıntaş", 39.0595, 30.1093),
            d("kutahya", "Aslanapa", 39.2147, 29.8703), d("kutahya", "Çavdarhisar", 39.2003, 29.6126),
            d("kutahya", "Domaniç", 39.8023, 29.6127), d("kutahya", "Dumlupınar", 38.8524, 29.9802),
            d("kutahya", "Emet", 39.3402, 29.2573), d("kutahya", "Gediz", 38.9904, 29.3926),
            d("kutahya", "Hisarcık", 39.2504, 29.2308), d("kutahya", "Pazarlar", 38.9945, 29.1231),
            d("kutahya", "Şaphane", 39.0248, 29.2197), d("kutahya", "Simav", 39.0888, 28.9772),
            d("kutahya", "Tavşanlı", 39.5468, 29.4873)
        ]),
        .init(id: "malatya", name: "Malatya", country: "Türkiye", utcOffset: 3, districts: [
            d("malatya", "Akçadağ", 38.3443, 37.9684), d("malatya", "Arapgir", 39.0387, 38.4888),
            d("malatya", "Arguvan", 38.7828, 38.2642), d("malatya", "Battalgazi", 38.3553, 38.3335),
            d("malatya", "Darende", 38.5465, 37.5117), d("malatya", "Doğanşehir", 38.0948, 37.8791),
            d("malatya", "Doğanyol", 38.3101, 39.0361), d("malatya", "Hekimhan", 38.8158, 37.9312),
            d("malatya", "Kale", 38.4013, 38.7462), d("malatya", "Kuluncak", 38.8847, 37.6703),
            d("malatya", "Pütürge", 38.1966, 38.8690), d("malatya", "Yazıhan", 38.5956, 38.1800),
            d("malatya", "Yeşilyurt", 38.3475, 38.2860)
        ]),
        .init(id: "manisa", name: "Manisa", country: "Türkiye", utcOffset: 3, districts: [
            d("manisa", "Ahmetli", 38.5137, 27.9379), d("manisa", "Akhisar", 38.9254, 27.8345),
            d("manisa", "Alaşehir", 38.3546, 28.5164), d("manisa", "Demirci", 39.0474, 28.6584),
            d("manisa", "Gölmarmara", 38.7135, 27.9183), d("manisa", "Gördes", 38.9352, 28.2896),
            d("manisa", "Kırkağaç", 39.1152, 27.6860), d("manisa", "Köprübaşı", 38.7474, 28.4031),
            d("manisa", "Kula", 38.5403, 28.6415), d("manisa", "Salihli", 38.4861, 28.1390),
            d("manisa", "Sarıgöl", 38.2367, 28.6992), d("manisa", "Saruhanlı", 38.7330, 27.5591),
            d("manisa", "Şehzadeler", 38.6153, 27.4305), d("manisa", "Selendi", 38.7434, 28.8702),
            d("manisa", "Soma", 39.1852, 27.6088), d("manisa", "Turgutlu", 38.4987, 27.6995),
            d("manisa", "Yunusemre", 38.6172, 27.4027)
        ]),
        .init(id: "kahramanmaras", name: "Kahramanmaraş", country: "Türkiye", utcOffset: 3, districts: [
            d("kahramanmaras", "Afşin", 38.2437, 36.9153), d("kahramanmaras", "Andırın", 37.5733, 36.3536),
            d("kahramanmaras", "Çağlayancerit", 37.7494, 37.2924), d("kahramanmaras", "Dulkadiroğlu", 37.5817, 36.9457),
            d("kahramanmaras", "Ekinözü", 38.0592, 37.1887), d("kahramanmaras", "Elbistan", 38.2057, 37.1876),
            d("kahramanmaras", "Göksun", 38.0224, 36.5042), d("kahramanmaras", "Nurhak", 37.9657, 37.4462),
            d("kahramanmaras", "Onikişubat", 37.5865, 36.8978), d("kahramanmaras", "Pazarcık", 37.4886, 37.2918),
            d("kahramanmaras", "Türkoğlu", 37.3846, 36.8462)
        ]),
        .init(id: "mardin", name: "Mardin", country: "Türkiye", utcOffset: 3, districts: [
            d("mardin", "Artuklu", 37.3225, 40.7216), d("mardin", "Dargeçit", 37.5450, 41.7222),
            d("mardin", "Derik", 37.3668, 40.2686), d("mardin", "Kızıltepe", 37.1875, 40.5841),
            d("mardin", "Mazıdağı", 37.4776, 40.4865), d("mardin", "Midyat", 37.4198, 41.3526),
            d("mardin", "Nusaybin", 37.0776, 41.2152), d("mardin", "Ömerli", 37.4028, 40.9544),
            d("mardin", "Savur", 37.5360, 40.8880), d("mardin", "Yeşilli", 37.3389, 40.8201)
        ]),
        .init(id: "mugla", name: "Muğla", country: "Türkiye", utcOffset: 3, districts: [
            d("mugla", "Bodrum", 37.0345, 27.4300), d("mugla", "Dalaman", 36.7659, 28.8066),
            d("mugla", "Datça", 36.7263, 27.6875), d("mugla", "Fethiye", 36.6235, 29.1126),
            d("mugla", "Kavaklıdere", 37.4461, 28.3630), d("mugla", "Köyceğiz", 36.9565, 28.6893),
            d("mugla", "Marmaris", 36.8530, 28.2706), d("mugla", "Menteşe", 37.2167, 28.3649),
            d("mugla", "Milas", 37.3139, 27.7837), d("mugla", "Ortaca", 36.8440, 28.7692),
            d("mugla", "Seydikemer", 36.6474, 29.3624), d("mugla", "Ula", 37.1014, 28.4183),
            d("mugla", "Yatağan", 37.3416, 28.1453)
        ]),
        .init(id: "mus", name: "Muş", country: "Türkiye", utcOffset: 3, districts: [
            d("mus", "Merkez", 38.7377, 41.4946), d("mus", "Bulanık", 39.0981, 42.2716),
            d("mus", "Hasköy", 38.6817, 41.6872), d("mus", "Korkut", 38.7421, 41.7854),
            d("mus", "Malazgirt", 39.1461, 42.5410), d("mus", "Varto", 39.1685, 41.4547)
        ]),
        .init(id: "nevsehir", name: "Nevşehir", country: "Türkiye", utcOffset: 3, districts: [
            d("nevsehir", "Merkez", 38.6267, 34.7199), d("nevsehir", "Acıgöl", 38.5500, 34.5090),
            d("nevsehir", "Avanos", 38.7192, 34.8472), d("nevsehir", "Derinkuyu", 38.3687, 34.7360),
            d("nevsehir", "Gülşehir", 38.7404, 34.6161), d("nevsehir", "Hacıbektaş", 38.9443, 34.5635),
            d("nevsehir", "Kozaklı", 39.2096, 34.8509), d("nevsehir", "Ürgüp", 38.6331, 34.9121)
        ]),
        .init(id: "nigde", name: "Niğde", country: "Türkiye", utcOffset: 3, districts: [
            d("nigde", "Merkez", 37.9694, 34.6757), d("nigde", "Altunhisar", 37.9958, 34.3682),
            d("nigde", "Bor", 37.8939, 34.5634), d("nigde", "Çamardı", 37.8366, 34.9899),
            d("nigde", "Çiftlik", 38.1749, 34.4847), d("nigde", "Ulukışla", 37.5477, 34.4848)
        ]),
        .init(id: "ordu", name: "Ordu", country: "Türkiye", utcOffset: 3, districts: [
            d("ordu", "Akkuş", 40.7918, 37.0177), d("ordu", "Altınordu", 40.9786, 37.8964),
            d("ordu", "Aybastı", 40.6845, 37.3999), d("ordu", "Çamaş", 40.9031, 37.5273),
            d("ordu", "Çatalpınar", 40.8787, 37.4535), d("ordu", "Çaybaşı", 41.0174, 37.0991),
            d("ordu", "Fatsa", 41.0313, 37.5009), d("ordu", "Gölkoy", 40.6871, 37.6183),
            d("ordu", "Gülyalı", 40.9664, 38.0611), d("ordu", "Gürgentepe", 40.7893, 37.6005),
            d("ordu", "İkizce", 41.0532, 37.0777), d("ordu", "Kabadüz", 40.8594, 37.8903),
            d("ordu", "Kabataş", 40.7512, 37.4507), d("ordu", "Korgan", 40.8291, 37.3444),
            d("ordu", "Kumru", 40.8736, 37.2644), d("ordu", "Mesudiye", 40.4624, 37.7731),
            d("ordu", "Perşembe", 41.0669, 37.7737), d("ordu", "Ulubey", 40.8730, 37.7586),
            d("ordu", "Ünye", 41.1315, 37.2866)
        ]),
        .init(id: "rize", name: "Rize", country: "Türkiye", utcOffset: 3, districts: [
            d("rize", "Merkez", 41.0252, 40.5173), d("rize", "Ardeşen", 41.1945, 40.9833),
            d("rize", "Çamlıhemşin", 41.0490, 41.0036), d("rize", "Çayeli", 41.0867, 40.7227),
            d("rize", "Derepazarı", 41.0247, 40.4215), d("rize", "Fındıklı", 41.2729, 41.1427),
            d("rize", "Güneysu", 40.9772, 40.6132), d("rize", "Hemşin", 41.0481, 40.8990),
            d("rize", "İkizdere", 40.7788, 40.5597), d("rize", "İyidere", 41.0158, 40.3665),
            d("rize", "Kalkandere", 40.9287, 40.4424), d("rize", "Pazar", 41.1802, 40.8844)
        ]),
        .init(id: "sakarya", name: "Sakarya", country: "Türkiye", utcOffset: 3, districts: [
            d("sakarya", "Adapazarı", 40.7786, 30.3989), d("sakarya", "Akyazı", 40.6834, 30.6249),
            d("sakarya", "Arifiye", 40.7148, 30.3619), d("sakarya", "Erenler", 40.7585, 30.4039),
            d("sakarya", "Ferizli", 40.9391, 30.4868), d("sakarya", "Geyve", 40.5086, 30.2903),
            d("sakarya", "Hendek", 40.7967, 30.7458), d("sakarya", "Karapürçek", 40.6419, 30.5377),
            d("sakarya", "Karasu", 41.1100, 30.6927), d("sakarya", "Kaynarca", 41.0339, 30.3055),
            d("sakarya", "Kocaali", 41.0542, 30.8506), d("sakarya", "Pamukova", 40.5071, 30.1685),
            d("sakarya", "Sapanca", 40.6973, 30.2694), d("sakarya", "Serdivan", 40.7724, 30.3631),
            d("sakarya", "Söğütlü", 40.9056, 30.4740), d("sakarya", "Taraklı", 40.3973, 30.4931)
        ]),
        .init(id: "samsun", name: "Samsun", country: "Türkiye", utcOffset: 3, districts: [
            d("samsun", "19 Mayıs", 41.4624, 36.0460), d("samsun", "Alaçam", 41.6118, 35.6040),
            d("samsun", "Asarcık", 41.0363, 36.2345), d("samsun", "Atakum", 41.3223, 36.2870),
            d("samsun", "Ayvacık", 40.9897, 36.6327), d("samsun", "Bafra", 41.5600, 35.9066),
            d("samsun", "Canik", 41.2684, 36.3594), d("samsun", "Çarşamba", 41.1983, 36.7232),
            d("samsun", "Havza", 40.9684, 35.6652), d("samsun", "İlkadım", 41.2786, 36.3281),
            d("samsun", "Kavak", 41.0701, 36.0290), d("samsun", "Ladik", 40.9120, 35.8947),
            d("samsun", "Salıpazarı", 41.0817, 36.8253), d("samsun", "Tekkeköy", 41.2201, 36.4525),
            d("samsun", "Terme", 41.2092, 36.9720), d("samsun", "Vezirköprü", 41.1434, 35.4605),
            d("samsun", "Yakakent", 41.6313, 35.5302)
        ]),
        .init(id: "siirt", name: "Siirt", country: "Türkiye", utcOffset: 3, districts: [
            d("siirt", "Merkez", 37.9255, 41.9415), d("siirt", "Baykan", 38.1628, 41.7841),
            d("siirt", "Eruh", 37.7491, 42.1844), d("siirt", "Kurtalan", 37.9258, 41.6998),
            d("siirt", "Pervari", 37.9324, 42.5481), d("siirt", "Şirvan", 38.0624, 42.0304),
            d("siirt", "Tillo", 37.9500, 42.0116)
        ]),
        .init(id: "sinop", name: "Sinop", country: "Türkiye", utcOffset: 3, districts: [
            d("sinop", "Merkez", 42.0265, 35.1511), d("sinop", "Ayancık", 41.9396, 34.5878),
            d("sinop", "Boyabat", 41.4635, 34.7775), d("sinop", "Dikmen", 41.6515, 35.2640),
            d("sinop", "Durağan", 41.4200, 35.0559), d("sinop", "Erfelek", 41.8798, 34.9069),
            d("sinop", "Gerze", 41.8039, 35.1948), d("sinop", "Saraydüzü", 41.3286, 34.8473),
            d("sinop", "Türkeli", 41.9482, 34.3394)
        ]),
        .init(id: "sivas", name: "Sivas", country: "Türkiye", utcOffset: 3, districts: [
            d("sivas", "Merkez", 39.7504, 37.0150), d("sivas", "Akıncılar", 40.0816, 38.3474),
            d("sivas", "Altınyayla", 39.2729, 36.7476), d("sivas", "Divriği", 39.3679, 38.1136),
            d("sivas", "Doğanşar", 40.2145, 37.5332), d("sivas", "Gemerek", 39.1848, 36.0717),
            d("sivas", "Gölova", 40.0613, 38.6084), d("sivas", "Gürün", 38.7217, 37.2782),
            d("sivas", "Hafik", 39.8546, 37.3889), d("sivas", "Imranlı", 39.8738, 38.1118),
            d("sivas", "Kangal", 39.2356, 37.3909), d("sivas", "Koyulhisar", 40.3011, 37.8323),
            d("sivas", "Şarkışla", 39.3501, 36.4097), d("sivas", "Suşehri", 40.1749, 38.0849),
            d("sivas", "Ulaş", 39.4431, 37.0414), d("sivas", "Yıldızeli", 39.8718, 36.5997),
            d("sivas", "Zara", 39.8971, 37.7590)
        ]),
        .init(id: "tekirdag", name: "Tekirdağ", country: "Türkiye", utcOffset: 3, districts: [
            d("tekirdag", "Çerkezköy", 41.2863, 27.9996), d("tekirdag", "Çorlu", 41.1606, 27.8009),
            d("tekirdag", "Ergene", 41.2391, 27.7112), d("tekirdag", "Hayrabolu", 41.2136, 27.1068),
            d("tekirdag", "Kapaklı", 41.3307, 27.9868), d("tekirdag", "Malkara", 40.8937, 26.9039),
            d("tekirdag", "Marmaraereğlisi", 40.9693, 27.9549), d("tekirdag", "Muratlı", 41.1726, 27.4963),
            d("tekirdag", "Saray", 41.4405, 27.9210), d("tekirdag", "Şarköy", 40.6102, 27.1123),
            d("tekirdag", "Süleymanpaşa", 40.9768, 27.5161)
        ]),
        .init(id: "tokat", name: "Tokat", country: "Türkiye", utcOffset: 3, districts: [
            d("tokat", "Merkez", 40.3088, 36.5528), d("tokat", "Almus", 40.3758, 36.9033),
            d("tokat", "Artova", 40.1164, 36.3004), d("tokat", "Başçiftlik", 40.5470, 37.1684),
            d("tokat", "Erbaa", 40.6723, 36.5679), d("tokat", "Niksar", 40.5901, 36.9512),
            d("tokat", "Pazar", 40.2763, 36.2833), d("tokat", "Reşadiye", 40.3929, 37.3387),
            d("tokat", "Sulusaray", 39.9976, 36.0838), d("tokat", "Turhal", 40.3878, 36.0834),
            d("tokat", "Yeşilyurt", 40.0073, 36.2184), d("tokat", "Zile", 40.3025, 35.8867)
        ]),
        .init(id: "trabzon", name: "Trabzon", country: "Türkiye", utcOffset: 3, districts: [
            d("trabzon", "Akçaabat", 41.0158, 39.5941), d("trabzon", "Araklı", 40.9387, 40.0541),
            d("trabzon", "Arsin", 40.9534, 39.9355), d("trabzon", "Beşikdüzü", 41.0544, 39.2282),
            d("trabzon", "Çarşıbaşı", 41.0840, 39.3794), d("trabzon", "Çaykara", 40.7461, 40.2423),
            d("trabzon", "Dernekpazarı", 40.7989, 40.2478), d("trabzon", "Düzköy", 40.8740, 39.4252),
            d("trabzon", "Hayrat", 40.8894, 40.3682), d("trabzon", "Köprübaşı", 40.8085, 40.1234),
            d("trabzon", "Maçka", 40.8140, 39.6108), d("trabzon", "Of", 40.9491, 40.2702),
            d("trabzon", "Ortahisar", 41.0034, 39.7241), d("trabzon", "Şalpazarı", 40.9414, 39.1928),
            d("trabzon", "Sürmene", 40.9125, 40.1147), d("trabzon", "Tonya", 40.8865, 39.2908),
            d("trabzon", "Vakfıkebir", 41.0484, 39.2786), d("trabzon", "Yomra", 40.9587, 39.8509)
        ]),
        .init(id: "tunceli", name: "Tunceli", country: "Türkiye", utcOffset: 3, districts: [
            d("tunceli", "Merkez", 39.1065, 39.5476), d("tunceli", "Çemişgezek", 39.0609, 38.9120),
            d("tunceli", "Hozat", 39.1076, 39.2193), d("tunceli", "Mazgirt", 39.0203, 39.6041),
            d("tunceli", "Nazımiye", 39.1804, 39.8286), d("tunceli", "Ovacık", 39.3577, 39.2163),
            d("tunceli", "Pertek", 38.8677, 39.3245), d("tunceli", "Pülümür", 39.4856, 39.8978)
        ]),
        .init(id: "sanliurfa", name: "Şanlıurfa", country: "Türkiye", utcOffset: 3, districts: [
            d("sanliurfa", "Akçakale", 36.7137, 38.9484), d("sanliurfa", "Birecik", 37.0238, 37.9903),
            d("sanliurfa", "Bozova", 37.3621, 38.5229), d("sanliurfa", "Ceylanpınar", 36.8474, 40.0489),
            d("sanliurfa", "Eyyübiye", 37.1483, 38.7830), d("sanliurfa", "Halfeti", 37.2436, 37.8695),
            d("sanliurfa", "Haliliye", 37.1674, 38.7954), d("sanliurfa", "Harran", 36.8588, 39.0333),
            d("sanliurfa", "Hilvan", 37.5878, 38.9543), d("sanliurfa", "Karaköprü", 37.2158, 38.7969),
            d("sanliurfa", "Siverek", 37.7551, 39.3165), d("sanliurfa", "Suruç", 36.9737, 38.4229),
            d("sanliurfa", "Viranşehir", 37.2275, 39.7613)
        ]),
        .init(id: "usak", name: "Uşak", country: "Türkiye", utcOffset: 3, districts: [
            d("usak", "Merkez", 38.6738, 29.4056), d("usak", "Banaz", 38.7399, 29.7531),
            d("usak", "Eşme", 38.3983, 28.9689), d("usak", "Karahallı", 38.3189, 29.5295),
            d("usak", "Sivaslı", 38.5001, 29.6839), d("usak", "Ulubey", 38.4169, 29.2910)
        ]),
        .init(id: "van", name: "Van", country: "Türkiye", utcOffset: 3, districts: [
            d("van", "Bahçesaray", 38.1235, 42.8072), d("van", "Başkale", 38.0433, 44.0185),
            d("van", "Çaldıran", 39.1373, 43.9131), d("van", "Çatak", 38.0069, 43.0591),
            d("van", "Edremit", 38.4142, 43.2623), d("van", "Erciş", 39.0289, 43.3591),
            d("van", "Gevaş", 38.2953, 43.1105), d("van", "Gürpınar", 38.3226, 43.4092),
            d("van", "İpekyolu", 38.4959, 43.3934), d("van", "Muradiye", 38.9902, 43.7611),
            d("van", "Özalp", 38.6580, 43.9899), d("van", "Saray", 38.6486, 44.1697),
            d("van", "Tuşba", 38.5252, 43.3542)
        ]),
        .init(id: "yozgat", name: "Yozgat", country: "Türkiye", utcOffset: 3, districts: [
            d("yozgat", "Merkez", 39.8187, 34.8047), d("yozgat", "Akdağmadeni", 39.6598, 35.8825),
            d("yozgat", "Aydıncık", 40.1290, 35.2858), d("yozgat", "Boğazlıyan", 39.1928, 35.2461),
            d("yozgat", "Çandır", 39.2435, 35.5145), d("yozgat", "Çayıralan", 39.3049, 35.6445),
            d("yozgat", "Çekerek", 40.0693, 35.4948), d("yozgat", "Kadışehri", 39.9950, 35.7905),
            d("yozgat", "Saraykent", 39.6905, 35.5112), d("yozgat", "Sarıkaya", 39.4936, 35.3754),
            d("yozgat", "Şefaatli", 39.5002, 34.7591), d("yozgat", "Sorgun", 39.8095, 35.1854),
            d("yozgat", "Yenifakılı", 39.2110, 35.0019), d("yozgat", "Yerköy", 39.6419, 34.4697)
        ]),
        .init(id: "zonguldak", name: "Zonguldak", country: "Türkiye", utcOffset: 3, districts: [
            d("zonguldak", "Merkez", 41.4523, 31.7878), d("zonguldak", "Alaplı", 41.1803, 31.3860),
            d("zonguldak", "Çaycuma", 41.4235, 32.0817), d("zonguldak", "Devrek", 41.2190, 31.9560),
            d("zonguldak", "Ereğli", 41.2842, 31.4133), d("zonguldak", "Gökçebey", 41.3061, 32.1433),
            d("zonguldak", "Kilimli", 41.4915, 31.8394), d("zonguldak", "Kozlu", 41.4352, 31.7445)
        ]),
        .init(id: "aksaray", name: "Aksaray", country: "Türkiye", utcOffset: 3, districts: [
            d("aksaray", "Merkez", 38.3708, 34.0272), d("aksaray", "Ağaçören", 38.8699, 33.9176),
            d("aksaray", "Eskil", 38.4015, 33.4129), d("aksaray", "Gülağaç", 38.3937, 34.3468),
            d("aksaray", "Güzelyurt", 38.2744, 34.3712), d("aksaray", "Ortaköy", 38.7366, 34.0392),
            d("aksaray", "Sarıyahşi", 38.9803, 33.8431), d("aksaray", "Sultanhanı", 38.2474, 33.5489)
        ]),
        .init(id: "bayburt", name: "Bayburt", country: "Türkiye", utcOffset: 3, districts: [
            d("bayburt", "Merkez", 40.2533, 40.2254), d("bayburt", "Aydıntepe", 40.3889, 40.1473),
            d("bayburt", "Demirözü", 40.1638, 39.8919)
        ]),
        .init(id: "karaman", name: "Karaman", country: "Türkiye", utcOffset: 3, districts: [
            d("karaman", "Merkez", 37.1811, 33.2222), d("karaman", "Ayrancı", 37.3618, 33.6893),
            d("karaman", "Başyayla", 36.7527, 32.6822), d("karaman", "Ermenek", 36.6388, 32.8901),
            d("karaman", "Kazımkarabekir", 37.2273, 32.9590), d("karaman", "Sarıveliler", 36.6968, 32.6154)
        ]),
        .init(id: "kirikkale", name: "Kırıkkale", country: "Türkiye", utcOffset: 3, districts: [
            d("kirikkale", "Merkez", 39.8393, 33.5061), d("kirikkale", "Bahşılı", 39.8133, 33.4718),
            d("kirikkale", "Balışeyh", 39.9102, 33.7211), d("kirikkale", "Çelebi", 39.4646, 33.5255),
            d("kirikkale", "Delice", 39.9435, 34.0326), d("kirikkale", "Karakeçili", 39.5932, 33.3781),
            d("kirikkale", "Keskin", 39.6731, 33.6136), d("kirikkale", "Sulakyurt", 40.1576, 33.7172),
            d("kirikkale", "Yahşihan", 39.8518, 33.4528)
        ]),
        .init(id: "batman", name: "Batman", country: "Türkiye", utcOffset: 3, districts: [
            d("batman", "Merkez", 37.8795, 41.1241), d("batman", "Beşiri", 37.9172, 41.2919),
            d("batman", "Gercüş", 37.5665, 41.3852), d("batman", "Hasankeyf", 37.7308, 41.4180),
            d("batman", "Kozluk", 38.1927, 41.4899), d("batman", "Sason", 38.3339, 41.4146)
        ]),
        .init(id: "sirnak", name: "Şırnak", country: "Türkiye", utcOffset: 3, districts: [
            d("sirnak", "Merkez", 37.5183, 42.4625), d("sirnak", "Beytüşşebap", 37.5704, 43.1665),
            d("sirnak", "Cizre", 37.3324, 42.1855), d("sirnak", "Güçlükonak", 37.4715, 41.9159),
            d("sirnak", "Idil", 37.3428, 41.8878), d("sirnak", "Silopi", 37.2470, 42.4688),
            d("sirnak", "Uludere", 37.4468, 42.8473)
        ]),
        .init(id: "bartin", name: "Bartın", country: "Türkiye", utcOffset: 3, districts: [
            d("bartin", "Merkez", 41.6321, 32.3362), d("bartin", "Amasra", 41.7470, 32.3855),
            d("bartin", "Kurucaşile", 41.8438, 32.7205), d("bartin", "Ulus", 41.5830, 32.6391)
        ]),
        .init(id: "ardahan", name: "Ardahan", country: "Türkiye", utcOffset: 3, districts: [
            d("ardahan", "Merkez", 41.1129, 42.7023), d("ardahan", "Çıldır", 41.1288, 43.1326),
            d("ardahan", "Damal", 41.3416, 42.8407), d("ardahan", "Göle", 40.7933, 42.6095),
            d("ardahan", "Hanak", 41.2333, 42.8477), d("ardahan", "Posof", 41.5096, 42.7276)
        ]),
        .init(id: "igdir", name: "Iğdır", country: "Türkiye", utcOffset: 3, districts: [
            d("igdir", "Merkez", 39.9200, 44.0436), d("igdir", "Aralık", 39.8736, 44.5160),
            d("igdir", "Karakoyunlu", 39.9717, 44.1724), d("igdir", "Tuzluca", 40.0400, 43.6631)
        ]),
        .init(id: "yalova", name: "Yalova", country: "Türkiye", utcOffset: 3, districts: [
            d("yalova", "Merkez", 40.6567, 29.2835), d("yalova", "Altınova", 40.6943, 29.5088),
            d("yalova", "Armutlu", 40.5192, 28.8259), d("yalova", "Çiftlikköy", 40.6646, 29.3227),
            d("yalova", "Çınarcık", 40.6465, 29.1173), d("yalova", "Termal", 40.6062, 29.1742)
        ]),
        .init(id: "karabuk", name: "Karabük", country: "Türkiye", utcOffset: 3, districts: [
            d("karabuk", "Merkez", 41.2058, 32.6232), d("karabuk", "Eflani", 41.4234, 32.9558),
            d("karabuk", "Eskipazar", 40.9429, 32.5305), d("karabuk", "Ovacık", 41.0754, 32.9198),
            d("karabuk", "Safranbolu", 41.2492, 32.6831), d("karabuk", "Yenice", 41.2035, 32.3210)
        ]),
        .init(id: "kilis", name: "Kilis", country: "Türkiye", utcOffset: 3, districts: [
            d("kilis", "Merkez", 36.7165, 37.1145), d("kilis", "Elbeyli", 36.6749, 37.4669),
            d("kilis", "Musabeyli", 36.8849, 36.9177), d("kilis", "Polateli", 36.8408, 37.1428)
        ]),
        .init(id: "osmaniye", name: "Osmaniye", country: "Türkiye", utcOffset: 3, districts: [
            d("osmaniye", "Merkez", 37.0739, 36.2451), d("osmaniye", "Bahçe", 37.2032, 36.5816),
            d("osmaniye", "Düziçi", 37.2401, 36.4535), d("osmaniye", "Hasanbeyli", 37.1309, 36.5559),
            d("osmaniye", "Kadirli", 37.3673, 36.0966), d("osmaniye", "Sumbas", 37.4536, 36.0247),
            d("osmaniye", "Toprakkale", 37.0677, 36.1444)
        ]),
        .init(id: "duzce", name: "Düzce", country: "Türkiye", utcOffset: 3, districts: [
            d("duzce", "Merkez", 40.8394, 31.1610), d("duzce", "Akçakoca", 41.0878, 31.1174),
            d("duzce", "Çilimli", 40.8955, 31.0461), d("duzce", "Cumayeri", 40.8730, 30.9508),
            d("duzce", "Gölyaka", 40.7747, 30.9979), d("duzce", "Gümüşova", 40.8455, 30.9384),
            d("duzce", "Kaynaşlı", 40.7735, 31.3194), d("duzce", "Yığılca", 40.9605, 31.4444)
        ]),
    ]

    static let abroad: [CityOption] = [
        .init(id: "nyc", name: "New York", country: "ABD", utcOffset: -5, districts: [
            d("nyc", "Manhattan", 40.7831, -73.9712), d("nyc", "Brooklyn", 40.6782, -73.9442),
            d("nyc", "Queens", 40.7282, -73.7949), d("nyc", "Bronx", 40.8448, -73.8648)
        ]),
        .init(id: "london", name: "Londra", country: "İngiltere", utcOffset: 0, districts: [
            d("london", "Westminster", 51.4975, -0.1357), d("london", "Camden", 51.5290, -0.1255),
            d("london", "Hackney", 51.5450, -0.0553), d("london", "Greenwich", 51.4826, -0.0077)
        ])
    ]
}

