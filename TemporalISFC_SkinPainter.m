%% Skin Painter (ISFC)
% Paint the Skin for BrainNetViewer Visualization.


%% Start

clc
clear
restoredefaultpath


%% Enter

% ISFC Contrast Path
ISFCContrastPath = 'Path of ISFC Contrast';

% Output Path
OutputPath = 'Output Path';

% Contrast List
ContrastList = readtable('Path of ContrastList.xlsx','FileType','spreadsheet','ReadVariableNames',true,'ReadRowNames',true);
[nContrasts,~] = size(ContrastList);

% Node List
NodeList = readcell('Path of Schaefer200Parcels17NetworksNode.xlsx');
[nNodes,~] = size(NodeList);


%% Basic Contrasts

for iContrast = 1 : nContrasts
    Node = NodeList;
    Edge = importdata(fullfile(ISFCContrastPath,['contrast-',ContrastList.Properties.RowNames{iContrast},'_ISFC-LeaveoutMean_desc-symmetric_SES.mat']));
    EdgeThreshold = importdata(fullfile(ISFCContrastPath,['contrast-',ContrastList.Properties.RowNames{iContrast},'_ISFC-LeaveoutMean_desc-symmetric_H_FWE.mat']));
    Edge = Edge .* EdgeThreshold;
    Degree = sum(Edge);
    for iNode = 1 : nNodes
        Node{iNode,5} = Degree(iNode);
    end
    writecell(Node,fullfile(OutputPath,['contrast-',ContrastList.Properties.RowNames{iContrast},'_ISFC-LeaveoutMean_desc-symmetric_SES.node']),'FileType','text','Delimiter','tab');
    writematrix(Edge,fullfile(OutputPath,['contrast-',ContrastList.Properties.RowNames{iContrast},'_ISFC-LeaveoutMean_desc-symmetric_SES.edge']),'FileType','text','Delimiter','tab');
end

