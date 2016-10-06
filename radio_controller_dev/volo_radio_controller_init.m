

% XILINX DDS Generator Phase increment (1MHz sine wave at 80MHz sample clock)
dds_generator_phase_inc_binary = dec2bin(hex2dec('33333333333'));

index = 2077;

repeat = 12;
 %load board3_dat.mat
% 
% rawData = board3_dat.rawDat;
% i_raw = rawData{index}.iArr;
% q_raw = rawData{index}.qArr;


%iArr = repmat(rawData{index}.iArr, 1, repeat);
%qArr = repmat(rawData{index}.qArr, 1, repeat);
% iArr = real(ret)*1.85;
% qArr = imag(ret)*1.85;

clear I_in Q_in

%I_in = [(1:length(iArr)).'  iArr.']*1.87;
%Q_in = [(1:length(qArr)).'  qArr.']*1.87;


% PARAMETERS
ramDepth=2047;
fir_len = 64;

fir_coeff_txerr = fir1(fir_len, [0.25 0.27], 'DC-0');%fir1(64, 0.25, 'high');

% fir_coeff_loft_lo = fir1(fir_len/2, 0.195, 'high');
% fir_coeff_loft_hi = fir1(fir_len/2, 0.205, 'low');

% fir_coeff_loft = conv(fir_coeff_loft_lo, fir_coeff_loft_hi);
fir_coeff_loft = fir1(fir_len, [0.195 0.205], 'DC-0');

fir_coeff_ssb = fir1(fir_len, [0.245 0.255], 'DC-0');


fir_coeff_loft_rx = fir1(fir_len, [0.03], 'low');

% FINAL AVERAGE
avg_len = 2048;
avg_del = log2(2048);
avg_scale = -1*avg_del;

dc_avglen = 256;


% Settings for Volo Radio Mult Testing

phase = 0;
magDB = -0.7;

gain = 1;

mag = 10^(magDB/10);


pRad = deg2rad(phase);

cMult = mag*cos(pRad);
sMult = mag*sin(pRad);


% g_inv = max(abs([cMult, 1+sMult, -1+sMult, 1-sMult, -1-sMult]));
g_inv = max(cMult, 1+sMult);
gain = 1/g_inv;

cFI = fi(cMult, 1, 13, 11);
sFI = fi(sMult, 1, 13, 11);
gFI = fi(gain, 1, 13, 11);

%% Stuff for Tx/Rx FIR filter values
addpath('./etc');

float_COEF_5MHz = load('FIR_Coef_LowPass5'); 
float_COEF_10MHz = load('FIR_Coef_LowPass10'); 
float_COEF_20MHz =load('FIR_Coef_LowPass20'); 

fixed_COEF_5MHz =fi(float_COEF_5MHz.Num5,1,16,14);
fixed_COEF_10MHz=fi(float_COEF_10MHz.Num10,1,16,14);
fixed_COEF_20MHz=fi(float_COEF_20MHz.Num,1,16,14);

COEF_5MHz = fixed_COEF_5MHz.data;
COEF_10MHz = fixed_COEF_10MHz.data;
COEF_20MHz = fixed_COEF_20MHz.data;


