%% ================================================================
%% ROBUSTNESS & SENSITIVITY SUITE  (reviewer response)
%% Corporate Governance & AI Adoption -- MDPI World world-4454304
%%
%% Reuses EXACTLY the structural model of figures_final_v6.m, but makes
%% noise, the AIxGOV interaction, governance cost, A-G correlation, the
%% aggregation rule and the performance weights configurable, then runs:
%%   EXP0  baseline reproduction check
%%   EXP1  noise sensitivity sweep (where does separation disappear?)
%%   EXP2  structural stress battery (second-order MC under adverse signs)
%%   EXP3  performance-weighting schemes (incl. non-compensatory)
%% Prints a plain-text report; saves robustness_results.mat + CSVs + figs.
%% ================================================================
clear; clc; close all;
rng_default = 'twister';

%% ---- Baseline parameters (manuscript Table 2) ----
P0.ai_innov=0.70; P0.gov_innov=0.15; P0.synergy=0.15;
P0.ai_risk=0.60;  P0.gov_risk=0.50;  P0.rho=0.05;
P0.gov_esg=0.85;  P0.ai_esg=0.10;    P0.esg_pen=20.0;
P0.wI=0.50; P0.wE=0.30; P0.wR=0.20;

AIR  = [0.70 0.90; 0.20 0.40; 0.45 0.65; 0.70 0.90];
GOVR = [0.20 0.40; 0.70 0.90; 0.45 0.65; 0.70 0.90];
SC   = {'S1','S2','S3','S4'};

% default options (match original model exactly)
opt0 = struct('sig',[2 2 2 0.02], 'rho_AG',0, 'invU',false, ...
              'gov_cost',0, 'agg','linear');

N = 10000;
diary_on = true;

%% ================================================================
%% EXP0 -- baseline reproduction (first order)
%% ================================================================
fprintf('\n========== EXP0: BASELINE REPRODUCTION ==========\n');
D = simscen(P0,AIR,GOVR,opt0,N,41);
MNP = cellfun(@mean, {D.PERF});
MNI = cellfun(@mean, {D.INNOV}); MNE = cellfun(@mean,{D.ESG}); MNR = cellfun(@mean,{D.RISK});
fprintf('           INNOV    RISK     ESG     PERF\n');
for k=1:4
  fprintf('  %s      %6.2f  %6.2f  %6.2f  %6.2f\n',SC{k},MNI(k),MNR(k),MNE(k),MNP(k));
end
[~,ord]=sort(MNP,'descend');
fprintf('  Ranking by PERF: %s > %s > %s > %s\n',SC{ord(1)},SC{ord(2)},SC{ord(3)},SC{ord(4)});
fprintf('  (expect S4~59.4 winner; S3 slightly above S2 = the S2-S3 reversal)\n');

