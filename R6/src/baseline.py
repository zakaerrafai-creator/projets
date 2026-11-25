from pathlib import Path
import csv
import numpy as np
from sklearn.pipeline import make_pipeline
from sklearn.preprocessing import StandardScaler
from sklearn.linear_model import Ridge
from sklearn.metrics import root_mean_squared_error
from scipy.stats import pearsonr

dossier = Path("results/processed")
fichiers_lab = sorted(dossier.glob("features_lab_*.npz"))
fichiers_real = sorted(dossier.glob("features_real_*.npz"))

# Entraîner sur toutes les personnes du laboratoire
X_lab = []
y_lab = []

for fichier in fichiers_lab:
    donnees = np.load(fichier)
    X_lab.append(donnees["X"])
    y_lab.append(donnees["y"])

X_train = np.concatenate(X_lab)
y_train = np.concatenate(y_lab)

modele = make_pipeline(StandardScaler(), Ridge(alpha=1.0))
modele.fit(X_train, y_train)

# Tester séparément sur chaque personne en conditions réelles
resultats = []

for fichier in fichiers_real:
    donnees = np.load(fichier)
    X_test = donnees["X"]
    y_test = donnees["y"]
    predictions = modele.predict(X_test)

    rmse = root_mean_squared_error(y_test, predictions)
    correlation = pearsonr(y_test, predictions).statistic

    resultat = [fichier.stem, len(y_test), rmse, correlation]
    resultats.append(resultat)
    print(
        fichier.stem,
        "fenêtres :", len(y_test),
        "RMSE :", round(rmse, 3),
        "corrélation :", round(correlation, 3)
    )

# Enregistrer les résultats
with open("results/baseline_sans_adaptation.csv", "w", newline="") as fichier:
    ecriture = csv.writer(fichier)
    ecriture.writerow(["sujet", "fenetres", "RMSE", "correlation"])
    ecriture.writerows(resultats)