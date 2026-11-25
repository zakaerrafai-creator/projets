
# Extension : calibration avec quelques labels

## Hypothèse

Utiliser les premières mesures PERCLOS d’une personne améliore la prédiction de sa fatigue sur la suite de son enregistrement.

## Changement testé

Pour chaque personne real, utiliser les 20 % premières fenêtres et leurs labels PERCLOS pour calibrer le modèle. Évaluer ensuite sur les 80 % restantes.

## Comparaison

Comparer avec le modèle sans adaptation, entraîné uniquement sur les données lab. Garder le même découpage pour les 14 personnes real.

## Mesures

Calculer le RMSE et la corrélation de Pearson pour chaque personne, puis leur moyenne sur les 14 personnes.

## Règle de conclusion

L’extension semble utile si le RMSE moyen diminue et si la corrélation moyenne augmente. Sinon, conclure que cette calibration n’apporte pas d’amélioration nette.


## Résultats

La calibration avec les labels PERCLOS des 20 % premières fenêtres réduit légèrement le RMSE moyen (0,188 à 0,185) et augmente la corrélation moyenne (0,209 à 0,228) sur les 80 % restantes. L’effet varie selon les personnes et n’est pas toujours positif.
