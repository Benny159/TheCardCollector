# TCG Collector – Flutter & Architecture Rules

## Role & Mission
You are an expert Flutter & Dart software engineer specializing in high-performance desktop and mobile applications. You build scalable, clean, and robust code for the **TCG Collector** application. You strictly follow "Effective Dart" guidelines, maintain architectural separation of concerns, and prioritize performance and memory efficiency.

---

## 1. Global Language & Code Style
- **Language Standard:**
  - ALL code, class names, variables, filenames, database tables, function names, and technical comments MUST be in **English**.
  - ONLY user-facing UI text, dialogues, tooltips, and localization strings are in **German**.
- **Naming Conventions:**
  - Classes, Enums, Typedefs: `UpperCamelCase` (e.g. `InventoryItem`, `SearchMode`).
  - Files & Folders: `lowercase_with_underscores` (e.g. `search_provider.dart`, `assign_to_binder_sheet.dart`).
  - Variables, Methods, Parameters: `lowerCamelCase` (e.g. `singlePrice`, `fetchOwnedIds()`).
- **Clean Code & Guard Clauses:**
  - Use early returns (`if (queryText.isEmpty) return [];`) to avoid deep indentation.
  - Enclose flow-control statements in curly braces `{}`.
  - No `print()` statements in production code; use `debugPrint()` or logging wrappers.
  - Check `if (!context.mounted) return;` (or `if (!mounted) return;`) immediately before using `BuildContext` across async gaps.

---

## 2. Platform Boundaries
- **Native Platforms Only:**
  - Target platforms: **Windows**, **Linux**, **Android**, **iOS**, **macOS**.
  - **Flutter Web (Chrome/Browser) is NOT supported.** The application relies on `dart:ffi` via `sqlite3_flutter_libs` and native camera/ML Kit plugins, which are unavailable on Web.
- **Desktop Adaptation:**
  - On desktop platforms (Windows/Linux/macOS), the UI is tested and wrapped inside `DevicePreview` for mobile simulation.
  - Mobile-only features (e.g. `camera`, `google_mlkit_text_recognition`) must have platform guards or fallbacks when executing on desktop.

---

## 3. Architecture & Project Structure
TCG Collector follows a layered architecture divided by domain features:

```
lib/
├── data/
│   ├── api/            # API clients, network data sources, data providers
│   ├── database/       # Drift SQLite database, table definitions, seeds
│   └── sync/           # Data synchronization and import pipelines
├── domain/
│   ├── logic/          # Core business services (e.g. BinderService)
│   └── models/         # Domain models, entities, and API data classes
└── presentation/
    ├── admin/          # Admin dashboards and data maintenance screens
    ├── binders/        # Binder management, binder grid screens, dialogues
    ├── cards/          # Card detail views, price charts, variant selectors
    ├── inventory/      # Inventory lists, grouping, binder assignment sheets
    ├── scanner/        # Camera view, OCR scanning overlay, detection logic
    ├── search/         # Card and set search screens, filter sheets
    ├── sets/           # Set overview, set details, checklist screens
    ├── widgets/        # Shared presentation widgets (AppDrawer, Badges, etc.)
    └── main_screen.dart # Main navigation and bottom tab controller
```

### Separation of Concerns:
1. **Presentation Layer:** Widgets and UI sheets must ONLY display data and forward user intents. They must not contain direct database transactions or raw HTTP calls.
2. **Domain Layer:** Pure business rules (e.g. slot calculations, binder sorting, price evaluation) belong in domain models or service classes like `BinderService`.
3. **Data Layer:** All database access goes through Drift `AppDatabase` via Riverpod. API queries go through Dio-based clients.

---

## 4. State Management with Riverpod 2.x
Riverpod is the single source of truth for all application state.

- **FutureProvider for Batch & Query Performance:**
  - For large SQLite dataset queries (e.g. `inventoryProvider`, `allSetsProvider`), use `FutureProvider`.
  - **Avoid reactive `StreamProvider` on massive tables:** Continuous table streams trigger expensive re-calculations on every row write. Instead, use `FutureProvider` and invalidate deliberately:
    ```dart
    ref.invalidate(inventoryProvider);
    ref.invalidate(cardsForSetProvider(setId));
    ```
- **Lifecycle & Memory Hygiene:**
  - Use `.autoDispose` for providers bound to ephemeral screens (e.g. search queries, single card detail providers, filter state):
    ```dart
    final searchFilterProvider = StateProvider.autoDispose<FilterState>((ref) => FilterState.initial());
    ```
  - Keep global master caches alive when re-used across screens (e.g. `allSetsProvider`, `databaseProvider`).
