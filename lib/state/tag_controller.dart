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

  /// Cómo van los tres pasos de la prueba de la contraseña.
  ProbeProgress probeProgress = const ProbeProgress();

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
      phase == NfcPhase.lifting ||
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
        readProtected = security!.protectsReading;
        return security!;
      });

  /// Cómo van las páginas de la prueba de la memoria.
  MemoryProgress memoryProgress = const MemoryProgress();

  /// Resultado de la última prueba de la memoria.
  MemoryTest? memory;

  /// Páginas que se probarían con [bytes], recortado a lo que cabe.
  int get _memoryPages => capabilities.maxTestableBytes ~/ Type2Chip.pageSize;

  /// Escribe bytes al azar en [bytes], los relee y los borra.
  ///
  /// La rejilla se reinicia antes de pedir la etiqueta, para que se vea desde
  /// el primer momento cuántas páginas se van a probar.
  Future<void> testMemory() {
    memory = null;
    memoryProgress = MemoryProgress(
      blocks: List.filled(_memoryPages, MemoryBlockState.pending),
    );
    notifyListeners();

    return _run('Probando la memoria', (chip) async {
      final result = await chip.testMemory(
        onBlock: (index, state) {
          memoryProgress = memoryProgress.at(index, state);
          notifyListeners();
        },
        onPhase: (phase) {
          memoryProgress = memoryProgress.inPhase(
            phase,
            reset: phase != MemoryPhase.done,
          );
          notifyListeners();
        },
      );

      memory = result;
      content = const TagContent(payloads: [], usedBytes: 0);
      await _refreshInfo(chip);
      return result;
    });
  }

  /// Pone una contraseña, intenta escribir sin ella y la quita.
  ///
  /// Cada paso vuelve a enganchar la etiqueta desde cero: no aplica AUTH0
  /// hasta que se la selecciona de nuevo, así que probar por el mismo canal
  /// en el que se ha puesto la contraseña daría siempre que no protege.
  Future<void> probeProtection() async {
    probe = null;
    probeProgress = const ProbeProgress();
    notifyListeners();

    var payloads = const <NdefPayload>[];
    var skipped = false;

    _probeStep(ProbeProgress.setPassword, ProbeStepState.running);
    await _run('Poniendo la contraseña de prueba', fresh: true, (chip) async {
      final before = await chip.readSecurity();
      if (before.isLocked) {
        probe = ProtectionProbe.alreadyLocked(config: before.config);
        skipped = true;
        return before;
      }

      // Escribir con la etiqueta libre: si ya rechaza esto, que rechace
      // luego no dice nada de la contraseña.
      payloads = (await chip.readContent()).payloads;
      try {
        await chip.writeContent(payloads);
      } catch (error) {
        probe = ProtectionProbe.notWritable(config: before.config);
        skipped = true;
        return before;
      }

      return chip.setPassword(
        probePassword,
        fromPage:
            chip.capabilities.firstProtectablePage ?? Type2Chip.firstDataPage,
      );
    });

    if (skipped) {
      probeProgress = const ProbeProgress();
      notifyListeners();
      return;
    }
    if (error != null) {
      _probeStep(ProbeProgress.setPassword, ProbeStepState.failed);
      return;
    }
    _probeStep(
      ProbeProgress.setPassword,
      ProbeStepState.done,
      note:
          'Puesta la contraseña ${String.fromCharCodes(probePassword)} '
          '(${hexBytes(probePassword)}).',
    );

    _probeStep(ProbeProgress.write, ProbeStepState.running);
    var accepted = false;
    await _run('Escribiendo sin la contraseña', fresh: true, (chip) async {
      try {
        final report = await chip.writeContent(payloads);
        accepted = true;
        return report;
      } catch (error) {
        // Rechazar es lo que se espera de una etiqueta protegida.
        return const WriteReport(bytesWritten: 0, pagesWritten: 0);
      }
    });
    _probeStep(
      ProbeProgress.write,
      accepted ? ProbeStepState.failed : ProbeStepState.done,
      note: accepted
          ? 'La etiqueta ha dejado escribir.'
          : 'La etiqueta lo ha rechazado.',
    );

    _probeStep(ProbeProgress.removePassword, ProbeStepState.running);
    var unlocked = false;
    var config = const <int>[];
    await _run('Quitando la contraseña', fresh: true, (chip) async {
      final result = await chip.removePassword(probePassword);
      unlocked = true;
      config = (await chip.readSecurity()).config;
      _forgetSecurity();
      await _refreshInfo(chip);
      return result;
    });
    _probeStep(
      ProbeProgress.removePassword,
      unlocked ? ProbeStepState.done : ProbeStepState.failed,
      note: unlocked
          ? 'La etiqueta vuelve a estar libre.'
          : 'La etiqueta sigue bloqueada.',
    );

    probe = ProtectionProbe.tested(
      config: config,
      writeAccepted: accepted,
      password: probePassword,
      unlocked: unlocked,
    );
    notifyListeners();
  }

  /// Publica en qué punto va un paso de la prueba de la contraseña.
  void _probeStep(int index, ProbeStepState state, {String? note}) {
    probeProgress = probeProgress.at(index, state, note: note);
    notifyListeners();
  }

  /// Pone [password] y protege desde la primera página que admita el modelo.
  Future<void> setPassword(List<int> password, {bool protectReading = false}) =>
      _run('Poniendo la contraseña', (chip) async {
        final result = await chip.setPassword(
          password,
          fromPage:
              chip.capabilities.firstProtectablePage ?? Type2Chip.firstDataPage,
          protectReading: protectReading,
        );
        readProtected = protectReading;
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
  ///
  /// Con [fresh] la etiqueta se vuelve a seleccionar antes de empezar, que es
  /// lo que hace que aplique la protección que tenga guardada.
  Future<void> _run(
    String title,
    Future<TagResult> Function(Ntag21xChip chip) action, {
    bool fresh = false,
  }) async {
    if (busy) return;
    error = null;
    lastMessage = null;
    _action = title;
    notifyListeners();
    try {
      final result = await _reader.execute(
        identify: chosenModel == null,
        fresh: fresh,
        (tag, identified) async {
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
        },
      );
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
