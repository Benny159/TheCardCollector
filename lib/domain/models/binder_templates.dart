enum BinderType {
  custom,
  nationalDex,
  kantoDex,  // Gen 1
  johtoDex,  // Gen 2
  hoennDex,  // Gen 3
  sinnohDex, // Gen 4
  einallDex, // Gen 5 (Unova)
  kalosDex,  // Gen 6
  alolaDex,  // Gen 7
  galarDex,  // Gen 8 (inkl. Hisui)
  paldeaDex, // Gen 9
}

class BinderTemplateInfo {
  final BinderType type;
  final String label;
  final String description;
  final String? iconAsset; 

  const BinderTemplateInfo(this.type, this.label, this.description, {this.iconAsset});
}

const List<BinderTemplateInfo> availableTemplates = [
  BinderTemplateInfo(
    BinderType.custom, 
    "Benutzerdefiniert", 
    "Leerer Binder, alles selbst gestalten."
  ),
  BinderTemplateInfo(
    BinderType.nationalDex, 
    "National Dex (Alle)", 
    "Slots für alle 1025 Pokémon (#0001 - #1025)."
  ),
  BinderTemplateInfo(
    BinderType.kantoDex, 
    "Kanto (Gen 1)", 
    "Bisasam bis Mew (#001 - #151)."
  ),
  BinderTemplateInfo(
    BinderType.johtoDex, 
    "Johto (Gen 2)", 
    "Endivie bis Celebi (#152 - #251)."
  ),
  BinderTemplateInfo(
    BinderType.hoennDex, 
    "Hoenn (Gen 3)", 
    "Geckarbor bis Deoxys (#252 - #386)."
  ),
  BinderTemplateInfo(
    BinderType.sinnohDex, 
    "Sinnoh (Gen 4)", 
    "Chelast bis Arceus (#387 - #493)."
  ),
  BinderTemplateInfo(
    BinderType.einallDex, 
    "Einall (Gen 5)", 
    "Victini bis Genesect (#494 - #649)."
  ),
  BinderTemplateInfo(
    BinderType.kalosDex, 
    "Kalos (Gen 6)", 
    "Igamaro bis Volcanion (#650 - #721)."
  ),
  BinderTemplateInfo(
    BinderType.alolaDex, 
    "Alola (Gen 7)", 
    "Bauz bis Melmetal (#722 - #809)."
  ),
  BinderTemplateInfo(
    BinderType.galarDex, 
    "Galar & Hisui (Gen 8)", 
    "Chimpep bis Enamorus (#810 - #905)."
  ),
  BinderTemplateInfo(
    BinderType.paldeaDex, 
    "Paldea (Gen 9)", 
    "Felori bis Pecharunt (#906 - #1025)."
  ),
];