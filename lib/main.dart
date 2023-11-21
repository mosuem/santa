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
          null => showAllItems(),
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
                    'You can gift "${item.name}" from ${item.brand}, which costs ${item.price} € (excluding delivery)'),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => launchUrl(Uri.parse(item.url)),
                  child: const Text(
                      'Preview the item. Do not buy using this link!'),
                ),
                const SizedBox(height: 100),
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
                      child:
                          const Text('I confirm that I want to buy this item.'),
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
                    'The item ${item.name} from ${item.brand} is already taken!'),
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

  Widget showAllItems() {
    DatabaseReference ref = FirebaseDatabase.instance.ref();
    return FutureBuilder(
        future: getAllData(ref),
        builder: (context, snapshot) {
          if (snapshot.data == null) return const Text('Loading items...');
          var allItems = snapshot.data!.value as Map<String, dynamic>;
          return ListAllItems(
              allItems: allItems.entries.map((e) {
            var itemMap = e.value as Map<String, dynamic>;
            itemMap['id'] = e.key;
            var item = Item.fromMap(itemMap);
            return item;
          }).toList()
                ..sort((a, b) => a.name.compareTo(b.name)));
        });
  }

  Future<DataSnapshot> getAllData(DatabaseReference ref) {
    print('Getting all data');
    return ref.get();
  }
}

class ListAllItems extends StatelessWidget {
  const ListAllItems({
    super.key,
    required this.allItems,
  });

  final List<Item> allItems;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: allItems.length,
      itemBuilder: (context, index) {
        var item = allItems[index];
        return ListTile(
          title: Row(
            children: [
              Text(
                item.name,
                style: item.isTaken != null
                    ? const TextStyle(color: Colors.grey)
                    : null,
              ),
              const Spacer(),
              Text(
                '~${5 * (item.price / 5).round()} €',
                style: item.isTaken != null
                    ? const TextStyle(color: Colors.grey)
                    : null,
              ),
            ],
          ),
          subtitle: Text(
            item.brand,
            style: item.isTaken != null
                ? const TextStyle(color: Colors.grey)
                : null,
          ),
          leading: Icon(
            Icons.redeem,
            color: item.isTaken != null ? Colors.grey : null,
          ),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (BuildContext context) {
                return HomePage(argId: item.id);
              },
            ),
          ),
        );
      },
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
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text('Thanks for participating! Now follow these steps:'),
              const SizedBox(height: 10),
              const Text('1. Order the product:'),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextButton(
                  onPressed: () => launchUrl(Uri.parse(item.url)),
                  child: Text(item.url),
                ),
              ),
              const Text(
                  '2. Send it to this address. Remember to include the name for tracking purposes. Alternatively, bring it to desk 5Z1C6A in MUC-ARP.'),
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: SelectableText(
                    "Google Germany GmbH\nNina Henkel\nErika-Mann-Str. 33\n80636 München"),
              ),
              const SizedBox(height: 10),
              const SelectableText(
                  'For any questions, consult the FAQs at go/arche-toys, or contact @henkel or @mosum.'),
            ],
          ),
        ),
      ),
    );
  }
}
