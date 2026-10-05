import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

enum ToastType {
  success,
  error,
  info,
  warning,
}

class AppToast {
  static void showSuccess(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    show(
      context,
      message: message,
      title: title,
      type: ToastType.success,
      duration: duration,
    );
  }

  static void showError(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 4),
  }) {
    show(
      context,
      message: message,
      title: title,
      type: ToastType.error,
      duration: duration,
    );
  }

  static void showInfo(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    show(
      context,
      message: message,
      title: title,
      type: ToastType.info,
      duration: duration,
    );
  }

  static void showWarning(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    show(
      context,
      message: message,
      title: title,
      type: ToastType.warning,
      duration: duration,
    );
  }

  static void show(
    BuildContext context, {
    required String message,
    String? title,
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger.hideCurrentSnackBar();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color primaryColor;
    Color backgroundColor;
    Color iconBgColor;
    List<List<dynamic>> icon;

    switch (type) {
      case ToastType.success:
        primaryColor = const Color(0xFF10B981);
        backgroundColor = isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5);
        iconBgColor = isDark ? const Color(0xFF047857) : const Color(0xFFD1FAE5);
        icon = HugeIcons.strokeRoundedCheckmarkCircle02;
        break;
      case ToastType.error:
        primaryColor = const Color(0xFFEF4444);
        backgroundColor = isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEF2F2);
        iconBgColor = isDark ? const Color(0xFFB91C1C) : const Color(0xFFFEE2E2);
        icon = HugeIcons.strokeRoundedAlertCircle;
        break;
      case ToastType.warning:
        primaryColor = const Color(0xFFF59E0B);
        backgroundColor = isDark ? const Color(0xFF78350F) : const Color(0xFFFFFBEB);
        iconBgColor = isDark ? const Color(0xFFB45309) : const Color(0xFFFEF3C7);
        icon = HugeIcons.strokeRoundedAlert02;
        break;
      case ToastType.info:
        primaryColor = const Color(0xFF3B82F6);
        backgroundColor = isDark ? const Color(0xFF1E3A8A) : const Color(0xFFEFF6FF);
        iconBgColor = isDark ? const Color(0xFF1D4ED8) : const Color(0xFFDBEAFE);
        icon = HugeIcons.strokeRoundedInformationCircle;
        break;
    }

    final textColor = isDark ? Colors.white : const Color(0xFF1F2937);

    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        padding: EdgeInsets.zero,
        duration: duration,
        content: AppToastCard(
          title: title,
          message: message,
          primaryColor: primaryColor,
          backgroundColor: backgroundColor,
          iconBgColor: iconBgColor,
          textColor: textColor,
          icon: icon,
          onClose: () => messenger.hideCurrentSnackBar(),
        ),
      ),
    );
  }
}

class AppToastCard extends StatelessWidget {
  final String? title;
  final String message;
  final Color primaryColor;
  final Color backgroundColor;
  final Color iconBgColor;
  final Color textColor;
  final List<List<dynamic>> icon;
  final VoidCallback? onClose;

  const AppToastCard({
    super.key,
    this.title,
    required this.message,
    required this.primaryColor,
    required this.backgroundColor,
    required this.iconBgColor,
    required this.textColor,
    required this.icon,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryColor.withAlpha(50),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: HugeIcon(
              icon: icon,
              color: primaryColor,
              size: 20.0,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null && title!.isNotEmpty) ...[
                  Text(
                    title!,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
          if (onClose != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onClose,
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: textColor.withAlpha(150),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
