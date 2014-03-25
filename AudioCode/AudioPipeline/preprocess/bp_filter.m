function Hd = bp_filter
%BP_FILTER Returns a discrete-time filter object.

% MATLAB Code
% Generated by MATLAB(R) 8.1 and the Signal Processing Toolbox 6.19.
% Generated on: 11-Feb-2014 12:29:08

% Butterworth Bandpass filter designed using FDESIGN.BANDPASS.

% All frequency values are in Hz.
Fs = 16000;  % Sampling Frequency

Fstop1 = 740;         % First Stopband Frequency
Fpass1 = 750;         % First Passband Frequency
Fpass2 = 820;         % Second Passband Frequency
Fstop2 = 830;         % Second Stopband Frequency
Astop1 = 80;          % First Stopband Attenuation (dB)
Apass  = 10;           % Passband Ripple (dB)
Astop2 = 80;          % Second Stopband Attenuation (dB)
match  = 'passband';  % Band to match exactly

% Construct an FDESIGN object and call its BUTTER method.
h  = fdesign.bandpass(Fstop1, Fpass1, Fpass2, Fstop2, Astop1, Apass, ...
                      Astop2, Fs);
Hd = design(h, 'butter', 'MatchExactly', match);

% [EOF]