import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'sets/set_list_screen.dart';        // Dein Set-Screen Import
import 'search/card_search_screen.dart';   // Dein Such-Screen Import

// Wir brauchen Keys, um den Status der Navigatoren zu speichern
final _searchNavigatorKey = GlobalKey<NavigatorState>();
final _setsNavigatorKey = GlobalKey<NavigatorState>();

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentIndex = 0;

  // Hier definieren wir unsere zwei Tabs
  // Wir nutzen "Navigator", damit man IN dem Tab weiterklicken kann, 
  // ohne dass die BottomBar verschwindet.
  late final List<Widget> _tabs = [
    // TAB 0: SUCHE
    _buildTabNavigator(
      _searchNavigatorKey, 
      const CardSearchScreen(),
    ),
    
    // TAB 1: SETS
    _buildTabNavigator(
      _setsNavigatorKey, 
      const SetListScreen(), // Stelle sicher, dass du diesen Screen hast
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // PopScope sorgt dafür, dass der Zurück-Button (Android) 
    // erst im Tab zurückgeht, bevor er die App schließt.
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;

        final NavigatorState? currentNavigator = _currentIndex == 0 
            ? _searchNavigatorKey.currentState 
            : _setsNavigatorKey.currentState;

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
          children: _tabs,
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            // Wenn man auf den Tab klickt, in dem man schon ist,
            // gehen wir zurück zum Anfang (wie bei Instagram/Spotify)
            if (_currentIndex == index) {
              final nav = index == 0 ? _searchNavigatorKey.currentState : _setsNavigatorKey.currentState;
              nav?.popUntil((route) => route.isFirst);
            } else {
              setState(() {
                _currentIndex = index;
              });
            }
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.search),
              label: 'Suche',
            ),
            NavigationDestination(
              icon: Icon(Icons.collections_bookmark), // Oder dein Set Icon
              label: 'Sets',
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