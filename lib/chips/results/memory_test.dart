// Prueba de la memoria: escribir, releer y borrar página a página.

import 'tag_result.dart';

/// En qué punto está cada página de la prueba.
enum MemoryBlockState {
  /// Todavía no le ha llegado el turno.
  pending,

  /// Se está hablando con la etiqueta sobre ella.
  busy,

  /// Ha guardado y devuelto lo suyo.
  good,

  /// La ha rechazado, o ha devuelto algo que no era.
  bad,

  /// Queda fuera del contenido: no se escribe para no romper la etiqueta.
  skipped,
}

/// Fase por la que va la prueba.
enum MemoryPhase {
  writing('Escribiendo bytes al azar'),
  reading('Releyendo lo escrito'),
  erasing('Borrando y comprobando'),
  done('Terminada');

  const MemoryPhase(this.label);

  /// Lo que se está haciendo, para enseñarlo mientras pasa.
  final String label;
}

/// Estado de cada página mientras la prueba avanza.
class MemoryProgress {
  const MemoryProgress({
    this.firstPage = 0,
    this.blocks = const [],
    this.phase = MemoryPhase.writing,
  });

  /// Página de la etiqueta que corresponde al primer bloque.
  final int firstPage;

  /// Estado de cada página, en orden.
  final List<MemoryBlockState> blocks;

  /// Qué se está haciendo ahora mismo.
  final MemoryPhase phase;

  /// Páginas que han respondido bien hasta ahora.
  int get goodCount =>
      blocks.where((state) => state == MemoryBlockState.good).length;

  /// Páginas que han fallado.
  int get badCount =>
      blocks.where((state) => state == MemoryBlockState.bad).length;

  /// Devuelve el progreso con el bloque [index] en otro estado.
  MemoryProgress at(int index, MemoryBlockState state) => MemoryProgress(
    firstPage: firstPage,
    phase: phase,
    blocks: [
      for (var i = 0; i < blocks.length; i++)
        if (i == index) state else blocks[i],
    ],
  );

  /// Devuelve el progreso en otra fase, con los bloques otra vez en espera.
  ///
  /// Los que no se tocan se quedan como están: no van a cambiar en ninguna
  /// fase.
  MemoryProgress inPhase(MemoryPhase next, {bool reset = true}) =>
      MemoryProgress(
        firstPage: firstPage,
        phase: next,
        blocks: reset
            ? [
                for (final state in blocks)
                  state == MemoryBlockState.skipped
                      ? state
                      : MemoryBlockState.pending,
              ]
            : blocks,
      );
}

/// Veredicto de la prueba de la memoria.
class MemoryTest extends TagResult {
  const MemoryTest({
    required this.declaredBytes,
    required this.writtenPages,
    required this.verifiedPages,
    required this.erasedPages,
    required this.totalPages,
    this.skippedPages = 0,
    this.firstBadPage,
    this.aborted = false,
  });

  /// Bytes que la etiqueta declara en el CC.
  final int declaredBytes;

  /// Páginas que aceptaron la escritura.
  final int writtenPages;

  /// Páginas que devolvieron exactamente lo que se les escribió.
  final int verifiedPages;

  /// Páginas que quedaron a cero al borrarlas.
  final int erasedPages;

  /// Páginas que se han probado en total.
  final int totalPages;

  /// Páginas que se pidieron pero no se tocan: bloqueo y configuración.
  final int skippedPages;

  /// Primera página que falló, o null si no falló ninguna.
  final int? firstBadPage;

  /// La etiqueta se separó a media prueba y no se llegó al final.
  final bool aborted;

  /// Indica si la memoria ha aguantado las tres fases enteras.
  bool get passed =>
      !aborted &&
      writtenPages == totalPages &&
      verifiedPages == totalPages &&
      erasedPages == totalPages;

  /// Bytes que han respondido bien en las tres fases.
  int get realBytes => verifiedPages * 4;

  /// Titular del resultado.
  String get verdict {
    if (aborted) return 'La prueba se ha quedado a medias.';
    return passed
        ? 'La memoria es real: $realBytes bytes comprobados.'
        : 'La memoria falla: solo $realBytes de los ${totalPages * 4} bytes '
              'de contenido responden bien.';
  }

  /// Lo que ha pasado, en una frase.
  String get detail {
    if (aborted) {
      return 'La etiqueta se ha separado antes de terminar. Las páginas que '
          'quedaron en gris no se han llegado a probar: déjala quieta sobre '
          'el teléfono y repite.';
    }
    if (passed) {
      return 'Se escribieron bytes al azar, se releyeron uno a uno y se '
          'borraron; todo coincidió.';
    }
    final page = firstBadPage;
    return [
      if (page != null) 'La primera página que falla es la $page.',
      'Escritas $writtenPages de $totalPages, releídas bien $verifiedPages, '
          'borradas $erasedPages.',
    ].join(' ');
  }

  @override
  String get summary => verdict;
}
