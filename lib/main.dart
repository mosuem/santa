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
const String shippingAddress =
    'Google Germany GmbH\n'
    'Nina Henkel\n'
    'Erika-Mann-Str. 33\n'
    '80636 München';

// Festive winter palette
const Color _kCranberry = Color(0xFFB4232A);
const Color _kCranberrySoft = Color(0xFFFDF2F2);
const Color _kPine = Color(0xFF1F6F43);
const Color _kPineSoft = Color(0xFFECFDF3);
const Color _kInk = Color(0xFF182230);
const Color _kMutedInk = Color(0xFF526071);
const Color _kBorder = Color(0xFFE2E8F0);
const Color _kSnowBgTop = Color(0xFFF7FAFC);
const Color _kSnowBgBottom = Color(0xFFEDF2F7);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _kCranberry,
      primary: _kCranberry,
      surface: Colors.white,
      brightness: Brightness.light,
    );
    return MaterialApp(
      title: 'Die Arche München — Toy Appeal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
        scaffoldBackgroundColor: _kSnowBgTop,
        textTheme: Typography.material2021().black.apply(
              bodyColor: _kInk,
              displayColor: _kInk,
            ),
        cardTheme: CardThemeData(
          color: Colors.white.withValues(alpha: 0.94),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: _kBorder),
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
      },
    );
  }
}

class SnowBackdrop extends StatelessWidget {
  final Widget child;
  const SnowBackdrop({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final snowCount = (height / 26).round().clamp(20, 65);
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_kSnowBgTop, _kSnowBgBottom],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          IgnorePointer(
            child: SnowWidget(
              isRunning: true,
              totalSnow: snowCount,
              speed: 0.85,
            ),
          ),
          child,
        ],
      ),
    );
  }
}

PreferredSizeWidget _buildAppBar(
  BuildContext context, {
  required bool showHomeAction,
  VoidCallback? onHomePressed,
}) {
  return AppBar(
    backgroundColor: Colors.white.withValues(alpha: 0.92),
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0.5,
    shape: const Border(bottom: BorderSide(color: _kBorder)),
    titleSpacing: 20,
    title: InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: showHomeAction ? onHomePressed : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: _kCranberrySoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.redeem_rounded,
              color: _kCranberry,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Flexible(
            child: Text(
              'Die Arche München Toy Appeal',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                letterSpacing: -0.2,
                color: _kInk,
              ),
            ),
          ),
        ],
      ),
    ),
    actions: [
      if (showHomeAction)
        TextButton.icon(
          onPressed: onHomePressed,
          icon: const Icon(Icons.grid_view_rounded, size: 18),
          label: const Text('All wishes'),
          style: TextButton.styleFrom(foregroundColor: _kMutedInk),
        ),
      Padding(
        padding: const EdgeInsets.only(right: 14, left: 4),
        child: OutlinedButton.icon(
          onPressed: () => launchUrl(Uri.parse('http://$faqGoLink')),
          icon: const Icon(Icons.help_outline_rounded, size: 17),
          label: const Text('FAQs'),
          style: OutlinedButton.styleFrom(
            foregroundColor: _kInk,
            side: const BorderSide(color: _kBorder),
            visualDensity: VisualDensity.compact,
          ),
        ),
      ),
    ],
  );
}

void _navigateToAllWishes(BuildContext context) {
  if (Uri.base.queryParameters.containsKey('id') && !Navigator.canPop(context)) {
    launchUrl(
      Uri.parse('https://toy-appeal-muc.web.app/'),
      webOnlyWindowName: '_self',
    );
    return;
  }
  Navigator.popUntil(context, (route) => route.isFirst);
  if (Uri.base.queryParameters.containsKey('id')) {
    launchUrl(
      Uri.parse('https://toy-appeal-muc.web.app/'),
      webOnlyWindowName: '_self',
    );
  }
}

class HomePage extends StatelessWidget {
  final String? argId;
  const HomePage({super.key, this.argId});

  @override
  Widget build(BuildContext context) {
    final queryParameter = Uri.base.queryParameters['id'];
    final id = argId ?? queryParameter;
    final isSingleView = id != null;

    return Scaffold(
      appBar: _buildAppBar(
        context,
        showHomeAction: isSingleView,
        onHomePressed: () => _navigateToAllWishes(context),
      ),
      body: SnowBackdrop(
        child: switch (id) {
          final s? => ShowSingleItem(id: s),
          null => const ShowAllItems(),
        },
      ),
    );
  }
}

