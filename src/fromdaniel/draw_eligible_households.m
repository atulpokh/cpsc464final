% Daniel Waldinger
% 2019-03-28

% Take eligible ACS households and draw a simulated sample of eligible
% households

clear

data = '../Data/Matlab/';
pha = 'CHA';
acs = readtable([data 'eligible_population_' pha '.txt'],...
                    'delimiter','|','ReadVariableNames',true);
nACS = size(acs,1);  % # sampled ACS households
display(['Number of Eligible Households: ' num2str(round(sum(acs.weight)))])

% For each survey household, draw an integer and remainder
% Draw the integer number of copies of the household
% Draw an additional copy with the remainder probability
% int = floor((1-p_acs).*acs.weight);
% pr = (1-p_acs).*acs.weight - floor((1-p_acs).*acs.weight);
int = floor(acs.weight);
pr = acs.weight - floor(acs.weight);
draws = rand(nACS,1);
eligible = acs(1,:);  % initializing table with a single row; will discard
for s=1:nACS
    if mod(s,100)==0, display(['Row ' num2str(s)]); end
    for i=1:int(s)
        eligible = [eligible; acs(s,:)];
    end
    if draws(s) < pr(s)
        eligible = [eligible; acs(s,:)];
    end
end
eligible = eligible(2:end,:);   % discard initializing row

save([data 'eligible_' pha '.mat'],'eligible');
writetable(eligible,[data 'eligible_' pha '.txt'],'delimiter','|');