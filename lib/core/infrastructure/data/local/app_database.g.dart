// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $MediaItemsTableTable extends MediaItemsTable
    with TableInfo<$MediaItemsTableTable, MediaItemsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MediaItemsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mediaStoreIdMeta = const VerificationMeta(
    'mediaStoreId',
  );
  @override
  late final GeneratedColumn<int> mediaStoreId = GeneratedColumn<int>(
    'media_store_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fingerprintMeta = const VerificationMeta(
    'fingerprint',
  );
  @override
  late final GeneratedColumn<String> fingerprint = GeneratedColumn<String>(
    'fingerprint',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateTakenMeta = const VerificationMeta(
    'dateTaken',
  );
  @override
  late final GeneratedColumn<DateTime> dateTaken = GeneratedColumn<DateTime>(
    'date_taken',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sizeBytesMeta = const VerificationMeta(
    'sizeBytes',
  );
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
    'size_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mimeTypeMeta = const VerificationMeta(
    'mimeType',
  );
  @override
  late final GeneratedColumn<String> mimeType = GeneratedColumn<String>(
    'mime_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _relativePathMeta = const VerificationMeta(
    'relativePath',
  );
  @override
  late final GeneratedColumn<String> relativePath = GeneratedColumn<String>(
    'relative_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<MediaType, String> mediaType =
      GeneratedColumn<String>(
        'media_type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<MediaType>($MediaItemsTableTable.$convertermediaType);
  static const VerificationMeta _isScreenshotMeta = const VerificationMeta(
    'isScreenshot',
  );
  @override
  late final GeneratedColumn<bool> isScreenshot = GeneratedColumn<bool>(
    'is_screenshot',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_screenshot" IN (0, 1))',
    ),
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta(
    'durationMs',
  );
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<TriageDecision, String> decision =
      GeneratedColumn<String>(
        'decision',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<TriageDecision>($MediaItemsTableTable.$converterdecision);
  static const VerificationMeta _albumIdMeta = const VerificationMeta(
    'albumId',
  );
  @override
  late final GeneratedColumn<String> albumId = GeneratedColumn<String>(
    'album_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _decidedAtMeta = const VerificationMeta(
    'decidedAt',
  );
  @override
  late final GeneratedColumn<DateTime> decidedAt = GeneratedColumn<DateTime>(
    'decided_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<TriageDecision?, String>
  preQueueDecision =
      GeneratedColumn<String>(
        'pre_queue_decision',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<TriageDecision?>(
        $MediaItemsTableTable.$converterpreQueueDecisionn,
      );
  static const VerificationMeta _preQueueAlbumIdMeta = const VerificationMeta(
    'preQueueAlbumId',
  );
  @override
  late final GeneratedColumn<String> preQueueAlbumId = GeneratedColumn<String>(
    'pre_queue_album_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _trashedInSystemMeta = const VerificationMeta(
    'trashedInSystem',
  );
  @override
  late final GeneratedColumn<bool> trashedInSystem = GeneratedColumn<bool>(
    'trashed_in_system',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("trashed_in_system" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _trashedAtMeta = const VerificationMeta(
    'trashedAt',
  );
  @override
  late final GeneratedColumn<DateTime> trashedAt = GeneratedColumn<DateTime>(
    'trashed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isAvailableMeta = const VerificationMeta(
    'isAvailable',
  );
  @override
  late final GeneratedColumn<bool> isAvailable = GeneratedColumn<bool>(
    'is_available',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_available" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
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
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'media_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<MediaItemsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('media_store_id')) {
      context.handle(
        _mediaStoreIdMeta,
        mediaStoreId.isAcceptableOrUnknown(
          data['media_store_id']!,
          _mediaStoreIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_mediaStoreIdMeta);
    }
    if (data.containsKey('fingerprint')) {
      context.handle(
        _fingerprintMeta,
        fingerprint.isAcceptableOrUnknown(
          data['fingerprint']!,
          _fingerprintMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fingerprintMeta);
    }
    if (data.containsKey('date_taken')) {
      context.handle(
        _dateTakenMeta,
        dateTaken.isAcceptableOrUnknown(data['date_taken']!, _dateTakenMeta),
      );
    } else if (isInserting) {
      context.missing(_dateTakenMeta);
    }
    if (data.containsKey('size_bytes')) {
      context.handle(
        _sizeBytesMeta,
        sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta),
      );
    } else if (isInserting) {
      context.missing(_sizeBytesMeta);
    }
    if (data.containsKey('mime_type')) {
      context.handle(
        _mimeTypeMeta,
        mimeType.isAcceptableOrUnknown(data['mime_type']!, _mimeTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_mimeTypeMeta);
    }
    if (data.containsKey('relative_path')) {
      context.handle(
        _relativePathMeta,
        relativePath.isAcceptableOrUnknown(
          data['relative_path']!,
          _relativePathMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_relativePathMeta);
    }
    if (data.containsKey('is_screenshot')) {
      context.handle(
        _isScreenshotMeta,
        isScreenshot.isAcceptableOrUnknown(
          data['is_screenshot']!,
          _isScreenshotMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_isScreenshotMeta);
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    }
    if (data.containsKey('album_id')) {
      context.handle(
        _albumIdMeta,
        albumId.isAcceptableOrUnknown(data['album_id']!, _albumIdMeta),
      );
    }
    if (data.containsKey('decided_at')) {
      context.handle(
        _decidedAtMeta,
        decidedAt.isAcceptableOrUnknown(data['decided_at']!, _decidedAtMeta),
      );
    }
    if (data.containsKey('pre_queue_album_id')) {
      context.handle(
        _preQueueAlbumIdMeta,
        preQueueAlbumId.isAcceptableOrUnknown(
          data['pre_queue_album_id']!,
          _preQueueAlbumIdMeta,
        ),
      );
    }
    if (data.containsKey('trashed_in_system')) {
      context.handle(
        _trashedInSystemMeta,
        trashedInSystem.isAcceptableOrUnknown(
          data['trashed_in_system']!,
          _trashedInSystemMeta,
        ),
      );
    }
    if (data.containsKey('trashed_at')) {
      context.handle(
        _trashedAtMeta,
        trashedAt.isAcceptableOrUnknown(data['trashed_at']!, _trashedAtMeta),
      );
    }
    if (data.containsKey('is_available')) {
      context.handle(
        _isAvailableMeta,
        isAvailable.isAcceptableOrUnknown(
          data['is_available']!,
          _isAvailableMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MediaItemsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MediaItemsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      mediaStoreId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}media_store_id'],
      )!,
      fingerprint: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fingerprint'],
      )!,
      dateTaken: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date_taken'],
      )!,
      sizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size_bytes'],
      )!,
      mimeType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mime_type'],
      )!,
      relativePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}relative_path'],
      )!,
      mediaType: $MediaItemsTableTable.$convertermediaType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}media_type'],
        )!,
      ),
      isScreenshot: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_screenshot'],
      )!,
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      ),
      decision: $MediaItemsTableTable.$converterdecision.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}decision'],
        )!,
      ),
      albumId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}album_id'],
      ),
      decidedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}decided_at'],
      ),
      preQueueDecision: $MediaItemsTableTable.$converterpreQueueDecisionn
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}pre_queue_decision'],
            ),
          ),
      preQueueAlbumId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pre_queue_album_id'],
      ),
      trashedInSystem: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}trashed_in_system'],
      )!,
      trashedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}trashed_at'],
      ),
      isAvailable: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_available'],
      )!,
    );
  }

  @override
  $MediaItemsTableTable createAlias(String alias) {
    return $MediaItemsTableTable(attachedDatabase, alias);
  }

  static TypeConverter<MediaType, String> $convertermediaType =
      const MediaTypeConverter();
  static TypeConverter<TriageDecision, String> $converterdecision =
      const TriageDecisionConverter();
  static TypeConverter<TriageDecision, String> $converterpreQueueDecision =
      const TriageDecisionConverter();
  static TypeConverter<TriageDecision?, String?> $converterpreQueueDecisionn =
      NullAwareTypeConverter.wrap($converterpreQueueDecision);
}

