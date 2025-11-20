package com.example.feature.auth.domain.interactors

import com.google.common.truth.Truth.assertThat
import io.mockk.*
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.runTest
import org.junit.jupiter.api.AfterEach
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.DisplayName
import org.junit.jupiter.api.Test
import com.example.feature.auth.domain.usecases.LoginUseCase
import com.example.feature.auth.domain.usecases.ValidateCredentialsUseCase
import com.example.core.utils.testing.FlowTestUtils

/**
 * ✅ ПРИМЕР: Interactor тест
 *
 * Interactor координирует несколько UseCase.
 * Здесь показано:
 * - Координация нескольких UseCase
 * - Обработка результатов от разных слоёв
 * - Логирование и аналитика
 * - Повторные попытки и таймауты
 */
@ExperimentalCoroutinesApi
class LoginInteractorImplTest {

    // ✅ Все зависимости с префиксом mock
    private val mockLoginUseCase: LoginUseCase = mockk(relaxed = true)
    private val mockValidateUseCase: ValidateCredentialsUseCase = mockk(relaxed = true)
    private val mockAnalytics: AnalyticsService = mockk(relaxed = true)
    private val mockSecurityService: SecurityService = mockk(relaxed = true)

    private lateinit var interactor: LoginInteractorImpl

    @BeforeEach
    fun setUp() {
        interactor = LoginInteractorImpl(
            mockLoginUseCase,
            mockValidateUseCase,
            mockAnalytics,
            mockSecurityService
        )
    }

    @AfterEach
    fun tearDown() {
        unmockkAll()
        clearAllMocks()
        FlowTestUtils.cleanupFlowResources()
    }

    // ========================
    // performLogin() - Happy Path
    // ========================

    @DisplayName("When performLogin called with valid credentials - Then return Success and log event")
    @Test
    fun performLogin_validCredentials_returnsSuccessAndLogsEvent() = runTest {
        // Given: валидные учетные данные
        val username = "user@example.com"
        val password = "securePass123"
        val mockToken = "auth_token_xyz"

        coEvery { mockValidateUseCase.validate(username, password) } returns RequestResult.Success(Unit)
        coEvery { mockLoginUseCase.execute(username, password) } returns RequestResult.Success(mockToken)
        every { mockSecurityService.storeToken(mockToken) } just Runs

        // When: выполнение логина
        val result = interactor.performLogin(username, password)

        // Then: проверка результата
        assertThat(result).isInstanceOf(RequestResult.Success::class.java)
        val successResult = result as RequestResult.Success
        assertThat(successResult.data).isEqualTo(mockToken)

        // ✅ Проверка последовательности вызовов
        coVerifySequence {
            mockValidateUseCase.validate(username, password)
            mockLoginUseCase.execute(username, password)
            mockSecurityService.storeToken(mockToken)
        }

        // ✅ Проверка логирования
        verify { mockAnalytics.logEvent("login_success", any()) }
    }

    // ========================
    // performLogin() - Validation Error
    // ========================

    @DisplayName("When performLogin called with invalid credentials - Then return Failure without calling login")
    @Test
    fun performLogin_invalidCredentials_returnsFailureWithoutLogin() = runTest {
        // Given: невалидные учетные данные
        val username = "invalid"
        val password = ""
        val validationError = ValidationException("Password is empty")

        coEvery {
            mockValidateUseCase.validate(username, password)
        } throws validationError

        // When
        val result = interactor.performLogin(username, password)

        // Then: login UseCase не должен был вызван
        assertThat(result).isInstanceOf(RequestResult.Failure::class.java)

        // ✅ Проверка, что login не был вызван
        coVerify(exactly = 0) { mockLoginUseCase.execute(any(), any()) }

        // ✅ Аналитика об ошибке
        verify { mockAnalytics.logEvent("login_validation_failed", any()) }
    }

    // ========================
    // performLogin() - Network Error
    // ========================

    @DisplayName("When performLogin called and API fails - Then return Failure and log analytics")
    @Test
    fun performLogin_apiError_returnsFailureAndLogsError() = runTest {
        // Given: API ошибка
        val username = "user@example.com"
        val password = "pass123"
        val networkError = Exception("Network timeout")

        coEvery { mockValidateUseCase.validate(username, password) } returns RequestResult.Success(Unit)
        coEvery { mockLoginUseCase.execute(username, password) } throws networkError

        // When
        val result = interactor.performLogin(username, password)

        // Then
        assertThat(result).isInstanceOf(RequestResult.Failure::class.java)

        // ✅ Проверка, что токен не был сохранен
        verify(exactly = 0) { mockSecurityService.storeToken(any()) }

        // ✅ Аналитика об ошибке
        verify { mockAnalytics.logEvent("login_error", match { event ->
            event.containsKey("error_type") && event["error_type"] == "network"
        }) }
    }

    // ========================
    // getLoginAttempts() - с запросом к сервису
    // ========================

    @DisplayName("When getLoginAttempts called - Then return current attempt count")
    @Test
    fun getLoginAttempts_called_returnsAttemptCount() = runTest {
        // Given
        coEvery { mockSecurityService.getLoginAttempts() } returns 2

        // When
        val result = interactor.getLoginAttempts()

        // Then
        assertThat(result).isEqualTo(2)
        coVerify { mockSecurityService.getLoginAttempts() }
    }

    // ========================
    // resetLoginAttempts() - State change
    // ========================

    @DisplayName("When resetLoginAttempts called - Then clear all login attempts")
    @Test
    fun resetLoginAttempts_called_clearsAttempts() = runTest {
        // Given
        every { mockSecurityService.resetLoginAttempts() } just Runs

        // When
        interactor.resetLoginAttempts()

        // Then
        verify { mockSecurityService.resetLoginAttempts() }
        verify { mockAnalytics.logEvent("login_attempts_reset", any()) }
    }

    // ========================
    // performLogout() - Cleanup
    // ========================

    @DisplayName("When performLogout called - Then clear session and logout from all services")
    @Test
    fun performLogout_called_clearsSessionFromAllServices() = runTest {
        // Given: есть активная сессия
        every { mockSecurityService.clearToken() } just Runs
        every { mockSecurityService.clearSession() } just Runs

        // When
        interactor.performLogout()

        // Then: все сервисы очищены
        verify(exactly = 1) { mockSecurityService.clearToken() }
        verify(exactly = 1) { mockSecurityService.clearSession() }
        verify { mockAnalytics.logEvent("logout_success", any()) }
    }

    // ========================
    // retry Logic
    // ========================

    @DisplayName("When performLogin fails temporarily - Then retry and succeed on second attempt")
    @Test
    fun performLogin_temporaryFailure_retriesAndSucceeds() = runTest {
        // Given: первый вызов падает, второй успешен
        val username = "user@example.com"
        val password = "pass123"
        val mockToken = "token_after_retry"

        coEvery { mockValidateUseCase.validate(username, password) } returns RequestResult.Success(Unit)
        coEvery { mockLoginUseCase.execute(username, password) }
            .throwsMany(Exception("Temporary error"))
            .andThen(RequestResult.Success(mockToken))

        every { mockSecurityService.storeToken(mockToken) } just Runs

        // When: с retryPolicy
        val result = interactor.performLoginWithRetry(username, password)

        // Then
        assertThat(result).isInstanceOf(RequestResult.Success::class.java)

        // ✅ Проверка, что было 2 попытки
        coVerify(exactly = 2) { mockLoginUseCase.execute(username, password) }
    }
}
