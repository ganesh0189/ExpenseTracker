/// App-wide constants for Money Tracker

// App Information
const String APP_NAME = 'Money Tracker';
const String APP_VERSION = '1.0.0';

// Database
const String DATABASE_NAME = 'money_tracker.db';
const int DATABASE_VERSION = 1;

// Currency
const String DEFAULT_CURRENCY_SYMBOL = '₹';
const String DEFAULT_CURRENCY_CODE = 'INR';

// Validation
const int MIN_USERNAME_LENGTH = 4;
const int MAX_USERNAME_LENGTH = 20;
const int MIN_PASSWORD_LENGTH = 6;
const int PIN_LENGTH = 4;

// Session Keys (SharedPreferences)
const String KEY_IS_LOGGED_IN = 'is_logged_in';
const String KEY_USER_ID = 'user_id';
const String KEY_USERNAME = 'username';
const String KEY_REMEMBER_ME = 'remember_me';
const String KEY_THEME_MODE = 'theme_mode';
const String KEY_AUTO_DETECT_ENABLED = 'auto_detect_enabled';
const String KEY_MONTHLY_BUDGET = 'monthly_budget';
const double DEFAULT_MONTHLY_BUDGET = 50000.0;

// Notification Channel IDs
const String NOTIFICATION_CHANNEL_ID = 'money_tracker_notifications';
const String NOTIFICATION_CHANNEL_NAME = 'Money Tracker';
const String NOTIFICATION_CHANNEL_DESC = 'Notifications for auto-detected payments';

// Supported Payment App Package Names
const Map<String, String> PAYMENT_APPS = {
  'com.google.android.apps.nbu.paisa.user': 'Google Pay',
  'com.phonepe.app': 'PhonePe',
  'net.one97.paytm': 'Paytm',
  'in.amazon.mShop.android.shopping': 'Amazon Pay',
  'com.whatsapp': 'WhatsApp Pay',
};

// Regex Patterns for Notification Parsing
class NotificationPatterns {
  // GPay patterns
  static final RegExp gpayPaid = RegExp(
    r'Paid ₹([\d,]+(?:\.\d{2})?) to (.+)',
    caseSensitive: false,
  );
  static final RegExp gpayReceived = RegExp(
    r'Received ₹([\d,]+(?:\.\d{2})?) from (.+)',
    caseSensitive: false,
  );

  // PhonePe patterns
  static final RegExp phonepePaid = RegExp(
    r'₹([\d,]+(?:\.\d{2})?) paid to (.+)',
    caseSensitive: false,
  );
  static final RegExp phonepeReceived = RegExp(
    r'₹([\d,]+(?:\.\d{2})?) received from (.+)',
    caseSensitive: false,
  );

  // Bank SMS patterns
  static final RegExp bankDebited = RegExp(
    r'(?:INR|Rs\.?)\s?([\d,]+(?:\.\d{2})?)\s*(?:debited|deducted)',
    caseSensitive: false,
  );
  static final RegExp bankCredited = RegExp(
    r'(?:INR|Rs\.?)\s?([\d,]+(?:\.\d{2})?)\s*credited',
    caseSensitive: false,
  );
  static final RegExp bankWithdrawn = RegExp(
    r'(?:INR|Rs\.?)\s?([\d,]+(?:\.\d{2})?)\s*withdrawn at (.+)',
    caseSensitive: false,
  );

  // Generic UPI pattern
  static final RegExp upiPayment = RegExp(
    r'(?:sent|paid|transferred)\s*₹?([\d,]+(?:\.\d{2})?)',
    caseSensitive: false,
  );
}

// Default Categories with icons and colors
class DefaultCategory {
  final String name;
  final String icon;
  final int color;

  const DefaultCategory({
    required this.name,
    required this.icon,
    required this.color,
  });
}

const List<DefaultCategory> DEFAULT_CATEGORIES = [
  DefaultCategory(name: 'Food & Dining', icon: 'restaurant', color: 0xFFFF6B6B),
  DefaultCategory(name: 'Transportation', icon: 'directions_car', color: 0xFF4ECDC4),
  DefaultCategory(name: 'Shopping', icon: 'shopping_cart', color: 0xFF45B7D1),
  DefaultCategory(name: 'Entertainment', icon: 'movie', color: 0xFF96CEB4),
  DefaultCategory(name: 'Health', icon: 'local_hospital', color: 0xFFFFEAA7),
  DefaultCategory(name: 'Bills & Utilities', icon: 'receipt', color: 0xFFDDA0DD),
  DefaultCategory(name: 'Home', icon: 'home', color: 0xFF98D8C8),
  DefaultCategory(name: 'Education', icon: 'school', color: 0xFFF7DC6F),
  DefaultCategory(name: 'Travel', icon: 'flight', color: 0xFFBB8FCE),
  DefaultCategory(name: 'Groceries', icon: 'local_grocery_store', color: 0xFF82E0AA),
  DefaultCategory(name: 'Personal Care', icon: 'spa', color: 0xFFF8B500),
  DefaultCategory(name: 'Gifts', icon: 'card_giftcard', color: 0xFFFF69B4),
  DefaultCategory(name: 'Investment', icon: 'trending_up', color: 0xFF00CED1),
  DefaultCategory(name: 'Others', icon: 'category', color: 0xFF95A5A6),
];

// Loan Types
class LoanType {
  static const String LENT = 'LENT';
  static const String BORROWED = 'BORROWED';
}

// Expense Sources
class ExpenseSource {
  static const String MANUAL = 'MANUAL';
  static const String AUTO = 'AUTO';
}

// Default Merchant Rules
const Map<String, String> DEFAULT_MERCHANT_RULES = {
  'swiggy': 'Food & Dining',
  'zomato': 'Food & Dining',
  'uber eats': 'Food & Dining',
  'dominos': 'Food & Dining',
  'mcdonald': 'Food & Dining',
  'kfc': 'Food & Dining',
  'starbucks': 'Food & Dining',
  'amazon': 'Shopping',
  'flipkart': 'Shopping',
  'myntra': 'Shopping',
  'ajio': 'Shopping',
  'uber': 'Transportation',
  'ola': 'Transportation',
  'rapido': 'Transportation',
  'irctc': 'Travel',
  'makemytrip': 'Travel',
  'goibibo': 'Travel',
  'netflix': 'Entertainment',
  'hotstar': 'Entertainment',
  'spotify': 'Entertainment',
  'prime video': 'Entertainment',
  'youtube': 'Entertainment',
  'jio': 'Bills & Utilities',
  'airtel': 'Bills & Utilities',
  'vodafone': 'Bills & Utilities',
  'electricity': 'Bills & Utilities',
  'water bill': 'Bills & Utilities',
  'gas bill': 'Bills & Utilities',
  'apollo': 'Health',
  'pharmacy': 'Health',
  'medplus': 'Health',
  'bigbasket': 'Groceries',
  'grofers': 'Groceries',
  'blinkit': 'Groceries',
  'zepto': 'Groceries',
  'dmart': 'Groceries',
};