class MediaItemsTableData extends DataClass
    implements Insertable<MediaItemsTableData> {
  /// UUID local (2.5.2). Chave primária — `mediaStoreId` não é estável
  /// o bastante para esse papel (2.5.1).
  final String id;
  final int mediaStoreId;
  final String fingerprint;
  final DateTime dateTaken;
  final int sizeBytes;
  final String mimeType;
  final String relativePath;
  final MediaType mediaType;
  final bool isScreenshot;

  /// Só existe em vídeo — mesma regra do `assert` da entidade.
  final int? durationMs;
  final TriageDecision decision;

  /// `null` = não classificado.
  final String? albumId;
  final DateTime? decidedAt;

  /// Snapshot pré-fila (2.2.4) — viabiliza 3.5.3 e 5.4.1 sem alteração
  /// futura de schema.
  final TriageDecision? preQueueDecision;
  final String? preQueueAlbumId;
  final bool trashedInSystem;
  final DateTime? trashedAt;
  final bool isAvailable;
  const MediaItemsTableData({
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
    required this.decision,
    this.albumId,
    this.decidedAt,
    this.preQueueDecision,
    this.preQueueAlbumId,
    required this.trashedInSystem,
    this.trashedAt,
    required this.isAvailable,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['media_store_id'] = Variable<int>(mediaStoreId);
    map['fingerprint'] = Variable<String>(fingerprint);
    map['date_taken'] = Variable<DateTime>(dateTaken);
    map['size_bytes'] = Variable<int>(sizeBytes);
    map['mime_type'] = Variable<String>(mimeType);
    map['relative_path'] = Variable<String>(relativePath);
    {
      map['media_type'] = Variable<String>(
        $MediaItemsTableTable.$convertermediaType.toSql(mediaType),
      );
    }
    map['is_screenshot'] = Variable<bool>(isScreenshot);
    if (!nullToAbsent || durationMs != null) {
      map['duration_ms'] = Variable<int>(durationMs);
    }
    {
      map['decision'] = Variable<String>(
        $MediaItemsTableTable.$converterdecision.toSql(decision),
      );
    }
    if (!nullToAbsent || albumId != null) {
      map['album_id'] = Variable<String>(albumId);
    }
    if (!nullToAbsent || decidedAt != null) {
      map['decided_at'] = Variable<DateTime>(decidedAt);
    }
    if (!nullToAbsent || preQueueDecision != null) {
      map['pre_queue_decision'] = Variable<String>(
        $MediaItemsTableTable.$converterpreQueueDecisionn.toSql(
          preQueueDecision,
        ),
      );
    }
    if (!nullToAbsent || preQueueAlbumId != null) {
      map['pre_queue_album_id'] = Variable<String>(preQueueAlbumId);
    }
    map['trashed_in_system'] = Variable<bool>(trashedInSystem);
    if (!nullToAbsent || trashedAt != null) {
      map['trashed_at'] = Variable<DateTime>(trashedAt);
    }
    map['is_available'] = Variable<bool>(isAvailable);
    return map;
  }

  MediaItemsTableCompanion toCompanion(bool nullToAbsent) {
    return MediaItemsTableCompanion(
      id: Value(id),
      mediaStoreId: Value(mediaStoreId),
      fingerprint: Value(fingerprint),
      dateTaken: Value(dateTaken),
      sizeBytes: Value(sizeBytes),
      mimeType: Value(mimeType),
      relativePath: Value(relativePath),
      mediaType: Value(mediaType),
      isScreenshot: Value(isScreenshot),
      durationMs: durationMs == null && nullToAbsent
          ? const Value.absent()
          : Value(durationMs),
      decision: Value(decision),
      albumId: albumId == null && nullToAbsent
          ? const Value.absent()
          : Value(albumId),
      decidedAt: decidedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(decidedAt),
      preQueueDecision: preQueueDecision == null && nullToAbsent
          ? const Value.absent()
          : Value(preQueueDecision),
      preQueueAlbumId: preQueueAlbumId == null && nullToAbsent
          ? const Value.absent()
          : Value(preQueueAlbumId),
      trashedInSystem: Value(trashedInSystem),
      trashedAt: trashedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(trashedAt),
      isAvailable: Value(isAvailable),
    );
  }

  factory MediaItemsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MediaItemsTableData(
      id: serializer.fromJson<String>(json['id']),
      mediaStoreId: serializer.fromJson<int>(json['mediaStoreId']),
      fingerprint: serializer.fromJson<String>(json['fingerprint']),
      dateTaken: serializer.fromJson<DateTime>(json['dateTaken']),
      sizeBytes: serializer.fromJson<int>(json['sizeBytes']),
      mimeType: serializer.fromJson<String>(json['mimeType']),
      relativePath: serializer.fromJson<String>(json['relativePath']),
      mediaType: serializer.fromJson<MediaType>(json['mediaType']),
      isScreenshot: serializer.fromJson<bool>(json['isScreenshot']),
      durationMs: serializer.fromJson<int?>(json['durationMs']),
      decision: serializer.fromJson<TriageDecision>(json['decision']),
      albumId: serializer.fromJson<String?>(json['albumId']),
      decidedAt: serializer.fromJson<DateTime?>(json['decidedAt']),
      preQueueDecision: serializer.fromJson<TriageDecision?>(
        json['preQueueDecision'],
      ),
      preQueueAlbumId: serializer.fromJson<String?>(json['preQueueAlbumId']),
      trashedInSystem: serializer.fromJson<bool>(json['trashedInSystem']),
      trashedAt: serializer.fromJson<DateTime?>(json['trashedAt']),
      isAvailable: serializer.fromJson<bool>(json['isAvailable']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'mediaStoreId': serializer.toJson<int>(mediaStoreId),
      'fingerprint': serializer.toJson<String>(fingerprint),
      'dateTaken': serializer.toJson<DateTime>(dateTaken),
      'sizeBytes': serializer.toJson<int>(sizeBytes),
      'mimeType': serializer.toJson<String>(mimeType),
      'relativePath': serializer.toJson<String>(relativePath),
      'mediaType': serializer.toJson<MediaType>(mediaType),
      'isScreenshot': serializer.toJson<bool>(isScreenshot),
      'durationMs': serializer.toJson<int?>(durationMs),
      'decision': serializer.toJson<TriageDecision>(decision),
      'albumId': serializer.toJson<String?>(albumId),
      'decidedAt': serializer.toJson<DateTime?>(decidedAt),
      'preQueueDecision': serializer.toJson<TriageDecision?>(preQueueDecision),
      'preQueueAlbumId': serializer.toJson<String?>(preQueueAlbumId),
      'trashedInSystem': serializer.toJson<bool>(trashedInSystem),
      'trashedAt': serializer.toJson<DateTime?>(trashedAt),
      'isAvailable': serializer.toJson<bool>(isAvailable),
    };
  }

  MediaItemsTableData copyWith({
    String? id,
    int? mediaStoreId,
    String? fingerprint,
    DateTime? dateTaken,
    int? sizeBytes,
    String? mimeType,
    String? relativePath,
    MediaType? mediaType,
    bool? isScreenshot,
    Value<int?> durationMs = const Value.absent(),
    TriageDecision? decision,
    Value<String?> albumId = const Value.absent(),
    Value<DateTime?> decidedAt = const Value.absent(),
    Value<TriageDecision?> preQueueDecision = const Value.absent(),
    Value<String?> preQueueAlbumId = const Value.absent(),
    bool? trashedInSystem,
    Value<DateTime?> trashedAt = const Value.absent(),
    bool? isAvailable,
  }) => MediaItemsTableData(
    id: id ?? this.id,
    mediaStoreId: mediaStoreId ?? this.mediaStoreId,
    fingerprint: fingerprint ?? this.fingerprint,
    dateTaken: dateTaken ?? this.dateTaken,
    sizeBytes: sizeBytes ?? this.sizeBytes,
    mimeType: mimeType ?? this.mimeType,
    relativePath: relativePath ?? this.relativePath,
    mediaType: mediaType ?? this.mediaType,
    isScreenshot: isScreenshot ?? this.isScreenshot,
    durationMs: durationMs.present ? durationMs.value : this.durationMs,
    decision: decision ?? this.decision,
    albumId: albumId.present ? albumId.value : this.albumId,
    decidedAt: decidedAt.present ? decidedAt.value : this.decidedAt,
    preQueueDecision: preQueueDecision.present
        ? preQueueDecision.value
        : this.preQueueDecision,
    preQueueAlbumId: preQueueAlbumId.present
        ? preQueueAlbumId.value
        : this.preQueueAlbumId,
    trashedInSystem: trashedInSystem ?? this.trashedInSystem,
    trashedAt: trashedAt.present ? trashedAt.value : this.trashedAt,
    isAvailable: isAvailable ?? this.isAvailable,
  );
  MediaItemsTableData copyWithCompanion(MediaItemsTableCompanion data) {
    return MediaItemsTableData(
      id: data.id.present ? data.id.value : this.id,
      mediaStoreId: data.mediaStoreId.present
          ? data.mediaStoreId.value
          : this.mediaStoreId,
      fingerprint: data.fingerprint.present
          ? data.fingerprint.value
          : this.fingerprint,
      dateTaken: data.dateTaken.present ? data.dateTaken.value : this.dateTaken,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      mimeType: data.mimeType.present ? data.mimeType.value : this.mimeType,
      relativePath: data.relativePath.present
          ? data.relativePath.value
          : this.relativePath,
      mediaType: data.mediaType.present ? data.mediaType.value : this.mediaType,
      isScreenshot: data.isScreenshot.present
          ? data.isScreenshot.value
          : this.isScreenshot,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
      decision: data.decision.present ? data.decision.value : this.decision,
      albumId: data.albumId.present ? data.albumId.value : this.albumId,
      decidedAt: data.decidedAt.present ? data.decidedAt.value : this.decidedAt,
      preQueueDecision: data.preQueueDecision.present
          ? data.preQueueDecision.value
          : this.preQueueDecision,
      preQueueAlbumId: data.preQueueAlbumId.present
          ? data.preQueueAlbumId.value
          : this.preQueueAlbumId,
      trashedInSystem: data.trashedInSystem.present
          ? data.trashedInSystem.value
          : this.trashedInSystem,
      trashedAt: data.trashedAt.present ? data.trashedAt.value : this.trashedAt,
      isAvailable: data.isAvailable.present
          ? data.isAvailable.value
          : this.isAvailable,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MediaItemsTableData(')
          ..write('id: $id, ')
          ..write('mediaStoreId: $mediaStoreId, ')
          ..write('fingerprint: $fingerprint, ')
          ..write('dateTaken: $dateTaken, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('mimeType: $mimeType, ')
          ..write('relativePath: $relativePath, ')
          ..write('mediaType: $mediaType, ')
          ..write('isScreenshot: $isScreenshot, ')
          ..write('durationMs: $durationMs, ')
          ..write('decision: $decision, ')
          ..write('albumId: $albumId, ')
          ..write('decidedAt: $decidedAt, ')
          ..write('preQueueDecision: $preQueueDecision, ')
          ..write('preQueueAlbumId: $preQueueAlbumId, ')
          ..write('trashedInSystem: $trashedInSystem, ')
          ..write('trashedAt: $trashedAt, ')
          ..write('isAvailable: $isAvailable')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
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
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MediaItemsTableData &&
          other.id == this.id &&
          other.mediaStoreId == this.mediaStoreId &&
          other.fingerprint == this.fingerprint &&
          other.dateTaken == this.dateTaken &&
          other.sizeBytes == this.sizeBytes &&
          other.mimeType == this.mimeType &&
          other.relativePath == this.relativePath &&
          other.mediaType == this.mediaType &&
          other.isScreenshot == this.isScreenshot &&
          other.durationMs == this.durationMs &&
          other.decision == this.decision &&
          other.albumId == this.albumId &&
          other.decidedAt == this.decidedAt &&
          other.preQueueDecision == this.preQueueDecision &&
          other.preQueueAlbumId == this.preQueueAlbumId &&
          other.trashedInSystem == this.trashedInSystem &&
          other.trashedAt == this.trashedAt &&
          other.isAvailable == this.isAvailable);
}

class MediaItemsTableCompanion extends UpdateCompanion<MediaItemsTableData> {
  final Value<String> id;
  final Value<int> mediaStoreId;
  final Value<String> fingerprint;
  final Value<DateTime> dateTaken;
  final Value<int> sizeBytes;
  final Value<String> mimeType;
  final Value<String> relativePath;
  final Value<MediaType> mediaType;
  final Value<bool> isScreenshot;
  final Value<int?> durationMs;
  final Value<TriageDecision> decision;
  final Value<String?> albumId;
  final Value<DateTime?> decidedAt;
  final Value<TriageDecision?> preQueueDecision;
  final Value<String?> preQueueAlbumId;
  final Value<bool> trashedInSystem;
  final Value<DateTime?> trashedAt;
  final Value<bool> isAvailable;
  final Value<int> rowid;
  const MediaItemsTableCompanion({
    this.id = const Value.absent(),
    this.mediaStoreId = const Value.absent(),
    this.fingerprint = const Value.absent(),
    this.dateTaken = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.relativePath = const Value.absent(),
    this.mediaType = const Value.absent(),
    this.isScreenshot = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.decision = const Value.absent(),
    this.albumId = const Value.absent(),
    this.decidedAt = const Value.absent(),
    this.preQueueDecision = const Value.absent(),
    this.preQueueAlbumId = const Value.absent(),
    this.trashedInSystem = const Value.absent(),
    this.trashedAt = const Value.absent(),
    this.isAvailable = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MediaItemsTableCompanion.insert({
    required String id,
    required int mediaStoreId,
    required String fingerprint,
    required DateTime dateTaken,
    required int sizeBytes,
    required String mimeType,
    required String relativePath,
    required MediaType mediaType,
    required bool isScreenshot,
    this.durationMs = const Value.absent(),
    required TriageDecision decision,
    this.albumId = const Value.absent(),
    this.decidedAt = const Value.absent(),
    this.preQueueDecision = const Value.absent(),
    this.preQueueAlbumId = const Value.absent(),
    this.trashedInSystem = const Value.absent(),
    this.trashedAt = const Value.absent(),
    this.isAvailable = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       mediaStoreId = Value(mediaStoreId),
       fingerprint = Value(fingerprint),
       dateTaken = Value(dateTaken),
       sizeBytes = Value(sizeBytes),
       mimeType = Value(mimeType),
       relativePath = Value(relativePath),
       mediaType = Value(mediaType),
       isScreenshot = Value(isScreenshot),
       decision = Value(decision);
  static Insertable<MediaItemsTableData> custom({
    Expression<String>? id,
    Expression<int>? mediaStoreId,
    Expression<String>? fingerprint,
    Expression<DateTime>? dateTaken,
    Expression<int>? sizeBytes,
    Expression<String>? mimeType,
    Expression<String>? relativePath,
    Expression<String>? mediaType,
    Expression<bool>? isScreenshot,
    Expression<int>? durationMs,
    Expression<String>? decision,
    Expression<String>? albumId,
    Expression<DateTime>? decidedAt,
    Expression<String>? preQueueDecision,
    Expression<String>? preQueueAlbumId,
    Expression<bool>? trashedInSystem,
    Expression<DateTime>? trashedAt,
    Expression<bool>? isAvailable,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (mediaStoreId != null) 'media_store_id': mediaStoreId,
      if (fingerprint != null) 'fingerprint': fingerprint,
      if (dateTaken != null) 'date_taken': dateTaken,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (mimeType != null) 'mime_type': mimeType,
      if (relativePath != null) 'relative_path': relativePath,
      if (mediaType != null) 'media_type': mediaType,
      if (isScreenshot != null) 'is_screenshot': isScreenshot,
      if (durationMs != null) 'duration_ms': durationMs,
      if (decision != null) 'decision': decision,
      if (albumId != null) 'album_id': albumId,
      if (decidedAt != null) 'decided_at': decidedAt,
      if (preQueueDecision != null) 'pre_queue_decision': preQueueDecision,
      if (preQueueAlbumId != null) 'pre_queue_album_id': preQueueAlbumId,
      if (trashedInSystem != null) 'trashed_in_system': trashedInSystem,
      if (trashedAt != null) 'trashed_at': trashedAt,
      if (isAvailable != null) 'is_available': isAvailable,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MediaItemsTableCompanion copyWith({
    Value<String>? id,
    Value<int>? mediaStoreId,
    Value<String>? fingerprint,
    Value<DateTime>? dateTaken,
    Value<int>? sizeBytes,
    Value<String>? mimeType,
    Value<String>? relativePath,
    Value<MediaType>? mediaType,
    Value<bool>? isScreenshot,
    Value<int?>? durationMs,
    Value<TriageDecision>? decision,
    Value<String?>? albumId,
    Value<DateTime?>? decidedAt,
    Value<TriageDecision?>? preQueueDecision,
    Value<String?>? preQueueAlbumId,
    Value<bool>? trashedInSystem,
    Value<DateTime?>? trashedAt,
    Value<bool>? isAvailable,
    Value<int>? rowid,
  }) {
    return MediaItemsTableCompanion(
      id: id ?? this.id,
      mediaStoreId: mediaStoreId ?? this.mediaStoreId,
      fingerprint: fingerprint ?? this.fingerprint,
      dateTaken: dateTaken ?? this.dateTaken,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      mimeType: mimeType ?? this.mimeType,
      relativePath: relativePath ?? this.relativePath,
      mediaType: mediaType ?? this.mediaType,
      isScreenshot: isScreenshot ?? this.isScreenshot,
      durationMs: durationMs ?? this.durationMs,
      decision: decision ?? this.decision,
      albumId: albumId ?? this.albumId,
      decidedAt: decidedAt ?? this.decidedAt,
      preQueueDecision: preQueueDecision ?? this.preQueueDecision,
      preQueueAlbumId: preQueueAlbumId ?? this.preQueueAlbumId,
      trashedInSystem: trashedInSystem ?? this.trashedInSystem,
      trashedAt: trashedAt ?? this.trashedAt,
      isAvailable: isAvailable ?? this.isAvailable,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (mediaStoreId.present) {
      map['media_store_id'] = Variable<int>(mediaStoreId.value);
    }
    if (fingerprint.present) {
      map['fingerprint'] = Variable<String>(fingerprint.value);
    }
    if (dateTaken.present) {
      map['date_taken'] = Variable<DateTime>(dateTaken.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (mimeType.present) {
      map['mime_type'] = Variable<String>(mimeType.value);
    }
    if (relativePath.present) {
      map['relative_path'] = Variable<String>(relativePath.value);
    }
    if (mediaType.present) {
      map['media_type'] = Variable<String>(
        $MediaItemsTableTable.$convertermediaType.toSql(mediaType.value),
      );
    }
    if (isScreenshot.present) {
      map['is_screenshot'] = Variable<bool>(isScreenshot.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (decision.present) {
      map['decision'] = Variable<String>(
        $MediaItemsTableTable.$converterdecision.toSql(decision.value),
      );
    }
    if (albumId.present) {
      map['album_id'] = Variable<String>(albumId.value);
    }
    if (decidedAt.present) {
      map['decided_at'] = Variable<DateTime>(decidedAt.value);
    }
    if (preQueueDecision.present) {
      map['pre_queue_decision'] = Variable<String>(
        $MediaItemsTableTable.$converterpreQueueDecisionn.toSql(
          preQueueDecision.value,
        ),
      );
    }
    if (preQueueAlbumId.present) {
      map['pre_queue_album_id'] = Variable<String>(preQueueAlbumId.value);
    }
    if (trashedInSystem.present) {
      map['trashed_in_system'] = Variable<bool>(trashedInSystem.value);
    }
    if (trashedAt.present) {
      map['trashed_at'] = Variable<DateTime>(trashedAt.value);
    }
    if (isAvailable.present) {
      map['is_available'] = Variable<bool>(isAvailable.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MediaItemsTableCompanion(')
          ..write('id: $id, ')
          ..write('mediaStoreId: $mediaStoreId, ')
          ..write('fingerprint: $fingerprint, ')
          ..write('dateTaken: $dateTaken, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('mimeType: $mimeType, ')
          ..write('relativePath: $relativePath, ')
          ..write('mediaType: $mediaType, ')
          ..write('isScreenshot: $isScreenshot, ')
          ..write('durationMs: $durationMs, ')
          ..write('decision: $decision, ')
          ..write('albumId: $albumId, ')
          ..write('decidedAt: $decidedAt, ')
          ..write('preQueueDecision: $preQueueDecision, ')
          ..write('preQueueAlbumId: $preQueueAlbumId, ')
          ..write('trashedInSystem: $trashedInSystem, ')
          ..write('trashedAt: $trashedAt, ')
          ..write('isAvailable: $isAvailable, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AlbumsTableTable extends AlbumsTable
    with TableInfo<$AlbumsTableTable, AlbumsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AlbumsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _externalRefMeta = const VerificationMeta(
    'externalRef',
  );
  @override
  late final GeneratedColumn<String> externalRef = GeneratedColumn<String>(
    'external_ref',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, createdAt, externalRef];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'albums';
  @override
  VerificationContext validateIntegrity(
    Insertable<AlbumsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('external_ref')) {
      context.handle(
        _externalRefMeta,
        externalRef.isAcceptableOrUnknown(
          data['external_ref']!,
          _externalRefMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AlbumsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AlbumsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      externalRef: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}external_ref'],
      ),
    );
  }

  @override
  $AlbumsTableTable createAlias(String alias) {
    return $AlbumsTableTable(attachedDatabase, alias);
  }
}

class AlbumsTableData extends DataClass implements Insertable<AlbumsTableData> {
  final String id;
  final String name;
  final DateTime createdAt;

  /// Reservado para os estágios 2 e 3 (1.3.2/1.3.3). Não usado ainda.
  final String? externalRef;
  const AlbumsTableData({
    required this.id,
    required this.name,
    required this.createdAt,
    this.externalRef,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || externalRef != null) {
      map['external_ref'] = Variable<String>(externalRef);
    }
    return map;
  }

  AlbumsTableCompanion toCompanion(bool nullToAbsent) {
    return AlbumsTableCompanion(
      id: Value(id),
      name: Value(name),
      createdAt: Value(createdAt),
      externalRef: externalRef == null && nullToAbsent
          ? const Value.absent()
          : Value(externalRef),
    );
  }

  factory AlbumsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AlbumsTableData(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      externalRef: serializer.fromJson<String?>(json['externalRef']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'externalRef': serializer.toJson<String?>(externalRef),
    };
  }

  AlbumsTableData copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    Value<String?> externalRef = const Value.absent(),
  }) => AlbumsTableData(
    id: id ?? this.id,
    name: name ?? this.name,
    createdAt: createdAt ?? this.createdAt,
    externalRef: externalRef.present ? externalRef.value : this.externalRef,
  );
  AlbumsTableData copyWithCompanion(AlbumsTableCompanion data) {
    return AlbumsTableData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      externalRef: data.externalRef.present
          ? data.externalRef.value
          : this.externalRef,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AlbumsTableData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('externalRef: $externalRef')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, createdAt, externalRef);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AlbumsTableData &&
          other.id == this.id &&
          other.name == this.name &&
          other.createdAt == this.createdAt &&
          other.externalRef == this.externalRef);
}

class AlbumsTableCompanion extends UpdateCompanion<AlbumsTableData> {
  final Value<String> id;
  final Value<String> name;
  final Value<DateTime> createdAt;
  final Value<String?> externalRef;
  final Value<int> rowid;
  const AlbumsTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.externalRef = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AlbumsTableCompanion.insert({
    required String id,
    required String name,
    required DateTime createdAt,
    this.externalRef = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt);
  static Insertable<AlbumsTableData> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<DateTime>? createdAt,
    Expression<String>? externalRef,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt,
      if (externalRef != null) 'external_ref': externalRef,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AlbumsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<DateTime>? createdAt,
    Value<String?>? externalRef,
    Value<int>? rowid,
  }) {
    return AlbumsTableCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      externalRef: externalRef ?? this.externalRef,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (externalRef.present) {
      map['external_ref'] = Variable<String>(externalRef.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AlbumsTableCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('externalRef: $externalRef, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $MediaItemsTableTable mediaItemsTable = $MediaItemsTableTable(
    this,
  );
  late final $AlbumsTableTable albumsTable = $AlbumsTableTable(this);
  late final Index idxMediaItemsDecision = Index(
    'idx_media_items_decision',
    'CREATE INDEX idx_media_items_decision ON media_items (decision)',
  );
  late final Index idxMediaItemsAlbumId = Index(
    'idx_media_items_album_id',
    'CREATE INDEX idx_media_items_album_id ON media_items (album_id)',
  );
  late final Index idxMediaItemsDateTaken = Index(
    'idx_media_items_date_taken',
    'CREATE INDEX idx_media_items_date_taken ON media_items (date_taken)',
  );
  late final Index idxMediaItemsRelativePath = Index(
    'idx_media_items_relative_path',
    'CREATE INDEX idx_media_items_relative_path ON media_items (relative_path)',
  );
  late final Index idxMediaItemsMediaStoreId = Index(
    'idx_media_items_media_store_id',
    'CREATE INDEX idx_media_items_media_store_id ON media_items (media_store_id)',
  );
  late final Index idxMediaItemsIsScreenshot = Index(
    'idx_media_items_is_screenshot',
    'CREATE INDEX idx_media_items_is_screenshot ON media_items (is_screenshot)',
  );
  late final Index idxMediaItemsTrashedInSystem = Index(
    'idx_media_items_trashed_in_system',
    'CREATE INDEX idx_media_items_trashed_in_system ON media_items (trashed_in_system)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    mediaItemsTable,
    albumsTable,
    idxMediaItemsDecision,
    idxMediaItemsAlbumId,
    idxMediaItemsDateTaken,
    idxMediaItemsRelativePath,
    idxMediaItemsMediaStoreId,
    idxMediaItemsIsScreenshot,
    idxMediaItemsTrashedInSystem,
  ];
}

typedef $$MediaItemsTableTableCreateCompanionBuilder =
    MediaItemsTableCompanion Function({
      required String id,
      required int mediaStoreId,
      required String fingerprint,
      required DateTime dateTaken,
      required int sizeBytes,
      required String mimeType,
      required String relativePath,
      required MediaType mediaType,
      required bool isScreenshot,
      Value<int?> durationMs,
      required TriageDecision decision,
      Value<String?> albumId,
      Value<DateTime?> decidedAt,
      Value<TriageDecision?> preQueueDecision,
      Value<String?> preQueueAlbumId,
      Value<bool> trashedInSystem,
      Value<DateTime?> trashedAt,
      Value<bool> isAvailable,
      Value<int> rowid,
    });
typedef $$MediaItemsTableTableUpdateCompanionBuilder =
    MediaItemsTableCompanion Function({
      Value<String> id,
      Value<int> mediaStoreId,
      Value<String> fingerprint,
      Value<DateTime> dateTaken,
      Value<int> sizeBytes,
      Value<String> mimeType,
      Value<String> relativePath,
      Value<MediaType> mediaType,
      Value<bool> isScreenshot,
      Value<int?> durationMs,
      Value<TriageDecision> decision,
      Value<String?> albumId,
      Value<DateTime?> decidedAt,
      Value<TriageDecision?> preQueueDecision,
      Value<String?> preQueueAlbumId,
      Value<bool> trashedInSystem,
      Value<DateTime?> trashedAt,
      Value<bool> isAvailable,
      Value<int> rowid,
    });

class $$MediaItemsTableTableFilterComposer
    extends Composer<_$AppDatabase, $MediaItemsTableTable> {
  $$MediaItemsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get mediaStoreId => $composableBuilder(
    column: $table.mediaStoreId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fingerprint => $composableBuilder(
    column: $table.fingerprint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dateTaken => $composableBuilder(
    column: $table.dateTaken,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get relativePath => $composableBuilder(
    column: $table.relativePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<MediaType, MediaType, String> get mediaType =>
      $composableBuilder(
        column: $table.mediaType,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<bool> get isScreenshot => $composableBuilder(
    column: $table.isScreenshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<TriageDecision, TriageDecision, String>
  get decision => $composableBuilder(
    column: $table.decision,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get albumId => $composableBuilder(
    column: $table.albumId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get decidedAt => $composableBuilder(
    column: $table.decidedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<TriageDecision?, TriageDecision, String>
  get preQueueDecision => $composableBuilder(
    column: $table.preQueueDecision,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get preQueueAlbumId => $composableBuilder(
    column: $table.preQueueAlbumId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get trashedInSystem => $composableBuilder(
    column: $table.trashedInSystem,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get trashedAt => $composableBuilder(
    column: $table.trashedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isAvailable => $composableBuilder(
    column: $table.isAvailable,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MediaItemsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $MediaItemsTableTable> {
  $$MediaItemsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mediaStoreId => $composableBuilder(
    column: $table.mediaStoreId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fingerprint => $composableBuilder(
    column: $table.fingerprint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dateTaken => $composableBuilder(
    column: $table.dateTaken,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get relativePath => $composableBuilder(
    column: $table.relativePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mediaType => $composableBuilder(
    column: $table.mediaType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isScreenshot => $composableBuilder(
    column: $table.isScreenshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get decision => $composableBuilder(
    column: $table.decision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get albumId => $composableBuilder(
    column: $table.albumId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get decidedAt => $composableBuilder(
    column: $table.decidedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get preQueueDecision => $composableBuilder(
    column: $table.preQueueDecision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get preQueueAlbumId => $composableBuilder(
    column: $table.preQueueAlbumId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get trashedInSystem => $composableBuilder(
    column: $table.trashedInSystem,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get trashedAt => $composableBuilder(
    column: $table.trashedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isAvailable => $composableBuilder(
    column: $table.isAvailable,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MediaItemsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $MediaItemsTableTable> {
  $$MediaItemsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get mediaStoreId => $composableBuilder(
    column: $table.mediaStoreId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fingerprint => $composableBuilder(
    column: $table.fingerprint,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get dateTaken =>
      $composableBuilder(column: $table.dateTaken, builder: (column) => column);

  GeneratedColumn<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => column);

  GeneratedColumn<String> get mimeType =>
      $composableBuilder(column: $table.mimeType, builder: (column) => column);

  GeneratedColumn<String> get relativePath => $composableBuilder(
    column: $table.relativePath,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<MediaType, String> get mediaType =>
      $composableBuilder(column: $table.mediaType, builder: (column) => column);

  GeneratedColumn<bool> get isScreenshot => $composableBuilder(
    column: $table.isScreenshot,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<TriageDecision, String> get decision =>
      $composableBuilder(column: $table.decision, builder: (column) => column);

  GeneratedColumn<String> get albumId =>
      $composableBuilder(column: $table.albumId, builder: (column) => column);

  GeneratedColumn<DateTime> get decidedAt =>
      $composableBuilder(column: $table.decidedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TriageDecision?, String>
  get preQueueDecision => $composableBuilder(
    column: $table.preQueueDecision,
    builder: (column) => column,
  );

  GeneratedColumn<String> get preQueueAlbumId => $composableBuilder(
    column: $table.preQueueAlbumId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get trashedInSystem => $composableBuilder(
    column: $table.trashedInSystem,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get trashedAt =>
      $composableBuilder(column: $table.trashedAt, builder: (column) => column);

  GeneratedColumn<bool> get isAvailable => $composableBuilder(
    column: $table.isAvailable,
    builder: (column) => column,
  );
}

class $$MediaItemsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MediaItemsTableTable,
          MediaItemsTableData,
          $$MediaItemsTableTableFilterComposer,
          $$MediaItemsTableTableOrderingComposer,
          $$MediaItemsTableTableAnnotationComposer,
          $$MediaItemsTableTableCreateCompanionBuilder,
          $$MediaItemsTableTableUpdateCompanionBuilder,
          (
            MediaItemsTableData,
            BaseReferences<
              _$AppDatabase,
              $MediaItemsTableTable,
              MediaItemsTableData
            >,
          ),
          MediaItemsTableData,
          PrefetchHooks Function()
        > {
  $$MediaItemsTableTableTableManager(
    _$AppDatabase db,
    $MediaItemsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MediaItemsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MediaItemsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MediaItemsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> mediaStoreId = const Value.absent(),
                Value<String> fingerprint = const Value.absent(),
                Value<DateTime> dateTaken = const Value.absent(),
                Value<int> sizeBytes = const Value.absent(),
                Value<String> mimeType = const Value.absent(),
                Value<String> relativePath = const Value.absent(),
                Value<MediaType> mediaType = const Value.absent(),
                Value<bool> isScreenshot = const Value.absent(),
                Value<int?> durationMs = const Value.absent(),
                Value<TriageDecision> decision = const Value.absent(),
                Value<String?> albumId = const Value.absent(),
                Value<DateTime?> decidedAt = const Value.absent(),
                Value<TriageDecision?> preQueueDecision = const Value.absent(),
                Value<String?> preQueueAlbumId = const Value.absent(),
                Value<bool> trashedInSystem = const Value.absent(),
                Value<DateTime?> trashedAt = const Value.absent(),
                Value<bool> isAvailable = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MediaItemsTableCompanion(
                id: id,
                mediaStoreId: mediaStoreId,
                fingerprint: fingerprint,
                dateTaken: dateTaken,
                sizeBytes: sizeBytes,
                mimeType: mimeType,
                relativePath: relativePath,
                mediaType: mediaType,
                isScreenshot: isScreenshot,
                durationMs: durationMs,
                decision: decision,
                albumId: albumId,
                decidedAt: decidedAt,
                preQueueDecision: preQueueDecision,
                preQueueAlbumId: preQueueAlbumId,
                trashedInSystem: trashedInSystem,
                trashedAt: trashedAt,
                isAvailable: isAvailable,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int mediaStoreId,
                required String fingerprint,
                required DateTime dateTaken,
                required int sizeBytes,
                required String mimeType,
                required String relativePath,
                required MediaType mediaType,
                required bool isScreenshot,
                Value<int?> durationMs = const Value.absent(),
                required TriageDecision decision,
                Value<String?> albumId = const Value.absent(),
                Value<DateTime?> decidedAt = const Value.absent(),
                Value<TriageDecision?> preQueueDecision = const Value.absent(),
                Value<String?> preQueueAlbumId = const Value.absent(),
                Value<bool> trashedInSystem = const Value.absent(),
                Value<DateTime?> trashedAt = const Value.absent(),
                Value<bool> isAvailable = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MediaItemsTableCompanion.insert(
                id: id,
                mediaStoreId: mediaStoreId,
                fingerprint: fingerprint,
                dateTaken: dateTaken,
                sizeBytes: sizeBytes,
                mimeType: mimeType,
                relativePath: relativePath,
                mediaType: mediaType,
                isScreenshot: isScreenshot,
                durationMs: durationMs,
                decision: decision,
                albumId: albumId,
                decidedAt: decidedAt,
                preQueueDecision: preQueueDecision,
                preQueueAlbumId: preQueueAlbumId,
                trashedInSystem: trashedInSystem,
                trashedAt: trashedAt,
                isAvailable: isAvailable,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MediaItemsTableTable, MediaItemsTableData>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $MediaItemsTableTable,
                    MediaItemsTableData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MediaItemsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MediaItemsTableTable,
      MediaItemsTableData,
      $$MediaItemsTableTableFilterComposer,
      $$MediaItemsTableTableOrderingComposer,
      $$MediaItemsTableTableAnnotationComposer,
      $$MediaItemsTableTableCreateCompanionBuilder,
      $$MediaItemsTableTableUpdateCompanionBuilder,
      (
        MediaItemsTableData,
        BaseReferences<
          _$AppDatabase,
          $MediaItemsTableTable,
          MediaItemsTableData
        >,
      ),
      MediaItemsTableData,
      PrefetchHooks Function()
    >;
typedef $$AlbumsTableTableCreateCompanionBuilder =
    AlbumsTableCompanion Function({
      required String id,
      required String name,
      required DateTime createdAt,
      Value<String?> externalRef,
      Value<int> rowid,
    });
typedef $$AlbumsTableTableUpdateCompanionBuilder =
    AlbumsTableCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<DateTime> createdAt,
      Value<String?> externalRef,
      Value<int> rowid,
    });

class $$AlbumsTableTableFilterComposer
    extends Composer<_$AppDatabase, $AlbumsTableTable> {
  $$AlbumsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get externalRef => $composableBuilder(
    column: $table.externalRef,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AlbumsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $AlbumsTableTable> {
  $$AlbumsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get externalRef => $composableBuilder(
    column: $table.externalRef,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AlbumsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $AlbumsTableTable> {
  $$AlbumsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get externalRef => $composableBuilder(
    column: $table.externalRef,
    builder: (column) => column,
  );
}

class $$AlbumsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AlbumsTableTable,
          AlbumsTableData,
          $$AlbumsTableTableFilterComposer,
          $$AlbumsTableTableOrderingComposer,
          $$AlbumsTableTableAnnotationComposer,
          $$AlbumsTableTableCreateCompanionBuilder,
          $$AlbumsTableTableUpdateCompanionBuilder,
          (
            AlbumsTableData,
            BaseReferences<_$AppDatabase, $AlbumsTableTable, AlbumsTableData>,
          ),
          AlbumsTableData,
          PrefetchHooks Function()
        > {
  $$AlbumsTableTableTableManager(_$AppDatabase db, $AlbumsTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AlbumsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AlbumsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AlbumsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String?> externalRef = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AlbumsTableCompanion(
                id: id,
                name: name,
                createdAt: createdAt,
                externalRef: externalRef,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required DateTime createdAt,
                Value<String?> externalRef = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AlbumsTableCompanion.insert(
                id: id,
                name: name,
                createdAt: createdAt,
                externalRef: externalRef,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AlbumsTableTable, AlbumsTableData>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $AlbumsTableTable,
                    AlbumsTableData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AlbumsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AlbumsTableTable,
      AlbumsTableData,
      $$AlbumsTableTableFilterComposer,
      $$AlbumsTableTableOrderingComposer,
      $$AlbumsTableTableAnnotationComposer,
      $$AlbumsTableTableCreateCompanionBuilder,
      $$AlbumsTableTableUpdateCompanionBuilder,
      (
        AlbumsTableData,
        BaseReferences<_$AppDatabase, $AlbumsTableTable, AlbumsTableData>,
      ),
      AlbumsTableData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$MediaItemsTableTableTableManager get mediaItemsTable =>
      $$MediaItemsTableTableTableManager(_db, _db.mediaItemsTable);
  $$AlbumsTableTableTableManager get albumsTable =>
      $$AlbumsTableTableTableManager(_db, _db.albumsTable);
}
