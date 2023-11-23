import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'firebase_options.dart';
import 'item.dart';

Future<void> main() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
          var s? => ShowSingleItem(id: s),
          null => const ShowAllItems(),
        },
      ),
    );
  }
}

class ShowSingleItem extends StatelessWidget {
  const ShowSingleItem({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    final ref = FirebaseDatabase.instance.ref(id);
    return StreamBuilder(
        stream: ref.onValue,
        builder: (context, event) {
          if (!event.hasData) return const CircularProgressIndicator();
          final itemMap = event.data!;
          var map = itemMap.snapshot.value as Map<String, dynamic>;
          map['id'] = id;
          final item = Item.fromMap(map);

          if (item.id.isEmpty) {
            throw ArgumentError('No item with the id $id exists.');
          }

          if (item.isTaken == null) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                    'You can fulfill a wish for ${item.number > 1 ? '${item.number} times' : ''} "${item.name}" from ${item.brand}, which costs ${item.price.toStringAsFixed(2)} € ${item.number > 1 ? 'total' : ''}(excluding delivery)'),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => launchUrl(Uri.parse(item.snipit)),
                  child: const Text('Preview the wish'),
                ),
                const SizedBox(height: 100),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        // ignore: use_build_context_synchronously
                        Navigator.push<void>(
                          context,
                          MaterialPageRoute<void>(
                            builder: (BuildContext context) => MyPage(
                              item: item,
                              ref: ref,
                            ),
                          ),
                        );
                      },
                      child: const Text('I would like to fulfill this wish!'),
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
                    'The wish ${item.name} from ${item.brand} is already fulfilled by somebody!'),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(
                        builder: (BuildContext context) => MyPage(
                          item: item,
                          ref: ref,
                          taken: true,
                        ),
                      ),
                    );
                  },
                  child: const Text('It was me, please show me the link again'),
                )
              ],
            );
          }
        });
  }
}

class ShowAllItems extends StatelessWidget {
  const ShowAllItems({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: FirebaseDatabase.instance.ref().onValue,
        builder: (context, event) {
          if (!event.hasData) return const Text('Loading items...');
          var allItems = event.data!.snapshot.value as Map<String, dynamic>;
          return ListAllItems(
              allItems: allItems.entries
                  .map((e) {
                    var itemMap = e.value as Map<String, dynamic>;
                    itemMap['id'] = e.key;
                    var item = Item.fromMap(itemMap);
                    return item;
                  })
                  .where((e) => !e.physical)
                  .toList()
                ..sort((a, b) => a.id.compareTo(b.id)));
        });
  }
}

final grey = Colors.grey.shade300;

class ListAllItems extends StatelessWidget {
  const ListAllItems({
    super.key,
    required this.allItems,
  });

  final List<Item> allItems;

  @override
  Widget build(BuildContext context) {
    print(allItems.length);
    return SizedBox(
      width: 800,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              '${allItems.where((item) => item.isTaken != null).length} out of the 100 wishes are fulfilled already - take part!',
              style: const TextStyle(fontSize: 20),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: allItems.length,
              itemBuilder: (context, index) {
                var item = allItems[index];
                return ListTile(
                  title: Row(
                    children: [
                      Text(
                        item.name +
                            (item.isTaken != null
                                ? ' (already fulfilled)'
                                : ''),
                        style: item.isTaken != null
                            ? TextStyle(color: grey)
                            : null,
                      ),
                      const Spacer(),
                      Text(
                        '~${5 * (item.price / 5).round()} €',
                        style: item.isTaken != null
                            ? TextStyle(color: grey)
                            : null,
                      ),
                    ],
                  ),
                  subtitle: Text(
                    item.brand,
                    style: item.isTaken != null ? TextStyle(color: grey) : null,
                  ),
                  leading: Icon(
                    Icons.redeem,
                    color: item.isTaken != null ? grey : null,
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
            ),
          ),
        ],
      ),
    );
  }
}

class MyPage extends StatelessWidget {
  final Item item;
  final bool taken;
  final DatabaseReference ref;

  const MyPage({
    Key? key,
    required this.item,
    required this.ref,
    this.taken = false,
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
              item.number <= 1
                  ? const Text('1. Order the product:')
                  : Text(
                      '1. Order exactly ${item.number} units of the product by following this link:'),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextButton(
                  onPressed: () async {
                    DataSnapshot? snapshot;
                    if (!taken) snapshot = await ref.child('isTaken').get();
                    if (snapshot == null || snapshot.value == null) {
                      if (!taken) {
                        await ref.update(
                            {'isTaken': DateTime.now().toIso8601String()});
                      }
                      await launchUrl(Uri.parse(item.url));
                    } else {
                      // ignore: use_build_context_synchronously
                      Navigator.pop(context);
                    }
                  },
                  child: const Text(
                      'ONLY click here if you will fulfill this wish. This will mark the wish as fulfilled for others.'),
                ),
              ),
              const Text(
                  '2. Send it to this address. Remember to include the name for tracking purposes. Alternatively, bring it to desk 5Z1C6A (@mosum) in MUC-ARP.'),
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: SelectableText(
                    "Google Germany GmbH\nNina Henkel (this name has to be included for tracking purposes)\nErika-Mann-Str. 33\n80636 München"),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const SelectableText(
                      'For any questions, consult the FAQs at'),
                  TextButton(
                    onPressed: () =>
                        launchUrl(Uri.parse('http://go/toy-appeal-muc-2023')),
                    child: const Text('go/toy-appeal-muc-2023'),
                  ),
                  const SelectableText(', or contact @henkel or @mosum.'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
