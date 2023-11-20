import 'dart:math';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'firebase_options.dart';
import 'item.dart';

Future<void> main() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Die Arche München Toy Appeal',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red.shade300),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  final String? argId;
  const HomePage({super.key, this.argId});

  @override
  Widget build(BuildContext context) {
    var id = argId ?? Uri.base.queryParameters['id'];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Die Arche München Toy Appeal'),
      ),
      body: Center(
        child: switch (id) {
          var s? => getItem(s),
          null => getRandomItem(),
        },
      ),
    );
  }

  FutureBuilder<Item> getItem(String id) {
    DatabaseReference ref = FirebaseDatabase.instance.ref(id);
    return FutureBuilder<Item>(
        future: ref.get().then((value) {
          if (!value.exists) {
            return Item.fromMap({});
          }
          var map = value.value as Map<String, dynamic>;
          map['id'] = id;
          return Item.fromMap(map);
        }),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const CircularProgressIndicator();
          final item = snapshot.data!;
          if (item.id.isEmpty) {
            throw ArgumentError('No item with the id $id exists.');
          }

          if (item.isTaken == null) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                    'You can gift ${item.company} from ${item.brand}, which costs about ${(item.price / 10).round() * 10} EUR (excluding delivery)'),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        await ref.update(
                            {'isTaken': DateTime.now().toIso8601String()});
                        // ignore: use_build_context_synchronously
                        Navigator.push<void>(
                          context,
                          MaterialPageRoute<void>(
                            builder: (BuildContext context) =>
                                MyPage(item: item),
                          ),
                        );
                      },
                      child: const Text('Yes'),
                    ),
                  ],
                )
              ],
            );
          } else {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                    'The item ${item.company} from ${item.brand} is already taken!'),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(
                        builder: (BuildContext context) => MyPage(item: item),
                      ),
                    );
                  },
                  child: const Text('I took it, please show me the link again'),
                )
              ],
            );
          }
        });
  }

  Widget getRandomItem() {
    DatabaseReference ref = FirebaseDatabase.instance.ref();
    return FutureBuilder(
        future: getAllData(ref),
        builder: (context, snapshot) {
          if (snapshot.data == null) return const Text('Loading items...');
          var allItems = snapshot.data!.value as Map<String, dynamic>;
          allItems.removeWhere((key, value) => value['isTaken'] != null);
          return RandomWidget(allItems: allItems);
        });
  }

  Future<DataSnapshot> getAllData(DatabaseReference ref) {
    print('Getting all data');
    return ref.get();
  }
}

class RandomWidget extends StatefulWidget {
  const RandomWidget({
    super.key,
    required this.allItems,
  });

  final Map<String, dynamic> allItems;

  @override
  State<RandomWidget> createState() => _RandomWidgetState();
}

class _RandomWidgetState extends State<RandomWidget> {
  int randomIndex = 0;

  @override
  Widget build(BuildContext context) {
    randomIndex = Random().nextInt(widget.allItems.length);
    var selectedItemEntry = widget.allItems.entries.toList()[randomIndex];
    var itemMap = selectedItemEntry.value as Map<String, dynamic>;
    itemMap['id'] = selectedItemEntry.key;
    var item = Item.fromMap(itemMap);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('How about this item: ${item.company} from ${item.brand}'),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (BuildContext context) => HomePage(argId: item.id),
                  ),
                );
              },
              child: const Text('Yes!'),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  randomIndex = Random().nextInt(widget.allItems.length);
                });
              },
              child: const Text('No, show me a different one'),
            ),
          ],
        )
      ],
    );
  }
}

class MyPage extends StatelessWidget {
  final Item item;
  const MyPage({
    Key? key,
    required this.item,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Die Arche München Toy Appeal'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextButton(
              onPressed: () => launchUrl(Uri.parse(item.url)),
              child: Text(
                  'Order the product from ${item.url} and send it to the following address: @henkel'),
            ),
          ],
        ),
      ),
    );
  }
}
