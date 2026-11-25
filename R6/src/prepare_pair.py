import mne
import numpy as np
from scipy.io import loadmat

fichier_eeg = r"C:\Users\ettaz\OneDrive\Documents\Labidprojet\VLA_VRW\lab\EEG\1.edf"
fichier_perclos = r"C:\Users\ettaz\OneDrive\Documents\Labidprojet\VLA_VRW\lab\perclos\1.mat"

# Ouvrir les deux fichiers
eeg = mne.io.read_raw_edf(fichier_eeg, preload=False, verbose="ERROR")
perclos = np.asarray(loadmat(fichier_perclos)["perclos"]).ravel()

# Découpage prévu : fenêtres de 8 secondes
frequence = eeg.info["sfreq"]
secondes_a_retirer = 24
duree_fenetre = 8

# Retirer les 24 premières secondes de l'EEG
debut = int(secondes_a_retirer * frequence)
taille_fenetre = int(duree_fenetre * frequence)
fenetres_eeg = (eeg.n_times - debut) // taille_fenetre

# Retirer les 3 premières valeurs PERCLOS : 24 secondes / 8 secondes
perclos = perclos[3:]

# Garder seulement les fenêtres présentes dans les deux fichiers
nombre_final = min(fenetres_eeg, len(perclos))

print("Fenêtres EEG disponibles :", fenetres_eeg)
print("Valeurs PERCLOS après retrait :", len(perclos))
print("Paires EEG-PERCLOS utilisables :", nombre_final)
print("Durée de chaque fenêtre :", duree_fenetre, "secondes")
print("Canaux EEG :", len(eeg.ch_names))