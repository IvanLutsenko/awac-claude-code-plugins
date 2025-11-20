---
description: Покрытие unit тестами бизнес-логики модуля (ViewModel, UseCase, Interactor, Repository)
argument-hint: "path/to/module"
allowed-tools: ["Read", "Write", "Edit", "Glob", "Grep", "Bash", "TodoWrite"]
---

## Задача

Создать unit тесты для всех классов бизнес-логики в указанном модуле:
- **ViewModel** - UI логика и состояние
- **UseCase** - бизнес-логика
- **Interactor** - координация UseCase
- **Repository** - работа с данными

## Workflow

### Шаг 1: Загрузи стандарты

**Быстрая шпаргалка** (начни с этого - 50 строк):
```
!cat ~/.claude/plugins/marketplaces/awac-claude-code-plugins/plugins/test-standards/standards/android-kotlin-quick-ref.md
```

**Полное руководство** (если нужны детали - 600+ строк):
```
!cat ~/.claude/plugins/marketplaces/awac-claude-code-plugins/plugins/test-standards/standards/android-kotlin.md
```

### Шаг 2: Сканирование модуля

Найди все классы бизнес-логики в модуле:

```bash
# ViewModel
find {module_path} -type f -name "*ViewModel.kt" -not -path "*/test/*"

# UseCase
find {module_path} -type f -name "*UseCase.kt" -not -path "*/test/*"

# Interactor
find {module_path} -type f -name "*Interactor*.kt" -not -path "*/test/*"

# Repository
find {module_path} -type f -name "*Repository*.kt" -not -path "*/test/*"
```

Создай список всех найденных классов.

### Шаг 3: Анализ покрытия

Для каждого найденного класса проверь существование теста:

```bash
# Для класса feature/auth/LoginViewModel.kt ищи
find {module_path}/src/test -name "LoginViewModelTest.kt"
find {module_path}/src/test -name "LoginViewModelBaseTest.kt"
```

Раздели на две группы:
- **✅ Покрыто тестами** - тест существует
- **❌ Без тестов** - тест отсутствует

### Шаг 4: Создание плана

Создай план покрытия в TodoWrite:

```
1. ViewModel: AuthViewModel - нужен BaseTest + 3 файла тестов
2. UseCase: LoginUseCase - нужен тест
3. UseCase: LogoutUseCase - уже покрыт ✅
4. Interactor: AuthInteractor - нужен тест
5. Repository: AuthRepository - уже покрыт ✅
...
```

### Шаг 5: Генерация тестов

Для каждого класса без тестов:

1. **Прочитай класс** - понять структуру и зависимости
2. **Найди примеры** - похожие тесты в проекте:
   ```bash
   find . -name "*{LayerType}*Test.kt" -path "*/test/*" | head -3
   ```
3. **Прочитай примеры** - понять паттерны проекта
4. **Сгенерируй тест** - следуя стандартам
5. **Отметь в TodoWrite** - как выполненное

### Шаг 6: Приоритизация

Генерируй в порядке приоритета:

**Высокий приоритет:**
1. UseCase - чистая бизнес-логика
2. Interactor - координация
3. Repository - работа с данными

**Средний приоритет:**
4. ViewModel - UI логика (сложнее, может требовать BaseTest)

### Шаг 7: Специфика по слоям

**UseCase (простой тест):**
```kotlin
@ExperimentalCoroutinesApi
class LoginUseCaseTest {

    private val mockRepository: AuthRepository = mockk(relaxed = true)
    private lateinit var useCase: LoginUseCase

    @BeforeEach
    fun setUp() {
        useCase = LoginUseCase(mockRepository)
    }

    @AfterEach
    fun tearDown() {
        unmockkAll()
        clearAllMocks()
    }

    @DisplayName("When execute with valid credentials - Then returns Success")
    @Test
    fun executeValidCredentials_returnsSuccess() = runTest {
        // Given
        val username = "user"
        val password = "pass"
        val mockUser = mockk<User>()
        coEvery { mockRepository.login(username, password) } returns RequestResult.Success(mockUser)

        // When
        val result = useCase.execute(username, password)

        // Then
        assertThat(result).isInstanceOf(RequestResult.Success::class.java)
        coVerify { mockRepository.login(username, password) }
    }
}
```

