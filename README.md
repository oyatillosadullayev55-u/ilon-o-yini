# Snake Neon Ultimate Pro

Flutter asosidagi "Ilon" (Snake) o'yini. Ilon real ko'rinishda chiziladi: uzluksiz, ingichkalashuvchi tanasi, pullaqka naqshi, ko'zli va tilli boshi hamda kataklar orasida silliq siljiydigan harakati bilan.

## Xususiyatlari

**5 ta o'yin rejimi**

| Rejim | Tavsif |
|---|---|
| Klassik | Devorga urilsa o'yin tugaydi |
| Cheksiz | Taxta chetidan chiqib, qarama-qarshi tomondan kiradi |
| Time Attack | 60 soniya ichida imkon qadar ko'p ball to'plash |
| Obstacle | Taxtada 5 ta to'siq, ularga urilsa bo'lmaydi |
| Survival | Yuqori boshlang'ich tezlik (130 ms) bilan boshlanadi |

**Grafika va animatsiya**
- `CustomPainter` orqali ilon tanasi: markaziy chiziqni teng bo'laklarga ajratish, kenglik profili (bo'yin → tana → dumi), tanaga qoplamali soya va yorug'lik effektlari.
- Yumshoq nur (glow) uchun `MaskFilter.blur`, gradient terilar.
- Har bir qadam orasida pozitsiya interpolatsiyasi — ilon sakramay, silliq siljiydi.
- Yemak yeyilganda zarrachalar (particles) va suzuvchi "+10" yozuvlari chiqadi.
- Daraja oshganda banner, o'yin oxirida ilon qizil rangga bo'yaladi (death glow).

**Boshqaruv**
- Sensorli: ekrandagi yo'nalish tugmalari va taxta ustidan sudrash (swipe).
- Klaviatura: strelkalar yoki `W/A/S/D`, `Space` — pauza/davom etish, `Enter` — boshlash.
- Pauza oynasi, tebranish (haptic) va ovoz effektlari sozlamalar orqali yoqiladi/yopiladi.

**Progress va iqtisodiyot**
- Tanga (coins), tajriba (XP) va daraja tizimi; har 10 ballda daraja oshadi va tezlik tezlashadi.
- Do'konda 5 ta ilon terisi: Classic Neon (bepul), Fire Snake (50), Ice Snake (100), Galaxy Snake (200), Golden Snake (500).
- Statistika: jami o'yinlar, yeyilgan yemaklar, eng uzun ilon va har bir rejim bo'yicha rekord.
- Bonus yemak 5 soniyaga paydo bo'ladi va +30 ball beradi.
- Butun taxtani to'ldirsangiz **G'ALABA** holati chiqadi (o'yin hech qachon qotib qolmaydi).
- Barcha ma'lumotlar `shared_preferences` da saqlanadi.

## Loyiha tuzilishi

```
lib/
├── main.dart                      # MaterialApp, neon qorong'i mavzu
├── models/
│   ├── animation_models.dart      # Particle, FloatingScore (to'r birliklarida)
│   ├── direction.dart             # Yo'nalish yordamchilari
│   └── game_enums.dart            # GameMode, GameState, SnakeSkinInfo, GameSkins
├── screens/
│   ├── main_menu_screen.dart      # Rejim tanlash, bosh menyu
│   ├── game_screen.dart           # O'yin mantiqi, holat, klaviatura, dialoglar
│   ├── shop_screen.dart           # Teri sotib olish va kiyish
│   ├── stats_screen.dart          # Rekordlar va statistika
│   └── settings_screen.dart       # Ovoz / vibratsiya
├── services/
│   └── game_storage_service.dart  # shared_preferences qatlami
└── widgets/
    ├── game_board.dart            # UltraSnakePainter — ilon va effektlarni chizadi
    └── score_board.dart           # Yuqoridagi ball/tezlik paneli
```

O'yin maydoni: 20 qator × 15 ustun. Ilon `List<int>` (yassi katak indeklari) sifatida saqlanadi; cheksiz rejimda tana bir necha uzluk bo'lakka ajratiladi.

## Ishga tushirish

Talab: Flutter 3.x (Dart SDK ^3.13.4).

```bash
flutter pub get
flutter run
```

## Tekshirish

```bash
flutter analyze --no-pub
flutter test
```

- `test/overflow_test.dart` — kichik ekranlarda (320×480) do'kon, bosh menyu va o'yin tugash dialogida RenderFlex overflow chiqmasligini tekshiradi.
- `test/gameplay_test.dart` — pauza oynasi ochilish/yopilish va klaviatura boshqaruvini simulyatsiya qiladi.

## Eslatma

Loyihada rasm yoki shrift resurslari ishlatilmaydi — barcha grafika kod orqali chiziladi.
