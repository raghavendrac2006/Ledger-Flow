import 'package:flutter/material.dart';
import '../models/customer.dart';

abstract class CustomerRepository {
  Stream<List<Customer>> getCustomersStream(IconData Function(String?) getIcon);
  Future<void> addCustomer(Customer customer);
  Future<void> updateCustomerOutstanding(String customerName, double amount);
  Future<void> saveCustomer(Customer customer);
  Future<void> deleteCustomer(String customerName);
  Future<List<Customer>> getAllCustomers(IconData Function(String?) getIcon);
}
