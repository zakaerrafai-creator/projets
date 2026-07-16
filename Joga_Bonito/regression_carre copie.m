function regression_carre(spectre_carre)
%***********************************************************************
% Fonction : regression_carre
%
% OBJECTIF :
% A partir du spectre du signal carré :
%   1. Extraire les amplitudes aux indices 4,10,16,22,28,34,40,46
%   2. n1 et n2 sont les points de base de la droite initiale
%   3. Boucle while (phase 1) : prédire, comparer (seuil 90%)
%      - < 90% : recalculer la droite sur les 2 derniers vrais points
%      - >= 90% : seuil atteint, on passe en phase 2
%   4. Phase 2 : on continue de prédire TOUS les points suivants
%      en utilisant uniquement la dernière valeur prédite (plus de vraies valeurs)
%
% INPUT :
%   ans: vecteur du spectre d'amplitude du signal carré
%
%***********************************************************************

idx_harm = [4, 10, 16, 22, 28, 34, 40, 46];
v_clean  = spectre_carre(idx_harm);

n_a = 1;  amp_a = v_clean(1);
n_b = 2;  amp_b = v_clean(2);

p = polyfit(log([n_a, n_b]), log([amp_a, amp_b]), 1);

fprintf('Droite initiale : n%d (amp=%.4f) et n%d (amp=%.4f)\n', ...
    n_a, amp_a, n_b, amp_b);
fprintf('Pente = %.4f (attendu ~-1)\n\n', p(1));

i               = 3;
seuil_ok        = false;
n_pred          = [];
vals_pred_graph = [];

fprintf('%-6s %-15s %-15s %-15s %-10s\n', ...
    'n', 'Valeur réelle', 'Valeur prédite', 'Correspondance', 'Action');

while i <= length(v_clean)

    val_predite = exp(polyval(p, log(i)));

    n_pred          = [n_pred, i];
    vals_pred_graph = [vals_pred_graph, val_predite];

    if ~seuil_ok
        val_reelle     = v_clean(i);
        correspondance = 1 - abs(val_predite - val_reelle) / val_reelle;

        fprintf('%-6d %-15.6f %-15.6f %-14.2f%%', ...
            i, val_reelle, val_predite, correspondance*100);

        if correspondance >= 0.90
            fprintf(' Seuil atteint → prédictions pures\n');
            seuil_ok = true;
            n_b   = i;    amp_b = val_predite;
            p     = polyfit(log([n_a, n_b]), log([amp_a, amp_b]), 1);
        else
            fprintf(' Remplacée → droite recalculée sur n%d et n%d\n', n_b, i);
            n_a   = n_b;    amp_a = amp_b;
            n_b   = i;      amp_b = val_reelle;
            p     = polyfit(log([n_a, n_b]), log([amp_a, amp_b]), 1);
        end

    else
        fprintf('%-6d %-15s %-15.6f %-14s %-10s\n', ...
            i, '(non utilisée)', val_predite, '-', 'Prédite pure');
        n_a   = n_b;    amp_a = amp_b;
        n_b   = i;      amp_b = val_predite;
        p     = polyfit(log([n_a, n_b]), log([amp_a, amp_b]), 1);
    end

    i = i + 1;
end

n_vals = 1:length(v_clean);

n_cont    = linspace(1, length(v_clean), 200);
droite    = exp(polyval(p, log(n_cont)));

figure;
hold on;

stem(n_vals, v_clean,        'r', 'filled', 'DisplayName', 'Spectre réel');
stem([1 2],  v_clean(1:2),   'g', 'filled', 'DisplayName', 'Points de base (n1, n2)');
stem(n_pred, vals_pred_graph,'b', 'filled', 'DisplayName', 'Valeurs prédites');
plot(n_cont, droite, 'w--',  'LineWidth', 1.2, 'DisplayName', 'Droite de régression');

xlabel('Numéro harmonique');
ylabel('Amplitude');
title('Régression sur le spectre du signal carré');
legend show;
grid on;

end