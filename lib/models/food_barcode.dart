/// A packaging GTIN (EAN-8, UPC-A, EAN-13 or GTIN-14), kept as text.
abstract final class FoodBarcode {
  static final _pattern = RegExp(r'^(?:[0-9]{8}|[0-9]{12,14})$');

  static bool isValid(String value) => _pattern.hasMatch(value.trim());

  /// Equivalent UPC/EAN representations identify the same packaging.
  static String key(String value) => value.trim().padLeft(14, '0');
}
