%% ================================================================
%% ROBUSTNESS v2 -- THRESHOLD SEARCH: where does S4 stop winning?
%% Extends robustness_v1 with reviewer-requested adverse structures,
%% each as an INTENSITY SWEEP so we can report the breaking point:
%%   EXP4A inverted-U governance->innovation (intensity lambda)
%%   EXP4B governance cost on innovation (bureaucratic drag)  kappa_I
%%   EXP4C governance cost directly on firm performance        kappa_P
%%   EXP4D overlapping scenario boundaries (box widening)      w
%%   EXP4E correlated AI-GOV within scenario                   rho
%%   EXP4F combined adversarial 2nd-order MC (can S4 EVER lose?)
%% Prints winner + S4 margin at each level; flags first level S4 loses.
%% ================================================================
clear; clc; close all;

P0.ai_innov=0.70; P0.gov_innov=0.15; P0.synergy=0.15;
P0.ai_risk=0.60;  P0.gov_risk=0.50;  P0.rho=0.05;
P0.gov_esg=0.85;  P0.ai_esg=0.10;    P0.esg_pen=20.0;
P0.wI=0.50; P0.wE=0.30; P0.wR=0.20;

AIR  = [0.70 0.90; 0.20 0.40; 0.45 0.65; 0.70 0.90];
GOVR = [0.20 0.40; 0.70 0.90; 0.45 0.65; 0.70 0.90];
SC   = {'S1','S2','S3','S4'};
opt0 = struct('sig',[2 2 2 0.02],'rho_AG',0,'invU',0,'gov_cost',0,'gov_cost_perf',0,'agg','linear');
N=10000;
results=struct();

sweepreport = @(name,lv,MP) report_sweep(name,lv,MP,SC);

%% ---------- EXP4A inverted-U intensity ----------
fprintf('\n===== EXP4A: inverted-U governance->innovation (lambda 0=linear .. 1=full U) =====\n');
lam=[0 0.25 0.5 0.75 1.0 1.5 2.0];
MP=zeros(numel(lam),4);
for i=1:numel(lam)
  o=opt0; o.invU=lam(i); D=simscen(P0,AIR,GOVR,o,N,41); MP(i,:)=cellfun(@mean,{D.PERF});
end
results.A=sweepreport('lambda',lam,MP);

%% ---------- EXP4B governance cost on innovation ----------
fprintf('\n===== EXP4B: governance cost on innovation (kappa_I * GOV*100 off INNOV) =====\n');
kI=[0 0.1 0.2 0.3 0.5 0.7 1.0];
MP=zeros(numel(kI),4);
for i=1:numel(kI)
  o=opt0; o.gov_cost=kI(i); D=simscen(P0,AIR,GOVR,o,N,41); MP(i,:)=cellfun(@mean,{D.PERF});
end
results.B=sweepreport('kappa_I',kI,MP);

%% ---------- EXP4C governance cost on performance ----------
fprintf('\n===== EXP4C: governance cost on firm performance (kappa_P * GOV*100 off PERF) =====\n');
kP=[0 0.1 0.2 0.3 0.5 0.7 1.0];
MP=zeros(numel(kP),4);
for i=1:numel(kP)
  o=opt0; o.gov_cost_perf=kP(i); D=simscen(P0,AIR,GOVR,o,N,41); MP(i,:)=cellfun(@mean,{D.PERF});
end
results.C=sweepreport('kappa_P',kP,MP);

%% ---------- EXP4D overlapping boundaries ----------
fprintf('\n===== EXP4D: overlapping scenario boundaries (widen each box by factor w) =====\n');
wv=[0 0.25 0.5 1.0 2.0 4.0];
MP=zeros(numel(wv),4);
for i=1:numel(wv)
  [A2,G2]=widenboxes(AIR,GOVR,wv(i));
  D=simscen(P0,A2,G2,opt0,N,41); MP(i,:)=cellfun(@mean,{D.PERF});
end
results.D=sweepreport('w',wv,MP);

