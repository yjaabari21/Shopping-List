import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shopping_list/data/categories.dart';
import 'package:shopping_list/models/grocery_item.dart';
import 'package:shopping_list/widget/new_item.dart';
import 'package:http/http.dart' as http;

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _grocItems = [];
  var _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() async {
    final url = Uri.https(
      'shopping-list-fcebb-default-rtdb.firebaseio.com',
      'shopping-list.json',
    );
    try {
      final response = await http.get(
        url,
      );
      if (response.statusCode >= 400) {
        setState(() {
          _error = "404 , Faild To Featch Data";
        });
      }
      if (response.body == 'null') {
        setState(
          () {
            _isLoading = false;
          },
        );
        return;
      }
      final Map<String, dynamic> listData = json.decode(response.body);
      final List<GroceryItem> _loadedItems = [];

      for (final item in listData.entries) {
        final cate = categories.entries
            .firstWhere(
              (catItem) => catItem.value.title == item.value['category'],
            )
            .value;
        _loadedItems.add(
          GroceryItem(
            id: item.key,
            name: item.value['name'],
            quantity: item.value['quantity'],
            category: cate,
          ),
        );
      }
      setState(() {
        _grocItems = _loadedItems;
        _isLoading = false;
      });
    } catch (err) {
      setState(() {
        _error = "Faild To fetch Data. please try again later";
      });
    }
  }

  void _addItem() async {
    final newItem = await Navigator.of(context).push<GroceryItem>(
      MaterialPageRoute(
        builder: (ctx) => const NewItem(),
      ),
    );

    if (newItem == null) {
      return;
    }
    setState(() {
      _grocItems.add(newItem);
    });
    _loadItems();
  }

  void _removeItem(GroceryItem item) async {
    final index = _grocItems.indexOf(item);

    setState(
      () {
        _grocItems.remove(item);
      },
    );
    final url = Uri.https(
      'shopping-list-fcebb-default-rtdb.firebaseio.com',
      'shopping-list/${item.id}.json',
    );
    final response = await http.delete(url);

    if (response.statusCode >= 400) {
      setState(() {
        _grocItems.insert(index, item);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = const Center(
      child: Text(
        'No items added',
        style: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    if (_isLoading) {
      content = const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_grocItems.isNotEmpty) {
      content = ListView.builder(
        itemCount: _grocItems.length,
        itemBuilder: (ctx, index) => Dismissible(
          onDismissed: (direction) {
            _removeItem(_grocItems[index]);
          },
          key: ValueKey(_grocItems[index]),
          child: ListTile(
            title: Text(_grocItems[index].name),
            leading: Container(
              width: 24,
              height: 24,
              color: _grocItems[index].category.color,
            ),
            trailing: Text(_grocItems[index].quantity.toString()),
          ),
        ),
      );
    }

    if (_error != null) {
      content = Center(
        child: Text(
          _error!,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Groceries'),
        actions: [
          IconButton(
            onPressed: _addItem,
            icon: Icon(Icons.add),
          ),
        ],
      ),
      body: content,
    );
  }
}
