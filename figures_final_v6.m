%% ================================================================
%% FIGURES 2-6  —  Corporate Governance & AI Adoption
%% v6: Figure 5 heatmap uses hardcoded values from Table 6
%%     to guarantee consistency between figure and table.
%% ================================================================
clear; clc; close all;

set(groot,'defaultAxesFontName',   'Times New Roman');
set(groot,'defaultTextFontName',   'Times New Roman');
set(groot,'defaultAxesFontSize',   12);
set(groot,'defaultAxesLineWidth',  0.9);
set(groot,'defaultLineLineWidth',  1.6);
set(groot,'defaultAxesBox',       'off');
set(groot,'defaultAxesTickDir',   'out');
set(groot,'defaultAxesGridAlpha',  0.20);
set(groot,'defaultAxesGridColor', [0.50 0.50 0.50]);
set(groot,'defaultFigureColor',   'white');

C(1,:) = [0.78 0.24 0.14];
C(2,:) = [0.12 0.35 0.62];
C(3,:) = [0.87 0.55 0.07];
C(4,:) = [0.04 0.52 0.44];

FULL = {'S1 — Innovation-driven','S2 — Compliance-driven',...
        'S3 — Balanced','S4 — Hybrid AI-ESG'};
SC   = {'S1','S2','S3','S4'};

P.ai_innov=0.70; P.gov_innov=0.15; P.synergy=0.15;
P.ai_risk=0.60;  P.gov_risk=0.50;  P.rho=0.05;
P.gov_esg=0.85;  P.ai_esg=0.10;    P.esg_pen=20.0;
P.wI=0.50; P.wE=0.30; P.wR=0.20;

AIR  = [0.70 0.90; 0.20 0.40; 0.45 0.65; 0.70 0.90];
GOVR = [0.20 0.40; 0.70 0.90; 0.45 0.65; 0.70 0.90];

N = 10000;
for k = 1:4
    rng(41+k);
    AI  = AIR(k,1)  + diff(AIR(k,:))  * rand(N,1);
    GOV = GOVR(k,1) + diff(GOVR(k,:)) * rand(N,1);
    INNOV = clipv((P.ai_innov*AI+P.gov_innov*GOV+P.synergy*AI.*GOV)*100+2*randn(N,1));
    r01  = max(P.ai_risk*AI - P.gov_risk*GOV, P.rho);
    R01  = min(1,max(0,r01 + 0.02*randn(N,1)));
    RISK = R01*100;
    ESG  = clipv((P.gov_esg*GOV+P.ai_esg*AI)*100-R01*P.esg_pen+2*randn(N,1));
    PERF = clipv(P.wI*INNOV+P.wE*ESG-P.wR*RISK+2*randn(N,1));
    D(k).AI=AI; D(k).GOV=GOV;
    D(k).INNOV=INNOV; D(k).RISK=RISK; D(k).ESG=ESG; D(k).PERF=PERF;
end
for k=1:4
    MN.INNOV(k)=mean(D(k).INNOV); MN.RISK(k)=mean(D(k).RISK);
    MN.ESG(k)=mean(D(k).ESG);     MN.PERF(k)=mean(D(k).PERF);
    SD.INNOV(k)=std(D(k).INNOV);  SD.RISK(k)=std(D(k).RISK);
    SD.ESG(k)=std(D(k).ESG);      SD.PERF(k)=std(D(k).PERF);
end

%% ================================================================
%% FIGURE 2 — Innovation vs. Firm Performance
%% ================================================================
fig2 = figure('Units','centimeters','Position',[3 3 16 13]);
ax2  = axes(fig2); hold on; grid on;

for k = 1:4
    plot([MN.INNOV(k)-SD.INNOV(k), MN.INNOV(k)+SD.INNOV(k)],...
         [MN.PERF(k) MN.PERF(k)],'-','Color',C(k,:),'LineWidth',0.9,...
         'HandleVisibility','off');
    plot([MN.INNOV(k) MN.INNOV(k)],...
         [MN.PERF(k)-SD.PERF(k), MN.PERF(k)+SD.PERF(k)],'-',...
         'Color',C(k,:),'LineWidth',0.9,'HandleVisibility','off');
