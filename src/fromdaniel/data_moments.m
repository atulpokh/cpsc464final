% Daniel Waldinger
% 2019-03-29

% Construct moments from data
% takes dev_data and hh_data tables

% waiting times
times = repmat(dev_data.months_waited / 12,3,1);  % converting to years waited

% composition of public housing tenants overall
K = length(model.applicant_characteristics);
chars = zeros(K,1);
for ii = 1:K
    chars(ii) = sum(dev_data.size .* dev_data.(model.applicant_characteristics{ii}))...
                /sum(dev_data.size);
end

% correlation between applicant and development characteristics
I = length(model.interactions);
corrs = zeros(I,1);
for ii = 1:I
    corrs(ii) = sum(dev_data.size .* dev_data.(model.interactions{ii}{1}) .* dev_data.(model.interactions{ii}{2})) ...
                / sum(dev_data.size);
end

m = [times;chars;corrs];