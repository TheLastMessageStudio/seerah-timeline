import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_state.dart';

/// État global de l'application (chargement des données, favoris, progression, Premium).
final appStateProvider = ChangeNotifierProvider<AppState>((ref) {
  final state = AppState();
  state.init();
  return state;
});
