# O'zgarishlar tarixi

## 3D versiya — 2026-10-24

### 3D grafika dvigateli (yangi)

- `lib/render3d/scene3d.dart` — qo'lda yozilgan pinhole 3D kamera:
  - dunyo koordinatalari `x` (o'ng), `y` (uzoqqa), `z` (yuqoriga);
  - `elevation`, `yaw`, `distanceFactor` parametrlari;
  - taxta burchaklarini `f = 1` da proyeksirlab, paneldan to'liq joy olish uchun
    masshtabni avtomatik hisoblash;
  - `autoTiltTo` — vertikal cho'ziq panelda kamerani tiklab, taxtaga bo'sh joy
    qoldirmaydi (keng panelda qiyalik saqlanadi);
  - `DepthSorted` — painter algoritmi: jismlar uzoqdan yaqinga saralanadi.
- `lib/widgets/game_board_3d.dart` — `SnakeScene3D` (o'lcham-mustaqil vidget) va
  `Scene3DPainter`:
  - ilon — uzunlik bo'yicha tenglashgan (`_step = 0.24`) sharlar zanjiri,
    bo'yin → tana → dum ingichkalashuvi;
  - `RadialGradient` shader + `translate/scale` (tezlik uchun shaderlar
    5 bit/kanel keshlanadi, `MaskFilter`/`saveLayer` ishlatilmaydi);
  - Bezier bosh, ayiqcha qorachiq, harakatlanuvchi til;
  - pol ustida kontakt soyalar, perspektiv to'r, osmon va yulduzlar;
  - 3D olma, gomometrik bonus tosh, yuzalari soyalangan to'siq bloklar;
  - qadamlar orasida vaqt bo'yicha interpolatsiya, cheksiz rejimda zanjir uzilishi;
  - tortishish kuchiga ega 3D zarrachalar va suzuvchi ochko yozuvlari;
  - o'yin oxirida death glow (ramqa va ilon qizil rangga o'tadi, halqa tarqaladi).
- Eski 2D taxta `lib/widgets/game_board.dart` o'chirildi.

### Interfeys to'plami (yangi)

- `lib/widgets/ui_kit.dart` — `NeonBackground` (animatsion 3D to'r + nur dog'lari +
  vinyetka), `GlassPanel` (`BackdropFilter` glassmorphism), `NeonButton`,
  `GlassButton`, `StatPill`, `NeonTitle`, `SectionLabel`, `FadeScaleRoute`.
- `lib/theme/app_theme.dart` — Material3 qorong'i mavzu va rang konstantalari.

### Ekranlar

- **Bosh menyu** — jonli 3D preview (aylanma yo'ldagi ilon), shishasimon rejim
  chiplari, suzuvchi neon sarlavha, `FadeScaleRoute` o'tishlari.
- **O'yin** — 3D taxta, xira pauza pardasi, shishasimon ochko/daraja paneli,
  animatsion o'yin tugash dialogi (ochko/daraja sanog'i bilan).
- **Do'kon** — har bir teri o'zining 3D namunasi bilan; kiyilgan kartochka nurli
  chegara bilan ajraladi.
- **Statistika** — glass kartochkalar, animatsion sanoq, har bir rejim uchun
  progress chizig'i.
- **Sozlamalar** — daraja/XP bloki, tebranish va ovoz kalitlari, boshqaruv eslatmalari.

### Model va mantiq

- `lib/models/animation_models.dart` — `Particle` va `FloatingScore` endi katak
  birliklarida + `z` balandlikka ega (oldingi koordinata xatosi tuzatildi).
- `GameScreen` — `prevSnakeLength`, devor soatiga asoslangan interpolatsiya va
  o'lim animatsiyasi kontrolleri qo'shildi.

### Testlar va hujjatlar

- `test/storage_test.dart` — tanga, XP/daraja, terilarni qulflash, rekord va
  statistika uchun 5 ta yangi test.
- `test/overflow_test.dart`, `test/gameplay_test.dart` — yangi UI da ham o'tadi
  (jami 11 ta test, `flutter analyze` toza).
- `README.md` — 3D arxitektura, interfeys to'plami va loyiha tuzilishi qayta yozildi;
  `CHANGELOG.md` qo'shildi.

### Cheklov

- O'zgarishlar emulator yoki fizik qurilmada yugurtirilmagan — UI `flutter test`
  ichida `RepaintBoundary` skrinshotlari orqali ko'z bilan tekshirilgan.
