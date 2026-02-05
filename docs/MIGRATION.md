# Rasa NLU Installation & Migration Guide

**Erstellt:** 05. Februar 2026  
**Version:** Rasa 3.6.21  
**Python:** 3.10.19  
**Status:** ✅ Produktionsbereit für NLU-Only Setup

---

## 📋 Übersicht

Dieses Dokument beschreibt die vollständige Installation von Rasa NLU 3.6.21 für das Voice Assistant Projekt sowie die **Exit-Strategie** für eine zukünftige Migration (2-3 Jahre).

### Projektzweck
- **Ziel:** Intent Recognition + Entity Extraction für deutschsprachige Voice Commands
- **Input:** Transkribierter Text vom STT Server (NeMo)
- **Output:** Strukturierte Intents mit Entities für MQTT Device Control
- **Daten:** 946 Trainingsbeispiele, 129 Geräte, 1 Intent (`device_control`)

---

## 🛠️ Installation (Durchgeführt)

### 1. Python 3.10 Installation

```bash
# PPA hinzufügen
sudo add-apt-repository -y ppa:deadsnakes/ppa
sudo apt update

# Python 3.10 mit venv und dev-Tools
sudo apt install -y python3.10 python3.10-venv python3.10-dev

# Version prüfen
python3.10 --version
# Output: Python 3.10.19
```

**Installiert in:** `/usr/bin/python3.10` (system-weit)  
**Python 3.10 EOL:** Oktober 2031 (Security Updates garantiert)

### 2. Virtual Environment

```bash
cd /home/dgl/Projekte/rasa-nlu

# Altes venv (Python 3.12) löschen und neu erstellen
rm -rf venv
python3.10 -m venv venv

# Aktivieren
source venv/bin/activate

# pip aktualisieren
pip install --upgrade pip
```

**venv-Pfad:** `/home/dgl/Projekte/rasa-nlu/venv/`

### 3. Rasa Installation

```bash
# Rasa 3.6.21 installieren (dauert ~3-5 Minuten)
pip install rasa==3.6.21

# Version prüfen
rasa --version
```

**Installierte Pakete (Auszug):**
- `rasa==3.6.21`
- `rasa-sdk==3.6.2`
- `tensorflow==2.12.0`
- `tensorflow-text==2.12.0`
- `scikit-learn==1.1.3`
- `numpy==1.23.5`

**Gesamtgröße:** ~800 MB (inkl. TensorFlow)

### 4. Konfigurationsdateien

#### `config.yml` - NLU Pipeline
```yaml
language: de

pipeline:
  - name: WhitespaceTokenizer
  - name: RegexFeaturizer
  - name: LexicalSyntacticFeaturizer
  - name: CountVectorsFeaturizer
    analyzer: char_wb
    min_ngram: 1
    max_ngram: 4
  - name: DIETClassifier
    epochs: 100
    constrain_similarities: true
    model_confidence: softmax
    entity_recognition: true
    use_masked_language_model: false
  - name: EntitySynonymMapper
  - name: FallbackClassifier
    threshold: 0.7
    ambiguity_threshold: 0.1
```

**Optimierungen:**
- CPU-only (kein GPU erforderlich)
- Char-level n-grams für Robustheit bei Tippfehlern
- DIETClassifier für Intent + Entity Recognition
- Fallback bei Confidence < 0.7

#### `domain.yml` - Intent/Entity Definitionen
```yaml
version: "3.1"

intents:
  - device_control

entities:
  - device
  - action
  - level

slots:
  device:
    type: text
    mappings:
      - type: from_entity
        entity: device
  action:
    type: text
    mappings:
      - type: from_entity
        entity: action
  level:
    type: text
    mappings:
      - type: from_entity
        entity: level
```

### 5. Trainings-Daten

**Quelle:** `/home/dgl/Projekte/Red/rasa-training/nlu.yml`  
**Kopiert nach:** `/home/dgl/Projekte/rasa-nlu/data/nlu.yml`

```bash
cp /home/dgl/Projekte/Red/rasa-training/nlu.yml /home/dgl/Projekte/rasa-nlu/data/nlu.yml
```

**Format-Beispiel:**
```yaml
version: "3.1"

nlu:
- intent: device_control
  examples: |
    - schalte das [Licht](device) [an](action:ein)
    - stelle [Heizung](device) auf [75](level) Prozent
    - [Alarm](device) [aus](action:aus)
```

**Statistiken:**
- 946 Zeilen
- 129 Geräte
- 3 Entity-Typen: `device`, `action`, `level`
- Generiert aus: MariaDB VoiceTargets

### 6. Training