%% ================================================================
%% EXP1 -- NOISE SENSITIVITY SWEEP
%%   Means are ~unaffected by symmetric noise; what degrades is the
%%   DISTRIBUTIONAL SEPARATION the paper claims (Fig.3 / Cohen's d).
%%   Report, per noise multiplier m (applied to sI,sE,sP,sR):
%%     Cohen's d (S4 vs 2nd best), P5(S4), P95(2nd), separation flag,
%%     overlap fraction, S4 win-fraction (pairwise draw-vs-draw).
%% ================================================================
fprintf('\n========== EXP1: NOISE SENSITIVITY SWEEP ==========\n');
mlist = [0.25 0.5 1 2 3 5 8 12 20 30];
E1 = zeros(numel(mlist),7);
fprintf('   mult   d(S4,2nd)  P5(S4)  P95(2nd)  sep?   overlap  S4win%%\n');
for i=1:numel(mlist)
  m=mlist(i); o=opt0; o.sig=[2 2 2 0.02]*m;
  Dm = simscen(P0,AIR,GOVR,o,N,41);
  mp = cellfun(@mean,{Dm.PERF});
  [~,os]=sort(mp,'descend'); kw=os(1); k2=os(2);
  s4=Dm(kw).PERF; sec=Dm(k2).PERF;
  d = (mean(s4)-mean(sec))/sqrt((var(s4)+var(sec))/2);
  p5=prctile(s4,5); p95=prctile(sec,95);
  sep = p5>p95;
  overlap = mean(s4 < p95);                  % frac of winner below 2nd's P95
  s4win = mean(s4 > sec(randperm(numel(sec)))); % random pairwise
  E1(i,:)=[m d p5 p95 sep overlap s4win];
  fprintf('  %5.2f   %7.2f   %6.1f  %7.1f    %d    %6.3f  %6.3f\n',...
          m,d,p5,p95,sep,overlap,s4win);
end
% noise multiple where separation (P5(S4)>P95(2nd)) first breaks
brk = find(E1(:,5)==0,1,'first');
if isempty(brk), fprintf('  Separation holds across all tested noise levels.\n');
else, fprintf('  >> Distributional separation disappears at noise x%.2f (approx).\n',E1(brk,1)); end

%% ================================================================
%% EXP2 -- STRUCTURAL STRESS BATTERY (second-order MC, adverse signs)
%%   Original 2nd-order MC fixes every coefficient sign in the favoured
%%   direction -> S4 cannot lose. Here we RELAX those signs.
%% ================================================================
fprintf('\n========== EXP2: STRUCTURAL STRESS BATTERY ==========\n');
N_OUT=500; N_IN=2000;

% triangular ranges (as original) -- [min mode max]
LIT0.ai_innov=[0.50 0.70 0.90]; LIT0.gov_innov=[0.05 0.15 0.25];
LIT0.synergy=[0.05 0.15 0.25];  LIT0.ai_risk=[0.40 0.60 0.80];
LIT0.gov_risk=[0.30 0.50 0.70]; LIT0.rho=[0.02 0.05 0.08];
LIT0.gov_esg=[0.70 0.85 0.95];  LIT0.ai_esg=[0.05 0.10 0.20];
LIT0.esg_pen=[10 20 30];        LIT0.wI=[0.40 0.50 0.60];
LIT0.wE=[0.20 0.30 0.40];

stress = {};
% A) baseline 2nd-order (reproduce S4=100%)
stress{end+1}=struct('name','A_baseline_2ndMC','LIT',LIT0,'opt',opt0,'govcost',[0 0 0]);
% B) interaction can be zero/negative
L=LIT0; L.synergy=[-0.25 0.00 0.25];
stress{end+1}=struct('name','B_interaction_zeroNeg','LIT',L,'opt',opt0,'govcost',[0 0 0]);
% C) AI may REDUCE risk in some regimes (ai_risk can go negative)
L=LIT0; L.ai_risk=[-0.20 0.20 0.60];
stress{end+1}=struct('name','C_AI_riskReduction','LIT',L,'opt',opt0,'govcost',[0 0 0]);
% D) governance has a cost (bureaucratic drag on innovation), drawn
L=LIT0;
stress{end+1}=struct('name','D_governanceCost','LIT',L,'opt',opt0,'govcost',[0.00 0.15 0.35]);
% E) ADVERSARIAL: all three relaxations together
L=LIT0; L.synergy=[-0.25 0.00 0.25]; L.ai_risk=[-0.20 0.20 0.60];
stress{end+1}=struct('name','E_adversarial_all','LIT',L,'opt',opt0,'govcost',[0.00 0.15 0.35]);

E2 = struct('name',{},'winpct',{},'cnt',{},'gapmean',{},'gapmin',{});
for s=1:numel(stress)
  st=stress{s}; L=st.LIT; flds=fieldnames(L);
  best=zeros(N_OUT,1); gap=zeros(N_OUT,1);
  for j=1:N_OUT
    rng(5000+j); Pj=P0; oj=st.opt;
    for fi=1:numel(flds), Pj.(flds{fi})=drawtri(L.(flds{fi})); end
    Pj.wR=max(1-Pj.wI-Pj.wE,0.05);
    if any(st.govcost), oj.gov_cost=drawtri(st.govcost); end
    mp=zeros(4,1);
    for k=1:4
      Dk=simscen_k(Pj,AIR,GOVR,oj,N_IN,5000+j*10+k,k);
      mp(k)=mean(Dk.PERF);
    end
    [~,ib]=max(mp); best(j)=ib; o=mp; mx4=mp(4); o(4)=[]; gap(j)=mx4-max(o);
  end
  cnt=histcounts(best,0.5:4.5);
  wp=sum(best==4)/N_OUT*100;
  E2(s)=struct('name',st.name,'winpct',wp,'cnt',cnt,'gapmean',mean(gap),'gapmin',min(gap));
  fprintf('  %-24s  S4 win=%5.1f%%  [S1=%d S2=%d S3=%d S4=%d]  gap mean=%.1f min=%.1f\n',...
          st.name,wp,cnt(1),cnt(2),cnt(3),cnt(4),mean(gap),min(gap));
