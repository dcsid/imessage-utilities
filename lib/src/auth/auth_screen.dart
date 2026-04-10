import 'package:chat_utilities_hub/src/auth/auth_controller.dart';
import 'package:chat_utilities_hub/src/presentation/app_backdrop.dart';
import 'package:chat_utilities_hub/src/presentation/app_palette.dart';
import 'package:chat_utilities_hub/src/presentation/app_surface.dart';
import 'package:flutter/material.dart';

enum _AuthMode { signIn, signUp, forgotPassword }

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.controller});

  final AuthController controller;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _codeController = TextEditingController();
  _AuthMode _mode = _AuthMode.signIn;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submitCredentials() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty) {
      return;
    }

    if (_mode == _AuthMode.forgotPassword) {
      await widget.controller.resetPassword(email: email);
      return;
    }

    if (password.isEmpty) {
      return;
    }

    if (_mode == _AuthMode.signIn) {
      await widget.controller.signIn(email: email, password: password);
      return;
    }

    await widget.controller.signUp(email: email, password: password);
  }

  Future<void> _confirmSignUp() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      return;
    }
    await widget.controller.confirmSignUp(code);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final controller = widget.controller;
        final errorMessage = controller.errorMessage;

        if (controller.userEmail != null &&
            _emailController.text.isEmpty &&
            controller.needsConfirmation) {
          _emailController.text = controller.userEmail!;
        }

        return Scaffold(
          body: AppBackdrop(
            child: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: AppSurface(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            controller.needsConfirmation
                                ? 'Confirm your email'
                                : controller.status == AuthStatus.awaitingResetPassword
                                    ? 'Reset your password'
                                    : _mode == _AuthMode.forgotPassword
                                        ? 'Forgot your password?'
                                        : 'Sign in to Plan Together',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            controller.needsConfirmation
                                ? 'Enter the code that AWS Cognito emailed you, then we will sign you in automatically.'
                                : controller.status == AuthStatus.awaitingResetPassword
                                    ? 'Enter the reset code sent to your email and your new password.'
                                    : _mode == _AuthMode.forgotPassword
                                        ? 'Enter your email to receive a password reset code.'
                                        : 'Use email and password to keep your planning boards tied to one account.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppPalette.mutedText),
                          ),
                          const SizedBox(height: 20),
                          if (controller.status == AuthStatus.loading)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: CircularProgressIndicator(),
                              ),
                            )
                          else if (controller.needsConfirmation)
                            _ConfirmationForm(
                              email: controller.userEmail ?? _emailController.text,
                              codeController: _codeController,
                              isBusy: controller.isBusy,
                              onConfirm: _confirmSignUp,
                              onResend: controller.resendConfirmationCode,
                              onBack: () {
                                _codeController.clear();
                                widget.controller.showSignIn();
                                setState(() {
                                  _mode = _AuthMode.signIn;
                                });
                              },
                            )
                          else if (controller.status == AuthStatus.awaitingResetPassword)
                            _ResetPasswordForm(
                              email: controller.userEmail ?? _emailController.text,
                              codeController: _codeController,
                              passwordController: _passwordController,
                              isBusy: controller.isBusy,
                              onConfirm: () async {
                                final code = _codeController.text.trim();
                                final newPassword = _passwordController.text;
                                if (code.isNotEmpty && newPassword.isNotEmpty) {
                                  await widget.controller.confirmResetPassword(
                                      newPassword: newPassword, confirmationCode: code);
                                }
                              },
                              onBack: () {
                                _codeController.clear();
                                _passwordController.clear();
                                widget.controller.showSignIn();
                                setState(() {
                                  _mode = _AuthMode.signIn;
                                });
                              },
                            )
                          else
                            _CredentialsForm(
                              mode: _mode,
                              emailController: _emailController,
                              passwordController: _passwordController,
                              isBusy: controller.isBusy,
                              onSubmit: _submitCredentials,
                              onModeChanged: (mode) {
                                setState(() {
                                  _mode = mode;
                                });
                              },
                            ),
                          if (errorMessage != null) ...[
                            const SizedBox(height: 16),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: AppPalette.primarySoft,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppPalette.border),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Text(
                                  errorMessage,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CredentialsForm extends StatelessWidget {
  const _CredentialsForm({
    required this.mode,
    required this.emailController,
    required this.passwordController,
    required this.isBusy,
    required this.onSubmit,
    required this.onModeChanged,
  });

  final _AuthMode mode;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isBusy;
  final Future<void> Function() onSubmit;
  final ValueChanged<_AuthMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    var submitLabel = 'Sign in';
    if (mode == _AuthMode.signUp) submitLabel = 'Create account';
    if (mode == _AuthMode.forgotPassword) submitLabel = 'Send reset code';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (mode != _AuthMode.forgotPassword)
          SegmentedButton<_AuthMode>(
            segments: const [
              ButtonSegment<_AuthMode>(
                value: _AuthMode.signIn,
                label: Text('Sign in'),
              ),
              ButtonSegment<_AuthMode>(
                value: _AuthMode.signUp,
                label: Text('Create account'),
              ),
            ],
            selected: {mode},
            onSelectionChanged: isBusy
                ? null
                : (selection) => onModeChanged(selection.first),
          ),
        if (mode != _AuthMode.forgotPassword)
          const SizedBox(height: 18),
        TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
          enabled: !isBusy,
          decoration: const InputDecoration(
            labelText: 'Email',
            hintText: 'you@example.com',
          ),
        ),
        if (mode != _AuthMode.forgotPassword) ...[
          const SizedBox(height: 14),
          TextField(
            controller: passwordController,
            obscureText: true,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            enabled: !isBusy,
            decoration: InputDecoration(
              labelText: 'Password',
              hintText: mode == _AuthMode.signIn
                  ? 'Your password'
                  : 'At least 8 chars, with upper/lowercase, number, symbol',
            ),
            onSubmitted: (_) {
              onSubmit();
            },
          ),
          if (mode == _AuthMode.signIn) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: isBusy ? null : () => onModeChanged(_AuthMode.forgotPassword),
                child: const Text('Forgot Password?'),
              ),
            ),
          ],
        ],
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: isBusy ? null : onSubmit,
            child: Text(submitLabel),
          ),
        ),
        if (mode == _AuthMode.forgotPassword) ...[
          const SizedBox(height: 10),
          Center(
            child: TextButton(
              onPressed: isBusy ? null : () => onModeChanged(_AuthMode.signIn),
              child: const Text('Back to sign in'),
            ),
          ),
        ],
      ],
    );
  }
}

