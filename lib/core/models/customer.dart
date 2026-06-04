import 'package:flutter/material.dart';

class Customer {
  final String name;
  final String type;
  final String area;
  final double outstanding;
  final IconData icon;
  final String location;
  final String status;

  Customer({
    required this.name,
    required this.type,
    required this.area,
    required this.outstanding,
    required this.icon,
    this.location = "Downtown Market",
    this.status = "Active Client",
  });

  Customer copyWith({
    String? name,
    String? type,
    String? area,
    double? outstanding,
    IconData? icon,
    String? location,
    String? status,
  }) {
    return Customer(
      name: name ?? this.name,
      type: type ?? this.type,
      area: area ?? this.area,
      outstanding: outstanding ?? this.outstanding,
      icon: icon ?? this.icon,
      location: location ?? this.location,
      status: status ?? this.status,
    );
  }

  factory Customer.fromJson(Map<String, dynamic> json, IconData Function(String?) getIcon) {
    return Customer(
      name: json['name'] ?? '',
      type: json['type'] ?? 'RETAIL',
      area: json['area'] ?? '',
      outstanding: (json['outstanding'] as num?)?.toDouble() ?? 0.0,
      icon: getIcon(json['type']),
      location: json['location'] ?? '',
      status: json['status'] ?? 'Active Client',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'area': area,
      'outstanding': outstanding,
      'location': location,
      'status': status,
    };
  }
}

