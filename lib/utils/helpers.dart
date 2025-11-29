import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';

/// Hash password using SHA-256
String hashPassword(String password) {
  final bytes = utf8.encode(password);
  final digest = sha256.convert(bytes);
  return digest.toString();
}

/// Generate unique ID
String generateUuid() {
  return const Uuid().v4();
}

/// Get month name from month number (1-12)
String getMonthName(int month, {bool short = false}) {
  const months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  const shortMonths = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  if (month < 1 || month > 12) return '';
  return short ? shortMonths[month - 1] : months[month - 1];
}

/// Get greeting based on time of day
String getGreeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) {
    return 'Good Morning';
  } else if (hour < 17) {
    return 'Good Afternoon';
  } else {
    return 'Good Evening';
  }
}

/// Get first name from full name
String getFirstName(String fullName) {
  final parts = fullName.trim().split(' ');
  return parts.isNotEmpty ? parts[0] : fullName;
}

/// Get initials from name
String getInitials(String name) {
  final parts = name.trim().split(' ');
  if (parts.length >= 2) {
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
    return parts[0][0].toUpperCase();
  }
  return '?';
}

/// Calculate percentage
double calculatePercentage(double value, double total) {
  if (total == 0) return 0;
  return (value / total) * 100;
}

/// Clamp percentage between 0 and 100
double clampPercentage(double percentage) {
  if (percentage < 0) return 0;
  if (percentage > 100) return 100;
  return percentage;
}

/// Get days in month
int getDaysInMonth(int year, int month) {
  return DateTime(year, month + 1, 0).day;
}

/// Check if date is today
bool isToday(DateTime date) {
  final now = DateTime.now();
  return date.year == now.year && date.month == now.month && date.day == now.day;
}

/// Check if date is yesterday
bool isYesterday(DateTime date) {
  final yesterday = DateTime.now().subtract(const Duration(days: 1));
  return date.year == yesterday.year &&
         date.month == yesterday.month &&
         date.day == yesterday.day;
}

/// Check if date is this week
bool isThisWeek(DateTime date) {
  final now = DateTime.now();
  final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
  final endOfWeek = startOfWeek.add(const Duration(days: 6));
  return date.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
         date.isBefore(endOfWeek.add(const Duration(days: 1)));
}

/// Check if date is this month
bool isThisMonth(DateTime date) {
  final now = DateTime.now();
  return date.year == now.year && date.month == now.month;
}

/// Get color from hex string
int hexToInt(String hex) {
  hex = hex.replaceFirst('#', '');
  if (hex.length == 6) {
    hex = 'FF$hex';
  }
  return int.parse(hex, radix: 16);
}

/// Delay helper for animations
Future<void> delay([int milliseconds = 300]) async {
  await Future.delayed(Duration(milliseconds: milliseconds));
}
