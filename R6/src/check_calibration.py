from pathlib import Path
import csv
import numpy as np
from sklearn.pipeline import make_pipeline
from sklearn.preprocessing import StandardScaler
from sklearn.linear_model import Ridge
from sklearn.metrics import root_mean_squared_error
from scipy.stats import pearsonr

dossier = Path("results/processed")

def standardiser(X, moyenne=None, ecart_type=None):
    if moyenne is None:
        moyenne = X.mean(axis=0)
    if ecart_type is None:
        ecart_type = X.std(axis=0)
    ecart_type = ecart_type.copy()
    ecart_type[ecart_type == 0] = 1
    return (X - moyenne) / ecart_type

# Modèle sans adaptation : apprend sur les données lab
X_lab = []
y_lab = []
for fichier in sorted(dossier.glob("features_lab_*.npz")):
    d = np.load(fichier)
    X_lab.append(d["X"])
    y_lab.append(d["y"])

modele_sans = make_pipeline(StandardScaler(), Ridge(alpha=1.0))
modele_sans.fit(np.concatenate(X_lab), np.concatenate(y_lab))

# Modèle avec alignement simple : chaque personne lab est standardisée
X_lab_aligne = []
y_lab_aligne = []
for fichier in sorted(dossier.glob("features_lab_*.npz")):
    d = np.load(fichier)
    X_lab_aligne.append(standardiser(d["X"]))
    y_lab_aligne.append(d["y"])

modele_aligne = Ridge(alpha=1.0)
modele_aligne.fit(
    np.concatenate(X_lab_aligne),
    np.concatenate(y_lab_aligne)
)

resultats = []

# Les premières 20 % des fenêtres real servent à l'alignement.
# Les 80 % restantes servent au test.
for fichier in sorted(dossier.glob("features_real_*.npz")):
    d = np.load(fichier)
    X, y = d["X"], d["y"]

    n_calibration = max(1, int(0.2 * len(y)))
    X_cal = X[:n_calibration]
    X_test = X[n_calibration:]
    y_test = y[n_calibration:]

    moyenne = X_cal.mean(axis=0)
    ecart_type = X_cal.std(axis=0)
    X_test_aligne = standardiser(X_test, moyenne, ecart_type)

    pred_sans = modele_sans.predict(X_test)
    pred_aligne = modele_aligne.predict(X_test_aligne)

    rmse_sans = root_mean_squared_error(y_test, pred_sans)
    rmse_aligne = root_mean_squared_error(y_test, pred_aligne)
    corr_sans = pearsonr(y_test, pred_sans).statistic
    corr_aligne = pearsonr(y_test, pred_aligne).statistic

    resultats.append([
        fichier.stem, rmse_sans, corr_sans, rmse_aligne, corr_aligne
    ])
    print(
        fichier.stem,
        "| sans alignement RMSE:", round(rmse_sans, 3),
        "corr:", round(corr_sans, 3),
        "| avec calibration RMSE:", round(rmse_aligne, 3),
        "corr:", round(corr_aligne, 3)
    )

with open("results/calibration_check.csv", "w", newline="") as f:
    ecriture = csv.writer(f)
    ecriture.writerow([
        "sujet", "RMSE_sans", "corr_sans",
        "RMSE_calibration", "corr_calibration"
    ])
    ecriture.writerows(resultats)