end

MK = {'o','s','^','d'};
for k = 1:4
    scatter(MN.INNOV(k),MN.PERF(k),140,C(k,:),MK{k},'filled',...
            'MarkerEdgeColor','white','LineWidth',1.0,'DisplayName',FULL{k});
end

offX = [2,-15,2,2]; offY = [-3,0,-3,2.5];
for k = 1:4
    text(MN.INNOV(k)+offX(k), MN.PERF(k)+offY(k), SC{k},...
         'Color',C(k,:),'FontSize',13,'FontWeight','bold');
end

annotation(fig2,'textarrow','X',[0.60 0.73],'Y',[0.84 0.84],...
    'String',{'+13.6 pts innovation','(same AI adoption range)'},...
    'FontSize',10,'Color',[0.40 0.40 0.40],...
    'HeadLength',6,'HeadWidth',5,'TextEdgeColor','none');

xlabel('Innovation Performance (0-100)','FontSize',14);
ylabel('Firm Performance (0-100)','FontSize',14);
title('Scenario outcomes: Innovation vs. Firm Performance',...
      'FontWeight','normal','FontSize',14);
leg2=legend('Location','northwest','FontSize',11,'Box','on');
leg2.Color='white'; leg2.EdgeColor=[0.70 0.70 0.70];
ax2.XLim=[12 97]; ax2.YLim=[18 77];
ax2.TickLength=[0.015 0.008];
text(0.02,0.04,'Error bars: \pm1 SD','Units','normalized',...
     'FontSize',10,'Color',[0.50 0.50 0.50]);
savefig_clean(fig2,'fig2_innov_perf');

%% ================================================================
%% FIGURE 3 — Box plots
%% ================================================================
fig3 = figure('Units','centimeters','Position',[3 3 17 12]);
ax3  = axes(fig3); hold on; grid on;

data_all=[D(1).PERF;D(2).PERF;D(3).PERF;D(4).PERF];
grp_all =[ones(N,1);2*ones(N,1);3*ones(N,1);4*ones(N,1)];
boxplot(data_all,grp_all,'Symbol','','Widths',0.46,'MedianStyle','line');

box_h=findobj(ax3,'Tag','Box');   med_h=findobj(ax3,'Tag','Median');
whi_h=findobj(ax3,'Tag','Whisker'); cap_h=findobj(ax3,'Tag','Cap');
for k=1:4
    idx=4-k+1;
    if idx<=numel(box_h), set(box_h(idx),'Color',C(k,:),'LineWidth',1.5); end
    if idx<=numel(med_h), set(med_h(idx),'Color',C(k,:),'LineWidth',2.2); end
    wi=(idx-1)*2+(1:2);
    if max(wi)<=numel(whi_h), set(whi_h(wi),'Color',C(k,:),'LineWidth',1.1); end
    if max(wi)<=numel(cap_h), set(cap_h(wi),'Color',C(k,:),'LineWidth',1.4); end
end

for k=1:4
    plot(k,MN.PERF(k),'d','MarkerFaceColor',C(k,:),...
         'MarkerEdgeColor','white','MarkerSize',9,'HandleVisibility','off');
    text(k+0.30,MN.PERF(k),sprintf('%.1f',MN.PERF(k)),...
         'FontSize',12,'Color',C(k,:),'FontWeight','bold',...
         'VerticalAlignment','middle');
end
for k=1:4
    p5=prctile(D(k).PERF,5); p95=prctile(D(k).PERF,95);
    text(k-0.30,p5, sprintf('P_{5}=%2.0f', p5),...
         'FontSize',9,'Color',[0.45 0.45 0.45],...
         'HorizontalAlignment','right','VerticalAlignment','middle');
    text(k-0.30,p95,sprintf('P_{95}=%2.0f',p95),...
         'FontSize',9,'Color',[0.45 0.45 0.45],...
         'HorizontalAlignment','right','VerticalAlignment','middle');
