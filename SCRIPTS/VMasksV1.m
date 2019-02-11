classdef VMasksV1 < VMasks
% VMasksV1

% Copyright Daan Kiviet 2018-
% Version : 2017-03-07

    properties (Constant)
        DEFAULT_SETTINGS       =  { 'msk_distOpening'           , uint32(1), 0 };
    end
    
    methods
        %% loading and saving %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function obj = VMasksV1( region )
            obj@VMasks( region ); 
        end
       
        %% calculations %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function data = calcData(obj, idf)
            data = obj.region.regionmask.mask;

            % make sure that idf can be masked
            if ~obj.canDataBeCalculated(idf), return; end
 
            % remove distOpening
            msk_distOpening = obj.get('msk_distOpening');
            if msk_distOpening > 0

                % opening depends on additionalRotation
                rotationAdditional90Idx = obj.region.rotationAdditional90Idx;
                if rotationAdditional90Idx == 1 % '90 LEFT'
                    mostBottomMaskPixel = find(sum(data,2),1,'last');
                    data((mostBottomMaskPixel - msk_distOpening):end, 1:end) = 0;
                    
                elseif rotationAdditional90Idx == 2 % '180'
                    mostLeftMaskPixel = find(sum(data,1),1,'first');
                    data(1:end,1:(mostLeftMaskPixel + msk_distOpening)) = 0;
                    
                elseif rotationAdditional90Idx == 3 % '90 RIGHT'
                    mostTopMaskPixel = find(sum(data,2),1,'first');
                    data(1:(mostTopMaskPixel + msk_distOpening), 1:end) = 0;

                elseif rotationAdditional90Idx == 4 % 'NONE'
                    mostRightMaskPixel = find(sum(data,1),1,'last');
                    data(1:end,(mostRightMaskPixel - msk_distOpening):end) = 0;
                end
            end
            
            % show when DEBUGGING
            if obj.get('van_DEBUG')
                hFig = figure;
                
                cColormap(1,:)                          = [0.0 0.0 0.0];
                maskPlot                                = ones( obj.region.regionSize );
                
                cColormap(2,:)                          = [0.3 0.0 0.0];
                maskPlot(obj.region.regionmask.mask)    = 2;

                cColormap(3,:)                          = [0.0 0.3 0.3];
                maskPlot(data)                          = 3;

                imshow( maskPlot, cColormap ); 
                waitforbuttonpress;
                close(hFig);                
            end            
        end
    end
end