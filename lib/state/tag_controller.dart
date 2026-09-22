// Estado de la sesión con la etiqueta, del que se alimenta la interfaz.

import 'package:flutter/foundation.dart';

import '../chips/chip_capabilities.dart';
import '../chips/chip_source.dart';
import '../chips/chip_catalog.dart';
import '../chips/chip_gate.dart';
import '../chips/chip_identification.dart';
import '../chips/errors/chip_not_available_error.dart';
import '../chips/errors/nfc_error.dart';
import '../chips/errors/nfc_unavailable_error.dart';
import '../chips/errors/read_rejected_error.dart';
import '../chips/errors/unknown_chip_error.dart';
import '../chips/errors/unsupported_feature_error.dart';
import '../chips/nfc_chip.dart';
import '../chips/type2/ntag21x_chip.dart';
import '../chips/type2/type2_chip.dart';
import '../chips/ndef/ndef_payload.dart';
import '../nfc/nfc_reader.dart';
import '../nfc/tag_transceiver.dart';
import '../utils/hex.dart';
import '../chips/results/counter_result.dart';
import '../chips/results/memory_test.dart';
import '../chips/results/probe_progress.dart';
import '../chips/results/protection_probe.dart';
import '../chips/results/security_status.dart';
import '../chips/results/tag_content.dart';
import '../chips/results/tag_info.dart';
import '../chips/results/tag_reading.dart';
import '../chips/results/tag_result.dart';
import '../chips/results/write_report.dart';

/// Guarda lo último que contestó la etiqueta y expone las acciones de la
/// interfaz como peticiones al chip que haya delante.
class TagController extends ChangeNotifier {
  TagController() {
    NfcReader.instance.phase.addListener(notifyListeners);
  }

  final NfcReader _reader = NfcReader.instance;

  /// Última ficha leída de la etiqueta.
  TagInfo? info;

  /// Último contenido leído de la etiqueta.
  TagContent? content;

  /// Última protección leída de la etiqueta.
  SecurityStatus? security;

  /// Última comprobación de si la protección se aplica de verdad.
  ProtectionProbe? probe;

  /// Última medición de la memoria real.
  CapacityProbe? capacity;

  /// Último valor leído del contador de lecturas.
  int? counter;

  /// Último chip identificado, para saber qué sabe hacer la etiqueta.
  NfcChip? chip;

  /// Modelo que el usuario ha elegido a mano, o null para detectarlo.
  ChipEntry? chosenModel;

  /// Nombre del modelo con el que se trabaja: el que hay delante o el elegido
  /// a mano, o null si todavía no hay ninguno.
  String? get modelName => chip?.name ?? chosenModel?.name;

  /// Lo que permite hacer el chip que haya delante, o el elegido a mano.
  ChipCapabilities get capabilities =>
      chip?.capabilities ??
      chosenModel?.capabilities ??
      const ChipCapabilities();

  /// Indica si el soporte del modelo con el que se trabaja está probado contra
  /// una etiqueta real; sin modelo todavía, no hay nada de lo que avisar.
  bool get tested => chip?.devTested ?? chosenModel?.devTested ?? true;

  /// Origen del modelo cuando todavía no se ha leído ninguna etiqueta.
  ChipSource? get sourceOfChoice =>
      chosenModel == null ? null : ChipSource.chosen;

  /// Fija el modelo con el que trabajar, o lo quita para volver a detectar.
  void chooseModel(ChipEntry? entry) {
    chosenModel = entry;
    chip = null;
    _forgetTag();
    notifyListeners();
  }

  /// Olvida todo lo leído de la etiqueta, que deja de valer al cambiar de
  /// modelo.
  void _forgetTag() {
    info = null;
    content = null;
    capacity = null;
    counter = null;
    _forgetSecurity();
  }

  /// Olvida lo leído sobre la protección, que deja de valer en cuanto se
  /// cambia.
  void _forgetSecurity() {
    security = null;
    probe = null;
  }

