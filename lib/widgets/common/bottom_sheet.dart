import 'package:flutter/material.dart';
import '../../config/themes.dart';

/// Modern bottom sheet container
class CustomBottomSheet extends StatelessWidget {
  final Widget child;
  final String? title;
  final bool showHandle;
  final EdgeInsetsGeometry? padding;

  const CustomBottomSheet({
    super.key,
    required this.child,
    this.title,
    this.showHandle = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showHandle) ...[
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.glassBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
          if (title != null) ...[
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                title!,
                style: const TextStyle(
                  color: AppColors.textLight,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Divider(height: 1, color: AppColors.glassBorder),
          ],
          Padding(
            padding: padding ?? const EdgeInsets.all(20),
            child: child,
          ),
        ],
      ),
    );
  }

  /// Show the bottom sheet
  static Future<T?> show<T>(
    BuildContext context, {
    required Widget child,
    String? title,
    bool showHandle = true,
    bool isDismissible = true,
    bool enableDrag = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      isScrollControlled: true,
      builder: (context) => CustomBottomSheet(
        title: title,
        showHandle: showHandle,
        child: child,
      ),
    );
  }
}

/// Action sheet with list of options
class ActionSheet extends StatelessWidget {
  final String? title;
  final List<ActionSheetItem> items;
  final bool showCancel;
  final String cancelText;

  const ActionSheet({
    super.key,
    this.title,
    required this.items,
    this.showCancel = true,
    this.cancelText = 'Cancel',
  });

  @override
  Widget build(BuildContext context) {
    return CustomBottomSheet(
      title: title,
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...items.map((item) => _buildItem(context, item)),
          if (showCancel) ...[
            Divider(height: 1, color: AppColors.glassBorder),
            ListTile(
              onTap: () => Navigator.of(context).pop(),
              title: Center(
                child: Text(
                  cancelText,
                  style: const TextStyle(
                    color: AppColors.textLightSecondary,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildItem(BuildContext context, ActionSheetItem item) {
    return ListTile(
      leading: item.icon != null
          ? Icon(
              item.icon,
              color: item.isDestructive ? AppColors.error : AppColors.textLight,
            )
          : null,
      title: Text(
        item.title,
        style: TextStyle(
          color: item.isDestructive ? AppColors.error : AppColors.textLight,
          fontSize: 16,
        ),
      ),
      subtitle: item.subtitle != null
          ? Text(
              item.subtitle!,
              style: const TextStyle(
                color: AppColors.textLightSecondary,
                fontSize: 12,
              ),
            )
          : null,
      onTap: () {
        Navigator.of(context).pop();
        item.onTap?.call();
      },
    );
  }

  static Future<void> show(
    BuildContext context, {
    String? title,
    required List<ActionSheetItem> items,
    bool showCancel = true,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ActionSheet(
        title: title,
        items: items,
        showCancel: showCancel,
      ),
    );
  }
}

class ActionSheetItem {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool isDestructive;

  const ActionSheetItem({
    required this.title,
    this.subtitle,
    this.icon,
    this.onTap,
    this.isDestructive = false,
  });
}

/// Date picker bottom sheet
class DatePickerSheet extends StatefulWidget {
  final DateTime? initialDate;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final String title;

  const DatePickerSheet({
    super.key,
    this.initialDate,
    this.firstDate,
    this.lastDate,
    this.title = 'Select Date',
  });

  @override
  State<DatePickerSheet> createState() => _DatePickerSheetState();

  static Future<DateTime?> show(
    BuildContext context, {
    DateTime? initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
    String title = 'Select Date',
  }) {
    return showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DatePickerSheet(
        initialDate: initialDate,
        firstDate: firstDate,
        lastDate: lastDate,
        title: title,
      ),
    );
  }
}

class _DatePickerSheetState extends State<DatePickerSheet> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return CustomBottomSheet(
      title: widget.title,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 250,
            child: Theme(
              data: ThemeData.dark().copyWith(
                colorScheme: const ColorScheme.dark(
                  primary: AppColors.accent,
                  surface: AppColors.darkSurface,
                ),
              ),
              child: CalendarDatePicker(
                initialDate: _selectedDate,
                firstDate: widget.firstDate ?? DateTime(2000),
                lastDate: widget.lastDate ?? DateTime(2100),
                onDateChanged: (date) {
                  setState(() => _selectedDate = date);
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: AppColors.textLightSecondary),
                  ),
                ),
              ),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(_selectedDate),
                  child: const Text('Select'),
                ),
              ),
            ],
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}
