import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Dark theme tokens (from the OTP screen in the Figma).
class AuthColors {
  static const bg = Color(0xFF13111F);
  static const field = Color(0xFF1C1A2B);
  static const primary = Color(0xFF7C55F0);
  static const ink = Color(0xFFF2EEFB);
  static const muted = Color(0xFFB4AEC8);
  static const border = Color(0xFF2E2A45);
  static const error = Color(0xFFFF6B8A);
  static const disabled = Color(0xFF2A2640);
}

class AuthText {
  // 'serif' uses the system serif. For the exact Figma look, add the
  // google_fonts package (Fraunces for headings, Figtree for body).
  static const heading = TextStyle(
    fontFamily: 'serif',
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AuthColors.ink,
    height: 1.15,
  );
  static const subtitle = TextStyle(
    fontSize: 15,
    height: 1.4,
    color: AuthColors.muted,
  );
  static const label = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AuthColors.muted,
  );
}

OutlineInputBorder _outline(Color color, double width) => OutlineInputBorder(
  borderRadius: BorderRadius.circular(12),
  borderSide: BorderSide(color: color, width: width),
);

/// Page frame: back chevron (or a [top] widget), serif title, subtitle,
/// then [children].
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.centered = false,
    this.showBack = true,
    this.top,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;
  final bool centered;
  final bool showBack;
  final Widget? top;

  @override
  Widget build(BuildContext context) {
    final align = centered ? TextAlign.center : TextAlign.start;
    final canBack = showBack && Navigator.canPop(context);

    return Scaffold(
      backgroundColor: AuthColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment:
            centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
            children: [
              if (top != null) ...[
                const SizedBox(height: 12),
                top!,
                const SizedBox(height: 28),
              ] else
                SizedBox(
                  height: 48,
                  child: canBack
                      ? Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      tooltip: 'Back',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(
                        width: 40,
                        height: 40,
                      ),
                      icon: const Icon(
                        Icons.chevron_left_rounded,
                        color: AuthColors.ink,
                        size: 28,
                      ),
                      onPressed: () => Navigator.maybePop(context),
                    ),
                  )
                      : null,
                ),
              const SizedBox(height: 16),
              Text(title, textAlign: align, style: AuthText.heading),
              if (subtitle != null) ...[
                const SizedBox(height: 8),
                Text(subtitle!, textAlign: align, style: AuthText.subtitle),
              ],
              const SizedBox(height: 28),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

/// Labeled text field (username, email, name, age...).
class DarkField extends StatelessWidget {
  const DarkField({
    super.key,
    required this.label,
    required this.controller,
    this.focusNode,
    this.enabled = true,
    this.error,
    this.helper,
    this.keyboardType,
    this.formatters,
    this.capitalization = TextCapitalization.none,
    this.obscure = false,
    this.suffix,
    this.hints,
    this.action,
    this.onChanged,
    this.onSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool enabled;
  final String? error;
  final String? helper;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? formatters;
  final TextCapitalization capitalization;
  final bool obscure;
  final Widget? suffix;
  final Iterable<String>? hints;
  final TextInputAction? action;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final hasError = error != null;
    final color = hasError ? AuthColors.error : AuthColors.border;
    final width = hasError ? 1.5 : 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AuthText.label),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          focusNode: focusNode,
          enabled: enabled,
          keyboardType: keyboardType,
          textInputAction: action,
          inputFormatters: formatters,
          textCapitalization: capitalization,
          obscureText: obscure,
          enableSuggestions: !obscure,
          autocorrect: !obscure,
          autofillHints: hints,
          cursorColor: AuthColors.primary,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          style: const TextStyle(fontSize: 16, color: AuthColors.ink),
          decoration: InputDecoration(
            filled: true,
            fillColor: AuthColors.field,
            suffixIcon: suffix,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 17,
            ),
            border: _outline(color, width),
            enabledBorder: _outline(color, width),
            disabledBorder: _outline(AuthColors.border, 1),
            focusedBorder: _outline(
              hasError ? AuthColors.error : AuthColors.primary,
              1.8,
            ),
          ),
        ),
        if (hasError)
          ErrorLine(error!)
        else if (helper != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              helper!,
              style: const TextStyle(fontSize: 12, color: AuthColors.muted),
            ),
          ),
      ],
    );
  }
}

