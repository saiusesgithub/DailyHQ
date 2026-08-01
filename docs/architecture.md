# DailyHQ architecture

DailyHQ uses a deliberately small feature-oriented structure. It is not a plug-in framework, and modules do not need to implement shared interfaces.

## Application layers

- `lib/main.dart` initializes Flutter and Firebase, then starts the application.
- `lib/app` owns the application widget, startup behavior, and themes.
- `lib/shell` owns responsive navigation and the currently selected destination.
- `lib/features` contains implemented product modules.
- `lib/pages` contains simple top-level pages that do not need a complete feature folder.
- `lib/shared` contains only genuinely reused UI helpers.

## Feature modules

A feature may use these folders when it needs them:

- `domain`: immutable feature data and enums, including Firestore conversion.
- `data`: a focused repository for that feature's Firestore operations and streams.
- `presentation`: screens, forms, dialogs, and feature-specific widgets.

Folders should not be created when a feature has nothing meaningful to put in them. Widgets consume real-time repository streams with standard Flutter state tools; there is no global mutable feature state.

## Adding a module

1. Put the feature under `lib/features/<feature_name>`.
2. Define only the domain types required by the current behavior.
3. Keep Firestore access out of presentation widgets in a feature-specific repository.
4. Add a user-owned collection below `users/{userId}`.
5. Add a matching ownership rule in `firestore.rules`.
6. Add the page to `lib/shell/navigation_destination.dart`.
7. Test both narrow and wide layouts.

Do not introduce a generic repository, registry, service locator, or broad design system solely to make a new module look uniform.

## Data ownership

Firebase is the shared source of truth. Feature repositories read and write only within the signed-in user's document path:

```text
users/{userId}/{feature_collection}/{documentId}
```

The app retains Firebase's authenticated session on each device. Firestore rules independently verify that the signed-in UID matches the UID in the requested path.
