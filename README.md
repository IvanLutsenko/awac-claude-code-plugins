# AWAC Claude Code Plugins

Custom Claude Code plugins by Ivan Lutsenko

## Installation

Add the marketplace once, then install plugins as needed:

```bash
/plugin marketplace add https://github.com/IvanLutsenko/awac-claude-code-plugins
```

## Available Plugins

### Bereke Business Test Gen

Automated unit test generation for Kotlin/Android business logic with corporate standards.

📚 **[Full Documentation](plugins/bereke-business-test-gen/README.md)**

**Installation:**
```bash
/plugin install bereke-business-test-gen
```

**Quick Start:**
```bash
/test-class src/main/java/.../YourClass.kt      # Single class (2-5 min)
/test-module feature/auth                        # Full module coverage (20-30 min)
```

**Status:** ✅ Production Ready | **Version:** 2.0.0

---

### Crashlytics

Firebase Crashlytics integration

📚 **[Full Documentation](plugins/crashlytics/README.md)**

**Status:** 🚧 Work in Progress | **Version:** 0.1.0

---

## Author

Ivan Lutsenko
GitHub: [@IvanLutsenko](https://github.com/IvanLutsenko)

## License

MIT - see [LICENSE](LICENSE)
