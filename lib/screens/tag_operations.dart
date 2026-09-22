// Catálogo de operaciones que se le pueden pedir a la etiqueta.

import 'package:flutter/material.dart';

import '../chips/ndef/ndef_payload.dart';
import '../state/tag_controller.dart';
import '../widgets/memory_card.dart';
import '../widgets/memory_grid.dart';
import '../widgets/probe_card.dart';
import '../widgets/probe_steps.dart';
import '../widgets/security_card.dart';
import '../widgets/tag_card.dart';

/// Apartado de la lista en el que cae cada operación.
enum OperationGroup {
  information('Información', 'Lo que la etiqueta cuenta sin cambiarla'),
  writing('Escritura', 'Cambia lo que hay grabado'),
  protection('Protección', 'Contraseña y bloqueo de la etiqueta'),
  experiments(
    'Experimentos',
    'Borran todo lo que tengas grabado y pueden dejar la etiqueta '
        'inservible. No entres si no sabes lo que haces.',
    danger: true,
  );

  const OperationGroup(this.label, this.hint, {this.danger = false});

  /// Nombre del apartado en la lista.
  final String label;

  /// Una línea diciendo qué se hace en el apartado.
  final String hint;

  /// Marca el apartado del que se puede salir con la etiqueta rota.
  final bool danger;
}

/// Lo que el usuario ha rellenado antes de lanzar la operación.
class OperationInput {
  const OperationInput({
    this.password = const [],
    this.payloads = const [],
    this.option = false,
  });

  /// Estado de la casilla que ofrezca la operación, si ofrece alguna.
  final bool option;

  /// Contraseña escrita, byte a byte; vacía si la operación no la pide.
  final List<int> password;

  /// Secciones de contenido montadas en el editor.
  final List<NdefPayload> payloads;
}

/// Operación de la lista: qué pide, qué ejecuta y qué enseña al terminar.
class TagOperation {
  const TagOperation({
    required this.group,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.run,
    this.needsPassword = false,
    this.passwordOptional = false,
    this.optionLabel,
    this.optionHint,
    this.needsContent = false,
    this.danger = false,
    this.warning,
    this.detail,
    this.progress,
  });

  /// Apartado en el que se lista la operación.
  final OperationGroup group;

  /// Icono de la fila y del botón que la lanza.
  final IconData icon;

  /// Nombre de la operación.
  final String title;

  /// Una línea diciendo qué hace, para la lista.
  final String subtitle;

  /// Explicación completa, para la pantalla de la operación.
  final String description;

  /// Ejecuta la operación con lo que se haya rellenado.
  final Future<void> Function(TagController controller, OperationInput input)
  run;

  /// Indica si hay que pedir la contraseña antes de lanzarla.
  final bool needsPassword;

  /// Indica que la contraseña se pide pero no hace falta rellenarla.
  ///
  /// La operación funciona sin ella y aporta algo más si se da.
  final bool passwordOptional;

  /// Casilla que la operación ofrece antes de lanzarse, o null si no ofrece.
  final String? optionLabel;

  /// Una línea explicando qué cambia la casilla.
  final String? optionHint;

  /// Indica si hay que montar contenido antes de lanzarla.
  final bool needsContent;

  /// Marca las operaciones de las que no se vuelve.
  final bool danger;

  /// Aviso que se enseña antes de ejecutarla.
  final String? warning;

  /// Detalle del resultado, o null si basta con el resumen.
  final Widget Function(TagController controller)? detail;

  /// Lo que se enseña mientras la operación está en marcha.
  final Widget Function(TagController controller)? progress;

  /// Indica si la operación arranca sola al abrir su pantalla.
  ///
  /// Las de información no cambian nada y no hay nada que confirmar. Las que
  /// piden contraseña esperan: un intento fallido cuenta para el AUTHLIM.
  bool get startsOnOpen =>
      group == OperationGroup.information && !needsPassword;
}