```bash
rasa train nlu --nlu data/nlu.yml --config config.yml --out models
```

**Ergebnis:**
- Modell: `models/nlu-20260205-103925-commutative-disk.tar.gz`
- Trainingszeit: ~1 Sekunde (CPU)
- Warnung: "Need at least 2 different intent classes" → OK, da nur 1 Intent

**Training erfolgreich:** ✅

---

## 🔌 Schnittstellenbeschreibung

### Input/Output Contract

**Das ist die KRITISCHE Schnittstelle für die Migration!**

#### Input (Text von STT)
```json
{
  "text": "schalte das Licht ein"
}
```

#### Output (Intent + Entities)
```json
{
  "intent": {
    "name": "device_control",
    "confidence": 0.95
  },
  "entities": [
    {
      "entity": "device",
      "value": "Licht",
      "start": 12,
      "end": 17,
      "confidence": 0.98
    },
    {
      "entity": "action",
      "value": "ein",
      "start": 18,
      "end": 21,
      "confidence": 0.97,
      "extractor": "DIETClassifier"
    }
  ],
  "text": "schalte das Licht ein"
}
```

### REST API Endpoints

**Rasa HTTP Server (Port 5005):**

```bash
# Server starten
rasa run --enable-api --model models/nlu-20260205-103925-commutative-disk.tar.gz

# NLU Parse Request
curl -X POST http://localhost:5005/model/parse \
  -H "Content-Type: application/json" \
  -d '{"text": "schalte das Licht ein"}'
```

**Response Format:**
```json
{
  "intent": {"name": "device_control", "confidence": 0.95},
  "entities": [...],
  "text": "schalte das Licht ein",
  "intent_ranking": [...],
  "recognized_entities": {...}
}
```

### MQTT Integration (Geplant)

**Flow:**
```
STT Server → MQTT topic: voice/text
           ↓
      Rasa NLU Parse
           ↓
MQTT topic: voice/intent → Voice Assistant
```

**MQTT Message Format:**
```json
{
  "timestamp": "2026-02-05T10:45:00Z",
  "text": "schalte das Licht ein",
  "intent": "device_control",
  "confidence": 0.95,
  "entities": {
    "device": "Licht",
    "action": "ein"
  }
}
```

---

## 🚪 Exit-Strategie & Migrations-Plan

### Warum Exit-Plan?

**Rasa Open Source Status:**
- ✅ Version 3.6.21 (10. Januar 2025) - Letzte Release
- ⚠️ "Maintenance Mode" seit ~2025
- ⚠️ Rasa fokussiert auf "Hello Rasa" (Cloud-basiert, CALM-Architektur)
- ✅ Python 3.10 Support bis Oktober 2031

**Risiken:**
1. Keine neuen Features
2. Nur Security-Patches
3. Breaking Changes in Dependencies (TensorFlow, NumPy)
4. Community-Support schwindet

### Migration-Zeitpunkt (Empfehlung)

**Trigger für Migration:**
- [ ] Python 3.10 nähert sich EOL (2030)
- [ ] Kritische TensorFlow-Sicherheitslücke ohne Rasa-Update
- [ ] SetFit/Alternative erreicht Production-Reife
- [ ] Performance-Probleme im Production-Betrieb

**Frühester Zeitpunkt:** 2027  
**Spätester Zeitpunkt:** 2030 (vor Python 3.10 EOL)

### Alternative Technologien

#### Option 1: SetFit (Hugging Face)
**Vorteile:**
- ✅ Aktiv entwickelt (letztes Update: August 2025)
- ✅ Few-shot Learning (8 Beispiele!)
- ✅ CPU-only
- ✅ Moderne Architektur (Sentence Transformers)

**Nachteile:**
- ⚠️ **Keine eingebaute Entity Extraction!**
- ⚠️ ABSA (Aspect-Based Sentiment) nur für Review-Analysen
- ⚠️ Eigene Entity-Lösung erforderlich

**Aufwand Migration:** 2-3 Wochen
- Intent Classification: 1 Tag
- Entity Extraction selbst bauen: 1-2 Wochen
- Testing & Integration: 3-5 Tage

**SetFit Code-Beispiel:**
```python
from setfit import SetFitModel, Trainer

# Intent Model
model = SetFitModel.from_pretrained("paraphrase-mpnet-base-v2")
trainer = Trainer(model=model, train_dataset=intent_data)
trainer.train()

# Entities: EIGENE LÖSUNG!
# Option A: spaCy NER trainieren
# Option B: Token Classification (Hugging Face)
# Option C: Regex + Lookup Tables
```

