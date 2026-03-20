function updateLocalGlobal_server(SyncOption)
narginchk(0, 1);
if nargin < 1
    SyncOption = false;
end
opts.log                  = '';
opts.SyncOption           = SyncOption;
opts.RepositoryPaths      = fileparts(mfilename("fullpath"));

mu.syncRepositories(opts);
