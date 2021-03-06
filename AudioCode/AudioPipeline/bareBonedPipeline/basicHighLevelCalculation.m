function [ combinedMatrix ] = basicHighLevelCalculation( fileList, ...
                            highLevelHandle )
%BASICHIGHLEVELCALCULATION Summary of this function goes here
%   Detailed explanation goes here

addpath ../;
r = length(fileList);
d = load(fileList{1});
[~,c] = size(d.var);
combinedMatrix = zeros(r,c-2);
clear d;

parObj = parpool;
parfor P=1:r
    disp(sprintf('Working with: %s',fileList{P}));
    loadedVar = parLoadVariable(fileList{P});
    loadedVar = loadedVar.var;
    summarizedFeatures = robustStat(loadedVar(:,4:c-3), highLevelHandle);
    fname = fileList{P};
    fname = strsplit(fname,'/');
    fname = fname{end};
    fname = strsplit(fname,'_');
    fname = fname{end};
    fname = strsplit(fname,'.');
    fname = fname{1};
    dn = datenum(fname,'yyyy-mm-dd');
    toSave = [loadedVar(1,1) loadedVar(1,2) loadedVar(1,3), dn ...
        summarizedFeatures];
    combinedMatrix(P,:) = toSave;
end
delete(parObj);
end

