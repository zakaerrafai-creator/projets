import mne

fichier = r"C:\Users\ettaz\OneDrive\Documents\Labidprojet\VLA_VRW\real\EEG\1.edf"
eeg = mne.io.read_raw_edf(fichier, preload=False, verbose="ERROR")

print("Canaux :", eeg.ch_names)
print("Fréquence :", eeg.info["sfreq"], "Hz")
print("Durée :", round(eeg.times[-1], 1), "secondes")