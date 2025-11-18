---
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, TodoWrite
description: Покрытие unit тестами бизнес-логики модуля (ViewModel, UseCase, Interactor, Repository)
---

## Задача

Создать unit тесты для всех классов бизнес-логики в указанном модуле:
- **ViewModel** - UI логика и состояние
- **UseCase** - бизнес-логика
- **Interactor** - координация UseCase
- **Repository** - работа с данными

## Workflow

### Шаг 1: Загрузи стандарты

```
!cat ~/.claude/plugins/marketplaces/claude-code-plugins/plugins/test-standards/standards/android-kotlin.md
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