%% ---------- EXP4E correlated AI-GOV ----------
fprintf('\n===== EXP4E: correlated AI-GOV within scenario (rho) =====\n');
rv=[-0.7 -0.3 0 0.3 0.7];
MP=zeros(numel(rv),4);
for i=1:numel(rv)
  o=opt0; o.rho_AG=rv(i); D=simscen(P0,AIR,GOVR,o,N,41); MP(i,:)=cellfun(@mean,{D.PERF});
end
results.E=sweepreport('rho',rv,MP);

%% ---------- EXP4F combined adversarial second-order MC ----------
fprintf('\n===== EXP4F: COMBINED ADVERSARIAL 2nd-order MC (can S4 lose?) =====\n');
N_OUT=800; N_IN=2000;
LIT.ai_innov=[0.50 0.70 0.90]; LIT.gov_innov=[0.05 0.15 0.25];
LIT.synergy=[-0.25 0.00 0.25]; LIT.ai_risk=[-0.20 0.20 0.60];
LIT.gov_risk=[0.30 0.50 0.70]; LIT.rho=[0.02 0.05 0.08];
LIT.gov_esg=[0.55 0.80 0.95];  LIT.ai_esg=[0.05 0.10 0.20];
LIT.esg_pen=[10 20 30];        LIT.wI=[0.40 0.50 0.60]; LIT.wE=[0.20 0.30 0.40];
flds=fieldnames(LIT);
best=zeros(N_OUT,1); margin=zeros(N_OUT,1);
for j=1:N_OUT
  rng(7000+j); Pj=P0;
  for fi=1:numel(flds), Pj.(flds{fi})=drawtri(LIT.(flds{fi})); end
  Pj.wR=max(1-Pj.wI-Pj.wE,0.05);
  oj=opt0;
  oj.invU         = rand()*1.5;                % 0..1.5
  oj.gov_cost     = drawtri([0.00 0.20 0.60]); % innov drag
  oj.gov_cost_perf= drawtri([0.00 0.10 0.30]); % perf overhead
  oj.rho_AG       = -0.6 + 1.2*rand();         % -0.6..0.6
  w               = 2.0*rand();                % 0..2 widening
  [A2,G2]=widenboxes(AIR,GOVR,w);
  mp=zeros(4,1);
  for k=1:4, Dk=simscen_k(Pj,A2,G2,oj,N_IN,7000+j*10+k,k); mp(k)=mean(Dk.PERF); end
  [~,ib]=max(mp); best(j)=ib; o=mp; mx4=mp(4); o(4)=[]; margin(j)=mx4-max(o);
end
cnt=histcounts(best,0.5:4.5);
fprintf('  Winner counts over %d adversarial draws: S1=%d S2=%d S3=%d S4=%d\n',N_OUT,cnt);
fprintf('  S4 wins %.1f%% ; S4 margin: min=%.1f mean=%.1f max=%.1f ; frac S4 margin<0 = %.1f%%\n',...
        sum(best==4)/N_OUT*100,min(margin),mean(margin),max(margin),mean(margin<0)*100);
results.F=struct('cnt',cnt,'winpct',sum(best==4)/N_OUT*100,'margin',margin,'best',best);

save('robustness_v2_results.mat','results','lam','kI','kP','wv','rv');

%% ---- figure: sweeps (S4 margin over 2nd best vs level) ----
f=figure('Units','centimeters','Position',[3 3 24 15]);
tl=tiledlayout(2,3,'TileSpacing','compact','Padding','compact');
plot_margin(nexttile,lam,results.A,'(a) inverted-U \lambda');
plot_margin(nexttile,kI, results.B,'(b) gov cost on innovation \kappa_I');
plot_margin(nexttile,kP, results.C,'(c) gov cost on performance \kappa_P');
plot_margin(nexttile,wv, results.D,'(d) overlapping boundaries w');
plot_margin(nexttile,rv, results.E,'(e) AI-GOV correlation \rho');
nexttile; histogram(results.F.margin,40,'FaceColor',[0.04 0.52 0.44]); hold on;
xline(0,'--r','LineWidth',1.5); grid on;
xlabel('S4 margin over 2nd best'); ylabel('draws');
title(sprintf('(f) combined adversarial: S4 wins %.0f%%',results.F.winpct));
exportgraphics(f,'fig_rob_thresholds.png','Resolution',200);
exportgraphics(f,'fig_rob_thresholds.pdf','ContentType','vector');
fprintf('\nDone. Saved robustness_v2_results.mat and fig_rob_thresholds.\n');

