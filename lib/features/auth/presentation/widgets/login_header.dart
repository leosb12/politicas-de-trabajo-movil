import 'package:flutter/material.dart';

class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Column(
      children: <Widget>[
        Container(
          height: 72,
          width: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: <Color>[colors.primary, colors.secondary],
            ),
          ),
          child: const Icon(
            Icons.lock_open_rounded,
            color: Colors.white,
            size: 36,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Ingreso movil',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          'Inicia sesion para continuar con el workflow.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.blueGrey.shade700,
              ),
        ),
      ],
    );
  }
}
