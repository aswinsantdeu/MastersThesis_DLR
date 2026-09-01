# MasterThesis_DLR
Heterogeneous Wireless Communication  Architecture in a Modular Research Vessel

The objective of this project is to develop and deploy a heterogeneous wireless network
(HetNet) offering seamless and secure data communication without using Wi-Fi bands.
The system incorporates a LoRa point-to-point link (868 MHz) for long-range communication,
a Bluetooth Low Energy link (BLE, 2.4 GHz) for onboard sensor data collection, and a custom prototype built for Near-Field Magnetic Induction (NFMI, 10 MHz) for short-range communication in an electromagnetically challenging environment.

Characterized performance for BLE and LoRa with an indoor channel modeling and ray tracing simulations in MATLAB from a 3-D model of a steel compartment made in Blender 4.1, Evaluated large-scale path loss and small-scale Rician fading and key performance metrics (RSSI, SNR, BER), 

The NFMI system was modeled and simulated at the circuit level in LTspice and at a physical level in CST Studio Suite to investigate the magnetic flux density and field strength with and without obstructions. 

Experimental validation was obtained using a steel cage constructed from ship-grade steel to test attenuation and interference effects of the three communication layers. 
Results confirm fading of BLE and LoRa signals in encapsulated enclosures by
measuring the metric of relative attenuation, while NFMI exhibited near 0dB attenuation
and penetration through steel doors. 
With optimized coil design following improved Q factor and impedance matching, the NFMI channel could be a valuable RF replacement system inside a HetNet, which can be a Wi-Fi alternative for continuous sensor telemetry in a maritime environment.
