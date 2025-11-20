# AWAC Claude Code Plugins

Custom Claude Code plugins by Ivan Lutsenko

## Available Plugins

### Bereke Business Test Gen
Automated unit test generation for Kotlin/Android business logic with corporate standards.

**Commands:**
- `/test-class path/to/ClassName.kt` - генерация теста для одного класса (2-5 мин)
- `/test-coverage path/to/module` - полное покрытие модуля (20-30 мин)
- `/validate-tests path/to/module` - валидация существующих тестов (опционально)

**Agent:**
- `test-engineer` - senior test automation engineer для сложных задач

**Category:** Testing
**Version:** 2.0.0
**Status:** ✅ Production Ready

### Crashlytics
Firebase Crashlytics integration (Work in Progress)

**Category:** Development
**Version:** 0.1.0
**Status:** 🚧 Work in Progress

## Installation

```bash
# Добавь marketplace
/plugin marketplace add https://github.com/IvanLutsenko/awac-claude-code-plugins

# Установи plugin
/plugin install bereke-business-test-gen
```

## Usage

```bash
# Тест для одного класса
/test-class src/main/java/.../YourClass.kt

# Полное покрытие модуля
/test-coverage feature/auth
```

## Documentation

- [Test Generation](plugins/bereke-business-test-gen/README.md)
- [Crashlytics Plugin](plugins/crashlytics/README.md)

## Author

Ivan Lutsenko
GitHub: [@IvanLutsenko](https://github.com/IvanLutsenko)

## License

MIT - see [LICENSE](LICENSE)
