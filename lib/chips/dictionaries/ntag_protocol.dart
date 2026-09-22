// Diccionario del protocolo NTAG21x: qué se le manda, qué contesta y por qué
// rechaza.
//
// Todo lo de este archivo sale de la hoja de datos NTAG213/215/216 de NXP
// (rev. 3.2, 2 de junio de 2015). Cada comando lleva el apartado que lo
// describe, para poder contrastarlo sin volver a buscarlo.

/// Acuse de 4 bits con el que la etiqueta contesta (tabla 23).
///
/// Android no los deja ver: `NfcA.transceive` convierte cualquier NAK en un
/// `IOException` sin contenido, así que el motivo hay que deducirlo del
/// comando y del estado de la etiqueta, no del código.
enum NtagAck {
  ack(0xA, 'Acuse de recibo: el comando ha ido bien.'),
  invalidArgument(
    0x0,
    'Argumento inválido, normalmente una página que no existe.',
  ),
  crcError(0x1, 'Error de paridad o de CRC en la trama.'),
  authCounterOverflow(
    0x4,
    'El contador de intentos fallidos se ha desbordado.',
  ),
  eepromWriteError(0x5, 'La memoria no ha podido grabarse.');

  const NtagAck(this.code, this.meaning);

  /// Valor de 4 bits que manda la etiqueta.
  final int code;

  /// Qué significa, en lenguaje llano.
  final String meaning;
}

/// Motivo documentado por el que la etiqueta contesta NAK.
enum NtagRejection {
  pageOutOfRange(
    'La página no existe en este modelo.',
    'Comprueba el modelo: cada uno tiene una última página distinta.',
  ),
  readProtected(
    'La página está en la zona protegida y la lectura pide contraseña '
        '(AUTH0 y PROT=1).',
    'Autentícate con PWD_AUTH antes de leer.',
  ),
  writeProtected(
    'La página está en la zona protegida y escribir pide contraseña (AUTH0).',
    'Autentícate con PWD_AUTH antes de escribir.',
  ),
  lockedPage(
    'La página está bloqueada por los bits de lock, que no se pueden '
        'levantar.',
    'No hay arreglo: el bloqueo por lock bits es permanente.',
  ),
  configLocked(
    'Las páginas de configuración están cerradas para siempre (CFGLCK=1).',
    'No hay arreglo: solo PWD y PACK siguen siendo escribibles.',
  ),
  counterProtected(
    'El contador pide contraseña (NFC_CNT_PWD_PROT=1).',
    'Autentícate con PWD_AUTH antes de leer el contador.',
  ),
  wrongPassword(
    'La contraseña no es la de la etiqueta.',
    'Prueba con la contraseña correcta; ojo con el AUTHLIM.',
  ),
  authLimitReached(
    'Se ha agotado el AUTHLIM: la zona protegida queda cerrada para siempre, '
        'aunque la contraseña sea la buena.',
    'No hay arreglo: la etiqueta ya no acepta ninguna autenticación.',
  ),
  eepromWriteError(
    'La etiqueta no ha conseguido grabar la página.',
    'Déjala quieta sobre el teléfono y repite la operación.',
  ),
  notSupported(
    'El chip no conoce este comando.',
    'Es un clon que no implementa toda la familia NTAG21x.',
  );

  const NtagRejection(this.cause, this.fix);

  /// Qué ha pasado en la etiqueta.
  final String cause;

  /// Qué puede hacer el usuario al respecto.
  final String fix;
}

