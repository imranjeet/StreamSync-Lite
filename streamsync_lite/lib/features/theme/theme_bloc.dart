import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/di/injection.dart';
import 'theme_state.dart';
import 'theme_event.dart';

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  final SharedPreferences _prefs = getIt<SharedPreferences>();

  ThemeBloc() : super(const ThemeInitial(ThemeMode.system)) {
    on<ThemeLoadRequested>(_onLoadTheme);
    on<ThemeToggleRequested>(_onToggleTheme);
    on<ThemeModeChanged>(_onThemeModeChanged);
    
    // Load theme on initialization
    add(ThemeLoadRequested());
  }

  void _onLoadTheme(ThemeLoadRequested event, Emitter<ThemeState> emit) async {
    final themeModeStr = _prefs.getString('theme_mode');
    ThemeMode mode;
    
    if (themeModeStr == 'dark') {
      mode = ThemeMode.dark;
    } else if (themeModeStr == 'light') {
      mode = ThemeMode.light;
    } else {
      mode = ThemeMode.system;
    }
    
    emit(ThemeLoaded(mode));
  }

  void _onToggleTheme(ThemeToggleRequested event, Emitter<ThemeState> emit) async {
    final currentState = state;
    ThemeMode newMode;
    
    if (currentState is ThemeLoaded) {
      // Toggle between light and dark (skip system)
      if (currentState.themeMode == ThemeMode.dark) {
        newMode = ThemeMode.light;
      } else {
        newMode = ThemeMode.dark;
      }
    } else {
      // Default to dark if initial state
      newMode = ThemeMode.dark;
    }
    
    await _prefs.setString('theme_mode', newMode == ThemeMode.dark ? 'dark' : 'light');
    emit(ThemeLoaded(newMode));
  }

  void _onThemeModeChanged(ThemeModeChanged event, Emitter<ThemeState> emit) async {
    String? modeStr;
    if (event.mode == ThemeMode.dark) {
      modeStr = 'dark';
    } else if (event.mode == ThemeMode.light) {
      modeStr = 'light';
    } else {
      modeStr = null; // system
    }
    
    if (modeStr != null) {
      await _prefs.setString('theme_mode', modeStr);
    } else {
      await _prefs.remove('theme_mode');
    }
    
    emit(ThemeLoaded(event.mode));
  }
}

