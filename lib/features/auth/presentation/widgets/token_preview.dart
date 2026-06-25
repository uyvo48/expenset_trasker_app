import 'package:flutter/material.dart';

class TokenPreview extends StatelessWidget {
  const TokenPreview({
    super.key,
    required this.label,
    required this.token,
  });

  final String label;
  final String token;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: textTheme.labelLarge),
            const SizedBox(height: 6),
            SelectableText(
              _compactToken(token),
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _compactToken(String token) {
  if (token.length <= 32) return token;
  return '${token.substring(0, 16)}...${token.substring(token.length - 12)}';
}