/// Comando del juego de instrucciones del NTAG21x (tabla 22, sección 10).
enum NtagCommand {
  getVersion(
    code: 0x60,
    label: 'GET_VERSION',
    section: '10.1',
    what: 'Pide los 8 bytes que identifican familia, versión y tamaño.',
    responseBytes: 8,
    addressed: false,
    writes: false,
    rejections: [NtagRejection.notSupported],
  ),
  read(
    code: 0x30,
    label: 'READ',
    section: '10.2',
    what: 'Lee cuatro páginas seguidas desde la indicada.',
    responseBytes: 16,
    addressed: true,
    writes: false,
    rejections: [NtagRejection.readProtected, NtagRejection.pageOutOfRange],
  ),
  fastRead(
    code: 0x3A,
    label: 'FAST_READ',
    section: '10.3',
    what: 'Lee de una vez todas las páginas entre dos direcciones.',
    responseBytes: null,
    addressed: true,
    writes: false,
    rejections: [
      NtagRejection.readProtected,
      NtagRejection.pageOutOfRange,
      NtagRejection.notSupported,
    ],
  ),
  write(
    code: 0xA2,
    label: 'WRITE',
    section: '10.4',
    what: 'Graba los 4 bytes de una página.',
    responseBytes: 1,
    addressed: true,
    writes: true,
    rejections: [
      NtagRejection.writeProtected,
      NtagRejection.lockedPage,
      NtagRejection.configLocked,
      NtagRejection.pageOutOfRange,
      NtagRejection.eepromWriteError,
    ],
  ),
  compatibilityWrite(
    code: 0xA0,
    label: 'COMPATIBILITY_WRITE',
    section: '10.5',
    what: 'Graba una página en dos tramas, para lectores antiguos.',
    responseBytes: 1,
    addressed: true,
    writes: true,
    rejections: [
      NtagRejection.writeProtected,
      NtagRejection.lockedPage,
      NtagRejection.configLocked,
      NtagRejection.pageOutOfRange,
      NtagRejection.eepromWriteError,
    ],
  ),
  readCounter(
    code: 0x39,
    label: 'READ_CNT',
    section: '10.6',
    what: 'Lee los 3 bytes del contador de lecturas.',
    responseBytes: 3,
    addressed: true,
    writes: false,
    rejections: [NtagRejection.counterProtected, NtagRejection.notSupported],
  ),
  passwordAuth(
    code: 0x1B,
    label: 'PWD_AUTH',
    section: '10.7',
    what: 'Verifica la contraseña de 4 bytes y devuelve el PACK.',
    responseBytes: 2,
    addressed: false,
    writes: false,
    rejections: [
      NtagRejection.wrongPassword,
      NtagRejection.authLimitReached,
      NtagRejection.notSupported,
    ],
  ),
  readSignature(
    code: 0x3C,
    label: 'READ_SIG',
    section: '10.8',
    what: 'Pide la firma ECC de 32 bytes grabada en fábrica.',
    responseBytes: 32,
    addressed: true,
    writes: false,
    rejections: [NtagRejection.notSupported],
  );

  const NtagCommand({
    required this.code,
    required this.label,
    required this.section,
    required this.what,
    required this.responseBytes,
    required this.addressed,
    required this.writes,
    required this.rejections,
  });

  /// Primer byte de la trama.
  final int code;

  /// Nombre con el que aparece en la hoja de datos y en la traza.
  final String label;

  /// Apartado de la hoja de datos que lo describe.
  final String section;

  /// Qué hace el comando.
  final String what;

  /// Bytes que devuelve cuando va bien, o null si depende de los argumentos.
  final int? responseBytes;

  /// Indica si el comando lleva una página como argumento.
  final bool addressed;

  /// Indica si el comando cambia la memoria.
  final bool writes;

  /// Motivos documentados por los que la etiqueta puede rechazarlo.
  final List<NtagRejection> rejections;

  /// Motivos que siguen en pie sabiendo si se ha autenticado o no.
  ///
  /// Estar autenticado descarta la protección por contraseña: la hoja de
  /// datos dice que en estado AUTHENTICATED los comandos se comportan como
  /// en una etiqueta sin proteger (secciones 10.1 a 10.6).
  List<NtagRejection> reasonsWhen({required bool authenticated}) {
    if (!authenticated) return rejections;
    return rejections
        .where(
          (reason) =>
              reason != NtagRejection.readProtected &&
              reason != NtagRejection.writeProtected &&
              reason != NtagRejection.counterProtected,
        )
        .toList();
  }
}

/// Explica por qué la etiqueta ha podido rechazar un comando.
///
/// Entrada: el comando y si se había autenticado. Salida: el motivo más
/// probable y qué hacer, o la lista de candidatos si hay más de uno.
String explainRejection(NtagCommand command, {bool authenticated = false}) {
  final reasons = command.reasonsWhen(authenticated: authenticated);
  final header =
      '${command.label} (0x${command.code.toRadixString(16).toUpperCase()}), '
      'apartado ${command.section} de la hoja de datos: ${command.what}';

  if (reasons.isEmpty) {
    return '$header\nRechazado sin motivo documentado.';
  }
  if (reasons.length == 1) {
    return '$header\n${reasons.first.cause} ${reasons.first.fix}';
  }
  return [
    header,
    'Motivos documentados por los que puede rechazarlo:',
    ...reasons.map((reason) => '· ${reason.cause} ${reason.fix}'),
  ].join('\n');
}
