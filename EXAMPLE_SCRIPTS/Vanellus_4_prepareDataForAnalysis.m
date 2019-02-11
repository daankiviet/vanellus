% PREPARE REGIONS  FOR ANALYSIS:
% 1. set SETTINGS to specify what you want analyse
%    - imageFolder  : location of image files on your harddisk (or external disk)
%    - destFolder   : location where Vanellus analysis will be setup (and stored)
%    - datasets     : parameters specifying regions
%              (1)  : position Nr
%              (2)  : region Nr
%              (3)  : frames to analyze
%              (4)  : shift in x between regions
%              (5)  : shift in y between regions
%              (6)  : rotation (1 / 2 / 3 / 4)
%              (7)  : width of region
%              (8)  : height of region
%              (9)  : minimum x of 1st region
%              (10) : minimum y of 1st region
%
% 2. run script below once
%

%% SETTINGS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
imageFolder     = ['/Volumes/EXTERNALHARDDRIVE/DATA/2015-09-05 Ara4/IMAGES/'];
destFolder      = ['/Users/kivietda/PolyBox/Vanellus Data/2015-09-05 Ara4/'];

%              pos, reg, frames, xsh, ysh, rot, wid, hei, xmi, ymi
datasets = {    ...
                16,  5, [1:582], 122,   0,   1, 120, 650,  66, 136; ...
                16,  6, [1:582], 122,   0,   1, 120, 650,  66, 136; ...
                17,  1, [1:382], 123,   0,   1, 120, 650,  80, 122; ...
                17,  2, [1:582], 122,   0,   1, 120, 650,  80, 122; ...
           };
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

cd(destFolder);
for i = 1:size(datasets,1)
            
    %% PREPARATION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    posNr                       = datasets{i,1};
    regNr                       = datasets{i,2};
    frames                      = datasets{i,3};
    xshift                      = datasets{i,4};
    yshift                      = datasets{i,5};
    rotate                      = datasets{i,6};
    width                       = datasets{i,7};
    height                      = datasets{i,8};
    xmin                        = datasets{i,9};
    ymin                        = datasets{i,10};
    first_rec                   = [ xmin ymin width height]; % [left bottom width height]
    posName                     = ['pos' num2str(posNr)];
    regName                     = ['reg' num2str(regNr)];
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %% SETUP EXPERIMENT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if exist(['vanellusExp.mat'], 'file') ~= 2
        van = Vanellus(); 
        exp = van.createExperiment(); 
        exp.set('img_class',    @VImagesCellSens);
        exp.set('img_folder',   imageFolder); 
        exp.set('stb_class',    @VStabilizationDFT);
        exp.set('rmsk_class',   @VRegionmaskFlow);
        exp.set('msk_class',    @VMasksV1);
        exp.set('seg_class',    @VSegmentationsV1);
        exp.set('trk_class',    @VTrackingsV1);
        exp.set('ann_class',    @VAnnotationsDivision);
        exp.save();
    else
        exp = VExperiment(); 
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %% SETUP POSITION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if exist([pwd filesep posName filesep 'vanellusPos.mat'], 'file') ~= 2
        pos = exp.createPosition(posName);
        pos.updateImages();
    else
        pos = VPosition([pwd filesep posName]);
    end

    if ~pos.getLocal('pos_isImgUpdated'), pos.updateImages(); end
    if ~pos.getLocal('pos_isImgStabilized'), pos.stabilize(); end
    pos.save();   
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %% SETUP REGIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if exist([pwd filesep posName filesep regName filesep 'vanellusReg.mat'], 'file') ~= 2
        rect = first_rec + [(regNr-1)*xshift (regNr-1)*yshift 0 0];
        reg = pos.createRegion([ regName ], rect);
        reg.set('reg_rotation90', VRegion.ADDITIONAL_ROTATIONS{rotate});
        reg.set('img_frames', frames);
        reg.save();
    else
        reg = VRegion([pwd filesep posName filesep regName]);
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %% CACHE REGIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    reg.cacheImages();
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %% CALCULATE REGIONMASK %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     reg.regionmask.set('img_frames', [1:100]);
%     reg.regionmask.calcAndSetRegionmask();
%     reg.save();
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %% CALCULATE SEGMENTATION AND TRACKING %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     reg.trackings.trackFrames(); 
%     reg.tree.calcTree(); 
%     reg.save();
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end