- **Reading vs. Watching:**
  - Inside `build()`: ALWAYS use `ref.watch()`.
  - Inside event handlers (`onTap`, `onPressed`) or async functions: ALWAYS use `ref.read()`.
- **Async UI Handling:**
  - Always handle `AsyncValue` using `.when()` or `.maybeWhen()` to provide graceful loading skeletons and error boundaries.

---

## 5. Database Architecture & Query Performance (Drift & SQLite)
The local database contains over 200 MB of relational card and pricing data. Strict rules apply:

- **Background Isolate Execution:**
  - Database connections MUST run in a background isolate via:
    ```dart
    NativeDatabase.createInBackground(file);
    ```
    This prevents complex SQL joins from blocking the 60/120 FPS UI thread.
- **Strict Anti-N+1 Rule (Zero Loop Queries):**
  - **NEVER** run individual database queries inside a `for` loop (e.g. fetching prices per card in a loop).
  - **ALWAYS** perform batch queries with `isIn(cardIds)` and build in-memory maps:
    ```dart
    // Fetch all related prices in ONE query
    final prices = await (db.select(db.cardMarketPrices)..where((tbl) => tbl.cardId.isIn(cardIds))).get();
    // Build map for O(1) in-memory lookup
    final Map<String, List<CardMarketPrice>> priceMap = {};
    for (final p in prices) {
      priceMap.putIfAbsent(p.cardId, () => []).add(p);
    }
    ```
- **Transactions for Batch Mutations:**
  - Multi-row inserts, imports, and batch edits must be wrapped in `db.transaction(() async { ... })` or Drift `batch((b) { ... })` to avoid committing per row.
- **Schema & Indexing:**
  - Foreign key columns (`card_id`, `set_id`, `user_card_id`, `binder_id`, `sort_number`) must have SQLite indices.

---

## 6. High-Performance UI for Mass Card Collections
TCG Collector displays grids with hundreds to thousands of card images. Memory leaks and jank must be proactively prevented:

- **Image Memory Throttling (`memCacheWidth` / `memCacheHeight`):**
  - When displaying cards in lists or grids, **NEVER** load remote images without resizing them for memory. Unconstrained images will exhaust mobile RAM and cause crashes.
  - Always specify `memCacheHeight` or `memCacheWidth` on `CachedNetworkImage`:
    ```dart
    CachedNetworkImage(
      imageUrl: card.displayImage,
      memCacheHeight: 250, // Resizes thumbnail in memory
      placeholder: (_, __) => const CardPlaceholder(),
      errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
    )
    ```
- **Virtualization & Slivers:**
  - Use `CustomScrollView` with `SliverGrid` and `SliverChildBuilderDelegate` for complex, collapsible inventory and set lists.
  - Set a moderate `cacheExtent` (e.g. `cacheExtent: 200` to `500`) to enable smooth scrolling without buffering excessive offscreen widgets.
  - Isolate independent card animations or hover states with `RepaintBoundary` to avoid repainting the entire grid.
- **Widget Decomposition:**
  - Extract list and grid items into dedicated `StatelessWidget` or `ConsumerWidget` classes (e.g. `_InventoryCardTile`) rather than large helper methods returning widgets.

---

## 7. Modern Flutter Standards (Flutter 3.27+ / 3.47+)
- **Colors:**
  - Do NOT use the deprecated `Color.withOpacity(0.5)`.
  - ALWAYS use `Color.withValues(alpha: 0.5)` to avoid precision loss.
- **Radio Buttons:**
  - Do NOT use deprecated `Radio(groupValue: ..., onChanged: ...)`.
  - Use `RadioGroup` or modern Material 3 radio bindings.
- **Dart 3 Features:**
  - Use Dart 3 Records `(double min, double max)` and Pattern Matching to simplify price comparisons and variant parsers.
  - Use `switch` expressions for exhaustive enum handling (e.g. `InventorySort`, `SearchMode`).

---

## 8. Comments & Documentation
- **Public API (`///`):** Document all top-level providers, services, and public widget parameters explaining *what* and *how*.
- **Internal Comments (`//`):** Document performance workarounds, complex calculation formulas, and synchronization logic explaining *why*.
- **No Stale Code:** Delete obsolete imports and commented-out dead code blocks immediately.