classdef VMasksPad < VMasks
% VMasksPad

% Copyright Daan Kiviet 2018-
% Version : 2017-03-07

    properties (Constant)
        DEFAULT_SETTINGS       =  { 'msk_sigma'                 , uint32(1), 2; ...
                                    'msk_medFilt'               , uint32(1), 3; ...
                                    'msk_cellWidthPixels'       , uint32(1), 16; ...
                                    'msk_EdgeFraction'          , uint32(1), 0.16 };
    end
    
    methods
        %% loading and saving %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function obj = VMasksPad( region )
            obj@VMasks( region ); 
        end
       
        %% calculations %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function data = calcData(obj, idf)
            % actual calculation of mask
            maskSize                = obj.region.regionSize;
            data                    = true( maskSize );

            % make sure that idf can be segmented
            if ~obj.canDataBeCalculated(idf), return; end

            % get image
            type                    = obj.get('msk_imgType');
            im                      = obj.region.getImage( idf(1), type);
            
            % get settings
            msk_sigma               = obj.get('msk_sigma');
            msk_medFilt             = obj.get('msk_medFilt');
            msk_cellWidthPixels     = obj.get('msk_cellWidthPixels');
            msk_EdgeFraction        = obj.get('msk_EdgeFraction');
            
            % filter image
            im_rescaled             = medfilt2( im, [msk_medFilt msk_medFilt]);
            
            % edge of image
            edgeIm                  = edge( im_rescaled, 'log', 0, msk_sigma);

            % select mask where there are little edges
            boxsize                 = 2 * msk_cellWidthPixels; % was 40
            edgeImAv                = imfilter(double(edgeIm), fspecial('average', boxsize) );
            mask                    = edgeImAv < msk_EdgeFraction;

            % remove mask close to border
            mask([1:msk_cellWidthPixels end-msk_cellWidthPixels+1:end],:) = false;
            mask(:,[1:msk_cellWidthPixels end-msk_cellWidthPixels+1:end]) = false;

            % remove blobs smaller than a 2*cell_width^2
            mask                    = bwareaopen( mask, 2*msk_cellWidthPixels*msk_cellWidthPixels, 4);

            % dilate with 1 cell width
            mask                    = imdilate( mask, strel('disk', msk_cellWidthPixels));

            % combine mask with regionMask
            data                    = data & mask & obj.region.regionmask.mask;

            % show when DEBUGGING
            if obj.get('van_DEBUG')
                hFig = figure;
                
                imshow(imadjust(edgeImAv));
                waitforbuttonpress;
                

                cColormap(1,:)                          = [0.0 0.0 0.0];
                maskPlot                                = ones( maskSize );
                cColormap(2,:)                          = [0.3 0.0 0.0];
                maskPlot(obj.region.regionmask.mask)    = 2;
                cColormap(3,:)                          = [0.0 0.3 0.3];
                maskPlot(mask)                          = 3;
                cColormap(4,:)                          = [0.5 0.5 0.0];
                maskPlot(data)                          = 4;
                cColormap(5,:)                          = [0.8 0.8 0.8];
                maskPlot(edgeIm)                        = 5;
                imshow( maskPlot, cColormap ); 
                waitforbuttonpress;
                close(hFig);                
            end
            
        end
        
    end
end

