import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'sets/set_list_screen.dart';        
import 'search/card_search_screen.dart';   
import 'inventory/inventory_screen.dart';  
import 'binders/binder_list_screen.dart';  
import '../../data/sync/pokedex_importer.dart';
import '../../data/database/database_provider.dart';

// --- NEU: Import für den Scanner (Datei erstellen wir gleich) ---
import 'scanner/scanner_screen.dart'; 

// Wir brauchen Keys, um den Status der Navigatoren zu speichern
final _searchNavigatorKey = GlobalKey<NavigatorState>();
final _setsNavigatorKey = GlobalKey<NavigatorState>();
final _inventoryNavigatorKey = GlobalKey<NavigatorState>();
final _binderNavigatorKey = GlobalKey<NavigatorState>(); 

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
    _buildTabNavigator(_searchNavigatorKey, const CardSearchScreen()),
    // TAB 1: SETS
    _buildTabNavigator(_setsNavigatorKey, const SetListScreen()),
    // TAB 2: INVENTAR
    _buildTabNavigator(_inventoryNavigatorKey, const InventoryScreen()),
    // TAB 3: BINDER
    _buildTabNavigator(_binderNavigatorKey, const BinderListScreen()),
  ];

  // --- NEU: Scanner öffnen Methode ---
  void _openScanner() {
    // Öffnet den Scanner über die komplette App (inkl. Nav-Leiste)
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (ctx) => const ScannerScreen(),
        fullscreenDialog: true, 
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // PopScope sorgt dafür, dass der Zurück-Button (Android) 
    // erst im Tab zurückgeht, bevor er die App schließt.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async { 
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
          currentNavigator = _binderNavigatorKey.currentState;
        }

        if (currentNavigator != null && currentNavigator.canPop()) {
          // Wenn wir im Tab zurückgehen können, tun wir das
          currentNavigator.pop();
        } else {
          // Wenn wir ganz am Anfang sind, schließen wir die App
          if (context.mounted) Navigator.of(context).pop(); 
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: [
            _activeTabs.contains(0) ? _tabs[0] : const SizedBox.shrink(),
            _activeTabs.contains(1) ? _tabs[1] : const SizedBox.shrink(),
            _activeTabs.contains(2) ? _tabs[2] : const SizedBox.shrink(),
            _activeTabs.contains(3) ? _tabs[3] : const SizedBox.shrink(),
          ],
        ),

        // --- NEU: Der fette, hervorgehobene Scanner-Button ---
        floatingActionButton: Container(
          height: 65,
          width: 65,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.4),
                spreadRadius: 2,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: FloatingActionButton(
            onPressed: _openScanner,
            backgroundColor: theme.colorScheme.primary,
            elevation: 0,
            shape: const CircleBorder(),
            child: const Icon(Icons.qr_code_scanner, size: 32, color: Colors.white),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

        // --- NEU: BottomAppBar, die den FAB "umschließt" ---
        bottomNavigationBar: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 8.0,
          color: theme.colorScheme.surface,
          elevation: 8,
          child: SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Linke Seite
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNavItem(0, Icons.search, 'Suche', theme),
                      _buildNavItem(1, Icons.collections_bookmark, 'Sets', theme),
                    ],
                  ),
                ),
                // Platz für den Notch (Scanner-Button in der Mitte)
                const SizedBox(width: 48), 
                // Rechte Seite
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNavItem(2, Icons.inventory_2, 'Inventar', theme),
                      _buildNavItem(3, Icons.book, 'Binder', theme),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- HILFSFUNKTION FÜR DIE NEUEN TAB-BUTTONS ---
  Widget _buildNavItem(int index, IconData icon, String label, ThemeData theme) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? theme.colorScheme.primary : Colors.grey;

    return InkWell(
      onTap: () {
        if (_currentIndex == index) {
          // Tab wurde nochmal angetippt -> Zurück zum Start des Tabs scrollen/navigieren
          final nav = index == 0 ? _searchNavigatorKey.currentState 
                    : index == 1 ? _setsNavigatorKey.currentState 
                    : index == 2 ? _inventoryNavigatorKey.currentState
                    : _binderNavigatorKey.currentState; 
          nav?.popUntil((route) => route.isFirst);
        } else {
          // Normaler Tab-Wechsel
          setState(() {
            _currentIndex = index;
            if (!_activeTabs.contains(index)) {
              _activeTabs.add(index);
            }
          });
        }
      },
      borderRadius: BorderRadius.circular(50),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: color,
              ),
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