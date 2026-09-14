/// Estado da permissão de acesso à galeria (seção 4). Sem ela o app não
/// tem função (4.2.2) — todo o resto depende deste estado ser
/// [granted] ou [limited].
enum MediaPermissionStatus {
  /// Acesso total concedido.
  granted,

  /// Acesso parcial (4.2.1, API 34+): o usuário concedeu apenas itens
  /// escolhidos via `READ_MEDIA_VISUAL_USER_SELECTED`. Só existe nessa
  /// faixa de API — em versões anteriores o resultado é sempre
  /// [granted] ou negado.
  limited,

  /// Negado, mas o sistema ainda pode mostrar o diálogo de novo.
  denied,

  /// Negado permanentemente ("Não perguntar novamente") ou bloqueado
  /// por política — só as Configurações do sistema resolvem (4.2.2).
  permanentlyDenied,
}
