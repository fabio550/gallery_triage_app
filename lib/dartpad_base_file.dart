//---1.IMPORTS
//---2.MAIN
//---3.APP-ROUTER-PROVIDER
//---4.ROUTES
//---5.APP-THEME
//---6.TRIAGE-VISUAL-STATE
//---7.TRIAGE-COLORS
//---8.TRIAGE-DECISION
//---9.PROGRESS-BAR
//---10.PROGRESS-CIRCULAR
//---11.PROGRESS-CIRCLE-PAINTER
//---12.MEDIA-ITEM-ENTITY
//---13.CATEGORY-GRANULARITY
//---14.CATEGORY-SUMMARY
//---15.CATEGORY-LIST
//---16.CATEGORY-TILE
//---17.GRANULARITY-PICKER-SHEET
//---18.GRANULARITY-SELECTOR
//---19.INFO-STATS-CARD
//---20.TOTAL-ITEMS-INFO
//---21.DASHBOARD-PAGE
//---22.MOCK-CATEGORIES
//---23.TRIAGE-PAGE
//---24.TRIAGE-CAROUSEL
//---25.CAROUSEL-THUMB
//---26.TRIAGE-CARD
//---27.MEDIA-CARD
//---28.SWIPE-OVERLAY
//---29.MOCK-MEDIA-ITEMS
//---30.TRIAGE-SESSION-NOTIFIER
//---31.TRIAGE-SESSION-STATE
//---32.MEDIA-PLACEHOLDER
//---33.TRIAGE-ACTION-BAR
//---34.UNDO-ENTRY
//--------------------------------------------------//1.IMPORTS
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;
import 'package:flutter/physics.dart';
//-------------------------------------------------//2.MAIN
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    ProviderScope(
      child: Consumer(
        builder: (context, ref, _) {
          final router = ref.watch(appRouterProvider);

          return MaterialApp.router(
            title: 'Driver Analytics',
            debugShowCheckedModeBanner: false,
            themeMode: ThemeMode.dark,
            theme: AppTheme.dark,
            routerConfig: router,
          );
        },
      ),
    ),
  );
}
//-------------------------------------------------//3.APP-ROUTER-PROVIDER
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: routes,
  );
});
//-------------------------------------------------//4.ROUTES
final routes = [
  GoRoute(
    path: '/',
    builder: (context, state) => const DashboardPage(),
  ),
  GoRoute(
    path: '/triage-page',
    builder: (context, state) {
      final category = state.extra as CategorySummary;

      return TriagePage(category: category);
    }
  ),
];
//-------------------------------------------------//5.APP-THEME

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

  /// Cada estilo parte do correspondente em [base] para preservar família e
  /// `height` resolvidos por `Typography`. Sem `apply()`: ele roda depois do
  /// `copyWith` e sobrescreveria as cores definidas aqui — foi o que apagava
  /// o cinza de `bodySmall` e `labelSmall`.
  static TextTheme _textTheme(TextTheme base) {
    // Contadores mudam a cada swipe. Com algarismos proporcionais a largura
    // do número oscila e o texto treme; `tnum` fixa o avanço.
    const tabular = <FontFeature>[FontFeature.tabularFigures()];

    return base.copyWith(
      displaySmall: base.displaySmall!.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w300,
        letterSpacing: -0.8,
        color: _Palette.text,
        fontFeatures: tabular,
      ),
      headlineSmall: base.headlineSmall!.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.4,
        color: _Palette.text,
      ),
      titleMedium: base.titleMedium!.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.15,
        color: _Palette.text,
      ),
      titleSmall: base.titleSmall!.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
        color: _Palette.text,
      ),
      bodyMedium: base.bodyMedium!.copyWith(
        fontSize: 14,
        height: 1.5,
        color: _Palette.text,
      ),
      bodySmall: base.bodySmall!.copyWith(
        fontSize: 12,
        color: _Palette.textMuted,
        fontFeatures: tabular,
      ),
      labelLarge: base.labelLarge!.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: _Palette.text,
      ),
      labelSmall: base.labelSmall!.copyWith(
        fontSize: 11,
        letterSpacing: 0,
        color: _Palette.textFaint,
        fontFeatures: tabular,
      ),
    );
  }
}
//-------------------------------------------------//6.TRIAGE-VISUAL-STATE
@immutable
class TriageColors extends ThemeExtension<TriageColors> {
  const TriageColors({
    required this.stateMarkedForDeletion,
    required this.stateClassified,
    required this.stateKept,
    required this.stateUndecided,
  });

  /// Prioridade 1 — item na fila de exclusão da categoria ativa.
  final Color stateMarkedForDeletion;

  /// Prioridade 2 — item vinculado a um álbum.
  final Color stateClassified;

  /// Prioridade 3 — item mantido sem álbum.
  final Color stateKept;

  /// Prioridade 4 — item ainda não alcançado ou pulado.
  final Color stateUndecided;

  static const dark = TriageColors(
    stateMarkedForDeletion: Color(0xFFF2554B),
    stateClassified: Color(0xFF2FBF87),
    stateKept: Color(0xFF4C8DFF),
    stateUndecided: Color(0xFF5A6270),
  );

  @override
  TriageColors copyWith({
    Color? stateMarkedForDeletion,
    Color? stateClassified,
    Color? stateKept,
    Color? stateUndecided,
  }) {
    return TriageColors(
      stateMarkedForDeletion:
          stateMarkedForDeletion ?? this.stateMarkedForDeletion,
      stateClassified: stateClassified ?? this.stateClassified,
      stateKept: stateKept ?? this.stateKept,
      stateUndecided: stateUndecided ?? this.stateUndecided,
    );
  }

  @override
  TriageColors lerp(covariant TriageColors? other, double t) {
    if (other == null) return this;
    return TriageColors(
      stateMarkedForDeletion: Color.lerp(
        stateMarkedForDeletion,
        other.stateMarkedForDeletion,
        t,
      )!,
      stateClassified: Color.lerp(stateClassified, other.stateClassified, t)!,
      stateKept: Color.lerp(stateKept, other.stateKept, t)!,
      stateUndecided: Color.lerp(stateUndecided, other.stateUndecided, t)!,
    );
  }
}

extension TriageColorsX on BuildContext {
  TriageColors get triageColors => Theme.of(this).extension<TriageColors>()!;
}
//-------------------------------------------------//7.TRIAGE-COLORS
enum TriageVisualState {
  markedForDeletion,
  classified,
  kept,
  undecided;

  static TriageVisualState of(MediaItemEntity item) {
    if (item.isInDeletionQueue) return TriageVisualState.markedForDeletion;
    if (item.isClassified) return TriageVisualState.classified;
    if (item.decision == TriageDecision.kept) return TriageVisualState.kept;
    return TriageVisualState.undecided;
  }

  Color colorIn(TriageColors colors) => switch (this) {
        TriageVisualState.markedForDeletion => colors.stateMarkedForDeletion,
        TriageVisualState.classified => colors.stateClassified,
        TriageVisualState.kept => colors.stateKept,
        TriageVisualState.undecided => colors.stateUndecided,
      };
}
//-------------------------------------------------//8.TRIAGE-DECISION
enum TriageDecision {
  undecided,
  kept,
  markedForDeletion,
}

enum MediaType {
  image,
  video,
}
//-------------------------------------------------//9.PROGRESS-BAR
class ProgressBar extends StatelessWidget {
  final bool showLegend;
  final int totalItems;
  final int classifiedItems;
  final int keptItems;

  const ProgressBar({
    this.showLegend = true,
    required this.totalItems,
    required this.classifiedItems,
    required this.keptItems,
    super.key
  });

