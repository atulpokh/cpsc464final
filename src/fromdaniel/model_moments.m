% Daniel Waldinger
% 2019-03-29

% Calculates moments given eligible households' characteristics and choices
% in the structural model

% Inputs:
%   X - (N*J,P) design matrix
%   w - (N*J,1) vector of weights
%   br - cell object with bedroom size relevant info
%   B - (J,3) fraction units of each bedroom size in each development
%   P - (N*J,1) vector of choice probabilities
%   v - (J,1) vacancy rates
%   s - (J,1) sizes
%   d - scalar attrition rate

%function [m0,times,w] = model_moments(N,J,X,br,B,P,v,d)
function [m0,times,w] = model_moments(N,J,X,w,br,B,P,v,d)
    
    % waiting times
    P_wide = reshape(P,N,J);
    times = zeros(J,3);
    for bb=1:3
        times(:,bb) = (log(sum(P_wide(br.sel(:,bb),:)))' - log(5*v(:,bb))) / d;
    end
    times(times==Inf) = 1e3;
    %times = times.*(times>=0);
    %w = exp(-d*times(br.mat).*(times(br.mat)>0));
    
    % applicant characteristics and interactions
%     z0 = repmat(w.*P,1,size(X,2)-J).*X(:,(J+1):end);
    z0 = repmat(w.*P,1,size(X,2)-3*J).*X(:,(3*J+1):end);
    
    % moments
    m0 = [times(:);(sum(z0)'/(w'*P))];