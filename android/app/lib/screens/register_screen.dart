import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/medicine_catalog.dart';
import '../services/auth_service.dart';
import '../utils/form_validators.dart';
import '../widgets/medi_background.dart';
import '../widgets/ui_kit.dart';
import '../widgets/validation_banner.dart';
import 'app_shell.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollCtr = ScrollController();
  final _emailCtr = TextEditingController();
  final _passCtr = TextEditingController();
  final _confirmPassCtr = TextEditingController();
  final _auth = AuthService();
  bool _busy = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _bannerMessage;

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 6),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Runs validators directly on controllers (does not rely on Form alone).
  String? _firstValidationError() {
    return FormValidators.email(_emailCtr.text) ??
        FormValidators.password(_passCtr.text) ??
        FormValidators.confirmPassword(_confirmPassCtr.text, _passCtr.text);
  }

  Future<void> _register() async {
    FocusScope.of(context).unfocus();

    final error = _firstValidationError();
    setState(() => _bannerMessage = error);

    final formOk = _formKey.currentState?.validate() ?? false;
    if (error != null || !formOk) {
      if (error != null) _showError(error);
      if (_scrollCtr.hasClients) {
        await _scrollCtr.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
      return;
    }

    setState(() {
      _busy = true;
      _bannerMessage = null;
    });

    final result = await _auth.register(
      email: _emailCtr.text.trim(),
      password: _passCtr.text,
    );
    if (!mounted) return;
    if (result.isSuccess) {
      try {
        await context.read<MedicineCatalog>().syncWithCloudAndReschedule();
      } catch (_) {}
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute<void>(builder: (_) => const AppShell()),
        (route) => false,
      );
    } else {
      final msg = result.errorMessage ?? 'Registration failed';
      setState(() => _bannerMessage = msg);
      _showError(msg);
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  void dispose() {
    _scrollCtr.dispose();
    _emailCtr.dispose();
    _passCtr.dispose();
    _confirmPassCtr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: MediBackground(
        child: AbsorbPointer(
          absorbing: _busy,
          child: SafeArea(
            child: SingleChildScrollView(
              controller: _scrollCtr,
              padding: const EdgeInsets.all(24),
              physics: const BouncingScrollPhysics(),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.always,
                child: Column(
                  children: [
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Join MediVoice',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Use a full email with @ (e.g. you@gmail.com).',
                            style: TextStyle(fontSize: 13, height: 1.35),
                          ),
                          if (_bannerMessage != null) ...[
                            const SizedBox(height: 12),
                            ValidationBanner(message: _bannerMessage!),
                          ],
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _emailCtr,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autocorrect: false,
                            enableSuggestions: false,
                            enabled: !_busy,
                            onChanged: (_) {
                              if (_bannerMessage != null) {
                                setState(() => _bannerMessage = null);
                              }
                            },
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.alternate_email_rounded),
                              hintText: 'you@gmail.com',
                            ),
                            validator: FormValidators.email,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _passCtr,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.next,
                            enabled: !_busy,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline_rounded),
                              helperText: 'Minimum 6 characters, no spaces',
                              helperMaxLines: 2,
                              suffixIcon: IconButton(
                                tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                                onPressed: _busy
                                    ? null
                                    : () => setState(() => _obscurePassword = !_obscurePassword),
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                            validator: FormValidators.password,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _confirmPassCtr,
                            obscureText: _obscureConfirm,
                            textInputAction: TextInputAction.done,
                            enabled: !_busy,
                            onFieldSubmitted: (_) {
                              if (!_busy) _register();
                            },
                            decoration: InputDecoration(
                              labelText: 'Confirm password',
                              prefixIcon: const Icon(Icons.lock_rounded),
                              suffixIcon: IconButton(
                                tooltip: _obscureConfirm ? 'Show password' : 'Hide password',
                                onPressed: _busy
                                    ? null
                                    : () => setState(() => _obscureConfirm = !_obscureConfirm),
                                icon: Icon(
                                  _obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                            validator: (value) => FormValidators.confirmPassword(value, _passCtr.text),
                          ),
                          const SizedBox(height: 24),
                          GradientButton(
                            label: _busy ? 'Creating account…' : 'Sign up',
                            icon: Icons.person_add_rounded,
                            busy: _busy,
                            onPressed: _busy ? null : _register,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
