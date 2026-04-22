import 'package:flutter/material.dart';

class MobileBottomNavBar extends StatelessWidget {
  const MobileBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      destinations: const <NavigationDestination>[
        NavigationDestination(
          icon: Icon(Icons.playlist_add_check_circle_outlined),
          selectedIcon: Icon(Icons.playlist_add_check_circle_rounded),
          label: 'Iniciar trámite',
        ),
        NavigationDestination(
          icon: Icon(Icons.list_alt_outlined),
          selectedIcon: Icon(Icons.list_alt_rounded),
          label: 'Mis trámites',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline_rounded),
          selectedIcon: Icon(Icons.person_rounded),
          label: 'Perfil',
        ),
      ],
    );
  }
}