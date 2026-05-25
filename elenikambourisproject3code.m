%% Eleni Kambouris CFD Project 3 Code
clc
clear
close all

pMax = 0.1; % vehicles/ft
vMax = 50;  % ft/s
dx = 50;    % mesh spacing
carLine = 100; % vehicles waiting
M = 250; % adjust as needed, hopefully gives enough buffer
x = (0:M-1)*dx + dx/2; % for plotting purposes


lineLength = carLine/pMax;
carPosition = lineLength/dx;
xLight = carPosition * dx;

% we will assume that the traffic starts at x = 0, and the light is after
% the minimum required amount of cells that the cars take up

%% Simulation
% Set up Schemes - 
schemeNames = {"Exact Riemann", "Lax-Wendroff", "Roe's Approximate Riemman", "Roe's w/ Entropy Fix"};
schemes = {@ExactRiemann, @LaxWendroff, @RoeApprox, @RoeEntropyFix};

% Get Table Ready
results = table();

% Set up Safety Factor Options
safetyFactors = [0.9, 0.6, 0.3];
colors = {'b--','m','g:'};


% Set up time
T = 60; % seconds

% Outer Loop for all 4 Schemes -
for s = 1:4
    scheme = schemeNames{s}; 
    fluxChoice = schemes{s};

    % Exact results and Plot
    tComp = 60; % seconds
    pExact = exactSol(x, tComp, xLight, pMax, vMax);

% Next Loop to Run Through Safety Factor Options - 
    for n = 1:length(safetyFactors)
        sf = safetyFactors(n);

        p = zeros(1, M);
        p(1:carPosition) = pMax;
        
        t = 0;

        % preallocate matrices to fill
        tHist = []; 
        leadHist = []; 
        lastHist = []; 
        speedHist = [];
        speedTime = [];

        while t < T
            % update dt based on safety factor
            a = vMax * (1 - 2*p/pMax);
            maxSpeed = max(abs(a));
            if maxSpeed == 0 
                maxSpeed = vMax; 
            end
            
            dt = sf * dx / maxSpeed;
            
            % Time step
            p = pUpdate(p, fluxChoice, pMax, vMax, dt, dx);

            t = t + dt;
            tol = dt/2;
            
            % speed stuff
            pLight = p(carPosition);

            if pLight > 0 && pLight < pMax
                vLight = vMax * (1 - pLight/pMax);
                speedHist(end+1) = vLight;
                speedTime(end+1) = t;
            end


            % calc head and tail car positions here ...
            [lastCar, leadCar] = carPositions(p, dx);
            
            % store to plot later
            tHist(end+1)    = t;
            leadHist(end+1) = leadCar;
            lastHist(end+1) = lastCar;

            if abs(t - 20) < tol || abs(t - 40) < tol || abs(t - 60) < tol
                newRow = table( ...
                    string(scheme), ...   % Scheme
                    t, ...                % Time
                    sf, ...               % Safety factor
                    leadCar, ...          % Lead car position
                    lastCar, ...          % Last car position
                    'VariableNames', {'Scheme','Time','SafetyFactor','LeadCar_ft','LastCar_ft'} ...
                );

            results = [results; newRow];
            end
            
        end

        % Plots!!

        % speed at light
        figure(8+s)
        subplot(2,2,n)
        plot(speedTime, speedHist, 'LineWidth', 1.5)
        yline(vMax/2, 'k--', 'Exact value')
        grid on
        xlabel('Time (s)')
        ylabel('Speed at light (ft/s)')
        ylim([5 30])
        title(sprintf('%s — Passing Speed (sf = %.1f)', scheme, sf))

        % Car Trajectory
        figure(4+s)
        subplot(2,2,n)
        plot(tHist, leadHist, 'r', 'LineWidth', 1.5); hold on
        plot(tHist, lastHist, 'b', 'LineWidth', 1.5);
        grid on
        xlabel('Time (s)')
        ylabel('Position (ft)')
        title(sprintf('%s — Vehicle Trajectories (sf = %.1f)', scheme, sf))
        legend('Lead vehicle','Last vehicle','Location','best')


        % Schemes and Safety Factors
        figure(s)
        subplot(2,2,n)
        plot(x, p, 'LineWidth', 1.5);
        hold on
        grid on
        xlabel('x (ft)');
        ylabel('\rho (veh/ft)');
        title(['Safety factor = ' num2str(sf)]);
        ylim([0 pMax*1.2]);
        xlim([0 M*dx]);
        sgtitle(scheme);

        % Comparison of all Safety Factors
        subplot(2,2,4)
        plot(x, p, colors{n}, 'LineWidth', 1.5, ...
             'DisplayName', sprintf('sf = %.1f', sf));
        hold on
        grid on
        xlabel('x (ft)');
        ylabel('\rho (veh/ft)');
        title('Safety factor Comparison');
        
        if n == length(safetyFactors)
            legend('show','Location','best');
        end
    end

    for z = 1:3
    figure(s)
    subplot(2,2,z)
    plot(x, pExact, 'k--', 'LineWidth', 1.5);
    hold on
    end

