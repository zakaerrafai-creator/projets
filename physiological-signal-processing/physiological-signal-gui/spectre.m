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
    if nargin < 1 || isempty(fe)
        fe = 1000;
    end

    if nargin < 2 || isempty(t)
        t = 0:1/fe:1;
    end

    if nargin < 3 || isempty(sd)
        % Signal de démonstration si aucun signal n'est fourni.
        sd = sin(2*pi*50*t) + 0.5*sin(2*pi*120*t);
    end

    if nargin < 4 || isempty(AFF)
        AFF = 1;
    end

    x = sd(:).';
    n = length(x);

    if n == 0
        error('Le signal d''entree sd est vide.');
    end

    tfs = abs(fft(x))/n;
    npos = floor(n/2) + 1;
    tfs = tfs(1:npos);

    if npos > 2
        tfs(2:end-1) = 2*tfs(2:end-1);
    end

    vectfreq = (0:npos-1) * (fe/n);

    spect = tfs; %/10;

    if AFF == 1
        stem(vectfreq, spect, 'filled', 'LineWidth', 1.2);
        xlabel('Fréquence (Hz)');
        ylabel('Amplitude');
        title('Estimation du spectre d''amplitude via fft');
        grid on;
    end
end
