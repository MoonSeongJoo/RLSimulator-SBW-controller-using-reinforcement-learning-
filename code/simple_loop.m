% Run a VS solver from here, without any extensions to the model. This
% example uses API functions to start (vs_setdef_and_read and
% vs_initialize), run (vs_integrate), and terminate (vs_terminate).

% To run, generate files from from the CarSim browser (use the button 
% "Generate Files for this Run"), and then run this file from MATLAB.

% Check if last loaded library is still in memory. If so, unload it.
clc;
if libisloaded('vs_solver')
  unloadlibrary('vs_solver');
end

% Scan simfile for DLL pathname. Change the name if it's not what you use.
simfile = 'simple.sim';
SolverPath = vs_dll_path(simfile);

% Load the solver DLL
[notfound, warnings] = ...
     loadlibrary(SolverPath, 'vs_api_def_m.h', 'alias', 'vs_solver');

% libfunctionsview('vs_solver'); % uncomment to see all VS API functions

% Start and read normal inputs
t = calllib('vs_solver', 'vs_setdef_and_read', simfile, 0, 0);
calllib('vs_solver', 'vs_initialize', t, 0, 0);
disp(calllib('vs_solver', 'vs_get_output_message'));

% stop is 0 to continue, nonzero to stop. Check current status
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
