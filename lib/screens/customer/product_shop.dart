//lib/screens/customer_modules/product_shop.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductShopScreen extends StatelessWidget {
  const ProductShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Glow Store")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('products').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          return GridView.builder(
            padding: const EdgeInsets.all(15),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, childAspectRatio: 0.75, crossAxisSpacing: 15, mainAxisSpacing: 15),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var product = snapshot.data!.docs[index];
              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Column(
                  children: [
                    Expanded(child: Image.network(product['imageUrl'], fit: BoxFit.cover)),
                    Text(product['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text("\$${product['price']}"),
                    ElevatedButton(onPressed: () {}, child: const Text("Add to Cart"))
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}