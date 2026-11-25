from pathlib import Path
import mne
import numpy as np
from scipy.io import loadmat
from scipy.signal import butter, sosfiltfilt

base = Path(r"C:\Users\ettaz\OneDrive\Documents\Labidprojet\VLA_VRW")
electrodes = [
    "Fp1", "Fp2", "F7", "F3", "F4", "Fz", "F8", "T3", "C3",
    "C4", "Cz", "T4", "T5", "P3", "P4", "T6", "O1", "O2"
]
bandes = {
    "delta": (1, 3), "theta": (4, 7), "alpha": (8, 13),
    "beta": (14, 30), "gamma": (31, 50)
}

sortie = Path("results/processed")
sortie.mkdir(parents=True, exist_ok=True)

for scenario in ("lab", "real"):
    fichiers = sorted(
        (base / scenario / "EEG").glob("*.edf"),
        key=lambda p: int(p.stem)
    )

    for fichier_eeg in fichiers:
        fichier_mat = base / scenario / "perclos" / f"{fichier_eeg.stem}.mat"
        if not fichier_mat.exists():
            print("PERCLOS manquant :", scenario, fichier_eeg.stem)
            continue

        raw = mne.io.read_raw_edf(fichier_eeg, preload=False, verbose="ERROR")
        canaux = [
            nom for nom in raw.ch_names
            if any(f"EEG {e} " in nom for e in electrodes)
        ]
        if len(canaux) != 18:
            print("Canaux inattendus :", scenario, fichier_eeg.stem, canaux)
            continue

        perclos = np.asarray(loadmat(fichier_mat)["perclos"]).ravel()[3:]

        frequence = raw.info["sfreq"]
        debut = int(24 * frequence)
        taille = int(8 * frequence)
        nb_eeg = (raw.n_times - debut) // taille
        nb = min(nb_eeg, len(perclos))

        signal = raw.get_data(
            picks=canaux,
            start=debut,
            stop=debut + nb * taille
        )

        caracteristiques = []
        for bas, haut in bandes.values():
            filtre = butter(
                4, [bas, haut], btype="bandpass",
                fs=frequence, output="sos"
            )
            filtre_signal = sosfiltfilt(filtre, signal, axis=1)
            blocs = filtre_signal.reshape(18, nb, taille)
            variance = np.var(blocs, axis=2)
            de = 0.5 * np.log(2 * np.pi * np.e * variance)
            caracteristiques.append(de.T)

        X = np.concatenate(caracteristiques, axis=1)
        y = perclos[:nb]
        nom_sortie = sortie / f"features_{scenario}_{fichier_eeg.stem}.npz"
        np.savez(nom_sortie, X=X, y=y)

        print(scenario, fichier_eeg.stem, "fenêtres :", nb, "forme :", X.shape)