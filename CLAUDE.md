# Körper-Labor

Offline-Android-App: Selbstmessungen mit Kamera und Beschleunigungssensor
plus drei Kopf-Tests, Export für Daniels Health-OS-Chat. Reine Web-App in
einer Datei, die per [apk-builder](../apk-builder) zur APK wird. Tests,
Verfahren, Genauigkeit und Exportformat stehen in [README.md](README.md),
Versionen in [CHANGELOG.md](CHANGELOG.md).

## Build & Test

Kein Bundler, kein Build-Step. Testserver `koerper-labor` aus der
Workspace-`.claude/launch.json` (Port 8160), dann
`http://localhost:8160/web/`. `?debug=1` führt den Selbsttest aus (Konsole
und Zeile auf der Startseite, auch per `klTests()`). Er muss komplett `OK`
zeigen; er prüft die Signalverarbeitung mit künstlichen Signalen.

Im Browser gibt es weder Bewegungssensor noch Kamera. Den Ablauf trotzdem
durchspielen: in der Konsole `Cam.open` durch eine Attrappe ersetzen, die
`onFrame(t, r, g, b)` mit einem künstlichen Pulssignal füttert (der Test
rechnet mit dem übergebenen `t`, 60 s lassen sich also sofort einspielen),
per `setInterval` `DeviceMotionEvent`s mit `accelerationIncludingGravity`
auslösen, `later` auf kurze Wartezeiten kappen und per Intervall `t-go`,
`pad` und `t-next` bedienen.

APK bauen, **immer über den eigenen Wrapper**:

```powershell
cd "D:\claude code projects\koerper-labor"
.\build.ps1 -VersionName "1.1" -VersionCode 2 -Release   # signiert -> dist\koerperlabor-<v>.apk
```

Der Wrapper patcht mehr als bei den anderen Apps: CAMERA-Berechtigung im
Manifest, Anzeigename mit Umlaut in `strings.xml`, Brücke `KlAndroid`, und
einen `WebChromeClient` für `getUserMedia` (das Template hat keinen).

## Konventionen

- Alles in `web/index.html`, kein Framework, kein Netzwerk, kein WebGL.
- Signalverarbeitung (`analyzePPG`, `analyzeJump`, `analyzeBreath`,
  `analyzeSteady`) bleibt frei von DOM und Sensoren und bekommt für jede
  Änderung einen Fall in `klTests()` mit künstlichem Signal.
- Sensorzugriff nur über `Cam.open()` und `motionRecorder()`.
- Jeder Test meldet über `ok(result)` oder `fail(text)`; Timer immer über
  `later()` und Aufräumen über `cleanup()`, damit ein Abbruch (Zurück-Geste)
  Kamera und Blitz sicher ausschaltet.
- Tests, bei denen man das Display nicht sieht (Atmung, Sprung, Balance),
  melden Start und Ende per Ton und Vibration.
- Die App bewertet nichts und gibt keine Empfehlungen. Angezeigt wird nur
  der eigene Schnitt (Median der letzten bis zu 14 früheren Tage, ab 3).
- Kein `confirm()`/`alert()` im Code verwenden.
- Exportfelder `lab_*` nur zusammen mit dem Skill `health-os-debrief` ändern
  (Arbeitskopie in `..\health-os-skills\`).

## Aktueller Stand

v1.0 (code 1, 2026-11-14): acht Tests, Morgen-Check, Einzeltests, Verlauf,
Gerätecheck, Backup, Export. Selbsttest 29/29; der ganze Morgen-Check lief
im Browser mit simulierten Sensoren durch. Signierte APK
`dist/koerperlabor-1.0.apk`.

**Erster Gerätetest (Pixel, 2026-11-14):** Fragen 1–3 unten sind
beantwortet: `devicemotion` liefert 60 Werte pro Sekunde, `getUserMedia`
funktioniert unter `file://` (240×320), der Blitz geht an. Im Dunkeln (ohne
Finger) kamen nur 15 Bilder pro Sekunde; die Rate bei aufgelegtem Finger ist
nicht gemessen. Pulstest: App 62 /min gegen Oura 65 /min. Sprung, Zittern,
Balance, Atmung, Signalqualität und HRV sind am Gerät noch offen.

Ursprüngliche Fragenliste (Einstellungen → Gerätecheck zeigt die ersten drei):

1. Liefert `devicemotion` im WebView unter `file://` Daten?
2. Funktioniert `getUserMedia` unter `file://` (Berechtigungsdialog kommt)?
3. Lässt sich der Blitz per `applyConstraints({advanced:[{torch:true}]})`
   einschalten? Ohne Blitz braucht die Pulsmessung eine helle Lampe.
4. Erkennt die Finger-Erkennung (Rot deutlich über Grün und Blau) den Finger,
   und übersteuert der Rotkanal?
5. Plausibilität: Puls gegen Oura oder Zählen, Sprunghöhe gegen Gefühl.

Liefert `file://` keine Kamera oder keinen Sensor, wäre der nächste Schritt,
die Seiten über `shouldInterceptRequest` unter einer https-Adresse
auszuliefern (sicherer Kontext), nicht die Tests umzubauen.

Bewusst noch nicht gebaut: Resonanzfrequenz-Suche mit Atemführung
(ursprüngliche Idee 2). Sie setzt voraus, dass die HRV-Messung am Gerät
brauchbar ist.
