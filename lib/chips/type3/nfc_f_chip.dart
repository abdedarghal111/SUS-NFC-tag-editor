// Base de la familia Type 3: FeliCa, con servicios y bloques de 16 bytes.

import '../nfc_chip.dart';

/// Chip de la familia Type 3 (NFC Forum), del estándar FeliCa de Sony.
///
/// Recoge lo que vale para toda la familia: el juego de comandos sin cifrar,
/// la forma del IDm y el tamaño de bloque. La memoria la pone cada modelo.
abstract class NfcFChip extends NfcChip {
  NfcFChip(super.tag);

  /// Longitud del IDm en bytes, el identificador que devuelve Polling.
  static const int idmLength = 8;

  /// Longitud del PMm en bytes, con los tiempos de respuesta del chip.
  static const int pmmLength = 8;

  /// Longitud de un bloque en bytes; FeliCa la fija para toda la familia.
  static const int blockSize = 16;

  /// Código de sistema que el NFC Forum reserva para las etiquetas NDEF.
  static const int ndefSystemCode = 0x12FC;

  /// Polling: busca etiquetas de un código de sistema y devuelve IDm y PMm.
  static const int polling = 0x00;

  /// Read Without Encryption: lee bloques de servicios sin autenticar.
  static const int readWithoutEncryption = 0x06;

  /// Write Without Encryption: graba bloques de servicios sin autenticar.
  static const int writeWithoutEncryption = 0x08;

  /// Código de sistema con el que el chip responde a Polling.
  int get systemCode;

  /// Bloques de usuario direccionables.
  int get userBlocks;

  /// Bytes de contenido disponibles para el usuario.
  int get userBytes;
}
