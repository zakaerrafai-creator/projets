# Carte de reproductibilité — R6

Statut : **J1, à faire valider par l’enseignant**.
Les données SEED-VLA / SEED-VRW ont été fournies par l’enseignant via FileSender.

## 0. Type de reproduction

**Reproduction partielle, choix provisoire.** Nous utilisons les données SEED-VLA / SEED-VRW de l’article de Luo et al. (2024), mais notre objectif minimal est de comparer un modèle simple sans adaptation et un alignement simple. Nous ne reproduisons pas le modèle CS2DA de l’article.

La fiche R6 initiale mentionne Cao et al. (2019). Le choix des données a été mis à jour par l’enseignant, qui nous a fourni SEED-VLA / SEED-VRW.

## 1. Résultat de référence

- **Où :** article de Luo et al. (2024), tableaux 5 et 6, p. 16.
- **Question :** l’adaptation aide-t-elle à prédire le PERCLOS d’une nouvelle personne en conditions réelles ?
- **Repères publiés :**
  - SVR sans adaptation, modèle source-only : PCC = 0,5236; RMSE = 0,2106.
  - CS2DA avec la règle Max : PCC = 0,6636; RMSE = 0,1365.
- Ces chiffres sont des repères. Ils ne seront pas directement comparables à notre Ridge et à notre alignement simple.

## 2. Données et accès

- **Nom :** SEED-VLA (laboratoire) et SEED-VRW (conditions réelles).
- **Source :** archive FileSender fournie par l’enseignant.
- **Taille observée :** 2,57 Go, 72 fichiers et 6 dossiers.
- **Organisation :** `lab/EEG`, `lab/perclos`, `real/EEG`, `real/perclos`.
- **Effectifs :** 20 enregistrements de laboratoire et 14 enregistrements en conditions réelles.
- **EEG :** fichiers `.edf`, échantillonnage vérifié à 300 Hz.
- **PERCLOS :** fichiers `.mat`, contenant une variable `perclos` de valeurs continues.
- **Fichier ouvert :** `real/EEG/1.edf` et son fichier associé `real/perclos/1.mat`.
- **Licence et diffusion :** usage pédagogique sous les conditions des producteurs. Ne pas redistribuer les données ni les déposer sur un espace public.
- Les données restent hors du dépôt Git. `data/` ne contient que des scripts éventuels.

## 3. Pipeline prévu

| Étape                    | Dans l’article / les données                                                                                                                                                    | Notre choix                                                                                                                                                         |
| ------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Sujets et enregistrements | 20 participants en laboratoire et 14 en conditions réelles. Les durées varient selon les personnes.                                                                             | Utiliser les fichiers appariés par numéro dans `lab` et `real`. Pas d’exclusion prévue à ce stade.                                                         |
| Unité d’observation     | L’article calcule les caractéristiques sur des fenêtres EEG de 8 secondes et extrait les PERCLOS correspondants.                                                               | Une ligne du jeu d’analyse = une fenêtre de 8 secondes.                                                                                                           |
| Cible et labels           | PERCLOS continu, compris entre 0 et 1, calculé à partir du suivi oculaire.                                                                                                      | Prédire la valeur PERCLOS associée à chaque fenêtre.                                                                                                            |
| Début et synchronisation | Les notes accompagnant les données recommandent de retirer la période initiale, par exemple les 24 premières secondes, et de tronquer les signaux à la durée la plus courte. | Retirer les 24 premières secondes de l’EEG et les trois premières valeurs PERCLOS, puis garder le nombre de fenêtres appariées.                                |
| Canaux                    | L’article décrit 18 électrodes EEG à 300 Hz. Les fichiers EDF contiennent aussi des canaux supplémentaires, dont `Trigger`.                                                | Utiliser les 18 électrodes décrites dans l’article. Vérifier les noms de canaux dans chaque fichier.                                                            |
| Caractéristiques         | L’article calcule des caractéristiques DE dans cinq bandes : delta (1–3 Hz), theta (4–7 Hz), alpha (8–13 Hz), beta (14–30 Hz), gamma (31–50 Hz), sur des fenêtres de 8 s. | Calculer 90 caractéristiques par fenêtre (18 canaux × 5 bandes). Notre script calcule la DE à partir de la variance du signal filtré par bande.                |
| Modèle                   | L’article compare notamment SVR et CS2DA.                                                                                                                                        | Baseline minimale : Ridge (`alpha=1.0`), sans adaptation; comparaison avec un alignement simple des caractéristiques.                                            |
| Apprentissage / test      | L’article évalue les modèles sur les personnes réelles laissées à tester.                                                                                                   | Entraîner sur `lab`, puis évaluer les personnes `real` individuellement. Pour l’alignement complet, utiliser seulement les EEG `real`, sans leurs PERCLOS. |
| Métriques                | L’article rapporte PCC et RMSE.                                                                                                                                                  | Calculer RMSE et corrélation de Pearson pour chaque personne, puis résumer par personne.                                                                          |

### Écarts de méthode à déclarer

- Notre modèle Ridge ne reproduit pas le SVR ni le CS2DA de l’article.
- Notre alignement simple ne reproduit pas la méthode d’adaptation CS2DA.
- Le traitement de la période initiale de 24 secondes vient des notes accompagnant les données; l’article décrit les fenêtres de 8 secondes, mais pas ce retrait de 24 secondes.
- Le calcul des caractéristiques DE suit les cinq bandes et les fenêtres de 8 secondes de l’article, avec une implémentation simplifiée.

## 4. Ce qui ne doit pas passer de l’apprentissage au test

- Les valeurs PERCLOS des personnes `real` ne doivent pas servir à l’alignement non supervisé.
- Le modèle sans adaptation est entraîné sur `lab`; les labels PERCLOS `real` sont réservés à l’évaluation.
- Pour l’essai avec calibration non étiquetée, seules les caractéristiques EEG des 20 % premières fenêtres servent à l’alignement; les 80 % restantes servent au test.
- Pour l’extension supervisée, les PERCLOS des 20 % premières fenêtres sont utilisés pour entraîner/calibrer le modèle; les PERCLOS des 80 % restantes sont réservés au test.
- Les réglages du modèle ne doivent pas être choisis en regardant les scores finaux `real`.

**Faiblesse à vérifier :** si l’alignement utilise toute la série EEG `real`, les caractéristiques EEG de la période de test ont aussi servi à calculer la normalisation. Elles sont non étiquetées, mais le protocole suppose que la série complète est disponible avant la prédiction. L’essai avec 20 % de calibration teste une situation plus réaliste où seule une première partie est disponible.

## 5. Première baseline et temps de calcul

- **Première baseline choisie :** Ridge sans adaptation, entraîné sur les personnes `lab`, puis évalué sur les personnes `real`.
- **Comparaison prévue :** Ridge avec alignement simple des caractéristiques EEG.
- **Temps de calcul :** à mesurer et à noter lors de la première exécution sur un enregistrement.
- **Dépôt Git :** créé localement; les données ne sont pas incluses.

## 6. Jalons suivants

- **J2 :** exploration des données, pipeline et première baseline.
- **J3 :** tableau comparant les références de l’article à nos résultats; explication des écarts.
- **J4 :** test expérimental d’une faiblesse du protocole et extension préenregistrée.
- **J5 :** rapport, figures et dépôt reproductible.

## 7. Plan B

Si l’alignement ou le calcul d’un modèle plus complexe bloque, conserver l’objectif minimal : comparer Ridge sans adaptation à un alignement simple, avec validation par personne et sans utiliser les labels de test pendant l’adaptation.
