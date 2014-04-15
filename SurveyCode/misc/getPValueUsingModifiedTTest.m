%runs modified TTest for the given attributes of the given attribute
%category.  Returns p values for each 

function [pValues] = getPValueUsingModifiedTTest(attributeCategoryOne, ...
    attributeCategoryTwo, attributeValueOne, attributeValueTwo,extractedData)

clearvars temp;
groupOneIndex = 1;
groupTwoIndex = 1;
groupOne = zeros([1,size(extractedData,2)]);
groupTwo = zeros([1,size(extractedData,2)]);
for k = 1 : size(extractedData,1)
   if extractedData(k,attributeCategoryOne + 3) > 0 && extractedData(k,attributeCategoryTwo + 3) > 0
       if extractedData(k,attributeCategoryOne + 3) == attributeValueOne
           groupOne(groupOneIndex,:) = extractedData(k,:);
           groupOneIndex = groupOneIndex + 1;
       elseif extractedData(k,attributeCategoryTwo + 3) == attributeValueTwo
           groupTwo(groupTwoIndex,:) = extractedData(k,:);
           groupTwoIndex = groupTwoIndex + 1;
       end
   end
end
%first we find the average and standard deviation of every subjective
%attribute of the two groups.  We will address each group one at a time to
%simplify indexing issues. Values will be stored in a matrix avgSTDContexts
%of the form AttributeVal, spAVG, spSTD, leAVG, leSTD, ldAVG, ldSTD, ld2AVG,
%ld2STD, lclAVG, lclSTD, apAVG, apSTD, qolAVG, qolSTD, imAVG, imSTD, stAVG,
%stSTD

%group one average and standard deviation calc
avgSTDContexts = zeros([1,19]);
avgSTDContexts(1,1) = attributeValueOne;
avgSTDContexts(2,1) = attributeValueTwo;
for k = 1 : 9
    index = 1;
    test = false;
    for i = 1 : size(groupOne,1)
        if groupOne(i,(14 + k - 1)) >= 0
            temp(index) = groupOne(i,(14 + k - 1));
            index = index + 1;
            test = true;
        end
    end
    if test
        avgSTDContexts(1,(k * 2)) = mean(temp);
        avgSTDContexts(1,((k * 2) + 1)) = std(temp);
    end
end

%group two average and standard deviation calc
for k = 1 : 9
    index = 1;
    test = false;
    for i = 1 : size(groupTwo,1)
        if groupTwo(i,(14 + k - 1)) >= 0
            temp(index) = groupTwo(i,(14 + k - 1));
            index = index + 1;
            test = true;
        end
    end
    if test
        avgSTDContexts(2,(k * 2)) = mean(temp);
        avgSTDContexts(2,((k * 2) + 1)) = std(temp);
    end
    clearvars temp;
end

%t values will be placed in the tValues array and will be ordered for the t
%values for comparisons of the subjective attributes sp, le, ld, ld2, lcl,
%ap, qol, im, st in the first row and df in second.  Notice that we are assumming that the variance of an
%attribute between the two groups is not the same.  We have modified our t
%test to account for this.  We also account for the possiblity that the
%sizes of group one and group two are different.  Our null hypothesis will
%always be that two attributes are similar (m1 - m2 = 0).  We will use the two-tailed
%test.  Therefore t values close to zero indicate that the two groups are
%similar and t values far from zero indicate that the two groups are
%different.
n1 = size(groupOne,1);
n2 = size(groupTwo,1);
for k = 1 : 9
   stDevOne = avgSTDContexts(1,((2 * k) + 1));
   stDevTwo = avgSTDContexts(2,((2 * k) + 1));
   avgOne = avgSTDContexts(1,(k * 2));
   avgTwo = avgSTDContexts(2,(k * 2));
   tValues(1,k) = (avgOne - avgTwo) / ((((stDevOne^2) / (n1)) + ((stDevTwo^2) / (n2)))^(1/2));
   if n1 == n2
       tValues(2,k) = 2 * (n1 - 1);
   else
       tValues(2,k) = ((((stDevOne^2)/n1) + ((stDevTwo^2)/n2))^2) / (((((stDevOne^2)/n1)^2) / (n1 - 1)) + ((((stDevTwo^2)/n2)^2) / (n2 - 1)));
   end
end

%calculate pValues, stored in pValues with the same ordering as the tValues
%matrix (by column)
for k = 1 : 9
   pValues(k) = tcdf(tValues(1,k),tValues(2,k)) * 2; 
end
return;
