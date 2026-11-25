from pathlib import Path
import csv
import matplotlib.pyplot as plt

def lire_csv(chemin):
    with open(chemin, newline="", encoding="utf-8") as f:
        return {ligne["sujet"]: ligne for ligne in csv.DictReader(f)}

sans = lire_csv("results/baseline_sans_adaptation.csv")
aligne = lire_csv("results/baseline_alignement.csv")

sujets = sorted(sans, key=lambda nom: int(nom.split("_")[-1]))
x = range(len(sujets))

fig, axes = plt.subplots(2, 1, figsize=(11, 8), sharex=True)

for ax, mesure, titre in [
    (axes[0], "RMSE", "Erreur RMSE (plus bas = mieux)"),
    (axes[1], "correlation", "Corrélation de Pearson (plus haut = mieux)")
]:
    valeurs_sans = [float(sans[s][mesure]) for s in sujets]
    valeurs_aligne = [float(aligne[s][mesure]) for s in sujets]

    ax.plot(x, valeurs_sans, marker="o", label="Sans adaptation")
    ax.plot(x, valeurs_aligne, marker="o", label="Alignement simple")
    ax.set_ylabel(titre)
    ax.grid(True, alpha=0.3)
    ax.legend()

axes[1].set_xticks(list(x))
axes[1].set_xticklabels(
    [s.split("_")[-1] for s in sujets],
    rotation=0
)
axes[1].set_xlabel("Personne real")

fig.suptitle("Prédiction du PERCLOS : lab vers real")
fig.tight_layout()

Path("results/figures").mkdir(parents=True, exist_ok=True)
fig.savefig("results/figures/comparaison_methodes.png", dpi=150)
plt.show()