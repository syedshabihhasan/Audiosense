%Ryan Brummet
%University of Iowa

%% initialize
close all;
clear;
clc;

makeGraphs = true;
outputVarFileName = 'compositeScoreOn_ap_UsingAVG';
dataFileName = 'DataTable.mat';  %must be .mat file, variable must be 'unProcessedData'
mapInfoFileName = '/Users/ryanbrummet/Documents/MATLAB/Audiology/robustMappingGraphsWtOutqolAndim/userNormalized/mapCoefVar.mat';
removeFifties = true;
omitListening = false;
omitNotListening = false;
omitUserInit = false;
omitNotUserInit = false;
omitWearingHearingAid = false;
omitNotWearingHearingAid = false;
minNumSamplesPerUser = 50;   %a user not having this # of samples has all samples removed
minPercentOfDurationFromMean = .5;    %all samples must be in the interval [avgDuration - duration*this, avgDuration + duration*this]
norm = 3;  %1 for not normalized, 2 for globally normalized, 3 for user normalized

outerCrossValFolds = 5;
innerCrossValFolds = 5;
groupVars = {'ac', 'lc', 'nz', 'patient'};  %used to build a composite variable that is used to statify in cross validation
randomizeDataSampleOrder = true;

targetAttr = 'ap';
combineScoreTechnique = 1; %1 for avg, 2 for sum, 3 for median, 4 for std, %MIN DOES NOT WORK SO IT IS LIKELY THAT MAX DOESN'T AS WELL
saveLocation = {'/Users/ryanbrummet/Documents/MATLAB/Audiology/robustMappingGraphsWtOutqolAndim/userNormalized/combinedScoreUsingMINap/'};

%% gobal variables
attributes = {'sp', 'le', 'ld', 'ld2', 'lcl', 'ap', 'qol', 'im', 'st'};
contexts = {'ac', 'lc', 'tf', 'vc', 'tl', 'nl', 'rs', 'cp', 'nz', 'condition'};
miscDataInfo = {'patient', 'listening', 'userinitiated', 'hau',};
combineScoreInfo = {'AVG', 'SUM', 'MEDIAN', 'STD', 'MAX', 'MIN'};
extractedColNames = [miscDataInfo contexts attributes];

%% preprocess data
load(dataFileName);

%remove samples where user is listening
if omitListening
    unProcessedData = unProcessedData(~strcmp(unProcessedData.listening,'true'),:);
end

%remove samples where user isn't listening
if omitNotListening
    unProcessedData = unProcessedData(~strcmp(unProcessedData.listening,'false'),:);
end

%remove samples where user initiated survey
if omitUserInit
    unProcessedData = unProcessedData(~strcmp(unProcessedData.userinitiated,'true'),:);
end

%remove samples where user didn't initiate survey
if omitNotUserInit
    unProcessedData = unProcessedData(~strcmp(unProcessedData.userinitiated,'false'),:);
end

%remove samples where user is wearing hearing aid
if omitWearingHearingAid
    unProcessedData = unProcessedData(~strcmp(unProcessedData.hau,'true'),:);
end

%remove samples where user isn't wearing hearing aid
if omitNotWearingHearingAid
    unProcessedData = unProcessedData(~strcmp(unProcessedData.hau,'false'),:);
end

%remove samples that don't make duration requirements and add unix
%timestamp to table
[unProcessedData] = findSamplesMeetingDurationReq(unProcessedData,minPercentOfDurationFromMean);

%remove fifty values
if removeFifties
    fiftyCorrectionDate = getUnixTime(2014,1,30,0,0,0);
    for k = 1 : size(attributes,2)
         unProcessedData.(attributes{k})((unProcessedData.(attributes{k}) == 50) ...
             & unProcessedData.timestamp < fiftyCorrectionDate) = NaN;
    end
end

%remove samples where all attributes are NaN
toBeRemoved = zeros(size(unProcessedData,1),1);
for k = 1 : size(attributes,2)
    toBeRemoved = isnan(unProcessedData.(attributes{k})) + toBeRemoved;
end
unProcessedData = unProcessedData(toBeRemoved < size(attributes,2),:);

%remove samples with users with an insufficient number of samples
[unProcessedData] = removeNonQualUsers(unProcessedData,minNumSamplesPerUser);

%randomize the row order of the matrix
if randomizeDataSampleOrder
    unProcessedData = unProcessedData(randperm(size(unProcessedData,1)),:);
end

%extract relevant columns
processedData = unProcessedData(:,extractedColNames);

%clear variables that are no longer needed
clearvars fiftyCorrectionDate unProcessedData 

%% Normalize Data
%for simplicity we pick the first partition of the inner and outer training
%sets.  In reality, we don't need an inner and outer training set, but we
%want to be consistent with how we generated our map Coef values
cvVar = zeros(size(processedData,1),1);
for gv = 1 : size(groupVars,2)
    if strcmp(char(groupVars{gv}),'patient')
        cvVar = cvVar + processedData.patient;
    else
        cvVar = cvVar + processedData.(groupVars{gv}) * 10 ^ (-gv);
    end
