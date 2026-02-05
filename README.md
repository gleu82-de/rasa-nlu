# Rasa NLU - Intent Recognition Service

> Natural Language Understanding für Sprachsteuerung - 129 Geräte, deutsche Sprache

## Features

- 🎯 **Intent Recognition** - Erkennt Geräte-Steuerungsbefehle aus natürlicher Sprache
- 🇩🇪 **Optimiert für Deutsch** - Deutsche Sprachmodelle und Training
- 🏠 **129 Smart Home Geräte** - Automatisch generierte Trainingsdaten
- 🔄 **Auto-Deployment** - GitHub Actions für PROD Release
- 📊 **Testing** - Umfassende Tests für Intent-Erkennung

## Architektur

```
Voice → STT (Parakeet) → Rasa NLU → MQTT (rasa/intent) → Voice Assistant
```

## Installation

### 1. Python venv erstellen

```bash
cd /home/dgl/Projekte/rasa-nlu
python3 -m venv venv
source venv/bin/activate
```

### 2. Rasa installieren

```bash
pip install --upgrade pip
pip install rasa
```

### 3. Training durchführen

```bash
rasa train nlu
```

### 4. Modell testen

```bash
rasa shell nlu
# Eingabe: "Schalte das Licht im Wohnzimmer an"
```

## Verzeichnisstruktur

```
rasa-nlu/
├── data/
│   └── nlu.yml              # Training-Daten (129 Geräte)
├── config/
│   ├── config.yml           # Rasa Pipeline Config
│   ├── domain.yml           # Intent/Entity Definitionen
│   └── endpoints.yml        # API Endpoints
├── models/                  # Trainierte Modelle (.tar.gz)
├── scripts/
│   └── update-nlu.sh        # Update nlu.yml von Red/rasa-training
├── tests/
│   └── test-intents.yml     # Test-Fälle
└── docs/
    └── TRAINING.md          # Training-Dokumentation
```

## Training-Daten

Die `nlu.yml` wird automatisch aus der MariaDB `Sprachsteuerung_Dev` generiert:

```bash
# In Red-Projekt:
cd /home/dgl/Projekte/Red/rasa-training
node test-export.js
```

Dann nach `rasa-nlu/data/` kopieren.

## Deployment

### Manuelles Deployment

```bash
# Auf PROD:
cd ~/rasa-nlu
source venv/bin/activate
rasa train nlu
```

### Auto-Deployment (geplant)

GitHub Actions deployt automatisch nach Git-Push.

## Development

### Test-Intent erkennen

```bash
source venv/bin/activate
echo '{"text": "Licht im Wohnzimmer an"}' | rasa run --enable-api --debug
```

### Modell evaluieren

```bash
rasa test nlu --nlu data/nlu.yml
```

## Konfiguration

- **Pipeline**: `LanguageModelFeaturizer` + `DIETClassifier` für deutsche Texte
- **Intents**: `device_control`
- **Entities**: `device`, `action`, `level`, `duration`, `delay`

## License

MIT
