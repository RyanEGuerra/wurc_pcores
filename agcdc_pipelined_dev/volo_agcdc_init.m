% =========================================================================
% Shared Registerd and Settings for the AGC_DC block
% 
% May 2013
% me@ryaneguerra.com
% =========================================================================

addpath('./etc');

% power threshold for detecting a packet, ignore anything below this
regAGC_pktDetCorr_minPower = 0.0003;        
% threshold value for packet detection via short autocorrelation
regAGC_pktDetCorr_ratioThresh = 0.7;    
% The number of samples that the Schmidl-Cox decision threshold must be
% crossed before a packet is declared "detected"
regAGC_pktDetMinDuration_autoCorr = 32;  % 48 default from WARPv3 OFDM 18.1
% The target gain value for the AGc block. The AGC will adjust Rx gains
% until the power of the Rx signal at the ADC is close to this level or it
% times out. Whichever comes first. Hex: 0x01E2
regAGC_targetRxInputPwr = -28.8;
% For the standalone energy-based packet detector, what is the desired
% average power difference threshold for detecting a packet?
% This is currently an arbitrary number and should be tuned.
% Hex: 0x01C4 = -60 Fix9_0
regAGC_pktDetPwr_deltaThreshold_dBm = 10;
% When searching for the deltaThreshold, compare power samples that are
% this lag time far apart. This is becasue if you compare back-to-back
% samples, the average detector ramps up rather than having a sudden jump
% in dB and that would be difficult to distinguish from noise variation.
% Max value is 63.
regAGC_pktDetPwr_detectLag = 16;
% For the standalong energy-based packet detector, what is the absolute
% power threshold over which we declare a packet as detected?
% This is currently arbitrary and should be tuned.
regAGC_pktDetPwr_absoluteThreshold_dBm = -60;

regAGC_WSD_CCAThreshold_dBm = -40;
% Long cross-correlation threshold for deciding whether the long correlator
% has suceeded in detecting and synchronizing the packet. This is a large
% value, so all 32 bits of precision are allowed.
regAGC_LongCorr_Threshold = 4000;
% Timeout for AGC convergence.
% Arbitrary now, should be tuned.
regAGC_ConvergenceTimeout = 128;
% Timeout for payload completion.
% Arbitrary now, should be tuned.
regAGC_Payload_TimeoutCount = 20000;
% Number of fine gain steps to take after saturation is removed.
regAGC_NumFineGainSteps = 2;
% Default gain values for the AGC. These are the large, blind gain steps
% that are triggers when saturation is detected at the ADC during the
% preamble of the data packet.
% This was made into a shared register to allow the default values to be
% chaged without a re-synthesis.
agc_HighGain = 61;
agc_MidGain = 34;
agc_LowGain = 7;
agc_NoGain = 6;     % because LNA is never set, don't let this go below 6
regAGC_DefaultGainSettings = agc_NoGain + ...
                             agc_LowGain * 2^8 + ...
                             agc_MidGain * 2^16 + ...
                             agc_HighGain * 2^24;                         
% Backoff values for dynamic default AGC gain adaptation.
% Note: the ideal step size is actually 27 dB. We choose 24
% because we don't really know how well this works and I'd
% like to provide a 3 dB margin (in addition to Rx gain
% estimation error) of overlap to avoid having a strange "blind spot"
% for incoming packet powers.
% The No-Gain option becomes 6 dBm, preventing the 
agc_Dyn_HighBits = 0;           % these are currently unused in the model
agc_Dyn_HighGain_Backoff = 24;  %dB
agc_Dyn_LowGain_Backoff = 48;   %dB
agc_Dyn_NoGain = 6;             %dBm - LNA is never set, don't get go below 6
regAGC_DynBackoffSettings  = agc_Dyn_NoGain + ...
                             agc_Dyn_LowGain_Backoff * 2^8 + ...
                             agc_Dyn_HighGain_Backoff * 2^16 + ...
                             agc_Dyn_HighBits * 2^24;
