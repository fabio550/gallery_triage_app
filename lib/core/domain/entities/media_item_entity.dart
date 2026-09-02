import '../enums/triage_decision.dart';

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