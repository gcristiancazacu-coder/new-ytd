# 🎬 YT Downloader Pro - Setup pentru Familie

Bun venit! Aceasta este o aplicație pentru descarcarea de video și audio de pe YouTube. Fiecare membru al familiei poate rula propria versiune.

---

## 📋 Ce ai nevoie:

- ✅ PC/Laptop (Windows/Mac/Linux)
- ✅ Telefon Android
- ✅ Ambele conectate la **ACEIAȘI REȚEA WiFi**
- ✅ Fisierele acestui proiect

---

## 🖥️ PASUL 1: Setup Backend pe PC

### 1.1 Instalează Python
1. Mergi la: https://www.python.org/downloads/
2. Download **Python 3.10+**
3. La instalare, **BIFEAZĂ: "Add Python to PATH"**
4. Click Install

### 1.2 Setup Backend
1. Deschide **Command Prompt** (CMD) sau **PowerShell**
2. Mergi în folderul proiectului:
   ```
   cd C:\Users\[USERNAME]\Desktop\YT_Downloader_Pro
   ```
3. Instaleaza dependencies:
   ```
   pip install -r backend/requirements.txt
   ```
4. Rulează backend-ul:
   ```
   python backend/main.py
   ```

Dacă vezi acest mesaj, e ok:
```
INFO:     Uvicorn running on http://127.0.0.1:8000
```

**⚠️ PASUL IMPORTANT:** Lasă aceasta fereastră DESCHISĂ! Backend-ul trebuie să ruleze mereu!

---

## 🌐 PASUL 2: Găsește IP-ul PC-ului

### Pe Windows:
1. Deschide **Command Prompt** (alt CMD window)
2. Scrie:
   ```
   ipconfig
   ```
3. Caută **"IPv4 Address"** la secțiunea **"Wi-Fi"** sau **"Ethernet"**
4. Vei vedea ceva ca: `192.168.1.133`
5. **NOTEAZA ACEST NUMAR!**

---

## 📱 PASUL 3: Instalează App pe Telefon

1. Copiază fisierul `app-release.apk` pe telefon (via USB sau WhatsApp)
2. Deschide **File Manager** pe telefon
3. Găsește `app-release.apk`
4. Apasă pe el → **Install**
5. Gata! App-ul apare pe telefon

---

## ⚙️ PASUL 4: Configurează Server URL

1. Deschide app-ul **"YT Downloader Pro"** pe telefon
2. Vei vedea un câmp: **"Server URL"**
3. Șterge ce scrie acolo
4. Scrie:
   ```
   http://192.168.1.XXX:8000
   ```
   Unde `192.168.1.XXX` = IP-ul găsit la PASUL 2

**Exemplu:**
```
http://192.168.1.133:8000
```

5. Gata! Acum app-ul se conectează la PC-ul tău

---

## ✅ PASUL 5: Testează Download

1. Caută un video pe YouTube
2. Copiază link-ul (ex: https://www.youtube.com/watch?v=...)
3. In app, apasă pe câmp **"Link video"**
4. Lipește link-ul
5. Alege: **Audio** sau **Video**
6. Apasă **"Descarcă"**
7. Asteaptă progresul să ajungă la 100%
8. Fisierul se salvează pe PC în folderul: `YT_Downloader_Pro\downloads\`

---

## 🔧 TROUBLESHOOTING

### "Connection refused" (Conexiune refuzată)
**Problemă:** Backend-ul nu rulează pe PC
**Soluție:** 
- Verifica dacă fereastra CMD cu backend e deschisă
- Daca nu, rulează din nou: `python backend/main.py`

### "Connection timed out" (Timeout)
**Problemă:** PC-ul și telefon nu sunt în aceeași WiFi
**Soluție:**
- Conectează telefon la ACEEAȘI WiFi cu PC-ul
- Verifica IP-ul din nou (s-ar putea să se schimbe)

### IP-ul s-a schimbat
**Problema:** Backend rulează pe IP diferit
**Soluție:**
1. Rulează `ipconfig` din nou
2. Noteaza IP-ul NOU
3. In app, actualizeaza "Server URL" cu IP-ul nou

### App nu se instaleaza
**Problema:** "Unknown app source"
**Soluție:**
- Du-te in **Settings → Security → Unknown Sources**
- Activează **"Allow app installs from unknown sources"**
- Incearca să reinstalezi APK-ul

---

## 📁 Unde gasesc fisierele descarcate?

Fisierele se salvează pe **PC** în:
```
C:\Users\[USERNAME]\Desktop\YT_Downloader_Pro\downloads\
```

Poți accesa această mapă direct de pe PC și muta fisierele unde vrei.

---

## 🛑 Oprire Backend

Când nu mai ai nevoie de app:
1. Du-te la fereastra CMD cu backend
2. Apasă: **Ctrl + C**
3. Backend-ul se oprește

---

## ❓ Intrebări?

Dacă ceva nu funcționează:
1. Verifica că backend rulează pe PC
2. Verifica că e aceeași WiFi
3. Verifica IP-ul și URL-ul din app
4. Restartează PC și telefon

---

## 📊 Versiune:
- **App Version:** 1.0.0 (Debug)
- **Backend:** Python FastAPI
- **Last Updated:** Feb 3, 2026

Distractie placuta! 🎉
