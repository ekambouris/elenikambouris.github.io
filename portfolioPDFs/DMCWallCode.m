clc
close
clear

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% READ ME %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The following program takes in a rectangular prism shaped wall 
% (dimensions specified by user) and converts it to DMC code to be read
% by the Optomec LENS MR-7 located in Flores Research Group Laboratory.

% The code is designed to take in a list of parameters (scan speed (mm/s), 
% layer height (mm), number of passes, and scan pattern (WIP); however,
% laser power (W), powder feedrate (g/min), and beam width (mm) are 
% modified outside of the DMC code, on the operating computer itself) that
% are being tested for metallic glass production.

% This code utilizes a convention where a DMC vector move is utilized when
% the laser is on, and DMC coordinate moves when the laser is off.

% NOTE: Vector moves are incremental, while coordinate moves are absolute

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% CREATE DMC FILE
prompt = 'What would you like to name your DMC file?\n';    % input ?
filename = input(prompt, 's');   % Ask user for file name
filename = filename + ".dmc";    % Create filename into DMC file

if isfile(filename)       % If file exists, overwrite it. 
    delete(filename)
    diary(filename)
else                      % If it doesn't, create it.
    diary(filename)
end

% DEBUG VARIABLES
debugvar = 0;

% USER DEFINED VARIABLES
  % Processing Parameters
scanSpd = 8;         % defines the scanning speed in mm/s
numPasses = 2;        % defines # of passes per layer
numLayers = 32;        % defines # of layers; based on layer and wall height
hatchorcrosshatch = 0;     % IN DEVELOPMENT (could be used for add. param.)

  % Wall Characteristics
lengthOfWall = 7;                   % defines wall length in mm
widthOfWall = 1;                    % defines wall width in mm
heightOfWall = 6.35;                 % defines wall height in mm

  % Machine Parameters
resolution = 200000;       % resolution of LENS (typ. 200000)
convert = resolution * (1/25.4);    % used to convert mm to counts in dmc
VA = 3000000;              % defines incremental acceleration, in cts/s^2
VD = 3000000;              % defines incremental decceleration, in cts/s^2
VS = round(scanSpd * convert);      % inc. speed calc. from scaning speed
AC = 3000000;              % defines absolute acceleration, in counts/s^2
DC = 3000000;              % defines absolute decceleration, in counts/s^2
SP = VS;                   % defines absolute speed, in counts/s 

% COMPUTER CALCULATED VARIABLES
    % Convert mmm wall to counts wall
countWidth = widthOfWall * convert;
countLength = lengthOfWall * convert;
countHeight = heightOfWall * convert;

    % Create DMC motion text variables
VAtext = ['VA ',num2str(VA)];
VDtext = ['VD ',num2str(VD)];
VStext = ['VS ',num2str(VS)];
ACtext = ['AC ',num2str(AC),', ',num2str(AC),', ',num2str(AC)];
DCtext = ['DC ',num2str(DC),', ',num2str(DC),', ',num2str(DC)];
SPtext = ['SP ',num2str(SP),',',num2str(SP),',',num2str(SP)];

% DECLARATION OF COORDINATE/VECTOR VARIABLES
originx = 0;
originy = 0;
xcoord = 0;
ycoord = 0;
zcoord = 0;
oldxcoord = 0;
oldycoord = 0;
oldzcoord = 0;
xvector = 0;
yvector = 0; 
zvector = 0;

% BEGINNING PORTION OF DMC CODE 
    % Slicer Comments that are placed at the beginning of all our DMC files
disp('REM SLICE1 PWR  35.0 PF1=1');
disp('REM SLICE2 PWR  35.0 PF2=2');
disp('REM SLICE PWR   END');
disp(['REM ***********************************************************' ...
    '************']);
disp(['REM C:\Documents and Settings\Administrator\Desktop\HEA_5x5_' ...
    'Square_30_y_v2.0.DMC']);
disp(['REM ***********************************************************' ...
    '************']);
