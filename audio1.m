% ============================================================
% DIALOGUE BOOSTER V12 - keep the dialogue, turn down the background
% Idea: commentary sits in the CENTER (mid), crowd/FX are spread WIDE (side).
% V11 processed only the mid and left the side untouched, which made the
% dialogue quieter relative to the background. V12 does the opposite.
% ============================================================
clear; clc;

input_filename = 'jonathanslattermusic_football_commentator_with_fx_that_is_nothing_but_incredible_546898_V3.wav';
if ~isfile(input_filename)
    error('File "%s" not found.', input_filename);
end

[audio, Fs] = audioread(input_filename);
if size(audio, 2) ~= 2
    error('This version needs a stereo file.');
end

% ---- settings (the only things you need to tune) ----
side_gain   = 0.3;    % background (side) level: 0.5 = -6 dB, 0.3 = -10 dB, 0.15 = -16 dB
hp_hz       = 90;     % cut rumble below this
lp_hz       = 9000;   % soften harsh top end above this
pres_lo     = 1800;   % dialogue clarity band (Hz)
pres_hi     = 4200;
pres_db     = 2.0;    % clarity boost in dB (0 = off)
target_peak = 0.95;

% ---- mid/side split ----
mid  = (audio(:,1) + audio(:,2)) / 2;
side = (audio(:,1) - audio(:,2)) / 2;

% ---- dialogue (mid): clean band-limit + gentle clarity boost (zero-phase) ----
[b, a] = butter(2, hp_hz/(Fs/2), 'high');
mid = filtfilt(b, a, mid);
[b, a] = butter(2, lp_hz/(Fs/2), 'low');
mid = filtfilt(b, a, mid);

[b, a] = butter(2, [pres_lo pres_hi]/(Fs/2), 'bandpass');
presence = filtfilt(b, a, mid);
mid = mid + (10^(pres_db/20) - 1) * presence;

% ---- background (side): turn it down ----
side = side * side_gain;

% ---- recombine, peak-normalize ----
output = [mid + side, mid - side];
output = output * (target_peak / max(abs(output(:))));

audiowrite('enhanced_audio_V12.wav', output, Fs);

% ---- diagnostics ----
rms_db = @(x) 20*log10(sqrt(mean(x.^2)) + 1e-12);
o_mid  = (audio(:,1) + audio(:,2)) / 2;
o_side = (audio(:,1) - audio(:,2)) / 2;
e_mid  = (output(:,1) + output(:,2)) / 2;
e_side = (output(:,1) - output(:,2)) / 2;

fprintf('\n=============================================\n');
fprintf('Dialogue (mid) level   : orig %.1f dBFS -> new %.1f dBFS\n', rms_db(o_mid), rms_db(e_mid));
fprintf('Background vs dialogue : orig %.1f dB -> new %.1f dB\n', rms_db(o_side) - rms_db(o_mid), rms_db(e_side) - rms_db(e_mid));
fprintf('=============================================\n');