import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'sets/set_list_screen.dart';        // Dein Set-Screen Import
import 'search/card_search_screen.dart';   // Dein Such-Screen Import
import 'inventory/inventory_screen.dart';  // Dein Inventar-Screen Import
import 'binders/binder_list_screen.dart';  // <--- NEU: Dein Binder-Screen Import
import '../../data/sync/pokedex_importer.dart';
import '../../data/database/database_provider.dart';

// Wir brauchen Keys, um den Status der Navigatoren zu speichern
final _searchNavigatorKey = GlobalKey<NavigatorState>();
final _setsNavigatorKey = GlobalKey<NavigatorState>();
final _inventoryNavigatorKey = GlobalKey<NavigatorState>();
final _binderNavigatorKey = GlobalKey<NavigatorState>(); // <--- NEU: Key für Binder

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentIndex = 0;
  final List<int> _activeTabs = [0];

  @override
  void initState() {
    super.initState();
    // Startet den Import im Hintergrund (blockiert die UI nicht)
    _initPokedex();
  }

  Future<void> _initPokedex() async {
    final db = ref.read(databaseProvider);
    final importer = PokedexImporter(db);
    await importer.syncPokedex();
  }

  // Hier definieren wir unsere vier Tabs
  late final List<Widget> _tabs = [
    // TAB 0: SUCHE
    _buildTabNavigator(
      _searchNavigatorKey, 
      const CardSearchScreen(),
    ),
    
    // TAB 1: SETS
    _buildTabNavigator(
      _setsNavigatorKey, 
      const SetListScreen(),
    ),

    // TAB 2: INVENTAR
    _buildTabNavigator(
      _inventoryNavigatorKey, 
      const InventoryScreen(),
    ),

    // TAB 3: BINDER (NEU)
    _buildTabNavigator(
      _binderNavigatorKey, 
      const BinderListScreen(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // PopScope sorgt dafür, dass der Zurück-Button (Android) 
    // erst im Tab zurückgeht, bevor er die App schließt.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async { // Korrekte Signatur für neues Flutter
        if (didPop) return;

        // Welcher Navigator ist gerade aktiv?
        final NavigatorState? currentNavigator;
        if (_currentIndex == 0) {
          currentNavigator = _searchNavigatorKey.currentState;
        } else if (_currentIndex == 1) {
          currentNavigator = _setsNavigatorKey.currentState;
        } else if (_currentIndex == 2) {
          currentNavigator = _inventoryNavigatorKey.currentState;
        } else {
          // Index 3 ist Binder
          currentNavigator = _binderNavigatorKey.currentState;
        }

        if (currentNavigator != null && currentNavigator.canPop()) {
          // Wenn wir im Tab zurückgehen können, tun wir das
          currentNavigator.pop();
        } else {
          // Wenn wir ganz am Anfang sind, schließen wir die App (oder minimieren)
          if (context.mounted) Navigator.of(context).pop(); 
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: [
            // NEU: Tabs werden erst gerendert, wenn sie in _activeTabs stehen
            _activeTabs.contains(0) ? _tabs[0] : const SizedBox.shrink(),
            _activeTabs.contains(1) ? _tabs[1] : const SizedBox.shrink(),
            _activeTabs.contains(2) ? _tabs[2] : const SizedBox.shrink(),
            _activeTabs.contains(3) ? _tabs[3] : const SizedBox.shrink(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            if (_currentIndex == index) {
              final nav = index == 0 ? _searchNavigatorKey.currentState 
                        : index == 1 ? _setsNavigatorKey.currentState 
                        : index == 2 ? _inventoryNavigatorKey.currentState
                        : _binderNavigatorKey.currentState; // <--- NEU
              nav?.popUntil((route) => route.isFirst);
            } else {
              setState(() {
                _currentIndex = index;
                // NEU: Wenn der Tab noch nie besucht wurde, fügen wir ihn hinzu
                if (!_activeTabs.contains(index)) {
                  _activeTabs.add(index);
                }
              });
            }
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.search),
              label: 'Suche',
            ),
            NavigationDestination(
              icon: Icon(Icons.collections_bookmark),
              label: 'Sets',
            ),
            NavigationDestination(
              icon: Icon(Icons.inventory_2), 
              label: 'Inventar',
            ),
            // <--- NEU: Der vierte Tab
            NavigationDestination(
              icon: Icon(Icons.book), 
              label: 'Binder',
            ),
          ],
        ),
      ),
    );
  }

  // HILFSFUNKTION: Baut einen Navigator für einen Tab
  static Widget _buildTabNavigator(GlobalKey<NavigatorState> key, Widget initialScreen) {
    return Navigator(
      key: key,
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          builder: (_) => initialScreen,
        );
      },
    );
  }
}