/// Password field with a show/hide eye.
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    this.label = 'Password',
    this.enabled = true,
    this.error,
    this.helper,
    this.newPassword = false,
    this.action = TextInputAction.done,
    this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final bool enabled;
  final String? error;
  final String? helper;
  final bool newPassword;
  final TextInputAction action;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _hide = true;

  @override
  Widget build(BuildContext context) {
    return DarkField(
      label: widget.label,
      controller: widget.controller,
      enabled: widget.enabled,
      error: widget.error,
      helper: widget.helper,
      obscure: _hide,
      keyboardType: TextInputType.visiblePassword,
      action: widget.action,
      hints: [
        widget.newPassword ? AutofillHints.newPassword : AutofillHints.password,
      ],
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      suffix: IconButton(
        tooltip: _hide ? 'Show password' : 'Hide password',
        icon: Icon(
          _hide ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          color: AuthColors.muted,
        ),
        onPressed: () => setState(() => _hide = !_hide),
      ),
    );
  }
}

/// Labeled dropdown in the same dark style.
class DarkDropdown extends StatelessWidget {
  const DarkDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.labelSuffix,
    this.hint = 'Select',
    this.error,
  });

  final String label;
  final String? labelSuffix;
  final String? value;
  final List<String> items;
  final ValueChanged<String?>? onChanged;
  final String hint;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final hasError = error != null;
    final color = hasError ? AuthColors.error : AuthColors.border;
    final width = hasError ? 1.5 : 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: label,
            style: AuthText.label,
            children: [
              if (labelSuffix != null)
                TextSpan(
                  text: labelSuffix,
                  style: const TextStyle(color: AuthColors.primary),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        InputDecorator(
          decoration: InputDecoration(
            filled: true,
            fillColor: AuthColors.field,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 6,
            ),
            border: _outline(color, width),
            enabledBorder: _outline(color, width),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              hint: Text(hint, style: const TextStyle(color: AuthColors.muted)),
              dropdownColor: AuthColors.field,
              borderRadius: BorderRadius.circular(12),
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AuthColors.muted,
              ),
              style: const TextStyle(fontSize: 16, color: AuthColors.ink),
              onChanged: onChanged,
              items: [
                for (final item in items)
                  DropdownMenuItem(value: item, child: Text(item)),
              ],
            ),
          ),
        ),
        if (hasError) ErrorLine(error!),
      ],
    );
  }
}

class ErrorLine extends StatelessWidget {
  const ErrorLine(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(Icons.info_outline, size: 14, color: AuthColors.error),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12,
                height: 1.3,
                color: AuthColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.looksDisabled = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  /// Grey "not ready yet" style that still responds to taps, so the page
  /// can show what is missing.
  final bool looksDisabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor:
          looksDisabled ? AuthColors.disabled : AuthColors.primary,
          foregroundColor: looksDisabled ? AuthColors.muted : Colors.white,
          disabledBackgroundColor: AuthColors.primary.withValues(alpha: 0.6),
          disabledForegroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: loading
            ? const SizedBox(
          height: 22,
          width: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: Colors.white,
          ),
        )
            : Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: AuthColors.field,
          foregroundColor: AuthColors.ink,
          side: const BorderSide(color: AuthColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class TextLinkButton extends StatelessWidget {
  const TextLinkButton(this.label, {super.key, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(foregroundColor: AuthColors.muted),
        child: Text(label, style: const TextStyle(fontSize: 15)),
      ),
    );
  }
}

class AuthCheckbox extends StatelessWidget {
  const AuthCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
    this.error,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String label;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final hasError = error != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          checked: value,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => onChanged(!value),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    height: 22,
                    width: 22,
                    decoration: BoxDecoration(
                      color: value ? AuthColors.primary : AuthColors.field,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: hasError
                            ? AuthColors.error
                            : value
                            ? AuthColors.primary
                            : AuthColors.muted,
                        width: 1.5,
                      ),
                    ),
                    child: value
                        ? const Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: Colors.white,
                    )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.35,
                          color: AuthColors.ink,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(left: 34),
            child: ErrorLine(error!),
          ),
      ],
    );
  }
}