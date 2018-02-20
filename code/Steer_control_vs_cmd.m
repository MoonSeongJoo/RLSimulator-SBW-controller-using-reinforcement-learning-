% Simple Steering control example to show how to use M-File script wrapper
% to work with a VS solver DLL using the VS API. This version uses
% vs_statement to define the controller with VS Commands specified here
% rather than in the regular Parsfile.

% To run, generate files from from the CarSim browser (use the button 
% "Generate Files for this Run"), and then run this file from MATLAB.

% Check if last loaded library is still in memory. If so, unload it.
clc;
if libisloaded('vs_solver')
  unloadlibrary('vs_solver');
end

% Scan simfile for DLL pathname. Change the name if it's not what you use.
simfile = 'steer_control_vs_cmd.sim';
SolverPath = vs_dll_path(simfile);

% Load the solver DLL
[notfound, warnings] = ...
     loadlibrary(SolverPath, 'vs_api_def_m.h', 'alias', 'vs_solver');

% libfunctionsview('vs_solver'); % uncomment to see all API functions

% Start and read normal inputs
t = calllib('vs_solver', 'vs_setdef_and_read', simfile, 0, 0);

% Use vs_statement API function to apply VS Commands after reading Parsfile
vs_statement('DEFINE_UNITS', 'deg/m DR');

% define three new parameters
vs_statement('DEFINE_PARAMETER', 'L_FORWARD 20; m ; Distance to view point')
vs_statement('DEFINE_PARAMETER', ...
    'LAT_TRACK -1.6; m ; Distance vehicle is offset from road centerline');
vs_statement('DEFINE_PARAMETER', 'GAIN_STEER_CTRL 10; deg/m ; Control gain');

% define two new output variables and set the component label for each
vs_statement('DEFINE_OUTPUT', ...
    'Xpreview = XCG_TM + L_FORWARD*cos(YAW); m ; X coordinate of preview point');
vs_statement('DEFINE_OUTPUT', ...
    'Ypreview = YCG_TM + L_FORWARD*sin(YAW); m ; Y coordinate of preview point');
vs_statement('SET_OUTPUT_COMPONENT', 'Xpreview Steer control preview point');
vs_statement('SET_OUTPUT_COMPONENT', 'Ypreview Steer control preview point');

% activate the IMP_STEER_SW import variable and set using an EQ_IN equation
vs_statement('IMPORT', 'IMP_STEER_SW vs_replace');
vs_statement('EQ_IN', ...
    'IMP_STEER_SW = if_gt_0_then(t, (LAT_TRACK - road_l(Xpreview, Ypreview))*GAIN_STEER_CTRL, 0)');

calllib('vs_solver', 'vs_initialize', t, 0, 0);
disp(calllib('vs_solver', 'vs_get_output_message'));

stop = calllib('vs_solver', 'vs_error_occurred');
disp('The simulation is running...');

% Call vs_integrate repeatedly until stop is nonzero
while ~stop
    [stop, t] = calllib('vs_solver', 'vs_integrate', t, 0);
end

% Terminate solver
calllib('vs_solver', 'vs_terminate_run', t);
disp('The simulation has finished.');

% Unload solver DLL
unloadlibrary('vs_solver');
