%Author Ryan Brummet
%University of Iowa

function [ extractedData, mappedData, combinedData, mappingError, mappingCoefficients, attrMapTarget ] = ...
    audioSurveyProc( targetFileName, targetAttrs, removeFiftyVals, ...
    minSurveyPercent, omitNotListening, omitListening, omitNotUserInit, ...
    omitUserInit, normalizeMethod, mapScore, mapPerUser, stratifySampling, ...
    reSample, attrMapTarget, polyFitDegree, medianTrueMeanFalse)

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

%extractedData (output matrix): gives the data that was extracted.  May or
%       may not be normalized depending on whether normalization was performed.
%       This matrix is in the form patientID, listening, userInit, ac, lc, tf, vc,
%       tl, nl, rs, cp, nz, condition, sp, le, ld, ld2, lcl, ap, qol, im,
%       st.  If values attributes were removed the column identities are
%       subject to change.  Removing attributes has the effect of deleting
%       columns so the indexes will be effected by which columns are
%       deleted.

%combinedData (output matrix): gives the data that was extracted with the
%       attributes combined to a single attribute.  First all attribute are
%       mapped onto attrMapTarget then either median or mean of the nine
%       attributes across a sample are used to determine the combined
%       score.  This matrix in the form patientID, listening, userInit, ac,
%       lc, tf, vc, tl, nl, rs, cp, nz, condition, score

%mapError (matrix): the training set error minus the testing set error.
%       The error for each set is found by subtracting real values from
%       predicted map values for each attribute.  The median, mean, and max
%       across all samples are recorded for the training and testing sets.
%       Finally the absolute difference between the testing and training
%       set is found.  This gives us a notion of the correctness of the
%       mapping over the whole set, but does not give us a notion of
%       accuracy.  That is, this test aims to show that mapping is
%       consistent over the whole set.  The accuracy is dependent on the
%       correlation between the attrMapTarget and the other attributes.
%       the mean is column 1, the median is column 2, and the max is column
%       3.  Row 1 is sp, 2 is le, 3 is ld, 4 is ld2, 5 is lcl, 6 is ap, 7
%       is qol, 8 is im, and 9 is st.

%mappingCoefficients (output matrix): gives the coefficients of a
%       polynomial mapping function from an attribute onto attrMapTarget.  The
%       coefficients are by row and are ordered such that the highest power is
%       at the highest index.  The rows are assined such that 1 is sp, 2 is
%       le, 3 is ld, 4 is ld2, 5 is lcl, 6 is ap, 7 is qol, 8 is im, and 9
%       is st.


    %extract the data
    [extractedData, userSet] = extractAndProcData(targetFileName, ...
        removeFiftyVals, omitNotListening, omitListening, omitNotUserInit, ...
        omitUserInit);
    
    %remove attributes that are not needed
    [ extractedData, attrMapTarget ] = pickAttrs( extractedData, targetAttrs, attrMapTarget);
    
    %remove samples that don't make duration requirements
    [extractedData, userSampleCount, userIndexSet] = testSurveyDuration( ...
        extractedData, minSurveyPercent, userSet);
    
    %remove all samples of users that don't have at least 20 samples
    %this is done to prevent problems that may arise because of a small
    %sample set when normalizing or mapping attributes
    [extractedData, userSet, userSampleCount, userIndexSet] = ...
        removeNonQualUsers(extractedData, userSet, userSampleCount, ...
        userIndexSet);
    
    %normalize based on normalizeMathod (or don't normalize)
    if normalizeMethod == 1
        [extractedData] = normalizeDataGlobally(extractedData);
    elseif normalizeMethod == 2
        [extractedData] = normalizeAcrossUsers(extractedData, ...
            userSet);
    end
    
    %map attributes if mapScore is true
    %combinedData has all attributes combined to one score while mappedData
    %has all the attributes mapped onto the target Attribute withoug
    %combining attributes.
    if mapScore
        [combinedData, mappedData, mappingError, mappingCoefficients] = ...
            mapAttributes(mapPerUser, stratifySampling, reSample, ...
            attrMapTarget, polyFitDegree, extractedData, ...
            userSampleCount, userIndexSet, medianTrueMeanFalse);
    else
        combinedData = NaN;
        mappingError = NaN;
        mappingCoefficients = NaN;
    end

end
