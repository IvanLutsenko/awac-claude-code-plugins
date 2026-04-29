# Отчёт по крашу CPT-3869 (issue 3d51ee648eac0b257dc8171bb7ada514)

## Detailed Analysis

### Краш: IllegalStateException — translucent activity + fixed orientation на Android 8.0

**Базовая информация:**
- Exception: `java.lang.IllegalStateException: Only fullscreen opaque activities can request orientation`
- Затронутые пользователи: 1 пользователь, 1 событие (eventTime 2026-04-03)
- Версии: firstSeen 1.57.0 — lastSeen 1.58.1 (build 168)
- Android API: 26 (Android 8.0.0) — баг исключительно этой версии (AOSP issue 68454016)
- Устройство: Samsung Galaxy S7 (SM-G930L), ARM64
- Компонент: UI / Activity lifecycle (HostActivity старт)

### Анализ stack trace

```
Caused by: java.lang.IllegalStateException: Only fullscreen opaque activities can request orientation
  at android.app.Activity.onCreate(Activity.java:1038)
  at androidx.core.app.ComponentActivity.onCreate(...)
  at androidx.activity.ComponentActivity.onCreate(...)
  at androidx.fragment.app.FragmentActivity.onCreate(...)
  at HostActivity.onCreate(HostActivity.kt:152)
```

Строка 152 — атрибуция Crashlytics к первой строке метода. Реальный source — `super.onCreate(savedInstanceState)` на строке 108. Внутри `Activity.onCreate` Android 8.0 проверяет: translucent тема + фиксированная ориентация → `IllegalStateException`.

### Проверенные файлы

- `core/activities/host-activity/src/main/java/kz/berekebank/business/core/activities/host_activity/HostActivity.kt` — onCreate, строки 105-168
- `app/src/main/AndroidManifest.xml` — строки 134-139 (декларация HostActivity)
- `core/uikit/src/main/res/values/styles.xml` — строки 14-22 (AppTheme)

### Выполненные команды

```
git blame -L 14,22 master -- core/uikit/src/main/res/values/styles.xml
git blame -L 134,140 master -- app/src/main/AndroidManifest.xml
git log master --oneline -10 -- core/uikit/src/main/res/values/styles.xml
git log --all --oneline --grep="CPT-3869"
git ls-tree master -- core/uikit/src/main/res/values-v26/styles.xml
git ls-tree origin/master -- core/uikit/src/main/res/values-v26/styles.xml
git merge-base --is-ancestor d8e45f985c master
```

Результаты git blame (master):
- `values/styles.xml:18-19` (windowTranslucentStatus/Navigation): `451dc1a1ce6` — ivanlutsenko, 2023-04-28
- `AndroidManifest.xml:137` (screenOrientation="portrait"): `ea123d6c7de` — o.krasnonozhenko, 2023-09-20
- `AndroidManifest.xml:138` (theme="@style/AppTheme"): `2fd4d5a07e8` — Beka, 2023-10-03
- `AndroidManifest.xml:134` (HostActivity name): `dcf3bf6f4ee` — Ivan Lutsenko, 2025-01-09 (CPT-1694)

### Root cause

AOSP issue 68454016: на API 26 (только Android 8.0) `Activity.onCreate()` бросает `IllegalStateException` если у активити translucent-тема и фиксированная ориентация. На API 27+ проверку убрали.

В проекте конфликт двух декларативных решений:
1. Translucent-флаги в `AppTheme` (2023-04, иммерсивный статус-бар).
2. `screenOrientation="portrait"` на HostActivity (2023-09).

Безопасно на API < 26 и API ≥ 27, крашится на API 26.

### Предлагаемый fix

