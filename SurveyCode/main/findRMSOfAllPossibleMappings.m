%Author Ryan Brummet
%University of Iowa

function [ RMSVals ] = findRMSOfAllPossibleMappings( targetFileName, repeat)

%targetFileName (input string): raw input data file name. include the
%       extension.

%targetAttrs (input vector): a 1x9 vector of 1s and 0s.  Each column stands
%       for, in increasing index size, sp, le, ld, ld2, lcl, ap, qol, im,
%       st.  A 1 indicates to extract the attribute, a 0 indicates not to
%       extract the attribute.  true or false may be used in place of the
%       1s and 0s.

%removeFiftyVals (input bool): whether or not to remove 50 vals

%minSurveyPercent (input int): we find the average amount of time that each
%       user spends taking a survey then find the value that is
%       minSurveyPercent of the average, bound.  Every sample for that user
%       must fall between [average - bound, average + bound]

%omitNotListening (input bool): omits samples that users weren't listening

%omitListening (input bool): omits samples that users were listening

%omitNotUserInit (input bool): omits samples that were not initiated by
%       users

%omitUserInit (input bool): omits samples that were initiated by users

%normalizeMethod (input int): if 1 normalization is done over the whole
%       extractedData set.  if 2 normalization is done over users.  if any
%       other value normalization is not done.

%mapScore (input bool): if true we map all attributes onto another
%       attribute.

%mapPerUser (input bool): if true we map attributes per user.  That is
%       mapping coefficients are individually created for every user

%stratifySampling (input bool): if true the samples used to created the
%       testing and training sets for the mapping coefficients are stratified
%       (sampling for the two sets are not done completely randomly). the
%       entire sample set is divided into sections of five samples and one
%       sample is randomly choosen to be in the test set.  the remaining
%       samples are placed in the training set.

%reSample (input bool): if true each user will have the same number of
%       samples in the training and testing sets.  There is no cross sampling
%       though.  That is no user will have a sample that is a member of both the
%       training and testing sets.

%attrMapTarget (input int): gives the attribute that all attributes will be
%       mapped onto.  1 for sp, 2 for le, 3 for ld, 4 for ld2, 5 for lcl, 6 for
%       ap, 7 for qol, 8 for im, 9 for st

%polyFitDegree (input int): gives the degree of the polynomial that is used
%       to map from one attribute onto the attrMapTarget

%medianTrueMeanFalse (input bool): the mapping function gives gives 8
%       attributes that have been mapped onto attrMapTarget in addition to the
%       attrMapTarget attribute.  We must combine these scores into a single
%       score.  If true the scores are combined by finding the median.  If false
%       the scores are combined by finding the average.


    %we repeat the experiment repeat times to account for variability that may
    %arise becuase of random number generation.  RMSVals stored in the form
    %normalizationValUsed, mapByUser, stratifySampling, reSample,
    %attrMapTarget, polyFitDeg, meanMedianAttrCombine, RMS score.
    RMSValsTemp = zeros(1,8,repeat);
    
    %extract the data
    [Data, userSet] = extractAndProcData(targetFileName, ...
        true, false, false, false, ...
        false);
    
    for run = 1 : repeat
        index = 1;
        for normal = 0 : 2
            for userMap = 0 : 1
                for stratify = 0 : 1
                    for sample = 0 : 1
                        for target = 1 : 9
                             if target == 7 || target == 8
                                 continue; 
                             end
                            for deg = 1 : 5
                                for meanMedian = 0 : 1
                                    run*.001 + index 
                                    userSetTemp = userSet;
                                    %remove attributes that are not needed
                                    [ extractedData, attrMapTarget ] = pickAttrs( Data, [1,1,1,1,1,1,1,1,1], target);
    
                                    %remove samples that don't make duration requirements
                                    [extractedData, userSampleCount, userIndexSet] = testSurveyDuration( ...
                                        extractedData, 50, userSetTemp);
    
                                    %remove all samples of users that don't have at least 20 samples
                                    %this is done to prevent problems that may arise because of a small
                                    %sample set when normalizing or mapping attributes
                                    [extractedData, userSetTemp, userSampleCount, userIndexSet] = ...
                                        removeNonQualUsers(extractedData, userSetTemp, userSampleCount, ...
                                        userIndexSet);
    
                                         %normalize based on normalizeMathod (or don't normalize)
                                    if normal == 1
                                        [extractedData] = normalizeDataGlobally(extractedData);
                                    elseif normal == 2
                                        [extractedData] = normalizeAcrossUsers(extractedData, ...
                                            userSetTemp);
                                    end
                                    
                                    [combinedData, mappedData, mappingError, mappingCoefficients] = ...
                                        mapAttributes(userMap, stratify, sample, ...
                                        attrMapTarget, deg, extractedData, ...
                                        userSampleCount, userIndexSet, meanMedian);
                            
                                    RMSValsTemp(index,1,run) = normal;
                                    RMSValsTemp(index,2,run) = userMap;
                                    RMSValsTemp(index,3,run) = stratify;
                                    RMSValsTemp(index,4,run) = sample;
                                    RMSValsTemp(index,5,run) = target;
                                    RMSValsTemp(index,6,run) = deg;
                                    RMSValsTemp(index,7,run) = meanMedian;
                                    summation = 0;
                                    minimum = 100;
                                    maximum = 0;
                                    amount = 0;
                                    for k = 1 : size(mappedData,1)
                                        if mappedData(k,13 + attrMapTarget) >= 0 && combinedData(k,14) >= 0
                                            summation = summation + (mappedData(k,13 + attrMapTarget) - combinedData(k,14))^2; 
                                            amount = amount + 1;
                                            if minimum > combinedData(k,14)
                                                minimum = combinedData(k,14); 
                                            elseif maximum < combinedData(k,14)
                                                maximum = combinedData(k,14); 
                                            end
                                        end
                                    end
                                    RMSValsTemp(index,8,run) = (sqrt(summation / amount)) / (maximum - minimum);
                                    index = index + 1;
                                    clearvars summation minimum maximum amount extractedData attrMapTarget ...
                                        userSampleCount userIndexSet userSetTemp userSampleCount ... 
                                        combinedData mappedData mappingError mappingCoefficients
                                 end
                            end
                        end
                    end
                end
            end
        end
    end
    RMSVals = zeros(1,8);
    for k = 1 : size(RMSValsTemp,1)
        for j = 1 : 7
            RMSVals(k,j) = RMSValsTemp(k,j,1);
        end
        RMSVals(k,8) = mean(RMSValsTemp(k,8,1:repeat));
    end

end

