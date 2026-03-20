function updateLocalGlobal(SyncOption, RepositoryPaths)
narginchk(0, 2);
if nargin < 1
    SyncOption = false;
end
if nargin < 2
    RepositoryPaths = fileparts(mfilename("fullpath"));
end
mu.syncRepositories([], "RepositoryPaths", RepositoryPaths, "SyncOption", SyncOption);
