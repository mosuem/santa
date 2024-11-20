import 'dart:convert';

class Item {
  final String id;
  final String description;
  final String name;
  final int number;
  final double _price;
  final String brand;
  final String url;
  final String snipit;
  final bool physical;
  final DateTime? isTaken;

  Item({
    required double price,
    required this.id,
    required this.description,
    required this.name,
    required this.number,
    required this.brand,
    required this.physical,
    required this.url,
    required this.snipit,
    this.isTaken,
  }) : _price = price;

  double get price => _price * number;

  Map<String, dynamic> toMap() => {
        'id': id,
        'description': description,
        'name': name,
        'number': number.toString(),
        'price': _price.toString(),
        'brand': brand,
        'physical': physical.toString(),
        'url': url,
        'snipit': snipit,
        'isTaken': isTaken?.toIso8601String(),
      };

  factory Item.fromMap(Map map) => Item(
        id: map['id'] ?? '',
        description: map['description'] ?? '',
        name: map['name'] ?? '',
        number: int.tryParse(map['number']) ?? 1,
        price: double.tryParse(map['price']) ?? 0,
        brand: map['brand'] ?? '',
        physical: bool.tryParse(map['physical']) ?? false,
        url: map['url'] ?? '',
        snipit: map['snipit'] ?? '',
        isTaken:
            map['isTaken'] != null ? DateTime.tryParse(map['isTaken']) : null,
      );

  String toJson() => json.encode(toMap());

  factory Item.fromJson(String source) => Item.fromMap(json.decode(source));

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Item &&
        other.id == id &&
        other.description == description &&
        other.name == name &&
        other.number == number &&
        other._price == _price &&
        other.brand == brand &&
        other.url == url &&
        other.snipit == snipit &&
        other.physical == physical &&
        other.isTaken == isTaken;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        description.hashCode ^
        name.hashCode ^
        number.hashCode ^
        _price.hashCode ^
        brand.hashCode ^
        url.hashCode ^
        snipit.hashCode ^
        physical.hashCode ^
        isTaken.hashCode;
  }

  @override
  String toString() {
    return 'Item(id: $id, description: $description, name: $name, number: $number, _price: $_price, brand: $brand, url: $url, snipit: $snipit, physical: $physical, isTaken: $isTaken)';
  }
}
