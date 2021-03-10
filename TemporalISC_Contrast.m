%% Contrasts among the ISCs of Different Conditions


%% Start

clc
clear
restoredefaultpath
addpath('Path of the EPEPT Software'); % Fewer permutations, more accurate P-values, Knijnenburg et al. (2009)


%% Enter

% ISC Path
ISCPath = 'Path of ISC';

% Contrast List
ContrastList = readtable('Path of ContrastList.xlsx','FileType','spreadsheet','ReadVariableNames',true,'ReadRowNames',true);
[nContrasts,nConditions] = size(ContrastList);

% Output Path
OutputPath = 'Output Path';


%% Load the ISC of All the Conditions

% Bootstrap
ISC_Bootstrap_Rest = importdata(fullfile(ISCPath,'task-rest_ISC-Bootstrap.mat'));
[nVertices,nResamples] = size(ISC_Bootstrap_Rest);
ISC_Bootstrap = zeros(nVertices,nResamples,nConditions);
for iCondition = 1 : nConditions
    ISC_Bootstrap(:,:,iCondition) = importdata(fullfile(ISCPath,['task-',ContrastList.Properties.VariableNames{iCondition},'_ISC-Bootstrap.mat']));
end

% Veritable
ISC_Veritable = zeros(nVertices,nConditions);
for iCondition = 1 : nConditions
    ISC_Veritable(:,iCondition) = importdata(fullfile(ISCPath,['task-',ContrastList.Properties.VariableNames{iCondition},'_ISC-Veritable.mat']));
end


%% Contrast

for iContrast = 1 : nContrasts
    tic
    Weight = ContrastList{iContrast,:};
    P = nan(nVertices,1);
    SES = nan(nVertices,1);
    Skewness = nan(nVertices,1);
    for iVertex = 1 : nVertices
        ISC_Veritable_iVertex = ISC_Veritable(iVertex,:);
        Contrast_Veritable_iVertex = Weight *  ISC_Veritable_iVertex';
        NullDistribution_iVertex = zeros(1,nResamples);
        for iResample = 1 : nResamples
            ISC_Bootstrap_iVertex_iResample = squeeze(ISC_Bootstrap(iVertex,iResample,:));
            Contrast_Bootsrap_iVertex_iResample = Weight *  ISC_Bootstrap_iVertex_iResample;
            NullDistribution_iVertex(1,iResample) = Contrast_Bootsrap_iVertex_iResample - Contrast_Veritable_iVertex;
        end
        P(iVertex) = Ppermest(Contrast_Veritable_iVertex,NullDistribution_iVertex);
        SES(iVertex) = (Contrast_Veritable_iVertex - mean(NullDistribution_iVertex)) / std(NullDistribution_iVertex,1);
        Skewness(iVertex) = skewness(NullDistribution_iVertex);
    end
    P(isnan(ISC_Veritable(:,1))) = NaN;
    SES(isnan(ISC_Veritable(:,1))) = NaN;
    Skewness(isnan(ISC_Veritable(:,1))) = NaN;
    save(fullfile(OutputPath,['contrast-',ContrastList.Properties.RowNames{iContrast},'_ISC_P.mat']),'P');
    save(fullfile(OutputPath,['contrast-',ContrastList.Properties.RowNames{iContrast},'_ISC_SES.mat']),'SES');
    save(fullfile(OutputPath,['contrast-',ContrastList.Properties.RowNames{iContrast},'_ISC_Skewness.mat']),'Skewness');
    disp(['Contrast: ',ContrastList.Properties.RowNames{iContrast},', ',num2str(toc),'s']);
end

