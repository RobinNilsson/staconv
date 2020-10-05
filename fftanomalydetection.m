clear all;
close all;
load 'signalGeneratordata.mat'

% Perform moving window FFT anomaly detection
winLength = anomalyLength;  %Length of moving window
winStep = anomalyLength / 5;
detectionCenterChannel = winLength / anomalyWavelength; %Choose center channel of known anomaly frequency
detectionBandWidth = 2; % Half width of detection band (channels) 
referenceChannelMin = 100;
referenceChannelMax = 200;
detectionBandMin = detectionCenterChannel - detectionBandWidth;
detectionBandMax = detectionCenterChannel + detectionBandWidth;
jj = 1;
figure(1);
for ii = 1:winStep:dataLength - winLength
    winData = signalDataAnomaly(ii:(ii + winLength));
    winFFT = abs(fft(winData));
    anomalyArea = sum(winFFT(detectionBandMin:detectionBandMax)) / (detectionBandMax - detectionBandMin);
    referenceArea = sum(winFFT(referenceChannelMin:referenceChannelMax)) / (referenceChannelMax - referenceChannelMin);
    anomalyDetectionVec(jj,1) = anomalyArea / referenceArea;    %Detected anomaly quotient 
    anomalyDetectionVec(jj,2) = ii;                             %Moving window start index
    anomalyDetectionVec(jj,3) = ii + winLength;                 %Moving window end index 
    anomalyDetectionVec(jj,4) = floor(ii + winLength / 2);      %Moving window center index
    anomalyDetectionVec(jj,5) = time(ii);                       %Moving window start time
    anomalyDetectionVec(jj,6) = time(ii + winLength);           %Moving window end time
    anomalyDetectionVec(jj,7) = time(floor(ii + winLength / 2));%Moving window center time
    
    
    if true  %Set to TRUE for individual FFT plot
        anomalyHitFlag = sum(anomalyLabel(ii:(ii + winLength))) > 0;
        if anomalyHitFlag
            plot(winFFT(2:100),'r');
        else
            plot(winFFT(2:100),'b');
        end
        drawnow;
    end
    
    jj = jj + 1;
end
jj = jj-1;
figure(2)
plot(anomalyDetectionVec(:,7),anomalyDetectionVec(:,1));
ylim([-1 1000]);
hold on
plot(time,(anomalyLabel*100)-0,'r');
datetick;

%Calculate anomalyFlag by thresholding
for ii = 1:200;
    anomalyThreshold = ii;
    anomalyFlag = zeros(length(anomalyDetectionVec),1);
    anomalyFlag = 1 * (anomalyDetectionVec(:,1) >= anomalyThreshold);
    
    %Calculate confusion matrix
    anomalyFlagReference = anomalyLabel(anomalyDetectionVec(:,4));
    totalSum = length(anomalyFlag);
    truePositive(ii) = sum(anomalyFlag & anomalyFlagReference);
    trueNegative(ii) = sum(~anomalyFlag & ~anomalyFlagReference);
    falsePositive(ii) = sum(anomalyFlag & ~anomalyFlagReference);
    falseNegative(ii) = sum(~anomalyFlag & anomalyFlagReference);
    truePositiveRate(ii) = truePositive/(truePositive + falseNegative);
    trueNegativeRate(ii) = trueNegative/(falsePositive + trueNegative);
end
figure(3)
plot(truePositiveRate,'g')
hold on
plot(trueNegativeRate,'r')

%Choose the threshold value when TRP and TNR crosses
diffTprTnr = abs(truePositiveRate-trueNegativeRate);
anomalyThreshold = find(diffTprTnr == min(diffTprTnr));
anomalyFlag = 1 * (anomalyDetectionVec(:,1) >= anomalyThreshold);

%Calculate confusion matrix again for the choosen threshold
truePositive = sum(anomalyFlag & anomalyFlagReference);
trueNegative = sum(~anomalyFlag & ~anomalyFlagReference);
falsePositive = sum(anomalyFlag & ~anomalyFlagReference);
falseNegative = sum(~anomalyFlag & anomalyFlagReference);
truePositiveRate = truePositive/(truePositive + falseNegative);
trueNegativeRate = trueNegative/(falsePositive + trueNegative);
confMatrix = [[truePositive, falsePositive];[falseNegative, trueNegative]]
