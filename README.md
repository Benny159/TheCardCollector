# 🎴 Pokémon TCG Collector & Scanner

![Status](https://img.shields.io/badge/Status-In%20Development-orange) ![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Windows-blue) ![Framework](https://img.shields.io/badge/Built%20with-Flutter-02569B)

Eine moderne **Cross-Platform App (Android & PC)** zur Verwaltung von Pokémon-Kartensammlungen.
Der Fokus liegt auf **Master-Sets**, **deutscher Lokalisierung**, realistischer **Binder-Visualisierung** und einer intelligenten **Scanner-Technologie**.

## 🚀 Vision & Alleinstellungsmerkmale

Die meisten TCG-Apps sind rein englischsprachig oder ignorieren die Struktur physischer Sammelordner. Diese App schließt die Lücke:

* **Intelligentes Sprach-Mapping:** Verknüpft englische API-Daten automatisch mit deutschen Kartennamen (z.B. *Charizard* ↔ *Glurak*), um korrekte Links für **Cardmarket** zu generieren.
* **Der "Einsortier-Assistent" (Locator):** Berechnet mathematisch exakt, auf welcher Seite, Zeile und Spalte eine Karte in deinem physischen Binder einsortiert werden muss.
* **Visuelles Sammeln:** Digitale Binder, die sich wie echte Ordner anfühlen (Ghost-Cards für fehlende Karten).

---

## ✨ Features

### 📂 Binder-Management
* **Individuelle Layouts:** Konfigurierbare Raster (z.B. 3x3 für 9-Pocket-Pages, 2x2, etc.).
* **Templates:** Automatische Befüllung für "Master Sets" (inkl. Reverse Holo Slots), Sets, Künstler oder Pokédex-Bereiche.
* **Visualisierung:**
    * **Ghost Cards:** Transparente Platzhalter für fehlende Karten.
    * **Owned Cards:** Farbige Darstellung (Wahlweise API-Bild oder eigener Scan).

### 📷 Smart Scanner
* **Hybrid-Erkennung:**
    * **OCR:** Scannt Name, Nummer (z.B. "37/151") und Set-Kürzel.
    * **Computer Vision:** Automatische Kantenerkennung und Entzerrung (Perspective Warp) der Karte.
* **Bulk-Mode (Geplant):** Schnelles Einscannen mehrerer Karten hintereinander für spätere Sortierung.

### 📦 Inventar & Finanzen
* **Zustands-Tracking:** Grading (PSA, BGS), Condition (Near Mint, Played) und Sprache.
* **Preisentwicklung:**
    * Abruf aktueller Marktpreise (via API/TCGPlayer).
    * Manuelle Preiseingabe möglich.
    * **Verlaufs-Diagramm:** Historische Wertentwicklung der Sammlung.
* **Cardmarket-Integration:** Generiert Direktlinks zur spezifischen Karte in der korrekten Sprache.

---

## 🛠 Tech Stack

Das Projekt setzt auf eine **Single-Codebase** für Mobile und Desktop.

| Bereich | Technologie | Beschreibung |
| :--- | :--- | :--- |
| **Framework** | **Flutter** (Dart) | UI & Logik für Android & Windows. |
| **Datenbank** | **Drift** (SQLite) | Relationale lokale Datenbank für komplexe Binder-Strukturen. |
| **State Management** | **Riverpod** | Reaktives Zustandsmanagement. |
| **Computer Vision** | **OpenCV** | Bildverarbeitung (Crop & Warp). |
| **OCR** | **Google ML Kit** | Texterkennung (On-Device). |
| **API** | **pokemontcg.io** | Datenquelle für Metadaten & Bilder. |
| **Charts** | **fl_chart** | Visualisierung der Preisverläufe. |

---

## 💾 Datenbank-Architektur

Wir nutzen ein relationales Modell, um "Referenzdaten" (API) von "Nutzerdaten" (Besitz) zu trennen:

* **Reference Layer:** Cache für Kartendaten (Sets, Bilder, Nummern) + `Localization Table` (Mapping EN/DE).
* **User Layer:** Speichert die konkrete Instanz einer Karte (Zustand, Kaufpreis, Pfad zum Scan).
* **Binder Logic:** Verknüpfungstabelle, die berechnet, welche Karte in welchem Slot liegt.

---

## ⚡ Getting Started

### API
* Pokemoncards & Price ?: https://pokemontcg.io/
* Multilanguage: https://tcgdex.dev

### Voraussetzungen
* Flutter SDK (neueste Stable Version)
* Dart SDK
* Android Studio / VS Code

### Installation

1.  **Repository klonen:**
    ```bash
    git clone [https://github.com/DEIN-USERNAME/DEIN-REPO-NAME.git](https://github.com/DEIN-USERNAME/DEIN-REPO-NAME.git)
    cd DEIN-REPO-NAME
    ```

2.  **Abhängigkeiten laden:**
    ```bash
    flutter pub get
    ```

3.  **Code Generierung (für Drift/Riverpod):**
    ```bash
    dart run build_runner build --delete-conflicting-outputs
    ```

4.  **App starten:**
    ```bash
    # Für Windows
    flutter run -d windows

    # Für Android (Emulator oder Gerät muss laufen)
    flutter run -d android
    ```

---

## 🗺 Roadmap

- [ ] **Phase 1: MVP**
    - [ ] Datenbank-Setup (Drift) & API Client.
    - [ ] Grundlegendes Binder-UI (Grid).
    - [ ] Manuelles Hinzufügen von Karten.
- [ ] **Phase 2: Scanner & Logic**
    - [ ] OpenCV Integration für Kamera.
    - [ ] OCR Implementierung für "Nummer/Set" Erkennung.
    - [ ] "Locator" Algorithmus (Einsortier-Hilfe).
- [ ] **Phase 3: Finanzen & Polish**
    - [ ] Preis-Charts.
    - [ ] Cardmarket Link Generator.
    - [ ] Backup/Export Funktion.

---

## 🤝 Contributing

Beiträge sind willkommen! Besonders im Bereich **Sprach-Mapping** (Erweiterung der deutschen Kartennamen-Datenbank) suchen wir Unterstützung.

1.  Fork das Projekt
2.  Erstelle deinen Feature Branch (`git checkout -b feature/AmazingFeature`)
3.  Commit deine Änderungen (`git commit -m 'Add some AmazingFeature'`)
4.  Push zum Branch (`git push origin feature/AmazingFeature`)
5.  Öffne einen Pull Request

---

## 📄 Lizenz

Distributed under the MIT License. See `LICENSE` for more information.

***

**Disclaimer:** This project is not affiliated with, endorsed, sponsored, or specifically approved by Nintendo, The Pokémon Company, or Game Freak. Pokémon and Pokémon character names are trademarks of Nintendo.
