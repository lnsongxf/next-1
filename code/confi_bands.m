function [lb, med, ub] = confi_bands(series,per)
% per = percentile  (i.e. .1 = 90% confidence band)
% 23 October 2019
[s1, s2, s3 ] = size(series);
% if series is stored in a three-dimensional matrix, then sort over third
% dimension, else sort over the second dimension - make sure sizes of inputs are
% right!
if s3 > 1
    i = 3;
    M = s3;
else
    i = 2;
    M = s2;
end
series_sorted = sort(series,i);
if i==2
    if M <= 2
        lb = series_sorted(:,1);
    else
        lb =  series_sorted(:,floor((per/2)*M));
    end
    ub =  series_sorted(:,ceil((1-per/2)*M));
    med = series_sorted(:,ceil(0.5*M));
elseif i==3
    if M <= 2
        lb = series_sorted(:,:,1);
    else
        lb =  series_sorted(:,:,floor((per/2)*M));
    end
    ub =  series_sorted(:,:,ceil((1-per/2)*M));
    med = series_sorted(:,:,ceil(0.5*M));
end