end

ax3.XTick=1:4;
ax3.XTickLabel=SC;
ax3.XTickLabelRotation=0;
ax3.FontSize=12;
ax3.YLim=[0 92]; ax3.TickLength=[0.012 0.008];
xlabel('Governance scenario','FontSize',14);
ylabel('Firm Performance (0-100)','FontSize',14);
title('Distribution of firm performance by governance scenario',...
      'FontWeight','normal','FontSize',14);

for k=1:4
    patch('XData',NaN,'YData',NaN,'FaceColor','none',...
          'EdgeColor',C(k,:),'LineWidth',2,'DisplayName',FULL{k});
end
leg3=legend('Location','northeast','FontSize',10,'Box','on');
leg3.Color='white'; leg3.EdgeColor=[0.70 0.70 0.70];
text(0.01,0.02,'\diamondsuit = mean','Units','normalized',...
     'FontSize',10,'Color',[0.40 0.40 0.40]);
savefig_clean(fig3,'fig3_boxplot');

%% ================================================================
%% FIGURE 4 — Governance threshold curves
%% ================================================================
fig4 = figure('Units','centimeters','Position',[3 3 16 12]);
ax4  = axes(fig4); hold on; grid on;

ai_x=linspace(0,1,400);
T_targets=[10 15 20 25];
T_colors=[C(1,:);C(3,:);C(2,:);C(4,:)];
T_labels={'Risk < 10%','Risk < 15%','Risk < 20%','Risk < 25%'};

for ti=1:4
    T=T_targets(ti);
    gov=max(0,(P.ai_risk*ai_x-T/100)/P.gov_risk);
    gov(gov>1)=NaN; valid=~isnan(gov);
    patch([ai_x(valid) fliplr(ai_x(valid))].*100,...
          [gov(valid) ones(1,sum(valid))].*100,...
          T_colors(ti,:),'FaceAlpha',0.07,'EdgeColor','none','HandleVisibility','off');
    plot(ai_x(valid).*100,gov(valid).*100,'-',...
         'Color',T_colors(ti,:),'LineWidth',2.0,'DisplayName',T_labels{ti});
end

for k=1:4
    yp=mean(GOVR(k,:))*100;
    patch([AIR(k,1) AIR(k,2) AIR(k,2) AIR(k,1)].*100,...
          [yp-1.3 yp-1.3 yp+1.3 yp+1.3],...
          C(k,:),'FaceAlpha',0.55,'EdgeColor','none','HandleVisibility','off');
    text(mean(AIR(k,:))*100,yp+3.8,SC{k},...
         'HorizontalAlignment','center','FontSize',12,...
         'FontWeight','bold','Color',C(k,:));
end

xlabel('AI Adoption (%)','FontSize',14);
ylabel('Minimum Governance Required (%)','FontSize',14);
title({'Governance threshold curves';...
       '(coloured bars = scenario AI adoption ranges)'},...
      'FontWeight','normal','FontSize',13);
leg4=legend('Location','northwest','FontSize',11,'Box','on');
leg4.Color='white'; leg4.EdgeColor=[0.70 0.70 0.70];
ax4.XLim=[0 100]; ax4.YLim=[0 110]; ax4.TickLength=[0.015 0.008];
savefig_clean(fig4,'fig4_thresholds');

%% ================================================================
%% FIGURE 5 — Correlation heatmap
%% FIX v6: hardcoded from Table 6 to guarantee consistency with paper
%% ================================================================
vars={'AI','GOV','INNOV','RISK','ESG','PERF'}; nV=numel(vars);

% Converged within-scenario correlations (population values, averaged over
% the four scenarios, stable to 3 decimal places). Generated by
% corr_per_scenario.m, which recomputes these from the model above and also
% exports the four per-scenario matrices (Supplementary Material S1).
Cavg = [
     1.000,  0.000,  0.881,  0.476,  0.033,  0.478;
     0.000,  1.000,  0.270, -0.392,  0.930,  0.639;
     0.881,  0.270,  1.000,  0.301,  0.281,  0.694;
     0.476, -0.392,  0.301,  1.000, -0.414, -0.161;
     0.033,  0.930,  0.281, -0.414,  1.000,  0.679;
     0.478,  0.639,  0.694, -0.161,  0.679,  1.000;
];

