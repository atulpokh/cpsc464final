% Daniel Waldinger
% 2019-04-14

% Code to summarize allocation produced by an equilibrium

function allocation = summarize_allocation(hh,eld,X,E,pr,br,r,d,v,theta,t,charlist)
    
    groups = max(pr);   % # priority groups
    N = length(pr); J = size(v,1);

    % construct choice probabilities and weights
    P = zeros(N*J,1); w = zeros(N*J,1); t_own = zeros(N*J,1);
    for pp=1:groups
        for bb=1:3

            ii_ind = pr==pp & br.sel(:,bb);    % mark priority group at person level
            ii_indev = repmat(ii_ind,J,1);  % and rows of design matrix

            % construct the equilibrium waiting times each applicant faced
            t_pp = repmat(t(J*(bb-1) + (1:J),pp),1,sum(ii_ind))';
            t_pp_long = t_pp(:);
            t_own(ii_indev) = t_pp_long;

            % mean utilities (exponentiated)
            expv_long = exp(X(ii_indev,:)*theta - r*t_pp_long).*E(ii_indev);
            expv = reshape(expv_long,sum(ii_ind),J);

            % choice probabilities
            ccp = expv ./ repmat(1+sum(expv,2),1,J);
            P(ii_indev) = ccp(:);
            
            % weights
            w(ii_indev) = exp(-d*t_pp_long);
            
        end
    end
    
    % matrix of household characteristics
    nchars = length(charlist);
    char_mat = zeros(size(hh,1),nchars);
    for ii = 1:nchars
        char_mat(:,ii) = hh.(charlist{ii});
    end
    
    % allocation overall
    allocation.overall = zeros(nchars+1,3);
    allocation.overall(:,1) = sum(repmat(w.*P,1,nchars+1).*[t_own repmat(char_mat,J,1)])' ./ repmat(sum(w.*P),1,nchars+1)';
    
        % elderly vs non-elderly
        eld_dis = zeros(N*J,1);
        for jj = 1:J
            if eld(jj)
                eld_dis((1:N) + (jj-1)*N) = 1;
            end
        end
        w_family = w .* (1-eld_dis);
        w_elderly = w .* eld_dis;
        allocation.overall(:,2) = sum(repmat(w_elderly.*P,1,nchars+1).*[t_own repmat(char_mat,J,1)])' ...
                                       ./ repmat(sum(w_elderly.*P),1,nchars+1)';
        allocation.overall(:,3) = sum(repmat(w_family.*P,1,nchars+1).*[t_own repmat(char_mat,J,1)])' ...
                                       ./ repmat(sum(w_family.*P),1,nchars+1)';
        
    
    % allocation by development
    wP = reshape(w.*P,N,J);
    allocation.bydev = zeros(nchars+1,J);
    allocation.bydev(1,:) = 12*sum(wP.*reshape(t_own,N,J)) ./ sum(wP);  % waiting time (months)
    for ii = 1:nchars
        allocation.bydev(ii+1,:) = sum(wP.*repmat(char_mat(:,ii),1,J)) ./ sum(wP);
    end
    
    % waiting times for those allocated
    allocation.wait_times = sum(repmat(w.*P.*t_own,1,nchars).*repmat(char_mat,J,1)) ...
                            ./ sum(repmat(w.*P,1,nchars).*repmat(char_mat,J,1));