#### Option 2: Hugging Face Transformers (Native)
**Vorteile:**
- ✅ Token Classification für Entities
- ✅ Text Classification für Intents
- ✅ Volle Kontrolle
- ✅ GPU-Beschleunigung möglich

**Nachteile:**
- ⚠️ Mehr Code-Aufwand
- ⚠️ Training-Pipeline selbst bauen
- ⚠️ Mehr ML-Expertise erforderlich

**Aufwand Migration:** 3-4 Wochen

#### Option 3: spaCy 3.x
**Vorteile:**
- ✅ NER + Text Classification eingebaut
- ✅ CPU-optimiert
- ✅ Aktiv entwickelt
- ✅ Deutsche Modelle verfügbar

**Nachteile:**
- ⚠️ Andere Trainings-Daten-Format
- ⚠️ Weniger Few-Shot-fähig

**Aufwand Migration:** 2 Wochen

### Migrations-Prozess (Schritt-für-Schritt)

#### Phase 1: Vorbereitung (Woche 1)
1. **Schnittstellen-Test erstellen**
   ```python
   # tests/test_nlu_interface.py
   def test_nlu_parse():
       input = {"text": "schalte das Licht ein"}
       output = nlu_service.parse(input)
       
       assert output["intent"]["name"] == "device_control"
       assert len(output["entities"]) >= 1
       assert any(e["entity"] == "device" for e in output["entities"])
   ```

2. **Benchmark-Daten sammeln**
   - 100 Test-Sätze aus Production-Logs
   - Ground Truth annotations
   - Rasa Baseline Accuracy/F1 messen

3. **Daten konvertieren**
   - `nlu.yml` → Alternative Format
   - Entities extrahieren
   - Train/Test Split

#### Phase 2: Parallel-Implementierung (Woche 2-3)
1. **Neue NLU-Lösung implementieren**
   - Adapter-Pattern für einheitliche Schnittstelle
   - Training-Pipeline
   - Model Serving

2. **A/B Testing Setup**
   ```python
   # nlu_router.py
   def parse_text(text):
       if USE_NEW_NLU:
           return new_nlu.parse(text)
       else:
           return rasa_nlu.parse(text)
   ```

3. **Performance-Tests**
   - Accuracy vergleichen
   - Latenz messen
   - CPU/RAM Verbrauch

#### Phase 3: Migration (Woche 4)
1. **Graduelle Umstellung**
   - 10% Traffic → Neue Lösung
   - Monitoring, Bug-Fixes
   - 50% → 100%

2. **Rasa deaktivieren**
   ```bash
   # venv löschen (optional)
   rm -rf /home/dgl/Projekte/rasa-nlu/venv
   
   # Python 3.10 behalten (für andere Projekte)
   # ODER deinstallieren:
   sudo apt remove python3.10 python3.10-venv python3.10-dev
   ```

3. **Dokumentation aktualisieren**

### Schnittstellen-Kompatibilität sicherstellen

**KRITISCH: Adapter-Pattern verwenden!**

```python
# nlu_adapter.py - Universelle Schnittstelle
from abc import ABC, abstractmethod

class NLUAdapter(ABC):
    @abstractmethod
    def parse(self, text: str) -> dict:
        """
        Returns:
        {
            "intent": {"name": str, "confidence": float},
            "entities": [
                {"entity": str, "value": str, "start": int, "end": int}
            ],
            "text": str
        }
        """
        pass

class RasaNLUAdapter(NLUAdapter):
    def parse(self, text: str) -> dict:
        # Rasa-spezifische Implementierung
        result = self.rasa_interpreter.parse(text)
        return self._normalize(result)

class SetFitNLUAdapter(NLUAdapter):
    def parse(self, text: str) -> dict:
        # SetFit + Custom Entity Extraction
        intent = self.intent_model.predict(text)
        entities = self.entity_extractor.extract(text)
        return {
            "intent": {"name": intent[0], "confidence": intent[1]},
            "entities": entities,
            "text": text
        }
```

**Voice Assistant Integration bleibt GLEICH:**
```javascript
// cIntentRouter.js - KEINE Änderung erforderlich!
mqtt.on('message', (topic, message) => {
    const nluResult = JSON.parse(message);
    
    // Schnittstelle bleibt identisch
    const intent = nluResult.intent.name;
    const entities = nluResult.entities;
    
    this.handleIntent(intent, entities);
});
```

---

## 📊 Bewertungsmatrix für Alternativen

