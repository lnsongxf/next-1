% simulate data from learning model with Euler equation learning
% Rely strongly on Ryan's code sim_learn.m - here agents learn constant and
% slope
% 14 sept 2019

function [xsim, ysim, shock] = sim_learn_EE(gx,hx,fxp,fx,fyp,fy,eta,T,ndrop,e)

ny = size(gx,1);
nx = size(hx,1);

ysim = zeros(ny,T);
xsim = zeros(nx,T);

%Learning PLM matrices, include a constant. Using RE as default starting point. 
gl = [zeros(ny,1) gx*hx];
[~,sigx] = mom(gx,hx,eta*eta');
R = eye(nx+1); R(2:end,2:end) = sigx;

%Simulate, with learning
for t = 1:T-1
    
    if t == 1
        ysim(:,t) = gx*xsim(:,t);
        xesim = hx*xsim(:,t);
    else
        %Form Expectations using last period's estimates
        yp_e = gl*[1; xsim(:,t)];
        yx = -[fy fxp]\(fyp*yp_e + fx*xsim(:,t));
        
        %Solve for current states
        ysim(:,t) = yx(1:ny);
        xesim     = yx(ny+1:end);
      
        %Update coefficients    
        R = R + t^(-1)*([1;xsim(:,t-1)]*[1;xsim(:,t-1)]' - R);
        gl = (gl' + t^(-1)*(R\([1;xsim(:,t-1)]*(ysim(:,t)-gl*[1;xsim(:,t-1)])')))';
        
    end
    
    %Simulate transition with shock
    xsim(:,t+1) = xesim + eta*e(:,t+1);
end

%Last period observables.
ysim(:,t+1) = gx*xsim(:,t+1);

%Drop ndrop periods from simulation
xsim = xsim(:,ndrop+1:end);
ysim = ysim(:,ndrop+1:end);
shock = e(:,ndrop+1:end); % innovations
