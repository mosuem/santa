import 'dart:convert';

class Item {
  final String id;
  final String description;
  final String name;
  final int number;
  final double _price;
  final String brand;
  final String url;
  final DateTime? isTaken;

  Item({
    required this.id,
    this.isTaken,
    required this.description,
    required this.name,
    required this.number,
    required double price,
    required this.brand,
    required this.url,
  }) : _price = price;

  double get price => _price * number;

  Item copyWith({
    String? id,
    DateTime? isTaken,
    String? description,
    String? name,
    int? number,
    double? price,
    String? brand,
    String? url,
  }) {
    return Item(
      id: id ?? this.id,
      isTaken: isTaken ?? this.isTaken,
      description: description ?? this.description,
      name: name ?? this.name,
      number: number ?? this.number,
      price: price ?? _price,
      brand: brand ?? this.brand,
      url: url ?? this.url,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'isTaken': isTaken?.toIso8601String(),
      'description': description,
      'name': name,
      'number': number.toString(),
      'price': _price.toString(),
      'brand': brand,
      'url': url,
    };
  }

  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      id: map['id'] ?? '',
      isTaken: map['isTaken'] != null ? DateTime.parse(map['isTaken']) : null,
      description: map['description'] ?? '',
      name: map['name'] ?? '',
      number: int.tryParse(map['number']) ?? 1,
      price: double.tryParse(map['price']) ?? 0,
      brand: map['brand'] ?? '',
      url: map['url'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory Item.fromJson(String source) => Item.fromMap(json.decode(source));

  @override
  String toString() {
    return 'Item(id: $id, isTaken: $isTaken, description: $description, name: $name, number: $number, price: $_price, brand: $brand, url: $url)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Item &&
        other.id == id &&
        other.isTaken == isTaken &&
        other.description == description &&
        other.name == name &&
        other.number == number &&
        other._price == _price &&
        other.brand == brand &&
        other.url == url;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        isTaken.hashCode ^
        description.hashCode ^
        name.hashCode ^
        number.hashCode ^
        _price.hashCode ^
        brand.hashCode ^
        url.hashCode;
  }
}
