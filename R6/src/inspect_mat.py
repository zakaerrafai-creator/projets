from scipy.io import loadmat
import numpy as np

fichier = r"C:\Users\ettaz\OneDrive\Documents\Labidprojet\VLA_VRW\real\perclos\1.mat"
donnees = loadmat(fichier)
perclos = np.asarray(donnees["perclos"]).ravel()

print("Nombre de valeurs :", len(perclos))
print("5 premières :", perclos[:5])
print("Minimum :", perclos.min())
print("Maximum :", perclos.max())
print("Valeurs non numériques :", np.sum(~np.isfinite(perclos)))
print("5 dernières :", perclos[-5:])
print("Moyenne :", round(perclos.mean(), 3))
import matplotlib.pyplot as plt

plt.plot(perclos)
plt.xlabel("Numéro de la mesure")
plt.ylabel("PERCLOS")
plt.title("PERCLOS — fichier lab 1")
plt.savefig("results/perclos_lab_1.png")
plt.show()