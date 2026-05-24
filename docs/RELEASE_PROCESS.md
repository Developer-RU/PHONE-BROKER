# Release Process

## Versioning

Project version is declared in `pubspec.yaml`:

- `version: <major>.<minor>.<patch>+<build>`

Use semantic increments where practical:

- Patch: fixes
- Minor: backward-compatible features
- Major: breaking changes

## Pre-Release Checklist

1. Update `CHANGELOG.md` under `Unreleased`.
2. Run quality checks:

```bash
flutter analyze
flutter test
```

3. Validate iOS build locally.
4. Confirm README/docs reflect behavior changes.

## Release Steps

1. Move changes from `Unreleased` into a new version section in `CHANGELOG.md`.
2. Update `pubspec.yaml` version.
3. Commit release changes.
4. Create Git tag matching release version (for example `v1.1.0`).
5. Publish GitHub Release with highlights and migration notes.

## Post-Release

- Add a fresh `Unreleased` section in `CHANGELOG.md` if needed.
- Verify release artifacts and links.
- Announce key updates in repository channels.
