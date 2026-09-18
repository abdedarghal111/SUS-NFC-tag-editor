// Tira de estado: dice qué hacer con la etiqueta en cada momento.

import 'package:flutter/material.dart';

import '../nfc/nfc_reader.dart';

/// Tira de estado: dice qué hacer con la etiqueta en cada momento.
///
/// Traduce la fase del lector a un icono, un titular y una instrucción, y
/// ofrece cancelar mientras se espera la etiqueta.
class TagStatusStrip extends StatelessWidget {
  const TagStatusStrip({
    super.key,
    required this.phase,
    required this.action,
    required this.message,
    required this.onCancel,
  });

  /// Fase del lector; de ella salen el icono, los colores y el titular.
  final NfcPhase phase;

  /// Operación en curso, para nombrarla mientras se espera o se trabaja.
  final String action;

  /// Aviso del último resultado; si falta se usa el texto por defecto.
  final String? message;

  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (icon, title, detail, background, foreground) = switch (phase) {
      NfcPhase.idle => (
        Icons.nfc,
        'Sin etiqueta',
        message ?? 'Elige una acción y acerca la etiqueta.',
        scheme.surfaceContainerHighest,
        scheme.onSurfaceVariant,
      ),
      NfcPhase.waiting => (
        Icons.touch_app,
        'Coloca la etiqueta',
        action.isEmpty ? 'Apóyala en la parte de atrás del teléfono.' : action,
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
      ),
      NfcPhase.working => (
        Icons.autorenew,
        action.isEmpty ? 'Trabajando' : action,
        'No la separes todavía.',
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
      ),
      NfcPhase.removing => (
        Icons.check_circle,
        'Listo',
        message ?? 'Ya puedes separar la etiqueta.',
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
      ),
    };

    return Container(
      width: double.infinity,
      color: background,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          if (phase == NfcPhase.working)
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: foreground,
              ),
            )
          else
            _PulsingIcon(
              icon: icon,
              color: foreground,
              animate: phase == NfcPhase.waiting,
            ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: foreground),
                ),
                Text(
                  detail,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: foreground),
                ),
              ],
            ),
          ),
          if (phase == NfcPhase.waiting)
            TextButton(
              onPressed: onCancel,
              style: TextButton.styleFrom(foregroundColor: foreground),
              child: const Text('Cancelar'),
            ),
        ],
      ),
    );
  }
}

/// Icono que late mientras se espera la etiqueta, para que se vea que la app
/// sigue pendiente.
class _PulsingIcon extends StatefulWidget {
  const _PulsingIcon({
    required this.icon,
    required this.color,
    required this.animate,
  });

  final IconData icon;
  final Color color;

  /// Mientras es cierto el icono late; al apagarse se queda opaco.
  final bool animate;

  @override
  State<_PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<_PulsingIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_PulsingIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.animate && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: widget.animate
          ? Tween<double>(begin: 0.35, end: 1).animate(_controller)
          : const AlwaysStoppedAnimation(1),
      child: Icon(widget.icon, size: 28, color: widget.color),
    );
  }
}
