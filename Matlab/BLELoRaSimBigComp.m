dataDir = fullfile(tempdir,"ShipCompartment");
filename = fullfile(dataDir,"CompMain21.glb");
viewer = siteviewer(SceneModel=filename,ShowEdges=false,ShowOrigin=true);

BLEtx = txsite("cartesian",AntennaPosition=[-0.5; 0.05; 1],TransmitterFrequency=2.4e9);
BLErx_1 = rxsite("cartesian",AntennaPosition=[-0.25; 0.45; 0.1]);
%BLErx_2 = rxsite("cartesian",AntennaPosition=[1; 0; 1]);

LoRatx = txsite("cartesian",AntennaPosition=[-0.5; 0.95; 1],TransmitterFrequency=0.868e9);
LoRarx_1 = rxsite("cartesian",AntennaPosition=[-0.25; 0.65; 0.1]);
%LoRarx_2 = rxsite("cartesian",AntennaPosition=[1; 0.5; 1]);

pm = propagationModel("raytracing", CoordinateSystem="cartesian", Method="sbr");
pm_fs = propagationModel("freespace");
% ray1 = raytrace(BLEtx, BLErx_1, pm, Map=viewer);
% ray2 = raytrace(BLEtx, BLErx_2, pm, Map=viewer);

pm.MaxNumReflections = 1;
pm.MaxNumDiffractions = 1;

los(BLEtx,BLErx_1)
los(LoRatx,LoRarx_1)
%raytrace(BLEtx,BLErx_1,pm)
%raytrace(LoRatx,LoRarx_1,pm)

% Combined Rx power (phasor-summed)
P_BLE_rx1_dBm = sigstrength(BLErx_1, BLEtx, pm_fs, Map=viewer);
%P_BLE_rx2_dBm = sigstrength(BLErx_2, BLEtx, pm, Map=viewer);
P_LoRa_rx1_dBm = sigstrength(LoRarx_1, LoRatx, pm_fs, Map=viewer);
%P_LoRa_rx2_dBm = sigstrength(LoRarx_2, LoRatx, pm, Map=viewer);

fprintf("BLE Rx1: %.1f dBm\n", P_BLE_rx1_dBm);
fprintf("LoRa Rx1: %.1f dBm\n", P_LoRa_rx1_dBm);

% Make a 2-D Rx grid at height z0 and compute coverage (BLE/LoRa)
% Auto grid bounds (+ margin)
allX = [BLEtx.AntennaPosition(1) BLErx_1.AntennaPosition(1) ...
        LoRatx.AntennaPosition(1) LoRarx_1.AntennaPosition(1)];
allY = [BLEtx.AntennaPosition(2) BLErx_1.AntennaPosition(2) ...
        LoRatx.AntennaPosition(2) LoRarx_1.AntennaPosition(2)];
margin = 0.5; res = 0.1;                      % adjust 
xmin = floor(min(allX)-margin); xmax = ceil(max(allX)+margin);
ymin = floor(min(allY)-margin); ymax = ceil(max(allY)+margin);
z0   = 1;                                  % height [m]
[xg,yg] = meshgrid(xmin:res:xmax, ymin:res:ymax); zg = z0*ones(size(xg));

% Build Rx sites on the grid (cartesian)
rxGrid = arrayfun(@(i) rxsite("cartesian", AntennaPosition=[xg(i); yg(i); zg(i)]), ...
                  1:numel(xg), "UniformOutput", false);

% BLE coverage (phasor-summed over rays)
Pgrid_BLE_dBm = reshape(sigstrength([rxGrid{:}], BLEtx, pm_fs, Map=viewer), size(xg));
% LoRa coverage
Pgrid_LoRa_dBm = reshape(sigstrength([rxGrid{:}], LoRatx, pm_fs, Map=viewer), size(xg));


%PgridFS_BLE = reshape(sigstrength([rxGrid{:}], BLEtx, pm_fs), size(xg));


%%%%%%%%%%%%%%%% Fit Close-In (CI) path-loss model %%%%%%%%%%%%%%%%% 


% Distance from BLE Tx to each grid point
txpBLE = BLEtx.AntennaPosition(:).';
dBLE = sqrt((xg-txpBLE(1)).^2 + (yg-txpBLE(2)).^2 + (zg-txpBLE(3)).^2);

PtBLE_dBm = BLEtx.TransmitterPower;                 % assumes isotropic 
PLBLE_dB  = PtBLE_dBm - Pgrid_BLE_dBm;              % path loss

