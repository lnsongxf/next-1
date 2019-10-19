% simulate data from long-horizon learning model
% general code, with lots of subcases
% constant = 1 if learn constant only - right now just give warning if you
% input something else
% gain: 1 = decreasing gain, 2 = endogenous gain, 3 = constant gain
% criterion: 1= CEMP's, 2 = CUSUM
% dt = timing of shock. If 0 or not specified, then no shock.
% x0 = the shock.
% 19 sept 2019

function [xsim, ysim, shock, diff,pibar_seq, k] = sim_learn(gx,hx,eta,T,ndrop,e, Aa, Ab, As, param, setp,H, anal, constant, gain, criterion, dt, x0)
if nargin < 17 %no shock specified
    dt = 0;
    x0 = 0;
end
gbar = param.gbar;
ny = size(gx,1);
nx = size(hx,1);

ysim = zeros(ny,T);
xsim = zeros(nx,T);

if constant==1
    %Learning PLM matrices, just a constant. Using RE as default starting point.
    pibar = 0;
    b = gx*hx;
    b1 = b(1,:);
else
    warning('Requested slope learning, but only learning constant is implemented.')
end

pibar_seq = zeros(T,1);
diff = zeros(T,1);
diff(1) = nan;
k = zeros(1,T);
k(:,1) = gbar^(-1);
%%% initialize CUSUM variables: FEV om and criterion theta
om = 0;
thet = 0; % CEMP don't really help with this, but I think zero is ok.
%%%
%Simulate, with learning
for t = 1:T-1
    
    if t == 1
        ysim(:,t) = gx*xsim(:,t);
        xesim = hx*xsim(:,t);
    else
        %Form Expectations using last period's estimates
        if anal ==1
            [fa, fb] = fafb_anal_constant(param, setp, [pibar;0;0], b, xsim(:,t));
        else
            [fa, fb] = fafb_trunc_constant(param, setp, [pibar;0;0], b, xsim(:,t), H);
        end
        
        %Solve for current states
        ysim(:,t) = Aa*fa + Ab*fb + As*xsim(:,t);
        xesim = hx*xsim(:,t);
        
        %Update coefficients
        % Here the code differentiates between decreasing, endogenous or
        % constant gain
        if gain ==1
            k(:,t) = k(:,t-1)+1;
        elseif gain==2
            % now choose the criterion
            if criterion == 1 % CEMP's
                kt = fk_pidrift(pibar, b, xsim(:,t-1), k(:,t-1), param, setp, Aa, Ab, As);
            elseif criterion == 2 % CUSUM
                f = ysim(1,t)-(pibar + b1*xsim(:,t-1)); % short-run FE
                [kt, om, thet] = fk_cusum(param,k(:,t-1),omt_1, thett_1,f);
            end
            k(:,t) = kt;
        elseif gain==3
            k(:,t) = gbar^(-1);
        end
        pibar = pibar + k(:,t).^(-1).*(ysim(1,t)-(pibar + b1*xsim(:,t-1)) );
        
        % check convergence
        diff(t) = max(max(abs(pibar - at_1)));
        
    end
    
    %Simulate transition with shock
    %%% here is the addition of the impulse
    if t+1==dt
        e(:,t+1) = e(:,t+1)+x0';
    end
    %%%
    xsim(:,t+1) = xesim + eta*e(:,t+1);
    
    % generate an old constant, to check convergence
    at_1 = pibar;
    pibar_seq(t)= pibar;
    %%% update CUSUM parameters
    omt_1 = om;
    thett_1 = thet;
end

%Last period observables.
ysim(:,t+1) = gx*xsim(:,t+1);

%Drop ndrop periods from simulation
xsim = xsim(:,ndrop+1:end);
ysim = ysim(:,ndrop+1:end);
shock = e(:,ndrop+1:end); % innovations