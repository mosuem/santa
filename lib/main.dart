import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'firebase_options.dart';
import 'item.dart';
import 'snow_animation.dart';

const String paypalPoolUrl = 'https://www.paypal.com/pool/9uitkxMD0A';
const String faqGoLink = 'go/toy-appeal-muc-2026';

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
      initialRoute: '/',
      routes: {
        // When navigating to the "/" route, build the FirstScreen widget.
        '/': (context) => const HomePage(),
      },
    );
  }
}

class HomePage extends StatelessWidget {
  final String? argId;
  const HomePage({super.key, this.argId});

  @override
  Widget build(BuildContext context) {
    var queryParameter = Uri.base.queryParameters['id'];
    var id = argId ?? queryParameter;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Die Arche München Toy Appeal'),
        actions: [
          if (queryParameter != null)
            IconButton(
              onPressed: () {
                launchUrl(Uri.parse('https://toy-appeal-muc.web.app/'));
              },
              icon: const Icon(Icons.home),
            ),
        ],
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
        var map = itemMap.snapshot.value as Map;
        map['id'] = id;
        final item = Item.fromMap(map);

        if (item.id.isEmpty) {
          throw ArgumentError('No item with the id $id exists.');
        }

        if (item.isTaken == null) {
          return Stack(
            children: [
              SnowWidget(
                isRunning: true,
                totalSnow: (MediaQuery.of(context).size.height / 30).round(),
                speed: 1,
              ),
              Align(
                alignment: Alignment.center,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 700),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          'You can fulfill a wish for ${item.number > 1 ? '${item.number} times ' : ''}"${item.name}" from ${item.brand}, which costs ${item.price.toStringAsFixed(2)} € ${item.number > 1 ? 'total ' : ''}(excluding delivery)',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 20),
                        WishPreviewImage(item: item),
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: () async {
                                // ignore: use_build_context_synchronously
                                Navigator.push<void>(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder: (BuildContext context) =>
                                        MyPage(item: item, ref: ref),
                                  ),
                                );
                              },
                              child: const Text(
                                'I would like to fulfill this wish!',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        } else {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                'The wish ${item.name} from ${item.brand} is already fulfilled by somebody!',
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (BuildContext context) =>
                          MyPage(item: item, ref: ref, taken: true),
                    ),
                  );
                },
                child: const Text('It was me, please show me the link again'),
              ),
            ],
          );
        }
      },
    );
  }
}

class ShowAllItems extends StatelessWidget {
  const ShowAllItems({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseDatabase.instance.ref().onValue,
      builder: (context, event) {
        if (!event.hasData) return const Text('Loading items...');
        var allItems2 = (event.data!.snapshot.value as Map).entries.map((
          entry,
        ) {
          var itemMap = Map<String, dynamic>.from(entry.value);
          itemMap['id'] = entry.key;
          return Item.fromMap(itemMap);
        }).toList()..sort((a, b) => a.id.compareTo(b.id));
        return ListAllItems(
          allItems: allItems2.where((e) => !e.physical).toList(),
          numTaken: allItems2.where((item) => item.isTaken != null).length,
        );
      },
    );
  }
}

final grey = Colors.grey.shade300;

class ListAllItems extends StatelessWidget {
  const ListAllItems({
    super.key,
    required this.allItems,
    required this.numTaken,
  });

  final List<Item> allItems;
  final int numTaken;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SnowWidget(
          isRunning: true,
          totalSnow: (MediaQuery.of(context).size.height / 30).round(),
          speed: 1,
        ),
        Align(
          alignment: Alignment.center,
          child: SizedBox(
            width: 800,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    '$numTaken out of the 100 wishes are fulfilled already - take part!',
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
                          style: item.isTaken != null
                              ? TextStyle(color: grey)
                              : null,
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
          ),
        ),
      ],
    );
  }
}

class MyPage extends StatelessWidget {
  final Item item;
  final bool taken;
  final DatabaseReference ref;

  const MyPage({
    super.key,
    required this.item,
    required this.ref,
    this.taken = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Die Arche München Toy Appeal'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.popUntil(context, (route) => false);
              Navigator.pushNamed(context, '/');
            },
            icon: const Icon(Icons.home),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Selected wish: ${item.name} (${item.price.toStringAsFixed(2)} €)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              const Text('Thanks for participating! Now follow these steps:'),
              const SizedBox(height: 10),
              const Text(
                '1. Order the product yourself: ONLY click here if you will fulfill this wish by ordering yourself. This will mark the wish as fulfilled for others.',
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextButton(
                  onPressed: () async {
                    DataSnapshot? snapshot;
                    if (!taken) snapshot = await ref.child('isTaken').get();
                    if (snapshot == null || snapshot.value == null) {
                      if (!taken) {
                        await ref.update({
                          'isTaken': DateTime.now().toIso8601String(),
                          'paypal': false,
                        });
                      }
                      await launchUrl(Uri.parse(item.url));
                    } else {
                      // ignore: use_build_context_synchronously
                      Navigator.pop(context);
                    }
                  },
                  child: const Text(
                    'Order the product yourself. This will mark the wish as fulfilled for others.',
                  ),
                ),
              ),
              const Text(
                '2. Let Nina & Moritz order for you by donating THE VALUE of the item via Paypal: Only click here if you will fulfill this wish by donating the value of the item via Paypal. This will mark the wish as fulfilled for others. Add the name of the item in the description of the Paypal money transfer.',
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: item.name));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Copied "${item.name}" to clipboard for PayPal description.',
                              ),
                            ),
                          );
                        }
                        DataSnapshot? snapshot;
                        if (!taken) snapshot = await ref.child('isTaken').get();
                        if (snapshot == null || snapshot.value == null) {
                          if (!taken) {
                            await ref.update({
                              'isTaken': DateTime.now().toIso8601String(),
                              'paypal': true,
                            });
                          }
                          await launchUrl(Uri.parse(paypalPoolUrl));
                        } else {
                          // ignore: use_build_context_synchronously
                          Navigator.pop(context);
                        }
                      },
                      child: Text(
                        'Donate ${item.price.toStringAsFixed(2)} € (the value of the item) via Paypal. This will mark the wish as fulfilled for others.',
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: item.name));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Copied "${item.name}" to clipboard.',
                              ),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Copy item name for PayPal note'),
                    ),
                  ],
                ),
              ),
              const Text(
                '3. When ordering yourself please send the item to the address below. Alternatively, bring it to desk 5Z1C6C (@henkel) in MUC-ARP.',
              ),
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: SelectableText(
                  "Google Germany GmbH\nNina Henkel (this name has to be included for tracking purposes)\nErika-Mann-Str. 33\n80636 München",
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const SelectableText(
                    'For any questions, consult the FAQs at',
                  ),
                  TextButton(
                    onPressed: () =>
                        launchUrl(Uri.parse('http://$faqGoLink')),
                    child: const Text(faqGoLink),
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

class WishPreviewImage extends StatelessWidget {
  const WishPreviewImage({super.key, required this.item});

  final Item item;

  @override
  Widget build(BuildContext context) {
    final relativePath = 'screenshots/${item.id}.webp';
    final fullImageUri = Uri.base.resolve(relativePath);
    return Tooltip(
      message: 'Click to open full-size image',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => launchUrl(fullImageUri),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 360, maxWidth: 600),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                relativePath,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const SizedBox(
                    height: 180,
                    width: 180,
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  if (item.snipit.isNotEmpty) {
                    return TextButton(
                      onPressed: () => launchUrl(Uri.parse(item.snipit)),
                      child: const Text('Preview the wish'),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
