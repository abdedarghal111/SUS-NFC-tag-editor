// Formateo de bytes en hexadecimal para trazas y para la interfaz.

/// Formatea una lista de bytes como pares hexadecimales separados por espacio.
String hexBytes(List<int> bytes) => bytes
    .map((byte) => byte.toRadixString(16).toUpperCase().padLeft(2, '0'))
    .join(' ');

/// Formatea un byte como literal hexadecimal con prefijo `0x`.
String hexByte(int byte) =>
    '0x${byte.toRadixString(16).toUpperCase().padLeft(2, '0')}';
