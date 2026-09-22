// Sesión con el hardware NFC: engancha la etiqueta y ejecuta sobre ella.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:nfc_manager/nfc_manager.dart';

import '../chips/chip_gate.dart';
import '../chips/chip_identification.dart';
import '../chips/errors/nfc_error.dart';
import '../chips/errors/nfc_unavailable_error.dart';
import '../chips/errors/reader_busy_error.dart';
import '../chips/errors/unsupported_tag_error.dart';
import 'tag_transceiver.dart';

/// Momento del diálogo con la etiqueta, para que la interfaz sepa qué pedir.
enum NfcPhase { idle, waiting, working, removing }

/// Lo que se quiere hacer con la etiqueta cuando aparezca.
typedef ChipAction<T> =
    Future<T> Function(TagTransceiver tag, ChipIdentification identified);

/// Única puerta de acceso al hardware NFC: solo transporte, nada de
/// contraseñas ni de NDEF.
///
/// La sesión sigue abierta mientras la app está en primer plano para que el
/// sistema no capture la etiqueta por su cuenta.
class NfcReader {
  NfcReader._();

  /// Lector compartido por toda la app.
  static final NfcReader instance = NfcReader._();

  /// Momento actual del diálogo con la etiqueta.
  final ValueNotifier<NfcPhase> phase = ValueNotifier(NfcPhase.idle);

  /// Traza de la última operación, en orden de envío.
  final List<String> trace = [];

  /// Margen por respuesta. Los clones tardan más que un NXP auténtico y con el
  /// valor por defecto de Android la conexión se da por perdida.
  static const int _transceiveTimeoutMs = 1200;

  static const int _maxAttempts = 3;

  ChipAction<Object?>? _pending;
  bool _identify = true;
  Completer<Object?>? _completer;
  int _attempt = 0;
  bool _sessionOpen = false;
  bool _running = false;

  /// Cuenta de acciones lanzadas, para que la espera de retirada de una no
  /// pise el estado de la siguiente.
  int _generation = 0;

  /// Indica si hay una acción esperando etiqueta o ejecutándose.
  bool get isBusy => _pending != null || _running;

  /// Reserva el lector para la app.
  ///
  /// Lanza [NfcUnavailableError] si el teléfono no tiene lector o lo tiene
  /// apagado, y en ese caso suelta la sesión que hubiera reservada.
  ///
  /// El estado se pregunta siempre, porque apagar el NFC mata la sesión sin
  /// avisar.
  Future<void> open() async {
    switch (await NfcManager.instance.checkAvailability()) {
      case NfcAvailability.unsupported:
        await close();
        throw const NfcUnavailableError.unsupported();
      case NfcAvailability.disabled:
        await close();
        throw const NfcUnavailableError.disabled();
      case NfcAvailability.enabled:
        break;
    }
    if (_sessionOpen) return;

    await NfcManager.instance.startSession(
      pollingOptions: {NfcPollingOption.iso14443},
      onDiscovered: _onDiscovered,
    );
    _sessionOpen = true;
  }

  /// Libera el lector y corta cualquier acción pendiente.
  Future<void> close() async {
    if (!_sessionOpen) return;
    _sessionOpen = false;
    _pending = null;
    _running = false;
    phase.value = NfcPhase.idle;
    final completer = _completer;
    _completer = null;
    if (completer != null && !completer.isCompleted) {
      completer.completeError(
        const NfcError('La operación se ha cortado al soltar el lector.'),
      );
    }
    try {
      await NfcManager.instance.stopSession();
    } catch (error) {
      trace.add('No se ha podido cerrar la sesión: $error');
    }
  }

