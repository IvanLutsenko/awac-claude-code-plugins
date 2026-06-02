# plugin-cross-port: Marketplace как производное от манифеста

**Дата:** 2026-06-02
**Статус:** Design (согласовано в brainstorming, ожидает review)
**Плагин:** `plugins/plugin-cross-port`

---

## 1. Контекст и проблема

`plugin-cross-port` конвертирует плагины между форматами Claude Code (CC) и Codex —
one-shot или continuous (pre-commit hook). На каждый плагин в игре **четыре JSON-файла
в двух слоях**:

**Слой 1 — манифест плагина (per-plugin):**
- `.claude-plugin/plugin.json` (CC) — исходник: тут живут `commands`, `hooks`, `mcpServers`.
- `.codex-plugin/plugin.json` (Codex) — производное ядро (`name/version/description/author`) + надстройка `interface`.

**Слой 2 — манифест marketplace (реестр, в корне репо):**
- `.claude-plugin/marketplace.json` (CC) — запись вшивает `version`, `description`, `author`, `category`, `source` (строка).
- `.agents/plugins/marketplace.json` (Codex) — запись содержит `name`, `source` (объект `{source, path}`), `policy`, `category`; **версию не вшивает** (тянется через `path`).

**Дрейф метаданных.** Для одного плагина `version` дублируется в трёх-четырёх местах.
Сейчас автоматически синхронизируется лишь `CC plugin.json → Codex plugin.json`
(`build_codex_manifest`). Остальное держится руками или никак:

| Файл | Кто синкает version/description сейчас |
|---|---|
| `.claude-plugin/plugin.json` | исходник (руками) |
| `.codex-plugin/plugin.json` | авто из CC-манифеста ✅ |
| `.claude-plugin/marketplace.json` | **руками** (release-чеклист, пункт 2) |
| `.agents/plugins/marketplace.json` | версию не несёт; запись апсертится без метаданных |

Дополнительные пробелы:
- `convert_cc_to_codex.py` трогает лишь Codex-marketplace; **CC-marketplace не трогает**.
- `convert_codex_to_cc.py` **не имеет marketplace-функции вообще** — обратное направление не регистрирует плагин нигде.

---

## 2. Согласованные решения (brainstorming)

1. **Marketplace — полностью производное.** Источник правды = манифест плагина
   (`.claude-plugin/plugin.json` для CC-sourced; `.codex-plugin/plugin.json` для codex-sourced).
   Конвертер сам синкает marketplace-записи; ручное редактирование метаданных в marketplace не предусмотрено.

2. **Sync независим от направления.** Sync marketplace — отдельный шаг, управляемый source-of-truth манифестом.
   Любой запуск (CC→Codex, Codex→CC, или отдельная команда) приводит **обе** marketplace-записи
   в соответствие манифесту. Release-чеклист пункт 2 (ручной bump CC-marketplace) **исчезает**.

3. **Корневые поля marketplace неприкосновенны.** Конвертер никогда не трогает
   `owner`, `name`/`description`/`version` *самого каталога*, `interface.displayName` каталога —
   только элемент внутри `plugins[]`.

4. **«Свой/чужой плагин» как отдельный режим — выброшено.** Нет флага `--no-marketplace`
   и нет автодетекта «чужой». Вместо этого единое правило гейтинга (см. §4).

5. **Перемещение между репо — не дело конвертера.** Cross-repo move = ручное/агентное действие
   (`vendor`), т.к. требует суждений (git-история, license, коллизии имён). Конвертер работает
   только in-repo. После перемещения конвертер отрабатывает чисто благодаря пересчёту путей (см. §5).

---

## 3. Модель источника правды и владения полями

Манифест плагина — единственный источник правды для **метаданных, которыми он владеет**.
Остальные файлы — производные. Но не все поля marketplace «принадлежат» манифесту: `category`
и `policy` в marketplace не имеют источника в `plugin.json`.

**Таблица владения полями marketplace-записи:**

