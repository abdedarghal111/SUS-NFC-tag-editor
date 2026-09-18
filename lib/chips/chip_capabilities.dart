// Lo que un chip permite hacer y con qué límites, para que la interfaz se
// dibuje sola sin conocer ningún modelo.

/// Forma de la contraseña de un chip.
class PasswordSpec {
  const PasswordSpec({required this.length});

  /// Bytes exactos que ocupa la contraseña; hay que rellenarlos todos.
  final int length;
}

/// Capacidades y límites del chip que hay delante.
class ChipCapabilities {
  const ChipCapabilities({
    this.maxContentBytes = 0,
    this.password,
    this.canProtectRead = false,
    this.hasCounter = false,
    this.firstProtectablePage,
  });

  /// Bytes de contenido que admite la etiqueta.
  final int maxContentBytes;

  /// Forma de su contraseña, o null si el modelo no tiene.
  final PasswordSpec? password;

  /// Indica si la protección puede alcanzar también a la lectura.
  final bool canProtectRead;

  /// Indica si lleva contador de lecturas.
  final bool hasCounter;

  /// Primera página desde la que se protege, o null si el modelo no protege.
  final int? firstProtectablePage;

  /// Indica si se puede grabar contenido.
  bool get canWrite => maxContentBytes > 0;

  /// Indica si hay algo que enseñar en la pantalla de seguridad.
  bool get hasSecurity => password != null;
}
