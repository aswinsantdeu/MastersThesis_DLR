% Frequencies (MHz) in ascending order for smooth lines
fMHz = [0.131, 10, 13.56, 433, 868, 2400, 5000];

% Skin depth (m) aligned to fMHz order
air   = [2.11e8, 2.4137e7, 2.0727e7, 3.668e6, 2.591e6, 1.558e6, 1.079e6];
cSt   = [5.2e-5,  5.9e-6,   5.1e-6,   9.05e-7, 6.39e-7, 3.8e-7,  2.6e-7];
ssFer = [2.9e-5,  3.4e-6,   2.9e-6,   5.1e-7,  3.6e-7,  2.2e-7,  1.5e-7];
glass = [1.87e5,  2.14e4,   1.84e4,   3.261e3, 2.303e3, 1.385e3, 960];
wood  = [62.2,    7,        6,        1.0,     0.76,    0.4594,  0.3183];

figure('Color','w'); hold on; box on; grid on; set(gca,'GridLineStyle',':')

loglog(fMHz, air,   '-o','LineWidth',1.8,'MarkerSize',5,'DisplayName','Air');
loglog(fMHz, cSt,   '-o','LineWidth',1.8,'MarkerSize',5,'DisplayName','Steel (C)');
loglog(fMHz, ssFer, '-o','LineWidth',1.8,'MarkerSize',5,'DisplayName','Steel (SS)');
loglog(fMHz, glass, '-o','LineWidth',1.8,'MarkerSize',5,'DisplayName','Glass');
loglog(fMHz, wood,  '-o','LineWidth',1.8,'MarkerSize',5,'DisplayName','Wood');

xlabel('Frequency (MHz)'); ylabel('SkinDepth (m)');
xlim([0.1 6000]); ylim([1e-7 1e9]);
set(gca,'XScale','log','YScale','log','FontName','Calibri','FontSize',11)
legend('Location','eastoutside'); title('Skin Depth vs Frequency');
