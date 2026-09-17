// Catálogo de clases de contenido que la app sabe grabar y leer.

import 'ndef_payload.dart';
import 'payloads/android_app_payload.dart';
import 'payloads/email_payload.dart';
import 'payloads/link_payload.dart';
import 'payloads/location_payload.dart';
import 'payloads/phone_payload.dart';
import 'payloads/sms_payload.dart';
import 'payloads/text_payload.dart';
import 'payloads/unknown_payload.dart';

/// Clase de contenido que la app sabe grabar y leer.
///
/// Cada valor construye su propio [NdefPayload], de modo que la interfaz solo
/// maneja tipos y texto.
enum NdefRecordKind {
  link('Enlace', 'https://ejemplo.com'),
  text('Texto', 'Lo que quieras escribir'),
  phone('Teléfono', '+34600000000'),
  email('Email', 'alguien@ejemplo.com'),
  sms('SMS', '+34600000000'),
  location('Ubicación', '40.4168,-3.7038'),
  androidApp('App de Android', 'com.ejemplo.app'),
  unknown('Otro', '');

  const NdefRecordKind(this.label, this.hint);

  final String label;

  final String hint;

  NdefPayload build(String value) => switch (this) {
    NdefRecordKind.link => LinkPayload(value),
    NdefRecordKind.text => TextPayload(value),
    NdefRecordKind.phone => PhonePayload(value),
    NdefRecordKind.email => EmailPayload(value),
    NdefRecordKind.sms => SmsPayload(value),
    NdefRecordKind.location => LocationPayload(value),
    NdefRecordKind.androidApp => AndroidAppPayload(value),
    NdefRecordKind.unknown => UnknownPayload(value),
  };

  static List<NdefRecordKind> get writable =>
      values.where((kind) => kind != NdefRecordKind.unknown).toList();
}
