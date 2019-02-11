% PREPARE POSITION FOR ANALYSIS:
% 1. set SETTINGS to specify what you want analyse
%    - imageFolder  : location of image files on your harddisk
%    - posName      : name of position
%    - frames       : frames for this region that you want to analyze
% 2. run script below once

clear all; clear classes; close all; cd(VTools.getCurrentScriptFolderpath());

%% SETTINGS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
imageFolder                 = ['/Volumes/EXTERNALHARDDRIVE/DATA/2015-09-05 Ara4/IMAGES/'];
posName                     = ['pos2'];
frames                      = [1:50];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% SETUP EXPERIMENT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if exist(['vanellusExp.mat'], 'file') ~= 2
    van = Vanellus(); 
    exp = van.createExperiment(); 
    exp.set('img_class',    @VImagesCellSens);
    exp.set('img_folder',   imageFolder); 
    exp.set('img_typeOrder', {'p'} );
    exp.set('stb_class',    @VStabilizationDFT);
    exp.set('rmsk_class',   @VRegionmaskFlow);
    exp.set('msk_class',    @VMasks);
    exp.set('seg_class',    @VSegmentationsV1);
    exp.set('trk_class',    @VTrackingsV1);
    exp.save();
else
    exp = VExperiment(); 
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% SETUP POSITION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if exist([pwd filesep posName filesep 'vanellusPos.mat'], 'file') ~= 2
    pos = exp.createPosition(posName);
else
    pos = VPosition([pwd filesep posName]);
end

pos.set('img_frames', frames);
pos.save();   

if ~pos.getLocal('pos_isImgUpdated'), pos.updateImages(); end
if ~pos.getLocal('pos_isImgStabilized'), pos.stabilize(); end
pos.save();   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% MANUAL ANALYSIS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
gui = VanellusGUI(pos);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