class _ConfirmationForm extends StatelessWidget {
  const _ConfirmationForm({
    required this.email,
    required this.codeController,
    required this.isBusy,
    required this.onConfirm,
    required this.onResend,
    required this.onBack,
  });

  final String email;
  final TextEditingController codeController;
  final bool isBusy;
  final Future<void> Function() onConfirm;
  final Future<void> Function() onResend;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          email,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: codeController,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.oneTimeCode],
          enabled: !isBusy,
          decoration: const InputDecoration(
            labelText: 'Confirmation code',
            hintText: '123456',
          ),
          onSubmitted: (_) {
            onConfirm();
          },
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: isBusy ? null : onConfirm,
            child: const Text('Confirm and continue'),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            OutlinedButton(
              onPressed: isBusy ? null : onResend,
              child: const Text('Resend code'),
            ),
            OutlinedButton(
              onPressed: isBusy ? null : onBack,
              child: const Text('Back'),
            ),
          ],
        ),
      ],
    );
  }
}

class _ResetPasswordForm extends StatelessWidget {
  const _ResetPasswordForm({
    required this.email,
    required this.codeController,
    required this.passwordController,
    required this.isBusy,
    required this.onConfirm,
    required this.onBack,
  });

  final String email;
  final TextEditingController codeController;
  final TextEditingController passwordController;
  final bool isBusy;
  final Future<void> Function() onConfirm;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          email,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: codeController,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.oneTimeCode],
          enabled: !isBusy,
          decoration: const InputDecoration(
            labelText: 'Reset code',
            hintText: '123456',
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: passwordController,
          obscureText: true,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.newPassword],
          enabled: !isBusy,
          decoration: const InputDecoration(
            labelText: 'New Password',
            hintText: 'At least 8 chars...',
          ),
          onSubmitted: (_) {
            onConfirm();
          },
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: isBusy ? null : onConfirm,
            child: const Text('Reset password'),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: OutlinedButton(
            onPressed: isBusy ? null : onBack,
            child: const Text('Back to sign in'),
          ),
        ),
      ],
    );
  }
}
