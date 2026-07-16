# TP2 - Detection et suivi de mouvement

Ce dossier contient une solution MATLAB pour le sujet `TP2 detection et suivi de mouvement` a partir des images `PIETON*.bmp`.

## Ce que fait le script

- charge les images de la sequence,
- cree la video `PIETON_sequence.avi`,
- estime un fond par mediane,
- segmente les pietons par difference avec le fond et morphologie,
- suit automatiquement les objets mobiles par centres de masse,
- genere une video annotee et l'image finale des trajectoires.

## Execution

Dans MATLAB, place-toi dans ce dossier puis lance :

```matlab
tp2_pieton
```

Le script ecrit ses sorties dans le dossier `sorties_tp2`.

## Sorties generees

- `PIETON_sequence.avi`
- `PIETON_tracking.avi`
- `PIETON_masques.gif`
- `PIETON_trajectoires_finales.png`
- `PIETON_fond_estime.png`
- `masques\`
- `frames_suivies\`

## Prerequis

Le script utilise les fonctions standard MATLAB et les operations de morphologie de l'Image Processing Toolbox.