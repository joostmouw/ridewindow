#!/usr/bin/env python3
"""Verandert het afspeeltempo van een geanimeerde WebP zonder te hercomprimeren.

De framelengtes staan als losse 3-bytes velden in de ANMF-chunks van het RIFF-
bestand. Die patchen raakt de gecomprimeerde beelddata niet aan, dus het
resultaat is pixel voor pixel identiek aan het origineel — alleen sneller of
langzamer. Dat is het verschil met een ronde door ffmpeg of Pillow, die het
beeld opnieuw zou coderen en scherpte kost die er in het monogram meteen af te
zien is.

    python3 tool/webp_speed.py bron.webp doel.webp 1.5

Het derde argument is de versnelling: 1.5 betekent anderhalf keer zo snel. De
framelengte wordt naar hele milliseconden afgerond, want het formaat kent niets
kleiners; het script meldt wat dat met de totale duur doet.
"""
import struct
import sys


def frame_durations(data: bytes) -> list[int]:
    """De offsets van alle framelengte-velden, plus hun huidige waarde."""
    assert data[:4] == b"RIFF" and data[8:12] == b"WEBP", "geen WebP-bestand"
    offsets = []
    pos = 12
    while pos + 8 <= len(data):
        fourcc = data[pos : pos + 4]
        size = struct.unpack("<I", data[pos + 4 : pos + 8])[0]
        payload = pos + 8
        if fourcc == b"ANMF":
            offsets.append(payload + 12)
        pos = payload + size + (size & 1)  # chunks zijn even uitgelijnd
    return offsets


def main(argv: list[str]) -> int:
    if len(argv) != 4:
        print(__doc__)
        return 64
    src, dst, factor = argv[1], argv[2], float(argv[3])
    if factor <= 0:
        print("De versnelling moet groter dan nul zijn.")
        return 64

    data = bytearray(open(src, "rb").read())
    offsets = frame_durations(bytes(data))
    if not offsets:
        print(f"{src} bevat geen ANMF-chunks — is dit wel een geanimeerde WebP?")
        return 65

    before = after = 0
    for off in offsets:
        old = int.from_bytes(data[off : off + 3], "little")
        new = max(1, round(old / factor))
        data[off : off + 3] = new.to_bytes(3, "little")
        before += old
        after += new

    open(dst, "wb").write(data)
    print(
        f"{len(offsets)} frames  "
        f"{before} ms → {after} ms  "
        f"({before / after:.3f}× gevraagd {factor}×)"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
