# Rasa NLU für Voice Assistant

**Status:** ✅ Production Ready  
**Version:** Rasa 3.6.21 | Python 3.10.19  
**Letzte Aktualisierung:** 05. Februar 2026

Intent Recognition und Entity Extraction für deutschsprachige Voice Commands.

## 🚀 Quick Start

### 1. Python venv erstellen

```bash
cd /home/dgl/Projekte/rasa-nlu
python3 -m venv venv
source venv/bin/activate
```

### 2. Rasa installieren

```bash
# Aktiviere venv
source venv/bin/activate

# Training (bei Datenänderungen)
rasa train nlu --nlu data/nlu.yml --config config.yml --out models

# Test im Terminal
rasa shell nlu

# HTTP Server starten (Port 5005)
rasa run --enable-api --model models/<model-name>.tar.gz
```

## 📊 Projekt-Übersicht

- **Intent:** `device_control`
- **Entities:** `device`, `action`, `level`
- **Trainings-Daten:** 946 Beispiele, 129 Geräte
- **Pipeline:** DIETClassifier (CPU-optimiert)
- **Quelle:** MariaDB VoiceTargets (exportiert via Red/Devices)

## 🔌 Schnittstelle

**Input:**
```json
{"text": "schalte das Licht ein"}
```

**Output:**
```json
{
  "intent": {"name": "device_control", "confidence": 0.95},
  "entities": [
    {"entity": "device", "value": "Licht"},
    {"entity": "action", "value": "ein"}
  ]
}
```

## 📁 Struktur

```
rasa-nlu/
├── data/nlu.yml         # Training Data
├── config.yml           # NLU Pipeline
├── domain.yml           # Intent/Entity Definitionen
├── models/              # Trainierte Modelle
└── docs/MIGRATION.md    # Exit-Strategie & Dokumentation
```

## 🔧 Wartung

**Daten aktualisieren:**
```bash
# In Red/Node-Red: Devices → exportRasaNLU() ausführen
# Dann:
cp ../Red/rasa-training/nlu.yml data/nlu.yml
rasa train nlu
```

**Python 3.10 Status:**
- Installiert: `/usr/bin/python3.10`
- venv: `/home/dgl/Projekte/rasa-nlu/venv/`
- EOL: Oktober 2031

## 📖 Dokumentation

- **Vollständige Installation & Migration:** [docs/MIGRATION.md](docs/MIGRATION.md)
- **Exit-Strategie (2027-2030):** Siehe MIGRATION.md Kapitel "Exit-Strategie"
- **Alternative Frameworks:** SetFit, spaCy, Hugging Face Transformers
- **Deployment:** [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md)

## ⚠️ Wichtige Hinweise

- **Rasa Status:** Maintenance Mode (keine neuen Features)
- **Support bis:** ~2030 (Python 3.10 EOL)
- **Migration empfohlen:** 2027-2028 → SetFit + spaCy
- **Schnittstelle:** Dokumentiert für nahtlose Migration

## 🔗 Integration

**Voice Assistant Flow:**
```
STT (NeMo) → [Text] → Rasa NLU → [Intent+Entities] → MQTT → Voice Assistant → Device Control
```

**MQTT Topics (geplant):**
- Input: `voice/text`
- Output: `voice/intent`

---

**Entwicklung:** GitHub Copilot  
**Wartung:** DGL  
**Lizenz:** Privates Projekt
- **Intents**: `device_control`
- **Entities**: `device`, `action`, `level`, `duration`, `delay`

## License

MIT
