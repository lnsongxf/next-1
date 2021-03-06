% materials 11
% Goals:
% 1. find a reasonable value of the gain gbar
% 21 Nov 2019
clearvars
close all
clc

% Add all the relevant paths and grab the codename
this_code = mfilename;
[current_dir, basepath, BC_researchpath,toolpath,export_figpath,figpath,tablepath,datapath] = add_paths;

% Variable stuff ---
print_figs        = 0;
stop_before_plots = 0;
skip_old_plots    = 0;
output_table = print_figs;

skip_old_stuff = 1;

%% RE model and parameters
tic
[param, setp] = parameters_next;

bet = param.bet;
sig = param.sig;
alph = param.alph;
kapp = param.kapp;
psi_x = param.psi_x;
psi_pi = param.psi_pi;
w = param.w;
gbar = param.gbar;
thetbar = param.thetbar;
rho_r = param.rho_r;
rho_i = param.rho_i;
rho_u = param.rho_u;
sig_r = param.sig_r;
sig_i = param.sig_i;
sig_u = param.sig_u;
rho = param.rho;
ne = 3;
nx = 4;% now n becomes 4
P = eye(ne).*[rho_r, rho_i, rho_u]';
SIG = eye(nx).*[sig_r, 0, 0, 0]';

% Model with interest rate smoothing
[fyn, fxn, fypn, fxpn] = model_NK_intrate_smoothing(param);
[gx,hx]=gx_hx_alt(fyn,fxn,fypn,fxpn);
[ny, nx] = size(gx);
[Ap_RE, As_RE, Aa, Ab, As] = matrices_A_intrate_smoothing(param, hx);

% Time
T = 5*400 % 400
burnin = 0;
% Cross-section
N = 100 %500 size of cross-section

% rng('shuffle');
eN = randn(ne,T,N); % gen all the N sequences of shocks at once.
%% min FEVs by choice of gain gbar -- obsolete b/c this isnt a good notion of gbar_opt
skip_this=1;
if skip_this==0
    tic
    %Optimization Parameters
    options = optimset('fmincon');
    options = optimset(options, 'TolFun', 1e-9, 'display', 'none');
    
    gbar0 = gbar; % start at CEMP's value
    gbar_opt = nan(N,1);
    ub = 0.2;
    lb = 0.00001;
    for n=1:N
        if mod(n,100)==0
            disp([num2str(n) ,' out of ', num2str(N)])
        end
        % Sequence of innovations
        e = [squeeze(eN(:,:,n)); zeros(1,T)]; % adding zero shocks to interest rate lag
        
        %Compute the objective function one time with some values
        %     loss = obj_minFEV(gbar,gx,hx,SIG,T,burnin,e,Aa,Ab,As);
        %Declare a function handle for optimization problem
        oh = @(gbar) obj_minFEV(gbar,gx,hx,SIG,T,burnin,e,Aa,Ab,As);
        gbar_opt(n) = fmincon(oh, gbar0, [],[],[],[],lb,ub,[],options);
    end
    disp(['mean(gbar_opt)=',num2str(nanmean(gbar_opt)), '; var(gbar_opt)=', num2str(nanvar(gbar_opt))])
    toc
end

%% try the exercise Ryan had in mind: simulate data using gbar = 0.145, and then let agents choose gbar_opt to min FEV
%Optimization Parameters
options = optimset('fmincon');
options = optimset(options, 'TolFun', 1e-9, 'display', 'none');

tic
PLM      = 1; % constant only
cgain    = 3; % constant gain
critCEMP = 1; % this doesn't matter
gbar0 = gbar;
ub = 0.2;
lb = -0.2;
gbar_o = nan(N,1);
for n=1:N
    e = squeeze(eN(:,:,n));
    %     e = randn(ne,T);
    e = [e; zeros(1,T)]; % adding zero shocks to interest rate lag
    %         [xsim, ysim] = sim_learn(gx,hx,SIG,T,burnin,e, Aa, Ab, As, param, PLM, cgain, critCEMP);
    
    % suppose the DGP was RE
    [xsim, ysim] = sim_model(gx,hx,SIG,T,burnin,e);
    
    oh = @(gbar) obj_minFEV_Ryan(gbar,xsim,ysim, gx, hx,T);
    gbar_o(n) = fmincon(oh, gbar0, [],[],[],[],lb,ub,[],options);
