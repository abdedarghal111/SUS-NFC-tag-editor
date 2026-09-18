// Icono con el que la interfaz representa cada clase de contenido NDEF.

import 'package:flutter/material.dart';

import '../chips/ndef/ndef_record_kind.dart';

/// Devuelve el icono con el que la interfaz representa cada clase de
/// contenido NDEF.
IconData iconForKind(NdefRecordKind kind) => switch (kind) {
  NdefRecordKind.link => Icons.link,
  NdefRecordKind.text => Icons.notes,
  NdefRecordKind.phone => Icons.phone,
  NdefRecordKind.email => Icons.mail_outline,
  NdefRecordKind.sms => Icons.sms_outlined,
  NdefRecordKind.location => Icons.place_outlined,
  NdefRecordKind.androidApp => Icons.android,
  NdefRecordKind.unknown => Icons.help_outline,
};
