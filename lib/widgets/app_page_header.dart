import 'package:flutter/material.dart';

import 'app_logo.dart';

class AppPageHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppPageHeader({
    required this.title,
    required this.compact,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String title;
  final bool compact;
  final String? actionLabel;
  final VoidCallback? onAction;

  bool get _hasAction => actionLabel != null && onAction != null;

  @override
  Size get preferredSize => Size.fromHeight(compact && _hasAction ? 142 : 72);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: preferredSize.height,
      titleSpacing: 20,
      title: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: compact && _hasAction
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const AppLogo(size: 42),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.visible,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 42,
                      child: FilledButton(
                        onPressed: onAction,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.add_rounded),
                              const SizedBox(width: 8),
                              Text(actionLabel!),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    const AppLogo(size: 42),
                    const SizedBox(width: 14),
                    Expanded(child: Text(title)),
                    if (_hasAction) ...[
                      const SizedBox(width: 16),
                      FilledButton.icon(
                        onPressed: onAction,
                        icon: const Icon(Icons.add_rounded),
                        label: Text(actionLabel!),
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}
