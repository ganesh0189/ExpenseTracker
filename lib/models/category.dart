import 'package:flutter/material.dart';

/// Category model for expense categorization
class Category {
  final int? id;
  final int userId;
  final String name;
  final String icon; // Material icon name
  final int color; // Color value as int (e.g., 0xFFFF4757)
  final bool isDefault;
  final bool isHidden;
  final int sortOrder;
  final DateTime createdAt;

  Category({
    this.id,
    required this.userId,
    required this.name,
    required this.icon,
    required this.color,
    this.isDefault = false,
    this.isHidden = false,
    this.sortOrder = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Create Category from database map
  factory Category.fromMap(Map<String, dynamic> map) {
    // Handle color - can be stored as int or String in database
    int colorValue;
    final rawColor = map['color'];
    if (rawColor is int) {
      colorValue = rawColor;
    } else if (rawColor is String) {
      // Parse hex string like "0xFFFF6B6B" or "4294923947"
      colorValue = int.tryParse(rawColor.replaceFirst('0x', ''), radix: 16) ??
          int.tryParse(rawColor) ??
          0xFF95A5A6; // Default gray
    } else {
      colorValue = 0xFF95A5A6; // Default gray
    }

    return Category(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      name: map['name'] as String,
      icon: map['icon'] as String,
      color: colorValue,
      isDefault: (map['is_default'] as int?) == 1,
      isHidden: (map['is_hidden'] as int?) == 1,
      sortOrder: map['sort_order'] as int? ?? 0,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
    );
  }

  /// Convert Category to database map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'name': name,
      'icon': icon,
      'color': color,
      'is_default': isDefault ? 1 : 0,
      'is_hidden': isHidden ? 1 : 0,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  Category copyWith({
    int? id,
    int? userId,
    String? name,
    String? icon,
    int? color,
    bool? isDefault,
    bool? isHidden,
    int? sortOrder,
    DateTime? createdAt,
  }) {
    return Category(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isDefault: isDefault ?? this.isDefault,
      isHidden: isHidden ?? this.isHidden,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Get Color object
  Color get colorValue => Color(color);

  /// Get IconData from icon name
  IconData get iconData {
    return _iconMap[icon] ?? Icons.category;
  }

  /// Map of icon names to IconData
  static final Map<String, IconData> _iconMap = {
    'restaurant': Icons.restaurant,
    'directions_car': Icons.directions_car,
    'shopping_cart': Icons.shopping_cart,
    'movie': Icons.movie,
    'local_hospital': Icons.local_hospital,
    'receipt': Icons.receipt,
    'home': Icons.home,
    'school': Icons.school,
    'flight': Icons.flight,
    'local_grocery_store': Icons.local_grocery_store,
    'spa': Icons.spa,
    'card_giftcard': Icons.card_giftcard,
    'trending_up': Icons.trending_up,
    'category': Icons.category,
    'work': Icons.work,
    'fitness_center': Icons.fitness_center,
    'pets': Icons.pets,
    'child_care': Icons.child_care,
    'local_cafe': Icons.local_cafe,
    'sports_esports': Icons.sports_esports,
    'music_note': Icons.music_note,
    'book': Icons.book,
    'build': Icons.build,
    'attach_money': Icons.attach_money,
    'account_balance': Icons.account_balance,
    'wifi': Icons.wifi,
    'phone_android': Icons.phone_android,
    'local_gas_station': Icons.local_gas_station,
    'local_parking': Icons.local_parking,
    'local_taxi': Icons.local_taxi,
  };

  /// Get all available icons for category selection
  static List<String> get availableIcons => _iconMap.keys.toList();

  @override
  String toString() {
    return 'Category(id: $id, name: $name, icon: $icon)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Category && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
