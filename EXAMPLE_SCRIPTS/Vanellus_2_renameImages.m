% RENAME VSI IMAGE FILES FOR USE WITH VANELLUS:
% 1. set SETTINGS to specify what you want to do
%    - sourceFile       : orignal vsi filename
%    - destinationFile  : destination vsi filename
%                         Vanellus vsi filenames should be in form "pos1-p-A1"
%                           -> "pos1" indicates name of the position (next would be "pos2")
%                           -> "p" indicates phase contrast (gfp would be "g")
%                           -> "A1" indicates first in series (if you stopped experiment and recorded new images later, next file should be callled "B1")
% 2. run script below once

clear all; clear classes; close all; cd(VTools.getCurrentScriptFolderpath());

%% SETTINGS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
sourceFile                  = ['/Users/kivietda/_2ORGANIZE/DATA/ANALYSIS/2016/2016-08-17 AleM/20160817_Kan4-8-12-16_2hr-05_Pos2_PH2_Exp001.vsi'];
destinationFile             = ['/Volumes/EXTERNALHARDDRIVE/DATA/2015-09-05 Ara4/IMAGES/pos2-p-A1.vsi'];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% COPY IMAGES INTO RIGHT FOLDER AND RENAME %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% make sure that destination directory exists
VTools.mkdir( VTools.getParentfolderpath( destinationFile ) );

% copy vsi file
copyfile( sourceFile, destinationFile);

% copy ets file and folder
soureFileFolder         = [ VTools.getParentfolderpath( sourceFile ) '_' VTools.getFilename( sourceFile ) '_' filesep];
destinationFileFolder   = [ VTools.getParentfolderpath( destinationFile ) '_' VTools.getFilename( destinationFile ) '_' filesep];
copyfile( soureFileFolder, destinationFileFolder);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
