
# Projet R6 — Adaptation entre sujets

## Objectif

Prédire les valeurs PERCLOS à partir de l’EEG, puis comparer un modèle sans adaptation avec un alignement simple et une calibration.

## Données

Les données SEED-VLA / SEED-VRW sont fournies par l’enseignant. Elles restent dans `Labidprojet/VLA_VRW` et ne sont pas incluses dans ce dépôt. Ne pas les redistribuer ni les publier.

## Préparation effectuée

- Retrait des 24 premières secondes.
- Fenêtres EEG de 8 secondes.
- Retrait des 3 premières valeurs PERCLOS.
- Calcul des caractéristiques DE sur 18 canaux et 5 bandes de fréquence.
- Les caractéristiques calculées sont enregistrées dans `results/processed/`, ignoré par Git.

## Installation

Avec Python installé, installer les bibliothèques nécessaires :

    python -m pip install mne scipy numpy scikit-learn matplotlib

## Relancer les analyses

Depuis le dossier `projet_R6`, exécuter dans cet ordre :

    python src/extract_all.py
    python src/baseline.py
    python src/baseline_alignement.py
    python src/check_calibration.py
    python src/extension_calibration.py
    python src/plot_comparison.py

Les scripts `baseline.py`, `baseline_alignement.py` et `check_calibration.py` produisent les résultats des premières comparaisons. `extension_calibration.py` teste l’extension avec les labels PERCLOS du début. `plot_comparison.py` crée la figure des deux méthodes de base.

## Versions utilisées

À compléter avec les versions de Python et des bibliothèques installées.
