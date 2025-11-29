import 'package:flutter/material.dart';

// Screen imports
import '../screens/splash/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/pin_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/loans/loans_screen.dart';
import '../screens/loans/add_loan_screen.dart';
import '../screens/loans/loan_detail_screen.dart';
import '../screens/expenses/expenses_screen.dart';
import '../screens/expenses/add_expense_screen.dart';
import '../screens/expenses/expense_detail_screen.dart';
import '../screens/friends/friends_screen.dart';
import '../screens/friends/add_friend_screen.dart';
import '../screens/friends/friend_detail_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/settings/categories_screen.dart';
import '../screens/settings/monitored_apps_screen.dart';
import '../screens/settings/merchant_rules_screen.dart';
import '../screens/settings/export_screen.dart';

/// Named routes for the app
class Routes {
  // Auth routes
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String pinLogin = '/pin';

  // Main routes
  static const String dashboard = '/dashboard';
  static const String home = '/home';

  // Loan routes
  static const String loans = '/loans';
  static const String addLoan = '/loans/add';
  static const String loanDetail = '/loans/detail';
  static const String editLoan = '/loans/edit';

  // Expense routes
  static const String expenses = '/expenses';
  static const String addExpense = '/expenses/add';
  static const String expenseDetail = '/expenses/detail';
  static const String editExpense = '/expenses/edit';

  // Friend routes
  static const String friends = '/friends';
  static const String addFriend = '/friends/add';
  static const String friendDetail = '/friends/detail';
  static const String editFriend = '/friends/edit';

  // Settings routes
  static const String settings = '/settings';
  static const String categories = '/settings/categories';
  static const String monitoredApps = '/settings/monitored-apps';
  static const String merchantRules = '/settings/merchant-rules';
  static const String exportData = '/settings/export';
  static const String changePassword = '/settings/change-password';
  static const String changePin = '/settings/change-pin';
}

/// Route generator function
Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    // Auth routes
    case Routes.splash:
      return _buildRoute(const SplashScreen(), settings);

    case Routes.login:
      return _buildRoute(const LoginScreen(), settings);

    case Routes.register:
      return _buildRoute(const RegisterScreen(), settings);

    case Routes.pinLogin:
      return _buildRoute(const PinScreen(), settings);

    // Main routes
    case Routes.dashboard:
    case Routes.home:
      return _buildRoute(const HomeScreen(), settings);

    // Loan routes
    case Routes.loans:
      return _buildRoute(const LoansScreen(), settings);

    case Routes.addLoan:
      final friendId = settings.arguments as int?;
      return _buildRoute(AddLoanScreen(preselectedFriendId: friendId), settings);

    case Routes.loanDetail:
      final loanId = settings.arguments as int;
      return _buildRoute(LoanDetailScreen(loanId: loanId), settings);

    case Routes.editLoan:
      final loanId = settings.arguments as int;
      return _buildRoute(AddLoanScreen(editLoanId: loanId), settings);

    // Expense routes
    case Routes.expenses:
      return _buildRoute(const ExpensesScreen(), settings);

    case Routes.addExpense:
      return _buildRoute(const AddExpenseScreen(), settings);

    case Routes.expenseDetail:
      final expenseId = settings.arguments as int;
      return _buildRoute(ExpenseDetailScreen(expenseId: expenseId), settings);

    case Routes.editExpense:
      final expenseId = settings.arguments as int;
      return _buildRoute(AddExpenseScreen(editExpenseId: expenseId), settings);

    // Friend routes
    case Routes.friends:
      return _buildRoute(const FriendsScreen(), settings);

    case Routes.addFriend:
      return _buildRoute(const AddFriendScreen(), settings);

    case Routes.friendDetail:
      final friendId = settings.arguments as int;
      return _buildRoute(FriendDetailScreen(friendId: friendId), settings);

    case Routes.editFriend:
      final friendId = settings.arguments as int;
      return _buildRoute(AddFriendScreen(editFriendId: friendId), settings);

    // Settings routes
    case Routes.settings:
      return _buildRoute(const SettingsScreen(), settings);

    case Routes.categories:
      return _buildRoute(const CategoriesScreen(), settings);

    case Routes.monitoredApps:
      return _buildRoute(const MonitoredAppsScreen(), settings);

    case Routes.merchantRules:
      return _buildRoute(const MerchantRulesScreen(), settings);

    case Routes.exportData:
      return _buildRoute(const ExportScreen(), settings);

    // Default - 404 page
    default:
      return _buildRoute(
        Scaffold(
          appBar: AppBar(title: const Text('Not Found')),
          body: Center(
            child: Text('Route ${settings.name} not found'),
          ),
        ),
        settings,
      );
  }
}

/// Helper to build MaterialPageRoute with slide transition
MaterialPageRoute<dynamic> _buildRoute(Widget page, RouteSettings settings) {
  return MaterialPageRoute(
    builder: (_) => page,
    settings: settings,
  );
}

/// Custom slide transition (optional, for fancier navigation)
class SlideRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  SlideRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;

            var tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        );
}
