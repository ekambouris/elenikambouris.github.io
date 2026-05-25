%% Eleni Kambouris CFD Project 2 Code
clc
clear
close all

% Extra Credit Initial Conditions are commented and uncommented depending 
% on the desired output of figures

%% Question 2
% Set up Schemes - 
schemes = {
    @(nu) 1;                               % Lax-Friedrichs
    @(nu) abs(nu);                          % Upwind
    @(nu) nu.^2;                            % Lax-Wendroff
    @(nu) (1/3) + (2/3)*nu.^2             % Min dispersion
    };

schemeNames = {'Lax-Friedrichs', 'Upwind', 'Lax-Wendroff', 'Min-Dispersion'};
% Set up Nu Options
nus = [1.0; 0.75; 0.50; 0.25];

% Set up time
a = 1;
T = 3/(2*a);

% Outer Loop for all 4 Schemes -
for s = 1:4
    scheme = schemeNames{s}; % for printing
    % select scheme and set up constants
    q_func = schemes{s};
    M = 32; dx = 1/M;
    x = (0:M-1)*dx + dx/2;

    % Extra Credit - 
    xi = 0.25; d = 3*dx;
    u_packet = cos(pi*(x-xi)/(2*d)).^2 .* (abs(x-xi) <= d);

% Next Loop to Run Through Nu Options - 
    for n = 1:4
        nu = nus(n);
        dt = (nu*dx)/a;
        t = 0:dt:T;
        N = ceil(T / dt);  % Number of time steps
        T = N * dt;
        q = q_func(nu);

        % Compute exact results and set up boundary conditions and array
        % u_exact = sin(2*pi*(x - a*T));
        % u = sin(2*pi*x);

        % Extra Credit
        u = u_packet;
        cells_to_shift = round(1.5 / dx);           
        u_exact = circshift(u_packet, cells_to_shift);

        % Update the U values with time - 
        
        for z = 1:N
            u = update_u(u, q, dx, dt, a);
        end

        % Compute amplitude and phase error
        [amp, phase] = fit_sine(x, u);
        amp_error = abs(amp) - 1;
        phase_error = -360 * phase; 
        
        % L1 error
        L1 = mean(abs(u - u_exact));

        fprintf('%s, nu=%.2f: Amp err=%.4f, Phase err=%.2f deg, L1=%.4f\n', ...
                scheme, nu, amp_error, phase_error, L1);
   
        figure(s)
        subplot(2,2,n)
        plot(x,u,'bo-','MarkerSize',4)
        hold on
        grid on
        plot(x,u_exact,'r--')
        xlabel('x')
        ylabel('u')
        legend("Nu = " + num2str(nu), "Exact Solution","Location","NorthWest")
        sgtitle('Comparing Nu Values for ' + string(schemeNames(s)));
        hold off
    end
end

%% Question 3
T = [0.5 1.0]; % leave a = 1
color = {'b','m','r','g'};

for t_bar = 1:2
    T_curr = T(t_bar);
    dist = 0.25 + T_curr;  % exact position of shock
    %u_exact = double(x <= dist);

    % Extra Credit - 
    xi = 0.25; d = 3*dx;
    u_packet = cos(pi*(x-xi)/(2*d)).^2 .* (abs(x-xi) <= d);
    
    
    for s = 1:4
        scheme = schemeNames{s}; % for printing
        q_func = schemes{s};
        % plot the exact solution
        figure(4+t_bar)
        subplot(2,2,s)
        plot(x, u_exact, 'k--', 'LineWidth', 2);
        hold on
        for n = 1:4
        nu = nus(n); dt = nu*dx/a; N = round(T_curr/(dt));
        q = q_func(nu); 
        % u = zeros(1,M); u(1:M/4) = 1;

        % Extra Credit
        u = u_packet;
        cells_to_shift = round(1.5 / dx);           
        u_exact = circshift(u_packet, cells_to_shift);

            for t = 1:N
            u = update_u_shock(u, q, dx, dt, a);
            end

            % plots of discrete schemes
            figure(4+t_bar) 
            subplot(2,2,s)
            plot(x, u, color{n});
            title(string(scheme))
            xlabel('x')
            ylabel('u')
            grid on
            if t_bar == 1
                 ylim([-0.2 1.2])
            elseif t_bar == 2
                ylim([0.8 1.1])
            end
        % L1 error
        L1 = mean(abs(u - u_exact));

        fprintf('%s, nu=%.2f:, L1=%.4f\n', ...
                scheme, nu, L1);

        % add a legend? without extra entries warning??
        legend('Exact','Nu = 1', 'Nu = 0.75', 'Nu = 0.5', 'Nu = 0.25',"Location","Southwest")
        sgtitle('Comparing Nus for Schemes with aT = ' + string(T_curr));
        end

    end

