% Daniel Waldinger
% 2019-03-29

% First model file for structural estimation
% This version only parameterizes the model; it doesn't include folders,
% filepaths, or model options


clear
model_folder = '../Data/Matlab/models/';
if ~isdir(model_folder), mkdir(model_folder); end

    % model structure
    model.name = '';
    model.model_folder = model_folder;
    model.applicant_characteristics = {'black','hispanic','elderly','children','disabled','income','pct_ami'};
    model.interactions = {{'black','size'},{'elderly','size'},{'children','size'},{'pct_ami','size'},...
                          {'black','tpoverty'},{'elderly','tpoverty'},{'children','tpoverty'},{'pct_ami','tpoverty'},...
                          {'black','tminority'},{'elderly','tminority'},{'children','tminority'},{'pct_ami','tminority'}...
                          {'elderly','family'}};
    
    % Folders...
    
    % Paths...
    
    % model options...
    
save([model_folder 'model_file_' model.name '.mat'],'model');