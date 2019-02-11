classdef VTools %% C
% VTools Contains Static helper functions

% Copyright Daan Kiviet 2018-
% Version : 2017-03-07

    methods(Static = true)
        
        function string = addToEndOfString(string,addition)
           if ~VTools.endsWith(string,addition)
               string = [string addition];
           end
        end
        
        function tf = endsWith(string,ending)
            tf = false;
            if length(string)>=length(ending) & strcmp( string(end-length(ending)+1:end), ending)
               tf = true;
           end
        end
                
        function tf = dataStringLessThan(dateString1, dateString2)
            tf = min([find(dateString1 < dateString2) 11]) < min([find(dateString1 > dateString2) 11]);
        end
        
        function string = all2str( var )
        % returns string version of input variable. Does not work for structures, classes, or >2 dimensional arrays
            if isempty( var )
                if ischar( var)
                    string = '''''';
                elseif iscell( var )
                    string = '{ }';
                else
                    string = '[]';
                end
            else
                if iscell( var )
                    string = ['{ '];
                    for i = 1:size( var, 1)
                        if i>1, string = [string ' ; ']; end
                        string = [string VTools.all2str( var{i,1} )];
                        for j = 2:size( var, 2 )
                            string = [string ', ' VTools.all2str( var{i} )];
                        end
                    end                        
                    string = [string ' }'];
                else
                    if size(var, 1) > 1
                        string = [VTools.all2str( var(1,:) )];
                        for i = 2:size(var, 1)
                            string = [string ';' VTools.all2str( var(i,:) )];
                        end
                    else
                        if ischar( var )
                            string = ['''' var '''' ];
                        elseif isa( var, 'function_handle')
                            string = func2str( var );
                            if string(1) ~= '@', string = ['@' string]; end
                        elseif isnumeric( var )
                            string = num2str( var );
                        elseif islogical( var )
                            tf_words = {'false','true'};
                            string = tf_words{var(1,1)+1};
                            for i = 2:size(var, 2)
                                string = [string ' ' tf_words{var(1,i)+1}];
                            end
                        end
                    end
                    if size(var, 2) > 1 && ( isnumeric( var ) || islogical( var ) )
                        string = ['[' string ']'];
                    end
                end                
            end
        end

        function subfoldernames = getSubfoldernames(folderpath)
            if ~VTools.isFolder(folderpath)
                subfoldernames = {};
                return;
            end
            d = dir(folderpath);
            idx = [d(:).isdir];
            subfoldernames = {d(idx).name}';
            subfoldernames(ismember(subfoldernames,{'.','..'})) = [];
        end

        function parentfolderpath = getParentfolderpath(path)
            if VTools.endsWith(path, filesep)
                path = path(1:end-1);
            end
            [parentfolderpath, ~, ~] = fileparts(path);
            parentfolderpath = [parentfolderpath filesep];
        end

        function parentfoldername = getParentfoldername(path)
            parentfoldername = '';
            path = VTools.addToEndOfString(path, filesep);
            SepIdx = strfind(path, filesep);
            if length(SepIdx) > 2
                parentfoldername = path( SepIdx(end-2)+1 : SepIdx(end-1)-1);
            end
        end        
        
        function folderpath = getFolderpath(path)
            [folderpath, ~, ~] = fileparts(path);
            folderpath = [folderpath filesep];
        end
        
        function foldername = getFoldername(filenamePath)
            foldername = '';
            if VTools.isFolder(filenamePath)
                filenamePath = VTools.addToEndOfString(filenamePath, filesep);
            end
            SepIdx = strfind(filenamePath, filesep);
            if length(SepIdx) > 2
                foldername = filenamePath( SepIdx(end-1)+1 : SepIdx(end-0)-1);
            end
        end
        
        function currentScriptfolderpath = getCurrentScriptFolderpath()
            [stackTrace, ~] = dbstack('-completenames');
            if length(stackTrace) > 1
                fullpath = stackTrace(2).file;
                [currentScriptfolderpath, currentScriptFilename, ext] = fileparts(fullpath);
                currentScriptfolderpath = [currentScriptfolderpath filesep];
            else
                currentScriptfolderpath = [pwd filesep];
            end
        end

        function result = isFolder(foldername)
            result = exist(foldername, 'dir') == 7;
        end
        
        function tf = mkdir(foldername)
            tf = false;
            if ischar(foldername) && ~isempty(foldername) && exist(foldername, 'dir')~=7
                tf = mkdir(foldername);
            end
            if exist(foldername, 'dir')==7, tf = true; end
        end
        
        function filename = getFilename(filenamePath)
            [~, filename, ~] = fileparts(filenamePath);
        end 
        
        function result = isFile(filename)
            result = exist(filename, 'file') == 2;
        end

        function data = makeEven(data)
            data = uint16(round(data));
            for i = 1:length(data)
                if mod(data(i),2)==1
                    data(i) = data(i)-1;
                end
            end
        end
        
        function output = scaleRange(input, source_range, target_range)
            if source_range(1) == source_range(2)
              source_range = source_range + [-1 1];
            end

            scale_factor = (target_range(2) - target_range(1)) / (source_range(2) - source_range(1)) ;
            shift_factor = ( target_range(1)*source_range(2) - target_range(2)*source_range(1) ) / (source_range(2) - source_range(1));

            output = input * scale_factor + shift_factor;
            output(find(output>target_range(2))) = target_range(2);
            output(find(output<target_range(1))) = target_range(1);        
        end        

        function B = imtranslate(A, shift)
            B = imtranslate(A, [shift(2) shift(1)]);
        end
        
        function B = imrotate(A, angle, isSameSize)
            if nargin < 3, isSameSize = false; end
            
            if isSameSize
                B = imrotate(A, -angle, 'bilinear','crop');
            else
                B = imrotate(A, -angle, 'bilinear');
            end
        end
        
        function B = implace(B, A, x, y)
            % copied from DJK_imagePlace
            [rows1, cols1] = size(B);
            [rows2, cols2] = size(A);    

            row = round( y - 0.5*rows2 );
            col = round( x - 0.5*cols2 );

            rmin2 = max(1,1-row);
            cmin2 = max(1,1-col);    

            rmin1 = max(1,1+row);
            cmin1 = max(1,1+col);    

            rmax2 = min(rows1-row, rows2);
            cmax2 = min(cols1-col, cols2);    

            rmax1 = min(rows2+row, rows1);
            cmax1 = min(cols2+col, cols1);    

            if rmax1 < 1 | cmax1 < 1 | rmax2 < 1 | cmax2 < 1 | rmin1 > rows1 | cmin1 > cols1 | rmin2 > rows2 | cmin2 > cols2
              return;
            end

            B(rmin1:rmax1, cmin1:cmax1) = A(rmin2:rmax2, cmin2:cmax2);
        end
        
        function rgb = addPhaseOverlayToRGB(rgb, im)
            overlay = double(im);
            overlay = VTools.scaleRange(overlay, [max(max(overlay)) min(min(overlay))], [0 1]);
            overlay = VTools.scaleRange(overlay, [0.25 1], [0 1]);
            rgb = 0.25 * rgb + 0.5 * repmat(overlay, [1 1 3]);
        end     
                
        function rectCor = calcCorrectRect(rect, imSize)
            h = imSize(1); w = imSize(2);
            
            if rect(1) > w || rect(2) > h || rect(1)+rect(3) < 1 || rect(2)+rect(4) < 1
                rectCor = [0 0 0 0];
                return;
            end
            
            rectCor(1:2) = min(rect(1:2), [w h]);
            rectCor(1:2) = max(rectCor(1:2), [1 1]);
            
            rectCor(3:4) = rect(3:4) - rectCor(1:2) + rect(1:2);
            
            rectCor(3:4) = max(rectCor(3:4), [1 1]);
            rectCor(3:4) = min(rectCor(3:4), [w-rectCor(1)+1 h-rectCor(2)+1]);
        end
        
        function coorRotated = rotateCoordinates( coor, k, oriRegionSize)
            for i = 1:size(coor,1)
                temp = zeros( oriRegionSize );
                temp = rot90(temp, k);
                temp( round(coor(i,1)), round(coor(i,2)) ) = 1;
                temp = rot90(temp, -k);
                [coorRotated(i,1), coorRotated(i,2)] = find(temp); 
            end
            coorRotated = cast(coorRotated,'like',coor);
        end
        
        function im = getImageOfNr(number)
            text = num2str(number); 
            text = text + 0;

            im = zeros(10,8*length(text));     

            location = 1;
            end_width = 0;

            for i=1:length(text)
                code=text(i);           

                if code==45 % -
                    TxtIm=[0,0,0,0,0,0;
                           0,0,0,0,0,0;
                           0,0,0,0,0,0;
                           0,0,0,0,0,0;
                           0,0,0,0,0,0;
                           0,1,1,1,1,0;
                           0,0,0,0,0,0;
                           0,0,0,0,0,0;
                           0,0,0,0,0,0;
                           0,0,0,0,0,0];
                elseif code==46 % .
                    TxtIm=[0,0,0,0;
                           0,0,0,0;
                           0,0,0,0;
                           0,0,0,0;
                           0,0,0,0;
                           0,0,0,0;
                           0,0,0,0;
                           0,0,0,0;
                           0,1,1,0;
                           0,0,0,0];
                elseif code==48 % 0
                    TxtIm=[0,0,0,0,0,0,0,0;
                           0,0,1,1,1,1,0,0;
                           0,1,1,0,0,1,1,0;
                           0,1,1,0,0,1,1,0;
                           0,1,1,0,0,1,1,0;
                           0,1,1,0,0,1,1,0;
                           0,1,1,0,0,1,1,0;
                           0,1,1,0,0,1,1,0;
                           0,0,1,1,1,1,0,0;
                           0,0,0,0,0,0,0,0];
                elseif code==49 % 1
                    TxtIm=[0,0,0,0,0,0;
                           0,0,0,1,1,0;
                           0,0,1,1,1,0;
                           0,1,1,1,1,0;
                           0,0,0,1,1,0;
                           0,0,0,1,1,0;
                           0,0,0,1,1,0;
                           0,0,0,1,1,0;
                           0,0,0,1,1,0;
                           0,0,0,0,0,0];
                elseif code==50 % 2
                    TxtIm=[0,0,0,0,0,0,0,0;
                           0,0,1,1,1,1,0,0;
                           0,1,1,0,0,1,1,0;
                           0,0,0,0,0,1,1,0;
                           0,0,0,0,0,1,1,0;
                           0,0,0,0,1,1,0,0;
                           0,0,0,1,1,0,0,0;
                           0,0,1,1,0,0,0,0;
                           0,1,1,1,1,1,1,0;
                           0,0,0,0,0,0,0,0];
                elseif code==51 % 3
                    TxtIm=[0,0,0,0,0,0,0,0;
                           0,0,1,1,1,1,0,0;
                           0,1,1,0,0,1,1,0;
                           0,0,0,0,0,1,1,0;
                           0,0,0,1,1,1,0,0;
                           0,0,0,0,0,1,1,0;
                           0,0,0,0,0,1,1,0;
                           0,1,1,0,0,1,1,0;
                           0,0,1,1,1,1,0,0;
                           0,0,0,0,0,0,0,0];
                elseif code==52 % 4
                    TxtIm=[0,0,0,0,0,0,0,0;
                           0,0,0,0,1,1,0,0;
                           0,0,0,1,1,1,0,0;
                           0,0,1,1,1,1,0,0;
                           0,0,1,1,1,1,0,0;
                           0,1,1,0,1,1,0,0;
                           0,1,1,1,1,1,1,0;
                           0,0,0,0,1,1,0,0;
                           0,0,0,0,1,1,0,0;
                           0,0,0,0,0,0,0,0];
                elseif code==53 % 5
                    TxtIm=[0,0,0,0,0,0,0,0;
                           0,0,1,1,1,1,1,0;
                           0,0,1,1,0,0,0,0;
                           0,1,1,0,0,0,0,0;
                           0,1,1,1,1,1,0,0;
                           0,0,0,0,0,1,1,0;
                           0,0,0,0,0,1,1,0;
                           0,1,1,0,0,1,1,0;
                           0,0,1,1,1,1,0,0;
                           0,0,0,0,0,0,0,0];
                elseif code==54 % 6
                    TxtIm=[0,0,0,0,0,0,0,0;
                           0,0,1,1,1,1,0,0;
                           0,1,1,0,0,1,1,0;
                           0,1,1,0,0,0,0,0;
                           0,1,1,1,1,1,0,0;
                           0,1,1,0,0,1,1,0;
                           0,1,1,0,0,1,1,0;
                           0,1,1,0,0,1,1,0;
                           0,0,1,1,1,1,0,0;
                           0,0,0,0,0,0,0,0];
                elseif code==55 % 7
                    TxtIm=[0,0,0,0,0,0,0,0;
                           0,1,1,1,1,1,1,0;
                           0,0,0,0,1,1,0,0;
                           0,0,0,0,1,1,0,0;
                           0,0,0,1,1,0,0,0;
                           0,0,0,1,1,0,0,0;
                           0,0,1,1,0,0,0,0;
                           0,0,1,1,0,0,0,0;
                           0,0,1,1,0,0,0,0;
                           0,0,0,0,0,0,0,0];
                elseif code==56 % 8
                    TxtIm=[0,0,0,0,0,0,0,0;
                           0,0,1,1,1,1,0,0;
                           0,1,1,0,0,1,1,0;
                           0,1,1,0,0,1,1,0;
                           0,0,1,1,1,1,0,0;
                           0,1,1,0,0,1,1,0;
                           0,1,1,0,0,1,1,0;
                           0,1,1,0,0,1,1,0;
                           0,0,1,1,1,1,0,0;
                           0,0,0,0,0,0,0,0];
                elseif code==57 % 9
                    TxtIm=[0,0,0,0,0,0,0,0;
                           0,0,1,1,1,1,0,0;
                           0,1,1,0,0,1,1,0;
                           0,1,1,0,0,1,1,0;
                           0,1,1,0,0,1,1,0;
                           0,0,1,1,1,1,1,0;
                           0,0,0,0,0,1,1,0;
                           0,1,1,0,0,1,1,0;
                           0,0,1,1,1,1,0,0;
                           0,0,0,0,0,0,0,0];
                else code==57 % ?
                    TxtIm=[1,1,1,1,1,1,1,1;
                           1,1,1,1,1,1,1,1;
                           1,1,1,1,1,1,1,1;
                           1,1,1,1,1,1,1,1;
                           1,1,1,1,1,1,1,1;
                           1,1,1,1,1,1,1,1;
                           1,1,1,1,1,1,1,1;
                           1,1,1,1,1,1,1,1;
                           1,1,1,1,1,1,1,1;
                           1,1,1,1,1,1,1,1];
                end

                width = size(TxtIm,2);

                im(1:10,location:location+width-1)=TxtIm; 

                end_width = end_width + width;
                location = location + width;
            end
        end
        
        function latestVersionString = getLatestVersionString()
            if ispref('Vanellus', 'lv')
                lv = getpref('Vanellus', 'lv');
                if iscell(lv) && numel(lv)==2 && ischar(lv{1}) && isnumeric(lv{2}) && VTools.getUnixTimeStamp() < lv{2}+3600
                    latestVersionString = lv{1};
                    return;
                end
            end
            latestVersionString = VTools.updateLatestVersionString();
        end
        
        function latestVersionString = updateLatestVersionString()
            latestVersionString = '';
            try
                [latestVersionString,onServer] = urlread( 'http://kiviet.com/research/projects/vanellus/latestVersion.php', 'Post', {'version', Vanellus.VERSION}, 'timeout', 0.5);
                setpref('Vanellus', 'lv', {latestVersionString VTools.getUnixTimeStamp()});
            catch
            end
        end
        
        function B = rot90_3D(A, k)
            if nargin < 2, k = 1; end
            
            Asize = size(A);
            k = mod(k, 4);
            switch k
                case 0
                    B = A;
                case 1
                    A = permute(A, [2, 1, 3]);
                    B = A(Asize(2):-1:1, :, :);
                case 2
                    B = A(Asize(1):-1:1, Asize(2):-1:1, :);
                case 3
                    B = permute(A(Asize(1):-1:1, :, :), [2, 1, 3]);
            end
        end

        function html = getHTMLColoredText(text, textcolor, bgcolor)
            if nargin < 3, bgcolor = []; end
            if nargin < 2, textcolor = []; end
            if isempty(bgcolor), bgcolor = [1 1 1]; end
            if isempty(textcolor), textcolor = [0 0 0]; end

            html = [ '<html><table width=400 border=0 bgcolor=' VTools.rgb2hex(bgcolor) '><tr><td color=' VTools.rgb2hex(textcolor) '>' text '</td></tr></table></html>' ];
        end
        
        function hex = rgb2hex(rgb)
            if max(rgb(:))<=1
                rgb = round(rgb*255); 
            else
                rgb = round(rgb); 
            end

            hex(:,2:7) = reshape(sprintf('%02X',rgb.'),6,[]).'; 
            hex(:,1) = '#';
        end        

        function charValue = convertValueToChar(value)
            switch class(value)
                case {'char'}
                    charValue = value;

                case {'double', 'uint32', 'uint16' }
                    charValue = num2str(value);
                    if length(value) > 1, charValue = ['[' charValue ']']; end

                case {'logical'}
                    tf_words = {'false','true'};
                    charValue = tf_words{value+1};

                case {'cell'}
                    areValuesChar = true;
                    for i = 1:numel(value)
                        areValuesChar = areValuesChar & ischar(value{i});
                    end
                    
                    if areValuesChar
                        charValue = '{ ';
                        for i = 1:numel(value)
                            charValue = [charValue '''' value{i} ''' '];
                        end
                        charValue = [charValue '}'];
                    else
                        charValue = '{ cell }';
                    end

                case {'function_handle'}
                    charValue = ['@' char(value)];

                otherwise
                    charValue = 'unknown class';
            end
        end

        function logKey( key )
            if ispref('Vanellus','loggedKeys')
                keys = getpref('Vanellus','loggedKeys');
            else
                keys = [];
            end
            setpref('Vanellus','loggedKeys', [keys key]);
        end
        
        function sendLog(  )
            % 2DO
        end
        
        function timestamp = getUnixTimeStamp( t2 )
            if nargin == 1
                timestamp = VTools.getUnixTimeStamp_OldVersion( t2 );
                return;
            end                
            if verLessThan('matlab','8.4') % in case version is R2014b or older
                timestamp = VTools.getUnixTimeStamp_OldVersion();
                return;
            end
            
            t1 = datetime(1970,1,1,0,0,0,'TimeZone','UTC');
            t2 = datetime('now','TimeZone','local');
            timestamp = uint32(seconds(t2 - t1));
        end
        
        function timestamp = getUnixTimeStamp_OldVersion( t2 )
            if nargin < 1
                t2 = now();
            end
            
            t1 = datenum(1970,1,1,0,0,0);
            temp = java.util.Date();
            t_offset = temp.getTimezoneOffset()/(24*60);
            timestamp = uint32( (t2+t_offset-t1)*(24*60*60) );
        end 
        
        function dt = getDatetimeFromUnixtimestamp( timestamp )
            dt = datetime( timestamp, 'ConvertFrom', 'posixtime', 'TimeZone', 'local');
        end
        
        function addLog4jAppender()
            bfCheckJavaPath(1);
            javaMethod('enableLogging', 'loci.common.DebugTools', 'ERROR');
        end

        function y = str(x, varargin)
            r = inputParser;
            r.addRequired('x', @isnumeric);
            r.addOptional('leadingZeros', 4, @isnumeric); 
            r.parse(x, varargin{:});

            y = num2str(r.Results.x,['%.' num2str(uint8(r.Results.leadingZeros)) 'u']);
        end
        
        function bg_cdata = getBackground()
            if ispref('Vanellus', 'bg_cdata')
                if ~ispref('Vanellus', 'bg_cdata_timestamp') || VTools.getUnixTimeStamp() > getpref('Vanellus', 'bg_cdata_timestamp') + 30*24*60*60
                    VTools.updateBackground();
                end
                bg_cdata = getpref('Vanellus', 'bg_cdata');
            else
                bg_cdata = VTools.updateBackground();
            end
            
            if isempty(bg_cdata) || ~isa(bg_cdata,'uint8') || ndims(bg_cdata) ~=3 || any( size(bg_cdata) < 3 )
                bg_cdata = uint8( zeros([500 500 3]) );
            end
        end
        
        function bg_cdata = updateBackground()
            bg_cdata = [];
            
            try
                url = 'http://kiviet.com/research/projects/vanellus/vanellus.png';
                bg_cdata = webread(url);
            catch
            end
            
            if ~isempty(bg_cdata) && isa(bg_cdata,'uint8') && ndims(bg_cdata) == 3 && all( size(bg_cdata) > 2 )
                setpref('Vanellus', 'bg_cdata', bg_cdata);
                setpref('Vanellus', 'bg_cdata_timestamp', VTools.getUnixTimeStamp());
            end
        end

        function RGB = segToRGB(seg, overlayIm, randomize)
            if nargin < 2, overlayIm = []; end
            if nargin < 3, randomize = false; end
            if ~isa(seg,'double'), seg = double(seg); end
            
            IND = mod(seg,255) + 1;
            IND(seg==0) = 1;

            M = min(max(max(seg)),255);
            mymap(1,:) = [0 0 0];
            mymap(2:1+M,:) = VTools.segColormap(M);

            if randomize
                mymap(2:end,:) = mymap(randperm(M)'+1,:);
            end

            RGB = ind2rgb(IND,mymap);

            if ~isempty(overlayIm) && isequal( size(seg), size(overlayIm))
                RGB = VTools.addPhaseOverlayToRGB(RGB, overlayIm);
            end
        end
        
        function map = segColormap(m)
            if nargin < 1, m = size(get(gcf,'colormap'),1); end

            h = (0:m-1)'/max(m,1);

            temp = 0.4;
            for i = [1:m]
                s(i,1) = temp;
                temp = temp + 0.3;
                if temp>1
                    temp = 0.4;
                end
            end

            temp = 0.6;
            for i = [1:m]
                v(i,1) = temp;
                temp = temp + 0.2;
                if temp>1
                    temp = temp - 0.5;
                end
            end

            if isempty(h)
              map = [];
            else
              map = hsv2rgb([h s v]);
            end
        end

        function new_cdata = applyAlpha( old_cdata, alphadata, backgroundColor)
            cdata       = double(old_cdata)/255;
            alpha       = repmat( double(alphadata)/255, [1 1 3]);
            background  = repmat(shiftdim(backgroundColor, -1), [size(old_cdata,1) size(old_cdata,2) 1]);
            
            new_cdata   = cdata .* alpha + background .* (1-alpha);
            new_cdata   = uint8( 255 * new_cdata);
        end

        function y = uniqueExcluding(x, excludeList)
            y = unique(x);
            if nargin > 1 && ~isempty(excludeList)
                for i = 1:length(excludeList)
                    if isnan(excludeList(i))
                        y(isnan(y)) = [];
                    else
                        y(y==excludeList(i)) = [];
                    end
                end
            end
        end        

    end
end
