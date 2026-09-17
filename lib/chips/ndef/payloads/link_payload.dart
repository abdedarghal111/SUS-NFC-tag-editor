// Enlace web.

import '../ndef_record_kind.dart';
import '../uri_payload.dart';

/// Dirección web que el móvil abre al leer la etiqueta.
class LinkPayload extends UriPayload {
  const LinkPayload(super.value);

  @override
  NdefRecordKind get kind => NdefRecordKind.link;

  @override
  String get scheme => 'https://';

  /// Un enlace ya trae su propio esquema; no se le añade nada.
  @override
  String get uri => value.trim();
}