enum _PriceFilter { all, upTo25, over25 }

class ShowAllItems extends StatelessWidget {
  const ShowAllItems({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseDatabase.instance.ref().onValue,
      builder: (context, event) {
        if (!event.hasData || event.data?.snapshot.value == null) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: _kCranberry),
                SizedBox(height: 14),
                Text(
                  'Loading wishes...',
                  style: TextStyle(color: _kMutedInk, fontSize: 15),
                ),
              ],
            ),
          );
        }
        final rawMap = event.data!.snapshot.value as Map;
        final allItems = rawMap.entries.map((entry) {
          final itemMap = Map<String, dynamic>.from(entry.value as Map);
          itemMap['id'] = entry.key;
          return Item.fromMap(itemMap);
        }).toList()
          ..sort((a, b) => a.id.compareTo(b.id));

        return ListAllItems(
          allItems: allItems.where((e) => !e.physical).toList(),
          totalCount: allItems.length,
          numTaken: allItems.where((item) => item.isTaken != null).length,
        );
      },
    );
  }
}

class ListAllItems extends StatefulWidget {
  const ListAllItems({
    super.key,
    required this.allItems,
    required this.totalCount,
    required this.numTaken,
  });

  final List<Item> allItems;
  final int totalCount;
  final int numTaken;

  @override
  State<ListAllItems> createState() => _ListAllItemsState();
}

class _ListAllItemsState extends State<ListAllItems> {
  String _searchQuery = '';
  _PriceFilter _priceFilter = _PriceFilter.all;
  bool _hideFulfilled = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Item> get _filteredItems {
    final q = _searchQuery.trim().toLowerCase();
    final filtered = widget.allItems.where((item) {
      if (_hideFulfilled && item.isTaken != null) return false;
      if (_priceFilter == _PriceFilter.upTo25 && item.price > 25.5) {
        return false;
      }
      if (_priceFilter == _PriceFilter.over25 && item.price <= 25.5) {
        return false;
      }
      if (q.isNotEmpty) {
        final hay = '${item.name} ${item.brand}'.toLowerCase();
        if (!hay.contains(q)) return false;
      }
      return true;
    }).toList();

    // Show available wishes first while preserving deterministic hash order.
    filtered.sort((a, b) {
      final aTaken = a.isTaken != null ? 1 : 0;
      final bTaken = b.isTaken != null ? 1 : 0;
      if (aTaken != bTaken) return aTaken.compareTo(bTaken);
      return a.id.compareTo(b.id);
    });
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final items = _filteredItems;
    final total = widget.totalCount > 0 ? widget.totalCount : 100;
    final available = (total - widget.numTaken).clamp(0, total);
    final progress = (widget.numTaken / total).clamp(0.0, 1.0);

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860),
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Hero & Progress Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Make a Holiday Wish Come True',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
                                color: _kInk,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Pick a gift for children and teens at Die Arche München — order it yourself or donate the exact item value via PayPal by December 11.',
                              style: TextStyle(
                                fontSize: 14.5,
                                height: 1.45,
                                color: _kMutedInk,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Text(
                                  '${widget.numTaken} of $total fulfilled',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: _kPine,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: available > 0
                                        ? _kCranberrySoft
                                        : _kPineSoft,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    available > 0
                                        ? '$available wishes still waiting'
                                        : 'All wishes fulfilled!',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: available > 0
                                          ? _kCranberry
                                          : _kPine,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 10,
                                backgroundColor: const Color(0xFFEDF2F7),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  _kPine,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Search & Filters Toolbar
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final narrow = constraints.maxWidth < 620;
                            final searchBox = TextField(
                              controller: _searchController,
                              onChanged: (v) =>
                                  setState(() => _searchQuery = v),
                              decoration: InputDecoration(
                                hintText: 'Search gifts (e.g. LEGO, Tonies, Scooter)...',
                                hintStyle: const TextStyle(
                                  color: _kMutedInk,
                                  fontSize: 14,
                                ),
                                prefixIcon: const Icon(
                                  Icons.search_rounded,
                                  size: 20,
                                  color: _kMutedInk,
                                ),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() => _searchQuery = '');
                                        },
                                        icon: const Icon(
                                          Icons.close_rounded,
                                          size: 18,
                                        ),
                                      )
                                    : null,
                                isDense: true,
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: _kBorder),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: _kBorder),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                    color: _kCranberry,
                                    width: 1.4,
                                  ),
                                ),
                              ),
                            );

                            final filterChips = Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                ChoiceChip(
                                  label: const Text('All prices'),
                                  selected: _priceFilter == _PriceFilter.all,
                                  onSelected: (_) => setState(
                                    () => _priceFilter = _PriceFilter.all,
                                  ),
                                  visualDensity: VisualDensity.compact,
                                ),
                                ChoiceChip(
                                  label: const Text('≤ 25 €'),
                                  selected: _priceFilter == _PriceFilter.upTo25,
                                  onSelected: (_) => setState(
                                    () => _priceFilter = _PriceFilter.upTo25,
                                  ),
                                  visualDensity: VisualDensity.compact,
                                ),
                                ChoiceChip(
                                  label: const Text('26 – 50 €'),
                                  selected: _priceFilter == _PriceFilter.over25,
                                  onSelected: (_) => setState(
                                    () => _priceFilter = _PriceFilter.over25,
                                  ),
                                  visualDensity: VisualDensity.compact,
                                ),
                                FilterChip(
                                  label: const Text('Available only'),
                                  selected: _hideFulfilled,
                                  onSelected: (v) =>
                                      setState(() => _hideFulfilled = v),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ],
                            );

                            if (narrow) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  searchBox,
                                  const SizedBox(height: 10),
                                  filterChips,
                                ],
                              );
                            }
                            return Row(
                              children: [
                                Expanded(child: searchBox),
                                const SizedBox(width: 12),
                                filterChips,
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (items.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.search_off_rounded,
                          size: 40,
                          color: _kMutedInk,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'No wishes match your current filter.',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                              _priceFilter = _PriceFilter.all;
                              _hideFulfilled = false;
                            });
                          },
                          child: const Text('Reset filters'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 36),
                sliver: SliverList.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    return _WishRowCard(item: items[index]);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _WishRowCard extends StatefulWidget {
  final Item item;
  const _WishRowCard({required this.item});

  @override
  State<_WishRowCard> createState() => _WishRowCardState();
}

