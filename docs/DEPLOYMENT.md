# Rasa NLU Deployment Guide

**Ziel:** Rasa NLU HTTP Server auf PROD (M910q) deployen

---

## 🎯 Deployment-Optionen

### Option 1: Systemd Service (Empfohlen)

```bash
# Service-Datei erstellen
sudo nano /etc/systemd/system/rasa-nlu.service
```

**Service-Konfiguration:**
```ini
[Unit]
Description=Rasa NLU HTTP Server
After=network.target mosquitto.service

[Service]
Type=simple
User=dgl
WorkingDirectory=/home/dgl/Projekte/rasa-nlu
Environment="PATH=/home/dgl/Projekte/rasa-nlu/venv/bin"
ExecStart=/home/dgl/Projekte/rasa-nlu/venv/bin/rasa run \
    --enable-api \
    --port 5005 \
    --model /home/dgl/Projekte/rasa-nlu/models/latest.tar.gz \
    --log-file /home/dgl/Projekte/rasa-nlu/logs/rasa.log
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

**Installation:**
```bash
# Service aktivieren
sudo systemctl daemon-reload
sudo systemctl enable rasa-nlu
sudo systemctl start rasa-nlu

# Status prüfen
sudo systemctl status rasa-nlu

# Logs anzeigen
sudo journalctl -u rasa-nlu -f
```

### Option 2: Docker (Alternative)

```dockerfile
# Dockerfile
FROM python:3.10-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 5005

CMD ["rasa", "run", "--enable-api", "--port", "5005"]
```

**Build & Run:**
```bash
docker build -t rasa-nlu:latest .
docker run -d -p 5005:5005 --name rasa-nlu rasa-nlu:latest
```

---

## 📦 Projekt nach PROD kopieren

```bash
# Von DEV nach PROD
scp -r /home/dgl/Projekte/rasa-nlu user@prod-server:/home/dgl/Projekte/

# Auf PROD:
cd /home/dgl/Projekte/rasa-nlu
python3.10 -m venv venv
source venv/bin/activate
pip install rasa==3.6.21
```

---

## 🔧 Model Update Workflow

```bash
# 1. Training auf DEV
cd /home/dgl/Projekte/rasa-nlu
source venv/bin/activate
rasa train nlu

# 2. Model nach PROD kopieren
scp models/nlu-*.tar.gz user@prod:/home/dgl/Projekte/rasa-nlu/models/

# 3. Symlink aktualisieren
ssh user@prod
cd /home/dgl/Projekte/rasa-nlu/models
ln -sf nlu-<timestamp>.tar.gz latest.tar.gz

# 4. Service neu starten
sudo systemctl restart rasa-nlu
```

---

## 🧪 Testing

```bash
# HTTP API Test
curl -X POST http://localhost:5005/model/parse \
  -H "Content-Type: application/json" \
  -d '{"text": "schalte das Licht ein"}'

# Erwartete Response
{
  "intent": {"name": "device_control", "confidence": 0.95},
  "entities": [...]
}
```

---

## 📊 Monitoring

```bash
# CPU/RAM Nutzung
ps aux | grep rasa

# Logs
tail -f /home/dgl/Projekte/rasa-nlu/logs/rasa.log

# Systemd Logs
journalctl -u rasa-nlu --since "1 hour ago"
```

---

## 🔒 Sicherheit

**Port 5005 nicht öffentlich exponieren!**

```bash
# Nur localhost
--cors "*" --enable-api

# Oder: Nginx Reverse Proxy mit Auth
```

---

## 🚀 Performance-Tuning

**CPU-Threads:**
```bash
# In config.yml
export TF_NUM_INTRAOP_THREADS=4
export TF_NUM_INTEROP_THREADS=2
```

**Memory Limit (Systemd):**
```ini
[Service]
MemoryMax=2G
```

---

## 📞 Troubleshooting

**Port bereits belegt:**
```bash
sudo lsof -i :5005
sudo kill <PID>
```

**Permission denied:**
```bash
sudo chown -R dgl:dgl /home/dgl/Projekte/rasa-nlu
```

**Model not found:**
```bash
ls -la models/
# Symlink prüfen
```

---

**Erstellt:** 05. Februar 2026
