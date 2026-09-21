#!/usr/bin/env python3
"""Genereert de spaaktikken voor de welkomstintro (2026-09-21).

De intro (assets/animations/welcome_ride.webp) heeft wielen zonder spaken en
het bronfilmpje bevat alleen muziek; het spaakgeluid bestaat dus niet en is
verzonnen. Dit script maakt assets/sounds/spoke_tick.wav en spoke_tock.wav:
korte metalige tikken (ongeveer 70 ms) die om en om gespeeld worden, zodat
acht tikken per seconde niet klinkt als een machine maar als een wiel.

Elke tik bestaat uit twee ingredienten:
- een ping: sinuspartials op een inharmonische verhouding (een spaak is geen
  ideale snaar) met exponentiele demping,
- een aanslag: 2 ms vormgegeven ruis die de "tik" maakt.

Bewust deterministisch (vaste seed, geen toeval): het geluid moet
reproduceerbaar zijn, en twee keer draaien hetzelfde bestand opleveren.
Aanpassen kan door de constanten onderaan te wijzigen en dit opnieuw te
draaien; niets wordt handmatig in de wav's geedit.

Gebruik: python3 tool/spoke_tick_sound.py   (vanuit de repo-root)
Vereist alleen de Python-stdlib.
"""

import math
import random
import struct
import wave
from pathlib import Path

RATE = 44100
DURATION = 0.07  # 70 ms: kort genoeg voor 8 tikken per seconde zonder stapelen
OUT_DIR = Path("assets/sounds")

# (bestandsnaam, grondtoon Hz, partialverhouding, partialaandeel, demping tau s, seed)
PRESETS = [
    ("spoke_tick.wav", 2900.0, 2.76, 0.35, 0.018, 20260921),
    ("spoke_tock.wav", 2300.0, 2.90, 0.40, 0.022, 20260922),
]


def render(f0: float, ratio: float, partial: float, tau: float, seed: int) -> list[float]:
    """Een tik als lijst samples in [-1, 1]."""
    rng = random.Random(seed)
    n = int(RATE * DURATION)
    samples = [0.0] * n

    # Ping: grondtoon + een inharmonische boventoon, beide exponentieel dempend.
    for i in range(n):
        t = i / RATE
        env = math.exp(-t / tau)
        samples[i] += math.sin(2 * math.pi * f0 * t) * env
        samples[i] += partial * math.sin(2 * math.pi * f0 * ratio * t) * env

    # Aanslag: 2 ms ruis met snelle demping op de eerste 2 ms van de tik.
    attack = int(RATE * 0.002)
    for i in range(attack):
        t = i / RATE
        samples[i] += (rng.random() * 2 - 1) * math.exp(-t / 0.0006)

    # 1 ms fade-in tegen overstuur, laatste 5 ms uitfaden tegen een knal aan
    # het eind: een tik moet ophouden omdat hij uitgedempt is, niet omdat hij
    # afgekapt is.
    fade_in = int(RATE * 0.001)
    for i in range(fade_in):
        samples[i] *= i / fade_in
    fade_out = int(RATE * 0.005)
    for i in range(fade_out):
        samples[-(i + 1)] *= i / fade_out
    return samples


def normalize(samples: list[float], peak: float = 0.5) -> list[float]:
    """Naar -6 dBFS: zacht genoeg om niet te schrikken, hoorbaar boven papier."""
    m = max(abs(s) for s in samples)
    return [s * peak / m for s in samples]


def write_wav(path: Path, samples: list[float]) -> None:
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        frames = b"".join(
            struct.pack("<h", max(-32768, min(32767, int(s * 32767))))
            for s in samples
        )
        w.writeframes(frames)


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for name, f0, ratio, partial, tau, seed in PRESETS:
        samples = normalize(render(f0, ratio, partial, tau, seed))
        path = OUT_DIR / name
        write_wav(path, samples)
        peak = max(abs(s) for s in samples)
        print(f"{path}: {len(samples) / RATE * 1000:.0f} ms, piek {peak:.2f}")


if __name__ == "__main__":
    main()
