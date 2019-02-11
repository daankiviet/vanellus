classdef VTrackingsAnalysis < handle %% C
% VTrackingsAnalysis Object for the Analysis of Trackings

% Copyright Daan Kiviet 2018-
% Version : 2017-03-07

    properties (Constant)
        DEFAULT_SETTINGS_SIZECHANGE = [-6 10];
    end
    
    properties (Transient) % not stored
        trackings
        
        problems
    end

    methods
        %% loading and obj building / updating %%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function obj = VTrackingsAnalysis( trackings )
            obj.trackings       = trackings;
            
            obj.problems        = {};
        end
 

        %% helper %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function actionAnalyze(obj, doLength, sizeChange)
            disp(['Analyzing Trackings']);
            
            % get tree
            tree = obj.trackings.region.tree;
            
            % first make sure tree is up to date
            tree.updateTree();
            
            % this will store the problems
            obj.problems = {}; % frameNr cellNr SegNr ProblemString
            
            % Size Change Analysis
            if doLength
                % get data for frame, segNr, daughter1, daughter2, length
                data_frame      = tree.getUpdatedData('frame');
                data_segNr      = tree.getUpdatedData('segNr');
                data_daughter1  = tree.getUpdatedData('daughter1');
                data_daughter2  = tree.getUpdatedData('daughter2');
                data_length     = tree.getUpdatedData('length');
                micronPerPixel  = obj.trackings.get('img_micronPerPixel');
                cellNrs         = find(~cellfun(@isempty, tree.cell2idx)); 
                
                % loop over the cells
                for cellNr = cellNrs

                    % check growth in each frame
                    idxs        = tree.cell2idx{cellNr};
                    for i = 1:length(idxs)-1

                        % calculate increase in length
                        sizeIncrease = data_length( idxs(i+1) ) - data_length( idxs(i) );

                        if sizeIncrease < sizeChange(1)
                            obj.problems{end+1} = [ 'Fr '  VTools.str( data_frame( idxs(i) ) ) ...
                                                    ' c# ' num2str(cellNr) ...
                                                    ' s# ' num2str( data_segNr( idxs(i) ) ) ...
                                                    ': Size change = ' num2str(round(sizeIncrease / micronPerPixel)) ' pixels (to small)'];
                            
                        elseif sizeIncrease > sizeChange(2)
                            obj.problems{end+1} = [ 'Fr '  VTools.str( data_frame( idxs(i) ) ) ...
                                                    ' c# ' num2str(cellNr) ...
                                                    ' s# ' num2str( data_segNr( idxs(i) ) ) ...
                                                    ': Size change = ' num2str(round(sizeIncrease / micronPerPixel)) ' pixels (to large)'];
                        end
                    end
                    
                    % check growth after division
                    cellNr_daughter1 = data_daughter1( idxs(1) );
                    cellNr_daughter2 = data_daughter2( idxs(1) );
                    
                    if ~isnan(cellNr_daughter1) && ~isnan(cellNr_daughter2) && cellNr_daughter1>0 && cellNr_daughter2>0
                    
                        % calculate increase in length
                        idxs_daughter1        = tree.cell2idx{cellNr_daughter1};
                        idxs_daughter2        = tree.cell2idx{cellNr_daughter2};
                        sizeIncrease = data_length( idxs_daughter1(1) ) + data_length( idxs_daughter2(1) ) - data_length( idxs(end) );

                        if sizeIncrease < sizeChange(1)
                            obj.problems{end+1} = [ 'Fr '  VTools.str( data_frame( idxs(end) ) ) ...
                                                    ' c# ' num2str(cellNr) ...
                                                    ' s# ' num2str( data_segNr( idxs(end) ) ) ...
                                                    ': Size change Div = ' num2str(round(sizeIncrease / micronPerPixel)) ' pixels (to small)'];
                            
                        elseif sizeIncrease > sizeChange(2)
                            obj.problems{end+1} = [ 'Fr '  VTools.str( data_frame( idxs(end) ) ) ...
                                                    ' c# ' num2str(cellNr) ...
                                                    ' s# ' num2str( data_segNr( idxs(end) ) ) ...
                                                    ': Size change Div = ' num2str(round(sizeIncrease / micronPerPixel)) ' pixels (to large)'];
                        end                        
                        
                    end
                end
                
                % sort obj.problems
                obj.problems = sort(obj.problems);
            end
        end
    end
end
