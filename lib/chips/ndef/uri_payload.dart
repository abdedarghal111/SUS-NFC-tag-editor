// Base de los contenidos que se guardan como URI con un esquema delante.

import 'dart:convert';

import 'ndef_payload.dart';
import 'uri_prefixes.dart';

/// Contenido que se graba como URI, anteponiendo su esquema si falta.
abstract class UriPayload extends NdefPayload {
  const UriPayload(super.value);

  /// Esquema que se antepone al valor si no lo trae ya.
  String get scheme;

  /// URI completo que se graba en la etiqueta.
  String get uri {
    final trimmed = value.trim();
    return trimmed.startsWith(scheme) ? trimmed : '$scheme$trimmed';
  }

  @override
  EncodedRecord encode() =>
      EncodedRecord(0x01, utf8.encode('U'), UriPrefix.compress(uri));
}
