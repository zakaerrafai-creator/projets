function [spectre_carre] = fou(h,P)
%***********************************************************************
% Fonction : fou
%
% OBJECTIF :
% Générer et analyser plusieurs signaux périodiques via leur série de
% Fourier :
%   - carré
%   - triangle
%   - dent de scie
%   - arche
%
% La fonction affiche :
%   - les signaux temporels
%   - les spectres (FFT)
%   - la reconstruction harmonique cumulative 3D
%   - une amélioration du signal par extrapolation harmonique
%
% INPUTS :
%   h : nombre d'harmoniques
%   P : période du signal
%
% EXEMPLES :
%   fou(5,1)
%   fou(10,1)
%***********************************************************************

Fe = 100;
nbP = 3;

t = 0:1/Fe:nbP*P;

f0 = 1/P;

%% Initialisation

carre = zeros(size(t));
triangle = zeros(size(t));
dent = zeros(size(t));
arche = zeros(size(t));

carre_mat = zeros(h,length(t));
triangle_mat = zeros(h,length(t));
dent_mat = zeros(h,length(t));
arche_mat = zeros(h,length(t));

%% Signal carré

temp = zeros(size(t));

for n=1:h
    k = 2*n-1;
    temp = temp + (4/pi)*(1/k)*sin(2*pi*k*f0*t);
    carre_mat(n,:) = temp;
end

carre = temp;

%% Signal triangle

temp = zeros(size(t));

for n=1:h
    k = 2*n-1;
    temp = temp + (8/pi^2)*(1/(k^2))*(-1)^(n-1)*sin(2*pi*k*f0*t);
    triangle_mat(n,:) = temp;
end

triangle = temp;

%% Signal dent de scie

temp = zeros(size(t));

for n=1:h
    temp = temp - (2/pi)*(1/n)*sin(2*pi*n*f0*t);
    dent_mat(n,:) = temp;
end

dent = temp;

%% Signal arche

temp = (2/pi) * ones(size(t));
arche_mat = zeros(h, length(t));

for n = 1:h
    temp = temp - (4/pi) * (1/(4*n^2 - 1)) * cos(4*pi*n*f0*t);
    arche_mat(n,:) = temp;
end
arche = temp;

%% Affichage des signaux

figure

subplot(2,2,1)
plot(t,carre)
title('Signal carré')
grid on

subplot(2,2,2)
plot(t,triangle)
title('Signal triangle')
grid on

subplot(2,2,3)
plot(t,dent)
title('Signal dent de scie')
grid on

subplot(2,2,4)
plot(t,arche)
title('Signal arche')
grid on

%% Spectres

figure

subplot(2,2,1)
[spectre_carre, freq_carre] = spectre(Fe, t, carre, 1);
title('Spectre carré')

subplot(2,2,2)
spectre(Fe,t,triangle,1)
title('Spectre triangle')

subplot(2,2,3)
spectre(Fe,t,dent,1)
title('Spectre dent de scie')

subplot(2,2,4)
spectre(Fe,t,arche,1)
title('Spectre arche')

%% Reconstruction 3D

figure

subplot(2,2,1)
mesh(t,1:h,carre_mat)
title('Reconstruction 3D carré')
xlabel('Temps')
ylabel('Harmoniques')
zlabel('Amplitude')

subplot(2,2,2)
mesh(t,1:h,triangle_mat)
title('Reconstruction 3D triangle')
xlabel('Temps')
ylabel('Harmoniques')
zlabel('Amplitude')

subplot(2,2,3)
mesh(t,1:h,dent_mat)
title('Reconstruction 3D dent de scie')
xlabel('Temps')
ylabel('Harmoniques')
zlabel('Amplitude')

subplot(2,2,4)
mesh(t,1:h,arche_mat)
title('Reconstruction 3D arche')
xlabel('Temps')
ylabel('Harmoniques')
zlabel('Amplitude')

end