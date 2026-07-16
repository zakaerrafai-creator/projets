function [spect, vectfreq] = spectre(fe, t, sd, AFF)
    % Fonction : Cette fonction calcule le spectre d'amplitude d'un signal
    %            s en utilisant la transformée de Fourier rapide (FFT).
    %
    % INPUTS :
    %   - fe  : Fréquence d'échantillonnage (Hz)
    %   - t   : Temps (s)
    %   - s   : Signal temporel 
    %   - AFF : Booléen (1 pour afficher le spectre, 0 sinon)
    %
    % OUTPUTS :
    %   - spect     : Spectre d'amplitude du signal
    %   - vectfreq  : Vecteur des fréquences correspondant au spectre
    %
    % Date : 17/09/2025
    %
    % Exemples d'utilisation :
    %
    % **********************************************************************
    x=sd;

    tfs = abs(fft(x))/fe;
    tfs = tfs(1,1:floor(fe/2));
    tfs = [tfs(1,1),2*tfs(1,2:end)];

    vectfreq = 0:1:floor(fe/2)-1;

    spect = tfs; 

    if AFF == 1
        stem(vectfreq, spect, 'filled', 'LineWidth', 1.2);
        xlabel('Fréquence (Hz)');
        ylabel('Amplitude');
        title('Estimation du spectre d''amplitude via fft');
        grid on;
    end
end