end

%% ================================================================
%% EXP3 -- PERFORMANCE-WEIGHTING SCHEMES (first order)
%%   incl. non-compensatory rule (firm must be good on ALL dimensions)
%% ================================================================
fprintf('\n========== EXP3: WEIGHTING SCHEMES ==========\n');
schemes = {
  'baseline_0.5/0.3/0.2', [0.50 0.30 0.20], 'linear';
  'equal_1/3',            [1 1 1]/3,        'linear';
  'ESG_dominant',         [0.25 0.55 0.20], 'linear';
  'risk_dominant',        [0.25 0.25 0.50], 'linear';
  'innovation_dominant',  [0.60 0.20 0.20], 'linear';
  'noncompensatory_min',  [NaN NaN NaN],    'noncomp'};
E3 = struct('name',{},'means',{},'winner',{},'margin',{});
% precompute scenario raw draws once (noise fixed) for fair comparison
Dbase = simscen(P0,AIR,GOVR,opt0,N,41);
for s=1:size(schemes,1)
  nm=schemes{s,1}; w=schemes{s,2}; agg=schemes{s,3};
  mp=zeros(1,4);
  for k=1:4
    I=Dbase(k).INNOV; R=Dbase(k).RISK; E=Dbase(k).ESG;
    if strcmp(agg,'noncomp')
      sc = min([I, 100-R, E],[],2);           % worst of the three (0-100)
    else
      sc = clipv(w(1)*I + w(2)*E - w(3)*R);
    end
    mp(k)=mean(sc);
  end
  [sv,os]=sort(mp,'descend');
  E3(s)=struct('name',nm,'means',mp,'winner',SC{os(1)},'margin',sv(1)-sv(2));
  fprintf('  %-22s  [%s=%.1f %s=%.1f %s=%.1f %s=%.1f]  winner=%s (+%.1f over 2nd)\n',...
     nm,SC{1},mp(1),SC{2},mp(2),SC{3},mp(3),SC{4},mp(4),SC{os(1)},sv(1)-sv(2));
end

%% ---- save ----
save('robustness_results.mat','E1','E2','E3','mlist','stress','schemes','MNP','MNI','MNE','MNR');
writecell([{'mult','d','P5_S4','P95_2nd','sep','overlap','S4win'}; num2cell(E1)],'exp1_noise.csv');
fid=fopen('exp2_stress.csv','w'); fprintf(fid,'name,S4win_pct,S1,S2,S3,S4,gap_mean,gap_min\n');
for s=1:numel(E2), fprintf(fid,'%s,%.1f,%d,%d,%d,%d,%.2f,%.2f\n',E2(s).name,E2(s).winpct,E2(s).cnt,E2(s).gapmean,E2(s).gapmin); end
fclose(fid);
fid=fopen('exp3_weights.csv','w'); fprintf(fid,'scheme,S1,S2,S3,S4,winner,margin\n');
for s=1:numel(E3), fprintf(fid,'%s,%.2f,%.2f,%.2f,%.2f,%s,%.2f\n',E3(s).name,E3(s).means,E3(s).winner,E3(s).margin); end
fclose(fid);

