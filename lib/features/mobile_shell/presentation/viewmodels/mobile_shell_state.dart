class MobileShellState {
  const MobileShellState({required this.currentIndex});

  factory MobileShellState.initial() {
    return const MobileShellState(currentIndex: 0);
  }

  final int currentIndex;

  MobileShellState copyWith({int? currentIndex}) {
    return MobileShellState(currentIndex: currentIndex ?? this.currentIndex);
  }
}