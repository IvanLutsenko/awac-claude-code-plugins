# AWAC Claude Code Plugins

Custom Claude Code plugins by Ivan Lutsenko

## Available Plugins

### Test Standards
Автоматическая генерация и валидация unit тестов для Android/Kotlin по корпоративным стандартам Bereke Business.

**Features:**
- `/generate-test` - генерация теста для одного класса
- `/validate-test` - валидация теста на соответствие стандартам
- `/test-module-business-core` - покрытие бизнес-логики модуля
- `/test-module-all` - покрытие всех классов модуля
- `test-engineer` агент для сложных задач

**Category:** Testing
**Version:** 1.0.0
**Status:** ✅ Production Ready

### Crashlytics
Firebase Crashlytics integration (Work in Progress)

**Category:** Development
**Version:** 0.1.0
**Status:** 🚧 Work in Progress

## Installation

```bash
# Добавь marketplace
/plugin marketplace add awac https://github.com/IvanLutsenko/awac-claude-code-plugins

# Установи plugin
/plugin install test-standards@awac
```

## Documentation

- [Test Standards Plugin](plugins/test-standards/README.md)
- [Crashlytics Plugin](plugins/crashlytics/README.md)

## Author

Ivan Lutsenko
GitHub: [@IvanLutsenko](https://github.com/IvanLutsenko)

## License

MIT - see [LICENSE](LICENSE)
