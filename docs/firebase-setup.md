# Firebase setup

Every independent DailyHQ deployment should use its own Firebase project.

## Configure Firebase

1. Create or select a project in the [Firebase Console](https://console.firebase.google.com/).
2. Open **Authentication → Sign-in method** and enable **Email/Password**.
3. Open **Firestore Database** and create a database in the region appropriate for you.
4. Install and authenticate the Firebase CLI and FlutterFire CLI.
5. Run this from the repository root:

   ```powershell
   flutterfire configure --project=YOUR_PROJECT_ID --platforms=android,windows
   ```

   This regenerates `lib/firebase_options.dart` and the Android Firebase configuration for your project.

6. Deploy the repository's Firestore rules:

   ```powershell
   firebase deploy --only firestore:rules --project YOUR_PROJECT_ID
   ```

7. Open **Authentication → Users → Add user** and create your personal email/password user.
8. Run DailyHQ and connect each device once with those credentials.

DailyHQ does not expose account creation. Firebase persists the session locally until **Disconnect this device** is selected in Settings or Firebase invalidates the session.

## Data paths

The current feature collections are:

```text
users/{userId}/linkedin_posts/{postId}
users/{userId}/project_ideas/{ideaId}
users/{userId}/projects/{projectId}
users/{userId}/daily_tasks/{taskId}
users/{userId}/recurring_daily_tasks/{recurringTaskId}
users/{userId}/todos/{todoId}
users/{userId}/daily_journals/{journalId}
users/{userId}/learning_items/{learningItemId}
users/{userId}/thought_days/{thoughtDayId}
```

The included rules require authentication and require the UID in the request path to equal the authenticated UID. No public reads or writes are allowed.

## Credentials and API keys

FlutterFire-generated client configuration is expected to ship with a client application. Its API keys are identifiers, not substitutes for authentication or Firestore authorization.

Still apply the platform restrictions recommended by Firebase/Google Cloud, and never commit service-account JSON, Admin SDK credentials, passwords, release signing keys, or CI secrets. See [SECURITY.md](../SECURITY.md) for reporting guidance.
