# Contributing to Flutter Notification Flow

Thank you for your interest in contributing to `flutter_notification_flow`! We welcome contributions, bug fixes, feature requests, and documentation improvements.

---

## 🛠️ Development Workflow

### 1. Fork & Clone
Fork the repository on GitHub and clone your fork locally:

```bash
git clone https://github.com/YOUR_USERNAME/flutter_notification_flow.git
cd flutter_notification_flow
```

### 2. Create a Feature Branch
```bash
git checkout -b feature/my-new-feature
```

### 3. Install Dependencies
Install dependencies for both the core package and the example project:

```bash
flutter pub get
cd example && flutter pub get && cd ..
```

### 4. Implement Your Changes
Write clean, well-documented, null-safe Dart code. Keep changes focused and avoid unnecessary abstractions or dependencies.

### 5. Format & Validate
Ensure all code passes formatting, analysis, and tests before opening a pull request:

```bash
# Format code
dart format .

# Verify formatting
dart format --output=none --set-exit-if-changed .

# Static analysis
flutter analyze

# Run unit and widget tests
flutter test

# Verify pub.dev publishing rules
flutter pub publish --dry-run
```

### 6. Commit & Push
Use clear, conventional commit messages (e.g. `feat: add payload transformer hook`, `fix: resolve race condition in queue drain`):

```bash
git add .
git commit -m "feat: description of changes"
git push origin feature/my-new-feature
```

### 7. Open a Pull Request
Open a pull request targeting the `main` branch of `sapanlabs/flutter_notification_flow`. Fill in the provided pull request template with a concise explanation of what was changed and why.

---

## 🧭 Core Contribution Principles

1. **Keep APIs Simple & Intuitive**: Design for developer experience. Avoid forcing complex boilerplate on developers.
2. **Zero Unnecessary Dependencies**: Keep the package lightweight. Use Dart and Flutter SDK built-ins whenever possible.
3. **Comprehensive Testing**: Always write meaningful tests in `test/` for any new logic, edge cases, or bug fixes.
4. **Documentation**: Update [README.md](README.md) and Dart doc comments if you introduce or alter public APIs.
5. **Backward Compatibility**: Preserve existing APIs whenever feasible. If a breaking change is unavoidable, describe it clearly in your PR.

---

## 💬 Questions or Bug Reports?

If you find a bug or have an idea for a feature, please [open an issue](https://github.com/sapanlabs/flutter_notification_flow/issues) using the appropriate issue template.
