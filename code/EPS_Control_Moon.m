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
% P = py.sys.path;
% if count(P,'D:\Work\KaistSW\2017\FinalProject\3.TechnicalConcept\DDPG-Keras-Torcs-master') == 0
%     insert(P,int32(0),'D:\Work\KaistSW\2017\FinalProject\3.TechnicalConcept\DDPG-Keras-Torcs-master');
% end

% Load the solver DLL
[notfound, warnings] = ...
     loadlibrary(SolverPath, 'vs_api_def_m.h', 'alias', 'vs_solver');

% libfunctionsview('vs_solver'); % uncomment to see all VS API functions

% Start and read normal inputs
t = calllib('vs_solver', 'vs_setdef_and_read', simfile, 0, 0);

% activate three export variables from VS Solver
vs_statement('EXPORT', 'M_Tbar');
vs_statement('EXPORT', 'Ay');
vs_statement('EXPORT', 'AV_Y');
% vs_statement('Define_output','Lateral = 0 ; m ;')
% vs_statement('eq_in','Lateral = road_l(XCG_TM,YCG_TM) ;')
vs_statement('EXPORT', 'YAW');
vs_statement('EXPORT', 'Lateral');
vs_statement('EXPORT', 'Steer_SW');
vs_statement('EXPORT', 'StrAV_SW');
vs_statement('EXPORT', 'Steer_L1');
vs_statement('EXPORT', 'Steer_R1');
vs_statement('EXPORT', 'Steer_L2');
vs_statement('EXPORT', 'Steer_R2');
vs_statement('EXPORT', 'Xcg_TM');
vs_statement('EXPORT', 'Ycg_TM');
vs_statement('EXPORT', 'Zcg_TM');
vs_statement('EXPORT', 'curv');


% activate three import variables for VS Solver
vs_statement('IMPORT', 'IMP_F_BOOST_EXT REPLACE 0');
% vs_statement('DEFINE_IMPORT', ... 
%     'IMP_flag = 0; - ; reset flag');
vs_statement('IMPORT', 'IMP_flag');
vs_statement('IMPORT', 'IMP_R_T');

calllib('vs_solver', 'vs_initialize', t, 0, 0);
disp(calllib('vs_solver', 'vs_get_output_message'));

% Define parameters that will be used in the steer controller
DR = 180/pi; % constant for units conversion: degrees per radians
Lfwd = 20.0; % preview distance
GainStr = 10; % control gain for steering wheel angle (deg/m)
LatTrack = -1.6; % target lateral position

% Define import/export arrays (both with length 3) and pointers to them
imports = zeros(1, 2);
exports = zeros(1, 15);
p_imp = libpointer('doublePtr', imports);
p_exp = libpointer('doublePtr', exports);
V_speed =120; % 100kph in carsim constant speed

% get time step and export variables from the initialization
t_dt = calllib('vs_solver', 'vs_get_tstep');
display(t_dt)
calllib('vs_solver', 'vs_copy_export_vars', p_exp);
stop = calllib('vs_solver', 'vs_error_occurred');
disp('The simulation is running...');
% Matlab Python TCP/IP communication for socket
ip = tcpip('127.0.0.1', 40000);
set(ip, 'TimeOut', 10)
set(ip, 'Terminator','CR/LF');
ip.OutputBufferSize = 4096;
ip.InputBufferSize = 4096;
fopen(ip);

% This is the main simulation loop. Continue as long as stop is 0.
while ~stop 

  t = t + t_dt;   % increment time 
  % Update s_t a_t and send-recieve with python
  exports = get(p_exp, 'Value');
  Yaw = exports(4)/DR; % convert from deg to rad
  T_bar_Tq = exports(1);
  Ay = exports(2);
  AV_Y = exports(3);
  Lateral = exports(5);
  Steer_SW = exports(6);
  StrAV_SW = exports(7);
  Steer_L1 =  exports(8);
  Steer_R1 = exports(9);
  Steer_L2 =  exports(10);
  Steer_R2 = exports(11);
  Xcg_TM = exports(12);
  Ycg_TM = exports(13);
  Zcg_TM = exports(14);
  curv = exports(15);
  disp(T_bar_Tq);
  exports_merge = horzcat(t,T_bar_Tq,Ay,AV_Y,Yaw,Lateral,Steer_SW,StrAV_SW,Steer_L1,Steer_R1,Steer_L2,Steer_R2,Xcg_TM,Ycg_TM,Zcg_TM,curv);
  % Send to Python s_t
  exports_t = jsonencode(exports_merge);
  exports2 =['s_t=',exports_t];
  disp(exports2);
  fwrite(ip, exports_t);
  % Recieve to Python a_t
  %pause(1)
%   data=fscanf(ip,'%f',[1,4]);
%   disp(data);
  data = fscanf(ip, '%c');
  data1 = jsondecode(data);
  disp(data1);
  t_next = data1(1);
%   a_t(1) = data1(2)*3.1416*DR; %convert from rad to deg
  a_t(1) = data1(2);
%   if abs(Lateral) > 10 || abs(Yaw) > pi
  if t_next >  20
    flag = 1;
    t = 0 ;
    a_t(1) = 0;
    Lateral = 0;
  elseif abs(Yaw) > pi || StrAV_SW > 1500
    t = 0 ;
    calllib('vs_solver', 'vs_terminate_run', t);
    disp('The simulation has finished.');
  else 
    flag = 0;
  end 
  a_t(2) = flag;
%   a_t(3) = r_t;
  disp(a_t);
  % Send to Carsim a_t01
  set(p_imp, 'Value', a_t); %set pointer for array of imports
  % Call VS API integration function and exchange import and export arrays
  stop = calllib('vs_solver', 'vs_integrate_io', t_next, p_imp, p_exp);
  
  % Update the array of exports using the pointer p_exp for s_t1
  exports = get(p_exp, 'Value');
  Yaw = exports(4)/DR; % convert from deg to rad
  T_bar_Tq = exports(1) ;
  Ay = exports(2) ;
  AV_Y = exports(3) ;
  Lateral = exports(5);
  Steer_SW = exports(6);
  StrAV_SW = exports(7);
  Steer_L1 =  exports(8);
  Steer_R1 = exports(9);
  Steer_L2 =  exports(10);
  Steer_R2 = exports(11);
  Xcg_TM = exports(12);
  Ycg_TM = exports(13);
  Zcg_TM = exports(14);
  curv = exports(15);
  disp(Lateral);
  r_t = cos(Yaw)-abs(sin(Yaw))-(abs(Lateral)/200);
  exports_merge1 = horzcat(T_bar_Tq,Ay,AV_Y,Yaw,Lateral,Steer_SW,StrAV_SW,Steer_L1,Steer_R1,Steer_L2,Steer_R2,Xcg_TM,Ycg_TM,Zcg_TM,curv,r_t,stop);
  % Send to Python s_t1
  exports_t1 = jsonencode(exports_merge1);
  exports2 =['s_t1=',exports_t1];
  disp(exports2);
  fwrite(ip, exports_t1);
  %pause(1); %delay 10 seconds because of sync python
end

% Terminate solver
calllib('vs_solver', 'vs_terminate_run', t);
disp('The simulation has finished.');

% Unload solver DLL
unloadlibrary('vs_solver');
