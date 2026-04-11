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
  final _identifierController = TextEditingController();
  final _signUpIdentifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final _codeController = TextEditingController();
  _AuthMode _mode = _AuthMode.signIn;
  AuthIdentifierMethod _signUpMethod = AuthIdentifierMethod.email;

  @override
  void dispose() {
    _identifierController.dispose();
    _signUpIdentifierController.dispose();
    _passwordController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submitCredentials() async {
    if (_mode == _AuthMode.forgotPassword) {
      final identifier = _identifierController.text.trim();
      if (identifier.isEmpty) {
        return;
      }
      await widget.controller.resetPassword(identifier: identifier);
      return;
    }

    final password = _passwordController.text;
    if (password.isEmpty) {
      return;
    }

    if (_mode == _AuthMode.signIn) {
      final identifier = _identifierController.text.trim();
      if (identifier.isEmpty) {
        return;
      }
      await widget.controller.signIn(
        identifier: identifier,
        password: password,
      );
      return;
    }

    final identifier = _signUpIdentifierController.text.trim();
    if (identifier.isEmpty) {
      return;
    }

    await widget.controller.signUp(
      method: _signUpMethod,
      identifier: identifier,
      password: password,
    );
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
        final infoMessage = controller.infoMessage;
        final currentContact = controller.userContact;

        if (currentContact != null &&
            _identifierController.text.isEmpty &&
            (controller.needsConfirmation ||
                controller.status == AuthStatus.awaitingResetPassword)) {
          _identifierController.text = currentContact;
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
                                ? 'Confirm your account'
                                : controller.status ==
                                      AuthStatus.awaitingResetPassword
                                ? 'Reset your password'
                                : _mode == _AuthMode.forgotPassword
                                ? 'Forgot your password?'
                                : _mode == _AuthMode.signUp
                                ? 'Create your account'
                                : 'Sign in to Plan Together',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            controller.needsConfirmation
                                ? controller.confirmationPrompt
                                : controller.status ==
                                      AuthStatus.awaitingResetPassword
                                ? controller.resetPasswordPrompt
                                : _mode == _AuthMode.forgotPassword
                                ? 'Use your email address or phone number to receive a password reset code.'
                                : _mode == _AuthMode.signUp
                                ? 'Create an account with either an email address or a phone number. You only need one.'
                                : 'Sign in with the same email address or phone number you used to create the account.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppPalette.mutedText),
                          ),
                          const SizedBox(height: 20),
                          if (controller.status == AuthStatus.loading)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          else if (controller.needsConfirmation)
                            _ConfirmationForm(
                              contact:
                                  controller.deliveryDestination ??
                                  currentContact ??
                                  _identifierController.text,
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
                          else if (controller.status ==
                              AuthStatus.awaitingResetPassword)
                            _ResetPasswordForm(
                              contact:
                                  controller.deliveryDestination ??
                                  currentContact ??
                                  _identifierController.text,
                              codeController: _codeController,
                              passwordController: _passwordController,
                              isBusy: controller.isBusy,
                              onConfirm: () async {
                                final code = _codeController.text.trim();
                                final newPassword = _passwordController.text;
                                if (code.isNotEmpty && newPassword.isNotEmpty) {
                                  await widget.controller.confirmResetPassword(
                                    newPassword: newPassword,
                                    confirmationCode: code,
                                  );
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
                              identifierController: _identifierController,
                              signUpIdentifierController:
                                  _signUpIdentifierController,
                              passwordController: _passwordController,
                              isBusy: controller.isBusy,
                              signUpMethod: _signUpMethod,
                              onSubmit: _submitCredentials,
                              onSignUpMethodChanged: (method) {
                                setState(() {
                                  _signUpMethod = method;
                                  _signUpIdentifierController.clear();
                                });
                              },
                              onModeChanged: (mode) {
                                setState(() {
                                  _mode = mode;
                                });
                              },
                            ),
                          if (infoMessage != null) ...[
                            const SizedBox(height: 16),
                            _MessageCard(message: infoMessage),
                          ],
                          if (errorMessage != null) ...[
                            const SizedBox(height: 16),
                            _MessageCard(message: errorMessage, isError: true),
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
    required this.identifierController,
    required this.signUpIdentifierController,
    required this.passwordController,
    required this.isBusy,
    required this.signUpMethod,
    required this.onSubmit,
    required this.onSignUpMethodChanged,
    required this.onModeChanged,
  });

  final _AuthMode mode;
  final TextEditingController identifierController;
  final TextEditingController signUpIdentifierController;
  final TextEditingController passwordController;
  final bool isBusy;
  final AuthIdentifierMethod signUpMethod;
  final Future<void> Function() onSubmit;
  final ValueChanged<AuthIdentifierMethod> onSignUpMethodChanged;
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
        if (mode != _AuthMode.forgotPassword) const SizedBox(height: 18),
        if (mode == _AuthMode.signUp) ...[
          SegmentedButton<AuthIdentifierMethod>(
            segments: const [
              ButtonSegment<AuthIdentifierMethod>(
                value: AuthIdentifierMethod.email,
                label: Text('Email'),
              ),
              ButtonSegment<AuthIdentifierMethod>(
                value: AuthIdentifierMethod.phone,
                label: Text('Phone'),
              ),
            ],
            selected: {signUpMethod},
            onSelectionChanged: isBusy
                ? null
                : (selection) => onSignUpMethodChanged(selection.first),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: signUpIdentifierController,
            keyboardType: signUpMethod == AuthIdentifierMethod.email
                ? TextInputType.emailAddress
                : TextInputType.phone,
            textInputAction: TextInputAction.next,
            autofillHints: signUpMethod == AuthIdentifierMethod.email
                ? const [AutofillHints.email]
                : const [AutofillHints.telephoneNumber],
            enabled: !isBusy,
            decoration: InputDecoration(
              labelText: signUpMethod == AuthIdentifierMethod.email
                  ? 'Email address'
                  : 'Phone number',
              hintText: signUpMethod == AuthIdentifierMethod.email
                  ? 'you@example.com'
                  : '+1 555 123 4567',
            ),
          ),
        ] else
          TextField(
            controller: identifierController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [
              AutofillHints.username,
              AutofillHints.email,
              AutofillHints.telephoneNumber,
            ],
            enabled: !isBusy,
            decoration: const InputDecoration(
              labelText: 'Email or phone',
              hintText: 'you@example.com or +1 555 123 4567',
            ),
          ),
        if (mode != _AuthMode.forgotPassword) ...[
          const SizedBox(height: 14),
          TextField(
            controller: passwordController,
            obscureText: true,
            textInputAction: TextInputAction.done,
            autofillHints: mode == _AuthMode.signUp
                ? const [AutofillHints.newPassword]
                : const [AutofillHints.password],
            enabled: !isBusy,
            decoration: InputDecoration(
              labelText: 'Password',
              hintText: mode == _AuthMode.signIn
                  ? 'Your password'
                  : 'At least 8 chars, with upper/lowercase, number, symbol',
            ),
            onSubmitted: (_) => onSubmit(),
          ),
          if (mode == _AuthMode.signIn) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: isBusy
                    ? null
                    : () => onModeChanged(_AuthMode.forgotPassword),
                child: const Text('Forgot password?'),
              ),
            ),
          ],
        ],
        if (mode == _AuthMode.signUp) ...[
          const SizedBox(height: 10),
          Text(
            signUpMethod == AuthIdentifierMethod.email
                ? 'Use a real email address so you can receive the confirmation code.'
                : 'Use a real mobile number that can receive SMS verification codes.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppPalette.mutedText),
          ),
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

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.message, this.isError = false});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isError ? const Color(0xFFFFF3F2) : AppPalette.primarySoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isError ? const Color(0xFFFFC9C5) : AppPalette.border,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Text(message, style: Theme.of(context).textTheme.bodyMedium),
      ),
    );
  }
}

class _ConfirmationForm extends StatelessWidget {
  const _ConfirmationForm({
    required this.contact,
    required this.codeController,
    required this.isBusy,
    required this.onConfirm,
    required this.onResend,
    required this.onBack,
  });

  final String contact;
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
          contact,
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
          onSubmitted: (_) => onConfirm(),
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
    required this.contact,
    required this.codeController,
    required this.passwordController,
    required this.isBusy,
    required this.onConfirm,
    required this.onBack,
  });

  final String contact;
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
          contact,
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
            labelText: 'New password',
            hintText: 'At least 8 chars...',
          ),
          onSubmitted: (_) => onConfirm(),
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