end

disp(results)
%% Helper Functions

% Update Function
function pNew = pUpdate(p, fluxChoice, pMax, vMax, dt, dx)
    M = length(p);
    F = zeros(1,M);

    for j = 1:M
            pL = p(j);
            if j == M
                pR = p(j);  % right BC: extrapolation
            else
                pR = p(j+1);
            end
            F(j) = fluxChoice(pL, pR, pMax, vMax, dt, dx);
    end

    F_left = fluxChoice(0, p(1), pMax, vMax, dt, dx);
    F = [F_left, F];
    
    pNew = p - (dt/dx) * (F(2:end) - F(1:end-1));

end

% Exact Riemann Flux
function F = ExactRiemann(pL, pR, pMax, vMax, ~, ~)
    fL = vMax*pL*(1-pL/pMax);
    fR = vMax*pR*(1-pR/pMax);
    aL = vMax*(1-2*pL/pMax);
    aR = vMax*(1-2*pR/pMax);

    if aL <= 0 && aR >= 0
        F = vMax*pMax/4;
    elseif aL + aR >= 0
        F = fL;
    else
        F = fR;
    end
end

% Lax-Wendroff Flux
function F = LaxWendroff(pL, pR, pMax, vMax, dt, dx)
    fL = vMax*pL*(1-pL/pMax);
    fR = vMax*pR*(1-pR/pMax);
    f = 0.5*(pL + pR) - 0.5*(dt/dx)*(fR - fL);

    F = vMax*f*(1-f/pMax);
end

% Roe's Approximate Riemann Solver
function F = RoeApprox(pL, pR, pMax, vMax, ~, ~)
    fL = vMax*pL*(1-pL/pMax);
    fR = vMax*pR*(1-pR/pMax);
    aL = vMax*(1-2*pL/pMax);
    aR = vMax*(1-2*pR/pMax);
   
    if aL + aR >= 0
        F = fL;
    else
        F = fR;
    end
end

% Roe's Approximate Riemann Solver with Entropy Fix
function F = RoeEntropyFix(pL, pR, pMax, vMax, ~, ~)
    fL = vMax*pL*(1-pL/pMax);
    fR = vMax*pR*(1-pR/pMax);
    aL = vMax*(1-2*pL/pMax);
    aR = vMax*(1-2*pR/pMax);

    if aL <= 0 && aR >= 0
        F = 0.5*(fL+fR-0.5*(aR-aL)*(pR-pL));
    elseif aL + aR >= 0
        F = fL;
    else
        F = fR;
    end
end

% First and Last Car
function [lastCar, leadCar] = carPositions(p, dx)

    % Cumulative vehicle count at cell edges
    xEdges = (0:length(p)) * dx;
    cum = [0 cumsum(p * dx)];
    total = cum(end);

    % Targets: first and last vehicle centers
    last = 0.5;
    lead = max(total - 0.5, last);

    [cum_u, ia] = unique(cum, 'stable');
    xEdges_u = xEdges(ia);

    % Interpolate positions
    lastCar = interp1(cum_u, xEdges_u, last, 'linear', 'extrap');
    leadCar = interp1(cum_u, xEdges_u, lead, 'linear', 'extrap');
end

% exact solution
function pExact = exactSol(x, t, xLight, pMax, vMax)

    xi = (x - xLight) ./ t;

    pExact = pMax/2 .* (1 - xi./vMax);

    % Enforce bounds of the rarefaction
    pExact(xi < -vMax) = pMax;
    pExact(xi >  vMax) = 0;
end
