% EXTRACT DATA FROM REGION:

%% SETTINGS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
expFolder                   = ['/Users/kivietda/PolyBox/Vanellus Data/2015-09-05 Ara4/'];
posName                     = ['pos16'];
regName                     = ['reg5'];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% load position
reg = VRegion( [expFolder filesep posName filesep regName] );

% extract tree
tree = reg.tree.calcRegionprops('MajorAxisLength');
% tree = reg.tree.compileTree(); % may be buggy

% get lineage
cellNr                      = 101;
rp_length                   = [];
frames                      = [];
while cellNr ~= 0
    rp_length               = [tree( cellNr ).rp_length rp_length];
    frames                  = [tree( cellNr ).frames frames];
    cellNr                  = tree( cellNr ).P;
end    
