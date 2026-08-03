/// Product Category Enum
/// Dart এর enum ব্যবহার করলে type-safe ভাবে category track করা যায়
/// যেমন: ProductCategory.grocery — string এর চেয়ে safe
enum ProductCategory {
  grocery('Grocery'),
  electronics('Electronics'),
  clothing('Clothing'),
  medicine('Medicine'),
  food('Food'),
  beverages('Beverages'),
  cosmetics('Cosmetics'),
  stationery('Stationery'),
  hardware('Hardware'),
  other('Other');

  final String displayName;

  const ProductCategory(this.displayName);

  /// String থেকে enum এ convert করে
  /// Firestore থেকে data আসলে String হয়, এটা দিয়ে enum বানাই
  static ProductCategory fromString(String? value) {
    if (value == null) return ProductCategory.other;
    return ProductCategory.values.firstWhere(
      (category) => category.name == value,
      orElse: () => ProductCategory.other,
    );
  }
}
