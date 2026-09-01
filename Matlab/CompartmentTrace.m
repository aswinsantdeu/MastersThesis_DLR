filename = fullfile(dataDir,"Compartment1.glb");
viewer = siteviewer(SceneModel=filename,ShowEdges=false,ShowOrigin=true);

BLEtx = txsite("cartesian",AntennaPosition=[-2; -3; 2.4],TransmitterFrequency=2.4e9);
BLErx_1 = rxsite("cartesian",AntennaPosition=[-1; 0; 1]);
BLErx_2 = rxsite("cartesian",AntennaPosition=[1; 0; 1]);

LoRatx = txsite("cartesian",AntennaPosition=[-2; 3; 2.4],TransmitterFrequency=0.868e9);
LoRarx_1 = rxsite("cartesian",AntennaPosition=[-1; 0.5; 1]);
LoRarx_2 = rxsite("cartesian",AntennaPosition=[1; 0.5; 1]);

pm = propagationModel("raytracing", CoordinateSystem="cartesian", Method="sbr");
% ray1 = raytrace(BLEtx, BLErx_1, pm, Map=viewer);
% ray2 = raytrace(BLEtx, BLErx_2, pm, Map=viewer);

pm.MaxNumReflections = 1;
pm.MaxNumDiffractions = 1;
raytrace(BLEtx,[BLErx_1 BLErx_2],pm)

raytrace(LoRatx,[LoRarx_1 LoRarx_2],pm)

PBLErx_1_dBm = sigstrength(BLErx_1, BLEtx, pm, Map=viewer);


%los(BLEtx,[BLErx_1 BLErx_2])

% Visualize the transmitter and receiver sites in the viewer
% show(BLEtx,Map=viewer);
% show(BLErx_1,Map=viewer);
% show(BLErx_2,Map=viewer);