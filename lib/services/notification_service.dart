import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../config/constants.dart';
import '../database/repositories/expense_repository.dart';
import '../database/repositories/monitored_app_repository.dart';
import '../database/repositories/merchant_rule_repository.dart';
import '../database/repositories/category_repository.dart';
import '../models/expense.dart';
import 'notification_parser.dart';

/// Service for handling notification listener and local notifications
class NotificationService {
  static const _methodChannel = MethodChannel('com.moneytracker/notifications');
  static const _eventChannel = EventChannel('com.moneytracker/notification_events');

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  final ExpenseRepository _expenseRepository = ExpenseRepository();
  final MonitoredAppRepository _monitoredAppRepository = MonitoredAppRepository();
  final MerchantRuleRepository _merchantRuleRepository = MerchantRuleRepository();
  final CategoryRepository _categoryRepository = CategoryRepository();

  StreamSubscription? _notificationSubscription;
  int? _currentUserId;

  /// Callback for when an expense is auto-created
  Function(Expense)? onExpenseCreated;

  /// Initialize the notification service
  Future<void> initialize() async {
    // Initialize local notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel
    const androidChannel = AndroidNotificationChannel(
      NOTIFICATION_CHANNEL_ID,
      NOTIFICATION_CHANNEL_NAME,
      description: NOTIFICATION_CHANNEL_DESC,
      importance: Importance.low,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  /// Start listening for notifications (call after user login)
  void startListening(int userId) {
    _currentUserId = userId;
    _notificationSubscription?.cancel();

    _notificationSubscription = _eventChannel
        .receiveBroadcastStream()
        .listen(_handleNotificationEvent);
  }

  /// Stop listening for notifications
  void stopListening() {
    _notificationSubscription?.cancel();
    _notificationSubscription = null;
    _currentUserId = null;
  }

  /// Handle incoming notification event from native code
  Future<void> _handleNotificationEvent(dynamic event) async {
    if (_currentUserId == null) return;

    try {
      final Map<String, dynamic> data = Map<String, dynamic>.from(event);
      final packageName = data['packageName'] as String?;
      final title = data['title'] as String? ?? '';
      final text = data['text'] as String? ?? '';

      if (packageName == null || packageName.isEmpty) return;

      // Check if this app is being monitored
      final isMonitored = await _monitoredAppRepository.isPackageMonitored(
        _currentUserId!,
        packageName,
      );

      if (!isMonitored) return;

      // Parse the notification
      final parsed = NotificationParser.parse(
        packageName: packageName,
        title: title,
        text: text,
      );

      if (parsed == null || !parsed.isValid || !parsed.isDebit) return;

      // Generate notification ID for deduplication
      final notificationId = NotificationParser.generateNotificationId(
        packageName: packageName,
        amount: parsed.amount,
        merchant: parsed.merchant,
        timestamp: DateTime.now(),
      );

      // Check if already processed
      if (await _expenseRepository.notificationIdExists(notificationId)) return;

      // Get category from merchant rules or default to 'Others'
      int? categoryId = await _merchantRuleRepository.matchMerchant(
        _currentUserId!,
        parsed.merchant,
      );

      if (categoryId == null) {
        final othersCategory = await _categoryRepository.getOthersCategory(_currentUserId!);
        categoryId = othersCategory?.id;
      }

      if (categoryId == null) return;

      // Create expense
      final expense = Expense(
        userId: _currentUserId!,
        categoryId: categoryId,
        amount: parsed.amount,
        merchant: parsed.merchant,
        description: 'Auto-detected from ${parsed.source}',
        date: DateTime.now(),
        time: _formatTime(DateTime.now()),
        source: ExpenseSource.AUTO,
        notificationId: notificationId,
      );

      final expenseId = await _expenseRepository.createExpense(expense);

      // Get the created expense with category info
      final createdExpense = await _expenseRepository.getExpenseById(expenseId);
      if (createdExpense != null && onExpenseCreated != null) {
        onExpenseCreated!(createdExpense);
      }

      // Show confirmation notification
      await _showExpenseNotification(parsed.amount, parsed.merchant);
    } catch (e) {
      // Silently handle errors to not disrupt user experience
      print('Error processing notification: $e');
    }
  }

  /// Format time as HH:mm
  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// Show local notification for auto-detected expense
  Future<void> _showExpenseNotification(double amount, String merchant) async {
    const androidDetails = AndroidNotificationDetails(
      NOTIFICATION_CHANNEL_ID,
      NOTIFICATION_CHANNEL_NAME,
      channelDescription: NOTIFICATION_CHANNEL_DESC,
      importance: Importance.low,
      priority: Priority.low,
      icon: '@mipmap/ic_launcher',
    );

    const details = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'Expense Recorded',
      '₹${amount.toStringAsFixed(2)} at $merchant',
      details,
    );
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    // Navigate to expenses screen or show expense detail
    // This will be handled by the app's navigation
  }

  // ============ Permission Management ============

  /// Check if notification listener permission is granted
  Future<bool> isNotificationListenerEnabled() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('isEnabled');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Open system settings to grant notification listener permission
  Future<void> openNotificationListenerSettings() async {
    try {
      await _methodChannel.invokeMethod('openSettings');
    } on PlatformException catch (e) {
      print('Failed to open settings: ${e.message}');
    }
  }

  /// Request notification permission (for Android 13+)
  Future<bool> requestNotificationPermission() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('requestPermission');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  // ============ Installed Apps ============

  /// Get list of installed payment apps
  Future<List<Map<String, String>>> getInstalledPaymentApps() async {
    try {
      final result = await _methodChannel.invokeMethod<List>('getInstalledApps');
      if (result == null) return [];

      return result.map((app) {
        final map = Map<String, dynamic>.from(app);
        return {
          'packageName': map['packageName'] as String,
          'appName': map['appName'] as String,
        };
      }).toList();
    } on PlatformException {
      // Return default list if native call fails
      return PAYMENT_APPS.entries
          .map((e) => {'packageName': e.key, 'appName': e.value})
          .toList();
    }
  }

  /// Check if a specific app is installed
  Future<bool> isAppInstalled(String packageName) async {
    try {
      final result = await _methodChannel.invokeMethod<bool>(
        'isAppInstalled',
        {'packageName': packageName},
      );
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Dispose resources
  void dispose() {
    stopListening();
  }
}

/// Singleton instance
final notificationService = NotificationService();