class _WishRowCardState extends State<_WishRowCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final taken = item.isTaken != null;
    final approxPrice = '~${5 * (item.price / 5).round()} €';

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        decoration: BoxDecoration(
          color: taken
              ? Colors.white.withValues(alpha: 0.65)
              : Colors.white.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _hovered && !taken
                ? _kCranberry.withValues(alpha: 0.45)
                : _kBorder,
          ),
          boxShadow: _hovered && !taken
              ? [
                  BoxShadow(
                    color: _kInk.withValues(alpha: 0.06),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ]
              : const [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (context) => HomePage(argId: item.id),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: taken ? const Color(0xFFF1F5F9) : _kCranberrySoft,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      taken
                          ? Icons.check_rounded
                          : Icons.card_giftcard_rounded,
                      color: taken ? _kMutedInk : _kCranberry,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w600,
                            color: taken ? _kMutedInk : _kInk,
                            decoration:
                                taken ? TextDecoration.lineThrough : null,
                            decorationColor: _kMutedInk,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(
                              Icons.storefront_outlined,
                              size: 13.5,
                              color: _kMutedInk.withValues(
                                alpha: taken ? 0.65 : 0.9,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              item.brand,
                              style: TextStyle(
                                fontSize: 13,
                                color: _kMutedInk.withValues(
                                  alpha: taken ? 0.65 : 0.95,
                                ),
                              ),
                            ),
                            if (item.number > 1) ...[
                              const SizedBox(width: 8),
                              Text(
                                '• ${item.number}×',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _kMutedInk,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (taken)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _kPineSoft,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Fulfilled',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: _kPine,
                        ),
                      ),
                    )
                  else ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: _kBorder),
                      ),
                      child: Text(
                        approxPrice,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: _kInk,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: _hovered ? _kCranberry : _kMutedInk,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
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
        if (!event.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: _kCranberry),
          );
        }
        final raw = event.data!.snapshot.value;
        if (raw is! Map) {
          return Center(
            child: Card(
              margin: const EdgeInsets.all(24),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 40, color: _kCranberry),
                    const SizedBox(height: 12),
                    Text(
                      'No wish found for ID "$id".',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 14),
                    FilledButton(
                      onPressed: () => _navigateToAllWishes(context),
                      child: const Text('Browse all wishes'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final map = Map<String, dynamic>.from(raw);
        map['id'] = id;
        final item = Item.fromMap(map);

        if (item.isTaken == null) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () => _navigateToAllWishes(context),
                            icon: const Icon(Icons.arrow_back_rounded, size: 18),
                            label: const Text('Back to all wishes'),
                            style: TextButton.styleFrom(
                              foregroundColor: _kMutedInk,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.number > 1
                              ? '${item.number}× ${item.name}'
                              : item.name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            color: _kInk,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 10,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: _kBorder),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.storefront_outlined,
                                    size: 15,
                                    color: _kMutedInk,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    item.brand,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13.5,
                                      color: _kMutedInk,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: _kCranberrySoft,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '${item.price.toStringAsFixed(2)} €${item.number > 1 ? ' total' : ''} (excl. delivery)',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.5,
                                  color: _kCranberry,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        Center(child: WishPreviewImage(item: item)),
                        const SizedBox(height: 26),
                        Center(
                          child: FilledButton.icon(
                            onPressed: () {
                              Navigator.push<void>(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (context) =>
                                      MyPage(item: item, ref: ref),
                                ),
                              );
                            },
                            icon: const Icon(Icons.volunteer_activism_rounded),
                            label: const Text('I would like to fulfill this wish!'),
                            style: FilledButton.styleFrom(
                              backgroundColor: _kCranberry,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 28,
                                vertical: 16,
                              ),
                              textStyle: const TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w700,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        } else {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 540),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: _kPineSoft,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.check_circle_rounded,
                            color: _kPine,
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Wish Already Fulfilled!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '"${item.name}" from ${item.brand} has already been picked by a fellow Googler.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.45,
                            color: _kMutedInk,
                          ),
                        ),
                        const SizedBox(height: 22),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            FilledButton.icon(
                              onPressed: () => _navigateToAllWishes(context),
                              icon: const Icon(Icons.card_giftcard_rounded, size: 18),
                              label: const Text('Browse other wishes'),
                              style: FilledButton.styleFrom(
                                backgroundColor: _kCranberry,
                                foregroundColor: Colors.white,
                              ),
                            ),
                            OutlinedButton(
                              onPressed: () {
                                Navigator.push<void>(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder: (context) => MyPage(
                                      item: item,
                                      ref: ref,
                                      taken: true,
                                    ),
                                  ),
                                );
                              },
                              child: const Text('It was me — show links again'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }
      },
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

  Future<void> _copyText(
    BuildContext context,
    String text,
    String snackLabel,
  ) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(snackLabel),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(
        context,
        showHomeAction: true,
        onHomePressed: () => _navigateToAllWishes(context),
      ),
      body: SnowBackdrop(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Selected wish header
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _kBorder),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: _kCranberrySoft,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.card_giftcard_rounded,
                                color: _kCranberry,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Selected wish',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: _kMutedInk,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item.name,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      color: _kInk,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '${item.price.toStringAsFixed(2)} €',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: _kCranberry,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (!taken)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 11,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                size: 18,
                                color: Color(0xFF92400E),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Choose either Option A or Option B below. Clicking an action button immediately marks this wish as fulfilled for others.',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    color: Color(0xFF78350F),
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 20),

                      // Option A: Order yourself
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _kBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Option A — Order the Gift Yourself',
                              style: TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text.rich(
                              TextSpan(
                                style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.45,
                                  color: _kMutedInk,
                                ),
                                children: [
                                  TextSpan(
                                    text:
                                        'Order ${item.number > 1 ? '${item.number} units of ' : ''}the item directly from ${item.brand} and either ship it to the Munich office ',
                                  ),
                                  const TextSpan(
                                    text: 'addressed to Nina Henkel',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: _kInk,
                                    ),
                                  ),
                                  const TextSpan(
                                    text:
                                        ' (important: always include "Nina Henkel" as recipient — do not address it to Google Germany GmbH alone!) or drop it off at desk 5Z1C6C in MUC-ARP by December 14.',
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            FilledButton.icon(
                              onPressed: () async {
                                DataSnapshot? snapshot;
                                if (!taken) {
                                  snapshot = await ref.child('isTaken').get();
                                }
                                if (snapshot == null || snapshot.value == null) {
                                  if (!taken) {
                                    await ref.update({
                                      'isTaken': DateTime.now().toIso8601String(),
                                      'paypal': false,
                                    });
                                  }
                                  await launchUrl(Uri.parse(item.url));
                                } else {
                                  if (context.mounted) Navigator.pop(context);
                                }
                              },
                              icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                              label: Text(
                                taken
                                    ? 'Open product page on ${item.brand}'
                                    : 'Fulfill & Open ${item.brand} Product Page',
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: _kCranberry,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 13,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: _kBorder),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Shipping Address (MUST include "Nina Henkel" as recipient):',
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w700,
                                            color: _kCranberry,
                                          ),
                                        ),
                                        SizedBox(height: 6),
                                        SelectableText(
                                          'Google Germany GmbH\n'
                                          'Nina Henkel\n'
                                          'Erika-Mann-Str. 33\n'
                                          '80636 München',
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            height: 1.4,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: () => _copyText(
                                      context,
                                      shippingAddress,
                                      'Copied shipping address to clipboard.',
                                    ),
                                    icon: const Icon(Icons.copy_rounded, size: 15),
                                    label: const Text('Copy address'),
                                    style: OutlinedButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Option B: PayPal
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _kBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Option B — Let Nina & Moritz Order via PayPal',
                              style: TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Donate ${item.price.toStringAsFixed(2)} € (the exact item value) to our PayPal pool and paste "${item.name}" into the PayPal note so we know which gift to order.',
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.45,
                                color: _kMutedInk,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                FilledButton.icon(
                                  onPressed: () async {
                                    await _copyText(
                                      context,
                                      item.name,
                                      'Copied "${item.name}" to clipboard for the PayPal note.',
                                    );
                                    DataSnapshot? snapshot;
                                    if (!taken) {
                                      snapshot =
                                          await ref.child('isTaken').get();
                                    }
                                    if (snapshot == null ||
                                        snapshot.value == null) {
                                      if (!taken) {
                                        await ref.update({
                                          'isTaken':
                                              DateTime.now().toIso8601String(),
                                          'paypal': true,
                                        });
                                      }
                                      await launchUrl(Uri.parse(paypalPoolUrl));
                                    } else {
                                      if (context.mounted) {
                                        Navigator.pop(context);
                                      }
                                    }
                                  },
                                  icon: const Icon(
                                    Icons.account_balance_wallet_outlined,
                                    size: 18,
                                  ),
                                  label: Text(
                                    taken
                                        ? 'Open PayPal Pool (${item.price.toStringAsFixed(2)} €)'
                                        : 'Fulfill & Donate ${item.price.toStringAsFixed(2)} € via PayPal',
                                  ),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFF005EA6),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 13,
                                    ),
                                  ),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () => _copyText(
                                    context,
                                    item.name,
                                    'Copied "${item.name}" to clipboard.',
                                  ),
                                  icon: const Icon(Icons.copy_rounded, size: 16),
                                  label: const Text('Copy item name for PayPal note'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Footer help
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text(
                            'Questions? Read the FAQs at ',
                            style: TextStyle(color: _kMutedInk, fontSize: 13.5),
                          ),
                          InkWell(
                            onTap: () =>
                                launchUrl(Uri.parse('http://$faqGoLink')),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 2,
                                vertical: 2,
                              ),
                              child: Text(
                                faqGoLink,
                                style: TextStyle(
                                  color: _kCranberry,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.5,
                                  decoration: TextDecoration.underline,
                                  decorationColor: _kCranberry,
                                ),
                              ),
                            ),
                          ),
                          const Text(
                            ' or contact @henkel or @mosum.',
                            style: TextStyle(color: _kMutedInk, fontSize: 13.5),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message: 'Click to open full-size preview in new tab',
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => launchUrl(fullImageUri),
              child: Container(
                constraints: const BoxConstraints(maxHeight: 380, maxWidth: 580),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _kBorder),
                  boxShadow: [
                    BoxShadow(
                      color: _kInk.withValues(alpha: 0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    relativePath,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const SizedBox(
                        height: 200,
                        width: 240,
                        child: Center(
                          child: CircularProgressIndicator(color: _kCranberry),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      if (item.snipit.isNotEmpty) {
                        return TextButton.icon(
                          onPressed: () => launchUrl(Uri.parse(item.snipit)),
                          icon: const Icon(Icons.image_outlined),
                          label: const Text('Preview the wish'),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Click image to view full size',
          style: TextStyle(fontSize: 12, color: _kMutedInk),
        ),
      ],
    );
  }
}
