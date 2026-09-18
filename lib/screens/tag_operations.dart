// Catálogo de operaciones que se le pueden pedir a la etiqueta.

import 'package:flutter/material.dart';

import '../chips/ndef/ndef_payload.dart';
import '../state/tag_controller.dart';
import '../widgets/capacity_card.dart';
import '../widgets/probe_card.dart';
import '../widgets/security_card.dart';
import '../widgets/tag_card.dart';

/// Apartado de la lista en el que cae cada operación.
enum OperationGroup {
  information('Información', 'Lo que la etiqueta cuenta sin cambiarla'),
  writing('Escritura', 'Cambia lo que hay grabado'),
  protection('Protección', 'Contraseña y bloqueo de la etiqueta'),
  experiments(
    'Experimentos',
    'Pruebas que maltratan la etiqueta para ver si cumple lo que declara',
  );

  const OperationGroup(this.label, this.hint);

  /// Nombre del apartado en la lista.
  final String label;

  /// Una línea diciendo qué se hace en el apartado.
  final String hint;
}

/// Lo que el usuario ha rellenado antes de lanzar la operación.
class OperationInput {
  const OperationInput({this.password = const [], this.payloads = const []});

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
    this.needsContent = false,
    this.tunesAuth0 = false,
    this.danger = false,
    this.warning,
    this.detail,
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

  /// Indica si hay que montar contenido antes de lanzarla.
  final bool needsContent;

  /// Marca las operaciones de las que no se vuelve.
  final bool danger;

  /// Aviso que se enseña antes de ejecutarla.
  final String? warning;

  /// Detalle del resultado, o null si basta con el resumen.
  final Widget Function(TagController controller)? detail;

  /// Indica si la operación trabaja con AUTH0 y admite elegir su posición.
  final bool tunesAuth0;

  /// Indica si la operación arranca sola al abrir su pantalla.
  ///
  /// Las de información no cambian nada y no hay nada que confirmar.
  bool get startsOnOpen => group == OperationGroup.information;
}

/// Operaciones que admite el chip que hay delante, en el orden de la lista.
///
/// Salida: solo las que el modelo permite y que tienen sentido con la
/// protección que la etiqueta tenga puesta ahora mismo.
List<TagOperation> operationsFor(TagController controller) {
  final can = controller.capabilities;
  final locked = controller.info?.isLocked ?? false;
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
        subtitle: 'Qué protege, cuántos intentos quedan y si la tuya vale',
        description:
            'Lee la configuración de seguridad de la etiqueta: si tiene '
            'contraseña, qué impide hacer sin ella, cuántos intentos fallidos '
            'admite y si la que escribas es la suya.',
        needsPassword: true,
        run: (controller, input) => controller.readSecurity(input.password),
        detail: (controller) => controller.security == null
            ? const SizedBox.shrink()
            : SecurityCard(security: controller.security!),
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
        subtitle: 'Hará falta para escribir en la etiqueta',
        description:
            'Graba la contraseña y protege la etiqueta a partir de la primera '
            'página de contenido.',
        needsPassword: true,
        tunesAuth0: true,
        warning: 'Si se olvida esta contraseña, no hay forma de recuperarla.',
        run: (controller, input) => controller.setPassword(input.password),
      ),
    if (can.hasSecurity && locked)
      TagOperation(
        group: OperationGroup.protection,
        icon: Icons.lock_open_outlined,
        title: 'Quitar la contraseña',
        subtitle: 'Deja la etiqueta abierta otra vez',
        description:
            'Devuelve la etiqueta a su estado abierto: cualquiera podrá '
            'escribir en ella.',
        needsPassword: true,
        tunesAuth0: true,
        run: (controller, input) => controller.removePassword(input.password),
      ),
    if (can.canProtectRead && locked)
      TagOperation(
        group: OperationGroup.protection,
        icon: Icons.visibility_off_outlined,
        title: 'Proteger también la lectura',
        subtitle: 'Pedirá contraseña hasta para leer',
        description:
            'Sube la protección de la escritura a la lectura: sin contraseña '
            'la etiqueta no contará nada.',
        needsPassword: true,
        tunesAuth0: true,
        run: (controller, input) =>
            controller.setReadProtection(true, input.password),
      ),
    if (can.hasSecurity)
      TagOperation(
        group: OperationGroup.experiments,
        icon: Icons.science_outlined,
        title: '¿La contraseña sirve de algo?',
        subtitle: 'Intenta escribir sin ella y mira si la etiqueta lo rechaza',
        description:
            'Un clon puede guardar la contraseña y luego no hacerle caso. '
            'Esta prueba intenta escribir sin autenticarse y compara lo que '
            'pasa con lo que la etiqueta declara.',
        warning:
            'La prueba escribe en la etiqueta: si la deja pasar, el contenido '
            'cambia.',
        tunesAuth0: true,
        run: (controller, input) => controller.probeProtection(),
        detail: (controller) => controller.probe == null
            ? const SizedBox.shrink()
            : ProbeCard(probe: controller.probe!),
      ),
    if (can.canWrite)
      TagOperation(
        group: OperationGroup.experiments,
        icon: Icons.straighten,
        title: '¿Tiene la memoria que dice?',
        subtitle: 'Escribe en todas las páginas para ver cuántas hay de verdad',
        description:
            'Los clones que declaran más memoria de la que llevan repiten la '
            'que tienen. La prueba escribe una marca distinta en cada página '
            'y mira desde dónde empieza a repetirse o a fallar.',
        warning:
            lockedWarning ??
            'La prueba borra lo que tengas grabado: escribe encima de todo el '
                'contenido y deja la etiqueta vacía.',
        danger: true,
        run: (controller, input) => controller.measureCapacity(),
        detail: (controller) => controller.capacity == null
            ? const SizedBox.shrink()
            : CapacityCard(capacity: controller.capacity!),
      ),
  ];
}