end
processedData.cvVar = cvVar;

outerCV = cvpartition(processedData.cvVar,'kfold',outerCrossValFolds);
outerTrainingSet = processedData(training(outerCV,1),:);
innerCV = cvpartition(outerTrainingSet.cvVar,'kfold',innerCrossValFolds);

if norm ~= 1
    [ normData, normAVG, normSTD ] = normalizeDataAndFindNormVals( processedData, ...
        outerTrainingSet, attributes, innerCV, 1, norm );
end


%% map attributes
%first we need to find and extract the relevant mapCoef.  For simplicity we
%look at only the first fold
load(mapInfoFileName);
targetAttr = find(strcmp(attributes,targetAttr));
index = 1;
for i = 1 : size(foldData,1)
    if foldData(i,1).targetAttr == targetAttr
        relevantMapInfo(index,:) = struct2table(foldData(i,1));
        index = index + 1;
    end
end

%now that we have the relevant mapCoef and have normalized we map
%attributes
combinedScoreData = normData;
for i = 1 : size(attributes,2)
    if targetAttr ~= i
        index = find(relevantMapInfo.mapAttr == i);
        combinedScoreData.(attributes{i}) = evaluatePolynomial(relevantMapInfo(index,:).mapCoef, normData.(attributes{i}));
    end
end

%extract normalized, mapped attributes
for k = 1 : size(attributes,2)
    normMappedAttr(:,k) = combinedScoreData.(attributes{k}); 
end

%produce combined Score
if combineScoreTechnique == 1
    combinedAttr = nanmean(normMappedAttr')';
elseif combineScoreTechnique == 2
    combinedAttr = nansum(normMappedAttr')';
elseif combineScoreTechnique == 3
    combinedAttr = nanmedian(normMappedAttr')';
elseif combineScoreTechnique == 4
    combinedAttr = nanstd(normMappedAttr')';
elseif combineScoreTechnique == 5
    combinedAttr = nanmax(normMappedAttr')';
elseif combineScoreTechnique == 6
    combinedAttr = nanmin(normMappedAttr')';
else
    error('An invalid combineScoreTechnique was used'); 
end


%put combined scores with context info
for k = 1 : size(attributes,2)
    combinedScoreData.(attributes{k}) = [];
end
combinedScoreData.score = combinedAttr;

%here we rescale the combined scores to spread them out and to put them
%onto a consistent interval
%combinedScoreData.score = 100 * (combinedScoreData.score - min(combinedScoreData.score)) / ...
%    (max(combinedScoreData.score) - min(combinedScoreData.score));

clearvars combinedAttr normMappedAttr index i k relevantMapInfo 

if makeGraphs
    mkdir(char(saveLocation)); 
    
    %make histogram
    hist(combinedScoreData.score, 100);
    title(char(strcat('Distribution of combined Scores Using', {' '}, combineScoreInfo{combineScoreTechnique})));
    xlabel('Score');
    ylabel('Count');
    savefig(gcf,char(strcat(saveLocation,'scoreDistribution')));
    close all;
    
    %distribution per context category
    mkdir(char(strcat(saveLocation,'contextVarDist')));
    for k = 1 : size(contexts,2)
        contextValues = unique(combinedScoreData.(contexts{k}));
        contextValues(isnan(contextValues)) = [];
        plotVals = nan(size(combinedScoreData,1),size(contextValues,1));
        for j = 1 : size(combinedScoreData,1)
            if ~isnan(combinedScoreData.(contexts{k})(j))
                if ~strcmp(contexts{k},'condition')
                    plotVals(j,combinedScoreData.(contexts{k})(j)) = combinedScoreData.score(j);
                else
                    plotVals(j,find(contextValues == combinedScoreData.(contexts{k})(j))) = combinedScoreData.score(j);
                end
            end
        end
        boxplot(plotVals, 'labels', contextValues);
        title(char(strcat(contexts{k}, {' '}, 'Combined Score Distribution Using', {' '}, combineScoreInfo{combineScoreTechnique})));
        xlabel('Context Value');
        savefig(gcf,char(strcat(saveLocation,'contextVarDist/',contexts{k},'ScoreBoxPlot')));
        close all;
    end
    
    %distribution per user
    plotVals = nan(size(combinedScoreData,1),size(unique(combinedScoreData.patient),1));
    for j = 1 : size(combinedScoreData,1)
        plotVals(j,combinedScoreData.patient(j)) = combinedScoreData.score(j); 
    end
    boxplot(plotVals);
    title(char(strcat('Patient Score Distribution Using', {' '}, combineScoreInfo{combineScoreTechnique})));
    xlabel('User');
    savefig(gcf,char(strcat(saveLocation,'userScoreBoxPlot')));
    close all;
end

validationSet = combinedScoreData(test(outerCV,1),:);
trainingSet = combinedScoreData(training(outerCV,1),:);
save(char(strcat('/Users/ryanbrummet/Documents/MATLAB/Audiology/compositeScores/',outputVarFileName)),'validationSet','trainingSet');