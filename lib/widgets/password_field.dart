// Campo de contraseña de las operaciones que la piden.

import 'package:flutter/material.dart';

/// Campo donde se teclea la contraseña de la etiqueta.
///
/// La longitud la fija el modelo y hay que rellenarla entera.
class PasswordField extends StatelessWidget {
  const PasswordField({
    super.key,
    required this.field,
    required this.length,
    required this.enabled,
    required this.onChanged,
    this.optional = false,
  });

  /// Texto tecleado, que gobierna la pantalla que monta el campo.
  final TextEditingController field;

  /// Caracteres exactos que ocupa la contraseña en este modelo.
  final int length;

  final bool enabled;

  final VoidCallback onChanged;

  /// Indica que la operación tira adelante aunque se deje en blanco.
  final bool optional;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: field,
      enabled: enabled,
      maxLength: length,
      onChanged: (_) => onChanged(),
      decoration: InputDecoration(
        labelText: optional
            ? 'Contraseña ($length caracteres, opcional)'
            : 'Contraseña ($length caracteres)',
        helperText: optional
            ? 'Déjala en blanco si no quieres comprobarla'
            : 'Hay que rellenarlos todos, como en las demás apps',
        border: const OutlineInputBorder(),
      ),
    );
  }
}
