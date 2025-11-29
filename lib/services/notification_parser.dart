/// Service for parsing payment notifications from various apps
class NotificationParser {
  /// Parse notification and extract payment details
  /// Returns null if notification is not a recognized payment notification
  static ParsedNotification? parse({
    required String packageName,
    required String title,
    required String text,
  }) {
    // Combine title and text for better pattern matching
    final fullText = '$title $text';

    // Try different parsing strategies based on package
    ParsedNotification? result;

    // Google Pay
    if (packageName.contains('google') && packageName.contains('paisa')) {
      result = _parseGooglePay(fullText);
    }
    // PhonePe
    else if (packageName.contains('phonepe')) {
      result = _parsePhonePe(fullText);
    }
    // Paytm
    else if (packageName.contains('paytm')) {
      result = _parsePaytm(fullText);
    }
    // Amazon Pay
    else if (packageName.contains('amazon')) {
      result = _parseAmazonPay(fullText);
    }
    // WhatsApp Pay
    else if (packageName.contains('whatsapp')) {
      result = _parseWhatsAppPay(fullText);
    }
    // Generic bank SMS
    else {
      result = _parseBankSMS(fullText);
    }

    // If no specific parser matched, try generic UPI patterns
    result ??= _parseGenericUPI(fullText);

    return result;
  }

  /// Parse Google Pay notifications
  static ParsedNotification? _parseGooglePay(String text) {
    // Pattern: "Paid ₹500 to Merchant Name"
    final paidPattern = RegExp(
      r'[Pp]aid\s*₹?\s*([\d,]+(?:\.\d{1,2})?)\s*to\s+(.+)',
    );

    // Pattern: "Received ₹500 from Person Name"
    final receivedPattern = RegExp(
      r'[Rr]eceived\s*₹?\s*([\d,]+(?:\.\d{1,2})?)\s*from\s+(.+)',
    );

    // Pattern: "Sent ₹500 to Merchant"
    final sentPattern = RegExp(
      r'[Ss]ent\s*₹?\s*([\d,]+(?:\.\d{1,2})?)\s*to\s+(.+)',
    );

    var match = paidPattern.firstMatch(text);
    if (match != null) {
      return ParsedNotification(
        amount: _parseAmount(match.group(1)!),
        merchant: _cleanMerchantName(match.group(2)!),
        type: TransactionType.debit,
        source: 'Google Pay',
      );
    }

    match = sentPattern.firstMatch(text);
    if (match != null) {
      return ParsedNotification(
        amount: _parseAmount(match.group(1)!),
        merchant: _cleanMerchantName(match.group(2)!),
        type: TransactionType.debit,
        source: 'Google Pay',
      );
    }

    match = receivedPattern.firstMatch(text);
    if (match != null) {
      return ParsedNotification(
        amount: _parseAmount(match.group(1)!),
        merchant: _cleanMerchantName(match.group(2)!),
        type: TransactionType.credit,
        source: 'Google Pay',
      );
    }

    return null;
  }

  /// Parse PhonePe notifications
  static ParsedNotification? _parsePhonePe(String text) {
    // Pattern: "₹500 paid to Merchant"
    final paidPattern = RegExp(
      r'₹?\s*([\d,]+(?:\.\d{1,2})?)\s*(?:paid|sent)\s*to\s+(.+)',
      caseSensitive: false,
    );

    // Pattern: "₹500 received from Person"
    final receivedPattern = RegExp(
      r'₹?\s*([\d,]+(?:\.\d{1,2})?)\s*received\s*from\s+(.+)',
      caseSensitive: false,
    );

    // Pattern: "Payment of ₹500 to Merchant successful"
    final paymentPattern = RegExp(
      r'[Pp]ayment\s*(?:of\s*)?₹?\s*([\d,]+(?:\.\d{1,2})?)\s*to\s+(.+?)(?:\s+successful|\s+completed)?',
    );

    var match = paidPattern.firstMatch(text);
    if (match != null) {
      return ParsedNotification(
        amount: _parseAmount(match.group(1)!),
        merchant: _cleanMerchantName(match.group(2)!),
        type: TransactionType.debit,
        source: 'PhonePe',
      );
    }

    match = receivedPattern.firstMatch(text);
    if (match != null) {
      return ParsedNotification(
        amount: _parseAmount(match.group(1)!),
        merchant: _cleanMerchantName(match.group(2)!),
        type: TransactionType.credit,
        source: 'PhonePe',
      );
    }

    match = paymentPattern.firstMatch(text);
    if (match != null) {
      return ParsedNotification(
        amount: _parseAmount(match.group(1)!),
        merchant: _cleanMerchantName(match.group(2)!),
        type: TransactionType.debit,
        source: 'PhonePe',
      );
    }

    return null;
  }

