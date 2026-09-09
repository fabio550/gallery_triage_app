import 'package:flutter/material.dart';

/// Cor determinística a partir do id do item — placeholder visual
/// enquanto não existe miniatura real (photo_manager). Substituído
/// quando o provider de miniatura existir; até lá, ao menos distingue
/// itens diferentes nos testes com dados mockados.
Color mediaPlaceholderColor(String id) {
  final hue = (id.hashCode % 360).abs().toDouble();
  return HSLColor.fromAHSL(1, hue, 0.35, 0.30).toColor();
}
