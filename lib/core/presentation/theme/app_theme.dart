import 'package:flutter/material.dart';
import 'package:gallery_triage_app/core/presentation/theme/triage_colors.dart';

/// Paleta base do app. Estes valores são candidatos a migrar para o pacote
/// `design_system` — são neutros e servem a qualquer um dos três projetos.
/// As cores de estado ficam fora daqui, em [TriageColors].
abstract final class _Palette {
  static const canvas = Color(0xFF0E1013);
  static const surface1 = Color(0xFF16181D);
  static const surface2 = Color(0xFF1E2127);
  static const surface3 = Color(0xFF272B33);
  static const line = Color(0xFF2B303A);
  static const text = Color(0xFFE9ECF1);
  static const textMuted = Color(0xFF98A0AC);
  static const textFaint = Color(0xFF6B727D);
}

abstract final class AppTheme {
  /// Tema único do app. Não há variante clara nesta versão: a triagem
  /// julga imagem, e superfície clara ao redor do card altera a percepção
  /// de exposição e saturação do conteúdo.
  static ThemeData get dark {
    const scheme = ColorScheme.dark(
      surface: _Palette.canvas,
      surfaceContainerLow: _Palette.surface1,
      surfaceContainer: _Palette.surface2,
      surfaceContainerHigh: _Palette.surface3,
      onSurface: _Palette.text,
      onSurfaceVariant: _Palette.textMuted,
      outline: _Palette.line,
      outlineVariant: _Palette.line,
      primary: Color(0xFF4C8DFF),
      onPrimary: Color(0xFF06152E),
      secondary: Color(0xFF2FBF87),
      onSecondary: Color(0xFF06251A),
      // Mesmo hex de `stateMarkedForDeletion`, de propósito: dois
      // vermelhos ligeiramente diferentes na mesma tela leem como bug.
      // O papel continua distinto — ver nota em [TriageColors].
      error: Color(0xFFF2554B),
      onError: Color(0xFF2A0B08),
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: _Palette.canvas,
      visualDensity: VisualDensity.standard,
    );

    return base.copyWith(
      extensions: const <ThemeExtension<dynamic>>[
        TriageColors.dark,
      ],
      textTheme: _textTheme(base.textTheme),
      dividerTheme: const DividerThemeData(
        color: _Palette.line,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: _Palette.canvas,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        toolbarHeight: 52,
        titleTextStyle: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.15,
          color: _Palette.text,
        ),
      ),
      cardTheme: const CardThemeData(
        color: _Palette.surface1,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: _Palette.surface2,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: _Palette.text,
        ),
        contentTextStyle: TextStyle(
          fontSize: 13.5,
          height: 1.5,
          color: _Palette.textMuted,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: _Palette.surface2,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        showDragHandle: true,
        dragHandleColor: Color(0xFF3B414C),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(42),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(42),
          shape: const StadiumBorder(),
          side: const BorderSide(color: _Palette.line),
          foregroundColor: _Palette.textMuted,
        ),
      ),
      iconTheme: const IconThemeData(color: _Palette.text, size: 24),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: _Palette.surface3,
        contentTextStyle: TextStyle(fontSize: 13.5, color: _Palette.text),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static TextTheme _textTheme(TextTheme base) {
    return base
        .copyWith(
          headlineSmall: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.4,
          ),
          titleSmall: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w300,
            letterSpacing: -0.15,
          ),
          titleMedium: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.15,
          ),
          titleLarge: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.15,
          ),
          bodySmall: const TextStyle(fontSize: 12, color: _Palette.textMuted),
          bodyMedium: const TextStyle(fontSize: 16, height: 1.5),
          bodyLarge: const TextStyle(fontSize: 20, height: 1.5),
          labelSmall: const TextStyle(fontSize: 11, color: _Palette.textFaint),
        )
        .apply(bodyColor: _Palette.text, displayColor: _Palette.text);
  }
}