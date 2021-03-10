%% Temporal ISFC


%% Start

clear
clc
restoredefaultpath


%% Enter

% TimeCourse Path
TimeCoursePath = 'Path of the TimeCourse';

% Output Path
OutputPath = 'Output Path';

% Subject List
SubjectList = {'sub-01','sub-02','sub-03','sub-04','sub-06','sub-08','sub-09','sub-11','sub-13','sub-14','sub-16','sub-17','sub-18','sub-19','sub-20','sub-21'};
nSubjects = length(SubjectList);

% Task List
TaskList = importdata('TaskList.mat');

% Number of Resamples
nResamples = 5000;


%% Resampling with Replacement for Subject-wise Bootstraping

tic
Resamples = zeros(nResamples,nSubjects);
for iResample = 1 : nResamples
    rng('shuffle');
    Resamples(iResample,:) = datasample(1:nSubjects,nSubjects,'Replace',true);
end
save(fullfile(OutputPath,'Resamples.mat'),'Resamples');
disp(['Generate the Resample List: ',num2str(toc),'s']);


%% Calculating the Temporal ISFC

% Start the Parallel Pool
parpool(5);

nTasks = length(TaskList);
parfor iTask = 1 : nTasks
    
    % Load the Time Course of All the Subjects
    TimeCourse_SingleSubject_File = dir(fullfile(TimeCoursePath,SubjectList{1},[SubjectList{1},'_task-',TaskList{iTask},'*.mat']));
    TimeCourse_SingleSubject = importdata(fullfile(TimeCoursePath,SubjectList{1},TimeCourse_SingleSubject_File(1).name));
    [nParcels,nTimePoints] = size(TimeCourse_SingleSubject);
    TimeCourse = zeros(nParcels,nTimePoints,nSubjects);
    for iSubject = 1 : nSubjects
        TimeCourse_SingleSubject_File = dir(fullfile(TimeCoursePath,SubjectList{iSubject},[SubjectList{iSubject},'_task-',TaskList{iTask},'*.mat']));
        TimeCourse_SingleSubject = importdata(fullfile(TimeCoursePath,SubjectList{iSubject},TimeCourse_SingleSubject_File(1).name));
        TimeCourse(:,:,iSubject) = TimeCourse_SingleSubject;
    end
    disp([TaskList{iTask},': Load the Time Course: Done.']);
    
    % Calculate the Veritable ISFC
    tic
    ISFC_LeaveoutMean_Asymmetric_Veritable = NaN(nParcels,nParcels);
    for iParcel = 1 : nParcels
        for jParcel = 1 : nParcels
            ISFC_Leaveout_Veritable_ijParcel = zeros(nSubjects,1);
            for iSubject = 1 : nSubjects
                TimeCourse_iParcel_iSubject = squeeze(TimeCourse(iParcel,:,iSubject))';
                TimeCourse_jParcel_OtherSubjects = squeeze(TimeCourse(jParcel,:,:));
                TimeCourse_jParcel_OtherSubjects(:,iSubject) = NaN;
                TimeCourse_jParcel_OtherSubjects = mean(TimeCourse_jParcel_OtherSubjects,2,'omitnan');
                ISFC_Leaveout_Veritable_ijParcel(iSubject,1) = atanh(corr(TimeCourse_iParcel_iSubject,TimeCourse_jParcel_OtherSubjects));
            end
            ISFC_LeaveoutMean_Asymmetric_Veritable(iParcel,jParcel) = mean(ISFC_Leaveout_Veritable_ijParcel);
        end
    end
    ISFC_LeaveoutMean_Symmetric_Veritable = (ISFC_LeaveoutMean_Asymmetric_Veritable + ISFC_LeaveoutMean_Asymmetric_Veritable')/2;
    parsave(fullfile(OutputPath,['task-',TaskList{iTask},'_ISFC-LeaveoutMean_desc-symmetric_Veritable.mat']),ISFC_LeaveoutMean_Symmetric_Veritable,'ISFC_LeaveoutMean_Symmetric_Veritable');
    disp([TaskList{iTask},', Leaveout Mean ISFC, Veritable: ',num2str(toc),'s.']);
    
    % Calculate the Bootstrapping ISFC
    ISFC_LeaveoutMean_Symmetric_Bootstrap = NaN(nParcels,nParcels,nResamples);
    for iResample = 1 : nResamples
        tic
        ISFC_LeaveoutMean_Asymmetric_Bootstrap_iResample = NaN(nParcels,nParcels);
        for iParcel = 1 : nParcels
            for jParcel = 1 : nParcels
                ISFC_Leaveout_Bootsrap_ijParcel_iResample = zeros(nSubjects,1);
                for iSubject = 1 : nSubjects
                    TimeCourse_iParcel_iSubject = squeeze(TimeCourse(iParcel,:,iSubject))';
                    TimeCourse_jParcel_OtherSubjects = squeeze(TimeCourse(jParcel,:,:));
                    Index = find(Resamples(iResample,:) == Resamples(iResample,iSubject));
                    TimeCourse_jParcel_OtherSubjects(:,Index) = NaN;
                    TimeCourse_jParcel_OtherSubjects = mean(TimeCourse_jParcel_OtherSubjects,2,'omitnan');
                    ISFC_Leaveout_Bootsrap_ijParcel_iResample(iSubject,1) = atanh(corr(TimeCourse_iParcel_iSubject,TimeCourse_jParcel_OtherSubjects));
                end
                ISFC_LeaveoutMean_Asymmetric_Bootstrap_iResample(iParcel,jParcel) = mean(ISFC_Leaveout_Bootsrap_ijParcel_iResample);
            end
        end
        ISFC_LeaveoutMean_Symmetric_Bootstrap(:,:,iResample) = (ISFC_LeaveoutMean_Asymmetric_Bootstrap_iResample + ISFC_LeaveoutMean_Asymmetric_Bootstrap_iResample')/2;
        disp([TaskList{iTask},', Leaveout Mean ISFC, Bootstrapping: ',num2str(iResample),'/',num2str(nResamples),' ',num2str(toc),'s.']);
    end
    parsave(fullfile(OutputPath,['task-',TaskList{iTask},'_ISFC-LeaveoutMean_desc-symmetric_Bootstrap.mat']),ISFC_LeaveoutMean_Symmetric_Bootstrap,'ISFC_LeaveoutMean_Symmetric_Bootstrap');
end

% Shut Down the Parallel Pool
p = gcp;
delete(p);

