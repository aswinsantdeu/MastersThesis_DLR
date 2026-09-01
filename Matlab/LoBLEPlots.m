STLoraRSSI = [
    -29, -21, -18, -21, -24, -24, -23, -23, -24, -23, ...
    -23, -25, -26, -27, -25, -27, -28, -29, -31, -30, ...
    -30, -30, -34, -20, -23, -24, -25, -24, -24, -23, ...
    -22, -24, -24, -24, -24, -23, -24, -23, -24, -25, ...
    -24, -25, -25, -25, -25, -24, -24, -25, -24, -23
];

% Create a column vector for SNR values (in dB)
STLoraSNR = [
    13, 12, 12, 12, 13, 13, 12, 12, 12, 13, ...
    13, 13, 12, 13, 14, 13, 13, 13, 13, 12, ...
    13, 13, 13, 12, 13, 13, 13, 13, 12, 13, ...
    13, 13, 13, 12, 12, 13, 12, 12, 12, 13, ...
    13, 13, 13, 13, 13, 12, 13, 13, 12, 12];

% Create a column vector for RSSI values (in dBm)
STBleRSSI = [
    -38, -47, -47, -56, -42, -42, -46, -49, -52, -42, ...
    -42, -42, -47, -53, -55, -42, -42, -47, -53, -55, ...
    -42, -42, -47, -49, -55, -41, -41, -53, -57, -51, ...
    -43, -43, -49, -57, -52, -42, -43, -50, -55, -50, ...
    -38, -44, -49, -54, -55, -38, -43, -44, -54, -55
];

% Create a column vector for SNR (Estimated) values (in dB)
STBleSNR = [
    57, 48, 48, 39, 53, 53, 49, 46, 43, 53, ...
    53, 53, 48, 42, 40, 53, 53, 48, 42, 40, ...
    53, 53, 48, 46, 40, 54, 54, 42, 38, 44, ...
    52, 52, 46, 38, 43, 53, 52, 45, 40, 45, ...
    57, 51, 46, 41, 40, 57, 52, 51, 41, 40 
];



% Define your data
STNfmiRaw = [220, 217, 222, 213, 214, 242, 222, 230, 233, 233, 233, 233, 223, ...
    235, 232, 234, 230, 237, 233, 235, 236, 233, 223, 222, 203, 220, 218, ...
    204, 204, 201, 210, 188, 199, 204, 199, 215, 259, 259, 262, 317, 327, ...
    309, 258, 240, 261, 263, 266, 268, 268, 283];
STMagneticFlux_dBuT = [52.39, 52.38, 52.40, 52.37, 52.37, 52.48, 52.40, 52.43, ...
    52.44, 52.44, 52.44, 52.44, 52.40, 52.45, 52.44, 52.45, 52.43, 52.46, ...
    52.44, 52.45, 52.46, 52.44, 52.40, 52.40, 52.33, 52.39, 52.39, 52.33, ...
    52.33, 52.32, 52.35, 52.27, 52.31, 52.33, 52.31, 52.37, 52.54, 52.54, ...
    52.56, 52.76, 52.80, 52.73, 52.54, 52.47, 52.55, 52.56, 52.57, 52.58, ...
    52.58, 52.58];
STMagneticFieldStrength_Am = [331, 331, 331, 330, 330, 334, 331, 332, 333, 333, ...
    333, 333, 331, 333, 333, 333, 332, 334, 333, 333, 333, 331, 331, 328, ...
    331, 331, 329, 329, 328, 329, 326, 328, 329, 328, 330, 337, 337, 337, ...
    345, 347, 344, 337, 334, 337, 337, 338, 338, 338, 338, 340];


t = 1:1:length(STBleSNR);

%% --- Relative Attenuation Comparison for Steel Cage Test ---
% Normalize each to 0 dB at first sample
BLE_rel = STBleRSSI - STBleRSSI(1);
LoRa_rel = STLoraRSSI - STLoraRSSI(1);
NFMI_rel = STMagneticFlux_dBuT - STMagneticFlux_dBuT(1) ;

% Plot
figure;
hold on; box on;

plot(BLE_rel, '-o', 'Color', 'b', 'LineWidth', 1.8, 'DisplayName', 'BLE (dBm)');
plot(LoRa_rel, '-^', 'Color', 'g', 'LineWidth', 1.8, 'DisplayName', 'LoRa (dBm)');
plot(NFMI_rel, '-s', 'Color', 'r', 'LineWidth', 1.8, 'DisplayName', 'NFMI (dBuT)');

xlabel('Sample Index');
ylabel('Relative Attenuation (dB)');
title('Relative Signal Attenuation Comparison: BLE, LoRa, and NFMI');
legend('Location', 'best');
ylim([-40 20]);
set(gca, 'FontSize', 12);




