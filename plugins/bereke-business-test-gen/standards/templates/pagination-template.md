# Pagination Test Template

**Size**: ~700 tokens | **Use**: PagingData repositories with loadMore functionality

---

## Pattern

Repository with pagination support:

```kotlin
// Source
class DocumentRepository(
    private val api: DocumentApi,
    private val cache: DocumentCache
) {

    companion object {
        private const val PAGE_SIZE = 20
    }

    fun searchDocuments(
        query: String,
        loadMore: Boolean = false
    ): Flow<PagingData<Document>> = flow {
        emit(PagingData.loading())

        val offset = if (loadMore) {
            cache.getCurrentOffset() ?: 0
        } else {
            0
        }

        try {
            val response = api.searchDocuments(
                query = query,
                limit = PAGE_SIZE,
                offset = offset
            )

            if (response.isSuccessful) {
                val documents = response.body()?.results ?: emptyList()

                if (loadMore) {
                    cache.appendDocuments(documents)
                } else {
                    cache.setDocuments(documents)
                }

                cache.setCurrentOffset(offset + documents.size)

                val hasMore = documents.size >= PAGE_SIZE
                cache.setHasMore(hasMore)

                emit(PagingData.success(documents, hasMore))
            } else {
                emit(PagingData.error(response.message()))
            }
        } catch (e: Exception) {
            emit(PagingData.error(e.message ?: "Unknown error"))
        }
    }

    suspend fun loadMore(): Flow<PagingData<Document>> {
        val currentQuery = cache.getCurrentQuery() ?: return flowOf(
            PagingData.error("No search query")
        )
        return searchDocuments(currentQuery, loadMore = true)
    }
}

sealed class PagingData<out T> {
    data class Loading<T> : PagingData<T>()
    data class Success<T>(
        val results: List<T>,
        val hasMore: Boolean
    ) : PagingData<T>()
    data class Error<T>(val message: String) : PagingData<T>()

    fun <R> map(transform: (T) -> R): PagingData<R> = when (this) {
        is Loading -> Loading()
        is Success -> Success(results.map(transform), hasMore)
        is Error -> Error(message)
    }
}
```

---

## Generated Tests

