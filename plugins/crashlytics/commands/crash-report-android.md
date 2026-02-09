---
description: Анализ логов Android Crashlytics с обязательным git blame анализом и фиксами на уровне кода. Мультиагентная архитектура: classifier-android → firebase-fetcher → forensics-android.
allowed-tools: Bash(git log:*), Bash(git blame:*), Bash(which firebase:*), Bash(firebase *:*), Bash(python3:*), Bash(curl:*), Task
---

# Android Crash Analysis - Multi-Agent Edition

Анализ краш-ошибок из Firebase Crashlytics с использованием трёх специализированных агентов.

**ВАЖНО**: ВСЕ ответы, анализы, отчёты и коммуникация ТОЛЬКО НА РУССКОМ ЯЗЫКЕ.

## Multi-Agent Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     /crash-report                               │
└─────────────────────────────────────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        ▼                     ▼                     ▼
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│  classifier  │───▶│  fetcher     │───▶│  forensics   │
│  (Haiku)     │    │  (Haiku)     │    │  (Sonnet)    │
│              │    │              │    │              │
│ Priority     │    │ Firebase     │    │ Git blame    │
│ Component    │    │ Stack traces │    │ Code search  │
│ Trigger      │    │ Device info  │    │ Assignee     │
└──────────────┘    └──────────────┘    └──────────────┘
```

## Workflow

### ШАГ 0: Firebase Auto-Init (выполняется автоматически!)

**Перед началом работы** проверь и настрой Firebase. Три уровня доступа: MCP → CLI API → Manual.

**НИКОГДА** не используй `mcp__plugin_crashlytics_firebase__firebase_login` — авторизация через MCP сломана (ошибка "Unable to verify client"). Если CLI не авторизован, проси пользователя выполнить `firebase login` в терминале.

#### Уровень 1: MCP (предпочтительный)

```yaml
1. Загрузи MCP tools:
   ToolSearch: "+firebase get_environment"

2. Попробуй:
   mcp__plugin_crashlytics_firebase__firebase_get_environment

3. Если работает → используй MCP для всех запросов (Шаги 1-5)
4. Если ошибка → переходи к Уровню 2
```

#### Уровень 2: CLI API fallback (через токен Firebase CLI)

Если MCP недоступен, но Firebase CLI авторизован — получи данные через REST API:

```yaml
1. Проверь CLI:
   Bash: which firebase 2>/dev/null && firebase login:list 2>/dev/null

   Если CLI не авторизован → переходи к Уровню 3