% Default gain values for the three gain blocks. This is used when AGC is
% enabled, only, and is only a default.
regAGC_ManualRxVGA1_Gain = 0;
regAGC_ManualRxVGA2_Gain = 0;
regAGC_ManualRxLNA_Gain = 6;

% I/Q value that triggers a "saturation warning" if exceeded
% TODO: need to tune this value
regSatDet_SaturationThreshold = 0.8;
% Count value for the maximum number of saturation warnings in 16 samples
% before issuing a saturation detection event
% TODO: need to tune this value
regSatDet_SaturationMaxCount = 3;
% The total number of samples required for a good SatDet, as well as the
% length of the SatDet.
regSatDet_NumSamples = 16;

% The total number of samples required to detect the average incoming power
% of the I/Q signal reliably. This should be tuned - max length available
% is 64, and the values MUST be a power of two!!
regPwrMeas_AvgLength = 32;
% Since some of the power measurement values can be VERY low, 
regPwrMeas_minPwrMeasuredThreshold = -44;

% A bunch of parameters to use for the AGC FSM block.
% This is all parametrized in order to avoid embedded magic values, but
% these values should not be changed without good reason.
agc_idleState = 0;
agc_numStates = 8;
agc_numInputs = 4;
agc_numOutputs = 4;
agc_numStateBits = ceil(log2(agc_numStates));
agc_numAddrBits = agc_numOutputs + agc_numStateBits;
% AGC ROM initialization files. See state machine transition tables on
% FARADProject.com
A = csvread('AGC_Next_State_ROM.csv');
agc_next_state_ROM = reshape( A', 1, numel(A));
B = csvread('AGC_output_ROM.csv');
agc_output_ROM = reshape(B', 1, numel(B));
if (numel(agc_next_state_ROM) ~= 2^agc_numAddrBits...
 || numel(agc_output_ROM) ~= 2^agc_numAddrBits)
    error('REG001: Wrong number of ROM initialization elements!');
end

% The number of samples to use as a window when estimating the mean voltage
% level of the raw I or raw Q input. This mean is then subtracted from the
% raw I/Q streams to remove the DC component.
% This value can be either 16, 32, or 64 only!!
regDCRemoval_AvgLength = 64;

% Table of gain register settings in order to control which combination of
% LNA and VGA settings are used to get to each overall target gain value.
% The LMS6002D FAQ guide claims that VGA1 should be maximized first before
% applying gain from VGA2 (this makes sense, as VGA1 is before the LPF).
% The LNA should be active in just about all cases to preserve the input
% SNR.
C = csvread('Gain_ROM_Table.csv');
J_RxVGA1_Gain =  C(:,5);
K_RxVGA2_Gain =  C(:,6);
L_RxLNA_Gain =  C(:,7);
GAIN_ROM = J_RxVGA1_Gain + ...
           K_RxVGA2_Gain * 2^8 + ...
           L_RxLNA_Gain * 2^16;
       
% Tranlation table for the gain setting of RxVGA2. This is required because
% the gain of that block is not log-linear with respect to the register
% code setting.
D = csvread('RxVGA1_Gain_ROM_Table.csv');
J_RxVGA1_CODE_ROM = D(:,1);     %note: swapped columns is correct

% Tranlation table for the gain setting of RxVGA1. This is required because
% the gain of that block is 1/3 the value of the gain setting.
E = csvread('RxVGA2_Gain_ROM_Table.csv');
K_RxVGA2_CODE_ROM = E(:,2);

% Tranlation table for the gain setting of RxLNA. This is required because
% the gain of that block is 1/3 the value of the gain setting.
F = csvread('RxLNA_Gain_ROM_Table.csv');
L_RxLNA_CODE_ROM = F(:,2);

% Length of the delay required to wait for a baseband SPI write to finish.
% Each SPI command is 16 bits, plus whatever propagation delays exist
% between the AGC block, the SPI block and the actual transceiver.
% Maximum value is 255.
regSPICtrl_SPIWriteDelay = 20;

