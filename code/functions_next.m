function [fk] = functions_next(param,set,zbar,s, kt_1)

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
ne = set(16); % number of state innovations
nxnl = set(17);
nxl = set(18);
ny = set(19);
P = eye(ne).*[rho_r, rho_i, rho_u]';

[A1, A2, A3] = matrices_next(param, set);

I = abs( (eye(ne)- A1/(1-alph*bet) - A2/(1-bet))*zbar + (eye(ne) -(A1*(eye(ne)-alph*bet*P)^(-1) +A2*(eye(ne)-bet*P)^(-1) +A3)*P)*s ) ...
    <= thetbar*(sig_r+sig_i + sig_u);
kt = I.*(kt_1+1) + (1-I)*gbar^(-1);
fk = kt;