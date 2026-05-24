# Contributing to PHONE BROKER

Thank you for your interest in contributing.

## Before You Start

- Read the project documentation in `README.md` and `docs/`.
- Search existing issues and pull requests before creating a new one.
- For major changes, open an issue first to align on scope and approach.

## Development Setup

1. Install Flutter (stable), Xcode, and CocoaPods.
2. Run:

```bash
flutter pub get
cd ios
pod install
cd ..
```

3. Run analysis and tests:

```bash
flutter analyze
flutter test
```

## Branching and Commits

- Base your work on the `main` branch.
- Use focused branches per change.
- Keep commits small and descriptive.
- Prefer clear commit messages in imperative mood.

Examples:

- `fix: prevent broker restore timeout`
- `docs: expand troubleshooting guide`
- `feat: add broker diagnostics export`

## Pull Request Checklist

Before submitting a PR, ensure:

- Code builds successfully for iOS.
- `flutter analyze` passes.
- `flutter test` passes.
- Documentation is updated if behavior changed.
- Screenshots are added for visible UI changes.

## Coding Standards

- Follow lints configured in `analysis_options.yaml`.
- Keep APIs stable unless change is intentional and documented.
- Avoid unrelated refactors in feature/fix PRs.
- Add comments only where logic is not self-evident.

## Reporting Bugs

Use the Bug Report issue template and include:

- Device model and iOS version
- App version / commit hash
- Reproducible steps
- Expected vs actual behavior
- Relevant logs or screenshots

## Security Issues

Do not report security issues in public issues.

Please follow `SECURITY.md` for responsible disclosure.
