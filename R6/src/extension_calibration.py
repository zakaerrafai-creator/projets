from pathlib import Path
import csv
import numpy as np
from sklearn.preprocessing import StandardScaler
from sklearn.linear_model import Ridge
from sklearn.metrics import root_mean_squared_error
from scipy.stats import pearsonr

dossier = Path("results/processed")

# Charger les données lab pour entraîner le modèle de base
X_lab = []
y_lab = []

for fichier in sorted(dossier.glob("features_lab_*.npz")):
    d = np.load(fichier)
    X_lab.append(d["X"])
    y_lab.append(d["y"])

X_lab = np.concatenate(X_lab)
y_lab = np.concatenate(y_lab)

# La normalisation est apprise uniquement sur lab
scaler = StandardScaler()
X_lab = scaler.fit_transform(X_lab)

resultats = []

for fichier in sorted(dossier.glob("features_real_*.npz")):
    d = np.load(fichier)
    X = scaler.transform(d["X"])
    y = d["y"]

    # Début pour calibration, fin pour évaluation
    n_cal = max(1, int(0.2 * len(y)))
    X_cal, y_cal = X[:n_cal], y[:n_cal]
    X_test, y_test = X[n_cal:], y[n_cal:]

    # Modèle sans calibration : entraîné sur lab seulement
    modele_base = Ridge(alpha=1.0)
    modele_base.fit(X_lab, y_lab)
    pred_base = modele_base.predict(X_test)

    # Modèle calibré : lab + début étiqueté de la personne real
    modele_cal = Ridge(alpha=1.0)
    modele_cal.fit(
        np.concatenate([X_lab, X_cal]),
        np.concatenate([y_lab, y_cal])
    )
    pred_cal = modele_cal.predict(X_test)

    rmse_base = root_mean_squared_error(y_test, pred_base)
    corr_base = pearsonr(y_test, pred_base).statistic
    rmse_cal = root_mean_squared_error(y_test, pred_cal)
    corr_cal = pearsonr(y_test, pred_cal).statistic

    resultats.append([
        fichier.stem, rmse_base, corr_base, rmse_cal, corr_cal
    ])

    print(
        fichier.stem,
        "| sans calibration RMSE:", round(rmse_base, 3),
        "corr:", round(corr_base, 3),
        "| avec calibration RMSE:", round(rmse_cal, 3),
        "corr:", round(corr_cal, 3)
    )

# Enregistrer les résultats par personne
with open("results/extension_calibration.csv", "w", newline="") as f:
    ecriture = csv.writer(f)
    ecriture.writerow([
        "sujet", "RMSE_sans", "corr_sans",
        "RMSE_calibration", "corr_calibration"
    ])
    ecriture.writerows(resultats)

# Afficher les moyennes, chaque personne ayant le même poids
r = np.array([ligne[1:] for ligne in resultats], dtype=float)
print("Moyennes sur les personnes :")
print("Sans calibration — RMSE:", round(r[:, 0].mean(), 3),
      "corr:", round(r[:, 1].mean(), 3))
print("Avec calibration — RMSE:", round(r[:, 2].mean(), 3),
      "corr:", round(r[:, 3].mean(), 3))