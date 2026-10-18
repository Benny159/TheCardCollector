/// Categorization and specialization types for collection binders and bulk boxes.
enum AdvancedBinderType {
  /// User-defined freeform collection binder.
  custom,

  /// Pokédex-oriented numerical collection binder.
  dex,

  /// Set-oriented expansion binder.
  set,

  /// Binder dedicated to a specific Pokémon across sets.
  pokemon,

  /// Binder dedicated to card artworks by a specific artist.
  artist,

  /// Storage box for unsorted or bulk cards without strict slot numbering.
  bulkBox,
}

/// Completion criteria for set-oriented binders.
enum SetCompletionType {
  /// Only standard numbered cards (1 through printed total).
  standard,

  /// Standard numbered cards plus regular holofoil and reverse holofoil variants.
  master,

  /// Complete collection including all secret rares, variants, and promo prints.
  complete,
}

/// Sorting placement for alternative forms in Pokédex binders.
enum DexSortStyle {
  /// Places alternative forms directly behind the national dex species base entry.
  inline,

  /// Groups all alternative forms in an appended section at the end of the binder.
  appended,
}

/// Directional layout order when viewing slots on a binder page.
enum BinderSortOrder {
  /// Reads slots row-by-row from left to right.
  leftToRight,

  /// Reads slots column-by-column from top to bottom.
  topToBottom,
}