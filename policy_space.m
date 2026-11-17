%% ========================================================================
%% policy_space.m  --  "% of AI x GOV space" for the policy table (Table 6)
%%
%% For each strategic objective, computes the fraction of the governance
%% design space (A, G) in [0,1]^2 at which the model's DETERMINISTIC
%% (expected, noise-free) output at the baseline parameters satisfies the
%% stated constraint. The space is sampled on a uniform grid of step 0.001
%% (1001 x 1001 points). This is the exact, reproducible definition of the
%% "% of AI x GOV space" column reported in Table 6.
%% ========================================================================
clear; clc;

% --- baseline parameters (Table 2) ---
b1=0.70; b2=0.15; b3=0.15;           % innovation
a1=0.60; a2=0.50; rho=0.05;          % risk
bgov=0.85; bai=0.10; gam=20.0;       % ESG
wI=0.50; wE=0.30; wR=0.20;           % firm-performance weights

% --- uniform grid over the (A, G) design space ---
ax = 0:0.001:1;                      % step 0.001
[A, G] = meshgrid(ax, ax);

% --- deterministic (noise-free, expected) model outputs, same clipping ---
clip = @(x) min(100, max(0, x));
INNOV = clip((b1.*A + b2.*G + b3.*A.*G)*100);
R01   = min(1, max(0, max(a1.*A - a2.*G, rho)));
RISK  = R01*100;
ESG   = clip((bgov.*G + bai.*A)*100 - R01*gam);
PERF  = clip(wI.*INNOV + wE.*ESG - wR.*RISK);

% --- share of the space satisfying each objective ---
pct = @(mask) 100*mean(mask(:));
fprintf('%% of AI x GOV space (grid step 0.001, deterministic outputs):\n');
fprintf('  Risk < 10%%            : %4.1f%%\n', pct(RISK  < 10));
fprintf('  Risk < 20%%            : %4.1f%%\n', pct(RISK  < 20));
fprintf('  Innovation > 60       : %4.1f%%\n', pct(INNOV > 60));
fprintf('  Innovation > 75       : %4.1f%%\n', pct(INNOV > 75));
fprintf('  ESG > 65              : %4.1f%%\n', pct(ESG   > 65));
fprintf('  Firm performance > 50 : %4.1f%%\n', pct(PERF  > 50));
fprintf('  Firm performance > 55 : %4.1f%%\n', pct(PERF  > 55));