%% ================= helpers =================
function y=clipv(x), y=min(100,max(0,x)); end
function p=drawtri(v)
  ct=(v(2)-v(1))/(v(3)-v(1)); u=rand();
  if u<ct, p=v(1)+sqrt(u*(v(3)-v(1))*(v(2)-v(1)));
  else,    p=v(3)-sqrt((1-u)*(v(3)-v(1))*(v(3)-v(2))); end
end
function [A2,G2]=widenboxes(AIR,GOVR,w)
  A2=AIR; G2=GOVR;
  for k=1:4
    ca=mean(AIR(k,:)); ha=diff(AIR(k,:))/2*(1+w);
    cg=mean(GOVR(k,:)); hg=diff(GOVR(k,:))/2*(1+w);
    A2(k,:)=[max(0,ca-ha) min(1,ca+ha)];
    G2(k,:)=[max(0,cg-hg) min(1,cg+hg)];
  end
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
  lam=0; if isfield(opt,'invU'), lam=opt.invU; end
  govI=(1-lam)*GOV + lam*4.*GOV.*(1-GOV);
  gcI=0; if isfield(opt,'gov_cost'), gcI=opt.gov_cost; end
  gcP=0; if isfield(opt,'gov_cost_perf'), gcP=opt.gov_cost_perf; end
  INNOV=clipv((P.ai_innov*AI+P.gov_innov*govI+P.synergy*AI.*GOV)*100 - gcI*GOV*100 + sg(1)*randn(N,1));
  r01=max(P.ai_risk*AI-P.gov_risk*GOV,P.rho);
  R01=min(1,max(0,r01+sg(4)*randn(N,1))); RISK=R01*100;
  ESG=clipv((P.gov_esg*GOV+P.ai_esg*AI)*100-R01*P.esg_pen+sg(2)*randn(N,1));
  PERF=clipv(P.wI*INNOV+P.wE*ESG-P.wR*RISK - gcP*GOV*100 + sg(3)*randn(N,1));
  Dk.INNOV=INNOV; Dk.RISK=RISK; Dk.ESG=ESG; Dk.PERF=PERF;
end
function D=simscen(P,AIR,GOVR,opt,N,seedbase)
  for k=1:4, D(k)=simscen_k(P,AIR,GOVR,opt,N,seedbase+k,k); end
end
function R=report_sweep(name,lv,MP,SC)
  R=struct('level',lv,'means',MP,'winner',{cell(numel(lv),1)},'margin',zeros(numel(lv),1));
  fprintf('   %-8s   S1     S2     S3     S4    winner  S4-margin\n',name);
  firstloss=[];
  for i=1:numel(lv)
    [sv,os]=sort(MP(i,:),'descend'); win=SC{os(1)};
    s4m=MP(i,4)-max(MP(i,[1 2 3]));
    R.winner{i}=win; R.margin(i)=s4m;
    fprintf('   %7.3f  %5.1f  %5.1f  %5.1f  %5.1f   %-4s   %+6.1f\n',lv(i),MP(i,:),win,s4m);
    if ~strcmp(win,'S4') && isempty(firstloss), firstloss=lv(i); end
  end
  if isempty(firstloss), fprintf('   >> S4 stays top across the whole sweep.\n');
  else, fprintf('   >> S4 loses the top rank at %s = %.3f.\n',name,firstloss); end
end
function plot_margin(ax,lv,R,ttl)
  plot(ax,lv,R.margin,'-o','LineWidth',1.6,'Color',[0.04 0.52 0.44]); hold(ax,'on');
  yline(ax,0,'--r','LineWidth',1.2); grid(ax,'on');
  xlabel(ax,'level'); ylabel(ax,'S4 margin'); title(ax,ttl);
end
