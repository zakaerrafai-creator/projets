# -*- coding: utf-8 -*-
"""
Robot 3D interactif avec sliders pour α β γ
@author: ettaz
"""

import numpy as np
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d import Axes3D
from matplotlib.widgets import Slider

# -----------------------------
# Fonctions utilitaires
# -----------------------------
def deg2rad(x):
    return x * np.pi / 180.0

def rad2deg(x):
    return x * 180.0 / np.pi

# -----------------------------
# Matrice DH
# -----------------------------
def dh_matrix(a, alpha, d, theta):
    ca = np.cos(alpha); sa = np.sin(alpha)
    ct = np.cos(theta); st = np.sin(theta)
    return np.array([
        [ct, -st*ca,  st*sa, a*ct],
        [st,  ct*ca, -ct*sa, a*st],
        [0.0,    sa,     ca,    d ],
        [0.0,  0.0,    0.0,   1.0]
    ])

# -----------------------------
# Cinématique directe
# -----------------------------
def forward_kinematics(dh_table):
    Ts = []
    T = np.eye(4)
    for (a, alpha, d, theta) in dh_table:
        A = dh_matrix(a, alpha, d, theta)
        T = T @ A
        Ts.append(T.copy())
    return Ts, Ts[-1]

# -----------------------------
# Visualisation 3D
# -----------------------------
def plot_robot(ax, joint_positions, R_end):
    ax.cla()  # effacer la figure

    xs = [p[0] for p in joint_positions]
    ys = [p[1] for p in joint_positions]
    zs = [p[2] for p in joint_positions]

    ax.plot(xs, ys, zs, '-o', linewidth=3, markersize=8, color='orange')

    # Axes pinceur
    pe = joint_positions[-1]
    scale = 0.1
    ax.quiver(pe[0], pe[1], pe[2], R_end[0,0], R_end[1,0], R_end[2,0], length=scale, color='r')
    ax.quiver(pe[0], pe[1], pe[2], R_end[0,1], R_end[1,1], R_end[2,1], length=scale, color='g')
    ax.quiver(pe[0], pe[1], pe[2], R_end[0,2], R_end[1,2], R_end[2,2], length=scale, color='b')

    ax.set_xlim(-1,1)
    ax.set_ylim(-1,1)
    ax.set_zlim(0,1)
    ax.set_xlabel('X')
    ax.set_ylabel('Y')
    ax.set_zlabel('Z')
    ax.set_title("Robot 3D interactif")
    ax.set_box_aspect([1,1,1])
    ax.grid(True)
    plt.draw()

# -----------------------------
# Table DH initiale
# -----------------------------
dh_table_base = [
    (0.0, deg2rad(90),  0.1, deg2rad(30)),
    (0.5, deg2rad(0),   0.0, deg2rad(-45)),
    (0.3, deg2rad(0),   0.0, deg2rad(20)),
    (0.0, deg2rad(90),  0.2, deg2rad(0)),
    (0.0, deg2rad(0),   0.05,deg2rad(10)),
]

# -----------------------------
# Setup figure et sliders
# -----------------------------
fig = plt.figure(figsize=(8,6))
ax = fig.add_subplot(111, projection='3d')
plt.subplots_adjust(left=0.1, bottom=0.25)

# Sliders pour alpha, beta, gamma
ax_alpha = plt.axes([0.1, 0.15, 0.8, 0.03])
ax_beta  = plt.axes([0.1, 0.10, 0.8, 0.03])
ax_gamma = plt.axes([0.1, 0.05, 0.8, 0.03])

s_alpha = Slider(ax_alpha, 'α (roll)', -180, 180, valinit=0)
s_beta  = Slider(ax_beta,  'β (pitch)', -180, 180, valinit=0)
s_gamma = Slider(ax_gamma, 'γ (yaw)', -180, 180, valinit=0)

# -----------------------------
# Fonction de mise à jour
# -----------------------------
def update(val):
    alpha_deg = s_alpha.val
    beta_deg  = s_beta.val
    gamma_deg = s_gamma.val

    # Cinématique directe
    Ts, T_end = forward_kinematics(dh_table_base)
    positions = [T[:3,3] for T in Ts]
    R_end = T_end[:3,:3]

    # Rotation globale du bras
    ca, sa = np.cos(deg2rad(alpha_deg)), np.sin(deg2rad(alpha_deg))
    cb, sb = np.cos(deg2rad(beta_deg)), np.sin(deg2rad(beta_deg))
    cg, sg = np.cos(deg2rad(gamma_deg)), np.sin(deg2rad(gamma_deg))

    Rx = np.array([[1,0,0],[0,ca,-sa],[0,sa,ca]])
    Ry = np.array([[cb,0,sb],[0,1,0],[-sb,0,cb]])
    Rz = np.array([[cg,-sg,0],[sg,cg,0],[0,0,1]])

    R_manual = Rz @ Ry @ Rx

    # Appliquer rotation à toutes les articulations
    positions_rot = [R_manual @ p for p in positions]
    R_final = R_manual @ R_end

    plot_robot(ax, positions_rot, R_final)

# -----------------------------
# Connexion sliders
# -----------------------------
s_alpha.on_changed(update)
s_beta.on_changed(update)
s_gamma.on_changed(update)

# Affichage initial
update(0)
plt.show()
