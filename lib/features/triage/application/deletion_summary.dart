import 'package:gallery_triage_app/core/domain/enums/deletion_mode.dart';

/// 6.4.1 — "resumo... quantidade de itens processados e volume
/// correspondente, com texto condicionado ao modo". Guardado na sessão
/// pra sobreviver à navegação de volta da Revisão e aparecer de forma
/// permanente na tela de fim de fila (§7), não só como SnackBar
/// transitório.
class DeletionSummary {
  const DeletionSummary({
    required this.count,
    required this.mode,
    required this.freedBytes,
  });

  final int count;
  final DeletionMode mode;
  final int freedBytes;
}