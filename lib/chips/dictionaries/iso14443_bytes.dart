// Traducción de los bytes que define ISO/IEC 14443-3, comunes a cualquier
// etiqueta NFC-A sea de la familia que sea.

import '../../utils/hex.dart';

/// Códigos de fabricante conocidos, tal y como aparecen en el primer byte del
/// UID y en el byte 1 de GET_VERSION.
///
/// Solo está el que documenta la hoja de datos del NTAG21x. El registro
/// completo es el de ISO/IEC 7816-6 y no se reproduce aquí: un código que no
/// esté en esta lista se declara como no reconocido, que es más honesto que
/// adivinarlo.
const Map<int, String> manufacturerCodes = {0x04: 'NXP Semiconductors'};

/// Qué fabricante declara [code].
String describeManufacturer(int code) =>
    manufacturerCodes[code] ?? 'sin reconocer, NXP sería 0x04';

/// Qué dice el ATQA con el que la etiqueta contesta al sondeo.
///
/// Entrada: los bytes tal y como llegan. Salida: una frase por cada cosa que
/// se puede afirmar.
List<String> describeAtqa(List<int> atqa) {
  if (atqa.length != 2) return const [];

  // Android lo entrega con el byte bajo primero, pero no todos los lectores
  // coinciden: se acepta en cualquier orden.
  final isNtag =
      (atqa[0] == 0x44 && atqa[1] == 0x00) ||
      (atqa[0] == 0x00 && atqa[1] == 0x44);
  if (!isNtag) return const ['no es de un NTAG21x, que contesta 00 44'];

  return const ['NTAG21x', 'UID de 7 bytes'];
}

/// Qué dice el SAK con el que la etiqueta cierra la selección.
List<String> describeSak(int sak) {
  if (sak == 0x00) return const ['NTAG21x', 'tipo 2, sin ISO-DEP'];

  return [
    'no es de un NTAG21x, que contesta 0x00',
    if (sak & 0x04 != 0) 'UID incompleto',
    if (sak & 0x20 != 0) 'admite ISO-DEP, propio del tipo 4',
  ];
}

/// Qué dice el UID sobre quién fabricó el chip.
List<String> describeUid(List<int> uid) {
  if (uid.isEmpty) return const [];
  return [
    '${uid.length} bytes',
    'fabricante ${hexByte(uid.first)}: ${describeManufacturer(uid.first)}',
  ];
}
