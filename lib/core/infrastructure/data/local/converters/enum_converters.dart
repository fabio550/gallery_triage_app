import 'package:drift/drift.dart';

import 'package:gallery_triage_app/core/domain/enums/triage_decision.dart';

/// Grava o enum pelo nome (`values.byName`), não pelo índice — evita que
/// reordenar `TriageDecision`/`MediaType` no domínio corrompa dados já
/// persistidos.
class TriageDecisionConverter extends TypeConverter<TriageDecision, String> {
  const TriageDecisionConverter();

  @override
  TriageDecision fromSql(String fromDb) => TriageDecision.values.byName(fromDb);

  @override
  String toSql(TriageDecision value) => value.name;
}

class MediaTypeConverter extends TypeConverter<MediaType, String> {
  const MediaTypeConverter();

  @override
  MediaType fromSql(String fromDb) => MediaType.values.byName(fromDb);

  @override
  String toSql(MediaType value) => value.name;
}