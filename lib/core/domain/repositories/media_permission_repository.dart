import '../enums/media_permission_status.dart';

/// Autorização de acesso à galeria (seção 4). Implementação concreta
/// (`permission_handler`) vive na camada `data`/`infrastructure` — o
/// domínio não conhece o pacote de plataforma.
abstract class MediaPermissionRepository {
  /// Estado atual, sem disparar nenhum diálogo do sistema. Usado para
  /// decidir a tela inicial (dashboard, aviso de acesso parcial ou tela
  /// de permissão negada, §7) e para reavaliar ao voltar do primeiro
  /// plano ou das Configurações do sistema.
  Future<MediaPermissionStatus> status();

  /// Dispara o diálogo do sistema. Chamar de novo com a permissão já
  /// negada permanentemente não reabre nada — é o próprio Android que
  /// recusa; nesse caso o chamador precisa de [openSystemSettings].
  ///
  /// Em [MediaPermissionStatus.limited] (4.2.1), chamar de novo no
  /// Android 14+ reabre o seletor do sistema para ampliar a seleção —
  /// é o mecanismo por trás do atalho "ampliar a seleção" do aviso
  /// persistente, sem precisar sair para as Configurações.
  Future<MediaPermissionStatus> request();

  /// Atalho para a tela de permissões do app nas Configurações do
  /// sistema (4.2.2 — negação sem mais diálogo possível). Retorna
  /// `true` se o SO conseguiu abrir a tela.
  Future<bool> openSystemSettings();
}