end
disp(['mean(gbar_opt)=',num2str(nanmean(gbar_o)), '; var(gbar_opt)=', num2str(nanvar(gbar_o))])
disp(['% of gbar_opt < 0 is ', num2str(100* numel(find(gbar_o<0))/N), '%.'])
toc
altvar = nansum(gbar_o.^2)/(N-1) - (nansum(gbar_o)/(N-1) )^2; % just checking that nanvar is ok.


%% plot MSE = FEV for various values of gbar
[fs, lw] = plot_configs;
ng = 1000;
gbar_vals = linspace(-0.002, 0.002, ng);
mse_Ryan = zeros(1,ng);

e = squeeze(eN(:,:,n));
% e = randn(ne,T);
e = [e; zeros(1,T)];
% DGP for Ryan's FEVmin method
[xsim, ysim] = sim_learn(gx,hx,SIG,T,burnin,e, Aa, Ab, As, param, PLM, cgain, critCEMP);
% suppose the DGP was RE
% [xsim, ysim] = sim_model(gx,hx,SIG,T,burnin,e);
for i=1:ng
    gbar_i = gbar_vals(i);
    mse_Ryan(i) = obj_minFEV_Ryan(gbar_i, xsim,ysim, gx, hx,T);
end

if skip_this==0 % not plottin cause i know it's monotonic
    % MSE as a function of gbar for one sequence of errors
    figure
    set(gcf,'color','w'); % sets white background color
    set(gcf, 'Position', get(0, 'Screensize')); % sets the figure fullscreen
    plot(gbar_vals,mse_Ryan, 'linewidth', lw)
    title('MSE(gen data given gbar, min FEV) for the 1st shock sequence')
    ax = gca; % current axes
    ax.FontSize = fs;
    grid on
    grid minor
end

% all optimal gbars across the cross-section
figure
set(gcf,'color','w'); % sets white background color
set(gcf, 'Position', get(0, 'Screensize')); % sets the figure fullscreen
plot(sort(gbar_o), 'linewidth', lw); hold on
plot(zeros(size(gbar_o)), '--', 'linewidth', lw)
title('\kappa^* across the cross-section')
ax = gca; % current axes
ax.FontSize = fs;
grid on
grid minor

figname = [this_code, '_', 'gbar_opt_distrib'];
% figname = [this_code, '_', 'gbar_opt_distrib_RE'];
if print_figs ==1
    disp(figname)
    cd(figpath)
    export_fig(figname)
    cd(current_dir)
    close
end

%% some stability analysis
M = 100;
ul = 0.05;
k_vals = linspace(-ul,ul,M);
for ki=1:M
    k = k_vals(ki);
    x1(ki) = (-1+sqrt(1-4*k))/(2*k);
    x2(ki) = (-1-sqrt(1-4*k))/(2*k);
end

figure
set(gcf,'color','w'); % sets white background color
set(gcf, 'Position', get(0, 'Screensize')); % sets the figure fullscreen
subplot(1,2,1)
plot(k_vals,x1, 'linewidth', lw); hold on
plot(k_vals,zeros(size(gbar_o)), '--', 'linewidth', lw)
% ylim([-1,1])
ax = gca; % current axes
ax.FontSize = fs;
grid on
grid minor
subplot(1,2,2)
plot(k_vals,x2,'linewidth', lw); hold on
plot(k_vals,zeros(size(gbar_o)), '--', 'linewidth', lw)
% ylim([-1,1])
ax = gca; % current axes
ax.FontSize = fs;
grid on
grid minor
sgtitle('Roots of characteristic eq. of FE difference eq., w/ 2 lags', 'fontsize',fs)