% Clean mask (ignore NaN/Inf, avoid d<=1 m for CI regression stability)
mask = isfinite(PLBLE_dB) & dBLE > 1;
y = PLBLE_dB(mask) - fspl(1, BLEtx.TransmitterFrequency);   % remove FSPL(1m)
X = 10*log10(dBLE(mask));
n_hat_BLE = X\y(:);                   % path-loss exponent (~<2 in steel corridors)
sigma_BLE = std(y(:) - X*n_hat_BLE);      % log-normal shadowing std [dB]
fprintf("CI fit (BLE): n = %.2f, sigma = %.1f dB\n", n_hat_BLE, sigma_BLE);

% Repeat for LoRa
txpLoRa = LoRatx.AntennaPosition(:).';
dLoRa = sqrt((xg-txpLoRa(1)).^2 + (yg-txpLoRa(2)).^2 + (zg-txpLoRa(3)).^2);
PtLoRa_dBm = LoRatx.TransmitterPower;
PLLoRa_dB  = PtLoRa_dBm - Pgrid_LoRa_dBm;
maskL = isfinite(PLLoRa_dB) & dLoRa > 1;
yL = PLLoRa_dB(maskL) - fspl(1, LoRatx.TransmitterFrequency);
XL = 10*log10(dLoRa(maskL));
n_hat_LoRa = XL\yL(:);
sigma_LoRa = std(yL(:) - XL*n_hat_LoRa);
fprintf("CI fit (LoRa): n = %.2f, sigma = %.1f dB\n", n_hat_LoRa, sigma_LoRa);

%%%%%%%%%%%%%%% Small-scale stats from rays at BLErx_1 %%%%%%%%%%%%%%

raysBLE = raytrace(BLEtx, BLErx_1, pm, Map=viewer);      % returns cell; take {1}
R1 = raysBLE{1};
% Try to get per-path received powers; if not present, derive from path loss
try
    Ppath_dBm = [R1.ReceivedPower].';
catch
    % Fall back: assume isotropic gains if patterns not set
    Ppath_dBm = BLEtx.TransmitterPower - [R1.PathLoss].';
end
Ppath_mW = 10.^(Ppath_dBm/10);

% Rician K (strongest vs. rest)
[~,kidx] = max(Ppath_mW);
Kble_linear = Ppath_mW(kidx) / max(eps, sum(Ppath_mW) - Ppath_mW(kidx));
Kble_dB     = 10*log10(Kble_linear);

% Delay spread and coherence bandwidth
tauble_s = [R1.PropagationDelay].';         % seconds
w = Ppath_mW / sum(Ppath_mW);
tblebar = sum(w.*tauble_s);
tauble_rms = sqrt(sum(w.*(tauble_s - tblebar).^2));
bleBc_Hz = 1/(5*tauble_rms + eps);

fprintf("Rician K @ BLErx_1: %.1f dB,  RMS delay: %.1f ns,  Bc≈ %.1f kHz\n", ...
        Kble_dB, 1e9*tauble_rms, 1e-3*bleBc_Hz);

%%%%%%%%%%%%%%   Small-scale stats from rays at LoRarx_1  %%%%%%%%%%%%%
raysLoRa = raytrace(LoRatx, LoRarx_1, pm, Map=viewer);      % returns cell; take {1}
R2 = raysLoRa{1};
% Try to get per-path received powers; if not present, derive from path loss
try
    Ppath2_dBm = [R2.ReceivedPower].';
catch
    % Fall back: assume isotropic gains if patterns not set
    Ppath2_dBm = LoRatx.TransmitterPower - [R2.PathLoss].';
end
Ppath2_mW = 10.^(Ppath2_dBm/10);

% Rician K (strongest vs. rest)
[~,klidx] = max(Ppath2_mW);
Klora_linear = Ppath2_mW(klidx) / max(eps, sum(Ppath2_mW) - Ppath2_mW(klidx));
Klora_dB     = 10*log10(Klora_linear);

% Delay spread and coherence bandwidth
taulora_s = [R2.PropagationDelay].';         % seconds
w = Ppath2_mW / sum(Ppath2_mW);
tlorabar = sum(w.*taulora_s);
taulora_rms = sqrt(sum(w.*(taulora_s - tlorabar).^2));
loraBc_Hz = 1/(5*taulora_rms + eps);

fprintf("Rician K @ LoRarx_2: %.1f dB,  RMS delay: %.1f ns,  Bc≈ %.1f kHz\n", ...
        Klora_dB, 1e9*taulora_rms, 1e-3*loraBc_Hz);
