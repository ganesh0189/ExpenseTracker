import '../config/constants.dart';

/// Validate username
String? validateUsername(String? value) {
  if (value == null || value.isEmpty) {
    return 'Username is required';
  }

  value = value.trim();

  if (value.length < MIN_USERNAME_LENGTH) {
    return 'Username must be at least $MIN_USERNAME_LENGTH characters';
  }

  if (value.length > MAX_USERNAME_LENGTH) {
    return 'Username must be less than $MAX_USERNAME_LENGTH characters';
  }

  if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
    return 'Username can only contain letters, numbers, and underscores';
  }

  return null;
}

/// Validate password
String? validatePassword(String? value) {
  if (value == null || value.isEmpty) {
    return 'Password is required';
  }

  if (value.length < MIN_PASSWORD_LENGTH) {
    return 'Password must be at least $MIN_PASSWORD_LENGTH characters';
  }

  return null;
}

/// Validate confirm password
String? validateConfirmPassword(String? value, String password) {
  if (value == null || value.isEmpty) {
    return 'Please confirm your password';
  }

  if (value != password) {
    return 'Passwords do not match';
  }

  return null;
}

/// Validate PIN
String? validatePin(String? value) {
  if (value == null || value.isEmpty) {
    return 'PIN is required';
  }

  if (value.length != PIN_LENGTH) {
    return 'PIN must be exactly $PIN_LENGTH digits';
  }

  if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
    return 'PIN must contain only numbers';
  }

  return null;
}

/// Validate optional PIN
String? validateOptionalPin(String? value) {
  if (value == null || value.isEmpty) {
    return null; // PIN is optional
  }

  return validatePin(value);
}

/// Validate required field
String? validateRequired(String? value, [String fieldName = 'This field']) {
  if (value == null || value.trim().isEmpty) {
    return '$fieldName is required';
  }
  return null;
}

/// Validate amount
String? validateAmount(String? value) {
  if (value == null || value.isEmpty) {
    return 'Amount is required';
  }

  // Remove currency symbols and commas
  final cleanValue = value.replaceAll(RegExp(r'[₹,\s]'), '');

  final amount = double.tryParse(cleanValue);
  if (amount == null) {
    return 'Please enter a valid amount';
  }

  if (amount <= 0) {
    return 'Amount must be greater than zero';
  }

  if (amount > 99999999) {
    return 'Amount is too large';
  }

  return null;
}

/// Validate email
String? validateEmail(String? value) {
  if (value == null || value.isEmpty) {
    return null; // Email is often optional
  }

  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
    return 'Please enter a valid email address';
  }

  return null;
}

/// Validate phone number
String? validatePhone(String? value) {
  if (value == null || value.isEmpty) {
    return null; // Phone is often optional
  }

  // Remove spaces and dashes
  final cleanValue = value.replaceAll(RegExp(r'[\s\-()]'), '');

  if (!RegExp(r'^[+]?[0-9]{10,15}$').hasMatch(cleanValue)) {
    return 'Please enter a valid phone number';
  }

  return null;
}

/// Validate name (person or friend name)
String? validateName(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Name is required';
  }

  if (value.trim().length < 2) {
    return 'Name must be at least 2 characters';
  }

  if (value.trim().length > 50) {
    return 'Name must be less than 50 characters';
  }

  return null;
}

/// Validate category name
String? validateCategoryName(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Category name is required';
  }

  if (value.trim().length < 2) {
    return 'Category name must be at least 2 characters';
  }

  if (value.trim().length > 30) {
    return 'Category name must be less than 30 characters';
  }

  return null;
}

/// Validate merchant pattern
String? validatePattern(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Pattern is required';
  }

  if (value.trim().length < 2) {
    return 'Pattern must be at least 2 characters';
  }

  return null;
}

/// Parse amount from string (handles currency symbols and commas)
double parseAmount(String value) {
  final cleanValue = value.replaceAll(RegExp(r'[₹,\s]'), '');
  return double.tryParse(cleanValue) ?? 0.0;
}
