# ⚡ LarrkMod for Telegram & Swiftgram (`ph.telegra.Telegraph` / `app.swiftgram.ios`)

[![Build LarrkMod Tweak](https://github.com/F1arLesss/LarrkMod/actions/workflows/build.yml/badge.svg)](https://github.com/F1arLesss/LarrkMod/actions/workflows/build.yml)
[![Release](https://img.shields.io/github/v/release/F1arLesss/LarrkMod?style=flat&color=9d4edd)](https://github.com/F1arLesss/LarrkMod/releases)
[![Platform](https://img.shields.io/badge/Platform-iOS%2014.0%2B-blue.svg)](https://apple.com)
[![Architecture](https://img.shields.io/badge/Arch-arm64-success.svg)](https://github.com/F1arLesss/LarrkMod)

Автономный iOS-твик **LarrkMod** для официального клиента **Telegram** (`ph.telegra.Telegraph`) и **Swiftgram** (`app.swiftgram.ios`). Разработан специально для сайдлоадинга через Sideloadly, ESign, TrollStore, Scarlet и AltStore на не-джейлбрейкнутых устройствах (iOS 14 - 18+).

---

## 🌟 Основные возможности

### 0. 🚀 Встроенный Jailed Sideload Fix (Решение черного экрана и вылетов при логине)
- **Спуфинг Bundle ID (`ph.telegra.Telegraph`):** автоматическая подмена бандла для главного модуля, исключающая сбои при смене Team ID и подписи.
- **Автоматический редирект AppGroup:** при запуске на не-джейлбрейкнутых устройствах (с бесплатным Apple ID и измененным Bundle ID) системный вызов `containerURLForSecurityApplicationGroupIdentifier:` перенаправляется в `<Documents>/AppGroup/telegram-data`.
- **Редирект NSUserDefaults Suite:** вызовы `initWithSuiteName:` для групп `group.*`, `telegraph` и `telegram` автоматически перенаправляются на рабочий `standardUserDefaults`.
- **Безопасный Keychain через Fishhook (без MSHookFunction):** перехват `SecItemAdd`, `SecItemCopyMatching`, `SecItemUpdate`, `SecItemDelete` только для бинарников внутри `.app/`, удаление `kSecAttrAccessGroup` и замена `kSecAttrAccessible` на `kSecAttrAccessibleAfterFirstUnlock`.
- **Надежный Fallback авторизации (`Documents/keychain_fallback.plist`):** предотвращение `abort()` и ошибок `-34018` при СМС-авторизации.
- **Блокировка рекламы сторонних сайтов:** подавление баннеров `FCAlertView`, `iOSGods`, `ArmConverter` и `JHBannerView`.

### 1. 🛡️ Анти-Удаление сообщений
- Сохраняет удаленные собеседником или администратором сообщения прямо в чате.
- Удаленные сообщения подсвечиваются полупрозрачным стилем (`alpha = 0.45`).
- Встроенный менеджер истории с возможностью просмотра счетчика и очистки кэша.

### 2. 👻 Приватность и Ghost Mode (8 независимых тумблеров)
Блокировка отправки MTProto TL-пакетов на сервера Telegram:
1. **Отключить Онлайн-Статус:** принудительная передача `offline = true` в `account.updateStatus` (вы всегда офлайн).
2. **Отключить статус ввода текста:** блокировка статуса «печатает...» (`0x16bf744e`).
3. **Отключить статус записи видео:** блокировка записи видеосообщений и кружочков (`0xa187d66f`, `0x88f27fbc`).
4. **Отключить статус загрузки видео:** блокировка отправки статуса выгрузки видео (`0xe9763aec`, `0x243e1c66`).
5. **Отключить статус записи голосового:** скрытие индикатора записи ГС (`0xd52f73f7`).
6. **Отключить статус загрузки голосового:** скрытие статуса выгрузки аудиофайла (`0xf351d7ab`).
7. **Отключить статус загрузки фото:** скрытие индикатора отправки фотографий (`0xd1d34a26`).
8. **Отключить статус загрузки файлов:** скрытие отправки документов (`0xaa0cd9e4`).

### 3. ⭐ Локальный Telegram Premium
- Клиентская активация Telegram Premium.
- Премиальная звездочка в профиле, разблокировка премиум-реакций и расширенных клиентских настроек.

### 4. 🎁 Локальный NFT-Подарок и Профиль
- Пресеты популярных NFT-подарков: `Pool Float 🛟`, `Plush Pepe 🐸`, `Durov's Cap 🧢`, `Astral Shard 💎`.
- Поддержка загрузки **любого кастомного изображения** из медиатеки (`UIImagePickerController`) с сохранением в `Documents/larrk_nft.png`.
- Выбор стильного градиента шапки профиля:
  - 🟣 Cyber Purple
  - 🔵 Ocean Blue
  - 🟡 Golden Star
  - 🟢 Emerald Neon
- Кастомный паттерн-эмодзи фона (например: `⚡`, `👑`, `💎`).
- Кнопка мгновенного применения и кнопка полного сброса.

### 5. 💫 Локальные Telegram Stars
- Визуальная подмена баланса Stars во всех экранах приложения.
- Ручной ввод любого количества звезд.
- Кнопки быстрого добавления (`+1 000 ⭐`, `+10 000 ⭐`, `+50 000 ⭐`).

---

## 🎯 Активация меню LarrkMod в приложении

В твик встроен скрытый интеллектуальный триггер удержания таббара:
1. Зажмите область таббара в левой части экрана (на вкладке **«Чаты»**).
2. **Первую 1.0 секунду** ничего не происходит, штатные жесты не блокируются.
3. Как только прошла 1.0 секунда — срабатывает легкий тактильный отклик (`UIImpactFeedbackGenerator`), стандартное контекстное меню Swiftgram подавляется, и над таббаром плавно всплывает неоновый темный HUD.
4. В течение **следующих 3.0 секунд** ползунок плавно заполняется от 0% до 100% с отображением обратного отсчета: `"Удерживайте еще 3.0 сек для LarrkMod..."`.
5. По завершении 3 секунд раздается виброотклик успеха (`UINotificationFeedbackGenerator`), ползунок скрывается и открывается полноценное темное меню `LarrkModViewController`.
6. Если отпустить палец раньше — HUD плавно исчезает без ложных срабатываний.

---

## ⚙️ Архитектура без внешних зависимостей

Твик написан на чистом **Objective-C / Objective-C++ (`.mm`)**:
- Использует стандартный рантайм `<objc/runtime.h>` (`objc_getClass`, `class_getInstanceMethod`, `method_exchangeImplementations`, `class_addMethod`).
- Инициализируется через конструктор `__attribute__((constructor)) static void LarrkModInit(void)`.
- **Полное отсутствие `CydiaSubstrate.framework` или `libhooker`**, что гарантирует 100% стабильность и отсутствие крэшей при инжекте на стоковых не-джейлбрейкнутых версиях iOS.

Структура каталогов:
```text
LarrkMod/
├── .github/
│   └── workflows/
│       └── build.yml               # CI/CD сборка dylib и создание Release v1.0.0
├── src/
│   ├── LarrkConfig.h               # Заголовок менеджера настроек
│   ├── LarrkConfig.mm              # Персистентное хранение настроек (NSUserDefaults)
│   ├── LarrkGestureOverlay.h       # Заголовок перехватчика жестов
│   ├── LarrkGestureOverlay.mm      # HUD, CADisplayLink и логика удержания 1с + 3с
│   ├── LarrkModViewController.h    # Заголовок меню настроек
│   ├── LarrkModViewController.mm   # Графический интерфейс в стиле Telegram Dark
│   └── LarrkHooks.mm               # Безопасные рантайм-хуки Swiftgram/MTProto
├── .gitignore                      # Исключения сборки
└── README.md                       # Документация проекта
```

---

## 🚀 Установка через Sideloadly

1. Скачайте последнюю версию `LarrkMod.dylib` из [Releases](https://github.com/F1arLesss/LarrkMod/releases).
2. Скачайте `.ipa` Swiftgram (или используйте IPA, экспортированный через Decrypted App Store).
3. Запустите **Sideloadly** на компьютере (macOS или Windows) и подключите iPhone кабелем.
4. Перетащите `.ipa` файл Swiftgram в окно Sideloadly.
5. Нажмите **Advanced Options**.
6. В разделе **Dylibs / Frameworks** нажмите **+** и выберите `LarrkMod.dylib`.
7. Укажите свой Apple ID и нажмите **Start**.
8. После установки откройте приложение на устройстве, перейдите в *Настройки -> Основные -> VPN и управление устройством* и подтвердите профиль разработчика.

---

## ☁️ Облачная компиляция через GitHub Actions

Сборка происходит автоматически при каждом push в ветку `main` в GitHub Actions на раннере `macos-latest`:
```bash
xcrun -sdk iphoneos clang++ \
  -dynamiclib \
  -arch arm64 \
  -isysroot $(xcrun -sdk iphoneos --show-sdk-path) \
  -miphoneos-version-min=14.0 \
  -fobjc-arc \
  -framework UIKit -framework Foundation -framework QuartzCore -framework CoreGraphics -framework AudioToolbox \
  -Wl,-install_name,@executable_path/Frameworks/LarrkMod.dylib \
  -O2 \
  src/*.mm -o LarrkMod.dylib
```
Собранный файл автоматически подписывается ad-hoc подписью (`codesign -f -s - LarrkMod.dylib`) и прикрепляется к релизу **v1.0.0**.

---

## 📜 Лицензия
Проект распространяется для образовательных целей и личного использования.
Разработано с ❤️ для комьюнити реверс-инжиниринга iOS.
