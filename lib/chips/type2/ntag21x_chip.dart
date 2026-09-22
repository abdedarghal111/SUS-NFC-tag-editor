// Subfamilia NTAG21x: Type 2 con contraseña por AUTH0 y firma de fábrica.

import 'dart:math';

import '../chip_capabilities.dart';
import '../dictionaries/iso14443_bytes.dart';
import '../dictionaries/ntag_bytes.dart';
import '../results/tag_reading.dart';
import '../ndef/ndef_message_codec.dart';
import '../ndef/ndef_payload.dart';
import '../results/auth_result.dart';
import '../results/memory_test.dart';
import '../results/protection_result.dart';
import '../results/security_status.dart';
import '../results/tag_content.dart';
import '../results/tag_info.dart';
import '../results/write_report.dart';
import '../../utils/hex.dart';
import '../errors/capacity_exceeded_error.dart';
import '../errors/incomplete_response_error.dart';
import '../errors/nfc_error.dart';
import '../errors/password_rejected_error.dart';
import '../errors/protection_not_applied_error.dart';
import '../errors/read_rejected_error.dart';
import '../errors/write_rejected_error.dart';
import '../features/counted.dart';
import '../features/erasable.dart';
import '../features/identifiable.dart';
import '../features/originality_signed.dart';
import '../features/password_protected.dart';
import '../features/read_protected.dart';
import '../features/readable.dart';
import '../features/writable.dart';
import 'type2_chip.dart';

/// PACK que se graba al poner contraseña.
///
/// Es el acuse que devuelve PWD_AUTH y que comprueban los lectores que lo
/// verifican.
const List<int> defaultPack = [0x00, 0x00];

