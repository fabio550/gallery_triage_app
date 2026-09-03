//---1.IMPORTS********************
//---2.MAIN
//---3.APP-ROUTER-PROVIDER
//---4.ROUTES
//---5.APP-THEME********************
//---6.TRIAGE-VISUAL-STATE
//---7.TRIAGE-COLORS
//---8.TRIAGE-DECISION
//---9.PROGRESS-BAR********************
//---10.PROGRESS-CIRCULAR
//---11.PROGRESS-CIRCLE-PAINTER
//---12.MEDIA-ITEM-ENTITY
//---13.CATEGORY-GRANULARITY
//---14.CATEGORY-SUMMARY
//---15.CATEGORY-LIST********************
//---16.CATEGORY-TILE********************
//---17.GRANULARITY-PICKER-SHEET
//---18.GRANULARITY-SELECTOR
//---19.INFO-STATS-CARD********************
//---20.TOTAL-ITEMS-INFO
//---21.DASHBOARD-PAGE********************
//---22.MOCK-CATEGORIES
//---23.TRIAGE-PAGE********************
//---24.IMAGE-SELECTOR********************
//---25.MINI-IMAGE-CARD********************
//---26.IMAGE-INCLINATION-EFFECT********************
//---27.IMAGE-CARD********************
//--------------------------------------------------//1.IMPORTS
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;
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
            onTap: () => context.push('/triage-page', extra: categories[index])
          ) :
          CategoryTile(
            summary: summary,
            onTap: () => context.push('/triage-page', extra: categories[index])
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
      width: MediaQuery.of(context).size.width-50,
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
    
    // TEMPORÁRIO: dados fixos até o repositório existir.
    const totalItems = 62418;
    const totalSizeGb = 21.7;
    const classifiedItems = 18902;
    const keptItems = 27310;
    final categories = MockCategories.of(_granularity);
    
    return Scaffold(
      appBar: AppBar(title: const Text('Triagem')),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: InfoStatsCard(
              totalItems: totalItems,
              totalSizeGb: totalSizeGb,
              classifiedItems: classifiedItems,
              keptItems: keptItems,
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
                onCategoryTap: (summary) => debugPrint(summary.ref.key),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
//-------------------------------------------------//22.MOCK-CATEGORIES
abstract final class MockCategories {
  static List<CategorySummary> of(CategoryGranularity granularity) {
    return switch (granularity) {
      CategoryGranularity.all => _all,
      CategoryGranularity.month => _months,
      CategoryGranularity.year => _years,
      CategoryGranularity.type => _types,
      CategoryGranularity.album => _albums,
    };
  }

  static CategorySummary _make(
    CategoryGranularity granularity,
    String key,
    String label,
    int total,
    int kept,
    int classified,
    int sizeMb,
  ) {
    return CategorySummary(
      ref: CategoryRef(granularity: granularity, key: key),
      label: label,
      totalItems: total,
      keptItems: kept,
      classifiedItems: classified,
      sizeBytes: sizeMb * 1024 * 1024,
    );
  }

  static final _all = [
    _make(CategoryGranularity.all, 'all', 'Todos os itens',
        62418, 27310, 18902, 22220),
  ];

  static final _months = [
    // Recém-triado: quase tudo classificado.
    _make(CategoryGranularity.month, '2025-10', 'Outubro de 2025',
        1284, 901, 411, 4100),
    // Categoria fechada: tudo decidido.
    _make(CategoryGranularity.month, '2025-09', 'Setembro de 2025',
        906, 906, 798, 2900),
    // Mal começado.
    _make(CategoryGranularity.month, '2025-08', 'Agosto de 2025',
        2041, 449, 184, 6800),
    // Intocado: exercita o caso 0 na barra e no anel.
    _make(CategoryGranularity.month, '2025-07', 'Julho de 2025',
        3118, 0, 0, 9700),
    // Mantidas sem álbum dominam: segmento azul bem maior que o verde.
    _make(CategoryGranularity.month, '2025-06', 'Junho de 2025',
        874, 806, 91, 2600),
    _make(CategoryGranularity.month, '2025-05', 'Maio de 2025',
        1502, 640, 512, 5100),
    // Categoria minúscula: testa o rótulo no singular implícito.
    _make(CategoryGranularity.month, '2025-04', 'Abril de 2025',
        3, 1, 1, 12),
  ];

  static final _years = [
    _make(CategoryGranularity.year, '2025', '2025', 18402, 9210, 6104, 61000),
    _make(CategoryGranularity.year, '2024', '2024', 21876, 21876, 19340, 74000),
    _make(CategoryGranularity.year, '2023', '2023', 14330, 2011, 640, 48000),
    _make(CategoryGranularity.year, '2022', '2022', 7810, 0, 0, 26000),
  ];

  // Tipo não forma partição: Imagens contém Fotos e Screenshots (6.1.5).
  // Somar as quatro linhas não fecha o total, e é esperado.
  static final _types = [
    _make(CategoryGranularity.type, 'photos', 'Fotos',
        41209, 19004, 13880, 152000),
    _make(CategoryGranularity.type, 'screenshots', 'Screenshots',
        9877, 3120, 402, 3900),
    _make(CategoryGranularity.type, 'images', 'Imagens',
        51086, 22124, 14282, 155900),
    _make(CategoryGranularity.type, 'videos', 'Vídeos',
        11332, 5186, 4620, 66300),
  ];

  // Álbum: keptItems == classifiedItems == totalItems por definição.
  // O tile de álbum ignora as métricas, mas o assert de CategorySummary
  // não — se inverter, quebra em debug.
  static final _albums = [
    _make(CategoryGranularity.album, 'alb-1', 'Família',
        4219, 4219, 4219, 1900),
    _make(CategoryGranularity.album, 'alb-2', 'Viagens',
        3740, 3740, 3740, 2400),
    _make(CategoryGranularity.album, 'alb-3', 'Documentos',
        1108, 1108, 1108, 210),
    _make(CategoryGranularity.album, 'alb-4', 'Receitas',
        332, 332, 332, 96),
    _make(CategoryGranularity.album, 'alb-5', 'Trabalho',
        9503, 9503, 9503, 6100),
    _make(CategoryGranularity.album, 'alb-6',
        'Comprovantes de pagamento e recibos', 87, 87, 87, 14),
  ];
}
//-------------------------------------------------//23.TRIAGE-PAGE
class TriagePage extends StatelessWidget {
  final CategorySummary category;
  
  const TriagePage({
    required this.category,
    super.key
  });

  @override
  Widget build(BuildContext context) {
    
    final text = Theme.of(context).textTheme;
    final List<Color> items = [
      Colors.green,
      Colors.red,
      Colors.orange,
      Colors.amber,
      Colors.blueGrey,
      Colors.indigo,
      Colors.green,
      Colors.red,
      Colors.orange,
      Colors.amber,
      Colors.blueGrey,
      Colors.indigo,
    ];

    
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(category.label),
            Text(
              'Item X de ${category.totalItems}',
              style: text.bodySmall,
            ),
          ]
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsetsGeometry.symmetric(horizontal: 40),
              child: ProgressBar(
              showLegend: true,
              totalItems: category.totalItems,
              classifiedItems: category.classifiedItems,
              keptItems: category.keptItems,
            ),
          ),
          ImageSelector(items: items),
        ]
      ),
    );
  }
}

