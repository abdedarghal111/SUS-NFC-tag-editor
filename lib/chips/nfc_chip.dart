// Base común de todos los chips NFC que la app reconoce.

import '../nfc/tag_transceiver.dart';
import 'chip_source.dart';

/// Chip NFC identificado, sea cual sea su familia.
///
/// Un chip vale para una sola pasada: nace cuando se identifica la etiqueta,
/// atiende las operaciones que pida la app y se tira. La siguiente pasada
/// construye uno nuevo, así que no guarda estado entre una y otra.
abstract class NfcChip {
  NfcChip(this._tag);

  TagTransceiver _tag;

  /// Cómo se ha averiguado que la etiqueta es de este modelo.
  ///
  /// Lo fija [ChipGate] al identificar. Vale [ChipSource.assumed] mientras
  /// nadie lo haya comprobado, que es lo que pasa al crear el chip a mano.
  ChipSource source = ChipSource.assumed;

  /// Nombre comercial del modelo.
  String get name;

  /// Indica si la app admite trabajar con este modelo.
  ///
  /// Falso significa que la clase existe como catálogo pero sus operaciones no
  /// están escritas: la etiqueta se reconoce y se rechaza con aviso.
  bool get enabled;

  /// Indica si el modelo se ha probado contra una etiqueta real.
  ///
  /// Falso significa que el soporte está escrito según el datasheet pero nadie
  /// lo ha verificado con hardware en la mano.
  bool get devTested;

  /// Canal abierto con la etiqueta.
  TagTransceiver get tag => _tag;
}
