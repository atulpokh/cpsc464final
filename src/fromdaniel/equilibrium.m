% Daniel Waldinger
% 2019-04-11

% Code to compute the equilibrium of a priority system given preferences

% Inputs:
%   X - (NJ,D) design matrix
%   E - (NJ,1) eligibility matrix
%   pr - (N,1) vector of priority groups (1 <-> highest) denoted by consecutive numbers
%   br - struct containing bedroom size related things
%   r - scalar discount factor
%   d - scalar attrition rate
%   v - (J,3) vacancy rates in each development
%   theta - (D,1) parameter vector
%   t0 - (J*3,2) initial waiting time vector

% Outputs:
%   t - (J*3,2) waiting times for each development and priority group


function [t,t_hist,dists] = equilibrium(X,E,pr,br,r,d,v,theta,t0)


    tol = 1e-12; l = 0.5; % weight on new vs old times
    groups = max(pr); t0 = t0(:,1:groups);
    maxiter=1e3; ii=1; t_out = t0;  % initializing
    dists = zeros(maxiter+1,1); dists(1) = 100;  
    t_hist = cell(maxiter,1);
    
    while ii <= maxiter && dists(ii) >= tol
        
        if mod(ii,10)==0
            display(['Iteration ' num2str(ii) '; Modulus: ' num2str(l) '; Distance: ' num2str(dists(ii))])
        end
        
        % use updated waiting times to calculate new predicted waiting times
       	t_in = t_out;  t_hist{ii} = t_in;
        t_pred = predicted_times(X,E,pr,br,r,d,v,theta,t_in);
        dif = abs(t_pred - t_in);
        dists(ii+1) = max(dif(:));
        
        % update modulus
        if dists(ii+1) > dists(ii)
            l = l/1.25;
        end
        
        % times to use for next iteration
        t_out = l*t_in + (1-l)*t_pred;
        ii=ii+1;
        
    end

    if ii>maxiter
        disp('Maximum Number of Iterations Completed')
    else
        disp('Equilibrium Found')
    end
    display(['Iteration ' num2str(ii) '; Modulus: ' num2str(l) '; Distance: ' num2str(dists(ii))])

    t = round(t_out,3);