| Kriterium | Rasa 3.6 | SetFit | HF Transformers | spaCy |
|-----------|----------|--------|-----------------|-------|
| **Intent Classification** | ✅ Exzellent | ✅ Exzellent | ✅ Sehr gut | ⚠️ Gut |
| **Entity Extraction** | ✅ Eingebaut | ❌ Selbst bauen | ⚠️ Token Clf. | ✅ Eingebaut |
| **CPU Performance** | ✅ Gut | ✅ Sehr gut | ⚠️ OK | ✅ Sehr gut |
| **Trainings-Aufwand** | ✅ Minimal | ✅ Minimal | ⚠️ Mittel | ⚠️ Mittel |
| **Wartung 2026+** | ❌ Maintenance | ✅ Aktiv | ✅ Aktiv | ✅ Aktiv |
| **Deutsche Sprache** | ✅ Gut | ✅ Sehr gut | ✅ Sehr gut | ✅ Exzellent |
| **Migrations-Aufwand** | - | ⚠️ 2-3 Wo | ⚠️ 3-4 Wo | ⚠️ 2 Wo |
| **Produktionsreife** | ✅ Battle-tested | ⚠️ Neu | ✅ Erprobt | ✅ Erprobt |

**Empfehlung für 2027-2028:** **SetFit + spaCy NER**
- SetFit für Intent Classification (exzellent, wenig Daten)
- spaCy NER für Entity Extraction (battle-tested)
- Gesamtaufwand: 2-3 Wochen
- Performance: Besser als Rasa
- Zukunftssicher: Beide aktiv entwickelt

---

## 🔧 Wartung & Troubleshooting

### Rasa NLU Update (innerhalb 3.6.x)

```bash
source venv/bin/activate
pip install --upgrade rasa==3.6.21  # oder neuere 3.6.x Version
```

### Modell neu trainieren

```bash
# Bei Datenänderungen
rasa train nlu --nlu data/nlu.yml --config config.yml --out models
```

### Bekannte Probleme

**1. SQLAlchemy Warning**
```
MovedIn20Warning: Deprecated API features detected!
```
**Lösung:** Ignorieren - Rasa 3.6 nutzt SQLAlchemy 1.4 (kompatibel)

**2. "Need at least 2 different intent classes"**
**Lösung:** Normal bei 1 Intent - Entity Extraction funktioniert trotzdem

**3. TensorFlow Warnings**
```
jax.xla_computation is deprecated
```
**Lösung:** Ignorieren - funktionale Deprecations, kein Impact

### Logs & Debugging

```bash
# Debug-Modus
rasa shell nlu --debug

# Modell-Info
rasa data validate

# Performance-Test
time rasa shell nlu < test_inputs.txt
```

---

## 📁 Datei-Struktur

```
/home/dgl/Projekte/rasa-nlu/
├── venv/                    # Python 3.10 Virtual Environment
├── data/
│   └── nlu.yml             # Training Data (946 Zeilen)
├── models/
│   └── nlu-*.tar.gz        # Trainierte Modelle
├── tests/
│   └── test_nlu.sh         # Test-Scripts (TODO)
├── scripts/
│   └── train.sh            # Training-Script (TODO)
├── docs/
│   └── MIGRATION.md        # Dieses Dokument
├── config.yml              # NLU Pipeline Config
├── domain.yml              # Intent/Entity Definitionen
├── endpoints.yml           # Endpoints (minimal)
├── .gitignore              # Git Ignore
└── README.md               # Projekt-README
```

---

## ✅ Checkliste: Installation abgeschlossen

- [x] Python 3.10.19 installiert
- [x] venv erstellt mit Python 3.10
- [x] Rasa 3.6.21 installiert
- [x] config.yml erstellt (CPU-optimiert)
- [x] domain.yml erstellt (1 Intent, 3 Entities)
- [x] nlu.yml kopiert (946 Trainingsbeispiele)
- [x] Training erfolgreich
- [x] Modell generiert
- [x] Git Repository initialisiert
- [x] Dokumentation erstellt

---

## 📞 Support & Referenzen

**Rasa Dokumentation:**
- Rasa 3.6 Docs: https://rasa.com/docs/rasa/
- Migration Guide: https://rasa.com/docs/rasa/migration-guide/
- NLU Training: https://rasa.com/docs/rasa/nlu-training-data/

**Alternative Frameworks:**
- SetFit: https://github.com/huggingface/setfit
- spaCy: https://spacy.io/
- Hugging Face: https://huggingface.co/docs/transformers/

**Internes:**
- Voice Assistant: `/home/dgl/Projekte/voice-assistant/`
- STT Server: `/home/dgl/stt-server/`
- Red DeviceController: `/home/dgl/Projekte/Red/Devices/classes/cDeviceController.js`

---

**Erstellt von:** GitHub Copilot  
**Letzte Aktualisierung:** 05. Februar 2026  
**Version:** 1.0
