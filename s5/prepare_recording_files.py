#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Sukuria ground-truth .txt failus IR padalina i train/test pogrupius.

Naudojimas:
    python3 prepare_recording_files.py [SAKINIU_FAILAS] [ISVESTIES_DIR]

Numatyti keliai:
    SAKINIU_FAILAS = mano_garso_irasai/medicinos_sakiniai.txt
    ISVESTIES_DIR  = mano_garso_irasai/

REZULTATAS (jeigu 150 sakiniu):
    mano_garso_irasai/
      train/
        irasas_001.txt - irasas_120.txt   (80% TRAIN, MAP adaptacijai)
      test/
        irasas_121.txt - irasas_150.txt   (20% TEST, 4.7 evaluation)

Komentarai (eilutes prasidedancios "#") ir tuscios eilutes - praleistos.
"""

import os
import sys

DEFAULT_INPUT = "mano_garso_irasai/medicinos_sakiniai.txt"
DEFAULT_OUTPUT_DIR = "mano_garso_irasai"
TRAIN_RATIO = 0.80  # 80% train, 20% test


def main():
    src = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_INPUT
    base = sys.argv[2] if len(sys.argv) > 2 else DEFAULT_OUTPUT_DIR

    if not os.path.isfile(src):
        print(f"KLAIDA: nera failo {src}")
        sys.exit(1)

    sentences = []
    with open(src, encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            sentences.append(line)

    if not sentences:
        print(f"KLAIDA: faile {src} nera sakiniu")
        sys.exit(1)

    train_dir = os.path.join(base, "train")
    test_dir = os.path.join(base, "test")
    os.makedirs(train_dir, exist_ok=True)
    os.makedirs(test_dir, exist_ok=True)

    n_total = len(sentences)
    n_train = int(n_total * TRAIN_RATIO)
    n_test = n_total - n_train

    print(f"Rasta {n_total} sakiniu")
    print(f"  TRAIN: {n_train} (~{TRAIN_RATIO*100:.0f}%)")
    print(f"  TEST:  {n_test} (~{(1-TRAIN_RATIO)*100:.0f}%)")
    print()

    for i, s in enumerate(sentences, start=1):
        name = f"irasas_{i:03d}"
        if i <= n_train:
            path = os.path.join(train_dir, f"{name}.txt")
        else:
            path = os.path.join(test_dir, f"{name}.txt")
        with open(path, "w", encoding="utf-8") as f:
            f.write(s + "\n")

    print(f"BAIGTA. Sukurta:")
    print(f"  {train_dir}/  - {n_train} txt failai")
    print(f"  {test_dir}/   - {n_test} txt failai")
    print()
    print("Tolimesni zingsniai:")
    print(f"  1. TRAIN: irasykite irasas_001.wav .. irasas_{n_train:03d}.wav")
    print(f"     Saugokite {train_dir}/")
    print(f"     Naudosis MAP akustines adaptacijai.")
    print()
    print(f"  2. TEST: irasykite irasas_{n_train+1:03d}.wav .. irasas_{n_total:03d}.wav")
    print(f"     Saugokite {test_dir}/")
    print(f"     Naudosis 4.7 skyriaus WER skaiciavimui.")
    print()
    print("KRITISKA: train ir test sakiniai turi buti ATSKIRI grupiu rinkiniai.")


if __name__ == "__main__":
    main()
