# Körper-Labor

Offline-Android-App für kurze Selbstmessungen mit den Sensoren des Handys,
gedacht als Morgen-Check: Puls und HRV über die Kamera, Reaktion, Tapping,
Zahlen merken, Zittern, Balance, Sprunghöhe, Atemfrequenz. Ergebnis als Text
für Daniels Health-OS-Chat.

**Kein Medizinprodukt. Die Messgenauigkeit am Gerät ist nicht validiert**;
alle Werte sind für den Vergleich mit sich selbst über die Zeit gedacht.

APK: [dist/koerperlabor-1.0.apk](dist/koerperlabor-1.0.apk)

## Tests

| Test | Sensor | Dauer | Ergebnis | Verfahren |
|---|---|---|---|---|
| Puls & HRV | Rückkamera + Blitz | 60 s | Puls /min, RMSSD ms | Mittlere Helligkeit je Bild (Rot und Grün), auf 30 Hz, Trend über 1 s abgezogen, Gipfel mit Parabel-Verfeinerung, Schlagabstände ±25 % um den Median |
| Reaktion | Touch | ~30 s | Median in ms | 6 Durchgänge, der erste zählt nicht, zufällige Wartezeit 1,5–4 s |
| Tapping | Touch | 10 s | Tipps pro Sekunde | ab dem ersten Tipp |
| Zahlen merken | Touch | ~70 s | Ziffernspanne | ab 4 Ziffern, Ende nach zwei Fehlern bei einer Länge |
| Zittern | Beschleunigung | 15 s | Milli-g | Anteile ab etwa 3 Hz (Signal minus 0,26-s-Mittel), RMS über alle Achsen |
| Balance | Beschleunigung | 30 s | Milli-g | Band etwa 0,2–2,5 Hz, RMS über alle Achsen |
| Sprung | Beschleunigung | 12 s | cm (höchster) | Flugzeit T zwischen Unter- und Überschreiten von 0,5 g, Höhe = g·T²/8 |
| Atmung | Beschleunigung | 60 s | Atemzüge /min | Achse mit der größten langsamen Schwankung, Aufwärts-Durchgänge mit Hysterese |

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
`lab_merken`, `lab_zittern_mg`, `lab_balance_mg`, `lab_sprung_cm`,
`lab_atem`, `lab_zeit`. Das Format ist eine Schnittstelle zum Skill
`health-os-debrief` (Abschnitt "Morgen-Check: Körper-Labor-App").

## Datenmodell (localStorage)

- `koerperlabor.days.v1`: Datum → `{datum, zeit, puls: {hr, rmssd, quality,
  kanal}, reaktion: {ms, fehl}, tapping: {tps}, merken: {span}, zittern:
  {mg}, balance: {mg}, sprung: {cm, alle}, atem: {bpm, cv, breaths}}`. Eine
  spätere Messung desselben Tages ersetzt die frühere.
- `koerperlabor.settings.v1`: `check` (Tests im Morgen-Check), `sound`,
  `lastExport`, `schema`
