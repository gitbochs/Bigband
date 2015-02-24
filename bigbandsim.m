close all
clear all

%% Receiver Parameters

effectiveBW = 900e6; %Nyquist Region for Fs = p*channelFs
p = 8; %Undersampling Factor
nfft = 128;

effectiveFs = effectiveBW*2;
channelFs = effectiveFs/p;

wrapTime = 1/effectiveFs;

timeDelays = [0,.33,1]'*wrapTime;

%% Signal Model
t = (0:nfft*p-1)*1/effectiveFs; %Time vector for non-aliased signal
f = [122e6,287e6,411e6]; %signal frequencies
A = [1;1;1];

% Figure out time vector for different channels after application of time
% delay

t = repmat(t,3,1);
t = t+repmat(timeDelays,1,size(t,2));

% Generate signal for different channels (i.e. at different delays)
for i = 1:3
    temp = repmat(A,1,size(t,2)).*sin(2*pi*f'*t(i,:));
    s(i,:) = sum(temp,1);
end
plot(s')

%Undersample
s = s(:,1:p:end);
figure()
plot(s')
for i = 1:3
    sF(i,:) = fft(s(i,:),nfft);
end

%% Estimate Frequency

[values, buckets] = findpeaks(abs(sF(1,1:nfft/2))); % Find peaks in buckets

b1 = sF(1,:); %Non-delayed spectrum
b2 = sF(3,:); %Delayed spectrum

values = b1(buckets);
%For each occupied bucket, estimate the true frequency by comparing phase
%difference between the delayed spectrum and non-delayed spectrum
for i = 1:length(buckets)
    ind = buckets(i);
    phaseEst = abs(angle(b2(ind)/b1(ind)));
    freqEst(i) = phaseEst/(2*pi*timeDelays(3));
end

freqEst/1e6;
freq = 0:channelFs/nfft:(channelFs-channelFs/nfft);

%% Construct xhat

freq = 0:effectiveFs/(p*nfft):(effectiveFs-effectiveFs/(p*nfft));
xf = zeros(size(freq));
for i = 1:length(buckets)
   [v,k] = min(abs(freqEst(i)-freq));
   xf(k) = values(i);
   freq(k) = inf;
end

sEst = ifft(xf,nfft*p);

plot(imag(sEst))