disp('REM ********** Convert Slice to DMC Process Parameters **********');
disp('REM Layer Thickness = 0.008 ');
disp('REM Resolution = 5000    ');
disp('REM Contour Feedrate = 40      ');
disp('REM X Axis Resolution = 200000  ');
disp('REM Y Axis Resolution = 200000  ');
disp('REM Z Axis Resolution = 200000  ');
disp('REM Laser On Feedrate = 40      ');
disp('REM Laser On Accel = 60000   ');
disp('REM Laser On Decel = 60000   ');
disp('REM Laser On Shutter Delay = 20      ');
disp('REM Laser Off Feedrate = 60      ');
disp('REM Laser Off Accel = 60000   ');
disp('REM Laser Off Decel = 60000   ');
disp('REM Laser Off Shutter Delay = 20      ');
disp('REM *************************************************************');

    % Begin writing LENS readable code 
disp('DP 0,0,0'); % Sets current position as origin
disp(ACtext); % Declares abs. accelerate in DMC
disp(DCtext); % Declares abs. accelerate in DMC
disp(SPtext); % Declares abs. accelerate in DMC
disp('WT 20000'); % Wait 20 seconds

% IF CROSSHATCH IS ENABLED (Still under development)
if hatchorcrosshatch == 0
    for layers = 1 : numLayers % Repeats for each layer
        % Calculate Height
        if layers == 1
            zHeight = 0;
        else
            zHeight = (layers - 1) * (countHeight / (numLayers - 1));
        end
        
        % Plot layer change for even layers
        if layers > 1 && mod(numPasses, 2) ~= 0 
            quiver3(xcoord / convert, ...
                    yvector / convert, ...
                    prevZHeight / convert, ...
                    -xcoord / convert, ...
                    -yvector / convert, ...
                    (countHeight / (numLayers - 1)) / convert, ...
                    'b-','LineWidth',1,'MaxHeadSize',50)
        end

        % Plot layer change for even layers
        if layers > 1 && mod(numPasses, 2) == 0
            quiver3(xcoord / convert, ...
                    0, ...
                    prevZHeight / convert, ...
                    -xcoord / convert, ...
                    0, ...
                    (countHeight / (numLayers - 1)) / convert, ...
                    'b-','LineWidth',1,'MaxHeadSize',50)
        end
        
        % Write DMC Code
        xcoord = originx;
        ycoord = originy;
        zcoord = zHeight;
        oldxcoord = xcoord;
        oldycoord = ycoord;
        oldzcoord = zcoord;
        xvector = 0;
        yvector = 0;
        zvector = zHeight;
        PAtextdisplay = PAtext_calculate(xcoord, ycoord, zcoord, ...
                         oldxcoord, oldycoord, ...
                         xvector, yvector, zvector, ...
                         hatchorcrosshatch, convert);
        disp(PAtextdisplay);    % Sets move coordinate
        disp('BG XYZ');         % Moves print head
        disp('AM XYZ');         % Waits for print head to finish movement
        passes = 1;

        while passes <= numPasses
            xvector = 0;
            yvector = countLength;
            zvector = zHeight;
            VPtextdisplay = VPtext_calculate(xvector, yvector, zvector, ...
                             xcoord, ycoord, zcoord, ...
                             hatchorcrosshatch, convert);
            disp('VM XY');            % Prepare for vector move
            disp(VAtext);             % Sets inc acceleration
            disp(VDtext);             % Sets inc decceleration
            disp(VStext);             % Sets inc speed
            disp(VPtextdisplay);      % Declares inc movement 
            disp('VE');               % End vector preparation
            disp('SB 1');             % Open laser shutter
            disp('WT 20');            % Wait for shutter to open
            disp('BGS');              % Complete vector move
            disp('AMS');              % Wait for movement to complete
            disp('CB 1');             % Close laser shutter
            disp('WT 30');            % Wait for shutter to close
            passes = passes + 1;
            
            % Breaks the loop if  you have just finished your last pass 
            if passes > numPasses
                debugvar = debugvar+1;
                prevZHeight = zHeight;
                break
            end  

            oldxcoord = xcoord;
            oldycoord = ycoord;
            xcoord = xcoord + (countWidth/(numPasses - 1));
            ycoord = ycoord + countLength;
            zcoord = zHeight;
            PAtextdisplay = PAtext_calculate(xcoord, ycoord, zcoord, ...
                             oldxcoord, oldycoord, ...
                             xvector, yvector, zvector, ...
                             hatchorcrosshatch, convert);
            disp(PAtextdisplay);    % Sets move coordinate
            disp('BG XYZ');         % Moves print head
            disp('AM XYZ');         % Waits for print head to finish move

            xvector = 0;
            yvector = -countLength;
            zvector = zHeight;
            VPtextdisplay = VPtext_calculate(xvector, yvector, zvector, ...
                             xcoord, ycoord, zcoord, ...
                             hatchorcrosshatch, convert);
            disp('VM XY');           % Prepare for vector move
            disp(VAtext);            % Set vector acceleration
            disp(VDtext);            % Set vector decceleration
            disp(VStext);            % Set vector speed
            disp(VPtextdisplay);     % Declare movement coordinates
            disp('VE');              % End vector preparation
            disp('SB 1');            % Open laser shutter
            disp('WT 20');           % Wait for shutter to open
            disp('BGS');             % Begin movement
            disp('AMS');             % Wait for movement to finish
            disp('CB 1');            % Close laser shutter
            disp('WT 30');           % Wait for shutter to close
            passes = passes + 1;
            
            % Breaks the loop if you have just finished your last pass
            if passes > numPasses
                debugvar = debugvar+1;
                prevZHeight = zHeight;
                break
            end
            
            oldxcoord = xcoord;
            oldycoord = ycoord;
            xcoord = xcoord + (countWidth/(numPasses - 1));
            ycoord = ycoord - countLength;
            zcoord = zHeight;
            PAtextdisplay = PAtext_calculate(xcoord, ycoord, zcoord, ...
                             oldxcoord, oldycoord, ...
                             xvector, yvector, zvector, ...
                             hatchorcrosshatch, convert);
            disp(PAtextdisplay);     % Set move coordinates
            disp('BG XYZ');          % Moves print head
            disp('AM XYZ');          % Waits for print head to finish move
        end
    end