| Поле marketplace-записи | Источник | Поведение при re-sync |
|---|---|---|
| `name` | манифест `name` | перезаписывается |
| `version` (только CC-marketplace) | манифест `version` | перезаписывается |
| `description` (только CC-marketplace) | манифест `description` | перезаписывается |
| `author` (только CC-marketplace) | манифест `author` | перезаписывается |
| `source` / `path` | **текущее расположение плагина** в repo-root | **пересчитывается** (не наследуется из старого файла) |
| `category` | не принадлежит манифесту | **preserve** существующее; для новой записи — дефолт (см. ниже) |
| `policy` (Codex) | не принадлежит манифесту | **preserve** существующее; для новой — дефолт `{installation: AVAILABLE, authentication: ON_INSTALL}` |

**Дефолт `category` для новой записи:** lower-case от `interface.category` Codex-манифеста
(сейчас всегда `Development` → `development`); фолбэк `development`, если нет.

**Принцип:** «fully derived» применяется к полям, которыми манифест **владеет**
(`name/version/description/author/source`). Поля, которых нет в манифесте (`category`, `policy`),
сохраняются из существующей записи, а для новой — заполняются разумным дефолтом. Это не нарушает
решение №1, т.к. ручное редактирование касается только не-derived полей.

---

## 4. Поведение sync marketplace

### Правило гейтинга (замена выброшенного «foreign mode»)

Различие «управляемый каталог vs standalone/выкидыш» сводится к **наличию
любого marketplace-манифеста в repo-root**:

> **Если в repo-root существует хотя бы один marketplace-файл** (`.claude-plugin/marketplace.json`
> **или** `.agents/plugins/marketplace.json`) → это управляемый каталог:
> конвертер синкает **обе** записи, создавая отсутствующий sibling-файл при необходимости.
>
> **Если нет ни одного** → standalone/чужая папка/выкидыш:
> конвертер **молча не трогает marketplace вообще** (и не создаёт новых файлов).

Это точно воспроизводит выброшенный «foreign mode» без флагов: граница «in-repo vs вне репо»
= «есть ли в repo-root marketplace-манифест». Вендоринг чужого плагина в управляемый репо
делает его in-repo автоматически.

> **Изменение поведения:** сейчас `update_codex_marketplace` создаёт Codex-marketplace,
> даже если его не было (`data = {'plugins': []}`). Теперь создание разрешено
> **только когда repo-root уже управляемый** (есть ≥1 marketplace-файл). Иначе — skip.

### Что синкается, независимо от направления конвертации

Оба скрипта (`cc_to_codex`, `codex_to_cc`) после основной трансформации вызывают
**общую логику sync обоих marketplace** от source-of-truth манифеста:

1. **CC-marketplace** (`.claude-plugin/marketplace.json`): upsert записи с полными
   метаданными (`name/version/description/author/source/category`). **Новое** для обоих скриптов.
2. **Codex-marketplace** (`.agents/plugins/marketplace.json`): upsert записи
   (`name/source/policy/category`), без version (path-based). Существует для `cc_to_codex`,
   **новое** для `codex_to_cc`.

Оба upsert-а — идемпотентны (обновить существующую запись по `name` или добавить новую),
с пересчётом `source`/`path` и сохранением не-derived полей (§3).

---

## 5. Перемещение между репо (vendor) и работа in-repo

**Разделение труда:**

- **LLM (скилл `cc-to-codex`, интерактивно) — фаза «vendor».** Отдельная явная фаза *перед*
  вызовом детерминированного скрипта: скопировать папку в `plugins_dir`, разрулить коллизию имён,
  разобраться с license/attribution, отбросить стейл-артефакты (чужой `.plugin-cross-port.yaml`,
  старую генерацию).
- **Детерминированный скрипт — формат + оба marketplace.** Остаётся move-agnostic:
  работает только в одном repo-root, никогда не ходит в два репо.

**Гарантия пересчёта путей:**

> Конвертер вычисляет `source`/`path` в marketplace **из текущего расположения плагина
> в целевом repo-root** и **никогда не доверяет пути, вшитому в скопированный marketplace
> или `.plugin-cross-port.yaml`**.

