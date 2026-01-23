# TheCardCollector

![Status](https://img.shields.io/badge/Status-In%20Development-orange?style=flat-square)
![Tech](https://img.shields.io/badge/Made%20with-Flutter-02569B?style=flat-square&logo=flutter&logoColor=white)
![DB](https://img.shields.io/badge/Database-Isar-purple?style=flat-square)
![API](https://img.shields.io/badge/Data-TCGdex%20API-green?style=flat-square)

**TheCardCollector** ist eine intelligente Mobile App für Sammelkartenspiele (Fokus: Pokémon TCG), die physische Sammelordner digital spiegelt. Anders als herkömmliche Collection-Tracker berechnet diese App automatisch die exakte Position jeder Karte im Binder basierend auf benutzerdefinierten Layouts.

---

## 🌟 Hauptfunktionen

### 🔍 Multi-Language Search & Mapping
* **Sprachunabhängige Suche:** Suche nach "Glurak" (DE) oder "Charizard" (EN) – das System verknüpft lokale Namen automatisch mit der globalen Karten-ID.
* **Metadaten:** Anzeige aller relevanten Artworks, Sets und Kartennummern.

### 📓 Smart Binder System (Kern-Feature)
* **Flexible Layouts:** Erstelle Binder mit benutzerdefinierten Rastern (z.B. 3x3 für Standardseiten, 4x3 für Playsets).
* **Kategorien:** Unterstützt Sortierungen nach National Dex (1-1025), Mastersets (Set-Nummerierung), Mega-Dex oder individuellen Kriterien.
* **Auto-Calculation:** Gib einfach das Pokémon an, und die App sagt dir: *"Seite 4, Zeile 2, Spalte 1"*.

### 📦 Inventar & Besitz
* **Detailliertes Tracking:** Erfasse Anzahl, Sprache, Zustand (Mint, NM, Played) und Besonderheiten (Reverse Holo, First Edition).
* **Custom Visuals:** Wähle zwischen dem offiziellen API-Bild oder lade ein eigenes Foto deiner Karte hoch.
* **Fortschritt:** Automatische Berechnung des Sammelfortschritts (in % und fehlenden Karten).

### 📈 Marktwerte (Geplant)
* Integration von Preis-APIs (z.B. Cardmarket), um den Gesamtwert des Binders basierend auf dem Kartenzustand zu ermitteln.

---

## 🛠️ Tech Stack

* **Frontend:** [Flutter](https://flutter.dev/) (Dart) – für native Performance auf Android & iOS.
* **Datenbank:** [Isar Database](https://isar.dev/) – NoSQL, extrem schnell, perfekt für komplexe Filter und Offline-Suche.
* **State Management:** Riverpod (geplant).
* **API:** [TCGdex API](https://www.tcgdex.net/) (Open Source, Multi-Language Support).

---

## 📐 Die Binder-Logik (Algorithmus)

Das Alleinstellungsmerkmal der App ist die mathematische Berechnung der Kartenposition. Anstatt Karten manuell zu schieben, berechnet die App den Slot basierend auf dem Index.

**Parameter:**
* $I$ = Index der Karte (z.B. Pokedex Nr. - 1)
* $R$ = Zeilen pro Seite (Rows)
* $C$ = Spalten pro Seite (Cols)
* $K$ = Karten pro Seite ($R \times C$)

**Berechnung:**
1.  **Seite:** $S = \lfloor \frac{I}{K} \rfloor + 1$
2.  **Position auf Seite (0-basiert):** $P = I \pmod K$
3.  **Zeile:** $Z = \lfloor \frac{P}{C} \rfloor + 1$
4.  **Spalte:** $Sp = (P \pmod C) + 1$

---

## 🗄️ Datenmodell (Architektur)

Das System trennt strikt zwischen den **Stammdaten** der Karte, dem **physischen Besitz** (Inventory) und der **Anzeige** (Binder).

```mermaid
erDiagram
    CARD_MASTER ||--o{ INVENTORY : "besitzt"
    BINDER ||--o{ BINDER_CONFIG : "hat Settings"
    BINDER ||--o{ VIEW_SLOT : "zeigt an"
    INVENTORY ||--o{ VIEW_SLOT : "befüllt"

    CARD_MASTER {
        string api_id "Unique ID"
        string name_de
        string name_en
        int pokedex_num
        string set_id
    }
    INVENTORY {
        int id PK
        string condition "NM, EX, etc"
        int quantity
        bool is_holo
        string image_path "Local Path"
    }
    BINDER {
        int id PK
        string name
        enum type "Pokedex, Set, Custom"
    }
    BINDER_CONFIG {
        int rows "z.B. 3"
        int cols "z.B. 3"
    }
