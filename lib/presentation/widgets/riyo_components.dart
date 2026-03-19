import 'package:flutter/material.dart';
import 'package:riyo/core/design_system.dart';

class RiyoTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const RiyoTextField({
    super.key,
    required this.controller,
    required this.label,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  State<RiyoTextField> createState() => _RiyoTextFieldState();
}

class _RiyoTextFieldState extends State<RiyoTextField> {
  late bool _isObscured;

  @override
  void initState() {
    super.initState();
    _isObscured = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _isObscured,
      keyboardType: widget.keyboardType,
      validator: widget.validator,
      style: AppTypography.bodyLarge.copyWith(
        color: Theme.of(context).textTheme.bodyLarge?.color,
      ),
      decoration: InputDecoration(
        labelText: widget.label,
        suffixIcon: widget.obscureText
            ? IconButton(
                icon: Icon(
                  _isObscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  size: 20,
                ),
                onPressed: () => setState(() => _isObscured = !_isObscured),
              )
            : widget.suffixIcon,
      ),
    );
  }
}

class RiyoButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isPrimary;
  final Duration debounceDuration;

  const RiyoButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isPrimary = true,
    this.debounceDuration = const Duration(milliseconds: 500),
  });

  @override
  State<RiyoButton> createState() => _RiyoButtonState();
}

class _RiyoButtonState extends State<RiyoButton> {
  bool _isDebouncing = false;

  void _handlePressed() {
    if (widget.onPressed == null || widget.isLoading || _isDebouncing) return;

    setState(() => _isDebouncing = true);
    widget.onPressed!();

    Future.delayed(widget.debounceDuration, () {
      if (mounted) setState(() => _isDebouncing = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = widget.onPressed == null || widget.isLoading || _isDebouncing;

    if (!widget.isPrimary) {
      return TextButton(
        onPressed: isDisabled ? null : _handlePressed,
        style: TextButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.primary,
          textStyle: AppTypography.labelLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        child: Text(isDisabled && widget.isLoading ? "Please wait..." : widget.text),
      );
    }

    return ElevatedButton(
      onPressed: isDisabled ? null : _handlePressed,
      child: widget.isLoading
          ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Text(_isDebouncing ? "Action already in progress" : widget.text),
    );
  }
}

class RiyoSocialButton extends StatelessWidget {
  final String text;
  final Widget icon;
  final VoidCallback onPressed;

  const RiyoSocialButton({
    super.key,
    required this.text,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.buttonBorderRadius),
        ),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon,
          const SizedBox(width: 12),
          Text(
            text,
            style: AppTypography.labelMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
