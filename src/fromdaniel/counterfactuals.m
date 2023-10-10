% Daniel Waldinger
% 2019-04-10

% Code to predict counterfactual equilibria. Called within estimation_wrapper.m

% For now, writing code assuming FCFS waitlist with choice. Only binary
% priority system allowed. Will generalize.

% Equilibrium concept uses large-market approximation to derive analytic
% equilibrium conditions

clear
inputs = '../Data/Matlab/';
outputs = '../results/Estimation/';
rhos = [0.1]; nrhos = length(rhos);     % annual discount factor
deltas = [0.25]; ndeltas = length(deltas);   % annual attrition rate
pha = 'CHA';    % PHA abbreviation
model_name='';
mm=1;nn=1;

load([outputs 'first_estimates_rho_' num2str(rhos(nn)) '_delta_' num2str(deltas(mm)) '.mat']);

    theta = argmins(:,1); % taking first parameter estimate
    rho = rhos(1); delta = deltas(1);
    
    E = E(:); % should be a vector
    
    % Priority groups
    systems = {'low_income','high_income','elderly','children','current'};
    system_names = {'Low-Income','High-Income','Elderly','Children','Current'};
    pr.current = ones(N,1);     % everyone has higher priority, except one guy (easier for code to run)
    pr.low_income = 1 + (hh_data.pct_ami >= 0.3);	% Low-Income Priority
    pr.high_income = 1 + (hh_data.pct_ami < 0.3);	% High-Income Priority
    pr.elderly = 2 - (hh_data.elderly | hh_data.disabled);       % Elderly/Disabled Priority
    pr.children = 2 - hh_data.children;     % Children Priority. For this one, allow families to live in elderly/disabled housing
    startval = repmat(times,3,2);  % priorities columns; block rows for bedroom size
        
    % to summarize allocations
    charlist = {'income','pct_ami','children','head_lt25','head_25_50','head_51_61','elderly','disabled','black','hispanic','ami_lt30','ami_30_50','ami_gt50'};
    hh_data.income = hh_data.income * 10000;
    hh_data.pct_ami = hh_data.pct_ami*100;
    hh_data.head_lt25 = hh_data.head_age <= 24;
    hh_data.head_25_50 = hh_data.head_age >= 25 & hh_data.head_age <= 50;
    hh_data.head_51_61 = hh_data.head_age >= 51 & hh_data.head_age <= 61;
    hh_data.head_62plus = hh_data.head_age >= 62;
    hh_data.ami_lt30 = hh_data.pct_ami < 30;
    hh_data.ami_30_50 = hh_data.pct_ami >= 30 & hh_data.pct_ami <= 50;
    hh_data.ami_gt50 = hh_data.pct_ami > 50;
    eld = strcmp(dev_data.type,'Elderly LIPH');

    % Search for counterfactual equilibria, which are fully summarized by waiting times
    for ii = 1:length(systems)
        disp([system_names{ii} ' Priority'])
        [t_eq.(systems{ii}),t_hist,dists] = equilibrium(X,E,pr.(systems{ii}),br,rho,delta,v,theta,startval);
        allocation.(systems{ii}) = summarize_allocation(hh_data,eld,X,E,pr.(systems{ii}),br,rho,delta,v,theta,t_eq.(systems{ii}),charlist);
    end
    
    % overall allocations
    overall_array = [allocation.low_income.overall allocation.high_income.overall allocation.elderly.overall ...
                       allocation.children.overall allocation.current.overall];
    overall_table = array2table(overall_array,'VariableNames',{'loinc_all','loinc_elderly','loinc_family','hiinc_all',...
                                                                'hiinc_elderly','hiinc_family','elder_all','elder_elderly',...
                                                                'elder_family','child_all','child_elderly','child_family',...
                                                                'curr_all','curr_elderly','curr_family'},...
                                              'RowNames',[{'wait_time'},charlist]);
    writetable(overall_table,[outputs 'counterfactuals.xls'],'Sheet',1,'WriteRowNames',true);
    
    % allocations by development
    [sorted,index] = sortrows(dev_data,{'type','name'});
    for ii = 1:length(systems)
        bydev_array = allocation.(systems{ii}).bydev(:,index);
        bydev_table = array2table(bydev_array,'VariableNames',{'Burns','Manning','Kennedy','Russell','Johnson','Millers','Norfolk',...
                                       'Corcoran','Jackson','Jefferson','Lincoln','Newtowne','Putnam','Roosevelt','Washington','Wilson'},...
                                              'RowNames',[{'wait_time'},charlist]);
        writetable(bydev_table,[outputs 'counterfactuals.xls'],'Sheet',ii+1,'WriteRowNames',true);
    end
    
    % measures of concentration: tract poverty and minority rates
    pop = dev_data.size .* dev_data.pct_occupied;
    concentration = zeros(length(charlist),2*length(systems));
    for ii = 1:length(systems)
        for kk = 1:length(charlist)
            shares_by_dev = allocation.(systems{ii}).bydev(kk+1,:);
            concentration(kk,ii) = sum(pop .* shares_by_dev' .* dev_data.tpoverty) / sum(pop .* shares_by_dev');
            concentration(kk,ii+length(systems)) = sum(pop .* shares_by_dev' .* dev_data.tminority) / sum(pop .* shares_by_dev');
        end
    end
    concentration_table = array2table(concentration,'VariableNames',{'loinc_pov','hiinc_pov','elder_pov','child_pov','curr_pov',...
                                                                     'loinc_min','hiinc_min','elder_min','child_min','curr_min'},...
                                                    'RowNames',charlist);
    writetable(concentration_table,[outputs 'counterfactuals.xls'],'Sheet',2+length(systems),'WriteRowNames',true);
    
    % waiting times table
    waiting_times = zeros(length(charlist),length(systems));
    for ii = 1:length(systems)
        waiting_times(:,ii) = allocation.(systems{ii}).wait_times;
    end
    wait_times_table = array2table(waiting_times,'VariableNames',{'loinc','hiinc','elder','child','curr'},'RowNames',charlist);
    writetable(wait_times_table,[outputs 'counterfactuals.xls'],'Sheet',3+length(systems),'WriteRowNames',true);