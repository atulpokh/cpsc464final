% Daniel Waldinger
% 2019-04-10

% Splitting off code for estimates table into separate file

offset = 3;
    table = cell(P+offset,3);
    for ii = 1:P
        table{offset+ii,2} = argmins(ii,1);
    end
    for kk = 1:(3*J)
        br = ceil(kk/J);
        devnum = kk - J*(br-1);
        table{offset+kk,1} = strcat('F.E. ', num2str(br), ' BR, ', dev_data.name(devnum));
    end
    table{offset+3*J+1,1} = 'Household Head African American';
    table{offset+3*J+2,1} = 'Household Head Hispanic';
    table{offset+3*J+3,1} = 'Household Head Elderly';
    table{offset+3*J+4,1} = 'Household Has Children';
    table{offset+3*J+5,1} = 'Household Head Disabled';
    table{offset+3*J+6,1} = 'Household Income ($10,000)';
    table{offset+3*J+7,1} = 'Household Fraction AMI';
    table{offset+3*J+8,1} = 'Household Head African American * Development Size';
    table{offset+3*J+9,1} = 'Household Head Elderly * Development Size';
    table{offset+3*J+10,1} = 'Household Has Children * Development Size';
    table{offset+3*J+11,1} = 'Household Fraction AMI * Development Size';
    table{offset+3*J+12,1} = 'Household Head African American * Tract Poverty Rate';
    table{offset+3*J+13,1} = 'Household Head Elderly * Tract Poverty Rate';
    table{offset+3*J+14,1} = 'Household Has Children * Tract Poverty Rate';
    table{offset+3*J+15,1} = 'Household Fraction AMI * Tract Poverty Rate';
    table{offset+3*J+16,1} = 'Household Head African American * Tract Pct Minority';
    table{offset+3*J+17,1} = 'Household Head Elderly * Tract Pct Minority';
    table{offset+3*J+18,1} = 'Household Head Has Children * Tract Pct Minority';
    table{offset+3*J+19,1} = 'Household Fraction AMI * Tract Pct Minority';
    table{offset+3*J+20,1} = 'Household Head Elderly * Family Development';
    
    table{1,1} = 'Annual Discount Factor';
    table{2,1} = 'Attrition Rate';
    table{3,1} = 'Application Window (Years)';
    table{1,2} = exp(-rhos(nn));
    table{2,2} = deltas(mm);
    table{3,2} = 5;
    
    table_ready = cell2table(table,'VariableNames',{'Coefficient','PointEstimate','SE'});