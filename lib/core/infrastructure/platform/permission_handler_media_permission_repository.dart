import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:gallery_triage_app/core/domain/enums/media_permission_status.dart';
import 'package:gallery_triage_app/core/domain/repositories/media_permission_repository.dart';
import 'package:permission_handler/permission_handler.dart';

/// Implementação Android via `permission_handler` (seção 4). O app não
/// tem suporte a iOS (1.2) — não há ramo de plataforma aqui além do
/// Android, só a faixa de API dentro dele varia.
class PermissionHandlerMediaPermissionRepository
    implements MediaPermissionRepository {
  PermissionHandlerMediaPermissionRepository({DeviceInfoPlugin? deviceInfo})
    : _deviceInfo = deviceInfo ?? DeviceInfoPlugin();

  final DeviceInfoPlugin _deviceInfo;

  @override
  Future<MediaPermissionStatus> status() async {
    final permissions = await _relevantPermissions();
    final statuses = await Future.wait(permissions.map((p) => p.status));
    return _combine(statuses);
  }

  @override
  Future<MediaPermissionStatus> request() async {
    final permissions = await _relevantPermissions();
    final statuses = await permissions.request();
    return _combine(statuses.values.toList());
  }

  @override
  Future<bool> openSystemSettings() => openAppSettings();

  /// `READ_MEDIA_IMAGES`/`READ_MEDIA_VIDEO` só existem a partir da API
  /// 33 — pedi-las abaixo disso seria um diálogo por um runtime
  /// permission que o SO nem reconhece (4.2). `permission_handler` não
  /// expõe o SDK_INT sozinho, daí o `device_info_plus` só pra essa
  /// leitura.
  Future<List<Permission>> _relevantPermissions() async {
    final sdkInt = await _sdkInt();
    // 4.1.1 — minSdk 30, então a faixa 30-32 sempre é alcançável.
    return sdkInt >= 33
        ? const [Permission.photos, Permission.videos]
        : const [Permission.storage];
  }

  Future<int> _sdkInt() async {
    if (!Platform.isAndroid) return 0;
    final info = await _deviceInfo.androidInfo;
    return info.version.sdkInt;
  }

  /// API 33+ pede fotos e vídeos juntas — não há tela que triagem só
  /// um dos dois (1.2), então a concessão é avaliada em conjunto.
  /// Prioridade granted > limited > permanentlyDenied > denied, do
  /// mais para o menos permissivo.
  MediaPermissionStatus _combine(List<PermissionStatus> statuses) {
    if (statuses.every((s) => s.isGranted)) {
      return MediaPermissionStatus.granted;
    }
    if (statuses.any((s) => s.isLimited)) {
      return MediaPermissionStatus.limited;
    }
    if (statuses.any((s) => s.isGranted)) {
      // Só uma das duas concedida (ex.: fotos sim, vídeos não) — trata
      // como parcial: a galeria fica incompleta do mesmo jeito que
      // 4.2.1 descreve, só que por tipo de mídia em vez de por item.
      return MediaPermissionStatus.limited;
    }
    if (statuses.any((s) => s.isPermanentlyDenied)) {
      return MediaPermissionStatus.permanentlyDenied;
    }
    return MediaPermissionStatus.denied;
  }
}
