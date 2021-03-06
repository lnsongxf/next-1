% simulate data from learning model with Euler equation learning
% here agents learn about the constant ONLY
% 17 sept 2019

function [xsim, ysim, shock,a] = sim_learn_EE_constant(gx,hx,eta,T,ndrop,e,Ap, As, param, setp)

ny = size(gx,1);
nx = size(hx,1);

ysim = zeros(ny,T);
xsim = zeros(nx,T);

%Learning PLM matrices, just a constant. Using RE as default starting point. 
a = zeros(ny,1);
b = gx*hx;

%Simulate, with learning
for t = 1:T-1
    
    if t == 1
        ysim(:,t) = gx*xsim(:,t);
        xesim = hx*xsim(:,t);
    else
        %Form Expectations using last period's estimates
        Ezp = Ez_h_constant(param, setp, a,b, xsim(:,t), 1);
        
        %Solve for current states
        ysim(:,t) = Ap*Ezp + As*xsim(:,t);
        xesim = hx*xsim(:,t);
      
        %Update coefficients    
        a = a + t^(-1)* (ysim(:,t)-(a + b*xsim(:,t-1)) );
        
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
