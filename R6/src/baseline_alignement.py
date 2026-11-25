from pathlib import Path
import csv
import numpy as np
from sklearn.linear_model import Ridge
from sklearn.metrics import root_mean_squared_error
from scipy.stats import pearsonr

dossier = Path("results/processed")

def standardiser(X):
    moyenne = X.mean(axis=0)
    ecart_type = X.std(axis=0)
    ecart_type[ecart_type == 0] = 1
    return (X - moyenne) / ecart_type

# Standardiser chaque personne lab, puis les réunir pour l'apprentissage
X_lab = []
y_lab = []

for fichier in sorted(dossier.glob("features_lab_*.npz")):
    donnees = np.load(fichier)
    X_lab.append(standardiser(donnees["X"]))
    y_lab.append(donnees["y"])

X_train = np.concatenate(X_lab)
y_train = np.concatenate(y_lab)

modele = Ridge(alpha=1.0)
modele.fit(X_train, y_train)

# Tester les personnes real une par une
resultats = []

for fichier in sorted(dossier.glob("features_real_*.npz")):
    donnees = np.load(fichier)
    X_test = standardiser(donnees["X"])
    y_test = donnees["y"]

    predictions = modele.predict(X_test)
    rmse = root_mean_squared_error(y_test, predictions)
    correlation = pearsonr(y_test, predictions).statistic

    resultat = [fichier.stem, len(y_test), rmse, correlation]
    resultats.append(resultat)
    print(
        fichier.stem,
        "RMSE :", round(rmse, 3),
        "corrélation :", round(correlation, 3)
    )

with open("results/baseline_alignement.csv", "w", newline="") as fichier:
    ecriture = csv.writer(fichier)
    ecriture.writerow(["sujet", "fenetres", "RMSE", "correlation"])
    ecriture.writerows(resultats)