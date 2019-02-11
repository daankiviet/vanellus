classdef VTrackingsV1 < VTrackings %% C
% VTrackingsV1

% Copyright Daan Kiviet 2018-
% Version : 2017-03-07

    properties (Constant)
        DEFAULT_SETTINGS =    { 'trk_class'         , uint32(1), @VTrackingsV1 ; ...
                                'trk_XX'            , uint32(1), 1  };
    end

    methods
        %% loading and saving %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function obj = VTrackingsV1( region )
            obj@VTrackings( region ); 
        end
    
        %% tracking %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function data = calcData(obj, idf)
            % actual calculation of tracking
            data = uint16( [] );
            
            % make sure that idf can be tracked
            if ~obj.canDataBeCalculated( idf ), return; end
            
            seg1 = obj.region.getSeg( idf(1) );
            seg2 = obj.region.getSeg( idf(2) );

  			cellNrs1 = unique(seg1);
  			cellNrs1 = cellNrs1(cellNrs1~=0);
  			cellNrs2 = unique(seg2);
  			cellNrs2 = cellNrs2(cellNrs2~=0);

            if isempty(cellNrs1) || isempty(cellNrs2)
                data = calcData@VTrackings( obj, idf );
                return;
            end
            
            coordinates1 = VTrackingsV1.getCentroidsOfCells( seg1 );
            coordinates2 = VTrackingsV1.getCentroidsOfCells( seg2 );

            trackLink = [];
            for c2 = cellNrs2'
                % XX 2DO: Used to be 4:5, but shouldn't this be 2:3? 
    			dist_square     = ( coordinates1(cellNrs1,[2 4 6])-coordinates2(c2,2) ).^2 + ( coordinates1(cellNrs1,[3 5 7])-coordinates2(c2,3) ).^2 ;
    			[~, idx]        = sort( min( dist_square, [], 2 ) );

    			trackLink       = [trackLink; cellNrs1(idx(1)) 0 0 c2];
            end
  			
            for c1 = cellNrs1'
                % how often does this cellNr come back?
                if ~isempty(trackLink)
                    cLinkIdx    = find( trackLink(:,1)==c1 );
                else
                    cLinkIdx    = 0;
                end
    
                % if cellNr occurs more than 2 times, it must be linked to extra cell(s) -> do correction, untill only 2 connections
                loopCount = 0;
                while length(cLinkIdx) > 2 && loopCount < 100
                    loopCount = loopCount + 1;
                    
                    barrenCellNrs1 = setdiff( cellNrs1, trackLink(:,1));
                    
                    if isempty(barrenCellNrs1)
                        for c1b = cellNrs1'
                            if length( find(trackLink(:,1)==c1b) ) == 1
                                barrenCellNrs1 = [barrenCellNrs1 c1b];
                            end
                        end
                    end
                    
                    if isempty(barrenCellNrs1)
                        trackLink(cLinkIdx(1), :) = [];
                    else
                        mindist = realmax('double') * ones([max(barrenCellNrs1) max(cLinkIdx)]) ;
                        for c2 = cLinkIdx'
                            dist_square                 = ( coordinates1(barrenCellNrs1,[2 4 6])-coordinates2(c2,2) ).^2 + ...
                                                          ( coordinates1(barrenCellNrs1,[3 5 7])-coordinates2(c2,3) ).^2 ;
                            [dist, idx]                 = sort( min( dist_square, [], 2 ) );
                            c1_closest                  = barrenCellNrs1(idx(1));
                            mindist(c1_closest, c2)     = min( mindist(c1_closest, c2), dist(1) );
                        end
                        [~, idx_c1]     = sort( min( mindist, [], 2 ) );
                        [~, idx_c2]     = sort( mindist(idx_c1(1),:) );

                        % update closest
                        trackLink(idx_c2(1), :) = [idx_c1(1) 0 0 idx_c2(1)];
                    end

                    % recalc
                    cLinkIdx    = find( trackLink(:,1)==c1 );
                end
            end
            data = uint16( VTrackingsV1.convertFromTracking( trackLink ) );
            data = obj.correctData(data, cellNrs1, cellNrs2);            
        end
    end
        
    methods(Static = true)
        function track = convertFromTracking( trackLink )
            track = [];
            for i = 1:size(trackLink,1)
                c1 = trackLink(i,1);
                c2 = trackLink(i,2:4);
                c2(c2==0) = [];
                
                if isempty(c2)
                    track(end+1,:) = [c1 0];
                end
                
                for j = 1:length(c2)
                    track(end+1,:) = [c1 c2];
                end
            end
        end

        function trackLink = convertToTracking( track )
            trackLink = [];
            cellNrs1 = unique( track(:,1) )';
            for c = cellNrs1
                idx = find( track(:,1) == c );
                if length(idx) == 1
                    trackLink(end+1,:) = [c 0 0 track(idx(1),2)];
                elseif length(idx) > 1
                    trackLink(end+1,:) = [c track(idx(1),2) track(idx(2),2) 0];
                end
            end
        end
        
        function centroids = getCentroidsOfCells( seg )
  			% determine 3 coordinates for each cellNr: 1/4, 1/2 & 3/4 of thin
        
            cellNrs = unique( seg );
  			cellNrs = cellNrs( cellNrs~=0 )';

            centroids = [];
  			for c = cellNrs
  				centroids(c,:) = VTrackingsV1.getCentroidsOfCell(seg, c);
  			end            
        end
        
        function centroids = getCentroidsOfCell(Lc, cellno)
            % extract subcell
            cell = +(Lc == cellno);
            [fx, fy]= find(cell);
            extra= 2;
            xmin= max(min(fx) - extra, 1);
            xmax= min(max(fx) + extra, size(cell,1));
            ymin= max(min(fy) - extra, 1);
            ymax= min(max(fy) + extra, size(cell,2));
            subcell= cell(xmin:xmax, ymin:ymax);

            % find thin
            thin = VTrackingsV1.bwmorphmelow(subcell, 'thin', inf);

            % reduce thin until only 2 spur points
            % get # spur points
            spurs = thin & ~VTrackingsV1.bwmorphmelow(thin, 'spur', 1);
            [sx,sy] = find(spurs>0);
            while length(sx)>2
              % try to remove forked ends
              thin = VTrackingsV1.bwmorphmelow(thin, 'spur', 1);

              % get # spur points
              spurs = thin & ~VTrackingsV1.bwmorphmelow(thin, 'spur', 1);
              [sx,sy] = find(spurs>0);
            end

            % get coordinates of thin
            [px, py]= VTrackingsV1.walkthin(thin);

            % find centroids
            if length(px)>0
              % centroids is are thirds of thin
              cen(1) = round(length(px)/4);
              cen(2) = round(length(px)/2);
              cen(3) = round(3*length(px)/4);
              centroids(1)   = cellno;
              centroids(2:3) = [(px(cen(2)) + xmin - 1) (py(cen(2)) + ymin - 1)];
              centroids(4:5) = [(px(cen(1)) + xmin - 1) (py(cen(1)) + ymin - 1)];
              centroids(6:7) = [(px(cen(3)) + xmin - 1) (py(cen(3)) + ymin - 1)];
            else
              disp('Thin to short?');
              centroids = [cellno round(mean(fx)) round(mean(fy)) round(mean(fx)) round(mean(fy)) round(mean(fx)) round(mean(fy))];
            end
        end
        
        function bw2 = bwmorphmelow(bw1,operation,n)
            marg = 3;

            [fx,fy] = find(bw1);
            x1 = max(min(fx)-marg,1);
            x2 = min(max(fx)+marg,size(bw1,1));

            y1 = max(min(fy)-marg,1);
            y2 = min(max(fy)+marg,size(bw1,2));

            if nargin <= 2,
                Z = bwmorph(bw1(x1:x2,y1:y2),operation);
            else
                Z = bwmorph(bw1(x1:x2,y1:y2),operation,n);
            end

            bw2 = zeros(size(bw1));
            bw2(x1:x2,y1:y2) = Z;
        end
        
        function [px, py] = walkthin(thin)
            % add empty border
            thin2= zeros(size(thin)+2);
            thin2(2:end-1, 2:end-1)= thin;
            nopts= length(find(thin > 0));

            if nopts < 5
                px= [];
                py= [];
                return
            end

            % find spurs
            spur= thin2 & ~VTrackingsV1.bwmorphmelow(thin2,'spur',1);
            [sx, sy]= find(spur);
            if isempty(sx)
                px= [];
                py= [];
                return
            end

            % find path
            i= 1; 
            px(1)= sx(1);
            py(1)= sy(1);
            while any(any(thin2)),

                thin2(px(i), py(i))= 0;
                [nx, ny]= VTrackingsV1.neighbours(thin2, px(i), py(i));

                i= i+1;
                if length(nx) > 1
                    % pick closest
                    [~, dI]= min(sqrt((nx - px(i-1)).^2 + (ny - py(i-1)).^2));
                    px(i)= nx(dI);
                    py(i)= ny(dI);
                elseif length(nx) == 1
                    px(i)= nx(1);
                    py(i)= ny(1);
                else
                    break;
                end

                if i > nopts
                    break;
                end

            end

            px= px - 1;
            py= py - 1;
        end
        
        function [nx, ny, colour]= neighbours(img, x, y, bsize)
            if nargin == 3
                bsize= 1;
            end
            colour= [];

            % pad image
            img2= zeros(size(img) + 2*bsize);
            img2(bsize+1:size(img2,1)-bsize, bsize+1:size(img2,2)-bsize)= img;

            % extract subimage
            bxmin= x;
            bxmax= x + 2*bsize;
            bymin= y;
            bymax= y + 2*bsize;
            subimg= img2(bxmin:bxmax, bymin:bymax);
            if bsize > 1
                subimg(2:2*bsize, 2:2*bsize)= zeros(2*bsize-1);
            end
            subimg(bsize+1, bsize+1)= 0;

            % find neighbours
            [nx, ny]= find(subimg > 0);
            % find pixel values of neighbours
            for i= 1:length(nx)
                colour(i,1)= subimg(nx(i), ny(i));
            end

            % translate back to original image
            nx= nx + bxmin - 1 - bsize;
            ny= ny + bymin - 1 - bsize;
        end
    end
end
