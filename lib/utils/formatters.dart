import 'package:intl/intl.dart';
import 'helpers.dart';

/// Format currency with symbol
String formatCurrency(double amount, {String symbol = '₹', bool showDecimals = true}) {
  final formatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: symbol,
    decimalDigits: showDecimals ? 2 : 0,
  );
  return formatter.format(amount);
}

/// Format currency compact (e.g., 1.2K, 1.5M)
String formatCurrencyCompact(double amount, {String symbol = '₹'}) {
  if (amount >= 10000000) {
    return '$symbol${(amount / 10000000).toStringAsFixed(1)}Cr';
  } else if (amount >= 100000) {
    return '$symbol${(amount / 100000).toStringAsFixed(1)}L';
  } else if (amount >= 1000) {
    return '$symbol${(amount / 1000).toStringAsFixed(1)}K';
  }
  return '$symbol${amount.toStringAsFixed(0)}';
}

/// Format number with commas
String formatNumber(double number, {int decimals = 0}) {
  final formatter = NumberFormat('#,##,###', 'en_IN');
  if (decimals > 0) {
    return '${formatter.format(number.floor())}.${number.toStringAsFixed(decimals).split('.')[1]}';
  }
  return formatter.format(number);
}

/// Format date (e.g., "28 Nov 2025")
String formatDate(DateTime date) {
  return DateFormat('d MMM yyyy').format(date);
}

/// Format date short (e.g., "28 Nov")
String formatDateShort(DateTime date) {
  return DateFormat('d MMM').format(date);
}

/// Format date with day (e.g., "Thu, 28 Nov")
String formatDateWithDay(DateTime date) {
  return DateFormat('E, d MMM').format(date);
}

/// Format date full (e.g., "Thursday, 28 November 2025")
String formatDateFull(DateTime date) {
  return DateFormat('EEEE, d MMMM yyyy').format(date);
}

/// Format time (e.g., "3:45 PM")
String formatTime(DateTime date) {
  return DateFormat('h:mm a').format(date);
}

/// Format time from string (HH:mm -> 3:45 PM)
String formatTimeString(String? time) {
  if (time == null || time.isEmpty) return '';
  final parts = time.split(':');
  if (parts.length < 2) return time;

  final hour = int.tryParse(parts[0]) ?? 0;
  final minute = int.tryParse(parts[1]) ?? 0;
  final date = DateTime(2000, 1, 1, hour, minute);
  return formatTime(date);
}

/// Format datetime (e.g., "28 Nov 2025, 3:45 PM")
String formatDateTime(DateTime date) {
  return DateFormat('d MMM yyyy, h:mm a').format(date);
}

/// Format relative date (Today, Yesterday, or date)
String formatRelativeDate(DateTime date) {
  if (isToday(date)) {
    return 'Today';
  } else if (isYesterday(date)) {
    return 'Yesterday';
  } else if (isThisWeek(date)) {
    return DateFormat('EEEE').format(date); // Day name
  } else if (isThisMonth(date)) {
    return DateFormat('d MMM').format(date);
  } else {
    return formatDate(date);
  }
}

/// Format relative date with time
String formatRelativeDateWithTime(DateTime date) {
  final datePart = formatRelativeDate(date);
  final timePart = formatTime(date);
  if (datePart == 'Today' || datePart == 'Yesterday') {
    return '$datePart at $timePart';
  }
  return '$datePart, $timePart';
}

/// Format month year (e.g., "November 2025")
String formatMonthYear(int month, int year) {
  return DateFormat('MMMM yyyy').format(DateTime(year, month));
}

/// Format month year short (e.g., "Nov 2025")
String formatMonthYearShort(int month, int year) {
  return DateFormat('MMM yyyy').format(DateTime(year, month));
}

/// Format duration (e.g., "2 days", "3 weeks")
String formatDuration(int days) {
  if (days == 0) return 'Today';
  if (days == 1) return '1 day';
  if (days < 7) return '$days days';
  if (days < 14) return '1 week';
  if (days < 30) return '${(days / 7).floor()} weeks';
  if (days < 60) return '1 month';
  if (days < 365) return '${(days / 30).floor()} months';
  if (days < 730) return '1 year';
  return '${(days / 365).floor()} years';
}

/// Format due status
String formatDueStatus(DateTime? dueDate) {
  if (dueDate == null) return 'No due date';

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
  final diff = due.difference(today).inDays;

  if (diff < 0) {
    return '${-diff} ${-diff == 1 ? 'day' : 'days'} overdue';
  } else if (diff == 0) {
    return 'Due today';
  } else if (diff == 1) {
    return 'Due tomorrow';
  } else if (diff <= 7) {
    return 'Due in $diff days';
  } else {
    return 'Due ${formatDateShort(dueDate)}';
  }
}

/// Format percentage
String formatPercentage(double value, {int decimals = 0}) {
  return '${value.toStringAsFixed(decimals)}%';
}

/// Format file size
String formatFileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
}
