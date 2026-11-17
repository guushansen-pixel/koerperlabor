# Körper-Labor

Offline-Android-App für kurze Selbstmessungen mit den Sensoren des Handys,
gedacht als Morgen-Check: Puls und HRV über die Kamera, Reaktion, Tapping,
Zahlen merken, Zittern, Balance, Sprunghöhe, Atemfrequenz. Ergebnis als Text
für Daniels Health-OS-Chat.

**Kein Medizinprodukt. Die Messgenauigkeit am Gerät ist nicht validiert**;
alle Werte sind für den Vergleich mit sich selbst über die Zeit gedacht.

APK: [dist/koerperlabor-1.1.apk](dist/koerperlabor-1.1.apk) (v1.1; die APK für v1.2 ist noch nicht gebaut)

## Tests

| Test | Sensor | Dauer | Ergebnis | Verfahren |
|---|---|---|---|---|
| Puls & HRV | Rückkamera + Blitz | 60 s | Puls /min, RMSSD ms | Mittlere Helligkeit je Bild (Rot und Grün), auf 30 Hz, Trend über 1 s abgezogen, Gipfel mit Parabel-Verfeinerung, Schlagabstände ±25 % um den Median |
| Reaktion | Touch | ~30 s | Median in ms | 6 Durchgänge, der erste zählt nicht, zufällige Wartezeit 1,5–4 s |
| Wach-Check | Touch | 3 min | Median in ms, Aussetzer | wie der Vigilanztest der Schlafforschung (PVT) in Kurzform: Reiz nach 1–4 s, laufender Zähler; Aussetzer = Reaktion ab 500 ms oder nach 3 s verpasst; nicht im Standard-Check |
| Tapping | Touch | 10 s | Tipps pro Sekunde | ab dem ersten Tipp |
| Zahlen merken | Touch | ~70 s | Ziffernspanne | ab 4 Ziffern, Ende nach zwei Fehlern bei einer Länge |
| Zittern | Beschleunigung | 15 s | Milli-g | Anteile ab etwa 3 Hz (Signal minus 0,26-s-Mittel), RMS über alle Achsen |
| Balance | Beschleunigung | 30 s | Milli-g | Band etwa 0,2–2,5 Hz, RMS über alle Achsen |
| Sprung | Beschleunigung | 12 s | cm (höchster) | Flugzeit T zwischen Unter- und Überschreiten von 0,5 g, Höhe = g·T²/8 |
| Atmung | Beschleunigung | 60 s | Atemzüge /min | Achse mit der größten langsamen Schwankung, Aufwärts-Durchgänge mit Hysterese |

Dazu drei Einzeltests außerhalb des Morgen-Checks ("Training und Atmung"):

| Test | Sensor | Dauer | Ergebnis | Verfahren |
|---|---|---|---|---|
| Tempo-Wächter | Beschleunigung | bis 90 s | Median Ablassen in s, Wiederholungen, Heben, Anteil im Ziel | Richtung der Schwerkraft → Kippwinkel in der Ebene quer zur ruhigsten Achse; Umkehrpunkte ab 0,3 rad Gegenbewegung; Dauer je Phase = Zeit von 10 % bis 90 % des Wegs, hochgerechnet (Pausen zählen nicht). Erste Bewegung = Heben. Ende nach 6 s Ruhe |
| Trittfrequenz | Beschleunigung | 30 s | Schritte /min | Betrag der Beschleunigung, Autokorrelation; kürzester Abstand, dessen Wert mindestens 40 % des höchsten erreicht |
| Resonanz-Atmung | Rückkamera + Blitz | 5 × 75 s | Atemtempo mit der größten Pulsschwankung | je Stufe Pulsverlauf aus den Schlagabständen (4 Hz), Anteil genau bei der Atemfrequenz über ganze Atemzüge, Tal-zu-Gipfel in Schlägen /min; die ersten 10 s jeder Stufe fallen weg |

Standard im Morgen-Check: Puls, Reaktion, Tapping, Zittern, Sprung (etwa
2,5 Minuten). Die Auswahl steht in den Einstellungen.

## Was die Zahlen taugen

Geprüft ist nur die Rechnung, mit künstlichen Signalen im Selbsttest
(`?debug=1`):

