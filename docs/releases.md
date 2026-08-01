# Release process

DailyHQ follows semantic versions such as `1.0.0`. The application version is declared in `pubspec.yaml`; Flutter's suffix after `+` is the platform build number.

## Prepare a release

1. Update `version` in `pubspec.yaml`.
2. Add the release and date to `CHANGELOG.md`.
3. Run formatting, analysis, and tests.
4. Merge the release changes into `main`.
5. Create and push a matching annotated tag:

   ```powershell
   git tag -a v1.0.0 -m "DailyHQ v1.0.0"
   git push origin v1.0.0
   ```

The tag must match the `pubspec.yaml` version without its build-number suffix.

## Automated publishing

The build workflow compiles the Android APK and Windows installer. For a `v*` tag, it verifies the version and creates a GitHub Release containing:

- `DailyHQ-Android.apk`
- `DailyHQ-Setup.exe`

Normal pushes, pull requests, and manual workflow runs build artifacts but do not publish a release.

## Signing limitation

The current public CI artifacts are not production code-signed. Windows SmartScreen and Android may warn users. Official store distribution should add protected signing credentials through GitHub Actions secrets without committing them to the repository.