  /// Los bytes de la ficha traducidos por el chip que haya delante.
  ///
  /// Cada familia aporta los suyos, así que la interfaz los pinta sin saber
  /// con qué modelo trabaja.
  List<TagReading> get readings {
    final ficha = info;
    final found = chip;
    if (ficha == null || found == null) return const [];
    return found.describeTag(ficha);
  }

  /// Los bytes de la protección traducidos por el chip que haya delante.
  List<TagReading> get securityReadings {
    final status = security;
    final found = chip;
    if (status == null || found == null) return const [];
    return found.describeSecurity(status);
  }

  /// Indica que la etiqueta ha rechazado leer y hay que autenticarse antes de
  /// sondearla.
  ///
  /// Su rechazo tumba la sesión, así que en cuanto se sabe no se la vuelve a
  /// sondear sin contraseña por delante.
  bool readProtected = false;

  /// Última contraseña escrita, para no volver a teclearla en cada operación
  /// de protección.
  String password = '1234';

  /// Error pendiente; se queda hasta que se descarte a mano.
  NfcError? error;

  /// Resumen de la última operación que terminó bien.
  String? lastMessage;

  String _action = '';

  /// Título de la operación en curso, o cadena vacía si no hay ninguna.
  String get action => _action;

  /// Momento actual del diálogo con la etiqueta.
  NfcPhase get phase => _reader.phase.value;

  /// Indica si hay una operación esperando etiqueta o en marcha.
  bool get busy =>
      phase == NfcPhase.waiting ||
      phase == NfcPhase.working ||
      _action.isNotEmpty;

  /// Reserva el lector si el NFC está disponible.
  ///
  /// Que no lo esté no se avisa aquí: lo dice la operación que lo necesite.
  Future<void> start() async {
    try {
      await _reader.open();
    } on NfcUnavailableError {
      return;
    }
  }

  /// Suelta el lector.
  Future<void> stop() => _reader.close();

  /// Descarta la operación pendiente.
  void cancel() {
    _reader.cancel();
    _action = '';
    notifyListeners();
  }

  /// Descarta el error pendiente.
  void dismissError() {
    if (error == null) return;
    error = null;
    notifyListeners();
  }

  /// Compone el informe del error pendiente con la traza de comandos.
  ///
  /// Salida: el texto del informe, o cadena vacía si no hay error.
  String errorReport() {
    final current = error;
    if (current == null) return '';
    return [
      current.message,
      if (current.details.isNotEmpty) ...['', current.details],
      '',
      '--- comandos ---',
      ..._reader.trace,
    ].join('\n');
  }

  /// Lee de una pasada todo lo que la etiqueta cuenta de sí misma: contenido,
  /// ficha y contador.
  Future<void> inspectTag({List<int> password = const []}) =>
      _run('Leyendo la etiqueta', (chip) async {
        // La ficha primero: lo que la etiqueta cuenta siempre. El contenido
        // va después porque es lo que puede rechazar.
        final ficha = await chip.readInfo(password: password);
        info = ficha;
        readProtected = ficha.readProtected;
        content = null;
        counter = null;

        if (ficha.readProtected) {
          // Sin contraseña no hay nada más que sacarle. No es un fallo: es
          // el estado en el que está, y la ficha ya lo enseña.
          return ficha;
        }

        content = await chip.readContent(password: password);
        if (capabilities.hasCounter) {
          counter = await chip.readCounter();
        }
        return ficha;
      });

  /// Graba el contenido sin autenticarse: una etiqueta protegida lo rechaza.
  Future<void> writeContent(List<NdefPayload> payloads) => _run(
    'Grabando el contenido',
    (chip) async {
      final report = await chip.writeContent(payloads);
      content = TagContent(payloads: payloads, usedBytes: report.bytesWritten);
      return report;
    },
  );

  /// Borra el contenido sin autenticarse: una etiqueta protegida lo rechaza.
  Future<void> eraseContent() => _run('Borrando el contenido', (chip) async {
    final report = await chip.eraseContent();
    content = const TagContent(payloads: [], usedBytes: 0);
    return report;
  });

  /// Lee el estado de la protección autenticándose con [password].
  Future<void> readSecurity(List<int> password) =>
      _run('Mirando la protección', (chip) async {
        security = await chip.readSecurity(password: password);
        return security!;
      });

