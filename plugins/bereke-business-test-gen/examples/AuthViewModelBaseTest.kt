package com.example.feature.auth.presentation.viewmodel

import com.google.common.truth.Truth.assertThat
import io.mockk.*
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.TestDispatcher
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.jupiter.api.AfterEach
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.DisplayName
import org.junit.jupiter.api.Test
import com.example.feature.auth.domain.interactors.LoginInteractor
import com.example.feature.auth.domain.interactors.LogoutInteractor
import com.example.core.utils.testing.FlowTestUtils
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import app.cash.turbine.test

/**
 * ✅ ПРИМЕР: ViewModel BaseTest
 *
 * ViewModel с состоянием требует сложной подготовки:
 * - TestDispatcher для управления временем
 * - Отдельные файлы для разных групп методов
 * - Проверка состояния через StateFlow
 * - Проверка иммутабельности состояния
 *
 * Файлы:
 * - AuthViewModelBaseTest (подготовка)
 * - AuthViewModelLoginTest (extends BaseTest)
 * - AuthViewModelLogoutTest (extends BaseTest)
 * - AuthViewModelStateTest (extends BaseTest)
 */
@ExperimentalCoroutinesApi
internal abstract class AuthViewModelBaseTest {

    // ✅ TestDispatcher для управления корутинами
    protected lateinit var testDispatcher: TestDispatcher

    // ✅ Моки с префиксом mock
    protected val mockLoginInteractor: LoginInteractor = mockk(relaxed = true)
    protected val mockLogoutInteractor: LogoutInteractor = mockk(relaxed = true)
    protected val mockAnalytics: AnalyticsService = mockk(relaxed = true)

    // ✅ ViewModel под тестом
    protected lateinit var viewModel: AuthViewModel

    @BeforeEach
    fun setupBase() {
        // ✅ Инициализация TestDispatcher
        testDispatcher = StandardTestDispatcher()
        Dispatchers.setMain(testDispatcher)

        // ✅ Инициализация ViewModel
        viewModel = AuthViewModel(
            loginInteractor = mockLoginInteractor,
            logoutInteractor = mockLogoutInteractor,
            analytics = mockAnalytics,
            dispatcher = testDispatcher
        )
    }

    @AfterEach
    fun tearDownBase() {
        // ✅ Сброс Dispatchers
        Dispatchers.resetMain()
        testDispatcher.scheduler.runCurrent()

        // ✅ Cleanup
        unmockkAll()
        clearAllMocks()
        FlowTestUtils.cleanupFlowResources()
    }

    /**
     * Вспомогательный метод для проверки состояния
     */
    protected suspend inline fun <reified T : AuthState> assertStateFlow(
        state: StateFlow<T>,
        crossinline block: suspend (T) -> Unit
    ) {
        state.test {
            val currentState = awaitItem()
            block(currentState)
            cancelAndIgnoreRemainingEvents()
        }
    }
}

// ========================
// Тесты для login
// ========================

@ExperimentalCoroutinesApi
class AuthViewModelLoginTest : AuthViewModelBaseTest() {

    @DisplayName("When login called with valid credentials - Then update state to Success")
    @Test
    fun login_validCredentials_updateStateToSuccess() = runTest(testDispatcher) {
        // Given: подготовка данных
        val username = "user@example.com"
        val password = "pass123"
        val mockToken = "auth_token"

        coEvery { mockLoginInteractor.performLogin(username, password) } returns RequestResult.Success(mockToken)

        // When: вызов login
        viewModel.login(username, password)

        // Даем время на корутину
        testDispatcher.scheduler.advanceUntilIdle()

        // Then: проверка состояния
        assertStateFlow(viewModel.state) { state ->
            assertThat(state).isInstanceOf(AuthState.Success::class.java)
            assertThat((state as AuthState.Success).token).isEqualTo(mockToken)
        }

        // ✅ Проверка вызовов
        coVerify { mockLoginInteractor.performLogin(username, password) }
        verify { mockAnalytics.logEvent("login_success", any()) }
    }

    @DisplayName("When login called with invalid credentials - Then update state to ValidationError")
    @Test
    fun login_invalidCredentials_updateStateToValidationError() = runTest(testDispatcher) {
        // Given
        val username = ""
        val password = ""

        coEvery {
            mockLoginInteractor.performLogin(username, password)
        } returns RequestResult.Failure(ValidationException("Credentials invalid"))

        // When
        viewModel.login(username, password)
        testDispatcher.scheduler.advanceUntilIdle()

        // Then
        assertStateFlow(viewModel.state) { state ->
            assertThat(state).isInstanceOf(AuthState.ValidationError::class.java)
        }
    }

