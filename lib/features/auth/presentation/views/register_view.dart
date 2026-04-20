import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_text_input.dart';
import '../../../../core/widgets/inline_error_message.dart';
import '../../../../core/widgets/primary_button.dart';
import '../viewmodels/auth_providers.dart';
import '../viewmodels/login_state.dart';

class RegisterView extends ConsumerStatefulWidget {
  const RegisterView({super.key});

  @override
  ConsumerState<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends ConsumerState<RegisterView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _nameValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El nombre es obligatorio';
    }

    if (value.trim().length < 3) {
      return 'El nombre debe tener al menos 3 caracteres';
    }

    return null;
  }

  String? _emailValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El correo es obligatorio';
    }

    const String emailPattern = r'^[^@\s]+@[^@\s]+\.[^@\s]+$';
    if (!RegExp(emailPattern).hasMatch(value.trim())) {
      return 'Ingresa un correo valido';
    }

    return null;
  }

  String? _confirmPasswordValidator(String? value) {
    final String? passwordError = _passwordValidator(value);
    if (passwordError != null) {
      return passwordError;
    }

    if (value != _passwordController.text) {
      return 'Las contrasenas no coinciden';
    }

    return null;
  }

  String? _passwordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contrasena es obligatoria';
    }

    if (value.length < 6) {
      return 'La contrasena debe tener al menos 6 caracteres';
    }

    return null;
  }

  Future<void> _handleRegister() async {
    FocusScope.of(context).unfocus();

    final FormState? formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    await ref
        .read(authViewModelProvider.notifier)
        .register(
          name: _nameController.text,
          email: _emailController.text,
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Scaffold(
        appBar: AppBar(title: const Text('Registro no disponible')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'El registro esta habilitado solo para usuarios de la app movil.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
      );
    }

    final LoginState state = ref.watch(authViewModelProvider);

    ref.listen<LoginState>(authViewModelProvider, (previous, next) {
      final bool wasAuthenticated = previous?.isAuthenticated ?? false;
      if (!wasAuthenticated && next.isAuthenticated && mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta movil')),
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
                          Text(
                            'Registro movil',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Esta cuenta quedara habilitada para uso movil.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.blueGrey.shade700),
                          ),
                          const SizedBox(height: 24),
                          AppTextInput(
                            controller: _nameController,
                            label: 'Nombre completo',
                            hint: 'Tu nombre',
                            textInputAction: TextInputAction.next,
                            validator: _nameValidator,
                          ),
                          const SizedBox(height: 14),
                          AppTextInput(
                            controller: _emailController,
                            label: 'Email',
                            hint: 'usuario@dominio.com',
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            validator: _emailValidator,
                          ),
                          const SizedBox(height: 14),
                          AppTextInput(
                            controller: _passwordController,
                            label: 'Password',
                            hint: 'Crea tu password',
                            obscureText: true,
                            textInputAction: TextInputAction.next,
                            validator: _passwordValidator,
                          ),
                          const SizedBox(height: 14),
                          AppTextInput(
                            controller: _confirmPasswordController,
                            label: 'Confirmar password',
                            hint: 'Repite tu password',
                            obscureText: true,
                            textInputAction: TextInputAction.done,
                            validator: _confirmPasswordValidator,
                            onFieldSubmitted: (_) => _handleRegister(),
                          ),
                          if (state.errorMessage != null) ...<Widget>[
                            const SizedBox(height: 14),
                            InlineErrorMessage(message: state.errorMessage!),
                          ],
                          const SizedBox(height: 20),
                          PrimaryButton(
                            label: 'Crear cuenta e ingresar',
                            isLoading: state.isLoading,
                            onPressed: _handleRegister,
                          ),
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: state.isLoading
                                ? null
                                : () => Navigator.of(context).maybePop(),
                            child: const Text(
                              'Ya tengo cuenta, volver al login',
                            ),
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