  /// Parse Paytm notifications
  static ParsedNotification? _parsePaytm(String text) {
    // Pattern: "Paid ₹500 to Merchant"
    final paidPattern = RegExp(
      r'[Pp]aid\s*₹?\s*([\d,]+(?:\.\d{1,2})?)\s*to\s+(.+)',
    );

    // Pattern: "₹500 received"
    final receivedPattern = RegExp(
      r'₹?\s*([\d,]+(?:\.\d{1,2})?)\s*received\s*(?:from\s+(.+))?',
      caseSensitive: false,
    );

    // Pattern: "Money sent ₹500"
    final sentPattern = RegExp(
      r'[Mm]oney\s*sent\s*₹?\s*([\d,]+(?:\.\d{1,2})?)\s*(?:to\s+(.+))?',
    );

    var match = paidPattern.firstMatch(text);
    if (match != null) {
      return ParsedNotification(
        amount: _parseAmount(match.group(1)!),
        merchant: _cleanMerchantName(match.group(2)!),
        type: TransactionType.debit,
        source: 'Paytm',
      );
    }

    match = sentPattern.firstMatch(text);
    if (match != null) {
      return ParsedNotification(
        amount: _parseAmount(match.group(1)!),
        merchant: match.group(2) != null ? _cleanMerchantName(match.group(2)!) : 'Unknown',
        type: TransactionType.debit,
        source: 'Paytm',
      );
    }

    match = receivedPattern.firstMatch(text);
    if (match != null) {
      return ParsedNotification(
        amount: _parseAmount(match.group(1)!),
        merchant: match.group(2) != null ? _cleanMerchantName(match.group(2)!) : 'Unknown',
        type: TransactionType.credit,
        source: 'Paytm',
      );
    }

    return null;
  }

  /// Parse Amazon Pay notifications
  static ParsedNotification? _parseAmazonPay(String text) {
    final paidPattern = RegExp(
      r'₹?\s*([\d,]+(?:\.\d{1,2})?)\s*(?:paid|sent|debited)\s*(?:to|for)?\s*(.+)?',
      caseSensitive: false,
    );

    final match = paidPattern.firstMatch(text);
    if (match != null) {
      return ParsedNotification(
        amount: _parseAmount(match.group(1)!),
        merchant: match.group(2) != null ? _cleanMerchantName(match.group(2)!) : 'Amazon',
        type: TransactionType.debit,
        source: 'Amazon Pay',
      );
    }

    return null;
  }

  /// Parse WhatsApp Pay notifications
  static ParsedNotification? _parseWhatsAppPay(String text) {
    // Only process if it looks like a payment notification
    if (!text.toLowerCase().contains('payment') &&
        !text.toLowerCase().contains('paid') &&
        !text.toLowerCase().contains('sent') &&
        !text.contains('₹')) {
      return null;
    }

    final paidPattern = RegExp(
      r'₹?\s*([\d,]+(?:\.\d{1,2})?)\s*(?:paid|sent)\s*to\s+(.+)',
      caseSensitive: false,
    );

    final match = paidPattern.firstMatch(text);
    if (match != null) {
      return ParsedNotification(
        amount: _parseAmount(match.group(1)!),
        merchant: _cleanMerchantName(match.group(2)!),
        type: TransactionType.debit,
        source: 'WhatsApp Pay',
      );
    }

    return null;
  }