/// Contraseña que pone y quita la prueba de protección.
///
/// Es fija y conocida para poder desbloquear la etiqueta a mano si el chip se
/// queda con ella puesta.
const List<int> probePassword = [0x50, 0x52, 0x4F, 0x42];

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

  /// Primera página que ya no es contenido, y por tanto tope de los recorridos.
  ///
  /// Sale de la memoria que declara el modelo, no de la posición de CFG0: de
  /// por medio puede haber una página de bloqueo dinámico, que el NTAG210 no
  /// tiene. En el NTAG216 el contenido va de la 0x04 a la 0xE1.
  int get lastContentPage =>
      Type2Chip.firstDataPage + userBytes ~/ Type2Chip.pageSize;

  /// Añade lo propio de la familia a lo que ya traduce el tipo 2.
  @override
  List<TagReading> describeTag(TagInfo info) => [
    ...super.describeTag(info),
    if (info.manufacturer != null)
      TagReading(
        label: 'Fabricante',
        raw: hexByte(info.manufacturer!),
        notes: [describeManufacturer(info.manufacturer!)],
      ),
    if (info.product != null)
      TagReading(
        label: 'Tamaño',
        raw: hexByte(info.product!),
        notes: describeStorageSize(info.product!),
      ),
    if (info.config.isNotEmpty)
      TagReading(
        label: 'CFG0',
        raw: hexBytes(info.config),
        notes: describeConfig0(info.config),
      ),
  ];

  @override
  List<TagReading> describeSecurity(SecurityStatus security) => [
    TagReading(
      label: 'CFG0',
      raw: hexBytes(security.config),
      notes: describeConfig0(security.config),
    ),
    TagReading(
      label: 'ACCESS',
      raw: hexByte(security.access),
      notes: describeAccess(security.access),
    ),
    TagReading(
      label: 'PWD · PACK',
      raw:
          '${hexBytes(security.storedPassword)} · '
          '${hexBytes(security.storedPack)}',
      notes: describeStoredPassword(
        security.storedPassword,
        security.storedPack,
      ),
    ),
  ];

  /// Indica que la etiqueta tampoco deja leer sin contraseña.
  ///
  /// Lo pone la interfaz cuando la etiqueta ya ha rechazado una lectura: a
  /// partir de ahí no se la puede sondear antes de autenticarse.
  bool readProtected = false;

  @override
  ChipCapabilities get capabilities => ChipCapabilities(
    maxContentBytes: userBytes,
    maxTestableBytes: (lastPage + 1) * Type2Chip.pageSize,
    password: const PasswordSpec(length: 4),
    canProtectRead: true,
    hasCounter: hasNfcCounter,
    firstProtectablePage: Type2Chip.firstDataPage,
  );

  /// Indica si el modelo lleva el contador de lecturas NFC.
  ///
  /// El NTAG210 y el NTAG212 no lo tienen; el resto de la serie sí.
  bool get hasNfcCounter => true;

  /// Lee los 4 bytes de CFG0, donde vive AUTH0.
  Future<List<int>> readConfig() async {
    final bytes = await readPages(configPage0);
    return bytes.sublist(0, Type2Chip.pageSize);
  }

  @override
  Future<bool> matchesTag() async {
    final info = await readInfo();
    return info.product == storageByte;
  }

  @override
  Future<List<int>> readOriginalitySignature() async => readSignature();

  /// Autentica solo si la zona está protegida y hay contraseña que enviar.
  ///
  /// Una contraseña vacía significa no autenticar: la etiqueta responde igual
  /// que ante cualquier otra app.
  Future<AuthResult> _authenticate(List<int> password, int page) async {
    // Con la lectura protegida, CFG0 tampoco se deja leer, y su rechazo deja
    // la etiqueta fuera de la sesión: la contraseña tiene que ir por delante.
    final hasPassword = password.length == Type2Chip.pageSize;
    if (readProtected && hasPassword) {
      return AuthResult.accepted(await sendPassword(password));
    }

    List<int> config;
    try {
      config = await readConfig();
    } catch (error) {
      if (!hasPassword) rethrow;
      // CFG0 está por encima de AUTH0 y la lectura protegida lo tapa; con
      // contraseña en la mano todavía se puede entrar.
      tag.note('CFG0 no se deja leer sin contraseña', error);
      return AuthResult.accepted(await sendPassword(password));
    }

    final auth0 = config[Type2Chip.auth0Offset];
    if (!Type2Chip.requiresAuth(auth0, page)) {
      return const AuthResult.notProtected();
    }
    if (password.length != Type2Chip.pageSize) {
      tag.trace.add('Zona protegida y sin contraseña que enviar.');
      return const AuthResult.skipped();
    }
    return AuthResult.accepted(await sendPassword(password));
  }

  @override
  Future<TagContent> readContent({List<int> password = const []}) async {
    final authenticated = await _unlockIfNeeded(password, demand: true);

    final bytes = <int>[];
    var page = Type2Chip.firstDataPage;
    NdefLocation? location;

    while (page < lastContentPage) {
      try {
        bytes.addAll(await readPages(page));
      } catch (error) {
        throw _rejectedRead(authenticated, error);
      }
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

  /// Autentica antes de leer cuando se ha dado una contraseña.
  ///
  /// La contraseña va por delante de cualquier lectura: con la protección de
  /// lectura puesta, ni CFG0 se puede mirar para saber si hace falta.
  ///
  /// Entrada: la contraseña, y [demand] para exigir que la acepte. Salida: si
  /// la etiqueta la ha aceptado. Lanza [PasswordRejectedError] con [demand] si
  /// la rechaza, porque a partir de ahí no queda sesión con la que seguir.
  Future<bool> _unlockIfNeeded(
    List<int> password, {
    bool demand = false,
  }) async {
    if (password.length != Type2Chip.pageSize) return false;
    try {
      await sendPassword(password);
      return true;
    } catch (error) {
      if (NfcError.isConnectionLost(error)) rethrow;
      if (demand) throw PasswordRejectedError(cause: error.toString());
      tag.note('la etiqueta no ha aceptado la contraseña', error);
      return false;
    }
  }

  /// Traduce el rechazo de una lectura a un error que diga qué hacer.
  NfcError _rejectedRead(bool authenticated, Object error) {
    if (error is NfcError) return error;
    if (NfcError.isConnectionLost(error)) return NfcError.from(error);
    return ReadRejectedError(
      authenticated: authenticated,
      cause: error.toString(),
    );
  }

  @override
  Future<WriteReport> writeContent(
    List<NdefPayload> payloads, {
    List<int> password = const [],
  }) async {
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

  @override
  Future<WriteReport> eraseContent({List<int> password = const []}) async {
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
  @override
  Future<SecurityStatus> readSecurity({List<int> password = const []}) async {
    // Con la lectura protegida ni las páginas de configuración se dejan leer.
    final unlocked = await _unlockIfNeeded(password);

    List<int> bytes;
    try {
      bytes = await readPages(configPage0);
    } catch (error) {
      throw _rejectedRead(unlocked, error);
    }
    if (bytes.length < 16) {
      throw IncompleteResponseError(
        command: 'READ ${hexByte(configPage0)}',
        expected: 16,
        received: bytes.length,
      );
    }

    final config = bytes.sublist(0, Type2Chip.pageSize);
    final auth0 = config[Type2Chip.auth0Offset];
    final access = bytes[4];
    // Sin contraseña que probar no se prueba nada, y sin protección tampoco
    // habría contra qué: la etiqueta acepta cualquier cosa.
    final canTest =
        password.length == Type2Chip.pageSize &&
        auth0 != Type2Chip.noProtection &&
        (access & Type2Chip.authLimitMask) == 0;

    var correct = unlocked;
    if (!unlocked && canTest) {
      try {
        await sendPassword(password);
        correct = true;
      } catch (error) {
        tag.note('la contraseña no ha sido aceptada', error);
        correct = false;
      }
    }

    return SecurityStatus(
      config: config,
      access: access,
      storedPassword: bytes.sublist(8, 12),
      storedPack: bytes.sublist(12, 14),
      passwordChecked: unlocked || canTest,
      passwordCorrect: correct,
    );
  }

  @override
  Future<ProtectionResult> setPassword(
    List<int> password, {
    required int fromPage,
    bool protectReading = false,
  }) async {
    await _authenticate(password, passwordPage);

    final config = await readConfig();
    await writePage(passwordPage, password);
    await writePage(packPage, [...defaultPack, 0x00, 0x00]);

    // El alcance se fija siempre, no se hereda: PROT se queda escrito de una
    // vez anterior y si no se toca, la contraseña nueva taparía la lectura
    // sin haberlo pedido. Va antes que AUTH0, que es lo que cierra la puerta.
    await _writeReadProtection(protectReading);

    await writePage(configPage0, Type2Chip.withAuth0(config, fromPage));

    final updated = await readConfig();
    if (updated[Type2Chip.auth0Offset] != fromPage) {
      throw ProtectionNotAppliedError(
        message:
            'La etiqueta ha aceptado el comando pero no ha guardado la '
            'configuración: la contraseña no ha quedado puesta.',
        expected: fromPage,
        found: hexBytes(updated),
        offset: Type2Chip.auth0Offset,
      );
    }
    return ProtectionResult(updated[Type2Chip.auth0Offset]);
  }

  @override
  Future<ProtectionResult> removePassword(List<int> password) async {
    await _authenticate(password, configPage0);

    final config = await readConfig();
    // Se baja el alcance mientras todavía hay sesión autenticada, para que la
    // etiqueta quede como estaba y no arrastre el bit a la próxima
    // contraseña.
    await _writeReadProtection(false);
    await writePage(
      configPage0,
      Type2Chip.withAuth0(config, Type2Chip.noProtection),
    );

    final updated = await readConfig();
    if (updated[Type2Chip.auth0Offset] != Type2Chip.noProtection) {
      throw ProtectionNotAppliedError(
        message: 'La etiqueta ha aceptado el comando pero sigue bloqueada.',
        expected: Type2Chip.noProtection,
        found: hexBytes(updated),
        offset: Type2Chip.auth0Offset,
      );
    }
    return ProtectionResult(updated[Type2Chip.auth0Offset]);
  }

  /// Reúne UID, capacidad, estado de la protección, versión y firma.
  ///
  /// GET_VERSION y READ_SIG son los comandos que más clones rechazan, y un
  /// rechazo corta la conexión, así que van al final y sus fallos se absorben.
  @override
  Future<TagInfo> readInfo({List<int> password = const []}) async {
    await _unlockIfNeeded(password, demand: true);

    // Las páginas 0-3 se leen de una vez: son las que ninguna protección
    // tapa, y de ahí salen el CC y la capacidad que declara.
    final header = await readPages(0x00);
    final cc = header.length >= 16 ? header.sublist(12, 16) : const <int>[];
    final capacity = header.length >= 15 ? header[14] * 8 : 0;

    int? manufacturer;
    int? product;
    try {
      final version = await getVersion();
      if (version.length >= 7) {
        manufacturer = version[1];
        product = version[6];
      }
    } catch (error) {
      tag.note('la etiqueta no responde a GET_VERSION', error);
    }

    var hasSignature = false;
    try {
      final signature = await readSignature();
      hasSignature = signature.isNotEmpty && signature.any((byte) => byte != 0);
    } catch (error) {
      tag.note('la etiqueta no responde a READ_SIG', error);
    }

    // CFG0 va el último: cae dentro de la zona protegida, así que es lo
    // primero que rechaza una etiqueta que no deja leer, y su rechazo corta
    // la conversación. Todo lo anterior ya está recogido.
    var config = const <int>[];
    var readProtected = false;
    try {
      config = await readConfig();
    } catch (error) {
      tag.note('CFG0 no se deja leer: la lectura está protegida', error);
      readProtected = true;
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
      cc: cc,
      readProtected: readProtected,
    );
  }

  /// Lee el contador de lecturas con READ_CNT.
  ///
  /// Devuelve 0 si el contador está desactivado: la etiqueta rechaza el
  /// comando en vez de contestar cero.
  @override
  Future<int> readCounter() async {
    try {
      final bytes = await tag.send([0x39, 0x00], label: 'READ_CNT');
      if (bytes.length < 3) return 0;
      return bytes[0] | (bytes[1] << 8) | (bytes[2] << 16);
    } catch (error) {
      tag.note('la etiqueta no lleva el contador activado', error);
      return 0;
    }
  }

  /// Cambia el bit PROT de ACCESS, que extiende la protección a la lectura.
  ///
  /// Conserva el resto del byte: los otros bits llevan AUTHLIM y la
  /// configuración del contador.
  @override
  Future<ProtectionResult> setReadProtection(
    bool enabled, {
    List<int> password = const [],
  }) async {
    await _authenticate(password, configPage1);
    await _writeReadProtection(enabled);

    final config = await readConfig();
    return ProtectionResult(config[Type2Chip.auth0Offset]);
  }

  /// Pone o quita el bit PROT de ACCESS, conservando el resto del byte.
  ///
  /// Los demás bits llevan CFGLCK, el contador y el AUTHLIM, así que se
  /// releen y se vuelven a escribir tal cual.
  Future<void> _writeReadProtection(bool enabled) async {
    final page = await readPages(configPage1);
    final access = page[0];
    final updated = enabled
        ? access | Type2Chip.protectReadMask
        : access & ~Type2Chip.protectReadMask;
    if (updated == access) return;
    await writePage(configPage1, [updated, page[1], page[2], page[3]]);
  }

  /// Prueba la memoria escribiendo bytes al azar, releyéndolos y borrándolos.
  ///
  /// Entrada: cuántos bytes probar y un aviso por cada página que cambia de
  /// estado. Salida: el recuento de las tres fases. Lanza [WriteRejectedError]
  /// si la etiqueta está protegida.
  Future<MemoryTest> testMemory({
    required void Function(int index, MemoryBlockState state) onBlock,
    required void Function(MemoryPhase phase) onPhase,
  }) async {
    final auth = await _authenticate(const [], Type2Chip.firstDataPage);
    if (auth.wasProtected) {
      throw WriteRejectedError(
        operation: 'la prueba de la memoria',
        cause: 'AUTH0 protege la zona de contenido.',
      );
    }

    // Se recorre la etiqueta entera para verla completa, pero solo se toca la
    // zona de contenido: en la cabecera, el bloqueo y la configuración, unos
    // bytes al azar la romperían para siempre.
    const first = 0;
    final pages = lastPage + 1;
    bool writable(int index) =>
        index >= Type2Chip.firstDataPage && index < lastContentPage;

    var skipped = 0;
    for (var i = 0; i < pages; i++) {
      if (writable(i)) continue;
      skipped++;
      onBlock(i, MemoryBlockState.skipped);
    }
    final tested = pages - skipped;

    final random = Random();
    final expected = [
      for (var i = 0; i < pages; i++)
        List<int>.generate(Type2Chip.pageSize, (_) => random.nextInt(256)),
    ];

    int? firstBad;
    var aborted = false;
    // Páginas que han fallado en cualquiera de las tres fases: al terminar se
    // enseñan todas en rojo, no solo las de la última.
    final failed = <int>{};

    void markBad(int index) {
      firstBad ??= first + index;
      failed.add(index);
    }

    /// Escribe [values] página a página. Un rechazo se anota y se sigue; una
    /// caída de conexión corta la prueba, porque a partir de ahí fallaría
    /// todo y pintaría de rojo páginas que nadie ha llegado a probar.
    Future<int> writeAll(List<List<int>> values) async {
      var done = 0;
      for (var i = 0; i < pages; i++) {
        if (!writable(i)) continue;
        onBlock(i, MemoryBlockState.busy);
        try {
          await writePage(first + i, values[i]);
          done++;
          onBlock(i, MemoryBlockState.good);
        } catch (error) {
          if (NfcError.isConnectionLost(error)) {
            tag.note('la etiqueta se ha ido en la página ${first + i}', error);
            onBlock(i, MemoryBlockState.pending);
            aborted = true;
            return done;
          }
          tag.note('la etiqueta rechaza la página ${first + i}', error);
          markBad(i);
          onBlock(i, MemoryBlockState.bad);
        }
      }
      return done;
    }

    onPhase(MemoryPhase.writing);
    final written = await writeAll(expected);

    var verified = 0;
    var erased = 0;

    if (!aborted) {
      onPhase(MemoryPhase.reading);
      final read = await _verify(
        first,
        pages,
        expected,
        writable: writable,
        onBlock: onBlock,
        onBad: markBad,
      );
      verified = read.good;
      aborted = read.aborted;
    }

    if (!aborted) {
      onPhase(MemoryPhase.erasing);
      final zeros = List.filled(pages, List.filled(Type2Chip.pageSize, 0));
      await writeAll(zeros);
      if (!aborted) {
        final read = await _verify(
          first,
          pages,
          zeros,
          writable: writable,
          onBlock: onBlock,
          onBad: markBad,
        );
        erased = read.good;
        aborted = read.aborted;
      }
    }

    // La etiqueta se queda con un mensaje vacío pero válido, no a ceros.
    try {
      await writePage(Type2Chip.firstDataPage, NdefMessageCodec.emptyBlock());
    } catch (error) {
      tag.note('la etiqueta no se ha podido dejar utilizable', error);
    }

    // Recuento final: rojo el que haya fallado en alguna fase, verde el que
    // ha aguantado las tres.
    if (!aborted) {
      for (var i = 0; i < pages; i++) {
        if (!writable(i)) continue;
        onBlock(
          i,
          failed.contains(i) ? MemoryBlockState.bad : MemoryBlockState.good,
        );
      }
    }
    onPhase(MemoryPhase.done);
    return MemoryTest(
      declaredBytes: await _readCapacity(),
      writtenPages: written,
      verifiedPages: verified,
      erasedPages: erased,
      totalPages: tested,
      skippedPages: skipped,
      firstBadPage: firstBad,
      aborted: aborted,
    );
  }

  /// Relee las páginas probadas y las compara con lo que deberían tener.
  ///
  /// Salida: cuántas han devuelto exactamente lo esperado.
  Future<({int good, bool aborted})> _verify(
    int first,
    int pages,
    List<List<int>> expected, {
    required bool Function(int index) writable,
    required void Function(int index, MemoryBlockState state) onBlock,
    required void Function(int index) onBad,
  }) async {
    var good = 0;
    // READ devuelve cuatro páginas de una vez: se aprovecha el viaje.
    for (var i = 0; i < pages; i += 4) {
      List<int> chunk;
      try {
        chunk = await readPages(first + i);
      } catch (error) {
        if (NfcError.isConnectionLost(error)) {
          tag.note('la etiqueta se ha ido releyendo ${first + i}', error);
          return (good: good, aborted: true);
        }
        tag.note('la etiqueta rechaza releer desde ${first + i}', error);
        chunk = const [];
      }
      for (var j = i; j < i + 4 && j < pages; j++) {
        if (!writable(j)) continue;
        final offset = (j - i) * Type2Chip.pageSize;
        final read = chunk.length >= offset + Type2Chip.pageSize
            ? chunk.sublist(offset, offset + Type2Chip.pageSize)
            : const <int>[];
        final ok = _sameBytes(read, expected[j]);
        if (ok) {
          good++;
        } else {
          onBad(j);
        }
        onBlock(j, ok ? MemoryBlockState.good : MemoryBlockState.bad);
      }
    }
    return (good: good, aborted: false);
  }

  bool _sameBytes(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
