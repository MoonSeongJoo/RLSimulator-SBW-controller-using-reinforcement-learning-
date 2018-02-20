function [SolverPath] = vs_dll_path(simfile)
%VS_DLL_PATH  A function that scans a simfile for the DLL pathname
SIMFILE = fopen(simfile, 'r');
if SIMFILE == -1
  fprintf('\n   Error: Can''t locate simfile.\n\n');
  return;
end

% Scan simfile to get the pathname for the VS DLL
SolverPath = [];
while 1
  tmpstr = fgetl(SIMFILE);
  if tmpstr == -1  % File end
     break;
  end
  if strncmpi(tmpstr, 'DLLFILE', 7)
    [keyword SolverPath] = strtok(tmpstr);
    SolverPath(1) = [];
    break;
  end
end
fclose(SIMFILE);