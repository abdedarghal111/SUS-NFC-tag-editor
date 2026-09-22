// Veredicto sobre si la contraseña de la etiqueta sirve de algo.

import '../../utils/hex.dart';
import 'tag_result.dart';
import '../../chips/type2/type2_chip.dart';

/// Veredicto de poner una contraseña, intentar escribir sin ella y quitarla.
///
/// La prueba solo concluye sobre una etiqueta libre que además deje escribir:
/// sin esas dos condiciones, lo que haga después no dice nada.
class ProtectionProbe extends TagResult {
  /// La etiqueta ya venía bloqueada: la prueba no se ha llegado a hacer.
  const ProtectionProbe.alreadyLocked({required this.config})
    : writeAccepted = null,
      password = const [],
      unlocked = false,
      _skipped =
          'La etiqueta ya tiene una contraseña puesta. Quítasela y vuelve '
          'a intentarlo.';

  /// La etiqueta no deja escribir ni estando libre: la prueba no dice nada.
  const ProtectionProbe.notWritable({required this.config})
    : writeAccepted = null,
      password = const [],
      unlocked = true,
      _skipped =
          'La etiqueta no deja escribir ni estando sin contraseña, así que '
          'no hay forma de saber si el bloqueo funciona.';

  /// La prueba se ha hecho: contraseña puesta, escritura intentada sin ella.
  const ProtectionProbe.tested({
    required this.config,
    required this.writeAccepted,
    required this.password,
    required this.unlocked,
  }) : _skipped = null;

  /// Los 4 bytes de CFG0 tal y como quedan al terminar la prueba.
  final List<int> config;

  /// Indica si la etiqueta dejó escribir con la contraseña puesta; es null
  /// cuando la prueba no se ha hecho.
  final bool? writeAccepted;

  /// Contraseña que se ha usado para la prueba, vacía si no se llegó a poner.
  final List<int> password;

  /// Indica si al terminar la etiqueta ha quedado otra vez sin contraseña.
  final bool unlocked;

  /// Motivo por el que no se ha hecho la prueba, o null si se hizo.
  final String? _skipped;

  /// Primera página protegida; 0xFF significa que no hay protección.
  int get auth0 => config[Type2Chip.auth0Offset];

  /// Indica que la prueba no se ha llegado a hacer.
  bool get skipped => _skipped != null;

  /// Indica si la etiqueta ha salido bien parada: rechazó la escritura.
  bool get passed => writeAccepted == false;

  /// Titular del resultado.
  String get verdict {
    if (skipped) return 'No se ha podido hacer la prueba.';
    return writeAccepted!
        ? 'El bloqueo por contraseña no funciona.'
        : 'El bloqueo por contraseña funciona.';
  }

  /// Lo que ha pasado durante la prueba.
  String get detail {
    final reason = _skipped;
    if (reason != null) return reason;
    return writeAccepted!
        ? 'Se le ha puesto una contraseña y aun así ha dejado que le '
              'escribieran sin ella.'
        : 'Se le ha puesto una contraseña y ha impedido que le escribieran '
              'sin ella.';
  }

  /// Aviso de que la etiqueta se ha quedado con la contraseña de la prueba.
  String? get warning => skipped || unlocked
      ? null
      : 'La etiqueta se ha quedado bloqueada con la contraseña '
            '${String.fromCharCodes(password)} (${hexBytes(password)}). '
            'Tecléala en «Quitar la contraseña» para desbloquearla.';

  @override
  String get summary => skipped ? 'Prueba no realizada.' : verdict;
}
