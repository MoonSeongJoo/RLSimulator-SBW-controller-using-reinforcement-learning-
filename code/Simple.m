% Run a VS solver from here, without any extensions to the model.

% To run, generate files from the VS browser (use the button 
% "Generate Files for this Run"), and then run this file from MATLAB.

% Check if last loaded library is still in memory. If so, unload it.
clc;
if libisloaded('vs_solver')
  unloadlibrary('vs_solver');
end

% Scan simfile for DLL pathname. Change the name if it's not what you use.
simfile = 'simple.sim'; % assign to variable because it's used twice
SolverPath = vs_dll_path(simfile);

% Load solver DLL, access the API functions, and name it 'vs_solver'
[notfound, warnings] = ...
     loadlibrary(SolverPath, 'vs_api_def_m.h', 'alias', 'vs_solver');
disp('The VS solver DLL is loaded; the simulation is now running...');

% Make the run
calllib('vs_solver', 'vs_run', simfile);
disp('The simulation has finished.');

% Unload solver DLL
unloadlibrary('vs_solver');
