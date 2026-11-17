# Changelog

## 1.2 (code 3) – 2026-11-16

Drei Einzeltests unter "Training und Atmung". Sie gehören nicht zum
Morgen-Check und gehen nicht in den Health-OS-Export.

- Tempo-Wächter: Handy am Arm oder Bein, misst über die Neigung die Dauer
  von Heben und Ablassen je Wiederholung; Ton nach jedem Ablassen (hoch =
  langsam genug, tief = zu schnell). Ziel 2 bis 6 Sekunden.
- Trittfrequenz: Schritte pro Minute aus 30 Sekunden Laufen oder Gehen.
- Resonanz-Atmung: fünf Atemtempi (6,5 bis 4,5 pro Minute) mit Atemführung
  und Pulsmessung per Kamera; zeigt, bei welchem Tempo der Puls am
  stärksten mit dem Atem schwingt.

## 1.1 (code 2) – 2026-11-16

- Wach-Check: drei Minuten Daueraufmerksamkeit (Reaktion auf seltene
  Reize), Ergebnis Median und Aussetzer, im Export als `lab_wach_ms` und
  `lab_wach_aussetzer`. Als Einzeltest und wählbar für den Morgen-Check.

## 1.0 (code 1) – 2026-11-14

Erste Version.

- Acht Tests: Puls & HRV (Kamera), Reaktion, Tapping, Zahlen merken,
  Zittern, Balance, Sprung, Atmung.
- Morgen-Check mit wählbaren Tests, Einzeltests, Vergleich mit dem eigenen
  Schnitt, Verlauf mit Kurven.
- Gerätecheck für Bewegungssensor, Kamera und Blitz.
- Export als Text mit JSON-Block für den Health-OS-Chat, Backup.
- Android: Kamera-Berechtigung, Brücke `KlAndroid`.