//-------------------------------------------------//24.IMAGE-SELECTOR
class ImageSelector extends StatefulWidget {
  final List<Color> items;
    
  ImageSelector({
    required this.items,
    super.key
  });

  @override
  State<ImageSelector> createState() => _ImageSelectorState();
}

class _ImageSelectorState extends State<ImageSelector> {
  int selectedIndex = 1; // Índice selecionado por padrão

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: widget.items.length,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (context, index) {
              return MiniImageCard(
                index: index,
                isSelected: selectedIndex == index,
                color: widget.items[index],
                onTap: () {
                  setState(() {
                    selectedIndex = index;
                  });
                },
              );
            },
          ),
        ),
        Padding(
          padding: EdgeInsetsGeometry.symmetric(
            horizontal: 16, vertical: 20,
          ),
          child: SizedBox(
            height: 500,
            child: ImageCard(
              color: widget.items[selectedIndex],
            ),
          ),
        ),
      ]
    );
  }
}

//-------------------------------------------------//25.MINI-IMAGE-CARD
class MiniImageCard extends StatelessWidget {
  final int index;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;
  
  const MiniImageCard({
    required this.index,
    required this.isSelected,
    required this.color,
    required this.onTap,
    super.key,
  });
  

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        width: 90,
        height: 90,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
          border: isSelected
              ? Border.all(color: Colors.white, width: 3)
              : null,
          boxShadow: isSelected
            ? [
                BoxShadow(
                  color: Colors.black.withValues(),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ]
            : [],
        ),
      ),
    );
  }
}
//-------------------------------------------------//26.IMAGE-INCLINATION-EFFECT

class ImageInclinationEffect extends StatefulWidget {
  final Color color;
  
  const ImageInclinationEffect({
    required this.color,
    super.key,
  });
  
  @override
  State<ImageInclinationEffect> createState() => _ImageInclinationEffectState();
}

class _ImageInclinationEffectState extends State<ImageInclinationEffect> with SingleTickerProviderStateMixin {
  
  late AnimationController _controller;
  
  Offset _position = Offset.zero;
  
  final double _maxRotationDegrees = 15;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300), // Duração do "pulo" de volta
    );
    // Ouvinte para atualizar a posição durante a animação de retorno
    _controller.addListener(() {
      setState(() {
        // Interpola a posição atual de volta para zero (centro)
        _position = Offset.lerp(_position, Offset.zero, _controller.value)!;
      });
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  double _calculateRotation() {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth == 0) return 0;

    // Normaliza o arrasto X entre -1.0 e 1.0
    double normalizedX = _position.dx / (screenWidth / 2);
    
    // Clampa o valor para garantir que não passe dos limites
    normalizedX = normalizedX.clamp(-1.0, 1.0);

    // Converte a porcentagem de arrasto no ângulo de rotação máximo (em radianos)
    // Se arrastou para a direita (positivo), inclina para a direita.
    final rotationRadians = normalizedX * (_maxRotationDegrees * math.pi / 180);
    
    return rotationRadians;
  }
    
  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onPanStart: (_) {
          _controller.stop();
        },
        onPanUpdate: (details) {
          setState(() {
            // Adiciona o deslocamento do dedo à posição atual
            _position += details.delta;
          });
        },
        // 3. QUANDO SOLTA, FAZ O "PÊNDULO" VOLTAR AO CENTRO
        onPanEnd: (_) {
          _controller.forward(from: 0); // Inicia a animação de retorno
        },
        child: Transform.rotate(
          angle: _calculateRotation(),
          alignment: Alignment.center,
          child: Transform.translate(
            offset: _position,
            child: ImageCard(color: widget.color),
          )
        )
      )
    );
  }
}
//-------------------------------------------------//27.IMAGE-CARD
class ImageCard extends StatelessWidget {
  final Color color;
  
  ImageCard({
    required this.color,
    super.key
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(
          color: Colors.black.withValues(),
          blurRadius: 8,
          offset: const Offset(0, 4),
        )],
      ),
    );
  }
}

