// Coordenadas geográficas.

import '../ndef_record_kind.dart';
import '../uri_payload.dart';

/// Punto del mapa que el móvil abre al leer la etiqueta.
class LocationPayload extends UriPayload {
  const LocationPayload(super.value);

  @override
  NdefRecordKind get kind => NdefRecordKind.location;

  @override
  String get scheme => 'geo:';
}
