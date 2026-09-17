// Subfamilia NTAG21x: Type 2 con contraseña por AUTH0 y firma de fábrica.

import '../ndef/ndef_message_codec.dart';
import '../ndef/ndef_payload.dart';
import '../results/auth_result.dart';
import '../results/protection_probe.dart';
import '../results/protection_result.dart';
import '../results/security_status.dart';
import '../results/tag_content.dart';
import '../results/tag_info.dart';
import '../results/write_report.dart';
import '../../utils/hex.dart';
import '../errors/capacity_exceeded_error.dart';
import '../errors/incomplete_response_error.dart';
import '../errors/nfc_error.dart';
import '../errors/protection_not_applied_error.dart';
import '../errors/write_rejected_error.dart';
import '../features/counted.dart';
import '../features/erasable.dart';
import '../features/identifiable.dart';
import '../features/originality_signed.dart';
import '../features/password_protected.dart';
import '../features/read_protected.dart';
import '../features/readable.dart';
import '../features/writable.dart';
import 'auth0_layout.dart';
import 'type2_chip.dart';

/// PACK que se graba al poner contraseña; su valor concreto es indiferente.
const List<int> kDefaultPack = [0x1A, 0x2B];

/// Chip de la serie NTAG21x de NXP.
///
/// Los siete modelos comparten comandos y mecanismo de protección; solo
/// cambian el tamaño y las direcciones de las páginas de configuración, que
/// aporta cada subclase.
abstract class Ntag21xChip extends Type2Chip
    implements
        Readable,
        Writable,
        Erasable,
        PasswordProtected,
        ReadProtected,
        OriginalitySigned,
        Counted,
        Identifiable {
  Ntag21xChip(super.tag);

  /// Bytes que se leen buscando la cabecera NDEF antes de rendirse.
  static const int _searchLimit = 64;

  /// Byte de tamaño que devuelve GET_VERSION en este modelo.
  int get storageByte;

  /// Bytes de contenido disponibles para el usuario.
  int get userBytes;

  /// Última página direccionable; leer más allá devuelve error.
  int get lastPage;

  /// Página CFG0, donde vive AUTH0.
  int get configPage0;

  /// Página CFG1, con el byte ACCESS.
  int get configPage1 => configPage0 + 1;

  /// Página que guarda la contraseña de 4 bytes.
  int get passwordPage => configPage0 + 2;

  /// Página que guarda el PACK de 2 bytes.
  int get packPage => configPage0 + 3;

  /// Primera página de configuración: el contenido nunca llega hasta ahí.
  int get lastContentPage => configPage0 - 3;

  /// Posición de AUTH0 dentro de CFG0 con la que se trabaja.
  ///
  /// El estándar lo pone en el último byte; los clones que miran el primero se
  /// atienden cambiando este valor desde la interfaz.
  Auth0Layout layout = Auth0Layout.standard;

  /// Lee los 4 bytes de CFG0, donde vive AUTH0.
  Future<List<int>> readConfig() async {
    final bytes = await readPages(configPage0);
    return bytes.sublist(0, Type2Chip.pageSize);
  }

  @override
  Future<TagContent> readContent({List<int> password = const []}) =>
      run(() => _readContent(password));

  @override
  Future<WriteReport> writeContent(
    List<NdefPayload> payloads, {
    List<int> password = const [],
  }) => run(() => _writeContent(payloads, password));

  @override
  Future<WriteReport> eraseContent({List<int> password = const []}) =>
      run(() => _eraseContent(password));

  @override
  Future<SecurityStatus> readSecurity({List<int> password = const []}) =>
      run(() => _readSecurity(password));

  @override
  Future<ProtectionResult> setPassword(
    List<int> password, {
    required int fromPage,
  }) => run(() => _setPassword(password, fromPage));

  @override
  Future<ProtectionResult> removePassword(List<int> password) =>
      run(() => _removePassword(password));

  @override
  Future<TagInfo> readInfo() => run(_readInfo);

  @override
  Future<bool> matchesTag() => run(() async {
    final info = await _readInfo();
    return info.product == storageByte;
  });

  @override
  Future<int> readCounter() => run(_readCounter);

  @override
  Future<List<int>> readOriginalitySignature() =>
      run(() async => readSignature());

  @override
  Future<ProtectionResult> setReadProtection(
    bool enabled, {
    List<int> password = const [],
  }) => run(() => _setReadProtection(enabled, password));

  /// Comprueba si la etiqueta aplica de verdad la protección que declara.
  ///
  /// Leer CFG0 solo cuenta lo que dice; un clon puede guardar el valor y no
  /// hacerle caso. La prueba concluyente es escribir sin autenticarse.
  Future<ProtectionProbe> probeProtection() => run(_probeProtection);

  /// Autentica solo si la zona está protegida y hay contraseña autorizada.
  ///
  /// Una contraseña vacía significa no autenticar: la etiqueta responde igual
  /// que ante cualquier otra app.
  Future<AuthResult> _authenticate(List<int> password, int page) async {
    final config = await readConfig();
    final auth0 = config[layout.offset];
    if (!Type2Chip.requiresAuth(auth0, page)) {
      return const AuthResult.notProtected();
    }
    if (password.length != Type2Chip.pageSize) {
      tag.trace.add('Zona protegida, pero no se ha autorizado la contraseña.');
      return const AuthResult.skipped();
    }
    return AuthResult.accepted(await sendPassword(password));
  }

  Future<TagContent> _readContent(List<int> password) async {
    await _unlockIfNeeded(password);

    final bytes = <int>[];
    var page = Type2Chip.firstDataPage;
    NdefLocation? location;

    while (page < lastContentPage) {
      bytes.addAll(await readPages(page));
      page += 4;
      location ??= NdefMessageCodec.locate(bytes);
      if (location != null && bytes.length >= location.end) break;
      if (location == null && bytes.length >= _searchLimit) break;
    }

    if (location == null) {
      return const TagContent(payloads: [], usedBytes: 0);
    }

    final message = bytes.sublist(
      location.start,
      location.end.clamp(location.start, bytes.length),
    );
    return TagContent(
      payloads: NdefMessageCodec.decode(message),
      usedBytes: location.length,
    );
  }

  /// Autentica antes de leer si hay protección y se conoce la contraseña.
  ///
  /// Un chip protegido puede cortar la conexión en mitad de la lectura en vez
  /// de responder con un rechazo limpio.
  Future<void> _unlockIfNeeded(List<int> password) async {
    if (password.length != Type2Chip.pageSize) return;
    final config = await readConfig();
    if (config[layout.offset] == Type2Chip.noProtection) return;
    await sendPassword(password);
  }

  Future<WriteReport> _writeContent(
    List<NdefPayload> payloads,
    List<int> password,
  ) async {
    final block = NdefMessageCodec.encode(payloads);
    await _ensureFits(block.length);

    final auth = await _authenticate(password, Type2Chip.firstDataPage);

    try {
      for (
        var offset = 0;
        offset < block.length;
        offset += Type2Chip.pageSize
      ) {
        await writePage(
          Type2Chip.firstDataPage + offset ~/ Type2Chip.pageSize,
          block.sublist(offset, offset + Type2Chip.pageSize),
        );
      }
    } catch (error) {
      throw _rejectedWrite(auth, error, 'la escritura');
    }

    return WriteReport(
      bytesWritten: block.length,
      pagesWritten: block.length ~/ Type2Chip.pageSize,
    );
  }

  Future<WriteReport> _eraseContent(List<int> password) async {
    final auth = await _authenticate(password, Type2Chip.firstDataPage);
    final block = NdefMessageCodec.emptyBlock();
    try {
      await writePage(Type2Chip.firstDataPage, block);
    } catch (error) {
      throw _rejectedWrite(auth, error, 'el borrado');
    }
    return WriteReport(bytesWritten: block.length, pagesWritten: 1);
  }

  /// Explica un rechazo cuando la etiqueta estaba protegida y no se autenticó.
  NfcError _rejectedWrite(AuthResult auth, Object error, String what) {
    if (auth.wasProtected && !auth.authenticated) {
      return WriteRejectedError(operation: what, cause: error.toString());
    }
    return error is NfcError ? error : NfcError.from(error);
  }

  /// Verifica contra el CC que el bloque quepa antes de escribir nada.
  Future<void> _ensureFits(int size) async {
    final capacity = await _readCapacity();
    if (capacity > 0 && size > capacity) {
      throw CapacityExceededError(needed: size, available: capacity);
    }
  }

  /// Capacidad declarada en el CC de la página 3, en bytes.
  Future<int> _readCapacity() async {
    final header = await readPages(0x00);
    return header.length >= 15 ? header[14] * 8 : 0;
  }

  /// Lee CFG0, CFG1, PWD y PACK de una vez y prueba la contraseña.
  ///
  /// La prueba se omite si AUTHLIM no es cero: cada fallo acercaría la
  /// etiqueta a un bloqueo permanente.
  Future<SecurityStatus> _readSecurity(List<int> password) async {
    final bytes = await readPages(configPage0);
    if (bytes.length < 16) {
      throw IncompleteResponseError(
        command: 'READ ${hexByte(configPage0)}',
        expected: 16,
        received: bytes.length,
      );
    }

    final config = bytes.sublist(0, Type2Chip.pageSize);
    final auth0 = config[layout.offset];
    final access = bytes[4];
    final canTest =
        auth0 != Type2Chip.noProtection &&
        (access & Type2Chip.authLimitMask) == 0;

    var correct = false;
    if (canTest) {
      try {
        await sendPassword(password);
        correct = true;
      } catch (_) {
        correct = false;
      }
    }

    return SecurityStatus(
      config: config,
      layout: layout,
      access: access,
      storedPassword: bytes.sublist(8, 12),
      storedPack: bytes.sublist(12, 14),
      passwordChecked: canTest,
      passwordCorrect: correct,
    );
  }

  Future<ProtectionResult> _setPassword(
    List<int> password,
    int fromPage,
  ) async {
    await _authenticate(password, passwordPage);

    final config = await readConfig();
    await writePage(passwordPage, password);
    await writePage(packPage, [...kDefaultPack, 0x00, 0x00]);
    await writePage(configPage0, Type2Chip.withAuth0(config, fromPage, layout));

    final updated = await readConfig();
    if (updated[layout.offset] != fromPage) {
      throw ProtectionNotAppliedError(
        message:
            'La etiqueta ha aceptado el comando pero no ha guardado la '
            'configuración: la contraseña no ha quedado puesta.',
        expected: fromPage,
        found: hexBytes(updated),
        offset: layout.offset,
      );
    }
    return ProtectionResult(updated[layout.offset]);
  }

  Future<ProtectionResult> _removePassword(List<int> password) async {
    await _authenticate(password, configPage0);

    final config = await readConfig();
    await writePage(
      configPage0,
      Type2Chip.withAuth0(config, Type2Chip.noProtection, layout),
    );

    final updated = await readConfig();
    if (updated[layout.offset] != Type2Chip.noProtection) {
      throw ProtectionNotAppliedError(
        message: 'La etiqueta ha aceptado el comando pero sigue bloqueada.',
        expected: Type2Chip.noProtection,
        found: hexBytes(updated),
        offset: layout.offset,
      );
    }
    return ProtectionResult(updated[layout.offset]);
  }

  /// Reúne UID, capacidad, estado de la protección, versión y firma.
  ///
  /// GET_VERSION y READ_SIG son los comandos que más clones rechazan, y un
  /// rechazo corta la conexión, así que van al final y sus fallos se absorben.
  Future<TagInfo> _readInfo() async {
    final capacity = await _readCapacity();
    final config = await readConfig();

    int? manufacturer;
    int? product;
    try {
      final version = await getVersion();
      if (version.length >= 7) {
        manufacturer = version[1];
        product = version[6];
      }
    } catch (_) {
      tag.trace.add('La etiqueta no responde a GET_VERSION.');
    }

    var hasSignature = false;
    try {
      final signature = await readSignature();
      hasSignature = signature.isNotEmpty && signature.any((byte) => byte != 0);
    } catch (_) {
      tag.trace.add('La etiqueta no responde a READ_SIG.');
    }

    return TagInfo(
      uid: tag.uid,
      atqa: tag.atqa,
      sak: tag.sak,
      capacityBytes: capacity,
      manufacturer: manufacturer,
      product: product,
      hasSignature: hasSignature,
      config: config,
      layout: layout,
    );
  }

  /// Lee el contador de lecturas con READ_CNT.
  ///
  /// Devuelve 0 si el contador está desactivado: la etiqueta rechaza el
  /// comando en vez de contestar cero.
  Future<int> _readCounter() async {
    try {
      final bytes = await tag.send([0x39, 0x00], label: 'READ_CNT');
      if (bytes.length < 3) return 0;
      return bytes[0] | (bytes[1] << 8) | (bytes[2] << 16);
    } catch (_) {
      tag.trace.add('La etiqueta no lleva el contador activado.');
      return 0;
    }
  }

  /// Cambia el bit PROT de ACCESS, que extiende la protección a la lectura.
  ///
  /// Conserva el resto del byte: los otros bits llevan AUTHLIM y la
  /// configuración del contador.
  Future<ProtectionResult> _setReadProtection(
    bool enabled,
    List<int> password,
  ) async {
    await _authenticate(password, configPage1);

    final page = await readPages(configPage1);
    final access = page[0];
    final updated = enabled
        ? access | Type2Chip.protectReadMask
        : access & ~Type2Chip.protectReadMask;
    await writePage(configPage1, [updated, page[1], page[2], page[3]]);

    final config = await readConfig();
    return ProtectionResult(config[layout.offset]);
  }

  /// Reescribe la primera página de contenido con su propio valor, sin
  /// autenticar, y observa si la etiqueta lo acepta.
  Future<ProtectionProbe> _probeProtection() async {
    final config = await readConfig();
    final page = await readPages(Type2Chip.firstDataPage);
    final original = page.sublist(0, Type2Chip.pageSize);

    var accepted = false;
    try {
      await writePage(Type2Chip.firstDataPage, original);
      accepted = true;
    } catch (_) {
      tag.trace.add('La etiqueta ha rechazado la escritura sin contraseña.');
    }

    return ProtectionProbe(
      config: config,
      layout: layout,
      writeAccepted: accepted,
    );
  }
}
