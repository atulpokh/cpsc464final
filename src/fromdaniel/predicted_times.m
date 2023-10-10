% Daniel Waldinger
% 2019-04-10

% Code to calculate predicated waiting times under lexicographic priorities

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
%   t - (J,2) waiting times for each development and priority group

function t = predicted_times(X,E,pr,br,r,d,v,theta,t0)

    groups = max(pr);   % # priority groups
    J = size(v,1);     % % developments
    v_res = v;  % keeps track of how many vacancies "left" after each priority group housed
    t = zeros(J*3,groups);  % times implied by optimal decisions, given proposed times
    
    for pp = 1:groups  % loop over priority groups
        
        for bb=1:3          % loop over bedroom sizes
            
            ii_ind = pr==pp & br.sel(:,bb);    % mark priority group at person level
            ii_indev = repmat(ii_ind,J,1);  % and rows of design matrix
        
        % choice probabilities

            % mean utilities (exponentiated)
            t_pp = repmat(t0(J*(bb-1) + (1:J),pp),1,sum(ii_ind))';
            t_pp = t_pp(:);
            expv_long = exp(X(ii_indev,:)*theta - r*t_pp).*E(ii_indev);
            expv = reshape(expv_long,sum(ii_ind),J);

            % choice probabilities
            P = sum(expv ./ repmat(1+sum(expv,2),1,J))';

            % implied waiting times
            t(J*(bb-1) + (1:J),pp) = ((log(P) - log(v_res(:,bb)*5)) / d).*(v_res(:,bb) > 0).*(P > v_res(:,bb)*5); 
            t(find(v_res(:,bb)<=0)+J*(bb-1),pp) = 1e3;  % assign effectively infinite waiting time to developments with no slots left

            % update remaining vacancy rates
            v_res(:,bb) = v_res(:,bb) - (P/5); v_res(:,bb) = v_res(:,bb).*(v_res(:,bb) >= 0);
        end
    end
    t(v==0)=1e03;