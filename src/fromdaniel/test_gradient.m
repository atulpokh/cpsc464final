% Daniel Waldinger
% 2019-04-11

% Code to test that numerical gradient and analytic gradient are close

%[val,grad,mom,dm,times] = objective_function(N,J,m,A,X,br,E,B,testval,rhos(nn),v,t,deltas(mm));
[val,grad,m0,dm] = objective_function(N,J,m,A,X,w(:,mm),br,E,B,testval,rhos(nn),v,t,deltas(mm));

[m m0]

% test against numerical gradient
vals = zeros(P,1);
% moments = zeros(P);
testval2 = testval;
step = 1e-05;
for pp = 1:P
    testval2(pp) = testval(pp) + step;
    [vals(pp),~,~] = objective_function(N,J,m,A,X,w(:,mm),br,E,B,testval2,rhos(nn),v,t,deltas(mm));
    testval2 = testval;
end

gradnum = (vals-val)/step;
[grad gradnum]
% 
% momentgrad = (moments - mom)/step;
% dif = momentgrad - dm;