% Daniel Waldinger
% 2019-03-29

% Create design matrix for eligible household data

J = size(dev_data,1);  % # devs
N = size(hh_data,1);   % # eligible households
K = length(model.applicant_characteristics); 
I = length(model.interactions);
P = 3*J+K+I;  % dimension of parameter vector
X = zeros(N*J,P);

    % bedroom size eligibility
    br.br = min(max(1,hh_data.bedrooms),3);
    br.mat = zeros(N*J,1);  % conversion from a Jx3 matrix to design matrix rows
    br.sel = false(N,3);    % indicators for household's br size 
    br.num = cell(3,1);     % numeric household row indices for each bedroom size
    for bb=1:3
        ii_bb = find(br.br==bb);
        for jj=1:J
            br.mat(ii_bb+N*(jj-1)) = J*(bb-1) + jj;
        end
        br.sel(ii_bb,bb)=true;
        br.num{bb}=ii_bb;
    end
    br.n = sum(br.sel); % number of bedrooms

%% design matrix itself

    % development fixed effects
    for bb=1:3
        for jj=1:J
            X(br.num{bb} + N*(jj-1),(bb-1)*J+jj) = 1;
        end
    end
    
    % applicant characteristics
    for ii=1:K
        X(:,3*J+ii) = repmat(hh_data.(model.applicant_characteristics{ii}),J,1);
    end
    
    % interactions
    for ii=1:I
        X(:,3*J+K+ii) = reshape(repmat(dev_data.(model.interactions{ii}{2}),1,N)',N*J,1)...
                        .* repmat(hh_data.(model.interactions{ii}{1}),J,1);
    end
    
%% other useful objects

    % eligibility matrix
    E = ones(N,J);
    elderly_devs = strcmp(dev_data.type','Elderly LIPH');
    family_hhs = (1-hh_data.elderly).*(1-hh_data.disabled);
    E = E - family_hhs*elderly_devs;
    
    % bedroom size shares
    B = [dev_data.pct_bed1 dev_data.pct_bed2 dev_data.pct_bed3];
    B = B ./ repmat(sum(B,2),1,3);
    
    % vacancy rates by development, bedroom size
    v = zeros(J,3);
    v(:,1) = (dev_data.size .* dev_data.pct_bed1 .* 12) ./ (2*dev_data.months_from_movein);
    v(:,2) = (dev_data.size .* dev_data.pct_bed2 .* 12) ./ (2*dev_data.months_from_movein);
    v(:,3) = (dev_data.size .* dev_data.pct_bed3 .* 12) ./ (2*dev_data.months_from_movein);
    v(v==0) = 0.05;

    % waiting times
    t = reshape(repmat(dev_data.months_waited/12,1,N)',N*J,1);
    
    % probabilities of making it through, given waiting times and attrition
    % rate
    times = dev_data.months_waited/12;
    w = zeros(N*J,ndeltas);
    for mm = 1:ndeltas
        wght = exp(-deltas(mm)*times);
        w(:,mm) = reshape(repmat(wght,1,N)',N*J,1);
    end