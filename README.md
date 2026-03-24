# Family Expense Tracker

A Flutter application that allows families to collaboratively track expenses, income, and investments in one shared account. Built with Firebase for authentication and real-time data storage.

## Features

### Authentication

- Email and password login/registration via Firebase Auth
- User profile creation with display name
- Secure session management with automatic auth state handling
- **Forgot Password** flow with email-based password reset

### Family Sharing

- Create a family group and get a 6-character invite code
- Share the invite code with family members (spouse, partner, etc.)
- All members see the same expenses, income, and investments in real time
- Each transaction shows who created it

### Custom Categories

- Each family can fully customize their **expense categories**, **income sources**, and **investment types**
- Manage categories from the Family tab with expandable sections for each type
- Add new categories or remove unused ones at any time
- Defaults provided on family creation (11 expense, 7 income, 8 investment categories)
- Existing records retain their category even if it's later removed from the active list

### Expense Tracking

- Add expenses with four fields: **date** (yyyy-MM-dd), **category**, **amount**, and **notes**
- Default categories: Food & Dining, Transportation, Housing & Rent, Utilities, Entertainment, Healthcare, Shopping, Education, Personal Care, Insurance, Other (customizable per family)
- Edit or swipe-to-delete any expense
- Filter by month with a month selector
- Expenses grouped by date with daily totals
- Color-coded categories with automatic color assignment for custom categories

### Income Tracking

- Track income from multiple sources (default: Salary, Freelance, Business, Dividends, Rental Income, Interest, Other — customizable per family)
- Monthly total summary card
- Same add/edit/delete UX as expenses

### Investment Tracking

- Track investments across types (default: Stocks, Mutual Funds, Real Estate, Cryptocurrency, Bonds, Fixed Deposit, Gold, Other — customizable per family)
- Summary breakdown by investment type
- Monthly total with per-type aggregation

### Dashboard & Reports

- Month-by-month navigation
- **Total Expenses** summary card prominently displayed
- **Expense by Category** pie chart with percentage labels and legend
- **Monthly Expense Trend** bar chart showing totals over the last 6 months
- **Category Trends** line chart tracking the top 5 expense categories over 6 months
- Income, Investments, and Net Savings cards hidden by default — tap to reveal (privacy-focused)

### Privacy & Compliance (App Store Ready)

- In-app **Privacy Policy** and **Terms of Service** documents
- Links shown during registration and in the Family/Account settings
- **Account deletion** feature with two-step confirmation and password re-authentication
- Full data cleanup on deletion: user profile, family membership, and (if sole member) all family data

## Tech Stack


| Layer           | Technology                                |
| --------------- | ----------------------------------------- |
| Framework       | Flutter 3.38+ (Dart 3.10+)                |
| UI              | Material 3 with `colorSchemeSeed` theming |
| Auth            | Firebase Authentication (email/password)  |
| Database        | Cloud Firestore (real-time streams)       |
| Charts          | fl_chart                                  |
| Date Formatting | intl                                      |

### Navigation (Bottom Tab Bar)

| Tab Position | Label    | Screen                                              |
| ------------ | -------- | --------------------------------------------------- |
| 1 (default)  | Expenses | Expense list grouped by date, add/edit/delete       |
| 2            | Income   | Income list with monthly summary                    |
| 3            | Invest   | Investment list with type breakdown                 |
| 4            | Family   | Members, invite code, category management, settings |
| 5            | Reports  | Charts, trends, and hidden income/investment cards  |


## Project Structure

```
lib/
├── main.dart                    # App entry, AuthGate, UserGate, routes
├── firebase_options.dart        # FlutterFire CLI generated config
├── models/
│   ├── app_user.dart            # User profile model
│   ├── expense.dart             # Expense model + default categories
│   ├── family_group.dart        # Family group model (incl. custom categories)
│   ├── income.dart              # Income model + default sources
│   └── investment.dart          # Investment model + default types
├── services/
│   ├── auth_service.dart        # Firebase Auth wrapper (login, register, reset, delete)
│   └── database_service.dart    # Firestore CRUD + category management
└── views/
    ├── login_view.dart          # Login screen with forgot-password flow
    ├── register_view.dart       # Registration with privacy/terms links
    ├── family_setup_view.dart   # Create or join family
    ├── home_shell.dart          # Bottom nav shell + family category streaming
    ├── dashboard_view.dart      # Reports: pie, bar, line charts + sensitive toggle
    ├── expenses_view.dart       # Expense list + add/edit (dynamic categories)
    ├── income_view.dart         # Income list + add/edit (dynamic sources)
    ├── investments_view.dart    # Investment list + add/edit (dynamic types)
    ├── family_view.dart         # Family mgmt, category mgmt, account deletion
    ├── privacy_policy_view.dart # In-app Privacy Policy
    └── terms_view.dart          # In-app Terms of Service
```

