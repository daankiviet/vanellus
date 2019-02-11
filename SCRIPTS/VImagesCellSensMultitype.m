classdef VImagesCellSensMultitype < VImages
% VImagesCellSensMultitype Object that links VImages to CellSens vsi
% files of position on harddisk, expects multiple types per vsi file
%
% Expects files to have this filename format:
% - "pos2-p-A1.vsi" , "pos2-y-A1.vsi" or "pos2-py-A1.vsi" for different image types / layers (in this case p and y)
% - if frames are collected in seperate files -> -A1.vsi & -B1.vsi

% Copyright Daan Kiviet 2018-
% Version : 2017-03-07

    properties (Constant)
        DEFAULT_SETTINGS  = { };
    end
    
    properties
        fileReference % fileReference( frame, type ) = { filename , iPlane }
    end
    
    methods
        %% loading and saving %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function obj = VImagesCellSensMultitype(position)
            obj@VImages(position); 
        end
        
        function tf = update(obj, position) 
            if nargin > 1, obj.position = position; end

            tf = false;
            
            imgFolder               = obj.position.get('img_folder');
            position_name               = VTools.getFoldername( obj.position.filename );
            
            image_listing = struct.empty;
            % collect pos1-py-A1.vsi type filenames if imageFolder exists
            if VTools.isFolder( imgFolder )
                image_listing = dir([imgFolder position_name '-*-*.vsi']);
            end
                
            if ~isempty(image_listing)
                filenames = unique( {image_listing.name} ); % 
                
                % keep track of which frame we are at
                lastFrameSoFar = 0;
                images_cellSens_frameOffset = obj.position.get('img_frameOffset');
                if ~isempty(images_cellSens_frameOffset)
                    lastFrameSoFar = lastFrameSoFar + images_cellSens_frameOffset;
                end
                
                % loop over files, should be sorted already A1 - B1 etc
                for fileNr = 1:length(filenames)
                    
                    % extract different types from filename
                    filename = filenames{fileNr};
                    idx = strfind(filename, '-');
                    type_chars = filename(idx(1)+1:idx(2)-1);
                    
                    % load file and extract nrFrames and nrTypes from it
                    reader = bfGetReader([imgFolder filename]);
                    nrFrames = reader.getSizeT; % frames
                    nrTypes = reader.getSizeC; % types
                    % NOT USED: width = reader.getSizeX; height = reader.getSizeY; nrLayers = reader.getSizeZ
                    
                    % if filename and nrTypes does not correspond, give a warning
                    if nrTypes ~= length(type_chars)
                        warning(['VImagesCellSensMultitype: file contains ' num2str(nrTypes) ' different types, but filename does not correspond: ' filename]); 
                    end
                    
                    % set types
                    for i = 1:nrTypes
                        obj.types{i} = type_chars(i);
                    end
                    
                    % update imageExist
                    frameNrs = [1:nrFrames] + lastFrameSoFar;
                    typeNrs = [1:nrTypes];
                    obj.imageExist(frameNrs, typeNrs) = true;
                    
                    % update fileReference( frame, type ) = { filename , iPlane }
                    serie = 1;
                    for ty = 1:nrTypes
                        for fr = 1:nrFrames
                            frameNr = fr + lastFrameSoFar;
                            iPlane = reader.getIndex( serie - 1, ty -1, fr - 1) + 1;
                            obj.fileReference{ frameNr, ty} = {filename, iPlane};
                        end
                    end
                    
                    % update lastFrameSoFar
                    lastFrameSoFar = lastFrameSoFar + nrFrames;
                end
  
            else        
                warning(['VImagesCellSensMultitype -> cannot find any ' position_name '-*-*.vsi images in folder ' imgFolder]);
            end
            
            % postprocessing steps by calling supercall VImages
            update@VImages(obj);
        end
        
        %% images %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function [im, success] = readImage(obj, frame, type )
            success = true;
            
            % convert type to typeIdx
            typeIdx     = obj.getTypeIdx( type );

            imgFolder   = obj.position.get('img_folder');
            
            % only continue when frame and typeIdx make sene
            if ~isempty(frame) && ~isempty(typeIdx) && frame <= size(obj.imageExist,1) && typeIdx <= size(obj.imageExist,2)
            
                if obj.imageExist( frame, typeIdx )
                    fileReference   = obj.fileReference{ frame, typeIdx };
                    filename        = [ imgFolder fileReference{1} ];
                    iPlane          = fileReference{2};

                    try
                        if VTools.isFile( filename )
                            reader = bfGetReader(filename);
                            im = bfGetPlane(reader, iPlane);
                            reader.close();
                            return;
                        end
                    catch
                    end                
                end
                
            end
            
            warning(['VImagesCellSensMultitype -> requested image (frame=' num2str(frame) ' type=' num2str(type) ...
                        ' does not seem to exist in ' imgFolder]);
            [im, success] = readImage@VImages(obj, frame, type );
        end
    end
end