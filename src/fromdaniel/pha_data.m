% Daniel Waldinger
% 2019-03-28

% Read in process data on tenants, developments, and, if needed, waiting times

pic_data = '../Data/HUD-PIC/2012/';

% HUD PIC data
pic = readtable([pic_data 'PROJECT_2012.csv'],...
                    'delimiter',',','ReadVariableNames',true);
filter = strcmp(pic.STD_CITY,'Cambridge') & strcmp(pic.states,'MA Massachusetts') & strcmp(pic.program_label,'Public Housing');
pic = pic(filter,:);