**Repository (с Flow и статическим мокированием):**
```kotlin
@ExperimentalCoroutinesApi
class AuthRepositoryImplTest {

    private val mockApi: AuthApi = mockk(relaxed = true)
    private lateinit var repository: AuthRepositoryImpl

    @BeforeEach
    fun setUp() {
        repository = AuthRepositoryImpl(mockApi)
    }

    @AfterEach
    fun tearDown() {
        unmockkAll()
        clearAllMocks()
        FlowTestUtils.cleanupFlowResources()
    }

    @DisplayName("When login called - Then return Flow with DataState Success")
    @Test
    fun login_returnsFlowWithSuccess() = runTest {
        // Given
        val mockedDto = mockk<AuthDTO>(relaxed = true)
        val mockedModel = mockk<AuthModel>(relaxed = true)

        mockkStatic("com.example.data.mappers.AuthMapperKt") {
            coEvery { mockedDto.toModel() } returns mockedModel
            coEvery { mockApi.login(any()) } returns Response.success(mockedDto)

            // When & Then
            repository.login("user", "pass").test {
                assertThat(awaitItem()).isInstanceOf(DataState.Loading::class.java)
                val success = awaitItem()
                assertThat(success).isInstanceOf(DataState.Success::class.java)
                awaitComplete()
            }

            FlowTestUtils.coVerifyFlowCall { repository.login("user", "pass") }
        }
    }
}
```

**ViewModel (BaseTest для сложных):**

Если ViewModel сложный (>5 методов):
1. Создай `{ViewModelName}BaseTest` с общим setup
2. Создай отдельные файлы по функциональности:
   - `{ViewModelName}HandleIntentTest`
   - `{ViewModelName}LoadDataTest`
   - `{ViewModelName}ValidationTest`

Если простой - один тестовый файл.

### Шаг 8: Валидация после генерации

После создания каждого теста:
1. Проверь соответствие стандартам
2. Убедись что тест компилируется
3. Отметь в TodoWrite

### Шаг 9: Итоговый отчет

```markdown
## ✅ Покрытие бизнес-логики модуля: {MODULE_NAME}

### Статистика

**Всего классов бизнес-логики:** 15
- ViewModel: 3
- UseCase: 6
- Interactor: 2
- Repository: 4

**До покрытия:**
- Покрыто: 6 (40%)
- Без тестов: 9 (60%)

**После покрытия:**
- Покрыто: 15 (100%) ✅

### Созданные тесты

#### ViewModel
1. ✅ `AuthViewModelBaseTest.kt` + 3 файла
2. ✅ `LoginViewModelTest.kt`

#### UseCase
3. ✅ `LoginUseCaseTest.kt`
4. ✅ `LogoutUseCaseTest.kt`
5. ✅ `ValidateCredentialsUseCaseTest.kt`

#### Interactor
6. ✅ `AuthInteractorImplTest.kt`

#### Repository
7. ✅ `AuthRepositoryImplTest.kt`

### Рекомендации

1. Запустить тесты: `./gradlew :{module}:test`
2. Проверить покрытие: `./gradlew :{module}:koverHtmlReport`
3. Добавить edge cases для critical paths
```

## Пример использования

```bash
# Покрыть модуль бизнес-логики
/test-module-core feature/auth

# Покрыть impl модуль
/test-module-core feature/qr-signing/qr-signing-impl
```

## Критические требования

При генерации ВСЕХ тестов соблюдай:
- ✅ @DisplayName (без backticks)
- ✅ Given-When-Then структура
- ✅ Truth assertions
- ✅ Префикс mock для моков
- ✅ FlowTestUtils для Flow
- ✅ Полный tearDown с cleanupFlowResources
- ✅ Happy path + error handling + edge cases
- ✅ **Пакет теста = пакет исходного класса** (только путь меняется)
- ✅ Тестировать только PUBLIC методы (минимум 1 happy path + 1 error case)

## Проверка качества после генерации

После завершения генерации всех тестов:

```bash
# 1. Проверка синтаксиса
./gradlew :{module}:compileDebugUnitTestKotlin

# 2. Проверка линтера и удаление неиспользуемых импортов
./gradlew :{module}:lintDebugUnitTest

# 3. Запуск всех тестов
./gradlew :{module}:testDebugUnitTest

# 4. Проверка покрытия кода
./gradlew :{module}:koverVerify
./gradlew :{module}:koverHtmlReport  # отчет в build/reports/kover/html/
```

**Если лinter нашел unused imports:**
- Удали их автоматически через Edit
- Переблюдай логику того что осталось

**Если тесты не компилируются:**
- Проверь типы параметров
- Убедись что все импорты правильные
- Перепроверь синтаксис Given-When-Then блоков

**Целевое покрытие:** >= 70% (стремись к 100%)

## ✨ BONUS: Достижение 100% покрытия

Для полного покрытия (100%) используй Kover анализ:

```bash
# 1. После генерации тестов - запусти Kover
./gradlew :{module}:koverXmlReport

# 2. Найди методы без покрытия (missed > 0)
grep -E '<method.*missed="[1-9]"' build/reports/kover/report.xml | \
grep -oP 'name="\K[^"]*'

# 3. Для каждого найденного метода - генерируй тест
/generate-test feature/auth/data/repositories/AuthRepository.kt

# 4. Повторяй шаги 1-3 пока все методы не покрыты
./gradlew :{module}:koverVerify  # ✅ Готово!
```

**Полный workflow с примерами:** смотри раздел "BONUS: Автоматическое достижение 100% покрытия" в `/test-standards:test-module-all`