end



%% Question 4
T = 0.5; % leave a = 1
color = {'b','m','r','g'};


    T_curr = T;
    dist = 0.25 + T_curr;  % exact position of shock
   % u_exact = double(x <= dist); 
    
    % Extra Credit - 
    xi = 0.25; d = 3*dx;
    u_packet = cos(pi*(x-xi)/(2*d)).^2 .* (abs(x-xi) <= d);

    for s = 1:4
        scheme = schemeNames{s}; % for printing
        q_func = schemes{s};
        % plot the exact solution
        figure(7)
        subplot(2,2,s)
        plot(x, u_exact, 'k--', 'LineWidth', 2);
        hold on
        for n = 1:4
        nu = nus(n); dt = nu*dx/a; N = round(T_curr/(dt));
        q = q_func(nu); 
        %u = zeros(1,M); u(1:M/4) = 1;

        % Extra Credit
        u = u_packet;
        cells_to_shift = round(1.5 / dx);           
        u_exact = circshift(u_packet, cells_to_shift);
        
            for t = 1:N
            u = update_u_shock_newFlux(u, nu, dx, dt);
            end

            % plots of discrete schemes
            figure(7) 
            subplot(2,2,s)
            plot(x, u, color{n});
            title(string(scheme))
            xlabel('x')
            ylabel('u')
            grid on
            ylim([-0.2 1.2])

        % L1 error
        L1 = mean(abs(u - u_exact));

        fprintf('%s, nu=%.2f:, L1=%.4f\n', ...
                scheme, nu, L1);

        % add a legend? without extra entries warning??
        legend('Exact','Nu = 1', 'Nu = 0.75', 'Nu = 0.5', 'Nu = 0.25',"Location","Southwest")
        sgtitle('Comparing Nus for Schemes with B-Flux Formula and aT = ' + string(T_curr));
        end

    end


%% Helper Functions - 

    % Update Function
    function u_new = update_u(u, q, dx, dt, a)
    % Extend periodically
    u_ext = [u(end), u, u(1)];
    
    F = flux(u_ext, q, dx, dt, a);
    
    % Update
    u_new = u - (dt/dx) * (F(2:end) - F(1:end-1));
    end
    
    % Flux Function
    function F = flux(u_ext, q, dx, dt, a)
    M_ext = length(u_ext);
    F = zeros(1, M_ext-1);  % Fluxes at j+1/2
    
    for j = 1:M_ext-1
        f_L = a * u_ext(j);
        f_R = a * u_ext(j+1);
        
        F(j) = 0.5*(f_L + f_R) - (q/2) * (dx/dt) * (u_ext(j+1) - u_ext(j));
    end
    end

    % Amplitude and Phase - 
    function [A, phi] = fit_sine(x, u)
    c = mean(u.*cos(2*pi*x));
    s = mean(u.*sin(2*pi*x));
    A = 2*sqrt(c^2 + s^2);
    phi = atan2(s,c)/(2*pi);
    end

    % Shock Function
    function u_new = update_u_shock(u, q, dx, dt, a)
    u_ext = [1, u, u(end)];
    
    F = flux(u_ext, q, dx, dt, a);
    
    % Update
    u_new = u - (dt/dx) * (F(2:end) - F(1:end-1));
    end





    % Shock Function - Part 4
    function u_new = update_u_shock_newFlux(u, nu, dx, dt)
    u_ext = [1, u, u(end)];
    
    F = flux_4(u,u_ext,nu);
    
    % Update
    u_new = u - (dt/dx) * (F(2:end) - F(1:end-1));
    end

    % Part 4 Flux Function
    function F = flux_4(u,u_ext, nu)

    M = length(u);
    delta = diff(u_ext); F = zeros(1,M+1);
    for j = 1:M
        dxB = delta(j); dyB = delta(j+1);

    % Set up B Conditions - 
    if sign(dxB)*sign(dyB) <= 0
        B = 0;
    else
        r = dxB/dyB;
        if abs(r) >= 0.5 && abs(r) <= 2.0
            B =  max(abs(dxB), abs(dyB));
        else
            B =  2 * min(abs(dxB), abs(dyB));
        end
    end
        % Get Flux
        F(j) = u_ext(j) + (1-nu)/2 * B; % a = 1 so like don't really have to multiply by it
    end
    end