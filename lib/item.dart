import 'dart:convert';

class Item {
  final String id;
  final String company;
  final String brand;
  final double price;
  final String url;
  final DateTime? isTaken;

  Item({
    required this.id,
    required this.company,
    required this.brand,
    required this.price,
    required this.url,
    this.isTaken,
  });

  Item copyWith({
    String? id,
    String? company,
    String? brand,
    double? price,
    String? url,
    DateTime? isTaken,
  }) {
    return Item(
      id: id ?? this.id,
      company: company ?? this.company,
      brand: brand ?? this.brand,
      price: price ?? this.price,
      url: url ?? this.url,
      isTaken: isTaken ?? this.isTaken,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'company': company,
      'brand': brand,
      'price': price,
      'url': url,
      'isTaken': isTaken?.toIso8601String(),
    };
  }

  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      id: map['id'] ?? '',
      company: map['company'] ?? '',
      brand: map['brand'] ?? '',
      price: map['price']?.toDouble() ?? 0.0,
      url: map['url'] ?? '',
      isTaken: map['isTaken'] != null ? DateTime.parse(map['isTaken']) : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory Item.fromJson(String source) => Item.fromMap(json.decode(source));

  @override
  String toString() {
    return 'Item(id: $id, company: $company, brand: $brand, price: $price, url: $url, isTaken: $isTaken)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Item &&
        other.id == id &&
        other.company == company &&
        other.brand == brand &&
        other.price == price &&
        other.url == url &&
        other.isTaken == isTaken;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        company.hashCode ^
        brand.hashCode ^
        price.hashCode ^
        url.hashCode ^
        isTaken.hashCode;
  }
}
