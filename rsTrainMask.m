clear, clc

p = 'D:\PizzorussoLAB\proj_wholeBrainPNN\DATA\ML_randomForest\training_01\mask_PV';
modelM = pixelClassifierTrain(p);

%% save model

save('D:\PizzorussoLAB\proj_wholeBrainPNN\DATA\ML_randomForest\training_01/modelM_PV.mat','modelM');

%%

imPaths = listfiles(p,'.tif');

i = 1;
I = imreadGrayscaleDouble(imPaths{i});
L = pixelClassifierClassify(I,modelM);
Mask = bwareafilt(L == 2,[0.01*numel(L) Inf]);
switchBetween(I,Mask)