%% Contrasts among the ISFCs of Different Conditions


%% Start

clc
clear
restoredefaultpath
addpath('Path of the EPEPT Software'); % Fewer permutations, more accurate P-values, Knijnenburg et al. (2009)


%% Enter

% ISFC Path
ISFCPath = 'Path of ISFC';

% Output Path
OutputPath = 'Output Path';

% Contrast List
ContrastList = readtable('Path of ContrastList.xlsx','FileType','spreadsheet','ReadVariableNames',true,'ReadRowNames',true);
[nContrasts,nConditions] = size(ContrastList);


%% Load the ISFC of All the Conditions

tic

% Bootstrap
ISFC_Bootstrap_Rest = importdata(fullfile(ISFCPath,'task-rest_ISFC-LeaveoutMean_desc-symmetric_Bootstrap.mat'));
[nParcels,~,nResamples] = size(ISFC_Bootstrap_Rest);
ISFC_Bootstrap = zeros(nParcels,nParcels,nResamples,nConditions);
for iCondition = 1 : nConditions
    ISFC_Bootstrap(:,:,:,iCondition) = importdata(fullfile(ISFCPath,['task-',ContrastList.Properties.VariableNames{iCondition},'_ISFC-LeaveoutMean_desc-symmetric_Bootstrap.mat']));
end

% Veritable
ISFC_Veritable = zeros(nParcels,nParcels,nConditions);
for iCondition = 1 : nConditions
    ISFC_Veritable(:,:,iCondition) = importdata(fullfile(ISFCPath,['task-',ContrastList.Properties.VariableNames{iCondition},'_ISFC-LeaveoutMean_desc-symmetric_Veritable.mat']));
end

disp(['Load the Data of ISFC: ',num2str(toc),'s.']);


%% Contrast

for iContrast = 1 : nContrasts
    tic
    Weight = ContrastList{iContrast,:};
    Contrast_Veritable = zeros(nParcels,nParcels);
    NullDistribution = zeros(nParcels,nParcels,nResamples);
    P = zeros(nParcels,nParcels);
    SES = zeros(nParcels,nParcels);
    Skewness = zeros(nParcels,nParcels);
    for iParcel = 1 : nParcels
        for jParcel = iParcel : nParcels
            ISFC_Veritable_ijParcel = squeeze(ISFC_Veritable(iParcel,jParcel,:));
            Contrast_Veritable(iParcel,jParcel) = Weight *  ISFC_Veritable_ijParcel;
            Contrast_Veritable(jParcel,iParcel) = Contrast_Veritable(iParcel,jParcel);
            for iResample = 1 : nResamples
                ISFC_Bootstrap_ijParcel_iResample = squeeze(ISFC_Bootstrap(iParcel,jParcel,iResample,:));
                Contrast_Bootsrap_ijParcel_iResample = Weight *  ISFC_Bootstrap_ijParcel_iResample;
                NullDistribution(iParcel,jParcel,iResample) = Contrast_Bootsrap_ijParcel_iResample - Contrast_Veritable(iParcel,jParcel);
                NullDistribution(jParcel,iParcel,iResample) = NullDistribution(iParcel,jParcel,iResample);
            end
            P(iParcel,jParcel) = Ppermest(Contrast_Veritable(iParcel,jParcel),NullDistribution(iParcel,jParcel,:));
            P(jParcel,iParcel) = P(iParcel,jParcel);
            SES(iParcel,jParcel) = (Contrast_Veritable(iParcel,jParcel) - mean(NullDistribution(iParcel,jParcel,:))) / std(NullDistribution(iParcel,jParcel,:),1);
            SES(jParcel,iParcel) = SES(iParcel,jParcel);
            Skewness(iParcel,jParcel) = skewness(NullDistribution(iParcel,jParcel,:));
            Skewness(jParcel,iParcel) = Skewness(iParcel,jParcel);
        end
    end
    FWECriterion = prctile(squeeze(max(max(NullDistribution))),(1-0.05)*100);
    H_FWE = Contrast_Veritable >  FWECriterion;
    save(fullfile(OutputPath,['contrast-',ContrastList.Properties.RowNames{iContrast},'_ISFC-LeaveoutMean_desc-symmetric_ContrastVeritable.mat']),'Contrast_Veritable');
    save(fullfile(OutputPath,['contrast-',ContrastList.Properties.RowNames{iContrast},'_ISFC-LeaveoutMean_desc-symmetric_P.mat']),'P');
    save(fullfile(OutputPath,['contrast-',ContrastList.Properties.RowNames{iContrast},'_ISFC-LeaveoutMean_desc-symmetric_SES.mat']),'SES');
    save(fullfile(OutputPath,['contrast-',ContrastList.Properties.RowNames{iContrast},'_ISFC-LeaveoutMean_desc-symmetric_Skewness.mat']),'Skewness');
    save(fullfile(OutputPath,['contrast-',ContrastList.Properties.RowNames{iContrast},'_ISFC-LeaveoutMean_desc-symmetric_H_FWE.mat']),'H_FWE');
    disp(['Contrast: ',ContrastList.Properties.RowNames{iContrast},', ',num2str(toc),'s']);
end

