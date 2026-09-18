// Base común de todos los chips NFC que la app reconoce.

import '../nfc/tag_transceiver.dart';
import 'chip_capabilities.dart';
import 'chip_source.dart';

/// Chip NFC identificado, sea cual sea su familia.
///
/// Un chip vale para una sola pasada: nace cuando se identifica la etiqueta,
/// atiende las operaciones que pida la app y se tira. La siguiente pasada
/// construye uno nuevo, así que no guarda estado entre una y otra.
///
/// También es la ficha del modelo: [name], [enabled], [devTested] y
/// [capabilities] describen el chip y no la etiqueta, y se responden sin canal.
abstract class NfcChip {
  NfcChip(this._tag);

  final TagTransceiver? _tag;

  /// Cómo se ha averiguado que la etiqueta es de este modelo.
  ///
  /// Lo fija [ChipGate] al identificar, o vale [ChipSource.chosen] si el
  /// modelo lo ha puesto el usuario a mano.
  ChipSource source = ChipSource.chosen;

  /// Nombre comercial del modelo.
  String get name;

  /// Lo que este modelo permite hacer y con qué límites.
  ///
  /// La interfaz se dibuja a partir de esto, sin preguntar qué chip es. Por
  /// defecto no permite nada: lo rellena cada familia que sepa operar.
  ChipCapabilities get capabilities => const ChipCapabilities();

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
  ///
  /// Lanza [StateError] si el chip se construyó solo como ficha del modelo,
  /// sin etiqueta delante.
  TagTransceiver get tag {
    final channel = _tag;
    if (channel == null) {
      throw StateError('$name se ha construido como ficha, sin etiqueta.');
    }
    return channel;
  }
}