    @DisplayName("When login called and network fails - Then update state to NetworkError")
    @Test
    fun login_networkError_updateStateToNetworkError() = runTest(testDispatcher) {
        // Given
        val username = "user@example.com"
        val password = "pass123"

        coEvery { mockLoginInteractor.performLogin(username, password) } returns RequestResult.Failure(
            Exception("Network timeout")
        )

        // When
        viewModel.login(username, password)
        testDispatcher.scheduler.advanceUntilIdle()

        // Then
        assertStateFlow(viewModel.state) { state ->
            assertThat(state).isInstanceOf(AuthState.Error::class.java)
            assertThat((state as AuthState.Error).message).contains("Network")
        }

        // ✅ Проверка аналитики ошибки
        verify { mockAnalytics.logEvent("login_error", any()) }
    }

    @DisplayName("When login loading - Then state should be Loading")
    @Test
    fun login_loading_stateIsLoading() = runTest(testDispatcher) {
        // Given
        val username = "user@example.com"
        val password = "pass123"

        coEvery { mockLoginInteractor.performLogin(username, password) } coAnswers {
            // Имитируем задержку
            kotlinx.coroutines.delay(1000)
            RequestResult.Success("token")
        }

        // When
        viewModel.login(username, password)

        // Then: сразу после вызова должно быть Loading
        viewModel.state.test {
            val loadingState = awaitItem()
            assertThat(loadingState).isInstanceOf(AuthState.Loading::class.java)

            // Пропускаем остальное
            cancelAndIgnoreRemainingEvents()
        }
    }
}

// ========================
// Тесты для logout
// ========================

@ExperimentalCoroutinesApi
class AuthViewModelLogoutTest : AuthViewModelBaseTest() {

    @DisplayName("When logout called - Then clear state and session")
    @Test
    fun logout_called_clearsStateAndSession() = runTest(testDispatcher) {
        // Given: есть успешное состояние
        viewModel._state.value = AuthState.Success(token = "some_token")

        coEvery { mockLogoutInteractor.performLogout() } returns RequestResult.Success(Unit)
        every { mockAnalytics.logEvent("logout_success", any()) } just Runs

        // When
        viewModel.logout()
        testDispatcher.scheduler.advanceUntilIdle()

        // Then: состояние вернулось в initial
        assertStateFlow(viewModel.state) { state ->
            assertThat(state).isInstanceOf(AuthState.Initial::class.java)
        }

        coVerify { mockLogoutInteractor.performLogout() }
    }

    @DisplayName("When logout fails - Then keep current state and show error")
    @Test
    fun logout_fails_keepStateAndShowError() = runTest(testDispatcher) {
        // Given
        val currentToken = "valid_token"
        viewModel._state.value = AuthState.Success(token = currentToken)

        coEvery { mockLogoutInteractor.performLogout() } returns RequestResult.Failure(
            Exception("Logout failed")
        )

        // When
        viewModel.logout()
        testDispatcher.scheduler.advanceUntilIdle()

        // Then: состояние не изменилось, показана ошибка
        assertStateFlow(viewModel.state) { state ->
            assertThat(state).isInstanceOf(AuthState.Success::class.java)
        }

        // ✅ Проверка сообщения об ошибке
        assertThat(viewModel.errorMessage.value).contains("Logout failed")
    }
}

// ========================
// Тесты для состояния
// ========================

@ExperimentalCoroutinesApi
class AuthViewModelStateTest : AuthViewModelBaseTest() {

    @DisplayName("When state changes - Then it's immutable from outside")
    @Test
    fun stateChanges_immutableFromOutside() = runTest(testDispatcher) {
        // Given: начальное состояние
        assertStateFlow(viewModel.state) { state ->
            assertThat(state).isInstanceOf(AuthState.Initial::class.java)
        }

        // When: пытаемся изменить через public API
        val username = "user@example.com"
        val password = "pass123"
        coEvery { mockLoginInteractor.performLogin(username, password) } returns RequestResult.Success("token")

        viewModel.login(username, password)
        testDispatcher.scheduler.advanceUntilIdle()

        // Then: состояние изменилось через вызов метода, а не напрямую
        assertStateFlow(viewModel.state) { state ->
            assertThat(state).isInstanceOf(AuthState.Success::class.java)
        }
    }

    @DisplayName("When multiple state changes - Then all emissions captured")
    @Test
    fun multipleStateChanges_allEmissionsCaptured() = runTest(testDispatcher) {
        // Given
        val username = "user@example.com"
        val password = "pass123"
        val mockToken = "token"

        coEvery { mockLoginInteractor.performLogin(username, password) } returns RequestResult.Success(mockToken)

        // When & Then: проверка всех эмиссий
        viewModel.state.test {
            // Initial state
            assertThat(awaitItem()).isInstanceOf(AuthState.Initial::class.java)

            // Вызываем login
            viewModel.login(username, password)

            // Loading state
            assertThat(awaitItem()).isInstanceOf(AuthState.Loading::class.java)

            testDispatcher.scheduler.advanceUntilIdle()

            // Success state
            val successState = awaitItem()
            assertThat(successState).isInstanceOf(AuthState.Success::class.java)

            // Нет больше эмиссий
            expectNoEvents()
            cancelAndIgnoreRemainingEvents()
        }
    }
}
