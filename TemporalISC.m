%% Temporal ISC


%% Start

clc
clear
restoredefaultpath


%% Enter

% TimeCourse Path
TimeCoursePath = 'TimeCoursePath';

% Output Path
OutputPath = 'OutputPath';

% Subject List
SubjectList = {'sub-01','sub-02','sub-03','sub-04','sub-06','sub-08','sub-09','sub-11','sub-13','sub-14','sub-16','sub-17','sub-18','sub-19','sub-20','sub-21'};
nSubjects = length(SubjectList);

% Task List
TaskList = importdata('TaskList.mat');
nTasks = length(TaskList);

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


%% Temporal ISC

% Start the Parallel Pool
parpool(5);

parfor iTask = 1 : nTasks
    
    % Load the Time Course of All the Subjects
    TimeCourse_SingleSubject_File = dir(fullfile(TimeCoursePath,SubjectList{1},[SubjectList{1},'_task-',TaskList{iTask},'*.mat']));
    TimeCourse_SingleSubject = importdata(fullfile(TimeCoursePath,SubjectList{1},TimeCourse_SingleSubject_File(1).name));
    [nVertices,nTimePoints] = size(TimeCourse_SingleSubject);
    TimeCourse = zeros(nVertices,nTimePoints,nSubjects);
    for iSubject = 1 : nSubjects
        TimeCourse_SingleSubject_File = dir(fullfile(TimeCoursePath,SubjectList{iSubject},[SubjectList{iSubject},'_task-',TaskList{iTask},'*.mat']));
        TimeCourse_SingleSubject = importdata(fullfile(TimeCoursePath,SubjectList{iSubject},TimeCourse_SingleSubject_File(1).name));
        TimeCourse(:,:,iSubject) = TimeCourse_SingleSubject;
    end
    disp([TaskList{iTask},': Load the Time Course: Done']);
    
    % Calculate the Veritable ISC
    ISC_LeaveoutMean_Veritable = zeros(nVertices,1);
    for iVertex = 1 : nVertices
        TimeCourse_iParcel = squeeze(TimeCourse(iVertex,:,:));
        ISC_Leaveout_Veritable_iParcel = zeros(nSubjects,1);
        for iSubject = 1 : nSubjects
            TimeCourse_iParcel_iSubject = TimeCourse_iParcel(:,iSubject);
            TimeCourse_iParcel_OtherSubjects = TimeCourse_iParcel;
            TimeCourse_iParcel_OtherSubjects(:,iSubject) = NaN;
            TimeCourse_iParcel_OtherSubjects = mean(TimeCourse_iParcel_OtherSubjects,2,'omitnan');
            ISC_Leaveout_Veritable_iParcel(iSubject,1) = atanh(corr(TimeCourse_iParcel_iSubject,TimeCourse_iParcel_OtherSubjects));
        end
        ISC_LeaveoutMean_Veritable(iVertex) = mean(ISC_Leaveout_Veritable_iParcel);
    end
    disp([TaskList{iTask},', Leaveout ISC: Veritable, Done.']);
    parsave(fullfile(OutputPath,['task-',TaskList{iTask},'_ISC-Veritable.mat']),ISC_LeaveoutMean_Veritable,'ISC_LeaveoutMean_Veritable');
    
    % Subject-wise Bootstrapping
    tic
    ISC_LeaveoutMean_Bootstrap = zeros(nVertices,nResamples);
    for iResample = 1 : nResamples
        TimeCourse_Bootstrap = TimeCourse(:,:,Resamples(iResample,:));
        for iVertex = 1 : nVertices
            TimeCourse_Bootstrap_iParcel = squeeze(TimeCourse_Bootstrap(iVertex,:,:));
            ISC_Leaveout_Bootstrap_iParcel = zeros(nSubjects,1);
            for iSubject = 1 : nSubjects
                TimeCourse_iParcel_iSubject = TimeCourse_Bootstrap_iParcel(:,iSubject);
                TimeCourse_iParcel_OtherSubjects = TimeCourse_Bootstrap_iParcel;
                Index = find(Resamples(iResample,:) == Resamples(iResample,iSubject));
                TimeCourse_iParcel_OtherSubjects(:,Index) = NaN;
                TimeCourse_iParcel_OtherSubjects = mean(TimeCourse_iParcel_OtherSubjects,2,'omitnan');
                ISC_Leaveout_Bootstrap_iParcel(iSubject) = atanh(corr(TimeCourse_iParcel_iSubject,TimeCourse_iParcel_OtherSubjects));
            end
            ISC_LeaveoutMean_Bootstrap(iVertex,iResample) = mean(ISC_Leaveout_Bootstrap_iParcel);
        end
        disp([TaskList{iTask},', Leaveout ISC: Bootstrapping, ',num2str(iResample),'/',num2str(nResamples),', ',num2str(toc),'s.']);
    end
    parsave(fullfile(OutputPath,['task-',TaskList{iTask},'_ISC-Bootstrap.mat']),ISC_LeaveoutMean_Bootstrap,'ISC_LeaveoutMean_Bootstrap');
    
end
        
% Shut Down the Parallel Pool
p = gcp;
delete(p);

