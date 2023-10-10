% Daniel Waldinger
% 2019-04-14

% Objective function without gradient


%function [f,g,m0,dm_dtheta,times] = objective_function(N,J,m,A,X,br,E,B,param,rho,v,t,d)
function [f,m0] = objective_nograd(N,J,m,A,X,w,br,E,B,param,rho,v,t,d)

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