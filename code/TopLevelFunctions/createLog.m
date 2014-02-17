function createLog( message, permission, varargin )

persistent logpath
if ~isempty(varargin)
    logpath = varargin{1};
end

fID = fopen(logpath, permission);
fprintf(fID, sprintf(message));
fclose(fID);

end