% --- Plot ---
figure;
hold on;
plot(t, STBleRSSI, 'b-o', 'LineWidth', 1.5, 'DisplayName', 'BLE RSSI (dBm)');
plot(t, STLoraRSSI, 'g-^', 'LineWidth', 1.5, 'DisplayName', 'LoRa RSSI (dBm)');
plot(t, STMagneticFlux_dBuT, 'r-s', 'LineWidth', 1.5, 'DisplayName', 'NFMI Flux (dBuT)');
plot(t, STMagneticFieldStrength_Am, 'r-*', 'LineWidth', 1.5, 'DisplayName', 'NFMI FieldStrength (A/M)');

% --- Formatting ---
xlabel('Time (sample index)');
ylabel('Signal Strength (dB)');
title('Signal Strength Variation over Time: BLE, LoRa, and NFMI');
legend('show', 'Location', 'best');
grid on;
ylim([-90 60]);  % adjust depending on your values
hold off;

%corrcoef([STBleRSSI, STBleSNR, STMagneticFlux_dBuT, STMagneticFieldStrength_Am, STNfmiRaw])


% --- Combine data ---
data = [STBleRSSI, STLoraRSSI, STMagneticFlux_dBuT];
labels = {'BLE RSSI (dBm)', 'LoRa RSSI (dBm)', 'NFMI Flux (dBuT)'};



% --- Optional aesthetics ---
h = findobj(gca,'Tag','Box');
colors = {'b','g','r'};
for j = 1:length(h)
    patch(get(h(j),'XData'), get(h(j),'YData'), colors{j}, 'FaceAlpha', 0.4);
end
figure;
hold on;
cdfplot(STBleRSSI); set(findobj(gca,'Type','line'),'Color','b','LineWidth',1.5);
cdfplot(STLoraRSSI); set(findobj(gca,'Type','line'),'Color','g','LineWidth',1.5);
cdfplot(STMagneticFlux_dBuT); set(findobj(gca,'Type','line'),'Color','r','LineWidth',1.5);
hold off;

xlabel('Signal Level (dB units)');
ylabel('Cumulative Probability');
title('Cumulative Distribution Function: BLE, LoRa, NFMI');
legend('BLE RSSI','LoRa RSSI','NFMI Flux','Location','best');
grid on;

figure;
t = (1:50)'; % assuming 50 samples per test

% % 3D line connecting BLE RSSI with NFMI Field Strength
% plot3(t, STBleRSSI, STMagneticFieldStrength_Am, 'b-o', ...
%     'LineWidth', 1.5, 'MarkerFaceColor', 'b', 'DisplayName', 'BLE');
% hold on;
% 
% % 3D line connecting LoRa RSSI with NFMI Field Strength
% plot3(t, STLoraRSSI, STMagneticFieldStrength_Am, 'g-^', ...
%     'LineWidth', 1.5, 'MarkerFaceColor', 'g', 'DisplayName', 'LoRa');

% 3D line for NFMI alone (field strength vs time)
plot3(t, STMagneticFlux_dBuT, STMagneticFieldStrength_Am, 'r-d', ...
    'LineWidth', 1.5, 'MarkerFaceColor', 'r', 'DisplayName', 'NFMI');

xlabel('Time (sample index)');
ylabel('Signal Level (dB units)');
zlabel('Magnetic Field Strength (A/m)');
title('3D Relationship: BLE, LoRa, and NFMI Field Strength');
legend('Location', 'best');

view(45, 30);

figure;
cmap = jet(length(STNfmiRaw));
[~, idx] = sort(STNfmiRaw);
color_idx = rescale(STNfmiRaw, 1, length(STNfmiRaw));
hold on;
for i = 1:length(t)-1
    c = interp1(1:length(cmap), cmap, color_idx(i), 'linear');
    plot3(t(i:i+1), STMagneticFlux_dBuT(i:i+1), STMagneticFieldStrength_Am(i:i+1), 'Color', c, 'LineWidth', 4);
end
hold off;

xlabel('Time (samples)');
ylabel('Magnetic Flux Density (dBµT)');
zlabel('Magnetic Field Strength H (A/m)');
title('NFMI inside Steel Cage');
grid on;
colormap(jet);
cb = colorbar;
clim([200 400]);
cb.Label.String = 'Raw Amplitude (mV)';
view(45, 30);

figure;
subplot(1,2,1)
scatter(STBleRSSI, STBleSNR, 'b', 'LineWidth', 2);
xlabel('RSSI(dBm)');
ylabel('SNR (dB)');
title('BLE RSSIvsSNR');
subplot(1,2,2)
scatter(STLoraRSSI, STLoraSNR, 'g', 'LineWidth', 2);
xlabel('RSSI(dBm)');
ylabel('SNR (dB)');
title('LoRa RSSIvsSNR');
