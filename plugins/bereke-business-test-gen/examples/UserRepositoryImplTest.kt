package com.example.feature.auth.data.repositories

import com.google.common.truth.Truth.assertThat
import io.mockk.*
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.runTest
import org.junit.jupiter.api.AfterEach
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.DisplayName
import org.junit.jupiter.api.Test
import kotlinx.coroutines.flow.flowOf
import app.cash.turbine.test
import com.example.core.utils.testing.FlowTestUtils

/**
 * ✅ ПРИМЕР: Простой Repository тест
 *
 * Следует корпоративным стандартам:
 * - Package совпадает с исходным классом (src/main → src/test)
 * - Все методы public тестируются
 * - Given-When-Then структура
 * - Truth assertions только
 * - FlowTestUtils для Flow методов
 * - Полный tearDown с cleanup
 */
@ExperimentalCoroutinesApi
class UserRepositoryImplTest {

    // ✅ Моки с префиксом mock
    private val mockUserApi: UserApi = mockk(relaxed = true)
    private val mockUserMapper: UserMapper = mockk(relaxed = true)

    // ✅ Класс под тестом
    private lateinit var repository: UserRepositoryImpl

    @BeforeEach
    fun setUp() {
        // ✅ Инициализация в setUp
        repository = UserRepositoryImpl(mockUserApi, mockUserMapper)
    }

    @AfterEach
    fun tearDown() {
        // ✅ Полный cleanup
        unmockkAll()
        clearAllMocks()
        FlowTestUtils.cleanupFlowResources()
    }

    // ========================
    // getUser() - Happy Path
    // ========================

    @DisplayName("When getUser called with valid ID - Then return Success with user data")
    @Test
    fun getUser_validId_returnsSuccessWithUserData() = runTest {
        // Given: подготовка моков
        val userId = "user123"
        val mockUserDto = mockk<UserDto>(relaxed = true)
        val mockUserModel = mockk<UserModel>(relaxed = true)

        coEvery { mockUserApi.fetchUser(userId) } returns Result.success(mockUserDto)
        coEvery { mockUserMapper.toModel(mockUserDto) } returns mockUserModel

        // When: выполнение метода
        val result = repository.getUser(userId)

        // Then: проверка результата
        assertThat(result).isInstanceOf(RequestResult.Success::class.java)
        val successResult = result as RequestResult.Success
        assertThat(successResult.data).isEqualTo(mockUserModel)

        // ✅ Проверка вызовов методов
        coVerify { mockUserApi.fetchUser(userId) }
        coVerify { mockUserMapper.toModel(mockUserDto) }
    }

    // ========================
    // getUser() - Error Case
    // ========================

    @DisplayName("When getUser called and API returns error - Then return Failure")
    @Test
    fun getUser_apiError_returnsFailure() = runTest {
        // Given: API возвращает ошибку
        val userId = "user123"
        val exception = Exception("Network error")
        coEvery { mockUserApi.fetchUser(userId) } throws exception

        // When: выполнение метода
        val result = repository.getUser(userId)

        // Then: проверка, что вернулась ошибка
        assertThat(result).isInstanceOf(RequestResult.Failure::class.java)
        val failureResult = result as RequestResult.Failure
        assertThat(failureResult.error.message).contains("Network error")
    }

    // ========================
    // getUserFlow() - с Flow
    // ========================

    @DisplayName("When getUserFlow called - Then return Flow with Loading and Success states")
    @Test
    fun getUserFlow_validId_returnsFlowWithStates() = runTest {
        // Given: подготовка данных
        val userId = "user123"
        val mockUserDto = mockk<UserDto>(relaxed = true)
        val mockUserModel = mockk<UserModel>(relaxed = true)

        coEvery { mockUserApi.fetchUser(userId) } returns Result.success(mockUserDto)
        coEvery { mockUserMapper.toModel(mockUserDto) } returns mockUserModel

        // When & Then: проверка Flow значений
        repository.getUserFlow(userId).test {
            // First emission: Loading
            val loadingState = awaitItem()
            assertThat(loadingState).isInstanceOf(DataState.Loading::class.java)

            // Second emission: Success
            val successState = awaitItem()
            assertThat(successState).isInstanceOf(DataState.Success::class.java)
            assertThat((successState as DataState.Success).data).isEqualTo(mockUserModel)

            // Flow завершена
            awaitComplete()
        }

        // ✅ FlowTestUtils для Flow методов
        FlowTestUtils.coVerifyFlowCall { repository.getUserFlow(userId) }
    }

    // ========================
    // saveUser() - Happy Path
    // ========================

    @DisplayName("When saveUser called with valid user - Then return Success")
    @Test
    fun saveUser_validUser_returnsSuccess() = runTest {
        // Given: подготовка пользователя
        val mockUser = mockk<UserModel>(relaxed = true)
        val mockUserDto = mockk<UserDto>(relaxed = true)

        coEvery { mockUserMapper.toDto(mockUser) } returns mockUserDto
        coEvery { mockUserApi.saveUser(mockUserDto) } returns Result.success(Unit)

        // When
        val result = repository.saveUser(mockUser)

        // Then
        assertThat(result).isInstanceOf(RequestResult.Success::class.java)
        coVerify { mockUserApi.saveUser(mockUserDto) }
    }

    // ========================
    // clearCache() - Edge Case
    // ========================

    @DisplayName("When clearCache called - Then clear all cached data")
    @Test
    fun clearCache_called_clearsCachedData() = runTest {
        // Given: подготовка кэша
        val cacheSlot = slot<String>()
        every { mockUserApi.clearCache(capture(cacheSlot)) } just Runs

        // When
        repository.clearCache()

        // Then: проверка, что кэш очищен
        verify { mockUserApi.clearCache(any()) }
        assertThat(cacheSlot.captured).isEqualTo("user_cache")
    }
}
