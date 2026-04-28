import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_text_input.dart';
import '../../../../core/widgets/inline_error_message.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../auth/presentation/viewmodels/auth_providers.dart';
import '../../../auth/presentation/viewmodels/login_state.dart';
import '../viewmodels/perfil_providers.dart';
import '../widgets/perfil_header_card.dart';
import '../widgets/perfil_info_tile.dart';

class PerfilView extends ConsumerStatefulWidget {
  const PerfilView({super.key});

  @override
  ConsumerState<PerfilView> createState() => _PerfilViewState();
}

class _PerfilViewState extends ConsumerState<PerfilView> {
  String? _requestedUserId;
  final GlobalKey<FormState> _changePasswordFormKey = GlobalKey<FormState>();
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _passwordValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'La contrasena es obligatoria';
    }

    if (value.trim().length < 6) {
      return 'La contrasena debe tener al menos 6 caracteres';
    }

    return null;
  }

  String? _confirmPasswordValidator(String? value) {
    final String? passwordError = _passwordValidator(value);
    if (passwordError != null) {
      return passwordError;
    }

    if (value != _newPasswordController.text) {
      return 'Las contrasenas no coinciden';
    }

    return null;
  }

  Future<void> _handleChangePassword() async {
    FocusScope.of(context).unfocus();

    final FormState? formState = _changePasswordFormKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    final authState = ref.read(authViewModelProvider);
    final String correo = authState.authenticatedUser?.correo.trim() ?? '';
    if (correo.isEmpty) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo identificar el correo actual.'),
        ),
      );
      return;
    }

    final bool success = await ref
        .read(authViewModelProvider.notifier)
        .changePassword(
          correo: correo,
          passwordActual: _currentPasswordController.text,
          nuevaContrasena: _newPasswordController.text,
          confirmarNuevaContrasena: _confirmPasswordController.text,
        );

    if (!mounted) {
      return;
    }

    if (success) {
      _changePasswordFormKey.currentState?.reset();
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contrasena actualizada correctamente.')),
      );
    }
  }

  Future<void> _confirmarCerrarSesion(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Cerrar sesion'),
          content: const Text('Seguro que quieres cerrar sesion?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Cerrar sesion'),
            ),
          ],
        );
      },
    );

    if (confirmar == true) {
      await ref.read(authViewModelProvider.notifier).logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(perfilViewModelProvider);
    final viewModel = ref.read(perfilViewModelProvider.notifier);
    final authState = ref.watch(authViewModelProvider);

    ref.listen<LoginState>(authViewModelProvider, (previous, next) {
      final String? previousError = previous?.errorMessage;
      final String? nextError = next.errorMessage;
      if (nextError != null && nextError != previousError && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(nextError)));
      }
    });

    final String userId = authState.authenticatedUser?.id.trim() ?? '';

    if (userId.isNotEmpty && _requestedUserId != userId && !state.isLoading) {
      _requestedUserId = userId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }

        viewModel.cargarPerfil(usuarioId: userId);
      });
    }

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.error_outline_rounded, size: 56),
              const SizedBox(height: 12),
              Text(state.errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: userId.isEmpty
                    ? null
                    : () {
                        _requestedUserId = userId;
                        viewModel.cargarPerfil(usuarioId: userId);
                      },
                child: const Text('Reintentar'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _confirmarCerrarSesion(context, ref),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Cerrar sesion'),
              ),
            ],
          ),
        ),
      );
    }

    if (userId.isEmpty || state.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.person_off_outlined, size: 56),
              const SizedBox(height: 12),
              Text(
                userId.isEmpty
                    ? 'No se pudo identificar al usuario actual.'
                    : 'No hay datos de perfil disponibles.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: userId.isEmpty
                    ? null
                    : () {
                        _requestedUserId = userId;
                        viewModel.cargarPerfil(usuarioId: userId);
                      },
                child: const Text('Actualizar'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _confirmarCerrarSesion(context, ref),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Cerrar sesion'),
              ),
            ],
          ),
        ),
      );
    }

    final perfil = state.perfil!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        PerfilHeaderCard(perfil: perfil),
        const SizedBox(height: 14),
        PerfilInfoTile(label: 'ID', value: perfil.usuarioId),
        PerfilInfoTile(label: 'Rol', value: perfil.rol),
        if (state.mostrarDepartamento)
          PerfilInfoTile(
            label: 'Departamento',
            value:
                (perfil.departamento == null ||
                    perfil.departamento!.trim().isEmpty)
                ? 'Sin departamento'
                : perfil.departamento!,
          ),
        const SizedBox(height: 24),
        Form(
          key: _changePasswordFormKey,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Cambiar contrasena',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  AppTextInput(
                    controller: _currentPasswordController,
                    label: 'Contrasena actual',
                    obscureText: true,
                    textInputAction: TextInputAction.next,
                    validator: _passwordValidator,
                  ),
                  const SizedBox(height: 14),
                  AppTextInput(
                    controller: _newPasswordController,
                    label: 'Nueva contrasena',
                    obscureText: true,
                    textInputAction: TextInputAction.next,
                    validator: _passwordValidator,
                  ),
                  const SizedBox(height: 14),
                  AppTextInput(
                    controller: _confirmPasswordController,
                    label: 'Confirmar nueva contrasena',
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    validator: _confirmPasswordValidator,
                    onFieldSubmitted: (_) => _handleChangePassword(),
                  ),
                  if (authState.errorMessage != null) ...<Widget>[
                    const SizedBox(height: 14),
                    InlineErrorMessage(message: authState.errorMessage!),
                  ],
                  const SizedBox(height: 16),
                  PrimaryButton(
                    label: 'Actualizar contrasena',
                    isLoading: authState.isLoading,
                    onPressed: _handleChangePassword,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () => _confirmarCerrarSesion(context, ref),
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Cerrar sesion'),
        ),
      ],
    );
  }
}