%% ---- quick diagnostic figures ----
f1=figure('Units','centimeters','Position',[3 3 16 11]);
yyaxis left;  plot(E1(:,1),E1(:,2),'-o','LineWidth',1.6); ylabel("Cohen's d (S4 vs 2nd)");
hold on; yline(0.8,':','d=0.8 (large)');
yyaxis right; plot(E1(:,1),E1(:,7),'-s','LineWidth',1.6); ylabel('S4 pairwise win fraction');
set(gca,'XScale','log'); xlabel('Noise multiplier (x baseline \sigma)');
title('EXP1: distributional separation vs noise'); grid on;
exportgraphics(f1,'fig_rob_noise.png','Resolution',200);
exportgraphics(f1,'fig_rob_noise.pdf','ContentType','vector');

f2=figure('Units','centimeters','Position',[3 3 16 10]);
wv=[E2.winpct]; bar(wv,0.6); set(gca,'XTickLabel',{E2.name},'XTickLabelRotation',25);
ylabel('S4 win % (500 draws)'); ylim([0 105]); grid on;
title('EXP2: S4 dominance under structural stress');
exportgraphics(f2,'fig_rob_stress.png','Resolution',200);
exportgraphics(f2,'fig_rob_stress.pdf','ContentType','vector');

fprintf('\nDone. Saved robustness_results.mat, exp1_noise.csv, exp2_stress.csv, exp3_weights.csv, figs.\n');

%% ================================================================
%% ============== helper functions ================================
%% ================================================================
function y=clipv(x), y=min(100,max(0,x)); end

function p=drawtri(v)
  % triangular inverse-CDF draw, v=[min mode max]
  ct=(v(2)-v(1))/(v(3)-v(1)); u=rand();
  if u<ct, p=v(1)+sqrt(u*(v(3)-v(1))*(v(2)-v(1)));
  else,    p=v(3)-sqrt((1-u)*(v(3)-v(1))*(v(3)-v(2))); end
end

function [AI,GOV]=draw_AG(AIR,GOVR,k,opt,N)
  if opt.rho_AG==0
    AI =AIR(k,1)+diff(AIR(k,:))*rand(N,1);
    GOV=GOVR(k,1)+diff(GOVR(k,:))*rand(N,1);
  else
    Z=mvnrnd([0 0],[1 opt.rho_AG; opt.rho_AG 1],N); U=normcdf(Z);
    AI =AIR(k,1)+diff(AIR(k,:))*U(:,1);
    GOV=GOVR(k,1)+diff(GOVR(k,:))*U(:,2);
  end
end

function Dk=simscen_k(P,AIR,GOVR,opt,N,seed,k)
  rng(seed); sg=opt.sig;
  [AI,GOV]=draw_AG(AIR,GOVR,k,opt,N);
  if isfield(opt,'invU') && opt.invU, govI=4*GOV.*(1-GOV); else, govI=GOV; end
  gc = 0; if isfield(opt,'gov_cost'), gc=opt.gov_cost; end
  INNOV=clipv((P.ai_innov*AI+P.gov_innov*govI+P.synergy*AI.*GOV)*100 - gc*GOV*100 + sg(1)*randn(N,1));
  r01=max(P.ai_risk*AI-P.gov_risk*GOV,P.rho);
  R01=min(1,max(0,r01+sg(4)*randn(N,1))); RISK=R01*100;
  ESG=clipv((P.gov_esg*GOV+P.ai_esg*AI)*100-R01*P.esg_pen+sg(2)*randn(N,1));
  if isfield(opt,'agg') && strcmp(opt.agg,'geom')
    PERF=clipv((max(INNOV,1).^P.wI .* max(ESG,1).^P.wE .* max(100-RISK,1).^P.wR) + sg(3)*randn(N,1));
  elseif isfield(opt,'agg') && strcmp(opt.agg,'noncomp')
    PERF=min([INNOV,ESG,100-RISK],[],2)+sg(3)*randn(N,1); PERF=clipv(PERF);
  else
    PERF=clipv(P.wI*INNOV+P.wE*ESG-P.wR*RISK+sg(3)*randn(N,1));
  end
  Dk.AI=AI; Dk.GOV=GOV; Dk.INNOV=INNOV; Dk.RISK=RISK; Dk.ESG=ESG; Dk.PERF=PERF;
end

function D=simscen(P,AIR,GOVR,opt,N,seedbase)
  for k=1:4, D(k)=simscen_k(P,AIR,GOVR,opt,N,seedbase+k,k); end
end