  @override
  Widget build(BuildContext context) {

  final color = Theme.of(context).colorScheme;
  final triageColors = context.triageColors;
  final text = Theme.of(context).textTheme;

  final total = totalItems == 0 ? 1 : totalItems;

  final classifiedPercent = classifiedItems / total;
  final keptPercent = keptItems / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            LinearProgressIndicator(
              value: 1,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(
                color.outline,
              ),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            LinearProgressIndicator(
              value: keptPercent.clamp(0.0, 1.0),                
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(
                triageColors.stateKept,
              ),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            LinearProgressIndicator(
              value: classifiedPercent.clamp(0.0, 1.0),                
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(
                triageColors.stateClassified,
              ),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
        SizedBox(height: 12,),
        !showLegend ? SizedBox() : 
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            Text.rich(
              TextSpan(
                text: '●',
                style: text.labelSmall?.copyWith(
                  color: triageColors.stateClassified,
                ),
                children: [
                  TextSpan(
                    text: ' Classificados - ',
                    style: text.labelSmall?.copyWith(
                      color: color.onSurfaceVariant,
                    ),
                  ),
                  TextSpan(
                    text: '$classifiedItems',
                    style: text.labelSmall?.copyWith(
                      color: color.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Text.rich(
              TextSpan(
                text: '●',
                style: text.labelSmall?.copyWith(
                  color: triageColors.stateKept,
                ),
                children: [
                  TextSpan(
                    text: ' Mantidos - ',
                    style: text.labelSmall?.copyWith(
                      color: color.onSurfaceVariant,
                    ),
                  ),
                  TextSpan(
                    text: '$keptItems',
                    style: text.labelSmall?.copyWith(
                      color: color.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Text.rich(
              TextSpan(
                text: '●',
                style: text.labelSmall?.copyWith(
                  color: color.outline,
                ),
                children: [
                  TextSpan(
                    text: ' Não decididos - ',
                    style: text.labelSmall?.copyWith(
                      color: color.onSurfaceVariant,
                    ),
                  ),
                  TextSpan(
                    text: '${total - keptItems}',
                    style: text.labelSmall?.copyWith(
                      color: color.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
//-------------------------------------------------//10.PROGRESS-CIRCULAR

class ProgressCircular extends StatelessWidget {
  final BuildContext context;
  final double progressPercent;
  final Color progressColor;

  const ProgressCircular({
    required this.context,
    required this.progressPercent,
    required this.progressColor,
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 52,
      child: CustomPaint(
        painter: ProgressCirclePainter(
          context: context,
          progressPercent: progressPercent.clamp(0.0, 1.0),
          progressColor: progressColor,
        ),
        child: Center(
          child: Text(
            '${(progressPercent.clamp(0.0, 1.0) * 100).toInt()}%',
          ),
        ),
      ),
    );
  }
}
//-------------------------------------------------//11.PROGRESS-CIRCLE-PAINTER

class ProgressCirclePainter extends CustomPainter {
  final BuildContext context;
  final double progressPercent;
  final Color progressColor;

  const ProgressCirclePainter({
    required this.context,
    required this.progressPercent,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    Paint backgroundPaint = Paint()
      ..color = Theme.of(context).colorScheme.outline
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;

    Paint progressPaint = Paint()
      ..color = progressColor
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(size.center(Offset.zero), size.width / 2, backgroundPaint);

    double angle = 2 * 3.1415926535 * progressPercent;
    canvas.drawArc(
        Rect.fromCircle(center: size.center(Offset.zero), radius: size.width / 2),
        -3.1415926535 / 2, // Começar no topo
        angle,
        false,
        progressPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

//-------------------------------------------------//12.MEDIA-ITEM-ENTITY
/// Sentinela para permitir que [MediaItemEntity.copyWith] escreva `null`
/// em campos opcionais. Sem isso, desclassificar um item (3.2.4) seria
/// indistinguível de "não mexer no álbum".
const Object _unset = Object();

/// Um item indexado — foto ou vídeo (spec 2.2.1).
///
/// O índice local é a fonte da verdade da triagem e não pode ser
/// reconstruído a partir do MediaStore (2.3.2). Metadados de arquivo são
/// cache derivado; `decision`, `albumId` e o snapshot de fila não são.
class MediaItemEntity {
  MediaItemEntity({
    required this.id,
    required this.mediaStoreId,
    required this.fingerprint,
    required this.dateTaken,
    required this.sizeBytes,
    required this.mimeType,
    required this.relativePath,
    required this.mediaType,
    required this.isScreenshot,
    this.durationMs,
    this.decision = TriageDecision.undecided,
    this.albumId,
    this.decidedAt,
    this.preQueueDecision,
    this.preQueueAlbumId,
    this.trashedInSystem = false,
    this.trashedAt,
    this.isAvailable = true,
  })  : assert(
          mediaType == MediaType.video || durationMs == null,
          'durationMs só existe em vídeo',
        ),
        assert(
          albumId == null ||
              decision == TriageDecision.kept ||
              decision == TriageDecision.markedForDeletion,
          'classificado implica mantido (3.2.1); na fila o vínculo é '
          'preservado (3.2.5)',
        );

  /// UUID gerado pelo app. `MediaStore._ID` não serve como chave: muda
  /// quando o arquivo é movido, o volume é remontado ou o MediaStore é
  /// reconstruído (2.5.1).
  final String id;

  final int mediaStoreId;

  /// Hash de `dateTaken` + `sizeBytes` + nome do arquivo (2.5.3).
  /// Não lê o conteúdo do arquivo.
  final String fingerprint;

  /// `DATE_TAKEN` do MediaStore, com fallback para `DATE_MODIFIED`.
  final DateTime dateTaken;

  final int sizeBytes;
  final String mimeType;
  final String relativePath;
  final MediaType mediaType;

  /// Derivado de [relativePath] na indexação, não em tempo de consulta.
  final bool isScreenshot;

  final int? durationMs;

  final TriageDecision decision;

  /// `null` = não classificado. Um item pertence a no máximo um álbum.
  final String? albumId;

  final DateTime? decidedAt;

  /// Snapshot gravado ao entrar na fila de exclusão (2.2.4). Permite
  /// restaurar o estado exato ao descartar as marcações (3.5.3) e na
  /// limpeza de inicialização (5.4.1).
  final TriageDecision? preQueueDecision;
  final String? preQueueAlbumId;

  /// `IS_TRASHED` do MediaStore. Item retido pelo sistema some das
  /// consultas normais mas não é órfão (5.5.3).
  final bool trashedInSystem;
  final DateTime? trashedAt;

  /// `false` quando o volume está desmontado. O registro é preservado —
  /// ausência de mídia não autoriza descartar a triagem (5.5.6).
  final bool isAvailable;

  /// Eixo B do modelo de estados (3.1.2). Não existe campo booleano
  /// espelhando isto: dois campos podem divergir (2.2.3).
  bool get isClassified => albumId != null;

  bool get isInDeletionQueue => decision == TriageDecision.markedForDeletion;

  bool get isVideo => mediaType == MediaType.video;

  /// Fora de qualquer recorte, contador ou denominador (6.1.10).
  bool get isCountable => !trashedInSystem && isAvailable;

  // --- Transições (3.4) ---------------------------------------------------

  /// Swipe direita / Manter. Não toca no álbum.
  MediaItemEntity keep(DateTime at) => copyWith(
        decision: TriageDecision.kept,
        decidedAt: at,
      );

  /// Selecionar álbum diferente do atual. Promove a decisão a `kept`
  /// (3.2.1) e substitui o vínculo anterior sem confirmação (3.2.3).
  MediaItemEntity assignToAlbum(String newAlbumId, DateTime at) => copyWith(
        decision: TriageDecision.kept,
        albumId: newAlbumId,
        decidedAt: at,
      );

  /// Tocar no álbum em que o item já está. A decisão permanece
  /// inalterada e o cursor não avança (3.2.4).
  MediaItemEntity unassignAlbum() => copyWith(albumId: null);

  /// Swipe esquerda / Excluir. Preserva `albumId` e congela o estado
  /// anterior (3.2.5). Idempotente: reentrar na fila não sobrescreve o
  /// snapshot, senão o restore devolveria o próprio estado de fila.
  MediaItemEntity markForDeletion(DateTime at) {
    if (isInDeletionQueue) return this;
    return copyWith(
      decision: TriageDecision.markedForDeletion,
      preQueueDecision: decision,
      preQueueAlbumId: albumId,
      decidedAt: at,
    );
  }

  /// Desmarcar na Revisão (6.3.4), descartar marcações na saída (3.5.3)
  /// ou limpeza de inicialização (5.4.1).
  MediaItemEntity restoreFromQueue() {
    if (!isInDeletionQueue) return this;
    return copyWith(
      decision: preQueueDecision ?? TriageDecision.undecided,
      albumId: preQueueAlbumId,
      preQueueDecision: null,
      preQueueAlbumId: null,
    );
  }

  /// Confirmação de `createTrashRequest` com `RESULT_OK`. Mantém
  /// decisão e álbum intactos para a restauração de 5.5.5 (3.6.1).
  MediaItemEntity moveToSystemTrash(DateTime at) => copyWith(
        trashedInSystem: true,
        trashedAt: at,
      );

  /// Item reapareceu na consulta normal do MediaStore: foi restaurado
  /// pelo usuário na lixeira do sistema. Volta com decisão e álbum
  /// originais, não como item novo (5.5.5).
  MediaItemEntity restoreFromSystemTrash() => copyWith(
        trashedInSystem: false,
        trashedAt: null,
      );

  /// Correspondência por fingerprint na sincronização: o registro é o
  /// mesmo, só o `_ID` do MediaStore mudou (2.5.4).
  MediaItemEntity rebindMediaStoreId(int newMediaStoreId) =>
      copyWith(mediaStoreId: newMediaStoreId);

  MediaItemEntity copyWith({
    int? mediaStoreId,
    String? fingerprint,
    DateTime? dateTaken,
    int? sizeBytes,
    String? mimeType,
    String? relativePath,
    bool? isScreenshot,
    Object? durationMs = _unset,
    TriageDecision? decision,
    Object? albumId = _unset,
    Object? decidedAt = _unset,
    Object? preQueueDecision = _unset,
    Object? preQueueAlbumId = _unset,
    bool? trashedInSystem,
    Object? trashedAt = _unset,
    bool? isAvailable,
  }) {
    return MediaItemEntity(
      id: id,
      mediaStoreId: mediaStoreId ?? this.mediaStoreId,
      fingerprint: fingerprint ?? this.fingerprint,
      dateTaken: dateTaken ?? this.dateTaken,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      mimeType: mimeType ?? this.mimeType,
      relativePath: relativePath ?? this.relativePath,
      mediaType: mediaType,
      isScreenshot: isScreenshot ?? this.isScreenshot,
      durationMs:
          durationMs == _unset ? this.durationMs : durationMs as int?,
      decision: decision ?? this.decision,
      albumId: albumId == _unset ? this.albumId : albumId as String?,
      decidedAt:
          decidedAt == _unset ? this.decidedAt : decidedAt as DateTime?,
      preQueueDecision: preQueueDecision == _unset
          ? this.preQueueDecision
          : preQueueDecision as TriageDecision?,
      preQueueAlbumId: preQueueAlbumId == _unset
          ? this.preQueueAlbumId
          : preQueueAlbumId as String?,
      trashedInSystem: trashedInSystem ?? this.trashedInSystem,
      trashedAt:
          trashedAt == _unset ? this.trashedAt : trashedAt as DateTime?,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MediaItemEntity &&
        other.id == id &&
        other.mediaStoreId == mediaStoreId &&
        other.fingerprint == fingerprint &&
        other.dateTaken == dateTaken &&
        other.sizeBytes == sizeBytes &&
        other.mimeType == mimeType &&
        other.relativePath == relativePath &&
        other.mediaType == mediaType &&
        other.isScreenshot == isScreenshot &&
        other.durationMs == durationMs &&
        other.decision == decision &&
        other.albumId == albumId &&
        other.decidedAt == decidedAt &&
        other.preQueueDecision == preQueueDecision &&
        other.preQueueAlbumId == preQueueAlbumId &&
        other.trashedInSystem == trashedInSystem &&
        other.trashedAt == trashedAt &&
        other.isAvailable == isAvailable;
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        mediaStoreId,
        fingerprint,
        dateTaken,
        sizeBytes,
        mimeType,
        relativePath,
        mediaType,
        isScreenshot,
        durationMs,
        decision,
        albumId,
        decidedAt,
        preQueueDecision,
        preQueueAlbumId,
        trashedInSystem,
        trashedAt,
        isAvailable,
      ]);
}

//-------------------------------------------------//13.CATEGORY-GRANULARITY
enum CategoryGranularity {
  all,
  month,
  year,
  type,
  album,
}
//-------------------------------------------------//13.CATEGORY-SUMMARY
class CategorySummary {
  const CategorySummary({
    required this.ref,
    required this.label,
    required this.totalItems,
    required this.keptItems,
    required this.classifiedItems,
    required this.sizeBytes,
    this.coverItemId,
  }) : assert(
          classifiedItems <= keptItems && keptItems <= totalItems,
          'classificado é subconjunto de mantido (3.2.1)',
        );

  final CategoryRef ref;

  /// Já formatado pela camada de apresentação: "Outubro de 2025".
  /// Depende de locale, por isso não é derivado aqui.
  final String label;

  /// Exclui itens com `trashedInSystem` ou `isAvailable` false (6.1.10).
  final int totalItems;

  /// Inclui os classificados.
  final int keptItems;
  final int classifiedItems;

  final int sizeBytes;
  final String? coverItemId;

  int get undecidedItems => totalItems - keptItems;

  double get keptRatio => totalItems == 0 ? 0 : keptItems / totalItems;
  double get classifiedRatio =>
      totalItems == 0 ? 0 : classifiedItems / totalItems;

  String get countLabel => undecidedItems == 0
      ? '$totalItems itens · tudo decidido'
      : '$totalItems itens · $undecidedItems sem decisão';
}

class CategoryRef {
  const CategoryRef({
    required this.granularity,
    required this.key,
  });

  final CategoryGranularity granularity;
  final String key;

  @override
  bool operator ==(Object other) =>
      other is CategoryRef &&
      other.granularity == granularity &&
      other.key == key;

  @override
  int get hashCode => Object.hash(granularity, key);
}

//-------------------------------------------------//15.CATEGORY-LIST
class CategoryList extends StatelessWidget {
  final List<CategorySummary> categories;
  final CategoryGranularity granularity;
  final ValueChanged<CategorySummary> onCategoryTap;
  
  const CategoryList({
    required this.categories,
    required this.granularity,
    required this.onCategoryTap,
    super.key,
  });
  
    @override
  Widget build(BuildContext context) {
    
    if (categories.isEmpty) return const _EmptyGallery();

    final isAlbum = granularity == CategoryGranularity.album;

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final summary = categories[index];
        return isAlbum ?
          CategoryTile.album(
            summary: summary,
            onTap: () => onCategoryTap(summary),
          ) :
          CategoryTile(
            summary: summary,
            onTap: () => onCategoryTap(summary),
          );
      },
    );
  }
}

class _EmptyGallery extends StatelessWidget {
  const _EmptyGallery();
 
  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 34),
        child: Text(
          'Nenhum item indexado em DCIM ou Pictures/Screenshots.',
          textAlign: TextAlign.center,
          style: text.bodySmall,
        ),
      ),
    );
  }
}
//-------------------------------------------------//16.CATEGORY-TILE
class CategoryTile extends StatelessWidget {
  final CategorySummary summary;
  final VoidCallback onTap;
  final bool _showMetrics;

  const CategoryTile({
    required this.summary,
    required this.onTap,
    super.key,
  }) : _showMetrics = true;

  const CategoryTile.album({
    required this.summary,
    required this.onTap,
    super.key,
  }) : _showMetrics = false;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final triageColors = context.triageColors;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          children: [
            _Cover(itemId: summary.coverItemId),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    summary.label,
                    style: text.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_showMetrics) ...[
                    const SizedBox(height: 7),
                    Padding(
                      padding: EdgeInsetsGeometry.only(right: 16),
                      child: ProgressBar(
                        showLegend: false,
                        totalItems: summary.totalItems,
                        classifiedItems: summary.classifiedItems,
                        keptItems: summary.keptItems,
                      ),
                    )
                  ] else
                    const SizedBox(height: 3),
                  Text(summary.countLabel, style: text.titleSmall),
                ],
              ),
            ),
            const SizedBox(width: 12),
            (_showMetrics) ?
              ProgressCircular(
                context: context,
                progressPercent: summary.keptItems / summary.totalItems,
                progressColor: triageColors.stateKept,
              ) : Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
            Divider(),
          ],
        ),
      ),
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover({this.itemId});
 
  final String? itemId;
 
  @override
  Widget build(BuildContext context) {
    // Placeholder até o provider de miniatura existir. Falha de leitura
    // não impede a linha de funcionar (§7).
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
//-------------------------------------------------//17.GRANULARITY-PICKER-SHEET
class GranularityPickerSheet extends StatelessWidget {
  const GranularityPickerSheet({required this.selected, super.key});

  final CategoryGranularity selected;

  static Future<CategoryGranularity?> show(
    BuildContext context, {
    required CategoryGranularity selected,
  }) {
    return showModalBottomSheet<CategoryGranularity>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => GranularityPickerSheet(selected: selected),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Text('Agrupar por', style: text.titleMedium),
          ),
          for (final granularity in CategoryGranularity.values)
            ListTile(
              title: Text(granularity.label, style: text.bodyMedium),
              trailing: granularity == selected
                  ? Icon(Icons.check, color: colors.primary)
                  : null,
              onTap: () => Navigator.pop(context, granularity),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
//-------------------------------------------------//18.GRANULARITY-SELECTOR
class GranularitySelector extends StatelessWidget {
  const GranularitySelector({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final CategoryGranularity selected;
  final ValueChanged<CategoryGranularity> onChanged;

  Future<void> _open(BuildContext context) async {
    final choice = await GranularityPickerSheet.show(
      context,
      selected: selected,
    );
    if (choice != null && choice != selected) onChanged(choice);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return SizedBox(
      width: double.infinity,
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: colors.outline),
        ),
        child: InkWell(
          onTap: () => _open(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Agrupar por ${selected.label.toLowerCase()}',
                    style: text.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.expand_more, size: 20, color: colors.onSurfaceVariant),
              ],
            ),
          ),
        ),
      )
    );
  }
}

extension CategoryGranularityLabel on CategoryGranularity {
  String get label => switch (this) {
        CategoryGranularity.all => 'Todos os itens',
        CategoryGranularity.month => 'Mês',
        CategoryGranularity.year => 'Ano',
        CategoryGranularity.type => 'Tipo',
        CategoryGranularity.album => 'Álbuns',
      };
}
//-------------------------------------------------//19.INFO-STATS-CARD
class InfoStatsCard extends StatelessWidget {
    final int totalItems;
    final double totalSizeGb;
    final int classifiedItems;
    final int keptItems;

  const InfoStatsCard({
    required this.totalItems,
    required this.totalSizeGb,
    required this.classifiedItems,
    required this.keptItems,
    super.key,
  });
  
  @override
  Widget build(BuildContext context) {
    
    final triageColors = context.triageColors;
    final classifiedIPercent = classifiedItems / totalItems;
    final keptPercent = keptItems / totalItems;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TotalItemsInfo(
                    totalItems: totalItems,
                    totalSizeGb: totalSizeGb,
                  ),
                  SizedBox(height: 8,),
                  Padding(
                    padding: EdgeInsetsGeometry.only(right: 16),
                    child: ProgressBar(
                      totalItems: totalItems,
                      classifiedItems: classifiedItems,
                      keptItems: keptItems,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 20,),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ProgressCircular(
                  context: context,
                  progressPercent: classifiedIPercent,
                  progressColor: triageColors.stateClassified,
                ),
                SizedBox(height: 20,),
                ProgressCircular(
                  context: context,
                  progressPercent: keptPercent,
                  progressColor: triageColors.stateKept,
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
//-------------------------------------------------//20.TOTAL-ITEMS-INFO
class TotalItemsInfo extends StatelessWidget {
  final int totalItems;
  final double totalSizeGb;

  const TotalItemsInfo({
    required this.totalItems,
    required this.totalSizeGb,
    super.key
  });

  @override
  Widget build(BuildContext context) {

    final text = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: totalItems.toString().replaceAllMapped(
              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), 
              (m) => '${m[1]}.'
            ).toString(),
            style: text.titleLarge,
            children: [
              TextSpan(
                text: ' itens',
                style: text.bodyMedium?.copyWith(
                  color: color.onSurfaceVariant, 
                ),
              )
            ]
          )
        ),
        Text(
          '${totalSizeGb.toStringAsFixed(1)} GB',
          style: text.bodyMedium?.copyWith(
            color: color.onSurfaceVariant, 
          ),
        ),
      ],
    );
  }
}
//-------------------------------------------------//21.DASHBOARD-PAGE

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  
  CategoryGranularity _granularity = CategoryGranularity.all;

  @override
  Widget build(BuildContext context) {
    
    // O card geral é a categoria "Todos os itens" — mesma fonte que
    // MockCategories.of(album/mês/ano/tipo), nunca um número à parte.
    final overall = MockCategories.of(CategoryGranularity.all).first;
    final categories = MockCategories.of(_granularity);
    
    return Scaffold(
      appBar: AppBar(title: const Text('Triagem')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: InfoStatsCard(
              totalItems: overall.totalItems,
              totalSizeGb: overall.sizeBytes / (1024 * 1024 * 1024),
              classifiedItems: overall.classifiedItems,
              keptItems: overall.keptItems,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GranularitySelector(
              selected: _granularity,
              onChanged: (value) => setState(() => _granularity = value),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: CategoryList(
                categories: categories,
                granularity: _granularity,
                onCategoryTap: (summary) =>
                    context.push('/triage-page', extra: summary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
//-------------------------------------------------//22.MOCK-CATEGORIES
const _monthNames = [
  '',
  'Janeiro',
  'Fevereiro',
  'Março',
  'Abril',
  'Maio',
  'Junho',
  'Julho',
  'Agosto',
  'Setembro',
  'Outubro',
  'Novembro',
  'Dezembro',
];

/// Deriva [CategorySummary] a partir de [MockMediaItems.all]. Nenhum
/// total é digitado — é a mesma garantia que o `TriageRepository` real
/// (2.4.2) vai dar via `COUNT` indexado (8.3).
abstract final class MockCategories {
  static List<CategorySummary> of(CategoryGranularity granularity) {
    return switch (granularity) {
      CategoryGranularity.all => _all(),
      CategoryGranularity.month => _months(),
      CategoryGranularity.year => _years(),
      CategoryGranularity.type => _types(),
      CategoryGranularity.album => _albums(),
    };
  }

  static List<CategorySummary> _all() {
    final summary = _summarize(
      CategoryRef(granularity: CategoryGranularity.all, key: 'all'),
      'Todos os itens',
      MockMediaItems.all,
    );
    return summary == null ? const [] : [summary];
  }

  static List<CategorySummary> _months() {
    final keys = MockMediaItems.all
        .map((i) => MockMediaItems.monthKey(i.dateTaken))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a)); // 6.1.8: temporal decrescente.

    return keys
        .map((key) {
          final parts = key.split('-');
          final month = int.parse(parts[1]);
          final label = '${_monthNames[month]} de ${parts[0]}';
          return _summarize(
            CategoryRef(granularity: CategoryGranularity.month, key: key),
            label,
            MockMediaItems.byMonth(key),
          );
        })
        .whereType<CategorySummary>()
        .toList();
  }

  static List<CategorySummary> _years() {
    final keys = MockMediaItems.all
        .map((i) => i.dateTaken.year.toString())
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    return keys
        .map((key) => _summarize(
              CategoryRef(granularity: CategoryGranularity.year, key: key),
              key,
              MockMediaItems.byYear(key),
            ))
        .whereType<CategorySummary>()
        .toList();
  }

  static List<CategorySummary> _types() {
    // Ordem fixa (6.1.8). Mesmo padrão skip-se-vazio dos demais
    // granularidades: um tipo sem item contável não vira tile.
    return [
      _summarize(
        CategoryRef(granularity: CategoryGranularity.type, key: 'photos'),
        'Fotos',
        MockMediaItems.photos(),
      ),
      _summarize(
        CategoryRef(
            granularity: CategoryGranularity.type, key: 'screenshots'),
        'Screenshots',
        MockMediaItems.screenshots(),
      ),
      _summarize(
        CategoryRef(granularity: CategoryGranularity.type, key: 'images'),
        'Imagens',
        MockMediaItems.images(),
      ),
      _summarize(
        CategoryRef(granularity: CategoryGranularity.type, key: 'videos'),
        'Vídeos',
        MockMediaItems.videos(),
      ),
    ].whereType<CategorySummary>().toList();
  }

  static List<CategorySummary> _albums() {
    final ids = MockMediaItems.all
        .map((i) => i.albumId)
        .whereType<String>()
        .toSet()
        .toList()
      ..sort((a, b) =>
          (MockAlbums.names[a] ?? a).compareTo(MockAlbums.names[b] ?? b));

    return ids
        .map((id) => _summarize(
              CategoryRef(granularity: CategoryGranularity.album, key: id),
              MockAlbums.names[id] ?? id,
              MockMediaItems.byAlbum(id),
            ))
        .whereType<CategorySummary>()
        .toList();
  }

  /// `null` se a categoria não tiver nenhum item contável (6.1.10) —
  /// evita gerar um `CategoryTile` para um recorte vazio.
  static CategorySummary? _summarize(
    CategoryRef ref,
    String label,
    List<MediaItemEntity> items,
  ) {
    final countable = items.where((i) => i.isCountable).toList();
    if (countable.isEmpty) return null;

    final kept =
        countable.where((i) => i.decision == TriageDecision.kept).toList();

    // Fix deliberado: NÃO usar `isClassified` (albumId != null) aqui. Um
    // item classificado que entrou na fila de exclusão preserva albumId
    // (3.2.5) mas deixa de estar "mantido" — 6.1.2 manda esse item para
    // o trilho vazio, não para os segmentos preenchidos. Sem essa
    // restrição extra, `classifiedItems` podia superar `keptItems` e
    // quebrar o assert de CategorySummary.
    final classified = kept.where((i) => i.albumId != null).length;

    final sizeBytes = countable.fold<int>(0, (sum, i) => sum + i.sizeBytes);

    return CategorySummary(
      ref: ref,
      label: label,
      totalItems: countable.length,
      keptItems: kept.length,
      classifiedItems: classified,
      sizeBytes: sizeBytes,
      coverItemId: countable.first.id,
    );
  }
}
//-------------------------------------------------//23.TRIAGE-PAGE

/// Sem estado próprio (2.1.2 — "Nenhum estado de triagem reside em
/// widget"). Cursor, itens e decisões vivem em [TriageSessionNotifier];
/// esta página só lê o estado e encaminha os callbacks de gesto/botão
/// para os métodos do notifier.
class TriagePage extends ConsumerWidget {
  const TriagePage({required this.category, super.key});

  final CategorySummary category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final provider = triageSessionProvider(category.ref);
    final session = ref.watch(provider);
    final notifier = ref.read(provider.notifier);

    // TODO §7 (Etapa 8): estado de conclusão real, com resumo das duas
    // métricas e ação de retorno ao dashboard. Por ora, só o botão que
    // evita o beco sem saída: reabrir a categoria para classificar em
    // álbum itens que ficaram mantidos sem álbum (3.2.2).
    if (session.isAtEnd) {
      return Scaffold(
        appBar: AppBar(title: Text(category.label)),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Fila concluída', style: text.titleMedium),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: notifier.restartFromBeginning,
                child: const Text('Rever itens'),
              ),
            ],
          ),
        ),
      );
    }

    final current = session.currentItem!;
    final nextItem =
        session.hasNext ? session.items[session.currentIndex + 1] : null;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(category.label),
            // `session.totalCount` em vez de `category.totalItems`: os
            // dois vêm do mesmo `MockMediaItems.forCategory`, mas usar o
            // da sessão evita depender de dois caminhos de agregação
            // ficarem sincronizados manualmente.
            Text(
              'Item ${session.currentIndex + 1} de ${session.totalCount}',
              style: text.bodySmall,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: ProgressBar(
              showLegend: true,
              totalItems: session.totalCount,
              classifiedItems: session.classifiedCount,
              keptItems: session.keptCount,
            ),
          ),
          TriageCarousel(
            items: session.items,
            currentIndex: session.currentIndex,
            onThumbTap: notifier.jumpTo,
          ),
          Expanded(
            child: Stack(
              children: [
                TriageCard(
                  // Key por item: sem ela o State do card sobrevive à
                  // troca e o próximo entra deslocado, onde o anterior
                  // saiu.
                  key: ValueKey(current.id),
                  item: current,
                  behind: nextItem != null ? MediaCard(item: nextItem) : null,
                  onSwipeLeft: notifier.markForDeletion,
                  onSwipeRight: notifier.keep,
                ),
                // Overlay topo-esquerdo (6.2.10). Desabilitado com a
                // pilha vazia — `onPressed: null` já cobre isso, sem
                // precisar de um estado visual separado.
                Positioned(
                  top: 8,
                  left: 8,
                  child: IconButton.filledTonal(
                    icon: const Icon(Icons.undo),
                    tooltip: 'Desfazer',
                    onPressed: session.canUndo ? notifier.undo : null,
                  ),
                ),
              ],
            ),
          ),
          TriageActionBar(
            onDelete: notifier.markForDeletion,
            onSkip: notifier.skip,
            onKeep: notifier.keep,
          ),
        ],
      ),
    );
  }
}
//-------------------------------------------------//24.TRIAGE-CAROUSEL

/// StatefulWidget só para o `ScrollController` — o cursor em si continua
/// vivendo no notifier (2.1.2), este widget apenas reage a ele.
class TriageCarousel extends StatefulWidget {
  final List<MediaItemEntity> items;
  final int currentIndex;
  final ValueChanged<int> onThumbTap;

  const TriageCarousel({
    required this.items,
    required this.currentIndex,
    required this.onThumbTap,
    super.key,
  });

  @override
  State<TriageCarousel> createState() => _TriageCarouselState();
}

class _TriageCarouselState extends State<TriageCarousel> {
  final _scrollController = ScrollController();

  // Precisa espelhar exatamente o footprint de CarouselThumb: largura
  // 90 + margem horizontal 4 de cada lado.
  static const _thumbFootprint = 98.0;
  static const _listPadding = 16.0;

  @override
  void initState() {
    super.initState();
    // Sem isso, abrir a categoria numa posição inicial != 0 (6.2.4,
    // ex.: primeiro item não decidido) mostra o carrossel do começo da
    // lista em vez de centralizado no item ativo.
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _centerActive(animate: false));
  }

  @override
  void didUpdateWidget(covariant TriageCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _centerActive(animate: true);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Foto ativa destacada no centro (6.2.5).
  void _centerActive({required bool animate}) {
    if (!_scrollController.hasClients || widget.items.isEmpty) return;

    final viewport = _scrollController.position.viewportDimension;
    final centerOfActive = _listPadding +
        widget.currentIndex * _thumbFootprint +
        _thumbFootprint / 2;
    final target = (centerOfActive - viewport / 2).clamp(
      _scrollController.position.minScrollExtent,
      _scrollController.position.maxScrollExtent,
    );

    if (animate) {
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(target);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: widget.items.length,
        padding: const EdgeInsets.symmetric(horizontal: _listPadding),
        itemBuilder: (context, index) {
          return CarouselThumb(
            item: widget.items[index],
            isActive: index == widget.currentIndex,
            onTap: () => widget.onThumbTap(index),
          );
        },
      ),
    );
  }
}
//-------------------------------------------------//25.CAROUSEL-THUMB

class CarouselThumb extends StatelessWidget {
  final MediaItemEntity item;
  final bool isActive;
  final VoidCallback onTap;

  const CarouselThumb({
    required this.item,
    required this.isActive,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final stateColor = TriageVisualState.of(item).colorIn(context.triageColors);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        width: 90,
        height: 90,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          // Contorno de seleção do item ativo (6.2.6) — deliberadamente
          // um elemento visual separado da borda de estado abaixo, para
          // não se confundirem.
          border: isActive ? Border.all(color: Colors.white, width: 3) : null,
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : const [],
        ),
        child: Container(
          decoration: BoxDecoration(
            color: mediaPlaceholderColor(item.id),
            borderRadius: BorderRadius.circular(9),
            // Borda de estado (6.2.7, precedência 3.3) — sempre visível,
            // ativo ou não.
            border: Border.all(color: stateColor, width: 2),
          ),
          child: item.isVideo
              ? const Center(
                  child: Icon(Icons.videocam, size: 16, color: Colors.white70),
                )
              : null,
        ),
      ),
    );
  }
}
//-------------------------------------------------//26.TRIAGE-CARD

class TriageCard extends StatefulWidget {
  final MediaItemEntity item;
  final VoidCallback onSwipeLeft;
  final VoidCallback onSwipeRight;

  /// Card de baixo da pilha. Opcional: sem ele o efeito continua, só
  /// perde a sensação de profundidade.
  final Widget? behind;

  const TriageCard({
    required this.item,
    required this.onSwipeLeft,
    required this.onSwipeRight,
    this.behind,
    super.key,
  });

  @override
  State<TriageCard> createState() => _TriageCardState();
}

class _TriageCardState extends State<TriageCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  Offset _dragEndPosition = Offset.zero;
  Offset _position = Offset.zero;

  final double _maxRotationDegrees = 15;

  /// Deslocamento em que a rotação satura. Não limita a translação: o
  /// card segue o dedo sem parede, só o ângulo é normalizado.
  double get _rotationSpan => MediaQuery.sizeOf(context).width * 0.5;

  /// Fração do delta vertical que o card acompanha. Y com o mesmo peso
  /// do X deixa o card escorregadio e tira a tendência horizontal, que é
  /// onde estão as duas decisões.
  static const double _verticalDamping = 0.25;
  
  static const double _commitFraction = 0.30;   // 30% da largura
  static const double _commitVelocity = 700.0;  // px/s 
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController.unbounded(vsync: this);
    // Sem setState: o AnimatedBuilder do build já escuta o controller e
    // reconstrói só o Transform.
    _controller.addListener(() {
      _position = Offset.lerp(_dragEndPosition, Offset.zero, _controller.value)!;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _runSpringAnimation(Velocity velocity) {
    _dragEndPosition = _position;

    const spring = SpringDescription(mass: 1, stiffness: 80, damping: 10);

    // `distance` é sempre positivo e perdia o sentido do lançamento: um
    // flick para fora dava o mesmo overshoot de um flick para dentro.
    // Projeta a velocidade no eixo do retorno (do ponto solto até o
    // centro) e normaliza pela distância a percorrer.
    final travel = _dragEndPosition.distance;
    final unit = travel == 0
        ? Offset.zero
        : Offset(-_dragEndPosition.dx / travel, -_dragEndPosition.dy / travel);
    final projected = velocity.pixelsPerSecond.dx * unit.dx +
        velocity.pixelsPerSecond.dy * unit.dy;

    _controller.animateWith(
      SpringSimulation(spring, 0, 1, travel == 0 ? 0 : projected / travel),
    );
  }
  
  Future<void> _exit(bool toRight) async {
    _runSpringAnimation(Velocity.zero);
    (toRight ? widget.onSwipeRight : widget.onSwipeLeft)();
  }
  
  double get _progress =>
      (_position.dx / _rotationSpan).clamp(-1.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;

    return Center(
      child: GestureDetector(
        onPanStart: (_) => _controller.stop(),
        onPanUpdate: (details) {
          setState(() {
            _position += Offset(
              details.delta.dx,
              details.delta.dy * _verticalDamping,
            );
          });
        },
        onPanEnd: (details) {
          final width = MediaQuery.sizeOf(context).width;
          final vx = details.velocity.pixelsPerSecond.dx;

          final passedDistance = _position.dx.abs() > width * _commitFraction;
          final passedVelocity = vx.abs() > _commitVelocity;

          if (passedDistance || passedVelocity) {
            // A velocidade tem prioridade: num flick rápido o dedo sai antes de
            // percorrer a distância, e o sinal dela é a intenção real.
            final toRight = passedVelocity ? vx > 0 : _position.dx > 0;
            _exit(toRight);
          } else {
            _runSpringAnimation(details.velocity);
          }
        },
        child: AnimatedBuilder(
          animation: _controller,
          // Fora do builder: a árvore da mídia não reconstrói a cada
          // frame de mola nem de arrasto, só o Transform.
          child: MediaCard(item: widget.item),
          builder: (context, child) {
            final progress = _progress;

            return Stack(
              alignment: Alignment.center,
              children: [
                if (widget.behind != null)
                  Transform.scale(
                    // Cresce conforme o card de cima se afasta: é o que
                    // vende a sensação de pilha.
                    scale: 0.92 + 0.08 * progress.abs(),
                    child: Opacity(opacity: 0.6, child: widget.behind),
                  ),
                Transform(
                  // Matrix4 único, translate antes de rotateZ. Aninhar
                  // Transform.rotate por fora de Transform.translate
                  // girava o eixo do arrasto: quanto maior o ângulo, mais
                  // o movimento horizontal virava diagonal.
                  transform: Matrix4.identity()
                    ..translateByDouble(_position.dx, _position.dy, 0, 1)
                    ..rotateZ(progress * _maxRotationDegrees * math.pi / 180),
                  // Pivô bem abaixo da tela. Girar na base do próprio
                  // card produz tombo; o eixo distante produz pêndulo.
                  origin: Offset(0, height * 0.6),
                  alignment: Alignment.center,
                  child: Stack(
                    fit: StackFit.passthrough,
                    children: [
                      child!,
                      SwipeOverlay(progress: progress),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
//-------------------------------------------------//27.MEDIA-CARD
class MediaCard extends StatelessWidget {
  final MediaItemEntity item;

  const MediaCard({
    required this.item,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor =
        TriageVisualState.of(item).colorIn(context.triageColors);

    return Container(
      width: 400,
      height: 400,
      decoration: BoxDecoration(
        color: mediaPlaceholderColor(item.id),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      // Placeholder de vídeo — controles reais entram em 6.2.17 (Etapa 9).
      child: item.isVideo
          ? const Center(
              child: Icon(
                Icons.play_circle_outline,
                size: 48,
                color: Colors.white70,
              ),
            )
          : null,
    );
  }
}
//-------------------------------------------------//28.SWIPE-OVERLAY


/// Lavagem de cor com ícone e rótulo, opacidade proporcional ao
/// deslocamento. O texto não é decoração: vermelho e verde são o par mais
/// confundido em deuteranopia, então a direção nunca é comunicada só por
/// cor.

class SwipeOverlay extends StatelessWidget {
  const SwipeOverlay({
    required this.progress,
    super.key,
  });

  final double progress;

  @override
  Widget build(BuildContext context) {
    final opacity = progress.abs();
    if (opacity <= 0.02) return const SizedBox.shrink();

    final toRight = progress > 0;
    final color = toRight ? const Color(0xFF4C8DFF) : const Color(0xFFF2554B);

    return Positioned.fill(
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.34 * opacity),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Opacity(
              opacity: opacity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    toRight ? Icons.check : Icons.delete_outline,
                    size: 44,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    toRight ? 'Manter' : 'Excluir',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

//-------------------------------------------------//29.MOCK-MEDIA-ITEMS

/// Placeholder até a entidade `Album` (2.2.2) entrar no domínio. Mapeia
/// albumId → nome só para rotular os testes mockados; some quando o
/// domínio real de álbum existir.
abstract final class MockAlbums {
  static const familia = 'alb-familia';
  static const viagens = 'alb-viagens';
  static const documentos = 'alb-documentos';

  static const names = <String, String>{
    familia: 'Família',
    viagens: 'Viagens',
    documentos: 'Documentos',
  };
}

/// Dataset único de [MediaItemEntity] para a fase mockada.
///
/// Fonte de verdade única: `MockCategories` deriva seus totais a partir
/// daqui, e a Tela de Triagem consome os mesmos itens por categoria. Não
/// há números digitados à parte — evita o dashboard mostrar uma
/// contagem que a triagem não consegue reproduzir.
///
/// Substituído pelo `MediaRepository` real quando o `SyncService`
/// existir (5.2/5.3).
abstract final class MockMediaItems {
  static final List<MediaItemEntity> all = _build();

  static String monthKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}';

  static List<MediaItemEntity> byMonth(String key) =>
      all.where((i) => monthKey(i.dateTaken) == key).toList();

  static List<MediaItemEntity> byYear(String key) =>
      all.where((i) => i.dateTaken.year.toString() == key).toList();

  static List<MediaItemEntity> byAlbum(String albumId) =>
      all.where((i) => i.albumId == albumId).toList();

  // Tipo não forma partição (6.1.5): Imagens contém Fotos e Screenshots.
  static List<MediaItemEntity> photos() => all
      .where((i) => i.mediaType == MediaType.image && !i.isScreenshot)
      .toList();

  static List<MediaItemEntity> screenshots() => all
      .where((i) => i.mediaType == MediaType.image && i.isScreenshot)
      .toList();

  static List<MediaItemEntity> images() =>
      all.where((i) => i.mediaType == MediaType.image).toList();

  static List<MediaItemEntity> videos() =>
      all.where((i) => i.mediaType == MediaType.video).toList();

  /// Ponto único de resolução `CategoryRef → itens`. Usado pela Tela de
  /// Triagem e, futuramente, pelo `TriageRepository` real como contrato
  /// de referência. Filtra por [MediaItemEntity.isCountable] (6.1.10):
  /// itens retidos ou indisponíveis não entram em nenhum recorte.
  static List<MediaItemEntity> forCategory(CategoryRef ref) {
    final items = switch (ref.granularity) {
      CategoryGranularity.all => all,
      CategoryGranularity.month => byMonth(ref.key),
      CategoryGranularity.year => byYear(ref.key),
      CategoryGranularity.album => byAlbum(ref.key),
      CategoryGranularity.type => switch (ref.key) {
          'photos' => photos(),
          'screenshots' => screenshots(),
          'images' => images(),
          'videos' => videos(),
          _ => const <MediaItemEntity>[],
        },
    };
    return items.where((i) => i.isCountable).toList();
  }

  static int _seq = 0;

  static MediaItemEntity _photo(
    DateTime dateTaken, {
    bool isScreenshot = false,
    int sizeMb = 4,
  }) {
    _seq++;
    return MediaItemEntity(
      id: 'mock-$_seq',
      mediaStoreId: 1000 + _seq,
      fingerprint: 'fp-$_seq',
      dateTaken: dateTaken,
      sizeBytes: sizeMb * 1024 * 1024,
      mimeType: isScreenshot ? 'image/png' : 'image/jpeg',
      relativePath: isScreenshot ? 'Pictures/Screenshots' : 'DCIM/Camera',
      mediaType: MediaType.image,
      isScreenshot: isScreenshot,
    );
  }

  static MediaItemEntity _video(
    DateTime dateTaken, {
    int sizeMb = 40,
    int durationMs = 15000,
  }) {
    _seq++;
    return MediaItemEntity(
      id: 'mock-$_seq',
      mediaStoreId: 1000 + _seq,
      fingerprint: 'fp-$_seq',
      dateTaken: dateTaken,
      sizeBytes: sizeMb * 1024 * 1024,
      mimeType: 'video/mp4',
      relativePath: 'DCIM/Camera',
      mediaType: MediaType.video,
      isScreenshot: false,
      durationMs: durationMs,
    );
  }

  static List<MediaItemEntity> _build() {
    final now = DateTime(2025, 10, 20);
    final items = <MediaItemEntity>[];

    // --- Outubro de 2025: recém-triado, quase tudo classificado ----------
    items.addAll([
      _photo(DateTime(2025, 10, 2, 9, 10))
          .assignToAlbum(MockAlbums.familia, now),
      _photo(DateTime(2025, 10, 5, 18, 40))
          .assignToAlbum(MockAlbums.viagens, now),
      _video(DateTime(2025, 10, 8, 20), durationMs: 32000)
          .assignToAlbum(MockAlbums.viagens, now),
      _photo(DateTime(2025, 10, 12, 14)).keep(now),
      // Classificado que caiu na fila: preserva albumId (3.2.5). Testa a
      // precedência visual (vermelho > verde, 3.3) e o fix do agregado —
      // não deve contar nem como mantido nem como classificado (6.1.2).
      _photo(DateTime(2025, 10, 15, 11))
          .assignToAlbum(MockAlbums.familia, now)
          .markForDeletion(now),
    ]);

    // --- Setembro de 2025: categoria fechada, tudo decidido ---------------
    items.addAll([
      _photo(DateTime(2025, 9, 3, 8))
          .assignToAlbum(MockAlbums.documentos, now),
      _photo(DateTime(2025, 9, 10, 19, 30)).keep(now),
      _photo(DateTime(2025, 9, 18, 12), isScreenshot: true, sizeMb: 1)
          .markForDeletion(now),
      _video(DateTime(2025, 9, 22, 16, 45), durationMs: 9000).keep(now),
      _photo(DateTime(2025, 9, 27, 10))
          .assignToAlbum(MockAlbums.familia, now),
    ]);

    // --- Agosto de 2025: mal começado --------------------------------------
    items.addAll([
      _photo(DateTime(2025, 8, 1, 9)),
      _photo(DateTime(2025, 8, 6, 17)),
      _photo(DateTime(2025, 8, 14, 13, 20)).keep(now),
      _video(DateTime(2025, 8, 25, 21), durationMs: 51000),
    ]);

    // --- Julho de 2025: intocado, exercita o caso 0 na barra e no anel ----
    items.addAll([
      _photo(DateTime(2025, 7, 2, 10), isScreenshot: true, sizeMb: 1),
      _photo(DateTime(2025, 7, 9, 15)),
      _photo(DateTime(2025, 7, 19, 11, 30)),
      _video(DateTime(2025, 7, 30, 19), durationMs: 22000),
    ]);

    // --- Junho de 2025: mantidas sem álbum dominam -------------------------
    items.addAll([
      _photo(DateTime(2025, 6, 4, 8, 30)).keep(now),
      _photo(DateTime(2025, 6, 11, 12)).keep(now),
      _photo(DateTime(2025, 6, 20, 17, 40)).keep(now),
      _photo(DateTime(2025, 6, 28, 9))
          .assignToAlbum(MockAlbums.viagens, now),
    ]);

    // --- Maio de 2025: mix kept / classificado ------------------------------
    items.addAll([
      _photo(DateTime(2025, 5, 3, 10))
          .assignToAlbum(MockAlbums.familia, now),
      _photo(DateTime(2025, 5, 12, 14)).keep(now),
      _video(DateTime(2025, 5, 19, 20), durationMs: 18000)
          .assignToAlbum(MockAlbums.viagens, now),
      _photo(DateTime(2025, 5, 26, 16)).keep(now),
    ]);

    // --- Abril de 2025: categoria minúscula, testa singular implícito ------
    items.add(_photo(DateTime(2025, 4, 5, 9)).keep(now));

    // --- Anos anteriores: variedade para a granularidade Ano ---------------
    items.addAll([
      _photo(DateTime(2024, 11, 3, 9))
          .assignToAlbum(MockAlbums.documentos, now),
      _photo(DateTime(2024, 11, 14, 13)).keep(now),
      _video(DateTime(2024, 11, 22, 18), durationMs: 27000),
      _photo(DateTime(2023, 3, 6, 10)),
      _photo(DateTime(2023, 3, 21, 15, 30)).markForDeletion(now),
    ]);

    return items;
  }
}

//-------------------------------------------------//30.TRIAGE-SESSION-NOTIFIER

final triageSessionProvider = NotifierProvider.family<TriageSessionNotifier,
    TriageSessionState, CategoryRef>(TriageSessionNotifier.new);

/// Estado de triagem em memória, escopado por categoria (3.5.1 — a fila
/// é sempre relativa à categoria ativa). Opera sobre o dataset mockado
/// hoje; a interface pública (métodos de transição + getters de
/// progresso, em [TriageSessionState]) é o contrato que o
/// `TriageRepository` real (2.4.2) deve preencher depois — a Tela de
/// Triagem não muda na troca.
///
/// Fora de escopo aqui: diálogo de saída com fila pendente (3.5.3 —
/// Etapa 8).
class TriageSessionNotifier extends Notifier<TriageSessionState> {
  TriageSessionNotifier(this._categoryRef);

  // Riverpod 3.0 fundiu FamilyNotifier em Notifier: o argumento da
  // family chega pelo construtor, não mais por parâmetro de build().
  final CategoryRef _categoryRef;

  static const _maxUndoEntries = 40;

  @override
  TriageSessionState build() {
    final items = MockMediaItems.forCategory(_categoryRef);
    return TriageSessionState(
      items: items,
      currentIndex: _resolveInitialIndex(items),
    );
  }

  /// 6.2.4, parcial: primeiro item não decidido; sem nenhum, primeiro
  /// item. A parte "última posição da sessão anterior" depende de
  /// persistência (Drift) e fica para quando o índice real existir —
  /// não há onde gravar isso ainda.
  static int _resolveInitialIndex(List<MediaItemEntity> items) {
    if (items.isEmpty) return 0;
    final firstUndecided =
        items.indexWhere((i) => i.decision == TriageDecision.undecided);
    return firstUndecided == -1 ? 0 : firstUndecided;
  }

  // --- Decisões (3.4) ------------------------------------------------

  /// Swipe direita / Manter.
  void keep() => _applyToCurrentAndAdvance((item, at) => item.keep(at));

  /// Swipe esquerda / Excluir.
  void markForDeletion() =>
      _applyToCurrentAndAdvance((item, at) => item.markForDeletion(at));

  /// Não altera decisão nem classificação, mas ainda é reversível
  /// (6.2.14 lista "pular" entre as ações que o desfazer cobre) — só
  /// que desfazê-lo apenas recua o cursor, sem restaurar nada, porque
  /// o snapshot da entrada é idêntico ao estado atual.
  void skip() {
    final current = state.currentItem;
    if (current == null) return;
    _pushUndo(current);
    _advance();
  }

  /// Painel de álbuns (6.2.16): toque em álbum diferente vincula e
  /// avança; toque no álbum atual desvincula e não avança (3.2.4). Um
  /// único método cobre as duas regras porque a UI não distingue os
  /// casos — só sabe qual álbum foi tocado.
  void toggleAlbum(String albumId) {
    final current = state.currentItem;
    if (current == null) return;

    if (current.albumId == albumId) {
      // 3.2.4: não avança.
      _pushUndo(current);
      _replaceCurrent(current.unassignAlbum());
      return;
    }

    _pushUndo(current);
    _replaceCurrent(current.assignToAlbum(albumId, DateTime.now()));
    _advance();
  }

  /// Toque no carrossel (6.2.6). Não passa por transição de domínio e
  /// não entra na pilha (6.2.14).
  void jumpTo(int index) {
    if (index < 0 || index >= state.items.length) return;
    state = state.copyWith(currentIndex: index);
  }

  /// Ação explícita da tela de fim de fila (§7) para reabrir uma
  /// categoria já percorrida. Só reposiciona o cursor — as decisões já
  /// tomadas continuam intactas; existe porque "mantido" não implica
  /// "classificado" (3.2.2) e o usuário pode querer voltar só para
  /// classificar em álbum itens que já estão mantidos.
  void restartFromBeginning() {
    if (state.items.isEmpty) return;
    state = state.copyWith(currentIndex: 0);
  }

  // --- Desfazer (6.2.14 / 6.2.15, revisado) ---------------------------
  //
  // Regra única, mais simples que a redação original de 6.2.15: cada
  // entrada guarda a posição do PRÓPRIO item de origem — não uma
  // "posição anterior" nem a "origem de um salto". Desfazer sempre
  // devolve o cursor exatamente para onde a ação aconteceu, esperando
  // nova decisão do usuário ali. Não importa se o item foi alcançado
  // por avanço sequencial ou salto pelo carrossel: o resultado é o
  // mesmo. Isto substitui a distinção sequencial/salto do texto
  // original de 6.2.15 — atualizar o arquitetura.md.

  /// Reverte a última ação: restaura decisão e álbum, e move o cursor
  /// de volta para o item que acabou de ser revertido.
  void undo() {
    if (state.undoStack.isEmpty) return;

    final entry = state.undoStack.last;
    final remaining = state.undoStack.sublist(0, state.undoStack.length - 1);

    final index = state.items.indexWhere((i) => i.id == entry.itemId);
    if (index == -1) {
      // Item não existe mais nesta sessão. Só ocorre depois que uma
      // exclusão real (fora de escopo ainda) remover itens da lista —
      // não há o que restaurar, só descarta a entrada.
      state = state.copyWith(undoStack: remaining);
      return;
    }

    final restored = state.items[index].copyWith(
      decision: entry.previousDecision,
      albumId: entry.previousAlbumId,
    );
    final items = [...state.items];
    items[index] = restored;

    state = state.copyWith(
      items: items,
      currentIndex: entry.anchorPosition,
      undoStack: remaining,
    );
  }

  /// 6.2.14 — "a pilha é zerada ao sair da categoria". Chamado no
  /// `initState()` da Tela de Triagem, não numa saída: o notifier
  /// sobrevive entre visitas (sem autoDispose, de propósito, para não
  /// perder decisões), e hoje não existe um hook limpo de "saída" —
  /// zerar na entrada tem o mesmo efeito prático.
  void resetSessionNavigation() {
    if (state.undoStack.isNotEmpty) {
      state = state.copyWith(undoStack: const []);
    }
  }

  void _pushUndo(MediaItemEntity beforeAction) {
    final entry = UndoEntry(
      itemId: beforeAction.id,
      previousDecision: beforeAction.decision,
      previousAlbumId: beforeAction.albumId,
      anchorPosition: state.currentIndex,
    );
    var stack = [...state.undoStack, entry];
    if (stack.length > _maxUndoEntries) {
      stack = stack.sublist(stack.length - _maxUndoEntries);
    }
    state = state.copyWith(undoStack: stack);
  }

  void _applyToCurrentAndAdvance(
    MediaItemEntity Function(MediaItemEntity item, DateTime at) transition,
  ) {
    final current = state.currentItem;
    if (current == null) return;
    _pushUndo(current);
    _replaceCurrent(transition(current, DateTime.now()));
    _advance();
  }

  void _replaceCurrent(MediaItemEntity updated) {
    final items = [...state.items];
    items[state.currentIndex] = updated;
    state = state.copyWith(items: items);
  }

  void _advance() {
    state = state.copyWith(
      currentIndex:
          state.hasNext ? state.currentIndex + 1 : state.items.length,
    );
  }
}
//-------------------------------------------------//31.TRIAGE-SESSION-STATE

/// Estado de uma sessão de triagem: os itens da categoria ativa e o
/// cursor. Não é o [MediaItemEntity] cru — é o recorte que a Tela de
/// Triagem está navegando.
class TriageSessionState {
  const TriageSessionState({
    required this.items,
    required this.currentIndex,
    this.undoStack = const [],
  });

  final List<MediaItemEntity> items;

  /// Pode chegar a `items.length` — é o estado de fim da fila (§7), não
  /// um índice inválido a ser evitado.
  final int currentIndex;

  /// 6.2.14 — limitada a 40 entradas pelo notifier. Exposta aqui para a
  /// UI decidir se o botão de desfazer (6.2.10) fica habilitado.
  final List<UndoEntry> undoStack;

  MediaItemEntity? get currentItem =>
      currentIndex >= 0 && currentIndex < items.length
          ? items[currentIndex]
          : null;

  bool get hasNext => currentIndex < items.length - 1;

  /// §7 — cursor passou do último item. Categoria nunca é marcada como
  /// concluída automaticamente (3.2.7); isto é só progresso informativo
  /// para a UI decidir mostrar o estado de conclusão.
  bool get isAtEnd => items.isEmpty || currentIndex >= items.length;

  bool get canUndo => undoStack.isNotEmpty;

  int get keptCount =>
      items.where((i) => i.decision == TriageDecision.kept).length;

  /// Mesma restrição de mock_categories.dart: um item classificado que
  /// caiu na fila (3.2.5) não conta como classificado no agregado —
  /// 6.1.2 manda esse item para o trilho vazio.
  int get classifiedCount => items
      .where((i) => i.decision == TriageDecision.kept && i.albumId != null)
      .length;

  int get queueCount => items.where((i) => i.isInDeletionQueue).length;

  int get totalCount => items.length;

  TriageSessionState copyWith({
    List<MediaItemEntity>? items,
    int? currentIndex,
    List<UndoEntry>? undoStack,
  }) {
    return TriageSessionState(
      items: items ?? this.items,
      currentIndex: currentIndex ?? this.currentIndex,
      undoStack: undoStack ?? this.undoStack,
    );
  }
}
//-------------------------------------------------//32.MEDIA-PLACEHOLDER

/// Cor determinística a partir do id do item — placeholder visual
/// enquanto não existe miniatura real (photo_manager). Substituído
/// quando o provider de miniatura existir; até lá, ao menos distingue
/// itens diferentes nos testes com dados mockados.
Color mediaPlaceholderColor(String id) {
  final hue = (id.hashCode % 360).abs().toDouble();
  return HSLColor.fromAHSL(1, hue, 0.35, 0.30).toColor();
}

//--------------------------------------------------//33.TRIAGE_ACTION_BAR

/// Rodapé da Tela de Triagem (6.2.12). Caminho equivalente ao swipe —
/// por isso os callbacks aqui são os mesmos métodos do notifier que o
/// `TriageCard` já chama, não lambdas separadas.
class TriageActionBar extends StatelessWidget {
  const TriageActionBar({
    required this.onDelete,
    required this.onSkip,
    required this.onKeep,
    super.key,
  });

  final VoidCallback onDelete;
  final VoidCallback onSkip;
  final VoidCallback onKeep;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final triageColors = context.triageColors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _ActionButton(
            icon: Icons.delete_outline,
            label: 'Excluir',
            color: triageColors.stateMarkedForDeletion,
            onTap: onDelete,
          ),
          _ActionButton(
            icon: Icons.skip_next_outlined,
            label: 'Pular',
            color: colors.onSurfaceVariant,
            onTap: onSkip,
          ),
          _ActionButton(
            icon: Icons.check,
            label: 'Manter',
            color: triageColors.stateKept,
            onTap: onKeep,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.14),
                border: Border.all(color: color, width: 1.5),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 6),
            Text(label, style: text.labelSmall?.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}
//--------------------------------------------------//34.UNDO-ENTRY

/// Uma entrada da pilha de desfazer.
///
/// `anchorPosition` é a posição do próprio item de origem da ação —
/// não uma "posição anterior". Ao desfazer, o cursor volta exatamente
/// para onde a ação aconteceu, independente de o item ter sido
/// alcançado por avanço sequencial ou salto pelo carrossel. (Revisão
/// de 6.2.15: o texto original distinguia os dois casos com âncoras
/// diferentes; simplificado para uma regra única após teste real
/// mostrar que voltar para uma posição anterior ao item revertido,
/// como o texto original pedia, não fazia sentido para quem está
/// desfazendo — a ação que motivou o desfazer foi a mais recente, e o
/// usuário espera vê-la, não pular por cima dela.)
class UndoEntry {
  const UndoEntry({
    required this.itemId,
    required this.previousDecision,
    required this.previousAlbumId,
    required this.anchorPosition,
  });

  final String itemId;
  final TriageDecision previousDecision;
  final String? previousAlbumId;
  final int anchorPosition;
}

//--------------------------------------------------//35.LAST-USED-ALBUM-PROVIDER

/// 2.6 — preferência global, fora do índice de mídia. Sobrevive entre
/// categorias e sessões (2.6.2: "não é por categoria. Quem tria Agosto
/// e depois Julho tende a usar os mesmos álbuns").
///
/// Em memória por enquanto — 2.6 documenta isto como
/// `shared_preferences`/Drift, que ainda não existem no projeto. Igual
/// ao resto do estado mockado, perde-se ao fechar o app; isso é uma
/// perda aceitável de ergonomia (2.6.1), não de triagem.
final lastUsedAlbumProvider =
    NotifierProvider<LastUsedAlbumNotifier, String?>(
  LastUsedAlbumNotifier.new,
);

class LastUsedAlbumNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String albumId) => state = albumId;

  /// 2.6.3 — se o álbum referenciado for excluído (6.5.5), a chave é
  /// limpa e o atalho de swipe para cima fica inerte até a próxima
  /// classificação. Sem chamador ainda: depende da tela de gestão de
  /// álbuns (6.5.2 / P-08), que não existe.
  void clearIfMatches(String albumId) {
    if (state == albumId) state = null;
  }
}