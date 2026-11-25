import mne
import numpy as np
from scipy.io import loadmat
from scipy.signal import butter, sosfiltfilt
from pathlib import Path

base = Path(r"C:\Users\ettaz\OneDrive\Documents\Labidprojet\VLA_VRW\real")
fichier_eeg = base / "EEG" / "1.edf"
fichier_perclos = base / "perclos" / "1.mat"

# Lire l'EEG et le PERCLOS
raw = mne.io.read_raw_edf(fichier_eeg, preload=False, verbose="ERROR")
perclos = np.asarray(loadmat(fichier_perclos)["perclos"]).ravel()

# Garder les 18 canaux du montage EEG
electrodes = [
    "Fp1", "Fp2", "F7", "F3", "F4", "Fz", "F8", "T3", "C3",
    "C4", "Cz", "T4", "T5", "P3", "P4", "T6", "O1", "O2"
]
canaux = [
    nom for nom in raw.ch_names
    if any(f"EEG {electrode} " in nom for electrode in electrodes)
]
if len(canaux) != 18:
    raise ValueError(f"Je trouve {len(canaux)} canaux au lieu de 18 : {canaux}")

# Retirer les 24 premières secondes et les 3 premiers labels PERCLOS
frequence = raw.info["sfreq"]
debut = int(24 * frequence)
taille_fenetre = int(8 * frequence)
perclos = perclos[3:]

# Garder le même nombre de fenêtres EEG et de labels
nb_fenetres_eeg = (raw.n_times - debut) // taille_fenetre
nb_fenetres = min(nb_fenetres_eeg, len(perclos))

signal = raw.get_data(
    picks=canaux,
    start=debut,
    stop=debut + nb_fenetres * taille_fenetre
)

# Calculer une caractéristique par canal, bande de fréquence et fenêtre
bandes = {
    "delta": (1, 3),
    "theta": (4, 7),
    "alpha": (8, 13),
    "beta": (14, 30),
    "gamma": (31, 50),
}

fenetres = signal.reshape(18, nb_fenetres, taille_fenetre)
caracteristiques = []

for nom_bande, (bas, haut) in bandes.items():
    filtre = butter(
        4, [bas, haut], btype="bandpass", fs=frequence, output="sos"
    )
    filtre_signal = sosfiltfilt(filtre, signal, axis=1)
    blocs = filtre_signal.reshape(18, nb_fenetres, taille_fenetre)
    variance = np.var(blocs, axis=2)
    de = 0.5 * np.log(2 * np.pi * np.e * variance)
    caracteristiques.append(de.T)

X = np.concatenate(caracteristiques, axis=1)
y = perclos[:nb_fenetres]

# Sauvegarder les caractéristiques dérivées localement
Path("results").mkdir(exist_ok=True)
np.savez("results/features_real_1.npz", X=X, y=y)

print("Fenêtres :", len(y))
print("Forme des caractéristiques :", X.shape)
print("Forme des labels PERCLOS :", y.shape)