2. Получи project_id и app_id через CLI:
   Bash: firebase projects:list --json 2>/dev/null | python3 -c "
     import sys,json
     for p in json.load(sys.stdin)['results']:
       print(f\"{p['projectId']} — {p.get('displayName','')}\")"

   Bash: firebase apps:list --project {PROJECT_ID} --json 2>/dev/null | python3 -c "
     import sys,json
     for a in json.load(sys.stdin)['result']:
       if a.get('platform')=='ANDROID':
         print(f\"{a['appId']} | {a.get('displayName','')}\")"

3. Получи access_token из сохранённых credentials Firebase CLI:
   Bash: python3 -c "
     import json, urllib.request, urllib.parse, os
     config = json.load(open(os.path.expanduser('~/.config/configstore/firebase-tools.json')))
     refresh_token = config['tokens']['refresh_token']
     data = urllib.parse.urlencode({
       'client_id': '563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com',
       'client_secret': 'j9iVZfS8kkCEFUPaAeJV0sAi',
       'refresh_token': refresh_token,
       'grant_type': 'refresh_token'
     }).encode()
     req = urllib.request.Request('https://oauth2.googleapis.com/token', data=data)
     resp = json.loads(urllib.request.urlopen(req).read())
     print(resp['access_token'])"

   ПРИМЕЧАНИЕ: client_id и client_secret — публичные OAuth credentials Firebase CLI
   (встроены в firebase-tools, это installed app OAuth flow)

4. Получи данные краша через Crashlytics REST API:
   Bash: curl -s -H "Authorization: Bearer {ACCESS_TOKEN}" \
     "https://firebasecrashlytics.googleapis.com/v1beta1/projects/{PROJECT_ID}/apps/{APP_ID}/issues/{ISSUE_ID}"

   Bash: curl -s -H "Authorization: Bearer {ACCESS_TOKEN}" \
     "https://firebasecrashlytics.googleapis.com/v1beta1/projects/{PROJECT_ID}/apps/{APP_ID}/issues/{ISSUE_ID}/events?pageSize=3"

5. Парси JSON ответ через python3 и извлеки:
   - title, type (FATAL/NON_FATAL/ANR), status
   - stack traces из events
   - device info, app version
   - event count
```

#### Уровень 3: Manual fallback (ссылка + ручной ввод)

Если ни MCP, ни API не сработали:

```yaml
1. ОБЯЗАТЕЛЬНО сгенерируй ссылку на Firebase Console:
   https://console.firebase.google.com/project/{PROJECT_ID}/crashlytics/app/android:{APP_ID}/issues/{ISSUE_ID}

   Если project_id/app_id известны из CLI (Уровень 2, шаг 2) — подставь их.
   Если нет — попроси пользователя перейти в Firebase Console вручную.

2. Попроси пользователя скопировать из Firebase Console:
   - Стектрейс (обязательно)
   - Заголовок краша
   - Количество событий, % пользователей, версия
```

**Общие правила:**
- Пробуй уровни последовательно: MCP → CLI API → Manual
- НЕ останавливайся на ошибке MCP — сразу пробуй CLI API
- Всегда генерируй Console URL если есть project_id и app_id
- Если есть Issue ID — всегда пытайся получить данные автоматически

### ШАГ 1: Получи данные

**Если пользователь предоставил Firebase Issue ID** — сначала попробуй загрузить данные автоматически (Шаг 3). Стектрейс и контекст запрашивай только если автозагрузка не удалась.

**Если Issue ID нет** — попроси предоставить:
- **Стектрейс** (обязательно)
- **Контекст**: количество крашей, % пользователей, устройство, версия app

### ШАГ 2: Вызови crash-classifier-android

```yaml
Task(
  subagent_type="crash-classifier-android",
  model="haiku",
  prompt="Классифицируй этот Android краш:

    Стектрейс:
    {stack_trace}

    Контекст:
    - Событий: {event_count}
    - Пользователей: {user_count}%
    - Версия: {app_version}
    - Устройство: {device}
  "
)
```

**Ожидаемый вывод:**
```yaml
priority: critical/high/medium/low
exception_type: NullPointerException
component: UI/Network/Database/Services/Background
trigger: user_action/background_task/lifecycle_event/async_operation
```

### ШАГ 3: Получи данные из Firebase (опционально)

Если предоставлен **Firebase Issue ID**, данные загружаются по приоритету:

**Вариант A: MCP работает (Шаг 0, Уровень 1 успешен)**

```yaml
Task(
  subagent_type="firebase-fetcher",
  model="haiku",
  prompt="Получи детали краша из Firebase:

    Issue ID: {issue_id}
    App ID: {app_id}
  "
)
```

**Вариант B: CLI API (Шаг 0, Уровень 2 — MCP не работает)**

Если на Шаге 0 ты уже получил project_id и app_id через CLI — запроси данные напрямую:

```bash
# Получи access token (если ещё не получен на Шаге 0)
ACCESS_TOKEN=$(python3 -c "
import json, urllib.request, urllib.parse, os
config = json.load(open(os.path.expanduser('~/.config/configstore/firebase-tools.json')))
data = urllib.parse.urlencode({
  'client_id': '563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com',
  'client_secret': 'j9iVZfS8kkCEFUPaAeJV0sAi',
  'refresh_token': config['tokens']['refresh_token'],
  'grant_type': 'refresh_token'
}).encode()
req = urllib.request.Request('https://oauth2.googleapis.com/token', data=data)
print(json.loads(urllib.request.urlopen(req).read())['access_token'])")

# Получи issue
curl -s -H "Authorization: Bearer $ACCESS_TOKEN" \
  "https://firebasecrashlytics.googleapis.com/v1beta1/projects/{PROJECT_ID}/apps/{APP_ID}/issues/{ISSUE_ID}"

# Получи events
curl -s -H "Authorization: Bearer $ACCESS_TOKEN" \
  "https://firebasecrashlytics.googleapis.com/v1beta1/projects/{PROJECT_ID}/apps/{APP_ID}/issues/{ISSUE_ID}/events?pageSize=3"
```

Парси JSON и извлеки: title, type, status, stack_traces, device_info, event_count.
**НЕ вызывай firebase-fetcher агента** — данные уже получены.

**Вариант C: Manual fallback**

Если ни MCP, ни CLI API не сработали — сгенерируй Console URL и попроси ручной ввод:
```
https://console.firebase.google.com/project/{PROJECT_ID}/crashlytics/app/android:{APP_ID}/issues/{ISSUE_ID}
```

### ШАГ 4: Вызови crash-forensics-android

```yaml
Task(
  subagent_type="crash-forensics-android",
  model="sonnet",
  prompt="Проанализируй Android краш с git blame:

    Классификация: {classifier_output}
    Данные Firebase: {firebase_output}
    Стектрейс: {stack_trace}
  "
)
```

Агент выполнит:
1. Поиск файлов в codebase
2. Git blame анализ
3. Определение assignee
4. Предложение фикса

### ШАГ 5: Вывод результатов

Агент crash-forensics вернёт два формата:

**Формат 1: Детальный анализ**
- Базовая информация
- Анализ стектрейса
- Проверенные файлы с git blame
- Корневая причина
- Решение (before/after)
- Assignee с обоснованием
- Контекст и предотвращение

**Формат 2: JIRA Brief**
- Название и проблема
- Ключевые строки стектрейса
- Корневая причина (1-2 предложения)
- Фикс кода (ready to copy-paste)
- Приоритет, файл, assignee
- Воспроизведение

## fallback режим (если агенты недоступны)

Если Task tool не может вызвать агентов, выполни анализ напрямую:

1. **Классификация**: Определи тип, приоритет, компонент, триггер
2. **Поиск файлов**: Glob/Grep по классам из стектрейса
3. **Git blame**: `git blame -L X,Y file.kt`
4. **Assignee**: Выбери 2-3 кандидата с обоснованием
5. **Фикс**: Предложи code-level решение
6. **Вывод**: Детальный анализ + JIRA Brief

## Критерии приоритета

| Priority | Когда | Примеры |
|----------|-------|---------|
| 🔴 Critical | Платежи/Авторизация/Безопасность, >5% пользователей | NPE в PaymentProcessor, KeystoreException |
| 🟠 High | Важные функции 1-5% пользователей, новые краши | NPE в основном экране, NetworkException |
| 🟡 Medium | Редкие <1% пользователей, некритичный функционал | Edge case NPE, IndexOutOfBounds |
| 🟢 Low | Single occurrence, non-blocking | Логирующие ошибки |

## Чеклист перед отправкой

### ✅ ОБЯЗАТЕЛЬНО ПРОВЕРЬ:
- [ ] Классификация выполнена (priority, component, trigger)
- [ ] Файлы найдены через Glob/Grep или причина объяснена
- [ ] git blame выполнен с реальными командами
- [ ] Assignee определен с источником (git blame строка X)
- [ ] Два формата отчета (Детальный + JIRA)

### 🚫 НЕ ОТПРАВЛЯЙ ЕСЛИ:
- Поиск кода не выполнен
- Нет git blame для найденных файлов
- Assignee = "TBD" без анализа
- Только один формат отчета

## Пример использования

```
Пользователь: /crash-report

Claude: 🔍 Android Crash Analysis - Multi-Agent

Пожалуйста, предоставьте:
1. Стектрейс (обязательно)
2. Firebase Issue ID (если есть)
3. Количество крашей и % пользователей
4. Устройство и версия приложения

---

[Пользователь предоставляет данные]

Claude:
📊 Шаг 1: Классификация...
[Вызывает crash-classifier]

📡 Шаг 2: Загрузка из Firebase...
[Вызывает firebase-fetcher]

🔬 Шаг 3: Git blame анализ...
[Вызывает crash-forensics]

✅ Анализ завершён

### Детальный анализ
[...(detalled analysis)]

### JIRA Brief
[...(JIRA format)]
```

## Важно

```yaml
Git blame + поиск кода = ОБЯЗАТЕЛЬНО
"TBD" = "я проанализировал и ownership неясен", НЕ "я не проверил"
Задокументируй точные выполненные команды
Каждый отчёт должен иметь git blame с выводом
```
