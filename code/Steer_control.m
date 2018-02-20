% Simple Steering control example to show how to use M-File script wrapper
% to work with a VS solver DLL using the VS API. This version uses
% vs_statement to setup the VS Solver with import and export variables to
% match the arrays defined in MATLAB.

% To run, generate files from from the CarSim browser (use the button 
% "Generate Files for this Run"), and then run this file from MATLAB.
% This is set up to look for a file named 'steer_control_vs_cmd.sim'.

% Check if last loaded library is still in memory. If so, unload it.
clc;
if libisloaded('vs_solver')
  unloadlibrary('vs_solver');
end

% Scan simfile for DLL pathname. Change the name if it's not what you use.
simfile = 'steer_control.sim';
SolverPath = vs_dll_path(simfile);
P = py.sys.path;
if count(P,'D:\Work\KaistSW\2017\FinalProject\3.TechnicalConcept\DDPG-Keras-Torcs-master') == 0
    insert(P,int32(0),'D:\Work\KaistSW\2017\FinalProject\3.TechnicalConcept\DDPG-Keras-Torcs-master');
end
% Load the solver DLL
[notfound, warnings] = ...
     loadlibrary(SolverPath, 'vs_api_def_m.h', 'alias', 'vs_solver');

% libfunctionsview('vs_solver'); % uncomment to see all VS API functions

% Start and read normal inputs
t = calllib('vs_solver', 'vs_setdef_and_read', simfile, 0, 0);

% activate three export variables from VS Solver
vs_statement('EXPORT', 'XCG_TM');
vs_statement('EXPORT', 'YCG_TM');
vs_statement('EXPORT', 'YAW');

% define two new import variables in VS Solver
vs_statement('DEFINE_IMPORT', ...
    'IMP_X_PREV = 0; m ; Preview point from MATLAB');
vs_statement('DEFINE_IMPORT', ...
    'IMP_Y_PREV = 0; m ; Preview point from MATLAB');

% activate three import variables for VS Solver
vs_statement('IMPORT', 'IMP_STEER_SW REPLACE 0');
vs_statement('IMPORT', 'IMP_X_PREV');
vs_statement('IMPORT', 'IMP_Y_PREV');

% define two new output variables and set the component label for each
vs_statement('DEFINE_OUTPUT', ...
    'Xpreview = IMP_X_PREV; m ; X coordinate of preview point');
vs_statement('DEFINE_OUTPUT', ...
    'Ypreview = IMP_Y_PREV; m ; Y coordinate of preview point');
vs_statement('SET_OUTPUT_COMPONENT', 'Xpreview Steer control preview point');
vs_statement('SET_OUTPUT_COMPONENT', 'Ypreview Steer control preview point');

calllib('vs_solver', 'vs_initialize', t, 0, 0);
disp(calllib('vs_solver', 'vs_get_output_message'));

% Define parameters that will be used in the steer controller
DR = 180/pi; % constant for units conversion: degrees per radians
Lfwd = 20.0; % preview distance
GainStr = 10; % control gain for steering wheel angle (deg/m)
LatTrack = -1.6; % target lateral position

% Define import/export arrays (both with length 3) and pointers to them
imports = zeros(1, 3);
exports = zeros(1, 3);
p_imp = libpointer('doublePtr', imports);
p_exp = libpointer('doublePtr', exports);

% get time step and export variables from the initialization
t_dt = calllib('vs_solver', 'vs_get_tstep');
calllib('vs_solver', 'vs_copy_export_vars', p_exp);
stop = calllib('vs_solver', 'vs_error_occurred');
disp('The simulation is running...');

% This is the main simulation loop. Continue as long as stop is 0.
while ~stop 
  t = t + t_dt;  % increment time

  % Update the array of exports using the pointer p_exp
  exports = get(p_exp, 'Value');
  Yaw = exports(3)/DR; % convert from deg to rad
  
  % calculate values for MATLAB-based controller 
  Xpreview = exports(1) + Lfwd*cos(Yaw);
  Ypreview = exports(2) + Lfwd*sin(Yaw);
  road_l = calllib('vs_solver', 'vs_road_l', Xpreview, Ypreview);

  % copy values into import array and set pointer for the VS solver
  imports(1)= GainStr*(LatTrack - road_l); 
  imports(2)= Xpreview;
  imports(3)= Ypreview;
  set(p_imp, 'Value', imports); %set pointer for array of imports

  % Call VS API integration function and exchange import and export arrays
  stop = calllib('vs_solver', 'vs_integrate_io', t, p_imp, p_exp);
end

% Terminate solver
calllib('vs_solver', 'vs_terminate_run', t);
disp('The simulation has finished.');

% Unload solver DLL
unloadlibrary('vs_solver');
