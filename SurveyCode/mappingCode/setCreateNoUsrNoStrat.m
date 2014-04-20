%Author Ryan Brummet
%University of Iowa

function [ trainingSet, testingSet, trainingIndex, testingIndex, currentSampleCountTraining, ...
    currentSampleCountTesting, currentSampleTrainingIndexes, ...
    currentSampleTestingIndexes] = setCreateNoUsrNoStrat(trainingIndex,... 
    testingIndex, userSampleCount, reSample, inputData)

%trainingIndex (input/output int): current next unused row of trainingSet

%testingIndex (input/output int): current next unused row of testingSet

%currentSampleCountTraining (output matrix): gives the number of
%       samples from each user that are in the training set thus far.  The
%       input is a matrix of zeros with patient id's only.

%currentSampleCountTesting (output matrix): gives the number of 
%       samples from each user that are int the testing set thus far.  The
%       input is a matrix of zeros with patient id's only.

%currentSampleTrainingIndexes (output matrix): gives the index of each
%       sample in the overall patient data matrix for each user sample in 
%       the training set. the input is a matrix of zeros.

%currentSampleTestingIndexes (output matrix): gives the index of each
%       sample in the overall patient data matrix for each user sample in
%       the testing set.  The input is a matrix of zeros.

%usrSampleCount  (input matrix): contains the usr and the number of samples
%       each has. This is passed to the function so as to not have to
%       calculate the information twice.

%reSample (input bool): if we are reSampling we must make sure that every user
%       has at least one sample.  In this case, we make sure that each user
%       has at least 5 samples in the sets generated with at least one in both.
%       We can't choose a higher miniumum of total samples
%       because we would lose the random nature of our sampling policy (some users
%       have a small number of samples, just barely more than the min of 20).

%inputData (input matrix): gives the overall patient data matrix

%trainingSet (output matrix): subset of the overall patient data matrix
%       that will be used as a training set to map attributes

%testingSet (output matrix): subset of the overall patient data matrix that
%       will be used as a testing set for the attribute mappings


    currentSampleCountTraining = zeros(size(userSampleCount,1),2);
    currentSampleCountTesting = zeros(size(userSampleCount,1),2);
    currentSampleCountTraining(:,1) = userSampleCount(:,1);
    currentSampleCountTesting(:,1) = userSampleCount(:,1);
    currentSampleTrainingIndexes = zeros(size(userSampleCount,1),1);
    currentSampleTestingIndexes = zeros(size(userSampleCount,1),1);    

    trainingSetSize = floor(size(inputData,1) * .8);
	trainingSetIndexes = randperm(size(inputData,1),trainingSetSize);
    redo = true;
    while redo 
        redo = false;
        for k = 1 : size(inputData,1)
            if ismember(k,trainingSetIndexes)
                trainingSet(trainingIndex,:) = inputData(k,:);
                trainingIndex = trainingIndex + 1;
                temp = find(currentSampleCountTraining(:,1) == inputData(k,1));
                currentSampleCountTraining(temp,2) = currentSampleCountTraining(temp,2) + 1;
                currentSampleTrainingIndexes(temp,k) = k;
            else
                testingSet(testingIndex,:) = inputData(k,:);
                testingIndex = testingIndex + 1;
                temp = find(currentSampleCountTesting(:,1) == inputData(k,1));
                currentSampleCountTesting(temp,2) = currentSampleCountTesting(temp,2) + 1;
                currentSampleTestingIndexes(temp,k) = k;
            end
        end
        if reSample
            for k = 1 : size(userSampleCount,1)
                if  (currentSampleCountTesting(k,2) + currentSampleCountTraining(k,2) < 5) ...
                    || currentSampleCountTesting(k,2) == 0 || currentSampleCountTraining(k,2) == 0
                    
                    'redo detected'
                    testingIndex = 1;
                    trainingIndex = 1;
                    trainingSetSize = floor(size(inputData,1) * .8);
                    trainingSetIndexes = randperm(size(inputData,1),trainingSetSize);
                    clearvars trainingSet testingSet
                    currentSampleCountTraining = zeros(size(userSampleCount,1),2);
                    currentSampleCountTesting = zeros(size(userSampleCount,1),2);
                    currentSampleCountTraining(:,1) = userSampleCount(:,1);
                    currentSampleCountTesting(:,1) = userSampleCount(:,1);
                    currentSampleTrainingIndexes = zeros(size(userSampleCount,1),1);
                    currentSampleTestingIndexes = zeros(size(userSampleCount,1),1);
                    redo = true; 
                end
            end
        end
    end
end
