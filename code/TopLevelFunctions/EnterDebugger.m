function EnterDebugger()
%EnterDebugger Summary of this function goes here
%   Detailed explanation goes here
dbs = dbstack;
dbstop('in',dbs(1).name,'at',num2str(dbs(1).line+2));
end

