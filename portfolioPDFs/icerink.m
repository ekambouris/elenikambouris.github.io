%% ICE Rink Cooling System

%% Loop!

% Set Up Knowns
T5 = -10;                     % C
T6 = -9.5;                    % C
T7 = -7.5;                    % C
T8 = -7;                      % C

T1 = -12;
T2 = 100;
T4 = -20;

rhoC = 1.775;                 % kg/m^3
Lmin_conversion = (1/60)*(1/1000)*rhoC;

mCstart = 2*Lmin_conversion;  % kg/s
mCend = 7*Lmin_conversion;    % kg/s

cp_Carbon = 0.842;            % kJ/kg-K
cp_Ammonia = 2.130;

mC = mCstart:0.5:mCend;

for k = 1:1:length(mC)

% Ice Rink CO2 Cycle
    WIcePump(k) = mC*cp_Carbon*(T6-T5);
    QIceRink(k) = mC*cp_Carbon*(T7-T6);
    WTank = 0;
    QHeatExchanger(k) = mC*cp_Carbon*(T5-T8);

    nCoolingCarbon(k) = QHeatExchanger(k)/(WTank-WIcePump(k));

   
% Ammonia Rankine Cycle
    qheatExchanger(k) = cp_Ammonia*(T1-T4);

    mAmmonia(k) = QHeatExchanger(k)/qheatExchanger(k);
    WAmmoniaCompressor(k) = mAmmonia(k)*cp_Ammonia*(T2-T1);
    h4 = 89.05;  % sat. liq
    h3 = h4;
    p3 = 1350; % finding T3 in tables from this (use 1400)
    T3 = 35;

    WAmmoniaPump(k) = mAmmonia(k)*cp_Ammonia*(T4-T3);
    QAmmoniaCondenser(k) = mAmmonia(k)*cp_Ammonia*(T3-T2);

    sysEff = QAmmoniaCondenser(k)/(WAmmoniaPump(k)+WIcePump(k)-WAmmoniaCondenser(k)-WAmmoniaCompressor(k));  % maybe change this

% Heat Exchanger
    
% Constants
    do = 0.0254;
    di = 0.01524;
    N = 200;
    nh = 0.4;
    nc = 0.3;
 
% Steam
mu_Co = ;
Pr_Co = ;
k_Co = ;

    % Reynolds Number
    dh = do-di;
    Re_Co = (dh*mC(k))/(mu_Co*N*(pi/4)*(do^2-di^2));

    % Nusselt Number
    Nu_Co = 0.023*Re_Co^(4/5)*Pr_Co^nh;

    % Heat Transfer Coefficient
    h_Co(k) = (Nu_Co*k_Co)/dh;

% Ammonia
mu_Am = ;
Pr_Am = ;
k_Am = ;

    % Reynolds Number
    Re_Am = (4*m_air)/(N*pi*mu_Am*di);

    % Nusselt Number
    Nu_Am = 0.023*Re_Am^(4/5)*Pr_Am^nc;

    % Heat Transfer Coefficient
    h_Am(k) = (Nu_Am*k_Am)/di;

    % Using Log-Mean
    delT1 = T5-T4; 
    delT2 = T8-T1;
    Tlm_s = (delT2-delT1)/log(delT2/delT1);

    U(k) = ((1/h_Am(k))+(1/h_Co(k)))^-1;

    L_superheater(k) = QHeatExchanger(k)/(N*pi*di*U(k)*Tlm_s);

end