## Firestore Data Model

```
users/{uid}
  ├── email: string
  ├── displayName: string
  ├── familyId: string | null
  └── createdAt: timestamp

families/{familyId}
  ├── name: string
  ├── inviteCode: string (6-char alphanumeric)
  ├── ownerId: string
  ├── memberIds: string[]
  ├── memberNames: { uid: name }
  ├── expenseCategories: string[]    # custom per family
  ├── incomeSources: string[]        # custom per family
  ├── investmentTypes: string[]      # custom per family
  ├── createdAt: timestamp
  ├── expenses/{id}
  │     ├── date: string (yyyy-MM-dd)
  │     ├── category: string
  │     ├── amount: number
  │     ├── notes: string
  │     ├── createdBy: string (uid)
  │     ├── createdByName: string
  │     └── createdAt: timestamp
  ├── income/{id}
  │     ├── date: string (yyyy-MM-dd)
  │     ├── source: string
  │     ├── amount: number
  │     ├── notes: string
  │     ├── createdBy: string (uid)
  │     ├── createdByName: string
  │     └── createdAt: timestamp
  └── investments/{id}
        ├── date: string (yyyy-MM-dd)
        ├── source: string
        ├── amount: number
        ├── notes: string
        ├── createdBy: string (uid)
        ├── createdByName: string
        └── createdAt: timestamp
```

## Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.38 or later
- [Dart SDK](https://dart.dev/get-dart) 3.10 or later
- [Firebase CLI](https://firebase.google.com/docs/cli) (`npm install -g firebase-tools`)
- [FlutterFire CLI](https://firebase.flutter.dev/docs/cli/) (`dart pub global activate flutterfire_cli`)
- **For iOS:** Xcode 15+ with command-line tools, CocoaPods
- **For Android:** Android Studio with Android SDK 21+, Java 17+

## Running Locally

### 1. Clone the repository

```bash
git clone <repo-url>
cd expensetracker
```

### 2. Firebase config

Firebase API keys are kept out of source control. Copy the example config and fill in your values:

```bash
cp firebase_config.example.json firebase_config.json
```

Then edit `firebase_config.json` with your Firebase project keys. You can find these values in the [Firebase Console](https://console.firebase.google.com/) under Project Settings > General.

Alternatively, if setting up from scratch, run:

```bash
firebase login
flutterfire configure
```

Then copy the generated values from `lib/firebase_options.dart` into `firebase_config.json`.

### 3. Install dependencies

```bash
flutter pub get
```

### 4. Run the app

All `flutter run` and `flutter build` commands require the config file flag:

```bash
# List available devices
flutter devices

# Run on a specific platform
flutter run --dart-define-from-file=firebase_config.json -d chrome    # Web
flutter run --dart-define-from-file=firebase_config.json -d macos     # macOS
flutter run --dart-define-from-file=firebase_config.json              # Default device

# Run on iOS simulator
open -a Simulator
flutter run --dart-define-from-file=firebase_config.json -d iPhone

# Run on Android emulator
flutter run --dart-define-from-file=firebase_config.json -d emulator-5554
```

### 5. Firebase Console

Manage your Firebase project at:
[https://console.firebase.google.com/u/0/project/expense-tracker-cc8ed/overview](https://console.firebase.google.com/u/0/project/expense-tracker-cc8ed/overview)

### Firestore Security Rules (Recommended)

Set these rules in the Firebase Console under Firestore > Rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }

    match /families/{familyId} {
      allow read: if request.auth != null
        && request.auth.uid in resource.data.memberIds;
      allow create: if request.auth != null;
      allow update: if request.auth != null
        && request.auth.uid in resource.data.memberIds;

      match /expenses/{expenseId} {
        allow read, write: if request.auth != null
          && request.auth.uid in get(/databases/$(database)/documents/families/$(familyId)).data.memberIds;
      }

      match /income/{incomeId} {
        allow read, write: if request.auth != null
          && request.auth.uid in get(/databases/$(database)/documents/families/$(familyId)).data.memberIds;
      }

      match /investments/{investmentId} {
        allow read, write: if request.auth != null
          && request.auth.uid in get(/databases/$(database)/documents/families/$(familyId)).data.memberIds;
      }
    }
  }
}
```

## Deploying to iOS (App Store)

### 1. Apple Developer Account

Sign up at [https://developer.apple.com/programs/](https://developer.apple.com/programs/) ($99/year).

### 2. Configure Xcode project

```bash
open ios/Runner.xcworkspace
```

In Xcode:

- Select the **Runner** target
- Under **Signing & Capabilities**, select your Team and set a unique **Bundle Identifier** (e.g. `com.yourcompany.expensetracker`)
- Set the **Display Name** and **Version/Build** numbers
- Under **General**, set the minimum iOS deployment target (iOS 14.0+ recommended)

### 3. App icons and launch screen

- Replace the icons in `ios/Runner/Assets.xcassets/AppIcon.appiconset/` with your own (use a tool like [AppIcon.co](https://appicon.co/))
- Update the launch screen in `ios/Runner/Base.lproj/LaunchScreen.storyboard`

### 4. Build the release archive

```bash
flutter build ipa --dart-define-from-file=firebase_config.json
```

This creates a `.ipa` file at `build/ios/ipa/`.

### 5. Upload to App Store Connect

Option A - Using Xcode:

```bash
open build/ios/archive/Runner.xcarchive
```

In Xcode Organizer, click **Distribute App** > **App Store Connect** > **Upload**.

Option B - Using the command line:

```bash
xcrun altool --upload-app --type ios \
  --file build/ios/ipa/expensetracker.ipa \
  --apiKey YOUR_API_KEY --apiIssuer YOUR_ISSUER_ID
```

### 6. Submit for review

- Go to [App Store Connect](https://appstoreconnect.apple.com/)
- Fill in the app metadata: description, screenshots, keywords, categories
- Submit the build for App Review

## Deploying to Android (Google Play Store)

### 1. Google Play Developer Account

Sign up at [https://play.google.com/console/](https://play.google.com/console/) ($25 one-time fee).

### 2. Create a signing key

```bash
keytool -genkey -v -keystore ~/expensetracker-release-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias expensetracker
```

Keep this keystore file safe - you need it for every future update.

### 3. Configure signing in Gradle

Create `android/key.properties` (do NOT commit this file):

```properties
storePassword=<your-store-password>
keyPassword=<your-key-password>
keyAlias=expensetracker
storeFile=<path-to>/expensetracker-release-key.jks
```

Update `android/app/build.gradle.kts` to reference the key properties:

```kotlin
import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    // ... existing config ...

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}
```

### 4. Update app metadata

In `android/app/build.gradle.kts`:

- Set `applicationId` (e.g. `com.yourcompany.expensetracker`)
- Set `versionCode` and `versionName`
- Set `minSdk` to 21 or higher

### 5. Build the release bundle

```bash
flutter build appbundle --dart-define-from-file=firebase_config.json
```

This creates an `.aab` file at `build/app/outputs/bundle/release/app-release.aab`.

For APK instead (e.g., for direct distribution):

```bash
flutter build apk --release --dart-define-from-file=firebase_config.json
```

### 6. Upload to Google Play Console

- Go to [Google Play Console](https://play.google.com/console/)
- Create a new app, fill in the store listing (title, description, screenshots, category)
- Go to **Release** > **Production** > **Create new release**
- Upload the `.aab` file
- Complete the content rating questionnaire and pricing/distribution settings
- Submit for review

## Adding `key.properties` to `.gitignore`

Make sure your signing keys are not committed:

```
# Add to .gitignore
android/key.properties
*.jks
*.keystore
```

## Useful Commands

```bash
# Install dependencies
flutter pub get

# Run analyzer
flutter analyze

# Run tests
flutter test

# Build for web
flutter build web --dart-define-from-file=firebase_config.json

# Build iOS release
flutter build ipa --dart-define-from-file=firebase_config.json

# Build Android release bundle
flutter build appbundle --dart-define-from-file=firebase_config.json

# Clean build artifacts
flutter clean

# Upgrade dependencies
flutter pub upgrade --major-versions
```

## Firebase Setup Commands (Reference)

These were used to initially set up the project:

```bash
flutter create --org com.truecube expensetracker
flutter pub add firebase_core
flutter pub add firebase_auth
flutter pub add cloud_firestore
flutter pub add firebase_analytics
flutter pub add fl_chart
flutter pub add intl
dart pub global activate flutterfire_cli
firebase login
flutterfire configure
```

