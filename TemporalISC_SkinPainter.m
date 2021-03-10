%% Skin Painter (ISC)
% Paint the Skin for Workbench Visualization.


%% Start

clear
clc
restoredefaultpath
addpath('Path of SPM12');
addpath ('Path of FieldTrip');
ft_defaults
[status] = ft_hastoolbox('GIFTI', 2, 0);


%% Enter

% ISC Path
ISCPath = 'Path of ISC';

% ISC Contrast Path
ISCContrastPath = 'Path of ISC Contrast';

% Contrast List
ContrastList = readtable('Path of ContrastList.xlsx','FileType','spreadsheet','ReadVariableNames',true,'ReadRowNames',true);
[nContrasts,nTasks] = size(ContrastList);

% Output Path
OutputPath = 'Output Path';

% The Path of wb_command
wb_commandPath = 'Path of wb_command';

% The Path of Standard Mesh Atlases
StandardMeshAtlasesPath = 'Path of Standard Mesh Atlases';

% Threshold for the Cluster Size (mm2)
SurfaceMinimumArea = 200;


%% Basic Contrasts

for iContrast = 1 : nContrasts
    
    % Load the Contrast Files
    P = importdata(fullfile(ISCContrastPath,['contrast-',ContrastList.Properties.RowNames{iContrast},'_ISC_P.mat']));
    SES = importdata(fullfile(ISCContrastPath,['contrast-',ContrastList.Properties.RowNames{iContrast},'_ISC_SES.mat']));
    nVertices = length(P)/2;
    
    % Write the Contrast Files into the .func.gii Images
    % P
    L = P(1 : nVertices);
    L = gifti(L);
    R = P(nVertices + 1 : 2 * nVertices);
    R = gifti(R);
    save(L,fullfile(OutputPath,['contrast-',ContrastList.Properties.RowNames{iContrast},'_space-fsaverage5_hemi-L_ISC_P.func.gii']),'Base64Binary');
    save(R,fullfile(OutputPath,['contrast-',ContrastList.Properties.RowNames{iContrast},'_space-fsaverage5_hemi-R_ISC_P.func.gii']),'Base64Binary');
    % SES
    L = SES(1 : nVertices);
    L = gifti(L);
    R = SES(nVertices + 1 : 2 * nVertices);
    R = gifti(R);
    save(L,fullfile(OutputPath,['contrast-',ContrastList.Properties.RowNames{iContrast},'_space-fsaverage5_hemi-L_ISC_SES.func.gii']),'Base64Binary');
    save(R,fullfile(OutputPath,['contrast-',ContrastList.Properties.RowNames{iContrast},'_space-fsaverage5_hemi-R_ISC_SES.func.gii']),'Base64Binary');
    % FDR Correction
    H = fdr_bh(P,0.05,'dep');
    SES = SES .* H;
    L = SES(1 : nVertices);
    L = gifti(L);
    R = SES(nVertices + 1 : 2 * nVertices);
    R = gifti(R);
    save(L,fullfile(OutputPath,['contrast-',ContrastList.Properties.RowNames{iContrast},'_space-fsaverage5_hemi-L_ISC_SES-FDR.func.gii']),'Base64Binary');
    save(R,fullfile(OutputPath,['contrast-',ContrastList.Properties.RowNames{iContrast},'_space-fsaverage5_hemi-R_ISC_SES-FDR.func.gii']),'Base64Binary');
    
    
    % Transform fsaverage5 Space to the fsLR Space
    CommandHead = wb_commandPath;
    CommandStructure = 'wb_command -metric-resample %s %s %s ADAP_BARY_AREA %s -area-metrics %s %s';
    % Left Hemisphere:
    CurrentSphere = fullfile(StandardMeshAtlasesPath,'resample_fsaverage','fsaverage5_std_sphere.L.10k_fsavg_L.surf.gii');
    NewSphere = fullfile(StandardMeshAtlasesPath,'resample_fsaverage','fs_LR-deformed_to-fsaverage.L.sphere.32k_fs_LR.surf.gii');
    CurrentArea = fullfile(StandardMeshAtlasesPath,'resample_fsaverage','fsaverage5.L.midthickness_va_avg.10k_fsavg_L.shape.gii');
    NewArea = fullfile(StandardMeshAtlasesPath,'resample_fsaverage','fs_LR.L.midthickness_va_avg.32k_fs_LR.shape.gii');
    % P
    MetricIn = fullfile(OutputPath,['contrast-',ContrastList.Properties.RowNames{iContrast},'_space-fsaverage5_hemi-L_ISC_P.func.gii']);
    MetricOut = fullfile(OutputPath,['contrast-',ContrastList.Properties.RowNames{iContrast},'_space-fsLR_hemi-L_ISC_P.func.gii']);
    Command = sprintf(CommandStructure,MetricIn,CurrentSphere,NewSphere,MetricOut,CurrentArea,NewArea);
    Command = [CommandHead,Command];
    disp(Command);
    system(Command);
    % SES
    MetricIn = fullfile(OutputPath,['contrast-',ContrastList.Properties.RowNames{iContrast},'_space-fsaverage5_hemi-L_ISC_SES.func.gii']);
    MetricOut = fullfile(OutputPath,['contrast-',ContrastList.Properties.RowNames{iContrast},'_space-fsLR_hemi-L_ISC_SES.func.gii']);
    Command = sprintf(CommandStructure,MetricIn,CurrentSphere,NewSphere,MetricOut,CurrentArea,NewArea);
    Command = [CommandHead,Command];
    disp(Command);
    system(Command);
    % SES-FDR
    MetricIn = fullfile(OutputPath,['contrast-',ContrastList.Properties.RowNames{iContrast},'_space-fsaverage5_hemi-L_ISC_SES-FDR.func.gii']);
    MetricOut = fullfile(OutputPath,['contrast-',ContrastList.Properties.RowNames{iContrast},'_space-fsLR_hemi-L_ISC_SES-FDR.func.gii']);
    Command = sprintf(CommandStructure,MetricIn,CurrentSphere,NewSphere,MetricOut,CurrentArea,NewArea);
    Command = [CommandHead,Command];
    disp(Command);
    system(Command);
    % Right Hemisphere:
    CurrentSphere = fullfile(StandardMeshAtlasesPath,'resample_fsaverage','fsaverage5_std_sphere.R.10k_fsavg_R.surf.gii');
    NewSphere = fullfile(StandardMeshAtlasesPath,'resample_fsaverage','fs_LR-deformed_to-fsaverage.R.sphere.32k_fs_LR.surf.gii');
    CurrentArea = fullfile(StandardMeshAtlasesPath,'resample_fsaverage','fsaverage5.R.midthickness_va_avg.10k_fsavg_R.shape.gii');
    NewArea = fullfile(StandardMeshAtlasesPath,'resample_fsaverage','fs_LR.R.midthickness_va_avg.32k_fs_LR.shape.gii');
    % P
    MetricIn = fullfile(OutputPath,['contrast-',ContrastList.Properties.RowNames{iContrast},'_space-fsaverage5_hemi-R_ISC_P.func.gii']);
    MetricOut = fullfile(OutputPath,['contrast-',ContrastList.Properties.RowNames{iContrast},'_space-fsLR_hemi-R_ISC_P.func.gii']);
    Command = sprintf(CommandStructure,MetricIn,CurrentSphere,NewSphere,MetricOut,CurrentArea,NewArea);
    Command = [CommandHead,Command];
    disp(Command);
    system(Command);
    % SES
    MetricIn = fullfile(OutputPath,['contrast-',ContrastList.Properties.RowNames{iContrast},'_space-fsaverage5_hemi-R_ISC_SES.func.gii']);
    MetricOut = fullfile(OutputPath,['contrast-',ContrastList.Properties.RowNames{iContrast},'_space-fsLR_hemi-R_ISC_SES.func.gii']);
    Command = sprintf(CommandStructure,MetricIn,CurrentSphere,NewSphere,MetricOut,CurrentArea,NewArea);
    Command = [CommandHead,Command];
    disp(Command);
    system(Command);
    % SES-FDR
    MetricIn = fullfile(OutputPath,['contrast-',ContrastList.Properties.RowNames{iContrast},'_space-fsaverage5_hemi-R_ISC_SES-FDR.func.gii']);
    MetricOut = fullfile(OutputPath,['contrast-',ContrastList.Properties.RowNames{iContrast},'_space-fsLR_hemi-R_ISC_SES-FDR.func.gii']);
    Command = sprintf(CommandStructure,MetricIn,CurrentSphere,NewSphere,MetricOut,CurrentArea,NewArea);
    Command = [CommandHead,Command];
    disp(Command);
    system(Command);
    
    % Convert the gifti Images to the cifti Images
    CommandHead = wb_commandPath;
    CommandStructure = 'wb_command -cifti-create-dense-scalar %s -left-metric %s -right-metric %s';
    % P
    CIFTIOut = fullfile(OutputPath,['contrast-',ContrastList.Properties.RowNames{iContrast},'_space-fsLR_ISC_P.dscalar.nii']);
    GIFTI_Left = fullfile(OutputPath,['contrast-',ContrastList.Properties.RowNames{iContrast},'_space-fsLR_hemi-L_ISC_P.func.gii']);
    GIFTI_Right = fullfile(OutputPath,['contrast-',ContrastList.Properties.RowNames{iContrast},'_space-fsLR_hemi-R_ISC_P.func.gii']);
    Command = sprintf(CommandStructure,CIFTIOut,GIFTI_Left,GIFTI_Right);
    Command = [CommandHead,Command];
    disp(Command);
    system(Command);
    % SES
    CIFTIOut = fullfile(OutputPath,['contrast-',ContrastList.Properties.RowNames{iContrast},'_space-fsLR_ISC_SES.dscalar.nii']);
    GIFTI_Left = fullfile(OutputPath,['contrast-',ContrastList.Properties.RowNames{iContrast},'_space-fsLR_hemi-L_ISC_SES.func.gii']);
    GIFTI_Right = fullfile(OutputPath,['contrast-',ContrastList.Properties.RowNames{iContrast},'_space-fsLR_hemi-R_ISC_SES.func.gii']);
    Command = sprintf(CommandStructure,CIFTIOut,GIFTI_Left,GIFTI_Right);
    Command = [CommandHead,Command];
    disp(Command);
    system(Command);
    % SES-FDR
    CIFTIOut = fullfile(OutputPath,['contrast-',ContrastList.Properties.RowNames{iContrast},'_space-fsLR_ISC_SES-FDR.dscalar.nii']);
    GIFTI_Left = fullfile(OutputPath,['contrast-',ContrastList.Properties.RowNames{iContrast},'_space-fsLR_hemi-L_ISC_SES-FDR.func.gii']);
    GIFTI_Right = fullfile(OutputPath,['contrast-',ContrastList.Properties.RowNames{iContrast},'_space-fsLR_hemi-R_ISC_SES-FDR.func.gii']);
    Command = sprintf(CommandStructure,CIFTIOut,GIFTI_Left,GIFTI_Right);
    Command = [CommandHead,Command];
    disp(Command);
    system(Command);
    
    % Save the Clusters Surviving from the Threshold
    CommandHead = wb_commandPath;
    CommandStructure = 'wb_command -cifti-find-clusters %s %f %f 0 0 COLUMN %s -left-surface %s -right-surface %s';
    LeftSurface = fullfile(StandardMeshAtlasesPath,'L.sphere.32k_fs_LR.surf.gii');
    RightSurface = fullfile(StandardMeshAtlasesPath,'R.sphere.32k_fs_LR.surf.gii');
    CIFTIIn = fullfile(OutputPath,['contrast-',ContrastList.Properties.RowNames{iContrast},'_space-fsLR_ISC_SES-FDR.dscalar.nii']);
    CIFTIOut = fullfile(OutputPath,['contrast-',ContrastList.Properties.RowNames{iContrast},'_space-fsLR_ISC_Cluster-FDR.dscalar.nii']);
    Command = sprintf(CommandStructure,CIFTIIn,0,SurfaceMinimumArea,CIFTIOut,LeftSurface,RightSurface);
    Command = [CommandHead,Command];
    disp(Command);
    system(Command);
    
    Head = ft_read_cifti(fullfile(OutputPath,['contrast-',ContrastList.Properties.RowNames{iContrast},'_space-fsLR_ISC_Cluster-FDR.dscalar.nii']));
    Cluster = Head.dscalar;
    Cluster = Cluster > 0;
    Head = ft_read_cifti(fullfile(OutputPath,['contrast-',ContrastList.Properties.RowNames{iContrast},'_space-fsLR_ISC_SES.dscalar.nii']));
    SES = Head.dscalar;
    SES = SES .* Cluster;
    Head.dscalar = SES;
    ft_write_cifti(fullfile(OutputPath,['contrast-',ContrastList.Properties.RowNames{iContrast},'_space-fsLR_ISC_SES-FDR-Cluster']),Head,'parameter','dscalar');
end