Благодаря этому «move + convert» — это композиция существующих шагов:
```
1. LLM:    cp -r чужой_плагин → plugins/X  (+ разрулить коллизии/license)   [суждение]
2. Скрипт: convert_cc_to_codex.py plugins/X --repo-root .                   [механика]
           → .codex-plugin/plugin.json + skills/generated-*
           → upsert в CC-marketplace    (появляется в твоём CC-каталоге)
           → upsert в Codex-marketplace (и в Codex-каталоге)
3. Готово: плагин в репо, dual-target, в обоих marketplace.
```

`.plugin-cross-port.yaml`, приехавший с чужим плагином, **пересчитывается**, а не наследуется
(в частности `source_of_truth` и любые пути).

---

## 6. Вне скоупа (YAGNI)

- **Cross-repo move в скрипте** — нет. Только ручной/агентный `vendor` + in-repo convert.
- **Режим «сконвертить и сознательно не регистрировать»** — нет. Гейтинг §4 покрывает это наличием marketplace-файла.
- **Флаги `--no-marketplace` / `--register`** — нет. Поведение определяется гейтингом.
- **Корневые поля marketplace** (`owner`, метаданные самого каталога, `interface.displayName` каталога) — конвертер не трогает.
- **Version в Codex-marketplace-записи** — не добавляем; Codex-каталог path-based.
- **Тонкая обёртка-команда `vendor`** — нет; перемещение остаётся работой LLM/пользователя.

---

## 7. Влияние на release-чеклист репо

Пункт 2 корневого `CLAUDE.md` («marketplace.json — обнови версию и описание») для dual-target
плагинов становится **автоматическим**: конвертер синкает CC-marketplace из `plugin.json` при каждом запуске
(вручную или через pre-commit hook). Чеклист следует обновить: для плагинов под `plugin-cross-port`
ручной bump CC-marketplace больше не нужен.

---

## 8. Поверхность реализации

**`scripts/convert_cc_to_codex.py`:**
- Вынести общую логику marketplace в функции с пересчётом пути и сохранением не-derived полей.
- Добавить `update_cc_marketplace(...)` — upsert полной CC-записи из манифеста.
- Огейтить оба marketplace-апсерта правилом §4 (≥1 marketplace-файл в repo-root; иначе skip).
- `update_codex_marketplace`: разрешить создание файла только в управляемом репо.

**`scripts/convert_codex_to_cc.py`:**
- Добавить marketplace-логику (сейчас отсутствует): upsert и CC-, и Codex-записей от Codex-манифеста как source of truth.
- То же правило гейтинга §4 и пересчёт путей.

**Общее:** вынести marketplace-логику в общий модуль/хелпер, чтобы оба направления
использовали один код (DRY) и одинаково гейтились.

**`skills/cc-to-codex/SKILL.md`:** добавить явную фазу «vendor» (перемещение/копирование + разрулить
коллизии/license) перед вызовом скрипта; подчеркнуть, что скрипт move-agnostic.

**Документация:** обновить `references/mapping.md` (marketplace-секция), `references/continuous-mode.md`
(both-marketplaces sync), `references/decision-file.md` (пересчёт путей), `README.md`, корневой `CLAUDE.md` (release-чеклист).

**Тесты (`tests/test_converters.py`):** sync CC-marketplace в обоих направлениях; гейтинг (нет marketplace → skip,
не создаёт файлов); пересчёт `path` после «перемещения»; preserve `category`/`policy` при re-sync;
дефолт category для новой записи; идемпотентность.

---

## 9. Риски / открытые вопросы

- **Схема Codex-marketplace.** Предполагаем, что она path-based и не имеет поля version. Проверить
  на актуальной документации Codex перед реализацией; если version там ожидается — добавить в §3.
- **Источник `category`.** Не принадлежит манифесту; стратегия preserve-or-default (§3). Если в будущем
  захотим управляемую category — добавить поле в `plugin.json` или в `.plugin-cross-port.yaml`.
- **Codex-sourced репо без CC-marketplace.** Гейтинг §4 сработает (есть Codex-marketplace → управляемый),
  создаст CC-marketplace sibling. Убедиться, что корневые поля CC-каталога при создании
  заполняются разумным дефолтом, не мусором.
