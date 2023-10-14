% Daniel Waldinger
% 2019-03-29

% Code to run structural estimation

clear

% filepaths
inputs = '../Data/Matlab/';
outputs = '../results/Estimation/';

% hard-coded parameters
rhos = [0.1]; nrhos = length(rhos);     % annual discount factor
deltas = [0.25]; ndeltas = length(deltas);   % annual attrition rate
pha = 'CHA';    % PHA abbreviation
model_name='';

%% read in data and model

    % model
    load([inputs 'models/model_file_' model_name '.mat']);

    % development data
    dev_data = readtable([inputs 'projects-ready-' pha '.txt'],...
                    'delimiter','|','ReadVariableNames',true);
    dev_data.size = dev_data.size/100;
    dev_data.income = dev_data.income/10000;
    dev_data.pct_ami = dev_data.pct_median/100;
    
    % eligible data
    hh_data = readtable([inputs 'eligible_' pha '.txt'],...
                    'delimiter','|','ReadVariableNames',true);
    hh_data.income = hh_data.income/10000;
    hh_data.pct_ami = hh_data.pct_ami/100;
    

%% moments from data
    data_moments

%% create data structure from eligible hh's and developments
    design_matrix

%% run estimation
    estimate_model

%% counterfactuals
    counterfactuals
