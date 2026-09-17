// Base de la familia Type 4: diálogo por APDU sobre ISO-DEP.

import '../nfc_chip.dart';

/// Chip de la familia Type 4 (NFC Forum), con sistema de ficheros y APDU.
///
/// Recoge lo que vale para toda la familia: la envoltura de las APDU y las
/// cifras de memoria, cifrado y organización que declara cada modelo.
abstract class IsoDepChip extends NfcChip {
  IsoDepChip(super.tag);

  /// Clase de APDU que envuelve los comandos nativos de NXP.
  static const int nativeClass = 0x90;

  /// Clase de APDU de los comandos ISO/IEC 7816-4 de toda la vida.
  static const int isoClass = 0x00;

  /// Instrucción GetVersion, que devuelve 28 bytes repartidos en tres tramos.
  static const int getVersionInstruction = 0x60;

  /// Instrucción que pide el siguiente tramo de una respuesta partida.
  static const int additionalFrameInstruction = 0xAF;

  /// Instrucción Read_Sig, que devuelve la firma ECC de fábrica.
  static const int readSignatureInstruction = 0x3C;

  /// Nombre DF de la aplicación NDEF del NFC Forum.
  static const List<int> ndefApplication = [
    0xD2,
    0x76,
    0x00,
    0x00,
    0x85,
    0x01,
    0x01,
  ];

  /// Valor de [maxApplications] cuando el límite lo pone solo la memoria.
  static const int applicationsLimitedByMemory = -1;

  /// Valor de [maxApplications] cuando el modelo no agrupa en aplicaciones.
  static const int withoutApplications = 0;

  /// Capacidades de memoria no volátil del modelo, en bytes.
  List<int> get storageSizes;

  /// Indica si el modelo autentica y cifra con AES de 128 bits.
  bool get usesAes;

  /// Indica si el modelo mantiene el cifrado DES y 3DES heredado.
  bool get usesTripleDes;

  /// Número máximo de aplicaciones que admite la etiqueta.
  int get maxApplications;

  /// Número máximo de ficheros dentro de cada aplicación.
  int get maxFilesPerApplication;
}
