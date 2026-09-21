#!/usr/bin/env python3
"""Smeedt de welkomst-intro uit Joosts fietsopname (2026-09-21, ronde 2).

De synthetische spaaktikken uit ronde 1 oordeelde Joost op het toestel als
"slaat nergens op": te veel piep, te weinig wiel. Zijn keuze voor ronde 2 was
een echte opname, en wel zo dat je de fiets hoort **opstarten en uitrijden**:
het begin (het pedaal grijpt in en het geratel trekt op) en het eind (de
rit wordt stiller en stopt) blijven, de zeven seconden gelijkmatig geratel
in het midden vervallen.

Bron: ~/Downloads/freesound_community-bicycle-pedal-105846.mp3 (10,37 s).
De nummers in die bestandsnaam wijzen níét naar freesound 105846 (dat is een
synthesizer-kick); de downloadlink en licentie moeten worden vastgelegd
voordat deze clip mee mag in een Play-release. Voor het toestel-experiment op
Joosts eigen Oppo is dat geen belemmering.

Segmenten (afgeleid uit de 50 ms-envelopmeting):
  A  0,33-1,05 s  de in-grijpende klik op 0,35 s en de optrekkende rammel
  B  8,70-10,05 s de uitrij: rammel die uitdunt naar losse tokjes, dan stil

A en B worden met een korte overvloeiing aan elkaar geplakt; het geheel
krijgt een fade-in en fade-out en wordt weggeschreven als
assets/sounds/welcome_roll.wav.

Dit script meet óók de trillingsmomenten: het loopje "elke tik een trilling"
uit ronde 1 wordt vertaald naar één puls per hoeveelheid hoorbaarheid
(genormaliseerde amplitude-som), waardoor de trillingen vanzelf versnellen
met de optrek en uitdunnen met de uitrij. Het print de pulstijden als
milliseconden (zowel cliptijd als intro-tijd) om over te nemen in
lib/features/welcome/spoke_track.dart.

Gebruik: python3 tool/rolling_intro_sound.py   (vanuit de repo-root)
Vereist: ffmpeg op PATH, alleen viderek de Python-stdlib.
"""

import struct
import subprocess
import sys
import wave
from pathlib import Path

SOURCE = Path("/Users/joostmouw/Downloads/freesound_community-bicycle-pedal-105846.mp3")
OUT = Path("assets/sounds/welcome_roll.wav")
RATE = 44100

# Segment A (opstart) en B (uitrit), in seconden in de bronopname.
# Ronde 3 (Joost, 2026-09-21): de uitrij mocht langer doorlopen "dat je hem
# uit hoort te trappen", dus B begint iets vroeger en loopt door tot de
# opname zelf stopt; de fade-out is alleen nog een vangnet.
A_START, A_END = 0.33, 1.05
B_START, B_END = 8.50, 10.35
CROSSFADE = 0.045  # s
FADE_IN = 0.06  # s
FADE_OUT = 0.15  # s
PEAK = 0.75  # normalisatie: luid genoeg voor een telefoonspeaker, niet overstuur

# Trillingsmaat: één puls per zoveel genormaliseerde amplitude-som. De
# constante is zo gekozen dat vol geratel circa 10 pulsen per seconde geeft.
HAPTIC_ENERGY_PER_PULSE = 0.10  # s aan volle-amplitude-equivalent


def decode() -> list[int]:
    raw = subprocess.run(
        ["ffmpeg", "-v", "error", "-i", str(SOURCE), "-ac", "1", "-ar",
         str(RATE), "-f", "s16le", "-"],
        capture_output=True,
        check=True,
    ).stdout
    return list(struct.unpack(f"<{len(raw)//2}h", raw))


def segment(s: list[int], start: float, end: float) -> list[float]:
    lo, hi = int(start * RATE), int(end * RATE)
    return [v / 32768.0 for v in s[lo:hi]]


def crossfade(a: list[float], b: list[float]) -> list[float]:
    """Blijvende join: laatste CROSSFADE seconden van A mengen met de eerste
    van B. De luidheid daalt bij de overgang, en dat is precies de bedoeling:
    de fiets rijdt van je weg."""
    n = int(CROSSFADE * RATE)
    out = a[:-n] if n else a[:]
    for i in range(n):
        t = i / n
        out.append(a[len(a) - n + i] * (1 - t) + b[i] * t)
    return out + b[n:]


def apply_fades(clip: list[float]) -> list[float]:
    fi, fo = int(FADE_IN * RATE), int(FADE_OUT * RATE)
    for i in range(fi):
        clip[i] *= i / fi
    for i in range(fo):
        clip[-(i + 1)] *= i / fo
    return clip


def normalize(clip: list[float]) -> list[float]:
    m = max(abs(v) for v in clip) or 1.0
    return [v * PEAK / m for v in clip]


def measure_haptics(clip: list[float]) -> list[float]:
    """Eén puls per HAPTIC_ENERGY_PER_PULSE seconde gemiddelde-amplitude-som.
    De drempel is aan de gemiddelde hoorbaarheid van de clip zelf gekoppeld,
    niet aan de piek: gemiddeld geeft dat circa 10 pulsen per seconde, en
    luidere passages (de optrek) kruisen de drempel vaker dan stillere (de
    uitrij). De som wordt niet gereset maar verlaagd met de drempel, zodat
    een harde piek de volgende puls juist sneller trekt. Een minimale
    tussenpoes van 70 ms houdt de trillingen fysiek gescheiden: korter voelt
    aan als één zoem in plaats van als een rit."""
    mean_abs = max(sum(abs(v) for v in clip) / len(clip), 1e-4)
    pulses: list[float] = []
    acc = 0.0
    threshold = mean_abs * HAPTIC_ENERGY_PER_PULSE * RATE
    last = -1.0
    for i, v in enumerate(clip):
        acc += abs(v)
        if acc >= threshold and (i / RATE) - last >= 0.07:
            pulses.append(i / RATE)
            last = i / RATE
            acc -= threshold
    return pulses


def write_wav(clip: list[float]) -> None:
    OUT.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(OUT), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(
            struct.pack("<h", max(-32768, min(32767, int(v * 32767))))
            for v in clip
        ))


def main() -> None:
    if not SOURCE.exists():
        sys.exit(f"bronopname ontbreekt: {SOURCE}")
    src = decode()
    a = segment(src, A_START, A_END)
    b = segment(src, B_START, B_END)
    clip = normalize(apply_fades(crossfade(a, b)))
    write_wav(clip)

    pulses = measure_haptics(clip)
    dur = len(clip) / RATE
    print(f"{OUT}: {dur * 1000:.0f} ms, piek {PEAK}")
    print()
    print("Trillingsmomenten (cliptijd in ms):")
    print(", ".join(f"{p * 1000:.0f}" for p in pulses))
    print()
    print("Zelfde momenten als intro-tijd (ms, clip start op 1000):")
    print(", ".join(f"{1000 + p * 1000:.0f}" for p in pulses))


if __name__ == "__main__":
    main()
