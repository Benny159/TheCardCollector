import 'package:drift/drift.dart';
import 'app_database.dart';

class DatabaseInitializer {
  final AppDatabase db;

  DatabaseInitializer(this.db);

  /// Synchronisiert die Mapping-Tabelle.
  /// Neue Einträge werden hinzugefügt, bestehende werden aktualisiert.
  Future<void> seedInitialMappings() async {
    print('🌱 Überprüfe/Aktualisiere Set-Mappings...');

    final List<Map<String, String?>> initialMappings = [
      // --- DIE AUTOMATISCHEN MATCHES ---
      {"tcgdexId": "base1", "ptcgId": "base1", "cmCode": "BS"}, // TCGdex: Base Set | PTCG: Base
      {"tcgdexId": "base2", "ptcgId": "base2", "cmCode": "JU"}, // TCGdex: Jungle | PTCG: Jungle
      {"tcgdexId": "basep", "ptcgId": "basep", "cmCode": "PR"}, // TCGdex: Wizards Black Star Promos | PTCG: Wizards Black Star Promos
      {"tcgdexId": "base3", "ptcgId": "base3", "cmCode": "FO"}, // TCGdex: Fossil | PTCG: Fossil
      {"tcgdexId": "base4", "ptcgId": "base4", "cmCode": "B2"}, // TCGdex: Base Set 2 | PTCG: Base Set 2
      {"tcgdexId": "base5", "ptcgId": "base5", "cmCode": "TR"}, // TCGdex: Team Rocket | PTCG: Team Rocket
      {"tcgdexId": "gym1", "ptcgId": "gym1", "cmCode": "G1"}, // TCGdex: Gym Heroes | PTCG: Gym Heroes
      {"tcgdexId": "gym2", "ptcgId": "gym2", "cmCode": "G2"}, // TCGdex: Gym Challenge | PTCG: Gym Challenge
      {"tcgdexId": "neo1", "ptcgId": "neo1", "cmCode": "N1"}, // TCGdex: Neo Genesis | PTCG: Neo Genesis
      {"tcgdexId": "neo2", "ptcgId": "neo2", "cmCode": "N2"}, // TCGdex: Neo Discovery | PTCG: Neo Discovery
      {"tcgdexId": "si1", "ptcgId": "si1", "cmCode": ""}, // TCGdex: Southern Islands | PTCG: Southern Islands
      {"tcgdexId": "neo3", "ptcgId": "neo3", "cmCode": "N3"}, // TCGdex: Neo Revelation | PTCG: Neo Revelation
      {"tcgdexId": "neo4", "ptcgId": "neo4", "cmCode": "N4"}, // TCGdex: Neo Destiny | PTCG: Neo Destiny
      {"tcgdexId": "lc", "ptcgId": "base6", "cmCode": "LC"}, // TCGdex: Legendary Collection | PTCG: Legendary Collection
      {"tcgdexId": "ecard1", "ptcgId": "ecard1", "cmCode": "EX"}, // TCGdex: Expedition Base Set | PTCG: Expedition Base Set
      {"tcgdexId": "bog", "ptcgId": "bp", "cmCode": "BP"}, // TCGdex: Best of game | PTCG: Best of Game
      {"tcgdexId": "ecard2", "ptcgId": "ecard2", "cmCode": "AQ"}, // TCGdex: Aquapolis | PTCG: Aquapolis
      {"tcgdexId": "ecard3", "ptcgId": "ecard3", "cmCode": "SK"}, // TCGdex: Skyridge | PTCG: Skyridge
      {"tcgdexId": "ex1", "ptcgId": "ex1", "cmCode": "RS"}, // TCGdex: Ruby & Sapphire | PTCG: Ruby & Sapphire
      {"tcgdexId": "ex2", "ptcgId": "ex2", "cmCode": "SS"}, // TCGdex: Sandstorm | PTCG: Sandstorm
      {"tcgdexId": "np", "ptcgId": "np", "cmCode": "PR-NP"}, // TCGdex: Nintendo Black Star Promos | PTCG: Nintendo Black Star Promos
      {"tcgdexId": "ex3", "ptcgId": "ex3", "cmCode": "DR"}, // TCGdex: Dragon | PTCG: Dragon
      {"tcgdexId": "ex4", "ptcgId": "ex4", "cmCode": "MA"}, // TCGdex: Team Magma vs Team Aqua | PTCG: Team Magma vs Team Aqua
      {"tcgdexId": "ex5", "ptcgId": "ex5", "cmCode": "HL"}, // TCGdex: Hidden Legends | PTCG: Hidden Legends
      {"tcgdexId": "ex6", "ptcgId": "ex6", "cmCode": "RG"}, // TCGdex: FireRed & LeafGreen | PTCG: FireRed & LeafGreen
      {"tcgdexId": "pop1", "ptcgId": "pop1", "cmCode": ""}, // TCGdex: POP Series 1 | PTCG: POP Series 1
      {"tcgdexId": "ex7", "ptcgId": "ex7", "cmCode": "TRR"}, // TCGdex: Team Rocket Returns | PTCG: Team Rocket Returns
      {"tcgdexId": "ex8", "ptcgId": "ex8", "cmCode": "DX"}, // TCGdex: Deoxys | PTCG: Deoxys
      {"tcgdexId": "ex9", "ptcgId": "ex9", "cmCode": "EM"}, // TCGdex: Emerald | PTCG: Emerald
      {"tcgdexId": "pop2", "ptcgId": "pop2", "cmCode": ""}, // TCGdex: POP Series 2 | PTCG: POP Series 2
      {"tcgdexId": "ex10", "ptcgId": "ex10", "cmCode": "UF"}, // TCGdex: Unseen Forces | PTCG: Unseen Forces
      {"tcgdexId": "ex11", "ptcgId": "ex11", "cmCode": "DS"}, // TCGdex: Delta Species | PTCG: Delta Species
      {"tcgdexId": "ex12", "ptcgId": "ex12", "cmCode": "LM"}, // TCGdex: Legend Maker | PTCG: Legend Maker
      {"tcgdexId": "pop3", "ptcgId": "pop3", "cmCode": ""}, // TCGdex: POP Series 3 | PTCG: POP Series 3
      {"tcgdexId": "ex13", "ptcgId": "ex13", "cmCode": "HP"}, // TCGdex: Holon Phantoms | PTCG: Holon Phantoms
      {"tcgdexId": "pop4", "ptcgId": "pop4", "cmCode": ""}, // TCGdex: POP Series 4 | PTCG: POP Series 4
      {"tcgdexId": "ex14", "ptcgId": "ex14", "cmCode": "CG"}, // TCGdex: Crystal Guardians | PTCG: Crystal Guardians
      {"tcgdexId": "ex15", "ptcgId": "ex15", "cmCode": "DF"}, // TCGdex: Dragon Frontiers | PTCG: Dragon Frontiers
      {"tcgdexId": "ex16", "ptcgId": "ex16", "cmCode": "PK"}, // TCGdex: Power Keepers | PTCG: Power Keepers
      {"tcgdexId": "pop5", "ptcgId": "pop5", "cmCode": ""}, // TCGdex: POP Series 5 | PTCG: POP Series 5
      {"tcgdexId": "dp1", "ptcgId": "dp1", "cmCode": "DP"}, // TCGdex: Diamond & Pearl | PTCG: Diamond & Pearl
      {"tcgdexId": "dpp", "ptcgId": "dpp", "cmCode": "PR-DPP"}, // TCGdex: DP Black Star Promos | PTCG: DP Black Star Promos
      {"tcgdexId": "dp2", "ptcgId": "dp2", "cmCode": "MT"}, // TCGdex: Mysterious Treasures | PTCG: Mysterious Treasures
      {"tcgdexId": "pop6", "ptcgId": "pop6", "cmCode": ""}, // TCGdex: POP Series 6 | PTCG: POP Series 6
      {"tcgdexId": "dp3", "ptcgId": "dp3", "cmCode": "SW"}, // TCGdex: Secret Wonders | PTCG: Secret Wonders
      {"tcgdexId": "dp4", "ptcgId": "dp4", "cmCode": "GE"}, // TCGdex: Great Encounters | PTCG: Great Encounters
      {"tcgdexId": "pop7", "ptcgId": "pop7", "cmCode": ""}, // TCGdex: POP Series 7 | PTCG: POP Series 7
      {"tcgdexId": "dp5", "ptcgId": "dp5", "cmCode": "MD"}, // TCGdex: Majestic Dawn | PTCG: Majestic Dawn
      {"tcgdexId": "dp6", "ptcgId": "dp6", "cmCode": "LA"}, // TCGdex: Legends Awakened | PTCG: Legends Awakened
      {"tcgdexId": "pop8", "ptcgId": "pop8", "cmCode": ""}, // TCGdex: POP Series 8 | PTCG: POP Series 8
      {"tcgdexId": "dp7", "ptcgId": "dp7", "cmCode": "SF"}, // TCGdex: Stormfront | PTCG: Stormfront
      {"tcgdexId": "pl1", "ptcgId": "pl1", "cmCode": "PL"}, // TCGdex: Platinum | PTCG: Platinum
      {"tcgdexId": "pop9", "ptcgId": "pop9", "cmCode": ""}, // TCGdex: POP Series 9 | PTCG: POP Series 9
      {"tcgdexId": "pl2", "ptcgId": "pl2", "cmCode": "RR"}, // TCGdex: Rising Rivals | PTCG: Rising Rivals
      {"tcgdexId": "pl3", "ptcgId": "pl3", "cmCode": "SV"}, // TCGdex: Supreme Victors | PTCG: Supreme Victors
      {"tcgdexId": "pl4", "ptcgId": "pl4", "cmCode": "AR"}, // TCGdex: Arceus | PTCG: Arceus
      {"tcgdexId": "ru1", "ptcgId": "ru1", "cmCode": ""}, // TCGdex: Pokémon Rumble | PTCG: Pokémon Rumble
      {"tcgdexId": "hgss1", "ptcgId": "hgss1", "cmCode": "HS"}, // TCGdex: HeartGold SoulSilver | PTCG: HeartGold & SoulSilver
      {"tcgdexId": "hgssp", "ptcgId": "hsp", "cmCode": "PR-HS"}, // TCGdex: HGSS Black Star Promos | PTCG: HGSS Black Star Promos
      {"tcgdexId": "hgss2", "ptcgId": "hgss2", "cmCode": "UL"}, // TCGdex: Unleashed | PTCG: HS—Unleashed
      {"tcgdexId": "hgss3", "ptcgId": "hgss3", "cmCode": "UD"}, // TCGdex: Undaunted | PTCG: HS—Undaunted
      {"tcgdexId": "hgss4", "ptcgId": "hgss4", "cmCode": "TM"}, // TCGdex: Triumphant | PTCG: HS—Triumphant
      {"tcgdexId": "col1", "ptcgId": "col1", "cmCode": "CL"}, // TCGdex: Call of Legends | PTCG: Call of Legends
      {"tcgdexId": "bw1", "ptcgId": "bw1", "cmCode": "BLW"}, // TCGdex: Black & White | PTCG: Black & White
      {"tcgdexId": "bwp", "ptcgId": "bwp", "cmCode": "PR-BLW"}, // TCGdex: BW Black Star Promos | PTCG: BW Black Star Promos
      {"tcgdexId": "bw2", "ptcgId": "bw2", "cmCode": "EPO"}, // TCGdex: Emerging Powers | PTCG: Emerging Powers
      {"tcgdexId": "bw3", "ptcgId": "bw3", "cmCode": "NVI"}, // TCGdex: Noble Victories | PTCG: Noble Victories
      {"tcgdexId": "bw4", "ptcgId": "bw4", "cmCode": "NXD"}, // TCGdex: Next Destinies | PTCG: Next Destinies
      {"tcgdexId": "bw5", "ptcgId": "bw5", "cmCode": "DEX"}, // TCGdex: Dark Explorers | PTCG: Dark Explorers
      {"tcgdexId": "bw6", "ptcgId": "bw6", "cmCode": "DRX"}, // TCGdex: Dragons Exalted | PTCG: Dragons Exalted
      {"tcgdexId": "dv1", "ptcgId": "dv1", "cmCode": "DRV"}, // TCGdex: Dragon Vault | PTCG: Dragon Vault
      {"tcgdexId": "bw7", "ptcgId": "bw7", "cmCode": "BCR"}, // TCGdex: Boundaries Crossed | PTCG: Boundaries Crossed
      {"tcgdexId": "bw8", "ptcgId": "bw8", "cmCode": "PLS"}, // TCGdex: Plasma Storm | PTCG: Plasma Storm
      {"tcgdexId": "bw9", "ptcgId": "bw9", "cmCode": "PLF"}, // TCGdex: Plasma Freeze | PTCG: Plasma Freeze
      {"tcgdexId": "bw10", "ptcgId": "bw10", "cmCode": "PLB"}, // TCGdex: Plasma Blast | PTCG: Plasma Blast
      {"tcgdexId": "xyp", "ptcgId": "xyp", "cmCode": "PR-XY"}, // TCGdex: XY Black Star Promos | PTCG: XY Black Star Promos
      {"tcgdexId": "bw11", "ptcgId": "bw11", "cmCode": "LTR"}, // TCGdex: Legendary Treasures | PTCG: Legendary Treasures
      {"tcgdexId": "xy0", "ptcgId": "xy0", "cmCode": "KSS"}, // TCGdex: Kalos Starter Set | PTCG: Kalos Starter Set
      {"tcgdexId": "xy1", "ptcgId": "xy1", "cmCode": "XY"}, // TCGdex: XY | PTCG: XY
      {"tcgdexId": "xy2", "ptcgId": "xy2", "cmCode": "FLF"}, // TCGdex: Flashfire | PTCG: Flashfire
      {"tcgdexId": "xy3", "ptcgId": "xy3", "cmCode": "FFI"}, // TCGdex: Furious Fists | PTCG: Furious Fists
      {"tcgdexId": "xy4", "ptcgId": "xy4", "cmCode": "PHF"}, // TCGdex: Phantom Forces | PTCG: Phantom Forces
      {"tcgdexId": "xy5", "ptcgId": "xy5", "cmCode": "PRC"}, // TCGdex: Primal Clash | PTCG: Primal Clash
      {"tcgdexId": "dc1", "ptcgId": "dc1", "cmCode": "DCR"}, // TCGdex: Double Crisis | PTCG: Double Crisis
      {"tcgdexId": "xy6", "ptcgId": "xy6", "cmCode": "ROS"}, // TCGdex: Roaring Skies | PTCG: Roaring Skies
      {"tcgdexId": "xy7", "ptcgId": "xy7", "cmCode": "AOR"}, // TCGdex: Ancient Origins | PTCG: Ancient Origins
      {"tcgdexId": "xy8", "ptcgId": "xy8", "cmCode": "BKT"}, // TCGdex: BREAKthrough | PTCG: BREAKthrough
      {"tcgdexId": "xy9", "ptcgId": "xy9", "cmCode": "BKP"}, // TCGdex: BREAKpoint | PTCG: BREAKpoint
      {"tcgdexId": "g1", "ptcgId": "g1", "cmCode": "GEN"}, // TCGdex: Generations | PTCG: Generations
      {"tcgdexId": "xy10", "ptcgId": "xy10", "cmCode": "FCO"}, // TCGdex: Fates Collide | PTCG: Fates Collide
      {"tcgdexId": "xy11", "ptcgId": "xy11", "cmCode": "STS"}, // TCGdex: Steam Siege | PTCG: Steam Siege
      {"tcgdexId": "xy12", "ptcgId": "xy12", "cmCode": "EVO"}, // TCGdex: Evolutions | PTCG: Evolutions
      {"tcgdexId": "sm1", "ptcgId": "sm1", "cmCode": "SUM"}, // TCGdex: Sun & Moon | PTCG: Sun & Moon
      {"tcgdexId": "smp", "ptcgId": "smp", "cmCode": "PR-SM"}, // TCGdex: SM Black Star Promos | PTCG: SM Black Star Promos
      {"tcgdexId": "sm2", "ptcgId": "sm2", "cmCode": "GRI"}, // TCGdex: Guardians Rising | PTCG: Guardians Rising
      {"tcgdexId": "sm3", "ptcgId": "sm3", "cmCode": "BUS"}, // TCGdex: Burning Shadows | PTCG: Burning Shadows
      {"tcgdexId": "sm3.5", "ptcgId": "sm35", "cmCode": "SLG"}, // TCGdex: Shining Legends | PTCG: Shining Legends
      {"tcgdexId": "sm4", "ptcgId": "sm4", "cmCode": "CIN"}, // TCGdex: Crimson Invasion | PTCG: Crimson Invasion
      {"tcgdexId": "sm5", "ptcgId": "sm5", "cmCode": "UPR"}, // TCGdex: Ultra Prism | PTCG: Ultra Prism
      {"tcgdexId": "sm6", "ptcgId": "sm6", "cmCode": "FLI"}, // TCGdex: Forbidden Light | PTCG: Forbidden Light
      {"tcgdexId": "sm7", "ptcgId": "sm7", "cmCode": "CES"}, // TCGdex: Celestial Storm | PTCG: Celestial Storm
      {"tcgdexId": "sm7.5", "ptcgId": "sm75", "cmCode": "DRM"}, // TCGdex: Dragon Majesty | PTCG: Dragon Majesty
      {"tcgdexId": "sm8", "ptcgId": "sm8", "cmCode": "LOT"}, // TCGdex: Lost Thunder | PTCG: Lost Thunder
      {"tcgdexId": "sm9", "ptcgId": "sm9", "cmCode": "TEU"}, // TCGdex: Team Up | PTCG: Team Up
      {"tcgdexId": "det1", "ptcgId": "det1", "cmCode": "DET"}, // TCGdex: Detective Pikachu | PTCG: Detective Pikachu
      {"tcgdexId": "sm10", "ptcgId": "sm10", "cmCode": "UNB"}, // TCGdex: Unbroken Bonds | PTCG: Unbroken Bonds
      {"tcgdexId": "sm11", "ptcgId": "sm11", "cmCode": "UNM"}, // TCGdex: Unified Minds | PTCG: Unified Minds
      {"tcgdexId": "sm115", "ptcgId": "sm115", "cmCode": "HIF"}, // TCGdex: Hidden Fates | PTCG: Hidden Fates
      {"tcgdexId": "sma", "ptcgId": "sma", "cmCode": "HIF"}, // TCGdex: Yellow A Alternate | PTCG: Hidden Fates Shiny Vault
      {"tcgdexId": "sm12", "ptcgId": "sm12", "cmCode": "CEC"}, // TCGdex: Cosmic Eclipse | PTCG: Cosmic Eclipse
      {"tcgdexId": "swshp", "ptcgId": "swshp", "cmCode": "PR-SW"}, // TCGdex: SWSH Black Star Promos | PTCG: SWSH Black Star Promos
      {"tcgdexId": "swsh1", "ptcgId": "swsh1", "cmCode": "SSH"}, // TCGdex: Sword & Shield | PTCG: Sword & Shield
      {"tcgdexId": "swsh2", "ptcgId": "swsh2", "cmCode": "RCL"}, // TCGdex: Rebel Clash | PTCG: Rebel Clash
      {"tcgdexId": "swsh3", "ptcgId": "swsh3", "cmCode": "DAA"}, // TCGdex: Darkness Ablaze | PTCG: Darkness Ablaze
      {"tcgdexId": "swsh3.5", "ptcgId": "swsh35", "cmCode": "CPA"}, // TCGdex: Champion's Path | PTCG: Champion's Path
      {"tcgdexId": "swsh4", "ptcgId": "swsh4", "cmCode": "VIV"}, // TCGdex: Vivid Voltage | PTCG: Vivid Voltage
      {"tcgdexId": "swsh4.5", "ptcgId": "swsh45", "cmCode": "SHF"}, // TCGdex: Shining Fates | PTCG: Shining Fates
      {"tcgdexId": "swsh5", "ptcgId": "swsh5", "cmCode": "BST"}, // TCGdex: Battle Styles | PTCG: Battle Styles
      {"tcgdexId": "swsh6", "ptcgId": "swsh6", "cmCode": "CRE"}, // TCGdex: Chilling Reign | PTCG: Chilling Reign
      {"tcgdexId": "swsh7", "ptcgId": "swsh7", "cmCode": "EVS"}, // TCGdex: Evolving Skies | PTCG: Evolving Skies
      {"tcgdexId": "cel25", "ptcgId": "cel25", "cmCode": "CEL"}, // TCGdex: Celebrations | PTCG: Celebrations
      {"tcgdexId": "swsh8", "ptcgId": "swsh8", "cmCode": "FST"}, // TCGdex: Fusion Strike | PTCG: Fusion Strike
      {"tcgdexId": "swsh9", "ptcgId": "swsh9", "cmCode": "BRS"}, // TCGdex: Brilliant Stars | PTCG: Brilliant Stars
      {"tcgdexId": "swsh10", "ptcgId": "swsh10", "cmCode": "ASR"}, // TCGdex: Astral Radiance | PTCG: Astral Radiance
      {"tcgdexId": "swsh10.5", "ptcgId": "pgo", "cmCode": "PGO"}, // TCGdex: Pokémon GO | PTCG: Pokémon GO
      {"tcgdexId": "swsh11", "ptcgId": "swsh11", "cmCode": "LOR"}, // TCGdex: Lost Origin | PTCG: Lost Origin
      {"tcgdexId": "swsh12", "ptcgId": "swsh12", "cmCode": "SIT"}, // TCGdex: Silver Tempest | PTCG: Silver Tempest
      {"tcgdexId": "swsh12.5", "ptcgId": "swsh12pt5", "cmCode": "CRZ"}, // TCGdex: Crown Zenith | PTCG: Crown Zenith
      {"tcgdexId": "svp", "ptcgId": "svp", "cmCode": "PR-SV"}, // TCGdex: SVP Black Star Promos | PTCG: Scarlet & Violet Black Star Promos
      {"tcgdexId": "sv01", "ptcgId": "sv1", "cmCode": "SVI"}, // TCGdex: Scarlet & Violet | PTCG: Scarlet & Violet
      {"tcgdexId": "sv02", "ptcgId": "sv2", "cmCode": "PAL"}, // TCGdex: Paldea Evolved | PTCG: Paldea Evolved
      {"tcgdexId": "sv03", "ptcgId": "sv3", "cmCode": "OBF"}, // TCGdex: Obsidian Flames | PTCG: Obsidian Flames
      {"tcgdexId": "sv03.5", "ptcgId": "sv3pt5", "cmCode": "MEW"}, // TCGdex: 151 | PTCG: 151
      {"tcgdexId": "sv04", "ptcgId": "sv4", "cmCode": "PAR"}, // TCGdex: Paradox Rift | PTCG: Paradox Rift
      {"tcgdexId": "sv04.5", "ptcgId": "sv4pt5", "cmCode": "PAF"}, // TCGdex: Paldean Fates | PTCG: Paldean Fates
      {"tcgdexId": "sv05", "ptcgId": "sv5", "cmCode": "TEF"}, // TCGdex: Temporal Forces | PTCG: Temporal Forces
      {"tcgdexId": "sv06", "ptcgId": "sv6", "cmCode": "TWM"}, // TCGdex: Twilight Masquerade | PTCG: Twilight Masquerade
      {"tcgdexId": "sv06.5", "ptcgId": "sv6pt5", "cmCode": "SFA"}, // TCGdex: Shrouded Fable | PTCG: Shrouded Fable
      {"tcgdexId": "sv07", "ptcgId": "sv7", "cmCode": "SCR"}, // TCGdex: Stellar Crown | PTCG: Stellar Crown
      {"tcgdexId": "sv08", "ptcgId": "sv8", "cmCode": "SSP"}, // TCGdex: Surging Sparks | PTCG: Surging Sparks
      {"tcgdexId": "sv08.5", "ptcgId": "sv8pt5", "cmCode": "PRE"}, // TCGdex: Prismatic Evolutions | PTCG: Prismatic Evolutions
      {"tcgdexId": "sv09", "ptcgId": "sv9", "cmCode": "JTG"}, // TCGdex: Journey Together | PTCG: Journey Together
      {"tcgdexId": "sv10", "ptcgId": "sv10", "cmCode": "DRI"}, // TCGdex: Destined Rivals | PTCG: Destined Rivals
      {"tcgdexId": "sv10.5b", "ptcgId": "zsv10pt5", "cmCode": "BLK"}, // TCGdex: Black Bolt | PTCG: Black Bolt
      {"tcgdexId": "sv10.5w", "ptcgId": "rsv10pt5", "cmCode": "WHT"}, // TCGdex: White Flare | PTCG: White Flare
      {"tcgdexId": "me01", "ptcgId": "me1", "cmCode": "MEG"}, // TCGdex: Mega Evolution | PTCG: Mega Evolution
      {"tcgdexId": "me02", "ptcgId": "me2", "cmCode": "PFL"}, // TCGdex: Phantasmal Flames | PTCG: Phantasmal Flames
      {"tcgdexId": "me02.5", "ptcgId": "me2pt5", "cmCode": "ASC"}, // TCGdex: Ascended Heroes | PTCG: Ascended Heroes

      // --- MANUELLE MATCHES ---
      {"tcgdexId": "2011bw", "ptcgId": "mcd11", "cmCode": ""}, // TCGdex: Macdonald's Collection 2011 | PTCG: McDonald's Collection 2011
      {"tcgdexId": "2012bw", "ptcgId": "mcd12", "cmCode": ""}, // TCGdex: Macdonald's Collection 2012 | PTCG: McDonald's Collection 2012
      {"tcgdexId": "2014xy", "ptcgId": "mcd14", "cmCode": ""}, // TCGdex: Macdonald's Collection 2014 | PTCG: McDonald's Collection 2014
      {"tcgdexId": "2015xy", "ptcgId": "mcd15", "cmCode": ""}, // TCGdex: Macdonald's Collection 2015 | PTCG: McDonald's Collection 2015
      {"tcgdexId": "2016xy", "ptcgId": "mcd16", "cmCode": ""}, // TCGdex: Macdonald's Collection 2016 | PTCG: McDonald's Collection 2016
      {"tcgdexId": "2017sm", "ptcgId": "mcd17", "cmCode": ""}, // TCGdex: Macdonald's Collection 2017 | PTCG: McDonald's Collection 2017
      {"tcgdexId": "2018sm", "ptcgId": "mcd18", "cmCode": ""}, // TCGdex: Macdonald's Collection 2018 | PTCG: McDonald's Collection 2018
      {"tcgdexId": "2019sm", "ptcgId": "mcd19", "cmCode": ""}, // TCGdex: Macdonald's Collection 2019 | PTCG: McDonald's Collection 2019
      {"tcgdexId": "2021swsh", "ptcgId": "mcd21", "cmCode": ""}, // TCGdex: Macdonald's Collection 2021 | PTCG: McDonald's Collection 2021
      {"tcgdexId": "fut2020", "ptcgId": "fut20", "cmCode": "FUT20"}, // TCGdex: Pokémon Futsal 2020 | PTCG: Pokémon Futsal Collection
      {"tcgdexId": "tk-ex-latia", "ptcgId": "tk1a", "cmCode": ""}, // TCGdex: EX trainer Kit (Latias) | PTCG: EX Trainer Kit Latias
      {"tcgdexId": "tk-ex-latio", "ptcgId": "tk1b", "cmCode": ""}, // TCGdex: EX trainer Kit (Latios) | PTCG: EX Trainer Kit Latios
      {"tcgdexId": "tk-ex-p", "ptcgId": "tk2a", "cmCode": ""}, // TCGdex: EX trainer Kit 2 (Plusle) | PTCG: EX Trainer Kit 2 Plusle
      {"tcgdexId": "tk-ex-m", "ptcgId": "tk2b", "cmCode": ""}, // TCGdex: EX trainer Kit 2 (Minun) | PTCG: EX Trainer Kit 2 Minun

      // --- NUR BEI TCGDEX ---
      {"tcgdexId": "wp", "ptcgId": null, "cmCode": null}, // W Promotional
      {"tcgdexId": "ex5.5", "ptcgId": null, "cmCode": null}, // Poké Card Creator Pack
      {"tcgdexId": "exu", "ptcgId": null, "cmCode": null}, // Unseen Forces Unown Collection
      {"tcgdexId": "tk-dp-l", "ptcgId": null, "cmCode": null}, // DP trainer Kit (Lucario)
      {"tcgdexId": "tk-dp-m", "ptcgId": null, "cmCode": null}, // DP trainer Kit (Manaphy)
      {"tcgdexId": "tk-hs-g", "ptcgId": null, "cmCode": null}, // HS trainer Kit (Gyarados)
      {"tcgdexId": "tk-hs-r", "ptcgId": null, "cmCode": null}, // HS trainer Kit (Raichu)
      {"tcgdexId": "tk-bw-z", "ptcgId": null, "cmCode": null}, // BW trainer Kit (Zoroark)
      {"tcgdexId": "tk-bw-e", "ptcgId": null, "cmCode": null}, // BW trainer Kit (Excadrill)
      {"tcgdexId": "rc", "ptcgId": null, "cmCode": null}, // Radiant Collection
      {"tcgdexId": "tk-xy-sy", "ptcgId": null, "cmCode": null}, // XY trainer Kit (Sylveon)
      {"tcgdexId": "tk-xy-n", "ptcgId": null, "cmCode": null}, // XY trainer Kit (Noivern)
      {"tcgdexId": "tk-xy-b", "ptcgId": null, "cmCode": null}, // XY trainer Kit (Bisharp)
      {"tcgdexId": "tk-xy-w", "ptcgId": null, "cmCode": null}, // XY trainer Kit (Wigglytuff)
      {"tcgdexId": "tk-xy-latia", "ptcgId": null, "cmCode": null}, // XY trainer Kit (Latias)
      {"tcgdexId": "tk-xy-latio", "ptcgId": null, "cmCode": null}, // XY trainer Kit (Latios)
      {"tcgdexId": "tk-xy-p", "ptcgId": null, "cmCode": null}, // XY trainer Kit (Pikachu Libre)
      {"tcgdexId": "tk-xy-su", "ptcgId": null, "cmCode": null}, // XY trainer Kit (Suicune)
      {"tcgdexId": "tk-sm-l", "ptcgId": null, "cmCode": null}, // SM trainer Kit (Lycanroc)
      {"tcgdexId": "tk-sm-r", "ptcgId": null, "cmCode": null}, // SM trainer Kit (Alolan Raichu)
      {"tcgdexId": "mep", "ptcgId": null, "cmCode": null}, // MEP Black Star Promos

      // --- NUR BEI PTCG ---
      {"tcgdexId": "swsh45sv", "ptcgId": "swsh45sv", "cmCode": "SHF"}, // NUR BEI PTCG: Shining Fates Shiny Vault
      {"tcgdexId": "cel25c", "ptcgId": "cel25c", "cmCode": "CEL"}, // NUR BEI PTCG: Celebrations: Classic Collection
      {"tcgdexId": "swsh9tg", "ptcgId": "swsh9tg", "cmCode": "BRS"}, // NUR BEI PTCG: Brilliant Stars Trainer Gallery
      {"tcgdexId": "swsh10tg", "ptcgId": "swsh10tg", "cmCode": "ASR"}, // NUR BEI PTCG: Astral Radiance Trainer Gallery
      {"tcgdexId": "swsh11tg", "ptcgId": "swsh11tg", "cmCode": "LOR"}, // NUR BEI PTCG: Lost Origin Trainer Gallery
      {"tcgdexId": "swsh12tg", "ptcgId": "swsh12tg", "cmCode": "SIT"}, // NUR BEI PTCG: Silver Tempest Trainer Gallery
      {"tcgdexId": "mcd22", "ptcgId": "mcd22", "cmCode": ""}, // NUR BEI PTCG: McDonald's Collection 2022
      {"tcgdexId": "swsh12pt5gg", "ptcgId": "swsh12pt5gg", "cmCode": "CRZ"}, // NUR BEI PTCG: Crown Zenith Galarian Gallery
      {"tcgdexId": "sve", "ptcgId": "sve", "cmCode": "SVE"}, // NUR BEI PTCG: Scarlet & Violet Energies
      {"tcgdexId": "me03", "ptcgId": "me3", "cmCode": "POR"}, // NUR BEI PTCG: Perfect Order
    ];

    // --- NEU: insertAllOnConflictUpdate anstelle von insertAll ---
    // Dadurch werden die Einträge bei jedem App-Start überprüft 
    // und (falls du die Liste änderst) sofort aktualisiert!
    await db.batch((batch) {
      batch.insertAllOnConflictUpdate(
        db.setMappings,
        initialMappings.map((m) => SetMappingsCompanion.insert(
          tcgdexId: m['tcgdexId'] as String,
          ptcgId: m['ptcgId'] != null ? Value(m['ptcgId'] as String) : const Value.absent(),
          cardmarketCode: m['cmCode'] != null ? Value(m['cmCode'] as String) : const Value.absent(),
        )).toList(),
      );
    });

    print('✅ Set-Mappings erfolgreich synchronisiert!');
  }
}