% RSSI -> SNR -> BER/PER (BLE-1M and LoRa@SF selectable)

% Noise floor assumptions
NF_dB = 6;                  % receiver noise figure (edit)
N0_dBmHz = -174;

% BLE-1M
BW_BLE = 1e6; Rb_BLE = 1e6;
N_BLE_dBm = N0_dBmHz + 10*log10(BW_BLE) + NF_dB;
SNR_BLE_grid = Pgrid_BLE_dBm - N_BLE_dBm;


% LoRa (125 kHz BW)
BW_LoRa = 125e3; N_LoRa_dBm = N0_dBmHz + 10*log10(BW_LoRa) + NF_dB;
SNR_LoRa_grid = Pgrid_LoRa_dBm - N_LoRa_dBm;

SF = '10';                   % SF '7'..'12'
thr = containers.Map({'7','8','9','10','11','12'}, ...
                     [-7.5, -10, -12.5, -15, -17.5, -20]); % dB thresholds
k_slope = 1.2;               % logistic slope; tune with measurements
PER_LoRa = 1 ./ (1 + exp(k_slope*(SNR_LoRa_grid - thr(SF))));

function g = rician_power(K_dB, sz)
    K = 10^(K_dB/10);
    s = sqrt(K/(K+1));                 % specular mean (normalized)
    sig = 1/sqrt(2*(K+1));             % scatter std
    x = s + sig.*randn(sz);            % I
    y =      sig.*randn(sz);           % Q
    g = x.^2 + y.^2;                   % power gain, E[g]=1
end

% SmallScale included BLE and LoRa SNR grid (in dB):
Nsamp = 50;
[m, n] = size(SNR_BLE_grid);
[p, q] = size(SNR_LoRa_grid);
Gble = rician_power(Kble_dB, [m, n, Nsamp]); % stack samples
Glora = rician_power(Klora_dB, [p, q, Nsamp]); % stack samples
SNRBLE = SNR_BLE_grid + 10*log10(Gble);                        % per-sample SNR
SNRLORA = SNR_LoRa_grid + 10*log10(Glora);
EbN0 = 10.^(SNRBLE/10);
BER_BLE = 0.5.*exp(-EbN0/2);                                  % BLE 1M proxy
% Lbits = 47*8 + 16;
% PERi = -expm1(Lbits.*log1p(-BERi));
% PER_BLE_avg = mean(PERi,3);                                % smooth 0..1 map



% visuals (turn on/off as needed)