  /// Parse bank SMS notifications
  static ParsedNotification? _parseBankSMS(String text) {
    // Pattern: "INR 500.00 debited from A/c"
    final debitPattern = RegExp(
      r'(?:INR|Rs\.?|₹)\s*([\d,]+(?:\.\d{1,2})?)\s*(?:debited|deducted|withdrawn|spent)',
      caseSensitive: false,
    );

    // Pattern: "INR 500.00 credited to A/c"
    final creditPattern = RegExp(
      r'(?:INR|Rs\.?|₹)\s*([\d,]+(?:\.\d{1,2})?)\s*credited',
      caseSensitive: false,
    );

    // Pattern: "Spent Rs 500 at Merchant"
    final spentAtPattern = RegExp(
      r'[Ss]pent\s*(?:INR|Rs\.?|₹)?\s*([\d,]+(?:\.\d{1,2})?)\s*(?:at|on)\s+(.+)',
    );

    // Pattern: "Transaction of Rs 500 at Merchant"
    final txnAtPattern = RegExp(
      r'[Tt](?:xn|ransaction)\s*(?:of\s*)?(?:INR|Rs\.?|₹)?\s*([\d,]+(?:\.\d{1,2})?)\s*(?:at|to)\s+(.+)',
    );

    var match = spentAtPattern.firstMatch(text);
    if (match != null) {
      return ParsedNotification(
        amount: _parseAmount(match.group(1)!),
        merchant: _cleanMerchantName(match.group(2)!),
        type: TransactionType.debit,
        source: 'Bank',
      );
    }

    match = txnAtPattern.firstMatch(text);
    if (match != null) {
      return ParsedNotification(
        amount: _parseAmount(match.group(1)!),
        merchant: _cleanMerchantName(match.group(2)!),
        type: TransactionType.debit,
        source: 'Bank',
      );
    }

    match = debitPattern.firstMatch(text);
    if (match != null) {
      // Try to extract merchant from text
      String merchant = _extractMerchantFromBankSMS(text);
      return ParsedNotification(
        amount: _parseAmount(match.group(1)!),
        merchant: merchant,
        type: TransactionType.debit,
        source: 'Bank',
      );
    }

    match = creditPattern.firstMatch(text);
    if (match != null) {
      return ParsedNotification(
        amount: _parseAmount(match.group(1)!),
        merchant: 'Bank Credit',
        type: TransactionType.credit,
        source: 'Bank',
      );
    }

    return null;
  }

  /// Parse generic UPI notifications
  static ParsedNotification? _parseGenericUPI(String text) {
    // Generic pattern for UPI payments
    final upiPattern = RegExp(
      r'(?:UPI|upi)\s*(?:payment|txn)?\s*(?:of\s*)?₹?\s*([\d,]+(?:\.\d{1,2})?)\s*(?:to|at)\s+(.+)',
      caseSensitive: false,
    );

    final match = upiPattern.firstMatch(text);
    if (match != null) {
      return ParsedNotification(
        amount: _parseAmount(match.group(1)!),
        merchant: _cleanMerchantName(match.group(2)!),
        type: TransactionType.debit,
        source: 'UPI',
      );
    }

    return null;
  }

  /// Extract merchant name from bank SMS
  static String _extractMerchantFromBankSMS(String text) {
    // Try to find merchant after "at" or "to"
    final atPattern = RegExp(r'(?:at|to|for)\s+([A-Za-z0-9\s]+?)(?:\.|,|$|\s+on|\s+dated)', caseSensitive: false);
    final match = atPattern.firstMatch(text);
    if (match != null) {
      return _cleanMerchantName(match.group(1)!);
    }
    return 'Unknown';
  }

  /// Parse amount string to double
  static double _parseAmount(String amountStr) {
    // Remove commas and currency symbols
    final cleaned = amountStr.replaceAll(',', '').replaceAll('₹', '').trim();
    return double.tryParse(cleaned) ?? 0.0;
  }

  /// Clean merchant name
  static String _cleanMerchantName(String name) {
    // Remove extra whitespace
    var cleaned = name.trim().replaceAll(RegExp(r'\s+'), ' ');

    // Remove common suffixes
    cleaned = cleaned
        .replaceAll(RegExp(r'\s*(?:successful|completed|done|via\s+\w+).*$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s*UPI.*$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s*Ref\s*(?:No)?\.?.*$', caseSensitive: false), '')
        .trim();

    // Capitalize first letter of each word
    if (cleaned.isNotEmpty) {
      cleaned = cleaned.split(' ').map((word) {
        if (word.isEmpty) return word;
        return word[0].toUpperCase() + word.substring(1).toLowerCase();
      }).join(' ');
    }

    return cleaned.isEmpty ? 'Unknown' : cleaned;
  }

  /// Generate a unique notification ID for deduplication
  static String generateNotificationId({
    required String packageName,
    required double amount,
    required String merchant,
    required DateTime timestamp,
  }) {
    final data = '$packageName|$amount|$merchant|${timestamp.millisecondsSinceEpoch ~/ 60000}';
    return data.hashCode.toString();
  }
}

/// Parsed notification data
class ParsedNotification {
  final double amount;
  final String merchant;
  final TransactionType type;
  final String source;

  ParsedNotification({
    required this.amount,
    required this.merchant,
    required this.type,
    required this.source,
  });

  /// Check if this is a valid payment (amount > 0)
  bool get isValid => amount > 0;

  /// Check if this is a debit (expense)
  bool get isDebit => type == TransactionType.debit;

  /// Check if this is a credit (income)
  bool get isCredit => type == TransactionType.credit;

  @override
  String toString() {
    return 'ParsedNotification(amount: $amount, merchant: $merchant, type: $type, source: $source)';
  }
}

/// Transaction type
enum TransactionType {
  debit,  // Money going out (expense)
  credit, // Money coming in (income)
}
