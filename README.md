# Money Tracker

A beautiful, feature-rich personal finance management app built with Flutter. Track your expenses, manage loans, and get insights into your spending habits - all offline!

## Features

### Expense Tracking
- Add, edit, and delete expenses manually
- Categorize expenses with 14+ customizable categories
- View expenses by month with visual breakdowns
- Auto-detect payments from UPI apps (GPay, PhonePe, Paytm, etc.)
- Merchant rules for automatic categorization

### Loan Management
- Track money you've lent to others
- Track money you've borrowed
- Partial payment tracking
- Settlement history
- Friend-wise loan summary

### Dashboard
- Net balance overview (To Receive vs To Pay)
- Monthly expense progress with budget tracking
- Recent transactions
- Quick access to key metrics

### Settings & Customization
- Dark theme UI
- Customizable monthly budget
- Manage expense categories
- Export data to CSV/JSON
- Secure PIN login option

## Tech Stack

- **Framework:** Flutter
- **Language:** Dart
- **Database:** SQLite (sqflite)
- **State Management:** Provider
- **Local Storage:** SharedPreferences, Flutter Secure Storage
- **Charts:** fl_chart

## Project Structure

```
lib/
├── main.dart
├── app.dart
├── config/
│   ├── constants.dart
│   ├── themes.dart
│   └── routes.dart
├── models/
│   ├── user.dart
│   ├── expense.dart
│   ├── loan.dart
│   ├── friend.dart
│   └── category.dart
├── database/
│   ├── database_helper.dart
│   └── repositories/
├── services/
│   ├── auth_service.dart
│   ├── notification_service.dart
│   └── notification_parser.dart
├── providers/
│   ├── auth_provider.dart
│   ├── expense_provider.dart
│   ├── loan_provider.dart
│   └── settings_provider.dart
├── screens/
│   ├── auth/
│   ├── home/
│   ├── expenses/
│   ├── loans/
│   ├── friends/
│   └── settings/
├── widgets/
│   └── common/
└── utils/
    ├── formatters.dart
    ├── validators.dart
    └── helpers.dart
```

## Getting Started

### Prerequisites

- Flutter SDK (3.0 or higher)
- Dart SDK
- Android Studio / VS Code
- Android device or emulator

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/ganesh0189/money_tracker.git
   cd money_tracker
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

### Build APK

```bash
flutter build apk --release
```

The APK will be generated at `build/app/outputs/flutter-apk/app-release.apk`

## Key Features

### Auto-Detect Payments
The app can automatically detect payment notifications from popular UPI apps:
- Google Pay
- PhonePe
- Paytm
- Amazon Pay
- WhatsApp Pay

### Merchant Rules
Create rules to automatically categorize expenses based on merchant names:
- Example: "Swiggy" → Food & Dining
- Example: "Amazon" → Shopping

### Data Privacy
- **100% Offline:** All data is stored locally on your device
- **No Cloud:** Your financial data never leaves your device
- **Secure:** Password and PIN protection with SHA-256 hashing

## Default Categories

- Food & Dining
- Transportation
- Shopping
- Entertainment
- Health
- Bills & Utilities
- Home
- Education
- Travel
- Groceries
- Personal Care
- Gifts
- Investment
- Others

## License

This project is licensed under the MIT License.

## Author

**Ganesh Bollem**

- GitHub: [@ganesh0189](https://github.com/ganesh0189)
