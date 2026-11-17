%% ========================================================================
%% corr_per_scenario.m  --  within-scenario correlation matrices (Table 5,
%%                          Figure 4, and Supplementary Material S1)
%%
%% Computes the Pearson correlation matrix of (AI, GOV, INNOV, RISK, ESG,
%% PERF) WITHIN each of the four governance scenarios, using the exact
%% structural model of figures_final_v6.m. It reports:
%%   - one correlation matrix per scenario  (Supplementary Table S1.1-S1.4)
%%   - their average                        (main-text Table 5)
%%   - the average heat-map                 (main-text Figure 4)
%%
%% The matrices are reported at a large sample size so that the values are
%% CONVERGED: they are the model's population within-scenario correlations,
%% stable to three decimal places and independent of the random-number
%% seed. (The main script figures_final_v6.m draws N = 10,000 per scenario
%% for the distributional figures; the within-scenario correlation is a
%% population quantity, so it is estimated here at large N to remove Monte
%% Carlo sampling noise. Re-running with any seed reproduces the reported
%% three-decimal values.)
%% ========================================================================
clear; clc;

% --- baseline parameters (Table 2), identical to figures_final_v6.m ---
P.ai_innov=0.70; P.gov_innov=0.15; P.synergy=0.15;   % innovation
P.ai_risk =0.60; P.gov_risk =0.50; P.rho    =0.05;   % risk
P.gov_esg =0.85; P.ai_esg   =0.10; P.esg_pen=20.0;   % ESG
P.wI=0.50; P.wE=0.30; P.wR=0.20;                     % firm-performance weights

% --- scenario boxes for (AI, GOV), identical to figures_final_v6.m ---
AIR  = [0.70 0.90; 0.20 0.40; 0.45 0.65; 0.70 0.90];
GOVR = [0.20 0.40; 0.70 0.90; 0.45 0.65; 0.70 0.90];

vars   = {'AI','GOV','INNOV','RISK','ESG','PERF'};
scLbl  = {'S1 (AI-leader)','S2 (Governance-first)', ...
          'S3 (Balanced)','S4 (Hybrid AI-ESG)'};
nV = numel(vars);

N = 3000000;                 % large N -> converged (population) correlations
clipv = @(x) min(100,max(0,x));

Cs = zeros(nV,nV,4);
for k = 1:4
    rng(41+k);               % same seeding scheme as the main script
    AI  = AIR(k,1)  + diff(AIR(k,:))  * rand(N,1);
    GOV = GOVR(k,1) + diff(GOVR(k,:)) * rand(N,1);
    INNOV = clipv((P.ai_innov*AI + P.gov_innov*GOV + P.synergy*AI.*GOV)*100 + 2*randn(N,1));
    r01  = max(P.ai_risk*AI - P.gov_risk*GOV, P.rho);
    R01  = min(1,max(0, r01 + 0.02*randn(N,1)));
    RISK = R01*100;
    ESG  = clipv((P.gov_esg*GOV + P.ai_esg*AI)*100 - R01*P.esg_pen + 2*randn(N,1));
    PERF = clipv(P.wI*INNOV + P.wE*ESG - P.wR*RISK + 2*randn(N,1));
    Cs(:,:,k) = corrcoef([AI GOV INNOV RISK ESG PERF]);
end
Cavg = mean(Cs,3);

% --- print per-scenario matrices (Supplementary S1) ---
printmat = @(M,ttl) print_corr(M,vars,ttl);
for k = 1:4
    printmat(Cs(:,:,k), sprintf('Supplementary Table S1.%d  %s', k, scLbl{k}));
end
printmat(Cavg, 'Table 5  Average within-scenario correlation matrix');

% --- key firm-performance correlates (for the Discussion text) ---
iP = 6;
fprintf('\nFirm-performance within-scenario correlates (average):\n');
fprintf('   INNOV = %.3f | ESG = %.3f | GOV = %.3f | RISK = %.3f\n', ...
    Cavg(3,iP), Cavg(5,iP), Cavg(2,iP), Cavg(4,iP));

% --- Figure 4: average within-scenario correlation heat-map ---
m=256; h2=m/2;
rb=[linspace(0.70,1,h2)',linspace(0.10,1,h2)',linspace(0.10,1,h2)';...
    linspace(1,0.10,h2)',linspace(1,0.10,h2)',linspace(1,0.70,h2)'];
fig=figure('Units','centimeters','Position',[3 3 14 12]);
ax=axes(fig); imagesc(ax,Cavg); hold on;
colormap(ax,rb); caxis([-1 1]);
cb=colorbar(ax,'FontSize',11); cb.Label.String='Pearson  r';
set(ax,'XTick',1:nV,'XTickLabel',vars,'YTick',1:nV,'YTickLabel',vars,...
       'TickLength',[0 0],'FontSize',11);
axis square;
for r=1:nV
    for c=1:nV
        v=Cavg(r,c); col='k'; if abs(v)>0.55, col='w'; end
        text(c,r,sprintf('%.2f',v),'HorizontalAlignment','center',...
             'FontSize',10,'Color',col);
    end
end
for i=0.5:nV+0.5
    plot([i i],[0.5 nV+0.5],'-','Color',[0.82 0.82 0.82]);
    plot([0.5 nV+0.5],[i i],'-','Color',[0.82 0.82 0.82]);
end
title(ax,'Average within-scenario correlation matrix');
if exist('exportgraphics','file')
    exportgraphics(fig,'fig4_corr_heatmap.png','Resolution',300);
end

% --- save matrices ---
save('corr_matrices.mat','Cs','Cavg','vars','scLbl');
fprintf('\nSaved corr_matrices.mat and fig4_corr_heatmap.png\n');

% ---------- helper ----------
function print_corr(M,vars,ttl)
    nV=numel(vars);
    fprintf('\n%s\n', ttl);
    fprintf('%10s',''); fprintf('%9s',vars{:}); fprintf('\n');
    for i=1:nV
        fprintf('%10s',vars{i});
        for j=1:nV
            if i==j
                fprintf('%9.3f',1.0);
            elseif (i==1 && j==2) || (i==2 && j==1)
                fprintf('%9s','--');       % AI-GOV: independent by design
            else
                fprintf('%9.3f',M(i,j));
            end
        end
        fprintf('\n');
    end
end
