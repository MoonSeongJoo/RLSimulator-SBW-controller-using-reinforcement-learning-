function [] = vs_statement(keyword, rest)
%VS_STATEMENT An M function that applies the vs_statement API function

calllib('vs_solver', 'vs_statement', keyword, rest, 1);