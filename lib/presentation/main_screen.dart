import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'sets/set_list_screen.dart';        
import 'search/card_search_screen.dart';   
import 'inventory/inventory_screen.dart';  
import 'binders/binder_list_screen.dart';  
import '../../data/sync/pokedex_importer.dart';
import '../../data/database/database_provider.dart';
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
    _initPokedex();
  }

  Future<void> _initPokedex() async {
    final db = ref.read(databaseProvider);
    final importer = PokedexImporter(db);
    await importer.syncPokedex();
  }

  late final List<Widget> _tabs = [
    _buildTabNavigator(_searchNavigatorKey, const CardSearchScreen()),
    _buildTabNavigator(_setsNavigatorKey, const SetListScreen()),
    _buildTabNavigator(_inventoryNavigatorKey, const InventoryScreen()),
    _buildTabNavigator(_binderNavigatorKey, const BinderListScreen()),
  ];

  void _openScanner() {
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async { 
        if (didPop) return;

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
          currentNavigator.pop();
        } else {
          if (context.mounted) Navigator.of(context).pop(); 
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false, 
        
        body: IndexedStack(
          index: _currentIndex,
          children: [
            _activeTabs.contains(0) ? _tabs[0] : const SizedBox.shrink(),
            _activeTabs.contains(1) ? _tabs[1] : const SizedBox.shrink(),
            _activeTabs.contains(2) ? _tabs[2] : const SizedBox.shrink(),
            _activeTabs.contains(3) ? _tabs[3] : const SizedBox.shrink(),
          ],
        ),

        // --- DER SCANNER BUTTON ---
        floatingActionButton: SizedBox(
          height: 64, // Leicht vergrößert für die perfekte Kreisform
          width: 64,
          child: FloatingActionButton(
            onPressed: _openScanner,
            backgroundColor: theme.colorScheme.primary,
            elevation: 4, 
            shape: const CircleBorder(),
            child: const Icon(Icons.qr_code_scanner, size: 28, color: Colors.white), 
          ),
        ),
        // --- HIER NUTZEN WIR UNSEREN NEUEN, TIEFEREN ANKERPUNKT ---
        floatingActionButtonLocation: const _LoweredCenterDockedFabLocation(),

        // --- DIE BOTTOM BAR (mit Notch) ---
        bottomNavigationBar: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 8.0, // Die wunderschöne Lücke! (Erhöht für besseren Effekt)
          clipBehavior: Clip.antiAlias, // WICHTIG: Schneidet die Ecken wirklich physisch ab!
          color: theme.colorScheme.surface,
          elevation: 16,
          child: SizedBox(
            height: 60, 
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNavItem(0, Icons.search, 'Suche', theme),
                      _buildNavItem(1, Icons.collections_bookmark, 'Sets', theme),
                    ],
                  ),
                ),
                const SizedBox(width: 48), // Platz für den Button
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

  Widget _buildNavItem(int index, IconData icon, String label, ThemeData theme) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? theme.colorScheme.primary : Colors.grey;

    return InkWell(
      onTap: () {
        if (_currentIndex == index) {
          final nav = index == 0 ? _searchNavigatorKey.currentState 
                    : index == 1 ? _setsNavigatorKey.currentState 
                    : index == 2 ? _inventoryNavigatorKey.currentState
                    : _binderNavigatorKey.currentState; 
          nav?.popUntil((route) => route.isFirst);
        } else {
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

// =========================================================================
// EIGENE KLASSE UM DEN BUTTON TIEFER ZU SETZEN
// =========================================================================
class _LoweredCenterDockedFabLocation extends FloatingActionButtonLocation {
  const _LoweredCenterDockedFabLocation();

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    // 1. Die Mitte des Bildschirms berechnen
    final double fabX = (scaffoldGeometry.scaffoldSize.width - scaffoldGeometry.floatingActionButtonSize.width) / 2.0;
    
    // 2. Standard-Docked-Höhe berechnen
    final double standardY = scaffoldGeometry.contentBottom - (scaffoldGeometry.floatingActionButtonSize.height / 2.0);
    
    // 3. Den Button um 12 Pixel tiefer setzen! (Kannst du anpassen, wenn er noch tiefer soll)
    final double fabY = standardY + 24.0; 
    
    return Offset(fabX, fabY);
  }
}