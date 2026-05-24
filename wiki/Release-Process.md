# Release Process

## Versioning

Version is defined in `pubspec.yaml`.

## Before Release

1. Update `CHANGELOG.md`.
2. Run checks:

```bash
flutter analyze
flutter test
```

3. Validate app runs on iOS.

## Publish

1. Bump app version.
2. Commit release notes and version updates.
3. Tag release (for example `v1.1.0`).
4. Publish GitHub Release.