% figure;
% imagesc([ymin ymax],[xmin xmax], PgridFS_BLE.'); axis xy equal; colorbar
% title('BLE Rx Power (dBm) – free space, power-sum'); xlabel('y [m]'); ylabel('x [m]');
% hold on; 
% plot(BLEtx.AntennaPosition(2), BLEtx.AntennaPosition(1), 'wo','markersize',8,'markerfacecolor','r'); % Tx
% plot(BLErx_1.AntennaPosition(2), BLErx_1.AntennaPosition(1), 'ws','markersize',7,'markerfacecolor','k');     % Rx
% hold off
% 
% % figure; imagesc([xmin xmax],[ymin ymax], flipud(Pgrid_BLE_dBm.')); axis xy equal;
% % colorbar; title('BLE Rx Power (dBm)'); xlabel('y [m]'); ylabel('x [m]');
% 
 SNRib_avg = mean(SNRBLE, 3);  % Average across the Rician samples (3rd dimension)
 SNRil_avg = mean(SNRLORA, 3);
% figure; imagesc([xmin xmax], [ymin ymax], flipud(SNRi_avg)); axis xy equal;
% colorbar; title('BLE SNR (dB)'); xlabel('y [m]'); ylabel('x [m]');
% hold on; 
% plot(BLEtx.AntennaPosition(2), BLEtx.AntennaPosition(1), 'wo','markersize',8,'markerfacecolor','r'); % Tx
% plot(BLErx_1.AntennaPosition(2), BLErx_1.AntennaPosition(1), 'ws','markersize',7,'markerfacecolor','k');     % Rx
% hold off
% 
 BER_BLE_avg = mean(BER_BLE, 3);
% figure; imagesc([xmin xmax], [ymin ymax], flipud(BER_BLE_avg)); axis xy equal;
% colorbar; clim([0 1]); title('BLE BER'); xlabel('y [m]'); ylabel('x [m]');
% hold on; 
% plot(BLEtx.AntennaPosition(2), BLEtx.AntennaPosition(1), 'wo','markersize',8,'markerfacecolor','r'); % Tx
% plot(BLErx_1.AntennaPosition(2), BLErx_1.AntennaPosition(1), 'ws','markersize',7,'markerfacecolor','k');     % Rx
% hold off
% 
% figure; imagesc([xmin xmax],[ymin ymax], flipud(Pgrid_LoRa_dBm.')); axis xy equal;
% colorbar; title('LoRa Rx Power (dBm)'); xlabel('y [m]'); ylabel('x [m]');
% hold on; 
% plot(LoRatx.AntennaPosition(2), LoRatx.AntennaPosition(1), 'wo','markersize',8,'markerfacecolor','r'); % Tx
% plot(LoRarx_1.AntennaPosition(2), LoRarx_1.AntennaPosition(1), 'ws','markersize',7,'markerfacecolor','k');     % Rx
% hold off
% 
% figure; imagesc([xmin xmax],[ymin ymax], flipud(SNR_LoRa_grid.')); axis xy equal;
% colorbar; title('LoRa SNR (dB)'); xlabel('y [m]'); ylabel('x [m]');
% hold on; 
% plot(LoRatx.AntennaPosition(2), LoRatx.AntennaPosition(1), 'wo','markersize',8,'markerfacecolor','r'); % Tx
% plot(LoRarx_1.AntennaPosition(2), LoRarx_1.AntennaPosition(1), 'ws','markersize',7,'markerfacecolor','k');     % Rx
% hold off
% 
% figure; imagesc([xmin xmax],[ymin ymax], flipud(PER_LoRa.')); axis xy equal;
% colorbar; clim([0 1]); title(['LoRa PER (SF' SF ')']); xlabel('y [m]'); ylabel('x [m]');
% hold on; 
% plot(LoRatx.AntennaPosition(2), LoRatx.AntennaPosition(1), 'wo','markersize',8,'markerfacecolor','r'); % Tx
% plot(LoRarx_1.AntennaPosition(2), LoRarx_1.AntennaPosition(1), 'ws','markersize',7,'markerfacecolor','k');     % Rx
% hold off
% Define a function to handle the plotting
function plotField(Arg, ttl, txpos, rxpos, ymin,ymax,xmin,xmax)
    figure; 
    imagesc([ymin ymax], [xmin xmax], Arg'); % Transpose Z to match axes
    axis xy equal tight; colorbar; 
    title(ttl); xlabel('y [m]'); ylabel('x [m]');
    hold on; 
    plot(txpos(2), txpos(1), 'wo', 'markersize', 8, 'markerfacecolor', 'r'); % Tx marker
    plot(rxpos(2), rxpos(1), 'ws', 'markersize', 7, 'markerfacecolor', 'k'); % Rx marker
    hold off;
end
% Use the plot function to generate each of your plots:
PgridFS_BLE = reshape(sigstrength([rxGrid{:}], BLEtx, pm_fs), size(xg));
PgridFS_LoRa = reshape(sigstrength([rxGrid{:}], LoRatx, pm_fs), size(xg));

% Plot each field using the defined function
plotField(PgridFS_BLE, 'BLE Rx Power (dBm)', BLEtx.AntennaPosition, BLErx_1.AntennaPosition,ymin,ymax,xmin,xmax);
plotField(PgridFS_LoRa, 'LoRa Rx Power (dBm)', LoRatx.AntennaPosition, LoRarx_1.AntennaPosition,ymin,ymax,xmin,xmax);
% plotField(Pgrid_BLE_dBm, 'BLE Rx Power (dBm) – Ray/Other', BLEtx.AntennaPosition, BLErx_1.AntennaPosition,ymin,ymax,xmin,xmax);
% plotField(Pgrid_LoRa_dBm, 'LoRa Rx Power (dBm) – Ray/Other', LoRatx.AntennaPosition, LoRarx_1.AntennaPosition,ymin,ymax,xmin,xmax);
plotField(SNRib_avg, 'BLE SNR (dB)', BLEtx.AntennaPosition, BLErx_1.AntennaPosition,ymin,ymax,xmin,xmax);
plotField(SNRil_avg, 'LoRa SNR (dB)', LoRatx.AntennaPosition, LoRarx_1.AntennaPosition,ymin,ymax,xmin,xmax);
plotField(BER_BLE_avg, 'BLE BER', BLEtx.AntennaPosition, BLErx_1.AntennaPosition,ymin,ymax,xmin,xmax);

plotField(PER_LoRa, sprintf('LoRa PER (SF%s)', SF), LoRatx.AntennaPosition, LoRarx_1.AntennaPosition,ymin,ymax,xmin,xmax);

