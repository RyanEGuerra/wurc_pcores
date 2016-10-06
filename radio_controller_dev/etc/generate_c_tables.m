% me@ryaneguerra.com
% Decemeber 16, 2013

clear all

% Numeric type to cast fixed point representation
T = numerictype(false, 16, 0);

float_COEF_5MHz = load('FIR_Coef_LowPass5'); 
float_COEF_10MHz = load('FIR_Coef_LowPass10'); 
float_COEF_20MHz =load('FIR_Coef_LowPass20'); 

fixed_COEF_5MHz  = fi(float_COEF_5MHz.Num5,1,16,14);
fixed_COEF_10MHz = fi(float_COEF_10MHz.Num10,1,16,14);
fixed_COEF_20MHz = fi(float_COEF_20MHz.Num,1,16,14);

int_COEF_5MHz = reinterpretcast(fixed_COEF_5MHz, T);
int_COEF_10MHz = reinterpretcast(fixed_COEF_10MHz, T);
int_COEF_20MHz = reinterpretcast(fixed_COEF_20MHz, T);

% Test conversion for sanity
assert(isequal(bin(fixed_COEF_5MHz), bin(int_COEF_5MHz)))
assert(isequal(bin(fixed_COEF_10MHz), bin(int_COEF_10MHz)))
assert(isequal(bin(fixed_COEF_20MHz), bin(int_COEF_20MHz)))

%dec_COEFF_5MHz = hex(int_COEFF_5MHz);
%dec_COEFF_10MHz = hex(int_COEFF_10MHz);
%dec_COEFF_20MHz = hex(int_COEFF_20MHz);

if 0
    figure()
    subplot(3, 1, 1);
        plot(fixed_COEF_5MHz, '.-');
        title('Rate-Change Filter Coefficients', 'FontSize', 14)
        legend('5 MHz');
        V = axis;
        axis([0, 128, V(3), V(4)])
        grid on;
    subplot(3, 1, 2);
        plot(fixed_COEF_10MHz, '.-');
        legend('10 MHz');
        grid on;
        V = axis;
        axis([0, 128, V(3), V(4)])
    subplot(3, 1, 3);
        plot(fixed_COEF_20MHz, '.-');
        legend('20 MHz');
        grid on;
        V = axis;
        axis([0, 128, V(3), V(4)])
end
        
fprintf('u32 VOLO_128_COEFFS_5MHZ[128] = {');
for ii = 1:1:length(int_COEF_5MHz)-1
    fprintf('0x%s, ', dec(int_COEF_5MHz(ii)))
end
fprintf('0x%s', dec(int_COEF_5MHz(ii+1)))
fprintf('};\n');

fprintf('u32 VOLO_128_COEFFS_10MHZ[128] = {');
for ii = 1:1:length(int_COEF_10MHz)-1
    fprintf('0x%s, ', dec(int_COEF_10MHz(ii)))
end
fprintf('0x%s', dec(int_COEF_10MHz(ii+1)))
fprintf('};\n');

fprintf('u32 VOLO_128_COEFFS_20MHZ[128] = {');
for ii = 1:1:length(int_COEF_20MHz)-1
    fprintf('0x%s, ', dec(int_COEF_20MHz(ii)))
end
fprintf('0x%s', dec(int_COEF_20MHz(ii+1)))
fprintf('};\n');

%COEF_5MHz = fixed_COEF_5MHz.data;
%COEF_10MHz = fixed_COEF_10MHz.data;
%COEF_20MHz = fixed_COEF_20MHz.data;