import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_text_input.dart';
import '../../../../core/widgets/inline_error_message.dart';
import '../../../../core/widgets/primary_button.dart';
import '../viewmodels/auth_providers.dart';
import '../viewmodels/login_state.dart';
import 'register_view.dart';
import 'forgot_password_view.dart';
import '../widgets/login_header.dart';

class LoginView extends ConsumerStatefulWidget {
  const LoginView({super.key});

  @override
  ConsumerState<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();
    final String email = _emailController.text.trim();
    developer.log(
      '[AUTH][UI] Login button pressed email=$email',
      name: 'LoginView',
    );
    print('[AUTH][UI] Login button pressed email=$email');

    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      developer.log('[AUTH][UI] Login form validation failed', name: 'LoginView');
      print('[AUTH][UI] Login form validation failed');
      return;
    }

    await ref
        .read(authViewModelProvider.notifier)
        .login(
          email: _emailController.text,
          password: _passwordController.text,
        );
  }

  Future<void> _goToRegister() async {
    ref.read(authViewModelProvider.notifier).clearError();

    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const RegisterView()));
  }

  Future<void> _goToForgotPassword() async {
    ref.read(authViewModelProvider.notifier).clearError();

    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const ForgotPasswordView()));
  }

  @override
  Widget build(BuildContext context) {
    final LoginState state = ref.watch(authViewModelProvider);

    ref.listen<LoginState>(authViewModelProvider, (previous, next) {
      final String? previousError = previous?.errorMessage;
      final String? nextError = next.errorMessage;
      final ModalRoute<dynamic>? route = ModalRoute.of(context);

      if (route != null && !route.isCurrent) {
        return;
      }

      if (nextError != null && nextError != previousError) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(nextError)));
      }
    });

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[Color(0xFFE9F2F8), Color(0xFFF9FBFD)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const LoginHeader(),
                          const SizedBox(height: 24),
                          AppTextInput(
                            controller: _emailController,
                            label: 'Email',
                            hint: 'usuario@dominio.com',
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            validator: Validators.email,
                          ),
                          const SizedBox(height: 14),
                          AppTextInput(
                            controller: _passwordController,
                            label: 'Password',
                            hint: 'Ingresa tu password',
                            obscureText: true,
                            textInputAction: TextInputAction.done,
                            validator: Validators.password,
                            onFieldSubmitted: (_) => _handleLogin(),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: state.isLoading ? null : _goToForgotPassword,
                              child: const Text('¿Olvidaste tu contraseña?'),
                            ),
                          ),
                          if (state.errorMessage != null) ...<Widget>[
                            const SizedBox(height: 14),
                            InlineErrorMessage(message: state.errorMessage!),
                          ],
                          const SizedBox(height: 20),
                          PrimaryButton(
                            label: 'Iniciar sesion',
                            isLoading: state.isLoading,
                            onPressed: _handleLogin,
                          ),
                          const SizedBox(height: 10),
                          if (!kIsWeb)
                            TextButton(
                              onPressed: state.isLoading ? null : _goToRegister,
                              child: const Text('Crear cuenta movil'),
                            )
                          else
                            Text(
                              'El registro solo esta habilitado en la app movil.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.blueGrey.shade700),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