```kotlin
@OptIn(ExperimentalCoroutinesApi::class)
class DocumentRepositoryTest {

    private val mockApi: DocumentApi = mockk(relaxed = true)
    private val mockCache: DocumentCache = mockk(relaxed = true)
    private lateinit var repository: DocumentRepository

    @BeforeEach
    fun setUp() {
        repository = DocumentRepository(mockApi, mockCache)
    }

    @AfterEach
    fun tearDown() {
        unmockkAll()
        clearAllMocks()
        FlowTestUtils.cleanupFlowResources()
    }

    // ==================== Initial Load Tests ====================

    @DisplayName("When searchDocuments with valid query - Then emits Loading then Success")
    @Test
    fun searchDocuments_validQuery_emitsLoadingThenSuccess() = runTest {
        // Given
        val query = "test"
        val documents = listOf(
            mockk<Document> { every { id } returns "doc_1" },
            mockk<Document> { every { id } returns "doc_2" }
        )
        val response = Response.success(SearchResponse(results = documents))

        coEvery { mockApi.searchDocuments(query, 20, 0) } returns response
        every { mockCache.setDocuments(documents) } just runs
        every { mockCache.setCurrentOffset(2) } just runs
        every { mockCache.setHasMore(true) } just runs  // 2 < 20 (PAGE_SIZE)

        // When & Then
        repository.searchDocuments(query, loadMore = false).test {
            // First emission: Loading
            val loading = awaitItem()
            assertThat(loading).isInstanceOf(PagingData.Loading::class.java)

            // Second emission: Success
            val success = awaitItem()
            assertThat(success).isInstanceOf(PagingData.Success::class.java)

            val data = success as PagingData.Success<Document>
            assertThat(data.results).hasSize(2)
            assertThat(data.results[0].id).isEqualTo("doc_1")
            assertThat(data.hasMore).isTrue()  // Can load more

            awaitComplete()

            // Verify cache operations
            verify { mockCache.setDocuments(documents) }
            verify { mockCache.setCurrentOffset(2) }
            verify { mockCache.setHasMore(true) }
        }

        // Verify API call
        coVerify(exactly = 1) {
            mockApi.searchDocuments(
                query = query,
                limit = 20,
                offset = 0
            )
        }
    }

    @DisplayName("When searchDocuments returns empty - Then hasMore is false")
    @Test
    fun searchDocuments_emptyResults_hasMoreFalse() = runTest {
        // Given
        val query = "no_results"
        val response = Response.success(SearchResponse(results = emptyList()))

        coEvery { mockApi.searchDocuments(query, 20, 0) } returns response
        every { mockCache.setDocuments(emptyList()) } just runs
        every { mockCache.setCurrentOffset(0) } just runs
        every { mockCache.setHasMore(false) } just runs

        // When & Then
        repository.searchDocuments(query).test {
            skip(1) // Skip Loading
            val success = awaitItem() as PagingData.Success<Document>
            assertThat(success.results).isEmpty()
            assertThat(success.hasMore).isFalse()

            verify { mockCache.setHasMore(false) }
            cancelAndIgnoreRemainingEvents()
        }
    }

    // ==================== Load More Tests ====================

    @DisplayName("When loadMore called - Then fetches next page with offset")
    @Test
    fun loadMore_fetchesNextPage() = runTest {
        // Given
        val query = "test"
        val cachedDocuments = listOf(
            mockk<Document> { every { id } returns "doc_1" }
        )
        val newDocuments = listOf(
            mockk<Document> { every { id } returns "doc_21" }
        )
        val response = Response.success(SearchResponse(results = newDocuments))

        every { mockCache.getCurrentQuery() } returns query
        every { mockCache.getCurrentOffset() } returns 20  // Already loaded 20
        coEvery { mockApi.searchDocuments(query, 20, 20) } returns response
        every { mockCache.appendDocuments(newDocuments) } just runs
        every { mockCache.setCurrentOffset(21) } just runs
        every { mockCache.setHasMore(true) } just runs

        // When & Then
        repository.loadMore().test {
            val success = awaitItem() as PagingData.Success<Document>
            assertThat(success.results).hasSize(1)
            assertThat(success.results[0].id).isEqualTo("doc_21")

            // Verify used offset
            coVerify {
                mockApi.searchDocuments(
                    query = query,
                    limit = 20,
                    offset = 20  // Offset from cache
                )
            }

            // Verify append (not replace)
            verify { mockCache.appendDocuments(newDocuments) }

            cancelAndIgnoreRemainingEvents()
        }
    }

    @DisplayName("When loadMore without previous search - Then emits Error")
    @Test
    fun loadMore_withoutPreviousSearch_emitsError() = runTest {
        // Given
        every { mockCache.getCurrentQuery() } returns null

        // When & Then
        repository.loadMore().test {
            val error = awaitItem()
            assertThat(error).isInstanceOf(PagingData.Error::class.java)

            val errorMessage = (error as PagingData.Error<Document>).message
            assertThat(errorMessage).contains("No search query")

            // API should NOT be called
            coVerify(exactly = 0) { mockApi.searchDocuments(any(), any(), any()) }

            cancelAndIgnoreRemainingEvents()
        }
    }

    @DisplayName("When loadMore and no more results - Then hasMore is false")
    @Test
    fun loadMore_noMoreResults_hasMoreFalse() = runTest {
        // Given
        val query = "test"
        val lastPage = listOf(
            mockk<Document> { every { id } returns "doc_last" }
        )
        val response = Response.success(SearchResponse(results = lastPage))

        every { mockCache.getCurrentQuery() } returns query
        every { mockCache.getCurrentOffset() } returns 100
        coEvery { mockApi.searchDocuments(query, 20, 100) } returns response
        every { mockCache.appendDocuments(lastPage) } just runs
        every { mockCache.setCurrentOffset(101) } just runs
        every { mockCache.setHasMore(false) } just runs  // Only 1 result < 20

        // When & Then
        repository.loadMore().test {
            val success = awaitItem() as PagingData.Success<Document>
            assertThat(success.hasMore).isFalse()

            cancelAndIgnoreRemainingEvents()
        }
    }

    // ==================== API Error Tests ====================

    @DisplayName("When searchDocuments and API fails - Then emits Error state")
    @Test
    fun searchDocuments_apiError_emitsError() = runTest {
        // Given
        val query = "test"
        val exception = IOException("Network error")

        coEvery { mockApi.searchDocuments(query, 20, 0) } throws exception

        // When & Then
        repository.searchDocuments(query).test {
            skip(1) // Skip Loading
            val error = awaitItem()
            assertThat(error).isInstanceOf(PagingData.Error::class.java)

            val errorMessage = (error as PagingData.Error<Document>).message
            assertThat(errorMessage).isNotEmpty()

            cancelAndIgnoreRemainingEvents()
        }
    }

    @DisplayName("When searchDocuments and HTTP error - Then emits Error with message")
    @Test
    fun searchDocuments_httpError_emitsErrorWithMessage() = runTest {
        // Given
        val query = "test"
        val errorResponse = Response.error<SearchResponse>(
            500,
            "Server Error".toResponseBody("application/json".toMediaType())
        )

        coEvery { mockApi.searchDocuments(query, 20, 0) } returns errorResponse

        // When & Then
        repository.searchDocuments(query).test {
            skip(1) // Skip Loading
            val error = awaitItem()
            assertThat(error).isInstanceOf(PagingData.Error::class.java)

            cancelAndIgnoreRemainingEvents()
        }
    }

    // ==================== Cache Integration Tests ====================

    @DisplayName("When searchDocuments with loadMore true - Then appends to cache")
    @Test
    fun searchDocuments_loadMoreTrue_appendsToCache() = runTest {
        // Given
        val query = "test"
        val documents = listOf(mockk<Document>())
        val response = Response.success(SearchResponse(results = documents))

        every { mockCache.getCurrentOffset() } returns 20
        coEvery { mockApi.searchDocuments(query, 20, 20) } returns response
        every { mockCache.appendDocuments(documents) } just runs

        // When & Then
        repository.searchDocuments(query, loadMore = true).test {
            awaitItem()

            // Verify append (not set)
            verify(exactly = 1) { mockCache.appendDocuments(documents) }
            verify(exactly = 0) { mockCache.setDocuments(any()) }

            cancelAndIgnoreRemainingEvents()
        }
    }

    @DisplayName("When searchDocuments loadMore false - Then replaces cache")
    @Test
    fun searchDocuments_loadMoreFalse_replacesCache() = runTest {
        // Given
        val query = "test"
        val documents = listOf(mockk<Document>())
        val response = Response.success(SearchResponse(results = documents))

        coEvery { mockApi.searchDocuments(query, 20, 0) } returns response
        every { mockCache.setDocuments(documents) } just runs

        // When & Then
        repository.searchDocuments(query, loadMore = false).test {
            awaitItem()

            // Verify set (not append)
            verify(exactly = 1) { mockCache.setDocuments(documents) }
            verify(exactly = 0) { mockCache.appendDocuments(any()) }

            cancelAndIgnoreRemainingEvents()
        }
    }

    // ==================== Edge Cases ====================

    @DisplayName("When searchDocuments with empty query - Then still calls API")
    @Test
    fun searchDocuments_emptyQuery_callsApi() = runTest {
        // Given
        val query = ""
        val response = Response.success(SearchResponse(results = emptyList()))

        coEvery { mockApi.searchDocuments("", 20, 0) } returns response

        // When & Then
        repository.searchDocuments(query).test {
            awaitItem()

            coVerify { mockApi.searchDocuments("", 20, 0) }
            cancelAndIgnoreRemainingEvents()
        }
    }

    @DisplayName("When page size exactly matches PAGE_SIZE - Then hasMore is true")
    @Test
    fun pageSizeMatches_PAGE_SIZE_hasMoreTrue() = runTest {
        // Given
        val documents = List(20) { mockk<Document>() }  // Exactly PAGE_SIZE
        val response = Response.success(SearchResponse(results = documents))

        coEvery { mockApi.searchDocuments(any(), any(), any()) } returns response
        every { mockCache.setDocuments(any()) } just runs
        every { mockCache.setCurrentOffset(any()) } just runs
        every { mockCache.setHasMore(true) } just runs

        // When & Then
        repository.searchDocuments("test").test {
            skip(1)
            val success = awaitItem() as PagingData.Success<Document>
            assertThat(success.results).hasSize(20)
            assertThat(success.hasMore).isTrue()

            cancelAndIgnoreRemainingEvents()
        }
    }
}
```

---

## Template Variables

| Variable | Description |
|----------|-------------|
| `{PAGE_SIZE}` | Page size constant |
| `{Document}` | Item type |
| `{DocumentCache}` | Cache interface |
| `{SearchResponse}` | API response type |

---

## Coverage Checklist

- [ ] Initial load (offset = 0)
- [ ] Load more (offset from cache)
- [ ] Loading state emitted first
- [ ] Success state with results
- [ ] Empty results (hasMore = false)
- [ ] Full page (hasMore = true)
- [ ] API error handling
- [ ] HTTP error handling
- [ ] Cache append vs set
- [ ] Offset increment
- [ ] Load more without previous query
- [ ] Flow verification with FlowTestUtils