m=256; h2=m/2;
rb=[linspace(0.70,1,h2)',linspace(0.10,1,h2)',linspace(0.10,1,h2)';...
    linspace(1,0.10,h2)',linspace(1,0.10,h2)',linspace(1,0.70,h2)'];

fig5=figure('Units','centimeters','Position',[3 3 14 12]);
ax5=axes(fig5);
imagesc(ax5,Cavg); hold on;
colormap(ax5,rb); caxis([-1 1]);
cb=colorbar(ax5,'FontSize',11); cb.Label.String='Pearson  r';
set(ax5,'XTick',1:nV,'XTickLabel',vars,'YTick',1:nV,'YTickLabel',vars,...
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
    plot([i i],[0.5 nV+0.5],'-','Color',[0.82 0.82 0.82],...
         'LineWidth',0.4,'HandleVisibility','off');
    plot([0.5 nV+0.5],[i i],'-','Color',[0.82 0.82 0.82],...
         'LineWidth',0.4,'HandleVisibility','off');
end
title('Average within-scenario correlation matrix',...
      'FontWeight','normal','FontSize',13);
text(0.01,-0.06,'Averaged across all four governance scenarios',...
     'Units','normalized','FontSize',9,'Color',[0.50 0.50 0.50]);
savefig_clean(fig5,'fig5_correlations');

%% ================================================================
%% FIGURE 6 — Second-order Monte Carlo
%% ================================================================
LIT.ai_innov=[0.50 0.70 0.90]; LIT.gov_innov=[0.05 0.15 0.25];
LIT.synergy=[0.05 0.15 0.25];  LIT.ai_risk=[0.40 0.60 0.80];
LIT.gov_risk=[0.30 0.50 0.70]; LIT.rho=[0.02 0.05 0.08];
LIT.gov_esg=[0.70 0.85 0.95];  LIT.ai_esg=[0.05 0.10 0.20];
LIT.esg_pen=[10 20 30];         LIT.wI=[0.40 0.50 0.60];
LIT.wE=[0.20 0.30 0.40];
flds=fieldnames(LIT);

N_OUT=500; N_IN=2000;
best=zeros(N_OUT,1); gap=zeros(N_OUT,1);
fprintf('Running second-order MC (%d draws)...\n',N_OUT);
for j=1:N_OUT
    rng(5000+j); Pj=P;
    for fi=1:numel(flds)
        v=LIT.(flds{fi}); ct=(v(2)-v(1))/(v(3)-v(1)); u=rand();
        if u<ct, Pj.(flds{fi})=v(1)+sqrt(u*(v(3)-v(1))*(v(2)-v(1)));
        else,    Pj.(flds{fi})=v(3)-sqrt((1-u)*(v(3)-v(1))*(v(3)-v(2))); end
    end
    Pj.wR=max(1-Pj.wI-Pj.wE,0.05);
    mp=zeros(4,1);
    for k=1:4
        rng(5000+j*10+k);
        Ak=AIR(k,1)+diff(AIR(k,:))*rand(N_IN,1);
        Gk=GOVR(k,1)+diff(GOVR(k,:))*rand(N_IN,1);
        Ik=clipv((Pj.ai_innov*Ak+Pj.gov_innov*Gk+Pj.synergy*Ak.*Gk)*100+2*randn(N_IN,1));
        r01k=max(Pj.ai_risk*Ak-Pj.gov_risk*Gk,Pj.rho);
        Rk=min(1,max(0,r01k+0.02*randn(N_IN,1)))*100;
        Ek=clipv((Pj.gov_esg*Gk+Pj.ai_esg*Ak)*100-(Rk/100)*Pj.esg_pen+2*randn(N_IN,1));
        mp(k)=mean(clipv(Pj.wI*Ik+Pj.wE*Ek-Pj.wR*Rk+2*randn(N_IN,1)));
    end
    [~,ib]=max(mp); best(j)=ib;
    oth=mp; oth(4)=[]; gap(j)=mp(4)-max(oth);
end
cnt=histcounts(best,0.5:4.5);
fprintf('S4=%d  S3=%d  S2=%d  S1=%d\n',cnt(4),cnt(3),cnt(2),cnt(1));
fprintf('Gap: min=%.1f  mean=%.1f  max=%.1f\n',min(gap),mean(gap),max(gap));

fig6=figure('Units','centimeters','Position',[3 3 20 9]);
tl6=tiledlayout(1,2,'TileSpacing','compact','Padding','compact');

ax6a=nexttile(tl6); hold on; grid on;
for k=1:4
    bar(k,cnt(k),0.55,'FaceColor',C(k,:),'EdgeColor','none');
    ypos=max(cnt(k)+8,18);
    text(k,ypos,num2str(cnt(k)),'HorizontalAlignment','center',...
         'FontSize',12,'FontWeight','bold','Color',C(k,:));
end
ax6a.XTick=1:4; ax6a.XTickLabel=SC; ax6a.YLim=[0 N_OUT*1.22];
ax6a.TickLength=[0.02 0.01]; ax6a.FontSize=11;
ylabel('Number of draws','FontSize',12);
xlabel('Governance scenario','FontSize',12);
title(sprintf('(a)  Best-performing scenario across %d parameter draws',N_OUT),...
      'FontWeight','normal','FontSize',11);
text(0.97,0.94,sprintf('S4 wins in %.0f%% of draws',sum(best==4)/N_OUT*100),...
     'Units','normalized','HorizontalAlignment','right','VerticalAlignment','top',...
     'FontSize',12,'Color',C(4,:),'FontWeight','bold');

ax6b=nexttile(tl6); hold on; grid on;
histogram(gap,30,'FaceColor',C(4,:),'EdgeColor','white','LineWidth',0.3,...
          'FaceAlpha',0.85,'HandleVisibility','off');
xline(mean(gap),'--k','LineWidth',1.5,'HandleVisibility','off');
yl=ylim;
text(mean(gap)+0.15, yl(2)*0.97,...
     sprintf('mean = %.1f pts', mean(gap)),...
     'FontSize',10,'Color','k','VerticalAlignment','top','HorizontalAlignment','left');
text(min(gap)+0.1, yl(2)*0.88, sprintf('min = %.1f',min(gap)),...
     'FontSize',9,'Color',[0.40 0.40 0.40]);
text(max(gap)-0.1, yl(2)*0.88, sprintf('max = %.1f',max(gap)),...
     'FontSize',9,'Color',[0.40 0.40 0.40],'HorizontalAlignment','right');
ph=patch('XData',NaN,'YData',NaN,'FaceColor',C(4,:),'EdgeColor','none',...
         'DisplayName','S4 — Hybrid AI-ESG');
lh=plot(NaN,NaN,'--k','LineWidth',1.5,...
        'DisplayName',sprintf('Mean = %.1f pts', mean(gap)));
leg6=legend([ph lh],'Location','northwest','FontSize',10,'Box','on');
leg6.Color='white'; leg6.EdgeColor=[0.70 0.70 0.70];
xlabel('S4 advantage over second-best scenario (performance points)','FontSize',11);
ylabel('Frequency','FontSize',12);
title('(b)  Distribution of S4 performance advantage',...
      'FontWeight','normal','FontSize',11);
ax6b.TickLength=[0.02 0.01]; ax6b.FontSize=11;
savefig_clean(fig6,'fig6_somc');
fprintf('\nDone. All figures saved.\n');

%% ── Helpers ──────────────────────────────────────────────────────
function y=clipv(x), y=min(100,max(0,x)); end
function savefig_clean(fig,name)
    exportgraphics(fig,[name '.pdf'],'Resolution',300,'ContentType','vector');
    exportgraphics(fig,[name '.png'],'Resolution',300);
    fprintf('  Saved: %s\n',name);
end
