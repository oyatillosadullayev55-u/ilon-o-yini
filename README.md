# Snake 3D Neon Ultimate

Flutter asosidagi "Ilon" (Snake) o'yini. Butun grafika **kod orqali** chiziladi:
haqiqiy 3D kamera (pinhole proyektsiya), chuqurlik bo'yicha saralash,
shishasimon (glassmorphism) interfeys va ilonning real ko'rinishdagi tanasi —
hech qanday rasm yoki 3D dvigatel ishlatilmaydi.

## Xususiyatlari

**5 ta o'yin rejimi**

| Rejim | Tavsif |
|---|---|
| Klassik | Devorga urilsa o'yin tugaydi |
| Cheksiz | Taxta chetidan chiqib, qarama-qarshi tomondan kiradi |
| Time Attack | 60 soniya ichida imkon qadar ko'p ball to'plash |
| Obstacle | Taxtada to'siq bloklar, ularga urilsa bo'lmaydi |
| Survival | Yuqori boshlang'ich tezlik (130 ms) bilan boshlanadi |

### 3D sahna (`lib/render3d/scene3d.dart`)

- Dunyo koordinatalari: `x` — o'ngga, `y` — kameradan uzoqqa, `z` — yuqoriga.
- Kamera taxta markazini nishon oladi: `elevation` (ko'tarilish burchagi),
  `yaw` (burilish), `distanceFactor` (masofa = yarim diagonal × koeffitsient).
- Har bir nuqta pinhole formula bilan ekranga tushiriladi va
  `perspective` (1.0 = markaz) hamda `unit` (o'sha chuqurlikdagi 1 katak px) qaytadi.
- **Avtomatik moslash**: taxta burchaklari `f = 1` holatda proyeksirlanib,
  sahna paneldan to'liq joy olishi uchun masshtab hisoblanadi.
- **`autoTiltTo`**: panel vertikal cho'ziq bo'lsa (smartfon), kamera sekin
  tiklanadi va taxta bo'sh joyqoldirmaydi — keng panellarda esa qiyalik saqlanadi.
- **Painter algoritmi**: barcha jismlar `DepthSorted(depth, paint)` sifatida
  yig'iladi va uzoqdan yaqinga saralanib chiziladi.

### Ilon va effektlar (`lib/widgets/game_board_3d.dart`)

- Ilon — uzunlik bo'yicha tenglashgan (`_step = 0.24`) sharlar zanjiri:
  bo'yin (0.30) → tana (0.355) → dum (2.6 kataklik ingichkalashuv).
- Har bir shar `RadialGradient` shader + `translate/scale` bilan chiziladi
  (`MaskFilter`/`saveLayer` ishlatilmaydi — tezlik uchun), shaderlar rang
  bo'yicha 5 bit/kanel keshlanadi.
- Bosh — Bezier shakli, yorug' nuqtali ko'zlar, ayiqcha qorachiq va
  tilli, harakatlanuvchi til.
- Pol ustida **kontakt soyalar** (decal), ilon ortidan yuruvchi izlar.
- Yemak — 3D olma (salqin nur va barg), bonus yemak — 8 qirrali **gomometrik tosh**.
- To'siqlar — yuzalari yorug'likka qarab soyalanadigan 3D bloklar.
- Qadamlar orasida **interpolatsiya**: harakat devor soatidan hisoblanadi,
  shuning uchun ilon sakramaydi; cheksiz rejimda chiziq uzilish joyida
  bir necha zanjirga bo'linadi.
- Zarrachalar va "+10" yozuvlari 3D mayfonda uchadi (tortishish va sakrash bilan).
- O'yin oxirida **death glow**: taxta ramqizi rangga o'zgaradi va halqa tarqaladi.

### Interfeys (`lib/widgets/ui_kit.dart`, `lib/theme/app_theme.dart`)

- `NeonBackground` — animatsion 3D perspektiv to'r, nur dog'lari va vinyetka.
- `GlassPanel` — `BackdropFilter` + gradient + nurli chegara (glassmorphism).
- `NeonButton` / `GlassButton` / `StatPill` / `NeonTitle` / `SectionLabel`.
- `FadeScaleRoute` — sahifalar orasidagi xira + masshtab o'tishi.
- Barcha ekranlar (menyu, o'yin, do'kon, statistika, sozlamalar) shu kit ustiga qurilgan;
  bosh menyuda **jonli 3D preview** (aylanma yo'ldagi ilon), do'konda har bir teri
  uchun alohida 3D namuna.

**Boshqaruv**
- Sensorli: ekrandagi yo'nalish tugmalari va taxta ustidan sudrash (swipe).
- Klaviatura: strelkalar yoki `W/A/S/D`, `P` — pauza, `Space` — boshlash/davom etish.
- Pauza pardasi, tebranish (haptic) va ovoz effektlari sozlamalar orqali boshqariladi.

**Progress va iqtisodiyot**
- Tanga, tajriba (XP) va daraja tizimi; har 10 ballda daraja oshadi va tezlik tezlashadi.
- Do'konda 5 ta teri: Classic Neon (bepul), Fire (50), Ice (100), Galaxy (200), Golden (500).
- Statistika: jami o'yinlar, yeyilgan yemaklar, eng uzun ilon va har bir rejim bo'yicha rekord
  (animatsion sanoq va progress chiziqlari bilan).
- Bonus yemak 5 soniyaga paydo bo'ladi va +30 ball beradi.
- Butun taxtani to'ldirsangiz **G'ALABA** holati chiqadi (o'yin hech qachon qotib qolmaydi).
- Barcha ma'lumotlar `shared_preferences` da saqlanadi.

## Loyiha tuzilishi

```
lib/
├── main.dart                      # MaterialApp, qorong'i neon mavzu
├── models/
│   ├── animation_models.dart      # Particle, FloatingScore (katak birliklari + z balandlik)
│   ├── direction.dart             # Yo'nalish yordamchilari
│   └── game_enums.dart            # GameMode, GameState, SnakeSkinInfo, GameSkins
├── render3d/
│   └── scene3d.dart               # V3, Projected, DepthSorted, Scene3D (kamera + proyektsiya)
├── screens/
│   ├── main_menu_screen.dart      # Rejim tanlash + jonli 3D preview
│   ├── game_screen.dart           # O'yin mantiqi, holat, klaviatura, dialoglar
│   ├── shop_screen.dart           # Terilar (har biri 3D namunada)
│   ├── stats_screen.dart          # Rekordlar va statistika
│   └── settings_screen.dart       # Ovoz / vibratsiya / daraja
├── services/
│   └── game_storage_service.dart  # shared_preferences qatlami
├── theme/
│   └── app_theme.dart             # AppTheme.dark (Material3) va rang konstantalari
└── widgets/
    ├── game_board_3d.dart         # SnakeScene3D + Scene3DPainter (ilon, yemak, to'siq, effektlar)
    ├── score_board.dart           # Ochko/daraja/rekord paneli va rejim chiplari
    └── ui_kit.dart                # NeonBackground, GlassPanel, NeonButton, FadeScaleRoute...
```

O'yin maydoni: 20 qator × 15 ustun. Ilon `List<int>` (yassi katak indeklari) sifatida
saqlanadi; cheksiz rejimda tana bir necha uzluk bo'lakka ajratiladi.

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

- `test/overflow_test.dart` — kichik ekranlarda (320×480 / 320×568) do'kon, bosh menyu
  va o'yin tugash dialogida RenderFlex overflow chiqmasligini tekshiradi.
- `test/gameplay_test.dart` — pauza pardasi ochilish/yopilish va klaviatura boshqaruvini
  simulyatsiya qiladi.
- `test/storage_test.dart` — `GameStorageService`: tanga, XP/daraja, terilarni qulflash,
  rekord va statistika sikllari (yetarli bo'lmagan xarid tanga ayirmaydi, rekord faqat
  katta natijada yoziladi).
- `test/widget_test.dart` — yechim (smoke) testi.

## Eslatma

Loyihada rasm, model yoki shrift resurslari yo'q — 3D sahna, ilon, yemaklar va
butun interfeys `Canvas` ustida qo'lda chiziladi. Shu sababli `flutter test`
ichida `PictureRecorder` orqali skrinshot olib, render natijasini tekshirish mumkin.

Yangilanishlar ro'yxati: [CHANGELOG.md](CHANGELOG.md).
