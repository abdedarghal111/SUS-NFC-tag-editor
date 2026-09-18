// Catálogo de modelos: la lista que se puede consultar sin etiqueta delante.

import 'chip_capabilities.dart';
import 'chip_gate.dart';
import 'nfc_chip.dart';
import 'classic/classic_1k_chip.dart';
import 'classic/classic_4k_chip.dart';
import 'classic/classic_mini_chip.dart';
import 'type1/topaz512_chip.dart';
import 'type1/topaz96_chip.dart';
import 'type2/ntag210_chip.dart';
import 'type2/ntag212_chip.dart';
import 'type2/ntag213_chip.dart';
import 'type2/ntag213f_chip.dart';
import 'type2/ntag215_chip.dart';
import 'type2/ntag216_chip.dart';
import 'type2/ntag216f_chip.dart';
import 'type2/ntag_i2c_1k_chip.dart';
import 'type2/ntag_i2c_2k_chip.dart';
import 'type2/ultralight_c_chip.dart';
import 'type2/ultralight_chip.dart';
import 'type2/ultralight_ev1_11_chip.dart';
import 'type2/ultralight_ev1_21_chip.dart';
import 'type3/felica_lite_s_chip.dart';
import 'type3/felica_standard_chip.dart';
import 'type4/desfire_ev1_chip.dart';
import 'type4/desfire_ev2_chip.dart';
import 'type4/desfire_ev3_chip.dart';
import 'type4/mifare_plus_chip.dart';
import 'type4/ntag424_dna_chip.dart';
import 'type4/st25ta_chip.dart';
import 'type5/icode_slix2_chip.dart';
import 'type5/icode_slix_chip.dart';
import 'type5/st25tv_chip.dart';
import 'typeb/sri512_chip.dart';

/// Familia a la que pertenece un modelo.
enum ChipFamily {
  type1('Type 1'),
  type2('Type 2'),
  type3('FeliCa'),
  type4('Type 4'),
  type5('ISO 15693'),
  classic('Mifare Classic'),
  typeB('ISO 14443-B');

  const ChipFamily(this.label);

  /// Nombre de la familia tal y como se enseña en pantalla.
  final String label;
}

/// Ficha de un modelo, para poder listarlo sin tener la etiqueta delante.
///
/// Lo que describe al modelo lo pone su clase de chip.
class ChipEntry {
  ChipEntry({required this.family, required this.builder})
    : _model = builder(null);

  /// Familia a la que pertenece.
  final ChipFamily family;

  /// Cómo se construye cuando haya canal.
  final ChipBuilder builder;

  /// Chip sin etiqueta, del que se leen los datos del modelo.
  final NfcChip _model;

  /// Nombre comercial del modelo.
  String get name => _model.name;

  /// Indica si la app sabe trabajar con este modelo.
  bool get enabled => _model.enabled;

  /// Indica si se ha probado contra una etiqueta real.
  bool get devTested => _model.devTested;

  /// Lo que permite hacer, para poder pintar la interfaz antes de leer nada.
  ChipCapabilities get capabilities => _model.capabilities;
}

/// Todos los modelos que la app reconoce, se puedan operar o no.
class ChipCatalog {
  const ChipCatalog._();

  /// Fichas de todos los modelos, en el orden en que se listan.
  static final List<ChipEntry> all = [
    ChipEntry(family: ChipFamily.type2, builder: Ntag216Chip.new),
    ChipEntry(family: ChipFamily.type2, builder: Ntag216fChip.new),
    ChipEntry(family: ChipFamily.type2, builder: Ntag215Chip.new),
    ChipEntry(family: ChipFamily.type2, builder: Ntag213Chip.new),
    ChipEntry(family: ChipFamily.type2, builder: Ntag213fChip.new),
    ChipEntry(family: ChipFamily.type2, builder: Ntag212Chip.new),
    ChipEntry(family: ChipFamily.type2, builder: Ntag210Chip.new),
    ChipEntry(family: ChipFamily.type2, builder: UltralightChip.new),
    ChipEntry(family: ChipFamily.type2, builder: UltralightCChip.new),
    ChipEntry(family: ChipFamily.type2, builder: UltralightEv111Chip.new),
    ChipEntry(family: ChipFamily.type2, builder: UltralightEv121Chip.new),
    ChipEntry(family: ChipFamily.type2, builder: NtagI2c1kChip.new),
    ChipEntry(family: ChipFamily.type2, builder: NtagI2c2kChip.new),
    ChipEntry(family: ChipFamily.classic, builder: ClassicMiniChip.new),
    ChipEntry(family: ChipFamily.classic, builder: Classic1kChip.new),
    ChipEntry(family: ChipFamily.classic, builder: Classic4kChip.new),
    ChipEntry(family: ChipFamily.type4, builder: DesfireEv1Chip.new),
    ChipEntry(family: ChipFamily.type4, builder: DesfireEv2Chip.new),
    ChipEntry(family: ChipFamily.type4, builder: DesfireEv3Chip.new),
    ChipEntry(family: ChipFamily.type4, builder: Ntag424DnaChip.new),
    ChipEntry(family: ChipFamily.type4, builder: MifarePlusChip.new),
    ChipEntry(family: ChipFamily.type4, builder: St25taChip.new),
    ChipEntry(family: ChipFamily.type5, builder: IcodeSlixChip.new),
    ChipEntry(family: ChipFamily.type5, builder: IcodeSlix2Chip.new),
    ChipEntry(family: ChipFamily.type5, builder: St25tvChip.new),
    ChipEntry(family: ChipFamily.type3, builder: FelicaLiteSChip.new),
    ChipEntry(family: ChipFamily.type3, builder: FelicaStandardChip.new),
    ChipEntry(family: ChipFamily.type1, builder: Topaz96Chip.new),
    ChipEntry(family: ChipFamily.type1, builder: Topaz512Chip.new),
    ChipEntry(family: ChipFamily.typeB, builder: Sri512Chip.new),
  ];

  /// Modelos de una familia, en el orden del catálogo.
  static List<ChipEntry> ofFamily(ChipFamily family) =>
      all.where((entry) => entry.family == family).toList();

  /// Familias que tienen algún modelo en el catálogo.
  static List<ChipFamily> get families =>
      all.map((entry) => entry.family).toSet().toList();
}
