% Daniel Waldinger
% 2019-03-29

% Code to estimate structural model

rng(295823795)

%% Objective function constraints and starting value

    testval = zeros(P,1);
    testval(1:(3*J)) = -4;
    A = eye(P);
    for ii = 1:7
        A(3*J+ii,3*J+ii) = 10;
    end
    argmins = zeros(P,ndeltas*nrhos); fvals = zeros(ndeltas*nrhos,1);
    mm=1;nn=1;
    dist=1; ii=1; T = m(1:(J*3)); maxiter = 1e03;
    while dist > 1e-03 && ii < maxiter
        [~,m_out] = objective_nograd(N,J,m,A,X,w(:,mm),br,E,B,testval,rhos(nn),v,t,deltas(mm));
        testval(1:(3*J)) = testval(1:(3*J)) + 0.25*(T - m_out(1:(3*J)));
        dist = norm(T - m_out(1:(3*J)));    
        ii=ii+1;
    end
    
    
%     test_gradient
    
%     for mm = 1:ndeltas
%         for nn = 1:nrhos
%             
            display(['Estimating Model for rho= ' num2str(rhos(nn))])
            display(['Estimating Model for delta= ' num2str(deltas(mm))])
            
            %[val,~] = objective_function(N,J,m,A,X,testval,rho,v,t,delta);
            curriedfun = @(x)(objective_function(N,J,m,A,X,w(:,mm),br,E,B,x,rhos(nn),v,t,deltas(mm)));
            estoptions = optimset('Display','iter','MaxIter',500,'MaxFunEvals',1e05,'GradObj','on');
            [argmin,fval,exitflag,output,grad,~] = fminunc(curriedfun,testval,estoptions);
            testval = argmin
            [val,grad,m_out,dm] = objective_function(N,J,m,A,X,w(:,mm),br,E,B,testval,rhos(nn),v,t,deltas(mm));
            
 %           max_perturbations = 10; pert_num = 1;
 %           while fval > 0.01 && pert_num <= 10
%                 display(['Perturbation No. ' num2str(pert_num)])
%                 estoptions = optimset('Display','iter','MaxIter',2e02,'MaxFunEvals',1e05,'GradObj','on');
%                 perturb = zeros(P,1);
%                 perturb(m_out(1:J)==0) = perturb(m_out(1:J)==0) + 2;
%                 startval = testval+perturb;
%                 [argmin,fval,exitflag,output,grad,~] = fminunc(curriedfun,startval,estoptions);
%                 argmin
%                 pert_num = pert_num+1;
 %           end
            
            argmins(:,(mm-1)*ndeltas + nn) = argmin; 
            fvals((mm-1)*ndeltas + nn) = fval;
%         end
%     end
%     
    
    save([outputs 'first_estimates_rho_' num2str(rhos(nn)) '_delta_' num2str(deltas(mm)) '.mat']);

    estimates_table
    writetable(table_ready,[outputs 'parameter_estimates.xls']);