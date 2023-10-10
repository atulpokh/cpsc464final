% Daniel Waldinger
% 2019-03-29

% Objective function for minimum distance procedure

% Inputs:
%   m - (D,1) moments from data
%   A - (D,D) weight matrix
%   X - (N*J,D) design matrix
%   w - (N*J,1) vector of weights
%   br - cell object with bedroom size relevant info
%   E - (N,J) eligibility matrix (zeros out expv for non-eligible devs)
%   B - (J,3) fraction units of each bedroom size in each development
%   param - (D,1) parameter vector
%   rho - scalar discount rate [exp(-rho*t)]
%   v - (J,1) vacancy rates
%   t - (N*J,1) waiting times, conformable to design matrix
%   d - scalar attrition rate

% Outputs:
%   f - scalar objective function value
%   g - (P,1) gradient of objective function

%function [f,g,m0,dm_dtheta,times] = objective_function(N,J,m,A,X,br,E,B,param,rho,v,t,d)
function [f,g,m0,dm_dtheta] = objective_function(N,J,m,A,X,w,br,E,B,param,rho,v,t,d)

D = length(param);
v_long = v();

%% Objective function

    % mean utilities (exponentiated)
    expv_long = exp(X*param - rho*t).*E(:);
    expv = reshape(expv_long,N,J);
    
    % choice probabilities
    P_wide = expv ./ repmat(1+sum(expv,2),1,J);
    P = P_wide(:);
    
    % moments predicted by model
    [m0,times,w] = model_moments(N,J,X,w,br,B,P,v,d);
    
    % value of objective function
    f = (m-m0)'*A*(m-m0);

%% Gradient

    % calculate gradient of CHOICE PROBABILITIES wrt parameters
    %   this is what determines the objective function gradient
    bot = repmat(1+sum(expv,2),1,D);
    top = zeros(N,D); % holds sum(x*exp(x*theta))
    for dd=1:D
        top(:,dd) = sum(reshape(expv_long .* X(:,dd),N,J),2);
    end
    ratio = top ./ bot; % an (NxD) matrix of the fraction term
    dP_dtheta = repmat(P,1,D) .* (X - repmat(ratio,J,1));

    % waiting time moments (gradient)
%     dt_dtheta = zeros(J,D);  % for mean times across br sizes
%     dtk_dtheta = cell(3,1);  % for br-specific times
%     dTij_dtheta = zeros(N*J,D);  % individual-br specific time gradient
%     for bb=1:3
%         dtk_dtheta{bb} = zeros(J,D);
%         denom = sum(P_wide(br.sel(:,bb),:))*d;  % denominator is sum of choice probabilities for each development, same for all parameters
%         for jj = 1:J
%             if times(jj,bb)>0  % capacity constrained
%                 ii_jj_bb = br.num{bb}+(jj-1)*N;
%                 dtk_dtheta{bb}(jj,:) = sum(dP_dtheta(ii_jj_bb,:)) / denom(jj);
%                 dTij_dtheta(ii_jj_bb,:) = repmat(dtk_dtheta{bb}(jj,:),br.n(bb),1);
%             end
%         end
%         dt_dtheta = dt_dtheta + repmat(B(:,bb),1,D) .* dtk_dtheta{bb};
%     end

    dt_dtheta = zeros(3*J,D);  % for mean times across br sizes
    dtk_dtheta = cell(3,1);  % for br-specific times
    for bb=1:3
        dtk_dtheta{bb} = zeros(J,D);
        denom = sum(P_wide(br.sel(:,bb),:))*d;  % denominator is sum of choice probabilities for each development, same for all parameters
        for jj = 1:J
%             if times(jj,bb)>0  % capacity constrained
                ii_jj_bb = br.num{bb}+(jj-1)*N;
                dtk_dtheta{bb}(jj,:) = sum(dP_dtheta(ii_jj_bb,:)) / denom(jj);
%             end
        end
        dt_dtheta((1:J)+(bb-1)*J,:) = dtk_dtheta{bb};
    end
    
    
    
    % characteristic/interaction moments (gradient)
    dotPw = w'*P;
%     term1 = X(:,(J+1):end)'*(repmat(w,1,D) .* (dP_dtheta - (d*dTij_dtheta.*repmat(P,1,D)))) / dotPw;
%     term2 = (X(:,(J+1):end)'*(w.*P))*(w'*(dP_dtheta - (d*dTij_dtheta.*repmat(P,1,D)))) / (dotPw*dotPw);
    term1 = X(:,(3*J+1):end)'*(repmat(w,1,D) .* dP_dtheta) / dotPw;
    term2 = (X(:,(3*J+1):end)'*(w.*P))*(w'*dP_dtheta) / (dotPw*dotPw);
    dmZ_dtheta = term1-term2;
    
    dm_dtheta = [dt_dtheta;dmZ_dtheta];  % gradient of moments wrt objective function
    
    g = -2*dm_dtheta'*A*(m-m0);