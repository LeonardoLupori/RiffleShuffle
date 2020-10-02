%% SETUP

clear, clc

%\\\SET
    % Full path to folder containing images.
    % Multichannel images should be split into separate channels and named
    % with a trailing "_C1" and "_C2" accordingly to the channel
    pathIn = '/scratch/RiffleShuffle/Stacks/Dataset_B_1.55_2.45';

    % Path to contour and mask machine learning models
    pathModelC = '/scratch/RiffleShuffle/SupportFiles/modelC.mat';
    pathModelM = '/scratch/RiffleShuffle/SupportFiles/modelM.mat';

    % If to quantify spots (otherwise quantifies diffuse signal)
    quantSpots = true; 
%///

l1 = listfiles(pathIn,'_C1.tif');   % First channel (contour extimation)
l2 = listfiles(pathIn,'_C2.tif');   % Second channel (quantification)
load(pathModelC);
load(pathModelM);


%% Measure a spot - for automatic spot detection

%\\\SET
    % index of image to use to test spot parameters
    i = 1;
%///
    
I2 = imread(l2{i});
J2 = imresize(I2,0.5);
spotMeasureTool(normalize(im2double(J2)));


%% Test spot detection parameters (no need to run if not quantifying spots)

%\\\SET
    % index of image to use to test spot detection
    i = 1;
    
    % sigma of spot (measured above)
    sigma = 3.6;
    
    % 'distance to background distribution' threshold; decrease to detect more spots (range [0,~100])
    dist2BackDistThr = 5;
    
    % 'similarity to ideal spot' threshold; decrease to select more spots (range [-1,1])
    spotinessThreshold = 0.8;
%///

I = imread(l1{i});
I2 = imread(l2{i});

J = imresize(I,0.1);
J2 = imresize(I2,0.5);

doubleJ = normalize(double(J));
L = pixelClassifierClassify(doubleJ,modelMask);
Mask = bwareafilt(L == 2,[0.01*numel(L) Inf]);

[~,ptSrcImg] = logPSD(J2, imresize(Mask,size(J2),'nearest'), sigma, dist2BackDistThr);
ptSrcImg = selLogPSD(J2, ptSrcImg, sigma, spotinessThreshold);

[r,c] = find(ptSrcImg);

J2 = imresize(J2,0.2);
r = r/5;
c = c/5;

imshow(imadjust(J2)), hold on
plot(c,r,'o'), hold off


%% Downsizes images, detects spots, writes to file

pathOut = [pathIn '_Downsized'];
if ~exist(pathOut,'dir')
    mkdir(pathOut);
end

pfpb = pfpbStart(length(l1));   % Progression monitor for the parfor

% Cycles through all the images
parfor i = 1:length(l1)
    I = imread(l1{i});      % First channel
    I2 = imread(l2{i});     % Second Channel
    
    J = imresize(I,0.1);
    J2 = imresize(I2,0.5);
    
    doubleJ = normalize(double(J));
    
    % Detect contour probability map
    [~,contourPM] = pixelClassifierClassify(doubleJ,modelC);
    contourPM = contourPM(:,:,1);
    
    % Detect mask (pixels belonging or not to the brain slice)
    L = pixelClassifierClassify(doubleJ,modelM);
    Mask = bwareafilt(L == 2,[0.01*numel(L) Inf]);

    if quantSpots
        % The automatic quantification of the spots is done on the second
        % chahhel (_C2) in the original images. The raw images are resized
        % to 50% of their original size for this step.
        [~,ptSrcImg] = logPSD(J2, imresize(Mask,size(J2),'nearest'), sigma, dist2BackDistThr);
        ptSrcImg = selLogPSD(J2, ptSrcImg, sigma, spotinessThreshold);
        [r,c] = find(ptSrcImg);
        r = r/5;
        c = c/5;
    end
    
    % ---------------------------------------------------------------------
    % WRITE OUTPUT IMAGES TO THE FOLLOWING FILESin the "/_Downsized" FOLDER:
    % "*_C1.tif": channel used to find contours
    % "*_CQ.tif": channel to quantify (instead of quantifying spots)
    % "*_M.png": Mask
    % "*_C.png": Contour probability maps
    % "*.csv": spot locations
    % ---------------------------------------------------------------------
    fullName = [pathOut filesep sprintf('I%03d_C1.tif',i)];
    % IMPROVEMENT - isn't this matrix equal to just J? maybe replace with 
    % J to avoid multiple rounding and casting steps
    imwrite(uint8(255*doubleJ),fullName);
    
    fullName = [pathOut filesep sprintf('I%03d_CQ.tif',i)];
    tiffwriteimj(imresize(J2,size(J)),fullName);
    
    fullName = [pathOut filesep sprintf('I%03d_M.png',i)];
    imwrite(255*uint8(Mask),fullName);
    
    fullName = [pathOut filesep sprintf('I%03d_C.png',i)];
    imwrite(uint8(255*contourPM),fullName);
    if quantSpots
        fullName = [pathOut filesep sprintf('I%03d.csv',i)];
        writetable(array2table([r c],'VariableNames',{'r','c'}),fullName);
    end
    
    pfpbUpdate(pfpb);
end


%% Check saved files
% For each slice shows images of: 
%   * the channel for the contours (C1), 
%   * the Channel for the quantification (CQ)
%   * the estimated mask (M)
%   * the contour probability mask (C)

if exist('figHandle','var') && ishandle(figHandle)
    close(figHandle)    % Close existing figure if cell is run twice
end

figureQSS

figHandle = gcf;
figHandle.NumberTitle = 'off';
figHandle.Name = 'Check saved files for each slice';

for i = 1:length(l1)
    I = imread([pathOut filesep sprintf('I%03d_C1.tif',i)]);
    Q = imread([pathOut filesep sprintf('I%03d_CQ.tif',i)]);
    M = imread([pathOut filesep sprintf('I%03d_M.png',i)]);
    C = imread([pathOut filesep sprintf('I%03d_C.png',i)]);
    A = table2array(readtable([pathOut filesep sprintf('I%03d.csv',i)]));
    
    subplot(1,4,1)
    titleStr = sprintf('Original-(%u/%u)', i, length(l1));
    imshow(imadjust(I)), title(titleStr)
    
    subplot(1,4,2)
    imshow(imadjust(Q))
    if quantSpots
        hold on, plot(A(:,2),A(:,1),'o'), hold off
    end
    titleStr = sprintf('Quantification-(%u/%u)', i, length(l1));
    title(titleStr)
    
    subplot(1,4,3)
    titleStr = sprintf('Mask-(%u/%u)', i, length(l1));
    imshow(M), title(titleStr)
    
    subplot(1,4,4)
    titleStr = sprintf('Contour-(%u/%u)', i, length(l1));
    imshow(C), title(titleStr)
    pause%(0.1)
end
close all