- Puls: 60, 72 und 110 /min werden auf etwa ±1 getroffen.
- HRV: Bei völlig gleichmäßigem Puls zeigt die Rechnung trotzdem etwa 8 ms
  RMSSD an. Das ist das Grundrauschen von 30 Bildern pro Sekunde; kleine
  HRV-Werte und kleine Änderungen sind damit nicht aussagekräftig.
- Sprung: 0,40 s und 0,55 s Flugzeit werden auf etwa ±2–3 cm getroffen.
- Atmung: 6 und 12 /min auf etwa ±0,5.

- Resonanz: 16 und 8 Schläge Schwankung im Atemtakt werden auf etwa ±1
  getroffen; eine Schwankung in einem anderen Takt zählt kaum mit.
- Tempo: 1 s Heben und 4 s Ablassen werden auf etwa ±0,1 s getroffen, auch
  über eine halbe Drehung hinaus.
- Trittfrequenz: 110, 170 und 180 /min auf ±1, auch wenn ein Bein deutlich
  schwächer durchschlägt. Bei sehr einseitigem Sitz (Hosentasche) kann die
  Hälfte herauskommen.

Grenzen der drei neuen Tests: Der Tempo-Wächter misst Neigung, keine
Strecke; Übungen ohne Kippen (Hantelstange beim Bankdrücken) erkennt er
nicht. Die Resonanz-Suche hängt an der Kamera-Pulsmessung, deren
Schlag-zu-Schlag-Genauigkeit am Gerät nicht validiert ist; die gesuchte
Schwankung (meist 5 bis 20 Schläge) ist aber viel größer als das
Grundrauschen der RMSSD-Rechnung. Fünf Stufen bedeuten gut sechs Minuten
Blitz am Finger, deshalb die Pausen dazwischen.

Nicht geprüft ist, wie gut die echten Sensoren des Pixel das liefern:
Belichtungsregelung und Bildrate der Kamera im WebView, Übersteuern des
Rotkanals mit Blitz, Sensor-Rate und Rauschen, und wie fest das Handy beim
Sprung wirklich am Körper bleibt. Ein Vergleich gegen Brustgurt oder
Oura-Ring steht aus.

Bei unruhigem Signal (weniger als 60 % brauchbare Schlagabstände) wird die
HRV weder angezeigt noch exportiert.

## Exportformat

```
KOERPERLABOR 2026-11-14 (Sa) 06:40
Puls: 58.4 /min
HRV (RMSSD): 42 ms
Reaktion: 285 ms
Sprung: 24.5 cm

KOERPERLABOR-JSON-START
{"datum":"2026-11-14","lab_puls":58.4,"lab_rmssd":42,"lab_reaktion_ms":285,"lab_sprung_cm":24.5,"lab_zeit":"06:40"}
KOERPERLABOR-JSON-ENDE
```

Felder: `lab_puls`, `lab_rmssd`, `lab_reaktion_ms`, `lab_tapping`,
`lab_wach_ms`, `lab_wach_aussetzer`, `lab_merken`, `lab_zittern_mg`,
`lab_balance_mg`, `lab_sprung_cm`,
`lab_atem`, `lab_zeit`. Tempo-Wächter, Trittfrequenz und Resonanz-Atmung
haben bewusst kein Exportfeld (`METRICS` ohne `json`). Das Format ist eine Schnittstelle zum Skill
`health-os-debrief` (Abschnitt "Morgen-Check: Körper-Labor-App").

## Datenmodell (localStorage)

- `koerperlabor.days.v1`: Datum → `{datum, zeit, puls: {hr, rmssd, quality,
  kanal}, reaktion: {ms, fehl}, tapping: {tps}, merken: {span}, zittern:
  {mg}, balance: {mg}, sprung: {cm, alle}, atem: {bpm, cv, breaths}, tempo: {reps, hin,
  rueck, ziel, treu, alle}, tritt: {spm, reg}, resonanz: {rate, swing, alle:
  [{rate, swing, q, hr}]}}`. Eine
  spätere Messung desselben Tages ersetzt die frühere.
- `koerperlabor.settings.v1`: `check` (Tests im Morgen-Check), `sound`,
  `lastExport`, `tempoZiel`, `schema`
