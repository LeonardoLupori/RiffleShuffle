%% [SET] SETUP

clear, clc

%\\\SET
    interiorContourDependence = true;
    % true: interior morphing depends on contour morphing; false: interior content is matched directly to atlas
    
    quantSpots = false;
    % true: quantify spots; false: quantify diffuse signal
    
    interactive = true;
    % true: interactive mode (run cell by cell);
    % false: fast track (run by calling rsPlaneAssignment in Matlab's prompt)
%///

%% [SET] Read and resize the Allen Institute template

%\\\SET
    path = 'C:\Users\Leonardo\Documents\MATLAB\wholeBrainPNN\RiffleShuffle_exampleDATA\SupportFiles\template.tif';
    % full path to template.tif

    resizeFactorZ = 0.5;
    % downsizing in z makes pairwise assignment faster
%///

fprintf([repmat('*',1,20) '\n'])
fprintf('IMAGE ASSIGNMENT TO ALLEN BRAIN ATLAS TEMPLATE\n')

fprintf(['Template location: ' strrep(path,'\','\\') '\n'])
fprintf('Reading and resizing Allen institute template...')

F = volumeRead(path);
F = normalize(imresize3(F,[size(F,1) size(F,2) size(F,3)*resizeFactorZ]));
if interactive
tlvt(F)
end

fprintf(' done.\n')

%% [SET] Read volume to register

%\\\SET
    imFolder = 'D:\PizzorussoLAB\proj_wholeBrainPNN\DATA\tiff8bit\RGB_ordered_channels\2_Downsized';
    % full path to _Downsized folder
%///

path = [imFolder '_Registered.tif'];

fprintf(['Volume path: ' strrep(path,'\','\\') '\n'])
fprintf('Reading and normalizing experimental volume...')

M = normalize(volumeRead(path));

if interactive
tlvt(M)
end

fprintf(' done.\n')
% bregmas increase from back to front
% template has planes from front to back

%% [SET] Read bregma values; crop template

%\\\SET

    manualAssignmentPath = 'D:\PizzorussoLAB\proj_wholeBrainPNN\DATA\tiff8bit\images_classification.xlsx';
    macroArea = 2;
%     b0 = -5.692315789; % smallest estimated bregma in dataset
%     b1 = -0.650578947; % largest estimated bregma in dataset
%     indices = [77,88,93,97,101,107,111,116,119,121,123,125,127,132,134,138,...
%         147,152,157,164,169,173,177,179,182,186,193,197,199,206,209,217,220,222,225,227,236,238];
    
%///

% Load putative bregma values from table
sliceTab = readtable(manualAssignmentPath);
indices = sliceTab.candidateBregma(sliceTab.macroArea==macroArea);
indices = round(indices* resizeFactorZ);

% Template bregma coordinates
b0_t = -7.905; 
b1_t = 5.345;
bregmas = linspace(b1_t,b0_t,size(F,3));

fprintf('Reading user-defined bregma values and cropping template...')

% Added by LEO & VALE
% ---------
bregmasAnnotated = bregmas(indices)';
b1 = bregmasAnnotated(1);
b0 = bregmasAnnotated(end);
% ---------
% bregmasAnnotated = linspace(b1,b0,size(M,3))';

% indices of template z-planes to which the most anterior(s10) and most 
% posterior(s00) slices of the dataset map
[~,s00] = min(abs(bregmas-b0));
[~,s10] = min(abs(bregmas-b1));

% Extra planes as 10% of the total range of the dataset
nExtraPlanes = round(0.1*(s00-s10+1));
% Corrects s00 and s10 for border effects
s0 = min(s00+nExtraPlanes,size(F,3));
s1 = max(s10-nExtraPlanes,1);

% Update number of extra planes after correction for border effect
nExtraLeft = s10-s1;
nExtraRight = s0-s00;

% Subset of interest of the template volume
subsetVolume = F(:,:,s1:s0);
bregmas = bregmas(s1:s0)';

% Filter the subset to highlight borders
subF = normalize(imgaussfilt3(imgradient3(subsetVolume),3));

% onset = nExtraLeft+1;
% offset = size(subF,3)-nExtraRight;
% initialMatch = round(linspace(onset,offset,size(M,3)));

% Added by LEO & VALE
% ---------
initialMatch = indices-s1+1;

if interactive
    figureQSS
    subplot(1,2,1)
    graystackmontage(subF), title('template')
    subplot(1,2,2)
    graystackmontage(M), title('to register')
end

fprintf(' done.\n')

%% [SET] Find out re-scaling factors
% divide length on data (image tool 2) by length on template (image tool 1)
% set as parameters fx,fy on cell below

%\\\SET
    imIndex = 15;
%///


% if interactive
% imtool(subF(:,:,round(size(subF,3)/2)))
% imtool(M(:,:,round(size(M,3)/2)))
% end

if interactive
imtool(subF(:,:,initialMatch(imIndex)))
imtool(M(:,:,imIndex))
end

%% [SET] Re-scale template to match scale of data

%\\\SET
    fx = 250/277; % horizontal direction scaling (data/template)
    fy = 173/210; % vertical direction scaling (data/template)
%///

fprintf('Resizing Allen template to match the scaling of experimental data...')

RsubF = imresize3(subF,[fy*size(subF,1) fx*size(subF,2) size(subF,3)]);
% imshow(RsubF(:,:,round(size(RsubF,3)/2))), imdistline
% figure, pause(0.5)
% imshow(M(:,:,round(size(M,3)/2))), imdistline
if interactive
imtool(RsubF(:,:,initialMatch(imIndex)))
imtool(M(:,:,imIndex))
end

fprintf(' done.\n')

%% [SET] Optimal plane assignment

imSubSeq = stack2list(M);       % Dataset
imSeq = stack2list(RsubF);      % Allen template Volume

%\\\SET
    scaleRange = 0.9:0.05:1.1;
    % range of scales to test during optimal plane assignment
    
    vertDispRange = -10:2:10;
    % range of vertical displacements to test during optimal plane assignment
    
    maxShift = 2;  % nExtraPlanes
    % maximum plane offset from initial guess based on equally spaced distribution
%///

fprintf('Assignment to optimal planes...\n')

if interactive
displayProgress = true;
displayOutput = true;
optimalAssignmentIndices = dpMatchPlanes(imSubSeq,imSeq,scaleRange,vertDispRange,initialMatch,maxShift,displayProgress,displayOutput);
T = array2table([bregmasAnnotated bregmas(optimalAssignmentIndices)],'VariableNames',{'orig_bregmas','assign_bregmas'});
disp(T)
end
fprintf(' done.\n')

%% Transform planes, save results

fprintf('Transforming planes...')


if interactive

% Dataset
% ---------------------------------------
Z = zeros(size(imSeq{1},1),size(imSeq{1},2),3); % Default black image    
R1 = [];        % Matrix to hold wide image of plane assignments
count = 0;      % Num of planes currently assigned
tforms = cell(1,length(imSubSeq));              %  Transform objects
TimSubSeq = cell(1,length(imSubSeq));           % Transformed Images

% Iteratively build the "dataset" portion of the wide image
for i = 1:length(imSeq)
    if min(abs(optimalAssignmentIndices-i)) == 0
        count = count+1;
        [TI,~,tform] = imscalereg(imSubSeq{count},imSeq{i},scaleRange,scaleRange,vertDispRange);
        TimSubSeq{count} = TI;
        tforms{count} = tform;
        R1 = [R1 insertText(normalize(TI),[0 0],sprintf('%d: %.02f',count,bregmasAnnotated(count)))];
    else
        R1 = [R1 Z];
    end
end

% Template
% ---------------------------------------
R2 = [];
% Iteratively build the "template" portion of the wide image
for i = 1:length(imSeq)
    R2 = [R2 insertText(imSeq{i},[0 0],sprintf('%d: %.02f',i,bregmas(i)))];
end

% Export the wide image as a tiff file
fprintf(' done. Saving results...')
imwrite([R1; R2],[imFolder '_Bregma_Assignment.tif']);

% Export plane assignment to a CSV file
bregmaAssignmentArray = [(1:length(optimalAssignmentIndices))' optimalAssignmentIndices bregmasAnnotated bregmas(optimalAssignmentIndices)];
bregmaAssignmentTable = array2table(bregmaAssignmentArray,...
    'VariableNames',{'dataset_index','atlas_index','bregmas_annotated','bregmas_assigned'});
writetable(bregmaAssignmentTable,[imFolder '_Bregma_Assignment.csv']);
end
fprintf(' done.\n')

%% edit (if needed)

% check assignment in _Bregma_Assignment.tif
% edit assignment in _Bregma_Assignment.csv (second column) if needed (if you do, run the session below)

%% run this if edits were made in _Bregma_Assignment.csv (it'll run automatically if interactive = false)
% an image visualizing the new assignment is saved as _Bregma_Assignment_Edited.tif

disp('recover plane assignment')
bregmaAssignmentTable = readtable([imFolder '_Bregma_Assignment.csv']);
bregmaAssignmentArray = table2array(bregmaAssignmentTable);
optimalAssignmentIndices = bregmaAssignmentArray(:,2);

Z = zeros(size(imSeq{1},1),size(imSeq{1},2),3);
R1 = [];
count = 0;
tforms = cell(1,length(imSubSeq));
TimSubSeq = cell(1,length(imSubSeq));
for i = 1:length(imSeq)
    disp([i length(imSeq)])
    if min(abs(optimalAssignmentIndices-i)) == 0
        count = count+1;
        [TI,~,tform] = imscalereg(imSubSeq{count},imSeq{i},scaleRange,scaleRange,vertDispRange);
        TimSubSeq{count} = TI;
        tforms{count} = tform;
        R1 = [R1 insertText(normalize(TI),[0 0],sprintf('%d: %.02f',count,bregmasAnnotated(count)))];
    else
        R1 = [R1 Z];
    end
end
R2 = [];
for i = 1:length(imSeq)
    R2 = [R2 insertText(imSeq{i},[0 0],sprintf('%d: %.02f',i,bregmas(i)))];
end

imwrite([R1; R2],[imFolder '_Bregma_Assignment_Edited.tif']);

%% check transformed planes

if interactive
for i = 1:length(tforms)
    im11 = centerCrop(imadjust(imSubSeq{i}),size(RsubF,2),size(RsubF,1));
    im12 = imadjust(TimSubSeq{i});
    im22 = imadjust(imSeq{optimalAssignmentIndices(i)});
    switchBetween([im11 im12],[im12 im22])
%     switchBetween(imadjust(TimSubSeq{i}),imadjust(imSeq{optimalAssignmentIndices(i)}))
end
end

%% Read and transform masks and quantification images (*_M and *_CQ)

fprintf('Reading and transforming masks and quantification images...')

pathPts = [imFolder '_Registered'];
nImages = length(imSubSeq);
tMasks = cell(1,nImages);
tQImgs = cell(1,nImages);

for i = 1:nImages
    
    % Load images
    Mask = imread([pathPts filesep sprintf('I%03d_M.png',i)]);
    QImg = im2double(imread([pathPts filesep sprintf('I%03d_CQ.tif',i)]));
    
    % Transform masks
    I = imSubSeq{i};
    Mask = imresize(Mask,size(I),'nearest');
    TMask = imwarp(Mask,tforms{i},'OutputView',imref2d(size(TI))) > 0;
    tMasks{i} = TMask;
    
    % Transform quantification images
    QImg = imresize(QImg,size(I));
    TQImg = imwarp(QImg,tforms{i},'OutputView',imref2d(size(TI)));
    tQImgs{i} = TQImg;
    
    if interactive
%         imshow(QImg)
        imshowpair(imadjust(TimSubSeq{i}),tMasks{i}), pause(0.2)
    end
end
if interactive
    close all
end
fprintf(' done.\n')

%% prepare to register planes

disp('prepare to register planes')

IJs = cell(nImages,2);
for i = 1:nImages
    disp([i nImages])
%     I = normalize(TimSubSeq{i});
%     J = normalize(imSeq{optimalAssignmentIndices(i)});
    I = adapthisteq(normalize(TimSubSeq{i}));
    J = adapthisteq(normalize(imSeq{optimalAssignmentIndices(i)}));
    if interiorContourDependence
        M = imbinarize(J);
        M = imfill(M,'holes');
        MOut = bwmorph(M,'dilate',10);
        MIn = bwmorph(M,'erode',10);
        M = MOut & not(MIn);   
        M = imgaussfilt(double(M),3);
        I = normalize(steerableDetector(I.*M,4,5));
        J = normalize(steerableDetector(J.*M,4,5));

        MI = imbinarize(I);
        MI0 = bwmorph(MI,'thin',Inf);
%         for j = 1:3
%             MI = imresize(MI,0.7,'nearest');
%             r0 = round((size(MI0,1)-size(MI,1))/2);
%             c0 = round((size(MI0,2)-size(MI,2))/2);
%             MI1 = false(size(MI0));
%             MI1(r0+1:r0+size(MI,1),c0+1:c0+size(MI,2)) = MI;
%             MI0 = MI0 | bwmorph(MI1,'thin',Inf);
%         end
        I = double(MI0);

        MI = imbinarize(J);
        MI0 = bwmorph(MI,'thin',Inf);
%         for j = 1:3
%             MI = imresize(MI,0.7,'nearest');
%             r0 = round((size(MI0,1)-size(MI,1))/2);
%             c0 = round((size(MI0,2)-size(MI,2))/2);
%             MI1 = false(size(MI0));
%             MI1(r0+1:r0+size(MI,1),c0+1:c0+size(MI,2)) = MI;
%             MI0 = MI0 | bwmorph(MI1,'thin',Inf);
%         end
        J = double(MI0);
    end
    
    IJs{i,1} = I;
    IJs{i,2} = J;
    if interactive
    imshow([I J]), pause(0.1)
    end
%     switchBetween(I,J)
end
if interactive
close all
end

%% reg with Matlab

Ds = cell(1,nImages);
TIs = cell(1,nImages);
for i = 1:nImages
    disp([i nImages])
    Ds{i} = imregdemons(IJs{i,1},IJs{i,2},'DisplayWaitbar',false);
    TIs{i} = imwarp(IJs{i,1},Ds{i});
end

%% check registration (plane by plane)
% press 'space' to continue

if interactive
for i = 1:nImages
    I = IJs{i,1};
    TI = TIs{i};
    J = IJs{i,2};
    switchBetween([I TI],[TI J])
end
end

%% check registration (volumes)

if interactive
TI3 = zeros(size(TI,1),size(TI,2),nImages);
J3 = zeros(size(TI,1),size(TI,2),nImages);
for i = 1:nImages
    TI3(:,:,i) = TIs{i};
    J3(:,:,i) = IJs{i,2};
end
tlvt([TI3 J3])
end

%% check reg on 'original' images (plane by plane)
% press 'space' to continue

if interactive
for i = 1:nImages
    I = normalize(TimSubSeq{i});
    J = imSeq{optimalAssignmentIndices(i)};
	D = Ds{i};
    TI = imwarp(I,D);
    switchBetween([I TI],[TI J])
end
end

%% check reg on 'original' images (volumes)

if interactive
TI3 = zeros(size(TI,1),size(TI,2),nImages);
J3 = zeros(size(TI,1),size(TI,2),nImages);
for i = 1:nImages
    I = normalize(TimSubSeq{i});
    J = imSeq{optimalAssignmentIndices(i)};
	D = Ds{i};
    TI = imwarp(I,D);
    TI3(:,:,i) = TI;
    J3(:,:,i) = J;
end
tlvt([TI3 J3])
end

%% [SET] Read points / transform (similarity)

fprintf('Reading points coordinates from CSV and transforming (similarity)...')
txys = cell(1,nImages);
for i = 1:nImages    
    xy = table2array(readtable([pathPts filesep sprintf('I%03d.csv',i)]));
%\\\SET
    % scale factor
    % see 'write volume for registration to Allen Institute atlas' session in rsStackRegistration.m
    xy = xy*10*0.548/25;
%///
    
    txy = transformSpots(xy,tforms{i});
    txys{i} = txy;
    
    if interactive
        subplot(1,2,1)
        imshow(imadjust(imSubSeq{i})), hold on
        plot(xy(:,1),xy(:,2),'.'), hold off
        subplot(1,2,2)
        imshow(imadjust(TimSubSeq{i})), hold on
        plot(txy(:,1),txy(:,2),'.'), hold off
        pause(0.1)
    end
end
fprintf(' done.\n')
close all

%% Transform points / masks (non-linear)

fprintf('Transforming points, masks, quantification images (non-linear)...')
% figureQSS
ttxys = cell(1,nImages);
ttMasks = cell(1,nImages);
ttQImgs = cell(1,nImages);
for i = 1:nImages
    I = TimSubSeq{i};
    D = Ds{i};
    TI = imwarp(I,D);
    txy = txys{i};
    
    TMask = tMasks{i};
    TTMask = imwarp(TMask,D);
    ttMasks{i} = TTMask;
    
    TQImg = tQImgs{i};
    TTQImg = imwarp(TQImg,D);
    ttQImgs{i} = TTQImg;

    ttxy = zeros(size(txy));
    for j = 1:size(txy,1)
        row = min(max(round(txy(j,2)),1),size(D,1));
        col = min(max(round(txy(j,1)),1),size(D,2));
        ttxy(j,1) = txy(j,1)-D(row,col,1);
        ttxy(j,2) = txy(j,2)-D(row,col,2);
    end
    ttxys{i} = ttxy;
    
    if interactive
        subplot(3,2,1)
        imshow(imadjust(I)), hold on
        plot(txy(:,1),txy(:,2),'.'), hold off
        subplot(3,2,2)
        imshow(imadjust(TI)), hold on
        plot(ttxy(:,1),ttxy(:,2),'.'), hold off
        subplot(3,2,3)
        imshow(TMask), hold on
        plot(txy(:,1),txy(:,2),'.'), hold off
        subplot(3,2,4)
        imshow(TTMask), hold on
        plot(ttxy(:,1),ttxy(:,2),'.'), hold off
        subplot(3,2,5)
        imshow(imadjust(TQImg)), hold on
        plot(txy(:,1),txy(:,2),'.'), hold off
        subplot(3,2,6)
        imshow(imadjust(TTQImg)), hold on
        plot(ttxy(:,1),ttxy(:,2),'.'), hold off
        pause(0.1)
    end
end
fprintf(' done.\n')
close all

%% [SET] read / crop annotations / re-scale / convert to list

fprintf('Reading, cropping and re-scaling annotations...')

%\\\SET
    atlasLabelsPath = 'C:\Users\Leonardo\Documents\MATLAB\wholeBrainPNN\RiffleShuffle_exampleDATA\SupportFiles\annotationsUInt32.tif';
    % full path to annotationsUInt32.tif
%///

A = volumeRead(atlasLabelsPath);
A = imresize3(A,size(F),'nearest');
maxA = max(A(:));
subA = A(:,:,s1:s0);
RsubA = imresize3(subA,[fy*size(subA,1) fx*size(subA,2) size(subA,3)],'nearest');
annotSeq = stack2list(RsubA);
fprintf(' done.')

%% build point-counting / signal quant planes

pcp = cell(1,nImages);

for i = 1:nImages
    P = imSeq{optimalAssignmentIndices(i)};
    if quantSpots
        xy = ttxys{i};
        cr = round(xy);
        C = zeros(size(P));
        for j = 1:size(cr,1)
            col = cr(j,1); row = cr(j,2);
            if row >= 1 && row <= size(C,1) && col >= 1 && col <= size(C,2)
                C(row,col) = C(row,col)+1;
            end
        end
        pcp{i} = C;
    else
        C = ttQImgs{i};
        pcp{i} = uint16(65535*C);
    end
    
    if interactive
%     switchBetween(P,normalize(C))
    imshowpair(P,normalize(C)), pause(0.1)
    end
end
pcpStack = list2stack(pcp);
masksStack = imopen(list2stack(ttMasks) > 0,strel('sphere',1)); % masks from data, not template
close all

%% [SET] Count

disp('count')

%\\\
    pathRegIDs = 'C:\Users\Leonardo\Documents\MATLAB\wholeBrainPNN\RiffleShuffle_exampleDATA\SupportFiles\RegionIDs.csv';
    % full path to RegionIDs.csv
%///

T = readtable(pathRegIDs);
CT = table2cell(T);

regionIndices = cat(1,CT{:,1})';
regionCounts = zeros(1,length(regionIndices));
regionCountsM = zeros(1,length(regionIndices));

subRsubA = zeros(size(pcpStack));
for i = 1:nImages
    A = annotSeq{optimalAssignmentIndices(i)};
    subRsubA(:,:,i) = A;
    C = pcp{i};
    M = masksStack(:,:,i);
    for j = 1:length(regionIndices)
        regionCounts(j) = regionCounts(j)+sum(C(A == regionIndices(j)));
        regionCountsM(j) = regionCountsM(j)+sum(M(A == regionIndices(j)));
    end
end

C = cell(length(regionIndices),5);
for i = 1:length(regionIndices)
    C{i,1} = regionIndices(i);
    C{i,2} = CT{i,2};
    C{i,3} = regionCounts(i);
    C{i,4} = regionCountsM(i);
    C{i,5} = regionCounts(i)/regionCountsM(i);
end

T = cell2table(C,'VariableNames',{'AreaID','AreaName','Quant','Volume','Average'});

if quantSpots
    qType = 'Spots';
else
    qType = 'Signal';
end
path = [imFolder sprintf('_Quant_%s.csv',qType)];
writetable(T,path);

%% [SET] Visualize quantification

disp('visualize quantization')

%\\\SET
    regionID = 972;
%///

pcpStackN = normalize(pcpStack);
maskA = subRsubA == regionID;
maskAB = maskA;
% maskAB = maskA & not(imerode(maskA,strel('sphere',1)));

% V = cat(4,maskAB,normalize(pcpStackN));
% tiffwriteimj(V,[imFolder sprintf('_HeatMap_%s_%d.tif',qType,regionID)]);

if interactive
    pcpStackN(maskAB) = 1;
    tlvt(pcpStackN)
end

disp('done')