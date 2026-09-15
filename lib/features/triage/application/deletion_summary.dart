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

  /// 4.4.5 — texto condicionado ao modo: lixeira menciona a retenção,
  /// definitivo informa o espaço liberado. Nunca anuncia espaço
  /// liberado que não aconteceu (modo lixeira não libera nada de fato
  /// até a purga do sistema, fora do controle do app). Fonte única —
  /// usado tanto pela Tela de Triagem (fim de fila) quanto pela Tela
  /// de Revisão (retorno da exclusão), pra não divergir de texto.
  String get text {
    if (mode == DeletionMode.trash) {
      return '$count itens movidos para a lixeira do sistema '
          '(retidos por cerca de 30 dias).';
    }
    final mb = (freedBytes / (1024 * 1024)).toStringAsFixed(0);
    return '$count itens excluídos — $mb MB liberados.';
  }
}