  /// Mide la memoria real escribiendo en todas las páginas de contenido.
  ///
  /// Se lleva por delante lo que hubiera grabado.
  Future<void> measureCapacity() => _run('Midiendo la memoria', (chip) async {
    capacity = await chip.measureCapacity();
    content = const TagContent(payloads: [], usedBytes: 0);
    await _refreshInfo(chip);
    return capacity!;
  });

  /// Comprueba si la etiqueta aplica de verdad la protección que declara.
  Future<void> probeProtection() =>
      _run('Comprobando la protección', (chip) async {
        probe = await chip.probeProtection();
        await _refreshInfo(chip);
        return probe!;
      });

  /// Pone [password] y protege desde la primera página que admita el modelo.
  Future<void> setPassword(List<int> password) =>
      _run('Poniendo la contraseña', (chip) async {
        final result = await chip.setPassword(
          password,
          fromPage:
              chip.capabilities.firstProtectablePage ?? Type2Chip.firstDataPage,
        );
        _forgetSecurity();
        await _refreshInfo(chip);
        return result;
      });

  /// Lee el contador de lecturas de la etiqueta.
  Future<void> readCounter() => _run('Leyendo el contador', (chip) async {
    counter = await chip.readCounter();
    return CounterResult(counter!);
  });

  /// Activa o levanta la protección de lectura autenticándose con [password].
  Future<void> setReadProtection(bool enabled, List<int> password) => _run(
    enabled ? 'Protegiendo la lectura' : 'Abriendo la lectura',
    (chip) async {
      final result = await chip.setReadProtection(enabled, password: password);
      _forgetSecurity();
      await _refreshInfo(chip);
      return result;
    },
  );

  /// Quita la contraseña y deja la etiqueta sin protección.
  Future<void> removePassword(List<int> password) =>
      _run('Quitando la contraseña', (chip) async {
        final result = await chip.removePassword(password);
        _forgetSecurity();
        await _refreshInfo(chip);
        return result;
      });

  /// Vuelve a leer la ficha sin soltar la etiqueta, para que el panel quede al
  /// día en cuanto termina la operación.
  ///
  /// Un fallo aquí no invalida la operación: la ficha se queda vacía.
  Future<void> _refreshInfo(Ntag21xChip chip) async {
    try {
      info = await chip.readInfo();
    } catch (error) {
      info = null;
    }
  }

  /// Decide con qué chip se trabaja: el elegido a mano, o el reconocido.
  ///
  /// Lanza [UnknownChipError] si no hay ninguno de los dos.
  NfcChip _resolve(TagTransceiver tag, ChipIdentification identified) {
    final choice = chosenModel;
    if (choice != null) {
      return ChipGate.force(choice.builder, tag);
    }
    if (identified is ChipRecognized) {
      return identified.chip;
    }
    throw const UnknownChipError();
  }

  /// Ejecuta una acción sobre el chip y reparte su resultado o su error.
  ///
  /// Comprueba antes que el chip sea un NTAG21x, la única familia que la app
  /// sabe manejar.
  Future<void> _run(
    String title,
    Future<TagResult> Function(Ntag21xChip chip) action,
  ) async {
    if (busy) return;
    error = null;
    lastMessage = null;
    _action = title;
    notifyListeners();
    try {
      final result = await _reader.execute(identify: chosenModel == null, (
        tag,
        identified,
      ) async {
        final found = _resolve(tag, identified);
        chip = found;
        if (!found.enabled) {
          throw ChipNotAvailableError(found.name);
        }
        if (found is! Ntag21xChip) {
          throw UnsupportedFeatureError(found.name, 'esta operación');
        }
        found.readProtected = readProtected;
        return action(found);
      });
      lastMessage = result.summary;
    } on NfcError catch (failure) {
      if (failure is ReadRejectedError) readProtected = true;
      error = failure;
    } catch (failure) {
      error = NfcError.from(failure);
    } finally {
      _action = '';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _reader.phase.removeListener(notifyListeners);
    _reader.close();
    super.dispose();
  }
}
