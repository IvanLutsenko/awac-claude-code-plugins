# Cache Hit/Miss Test Template

**Size**: ~600 tokens | **Use**: Repository methods with cache logic

---

## Pattern

Repository with local cache (in-memory, SharedPreferences, Room):

```kotlin
// Source
class CachedRepository(
    private val api: Api,
    private val cache: Cache
) {
    suspend fun getData(key: String, forceRefresh: Boolean = false): Data? {
        // 1. Check cache first
        if (!forceRefresh) {
            val cached = cache.get(key)
            if (cached != null) return cached  // Cache HIT
        }

        // 2. Fetch from API
        val fresh = api.fetchData(key)

        // 3. Update cache
        cache.put(key, fresh)

        return fresh  // Cache MISS
    }
}
```

---

## Generated Tests

```kotlin
// ==================== Cache HIT Tests ====================

@DisplayName("When getData with cache HIT - Then returns cached data without API call")
@Test
fun getData_cacheHit_returnsCachedData() = runTest {
    // Given
    val key = "test_key"
    val cachedData = mockk<Data>(relaxed = true)
    every { mockCache.get(key) } returns cachedData

    // When
    val result = repository.getData(key, forceRefresh = false)

    // Then
    assertThat(result).isEqualTo(cachedData)
    verify { mockCache.get(key) }
    coVerify(exactly = 0) { mockApi.fetchData(any()) }  // API NOT called
    verify(exactly = 0) { mockCache.put(any(), any()) }  // Cache NOT updated
}

@DisplayName("When getData called twice - Then second call hits cache")
@Test
fun getData_twoCalls_secondHitsCache() = runTest {
    // Given
    val key = "test_key"
    val freshData = mockk<Data>(relaxed = true)
    every { mockCache.get(key) } returns null andThen freshData
    coEvery { mockApi.fetchData(key) } returns freshData

    // When - First call (cache MISS)
    val result1 = repository.getData(key, forceRefresh = false)

    // Then - API called, cache updated
    assertThat(result1).isEqualTo(freshData)
    coVerify(exactly = 1) { mockApi.fetchData(key) }
    verify { mockCache.put(key, freshData) }

    // When - Second call (cache HIT)
    val result2 = repository.getData(key, forceRefresh = false)

    // Then - API NOT called again
    assertThat(result2).isEqualTo(freshData)
    coVerify(exactly = 1) { mockApi.fetchData(key) }  // Still 1, not 2
}

// ==================== Cache MISS Tests ====================

@DisplayName("When getData with cache MISS - Then fetches from API and updates cache")
@Test
fun getData_cacheMiss_fetchesFromApiAndUpdatesCache() = runTest {
    // Given
    val key = "test_key"
    val freshData = mockk<Data>(relaxed = true)
    every { mockCache.get(key) } returns null  // Cache MISS
    coEvery { mockApi.fetchData(key) } returns freshData

    // When
    val result = repository.getData(key, forceRefresh = false)

    // Then
    assertThat(result).isEqualTo(freshData)
    coVerify(exactly = 1) { mockApi.fetchData(key) }
    verify { mockCache.put(key, freshData) }
}

@DisplayName("When getData with empty cache - Then returns null")
@Test
fun getData_emptyCache_returnsNull() = runTest {
    // Given
    val key = "test_key"
    every { mockCache.get(key) } returns null
    coEvery { mockApi.fetchData(key) } returns null  // API returns null too

    // When
    val result = repository.getData(key, forceRefresh = false)

    // Then
    assertThat(result).isNull()
    coVerify { mockApi.fetchData(key) }
}

// ==================== Force Refresh Tests ====================

@DisplayName("When getData with forceRefresh true - Then skips cache and fetches from API")
@Test
fun getData_forceRefresh_skipsCacheAndFetchesFromApi() = runTest {
    // Given
    val key = "test_key"
    val cachedData = mockk<Data>(relaxed = true)
    val freshData = mockk<Data>(relaxed = true)
    every { mockCache.get(key) } returns cachedData  // Has cached data
    coEvery { mockApi.fetchData(key) } returns freshData

    // When
    val result = repository.getData(key, forceRefresh = true)

    // Then
    assertThat(result).isEqualTo(freshData)  // Fresh data, not cached
    coVerify(exactly = 1) { mockApi.fetchData(key) }
    verify { mockCache.put(key, freshData) }  // Cache updated with fresh
}

@DisplayName("When getData with forceRefresh and cache HIT - Then ignores cache")
@Test
fun getData_forceRefresh_withCacheHit_ignoresCache() = runTest {
    // Given
    val key = "test_key"
    val cachedData = mockk<Data>(relaxed = true)
    val freshData = mockk<Data>(relaxed = true)
    every { mockCache.get(key) } returns cachedData
    coEvery { mockApi.fetchData(key) } returns freshData

    // When
    val result = repository.getData(key, forceRefresh = true)

    // Then
    assertThat(result).isNotEqualTo(cachedData)  // Not the cached value
    assertThat(result).isEqualTo(freshData)
    coVerify { mockApi.fetchData(key) }  // API was called
}

// ==================== API Error Tests ====================

@DisplayName("When getData and API throws exception - Then propagates error without cache update")
@Test
fun getData_apiThrowsException_propagatesError() = runTest {
    // Given
    val key = "test_key"
    val exception = NetworkException("Connection failed")
    every { mockCache.get(key) } returns null
    coEvery { mockApi.fetchData(key) } throws exception

    // When & Then
    assertThrows<NetworkException> {
        repository.getData(key, forceRefresh = false)
    }

    coVerify { mockApi.fetchData(key) }
    verify(exactly = 0) { mockCache.put(any(), any()) }  // Cache NOT updated on error
}

@DisplayName("When getData with cache HIT and API would fail - Then still works (offline)")
@Test
fun getData_cacheHit_andApiDown_stillReturnsCached() = runTest {
    // Given
    val key = "test_key"
    val cachedData = mockk<Data>(relaxed = true)
    every { mockCache.get(key) } returns cachedData

    // When
    val result = repository.getData(key, forceRefresh = false)

    // Then - Works even if API is down
    assertThat(result).isEqualTo(cachedData)
    coVerify(exactly = 0) { mockApi.fetchData(any()) }  // API NOT called
}
```

---

## Template Variables

| Variable | Description |
|----------|-------------|
| `{key}` | Cache key parameter |
| `{cachedData}` | Mocked cached data |
| `{freshData}` | Mocked fresh data from API |
| `{Data}` | Return type |
| `{forceRefresh}` | Force refresh parameter name |
| `{exception}` | Expected exception type |

---

## Coverage Checklist

- [ ] Cache HIT path (data in cache, forceRefresh=false)
- [ ] Cache MISS path (no data in cache)
- [ ] Force refresh (forceRefresh=true) skips cache
- [ ] Empty cache returns null/handles gracefully
- [ ] API error doesn't corrupt cache
- [ ] Offline mode works with cached data
- [ ] Second call hits cache (API called once)