/// Operaciones que admite el chip que hay delante, en el orden de la lista.
///
/// Salida: solo las que el modelo permite y que tienen sentido con la
/// protección que la etiqueta tenga puesta ahora mismo.
List<TagOperation> operationsFor(TagController controller) {
  final can = controller.capabilities;
  final locked = controller.info?.isLocked ?? false;
  // Sin ficha no se sabe cómo está la etiqueta: con la lectura protegida no
  // se deja leer. Las operaciones que la abren tienen que seguir a mano.
  final unknown = controller.info == null;
  // Escribir y borrar nunca se autentican: con la etiqueta protegida se avisa
  // de que la va a rechazar.
  final lockedWarning = locked
      ? 'La etiqueta está protegida con contraseña y rechazará el cambio. '
            'Quítasela antes desde el apartado de protección.'
      : null;

  return [
    TagOperation(
      group: OperationGroup.information,
      icon: Icons.download_outlined,
      title: 'Leer la etiqueta',
      subtitle: 'Ficha, contenido y contador de una pasada',
      description:
          'Trae el UID, la capacidad, el estado de la protección y lo que '
          'tenga grabado.',
      run: (controller, input) => controller.inspectTag(),
      detail: (controller) => TagCard(
        model: controller.modelName ?? 'Sin modelo',
        info: controller.info,
        capabilities: controller.capabilities,
        source: controller.chip?.source ?? controller.sourceOfChoice,
        tested: controller.tested,
        readings: controller.readings,
        content: controller.content,
        counter: controller.counter,
      ),
    ),
    if (can.hasSecurity)
      TagOperation(
        group: OperationGroup.information,
        icon: Icons.key_outlined,
        title: 'Leer con contraseña',
        subtitle: 'Para las etiquetas que tampoco dejan leer sin ella',
        description:
            'Se autentica antes de leer. Hace falta cuando la etiqueta tiene '
            'protegida también la lectura y rechaza cualquier consulta.',
        needsPassword: true,
        run: (controller, input) =>
            controller.inspectTag(password: input.password),
        detail: (controller) => TagCard(
          model: controller.modelName ?? 'Sin modelo',
          info: controller.info,
          capabilities: controller.capabilities,
          source: controller.chip?.source ?? controller.sourceOfChoice,
          tested: controller.tested,
          readings: controller.readings,
          content: controller.content,
          counter: controller.counter,
        ),
      ),
    if (can.hasCounter)
      TagOperation(
        group: OperationGroup.information,
        icon: Icons.numbers_outlined,
        title: 'Leer el contador',
        subtitle: 'Veces que la etiqueta dice haberse leído',
        description:
            'El contador lo lleva la propia etiqueta y sube sola cada vez que '
            'se la lee.',
        run: (controller, input) => controller.readCounter(),
      ),
    if (can.hasSecurity)
      TagOperation(
        group: OperationGroup.information,
        icon: Icons.policy_outlined,
        title: 'Estado de la contraseña',
        subtitle: 'Qué protege y cuántos intentos quedan',
        description:
            'Lee la configuración de seguridad de la etiqueta: si tiene '
            'contraseña, qué impide hacer sin ella y cuántos intentos '
            'fallidos admite. La contraseña no hace falta; si la pones, '
            'además comprueba si es la suya.',
        needsPassword: true,
        passwordOptional: true,
        run: (controller, input) => controller.readSecurity(input.password),
        detail: (controller) => controller.security == null
            ? const SizedBox.shrink()
            : SecurityCard(
                security: controller.security!,
                readings: controller.securityReadings,
              ),
      ),
    if (can.canWrite)
      TagOperation(
        group: OperationGroup.writing,
        icon: Icons.edit_outlined,
        title: 'Escribir contenido',
        subtitle: 'Enlace, texto, teléfono, ubicación…',
        description:
            'Sustituye lo que haya grabado por las secciones que montes aquí.',
        needsContent: true,
        warning: lockedWarning,
        run: (controller, input) => controller.writeContent(input.payloads),
      ),
    if (can.canWrite)
      TagOperation(
        group: OperationGroup.writing,
        icon: Icons.layers_clear_outlined,
        title: 'Dejarla vacía',
        subtitle: 'Borra el contenido y la deja utilizable',
        description:
            'Graba un mensaje vacío: la etiqueta queda sin contenido pero '
            'sigue siendo válida.',
        warning: lockedWarning,
        danger: true,
        run: (controller, input) => controller.eraseContent(),
      ),
    if (can.hasSecurity && !locked)
      TagOperation(
        group: OperationGroup.protection,
        icon: Icons.lock_outline,
        title: 'Poner contraseña',
        subtitle: 'Protege la etiqueta de lectura y escritura',
        description:
            'Graba la contraseña y protege la etiqueta a partir de la primera '
            'página de contenido.',
        needsPassword: true,
        optionLabel: 'Proteger también la lectura',
        optionHint:
            'Sin marcar, la contraseña solo frena los cambios y cualquiera '
            'puede leer lo que tiene. Marcada, la etiqueta no cuenta nada '
            'sin ella.',
        warning: 'Si se olvida esta contraseña, no hay forma de recuperarla.',
        run: (controller, input) => controller.setPassword(
          input.password,
          protectReading: input.option,
        ),
      ),
    if (can.hasSecurity && (locked || unknown))
      TagOperation(
        group: OperationGroup.protection,
        icon: Icons.lock_open_outlined,
        title: 'Quitar la contraseña',
        subtitle: 'Deja la etiqueta abierta otra vez',
        description:
            'Devuelve la etiqueta a su estado abierto: cualquiera podrá '
            'escribir en ella.',
        needsPassword: true,
        run: (controller, input) => controller.removePassword(input.password),
      ),
    if (can.canProtectRead && (locked || unknown))
      TagOperation(
        group: OperationGroup.protection,
        icon: Icons.visibility_off_outlined,
        title: 'Proteger también la lectura',
        subtitle: 'Pedirá contraseña hasta para leer',
        description:
            'Sube la protección de la escritura a la lectura: sin contraseña '
            'la etiqueta no contará nada.',
        needsPassword: true,
        run: (controller, input) =>
            controller.setReadProtection(true, input.password),
      ),
    if (can.canProtectRead && (locked || unknown))
      TagOperation(
        group: OperationGroup.protection,
        icon: Icons.visibility_outlined,
        title: 'Dejar leer sin contraseña',
        subtitle:
            'La lectura vuelve a estar abierta; escribir sigue pidiendo '
            'contraseña',
        description:
            'Baja la protección a la escritura: la etiqueta vuelve a contar '
            'lo que tiene sin pedir nada.',
        needsPassword: true,
        run: (controller, input) =>
            controller.setReadProtection(false, input.password),
      ),
    if (can.hasSecurity)
      TagOperation(
        group: OperationGroup.experiments,
        icon: Icons.science_outlined,
        title: '¿La contraseña sirve de algo?',
        subtitle: 'Pone una contraseña, intenta escribir sin ella y la quita',
        description:
            'Un clon puede guardar la contraseña y luego no hacerle caso. '
            'La prueba pone una contraseña conocida, intenta escribir sin '
            'autenticarse y la quita al terminar. Si la escritura pasa, la '
            'protección es de adorno. Son tres pasos y cada uno necesita su '
            'propia pasada: la etiqueta te la pedirá tres veces.',
        warning:
            'La prueba pone y quita una contraseña de verdad. Si la etiqueta '
            'la acepta pero luego no deja quitarla, se queda bloqueada. Con '
            'una etiqueta ya bloqueada la prueba no se hace.',
        run: (controller, input) => controller.probeProtection(),
        progress: (controller) =>
            ProbeSteps(progress: controller.probeProgress),
        detail: (controller) => controller.probe == null
            ? const SizedBox.shrink()
            : ProbeCard(probe: controller.probe!),
      ),
    if (can.canWrite)
      TagOperation(
        group: OperationGroup.experiments,
        icon: Icons.straighten,
        title: '¿Tiene la memoria que dice?',
        subtitle: 'Escribe bytes al azar, los relee y los borra',
        description:
            'Los clones declaran más memoria de la que llevan. La prueba '
            'escribe bytes al azar página a página, los vuelve a leer para '
            'ver si son los mismos y los borra. Cada casilla es una página: '
            'verde si responde bien, roja si no. Las rayadas son la cabecera, '
            'el bloqueo y la configuración, que no se tocan.',
        warning:
            lockedWarning ??
            'La prueba borra lo que tengas grabado: escribe encima de todo el '
                'contenido y deja la etiqueta vacía.',
        danger: true,
        run: (controller, input) => controller.testMemory(),
        progress: (controller) =>
            MemoryGrid(progress: controller.memoryProgress),
        detail: (controller) => controller.memory == null
            ? const SizedBox.shrink()
            : MemoryCard(test: controller.memory!),
      ),
  ];
}