end

disp("UI 3");     % End DMC program

diary off % Stops writing dmc file

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%% INNER SCRIPT FUNCTIONS BELOW %%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% Function to create coordinate moves into DMC text and plot on slicer
function p = PAtext_calculate(xcoord, ycoord, zcoord, ...
                              oldxcoord, oldycoord, ...
                              xvector, yvector, zvector, ...
                              hatchorcrosshatch, convert)

    % This creates the text for the absolute movement
    PAtext = ['PA ', ...
              num2str(round(xcoord)), ',', ...
              num2str(round(ycoord)), ',', ...
              num2str(round(zcoord))];
    
    p = PAtext;  % Output variable so it can be used in script

    % This plots what the absolute movement is
    hold on 
    plot3(xcoord / convert, ...
          ycoord / convert, ...
          zcoord / convert, ...
          'bo', LineWidth=2);
    xlabel('X-Axis (mm)');
    ylabel('Y-Axis (mm)');
    zlabel('Z-Axis (mm)');
    title('Slice Image of Wall');
    axis equal

    if hatchorcrosshatch == 0
        % Plots absolute move on slice image
        quiver3((oldxcoord + xvector) / convert, ...
                (oldycoord + yvector) / convert, ...
                zvector / convert, ...
                (xcoord - oldxcoord - xvector) / convert, ...
                (ycoord - oldycoord - yvector)  / convert, ...
                0, ...
                'b-','LineWidth',1,'MaxHeadSize',50)
    end
end


% Function to create vector moves into DMC text and plot on slicer
function v = VPtext_calculate(xvector, yvector, zvector, ...
                              xcoord, ycoord, zcoord, ...
                              hatchorcrosshatch, convert)

    % This creates the text for the incremental movement
    VPtext = ['VP ', ...
              num2str(round(xvector)), ',', ...
              num2str(round(yvector))];

    v = VPtext;   % Output variable so it can be used in script

    % This plots the point to where the vector movement is going
    hold on 
    plot3((xcoord + xvector) / convert, ...
          (ycoord + yvector) / convert, ...
          zvector / convert, ...
         'ro',LineWidth=2)  
    axis equal

    if hatchorcrosshatch == 0
        % This plots the incremental directional arrow 
        quiver3(xcoord / convert, ycoord / convert, zcoord / convert, ...
                xvector / convert, yvector / convert, 0,...
                'r-',LineWidth=1,MaxHeadSize=1)
    end
end
