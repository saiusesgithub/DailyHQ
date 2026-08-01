# Contributing to DailyHQ

Thanks for helping improve DailyHQ. The project favors focused, maintainable changes over speculative architecture.

## Before you start

- Search existing issues before opening a new one.
- Use an issue to discuss substantial features or architectural changes first.
- Keep pull requests limited to one coherent change.
- Do not include personal Firebase projects, credentials, service-account files, or production data.

## Development workflow

1. Fork the repository and create a branch from `main`.
2. Follow [the Firebase setup guide](docs/firebase-setup.md) with your own Firebase project.
3. Install dependencies with `flutter pub get`.
4. Make the smallest change that solves the issue.
5. Add or update tests for behavior changes.
6. Run:

   ```powershell
   dart format lib test
   flutter analyze
   flutter test
   ```

7. Open a pull request and complete the checklist.

## Project conventions

- Use Material 3 and preserve the compact, calm interface in both themes.
- Check narrow Android layouts and wide Windows layouts.
- Keep feature-specific domain, data, and presentation code together under `lib/features/<feature>`.
- Use focused Firestore repositories; do not introduce generic CRUD abstractions.
- Keep all user data below `users/{userId}` and update `firestore.rules` when adding a collection.
- Avoid adding state-management, routing, or persistence packages without a current need.
- Never add fake dashboard statistics or production sample records.

## Commit messages

Short Conventional Commit-style messages are encouraged, for example:

```text
feat: add project deadline filtering
fix: prevent duplicate recurring tasks
docs: clarify Firebase setup
```

By contributing, you agree that your contribution is licensed under the project's MIT License.
