import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/customer.dart';
import '../customer_repository.dart';

class FirestoreCustomerRepository implements CustomerRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Stream<List<Customer>> getCustomersStream(IconData Function(String?) getIcon) {
    return _firestore.collection('customers').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Customer.fromJson(data, getIcon);
      }).toList();
    });
  }

  @override
  Future<void> addCustomer(Customer customer) async {
    await _firestore.collection('customers').doc(customer.name).set(customer.toJson());
  }

  @override
  Future<void> updateCustomerOutstanding(String customerName, double amount) async {
    await _firestore.collection('customers').doc(customerName).update({
      'outstanding': FieldValue.increment(amount),
    });
  }

  @override
  Future<void> saveCustomer(Customer customer) async {
    await _firestore.collection('customers').doc(customer.name).set(customer.toJson());
  }

  @override
  Future<void> deleteCustomer(String customerName) async {
    await _firestore.collection('customers').doc(customerName).delete();
  }

  @override
  Future<List<Customer>> getAllCustomers(IconData Function(String?) getIcon) async {
    final snapshot = await _firestore.collection('customers').get();
    return snapshot.docs.map((doc) {
      return Customer.fromJson(doc.data(), getIcon);
    }).toList();
  }
}