**Готовый фикс уже в `origin/master`** — commit `d8e45f985c` (Ivan Lutsenko, 2026-03-12, PR #4331 Release_1.59.0). Локальный `master` отстаёт от origin (`64cb0f6662` vs `8e1b12467f`).

Содержимое фикса — два новых файла:

```xml
<!-- Before: values/styles.xml — действует для всех API -->
<style name="HostActivityTheme" parent="AppTheme">
    <item name="android:windowIsTranslucent">true</item>
    <item name="android:windowBackground">@android:color/transparent</item>
</style>

<!-- After: values-v26/styles.xml — только Android 8.0 -->
<resources>
    <style name="HostActivityTheme" parent="AppTheme">
        <item name="android:windowIsTranslucent">false</item>
        <item name="android:windowBackground">@android:color/white</item>
    </style>
</resources>

<!-- After: values-v27/styles.xml — API 27+ -->
<resources>
    <style name="HostActivityTheme" parent="AppTheme">
        <item name="android:windowIsTranslucent">true</item>
        <item name="android:windowBackground">@android:color/transparent</item>
    </style>
</resources>
```

API 26 получает opaque тему — конфликт исчезает. API 27+ продолжает с translucent.

### Assignee

**Ivan Lutsenko** — фикс подготовлен и смержен в `origin/master`.
- Источник: `git log --all --grep="CPT-3869"` — три коммита `fix: [CPT-3869] ...`, попавшие в `origin/master` через PR #4331.
- Альтернативные кандидаты: o.krasnonozhenko (manifest:137), Beka (manifest:138).

### Context & Prevention

- **Trigger**: холодный старт на Android 8.0.0 → `super.onCreate` → системная проверка → `IllegalStateException`.
- **Why now**: комбинация существует с октября 2023. Краш виден только на API 26 — узкая прослойка устройств (S7 на стоковой 8.0). Single-event report — статистический хвост.
- **Prevention**:
  1. Smoke-тест запуска на эмуляторе API 26 portrait в CI.
  2. Чек-лист PR: новые `screenOrientation` в манифесте → требуется `values-v26/` оверрайд.
  3. Долгосрочно — отказ от `windowTranslucentStatus/Navigation` в пользу `enableEdgeToEdge()` (уже используется в `HostActivity.onCreate:110`).

---

## JIRA Brief

**Crash**: IllegalStateException "Only fullscreen opaque activities can request orientation" на Android 8.0
**Component**: app / core/uikit (manifest + theme)
**Assignee**: Ivan Lutsenko (git log --grep=CPT-3869, git blame styles.xml:18)

**Problem**: на Android 8.0.0 приложение крашится сразу при запуске.

**Stack trace**:
```
Caused by: java.lang.IllegalStateException: Only fullscreen opaque activities can request orientation
  at android.app.Activity.onCreate(Activity.java:1038)
  at androidx.fragment.app.FragmentActivity.onCreate(FragmentActivity.java:216)
  at kz.berekebank.business.core.activities.host_activity.HostActivity.onCreate(HostActivity.kt:152)
```

**Cause**: AppTheme (`core/uikit/.../values/styles.xml:18-19`) — `windowTranslucentStatus=true` + `windowTranslucentNavigation=true`. Манифест (`app/src/main/AndroidManifest.xml:137`) — `screenOrientation="portrait"`. На API 26 (AOSP 68454016) — `IllegalStateException`.

**Fix**: уже реализован — commit `d8e45f985c`, в `origin/master` через PR #4331.

```xml
<!-- Before: только values/styles.xml, действует для всех API -->
<style name="HostActivityTheme" parent="AppTheme">
    <item name="android:windowIsTranslucent">true</item>
    <item name="android:windowBackground">@android:color/transparent</item>
</style>

<!-- After: values-v26/styles.xml (NEW, только Android 8.0) -->
<resources>
    <style name="HostActivityTheme" parent="AppTheme">
        <item name="android:windowIsTranslucent">false</item>
        <item name="android:windowBackground">@android:color/white</item>
    </style>
</resources>

<!-- After: values-v27/styles.xml (NEW, API 27+) -->
<resources>
    <style name="HostActivityTheme" parent="AppTheme">
        <item name="android:windowIsTranslucent">true</item>
        <item name="android:windowBackground">@android:color/transparent</item>
    </style>
</resources>
```

**Reproduction**:
1. Установить APK 1.58.1 (build 168) на Samsung Galaxy S7 (SM-G930L) с Android 8.0.0 (или эмулятор API 26 portrait).
2. Запустить приложение из launcher.
3. Немедленный краш на холодном старте до показа UI.

**Firebase**: https://console.firebase.google.com/project/sberbusiness-bef19/crashlytics/app/android:kz.berekebank.business.app/issues/3d51ee648eac0b257dc8171bb7ada514

---

## Статус тикета

Фикс уже в `origin/master` (PR #4331 Release_1.59.0). Перед закрытием тикета — убедиться:
1. Релиз 1.59.0+ выкатили в продакшен.
2. После 1.59.0 событие 3d51ee648e... в Crashlytics не повторяется.
