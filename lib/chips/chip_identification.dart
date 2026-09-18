// Lo que da de sí identificar la etiqueta: se reconoce el modelo o no.

import 'nfc_chip.dart';

/// Lo que el portero ha averiguado de la etiqueta.
sealed class ChipIdentification {
  const ChipIdentification();
}

/// Se ha reconocido el modelo y el chip queda listo para trabajar.
class ChipRecognized extends ChipIdentification {
  const ChipRecognized(this.chip);

  /// Chip ya enganchado al canal de la etiqueta.
  final NfcChip chip;
}

/// No se ha reconocido el modelo.
///
/// Lleva lo que la etiqueta llegó a contestar, para poder enseñarlo y para que
/// el usuario elija modelo a mano si quiere.
class ChipUnknown extends ChipIdentification {
  const ChipUnknown({this.version});

  /// Respuesta a GET_VERSION, o null si la etiqueta la rechazó.
  final List<int>? version;
}