  /// Ejecuta [action] sobre el chip de la primera etiqueta que aparezca.
  ///
  /// Con [identify] en false no se pregunta el modelo, que es lo que conviene
  /// cuando ya lo ha elegido el usuario: así no se manda GET_VERSION, el
  /// comando que más clones rechazan cortando la conexión.
  ///
  /// Lanza [NfcError] si el NFC no está disponible, si ya hay otra acción en
  /// marcha o si la etiqueta rechaza algún comando.
  Future<T> execute<T>(ChipAction<T> action, {bool identify = true}) async {
    if (isBusy) {
      throw const ReaderBusyError();
    }
    await open();

    trace.clear();
    _generation++;
    final completer = Completer<Object?>();
    _identify = identify;
    _pending = (tag, identified) async => await action(tag, identified);
    _completer = completer;
    _attempt = 1;
    phase.value = NfcPhase.waiting;
    await _restartPolling();
    return await completer.future as T;
  }

  /// Descarta la acción pendiente sin soltar el lector.
  void cancel() {
    _pending = null;
    _completer = null;
    phase.value = NfcPhase.idle;
  }

  /// Reinicia el modo lector para que el sondeo vuelva a empezar.
  ///
  /// Android solo avisa cuando la etiqueta entra en el campo, así que sin este
  /// reinicio una etiqueta ya apoyada en el teléfono no se detectaría.
  Future<void> _restartPolling() async {
    if (!_sessionOpen) return;
    try {
      await NfcManager.instance.stopSession();
      await Future<void>.delayed(const Duration(milliseconds: 200));
      await NfcManager.instance.startSession(
        pollingOptions: {NfcPollingOption.iso14443},
        onDiscovered: _onDiscovered,
      );
    } catch (error) {
      _sessionOpen = false;
      trace.add('No se ha podido reiniciar la detección: $error');
    }
  }

  /// Identifica la etiqueta descubierta y le aplica la acción pendiente;
  /// reintenta desde el principio si la conexión se cae.
  Future<void> _onDiscovered(NfcTag tag) async {
    final action = _pending;
    final completer = _completer;
    if (action == null || completer == null || _running) return;

    _pending = null;
    _running = true;
    phase.value = NfcPhase.working;

    TagTransceiver? transceiver;
    var willRetry = false;
    try {
      transceiver = TagTransceiver.from(tag, trace);
      if (transceiver == null) {
        throw const UnsupportedTagError();
      }
      await transceiver.applyTimeout(_transceiveTimeoutMs);
      final identified = _identify
          ? await ChipGate.identify(transceiver)
          : const ChipUnknown();
      completer.complete(await action(transceiver, identified));
    } catch (error) {
      willRetry = NfcError.isConnectionLost(error) && _attempt < _maxAttempts;
      if (!willRetry) {
        completer.completeError(
          error is NfcError ? error : NfcError.from(error),
        );
      }
    }

    if (willRetry) {
      await _retry(action, completer);
      return;
    }

    _running = false;
    _completer = null;
    await _waitForRemoval(transceiver);
  }

  /// Vuelve a dejar la acción pendiente y reinicia el sondeo.
  ///
  /// La etiqueta suele seguir apoyada, así que el reinicio del modo lector la
  /// recupera al instante.
  Future<void> _retry(
    ChipAction<Object?> action,
    Completer<Object?> completer,
  ) async {
    _attempt++;
    _running = false;
    _pending = action;
    _completer = completer;
    trace.add(
      '-- se perdió la conexión, intento $_attempt de $_maxAttempts --',
    );
    phase.value = NfcPhase.waiting;
    await _restartPolling();
  }

  /// Espera a que la etiqueta salga del campo; se rinde a los nueve segundos.
  Future<void> _waitForRemoval(TagTransceiver? transceiver) async {
    final generation = _generation;
    if (transceiver == null || !_sessionOpen) {
      phase.value = NfcPhase.idle;
      return;
    }
    phase.value = NfcPhase.removing;
    for (var attempt = 0; attempt < 30; attempt++) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      // Otra acción ha tomado el relevo: el estado ya es suyo.
      if (!_sessionOpen || generation != _generation) return;
      if (!await transceiver.isPresent()) break;
    }
    if (generation != _generation) return;
    phase.value = NfcPhase.idle;
  }
}
