import 'package:flutter/material.dart';
import 'package:my_app/utils/auth_text.dart';

class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.linking = false,
    this.busy = false,
  });
  final VoidCallback? onPressed;
  final bool linking;
  final bool busy;

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onPressed,
    style: OutlinedButton.styleFrom(
      foregroundColor: const Color(0xFF1F1F1F),
      backgroundColor: Colors.white,
      side: const BorderSide(color: Color(0xFF747775)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      minimumSize: const Size(double.infinity, 48),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    ),
    child: Row(
      children: [
        Image.asset(
          'assets/brand/google_g.png',
          width: 20,
          height: 20,
          excludeFromSemantics: true,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            authText(
              linking ? 'googleContinue' : 'googleSignIn',
              Localizations.localeOf(context).languageCode,
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
        if (busy) ...[
          const SizedBox(width: 10),
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ],
      ],
    ),
  );
}
