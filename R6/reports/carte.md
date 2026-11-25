# Carte de reproductibilité — R6

## Données

- Nom : SEED-VLA / SEED-VRW
- Taille : 2,57 Go (2 763 328 444 octets)
- Contenu : 72 fichiers, 6 dossiers
- Conditions : usage pédagogique, ne pas redistribuer

## Préparation

- Retirer les 24 premières secondes : à faire
- Synchroniser EEG et PERCLOS : à faire
- Fichier EEG ouvert avec MNE : à faire
- Fichier lab 1 vérifié : 597 valeurs PERCLOS, toutes numériques.
  Graphique créé : results/perclos_lab_1.png
  Intervalle entre les valeurs : à déterminer.

Premier essai : modèle entraîné sur lab, testé sur real.
Sans alignement : RMSE moyen ≈ 0,183 ; corrélation moyenne ≈ 0,235.
Avec alignement : RMSE moyen ≈ 0,176 ; corrélation moyenne ≈ 0,251.
L’alignement utilise les EEG real sans leurs labels PERCLOS.
