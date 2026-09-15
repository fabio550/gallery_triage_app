/// Resultado de uma tentativa de exclusão/lixeira (4.3.4-4.3.6, §7).
enum DeletionOutcome {
  /// `RESULT_CANCELED`, ou nenhum item pôde ser mapeado pro sistema —
  /// fila intacta, nada mudou (4.3.6).
  cancelled,

  /// Alguns itens foram processados, outros não (§7 — "Exclusão
  /// parcialmente aplicada: reconciliar pelo retorno da chamada; itens
  /// não processados permanecem na fila").
  partial,

  /// Todos os itens solicitados foram processados.
  completed,
}
