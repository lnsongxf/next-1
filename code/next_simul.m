function [xn_true, xl_true, y, wl] = next_simul(param,set,T, burnin)
% Simulate the CEMP-Preston mixed model. Builds on cemp_simul_fun.m.
% 4 Sep 2019

bet  = param(1);
sig  = param(2);
alph = param(3);
kapp = param(4);
psi_x  = param(5);
psi_pi = param(6);
w    = param(7);
gbar = param(8);
thetbar = param(9);
rho_r = param(10);
rho_i = param(11);
rho_u = param(12);
sig_r = param(13);
sig_i = param(14); 
sig_u = param(15); 
n = set(16);
P = eye(n).*[rho_r, rho_i, rho_u]';


k_n = 2; % number of nonlinear states
k_l = 3; % number of linear states
ne  = 2; % number of state innovations
l = 5; % number of observed variables (check that this is consistent with obs_blocksize!)


xn_true = zeros(k_n,T);
xl_true = zeros(k_l,T);
y  = zeros(l,T);
% 1.) Initialize xn0
randgbar = gbar.*rand(1,1);
k0 = randgbar.^(-1);
pibar0 = randn(1,1);
xn_t_1 = [k0; pibar0];
% evaluate initial xl0 given xn0
[~, ~, ~, fxi] = cemp_functions_matrices(param, k0, pibar0, obs_blocksize);
xi0 = fxi;
xl_t_1 = xi0;

[SIG, Sxi] = cemp_SIG_S(param); 
% generate shock sequence
wl = mvnrnd([0, 0],SIG,T+burnin)'; %  3.)  scale with chol(SIG)
e = randn(l,T+burnin); % measurement error

for t=1:T+burnin
    % 2a) Evaluate functions given xn_{t-1}
    [fk, fpibar, Apibar, fxi, Axi, Sxi, SIG, h0, hpibar, H, R] = cemp_functions_matrices(param, xn_t_1(1), xn_t_1(2), obs_blocksize);
    kt = fk;
    pibar_t = fpibar + Apibar*xl_t_1;
    xn_t = [kt,pibar_t];
    
    % Map things to SGN notation:
    [fn, An, fl, Al, Gl, h, C, Ql, R, Gn, Qn, Qln] = cemp_to_sgn_notation(fk, fpibar, Apibar, fxi, Axi, Sxi, SIG, hpibar, H, R);
    
    % 2b) Advance xl_t given xn_{t}
    xl_t = fl + Al* xl_t_1 + Gl*wl(:,t);
    
    % 2c) Evaluate yt given xl_t
    y_t = h0 + h*pibar_t + C*xl_t + chol(R)*e(:,t);
    
    if t>burnin
    tt = t-burnin;
    xn_true(:,tt) = xn_t;
    xl_true(:,tt) = xl_t;
    y(:,tt) = y_t;
    end
    % Update
    xn_t_1 = xn_t;
    xl_t_1 = xl_t;
end

