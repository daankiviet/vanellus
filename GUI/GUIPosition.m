classdef GUIPosition < GUITogglePanel
% GUIPosition

% Copyright Daan Kiviet 2018-
% Version : 2017-03-07

    properties
        vanellusGUI
        position

        contentPanel
        controlPanel
        
        uiTogglePanels
        uiTexts
        uiButtons
        uiListboxes
        uiEdits
        uiCheckboxes
        
        picture
        currentFrameIdx
        currentTypeIdx
    end

    methods
        %% loading and gui building / updating %%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function gui = GUIPosition(vanellusGUI, position)
            if nargin < 1
                error('Need VanellusGUI as argument');
            end
            if nargin < 2
                error('Need position as argument');
            end
            gui.vanellusGUI     = vanellusGUI;
            gui.position        = position;

            gui.picture         = VPicture( gui.position );
            gui.currentFrameIdx = 1;
            gui.currentTypeIdx  = 1;

            gui.guiBuild();
        end
 
        function guiBuild(gui)
            % SET CONTROLPANEL
            gui.controlPanel                    = uipanel(gui.vanellusGUI.fig);
            gui.controlPanel.BackgroundColor    = gui.vanellusGUI.CONTROLPANEL_BGCOLOR;
            gui.controlPanel.BorderType         = 'none';
            gui.controlPanel.Units              = 'pixels';
            
            gui.uiTogglePanels                        = uipanel(gui.controlPanel);
            gui.uiTogglePanels(1).BackgroundColor     = gui.vanellusGUI.DISPLAYPANEL_BGCOLOR;
            gui.uiTogglePanels(1).Title               = 'Display';
            gui.uiTogglePanels(1).BorderType          = 'beveledin'; % 'etchedin' (default) | 'etchedout' | 'beveledin' | 'beveledout' | 'line' | 'none'
            gui.uiTogglePanels(1).BorderWidth         = 2; % 1 (default)
            gui.uiTogglePanels(1).Units               = 'pixels';
            
            gui.uiTogglePanels(2)                     = copyobj(gui.uiTogglePanels(1), gui.controlPanel);
            gui.uiTogglePanels(2).BackgroundColor     = gui.vanellusGUI.SETTINGSPANEL_BGCOLOR;
            gui.uiTogglePanels(2).Title               = 'Settings';
            
            gui.uiTogglePanels(3)                     = copyobj(gui.uiTogglePanels(1), gui.controlPanel);
            gui.uiTogglePanels(3).BackgroundColor     = gui.vanellusGUI.ANALYSISPANEL_BGCOLOR;
            gui.uiTogglePanels(3).Title               = 'Analysis';
            
            gui.uiTogglePanels(4)                     = copyobj(gui.uiTogglePanels(1), gui.controlPanel);
            gui.uiTogglePanels(4).BackgroundColor     = gui.vanellusGUI.CACHINGPANEL_BGCOLOR;
            gui.uiTogglePanels(4).Title               = 'Caching';
            
            %% Display Panel
            gui.uiTexts                         = uicontrol(gui.uiTogglePanels(1));
            gui.uiTexts(1).Style                = 'text';
            gui.uiTexts(1).HorizontalAlignment  = 'left';
            gui.uiTexts(1).String               = 'Frame';
            gui.uiTexts(1).BackgroundColor      = gui.uiTexts(1).Parent.BackgroundColor;

            gui.uiButtons                       = uicontrol(gui.uiTogglePanels(1));
            gui.uiButtons(1).Style              = 'pushbutton';
            gui.uiButtons(1).String             = 'Prev';
            gui.uiButtons(1).Callback           = @gui.actionChangeFrame;                                  

            gui.uiEdits                         = uicontrol(gui.uiTogglePanels(1));
            gui.uiEdits(1).Style                = 'edit';
            gui.uiEdits(1).String               = '';
            gui.uiEdits(1).KeyPressFcn          = @gui.actionChangeFrame;            
            
            gui.uiButtons(2)                    = copyobj(gui.uiButtons(1), gui.uiTogglePanels(1));
            gui.uiButtons(2).String             = 'Next';
            gui.uiButtons(2).Callback           = @gui.actionChangeFrame;                          

            gui.uiCheckboxes                    = uicontrol(gui.uiTogglePanels(1));
            gui.uiCheckboxes(1).Style           = 'checkbox';
            gui.uiCheckboxes(1).Value           = 1;
            gui.uiCheckboxes(1).BackgroundColor = gui.uiCheckboxes(1).Parent.BackgroundColor;
            gui.uiCheckboxes(1).Callback        = @gui.guiUpdate;                                  

            gui.uiTexts(3)                      = copyobj(gui.uiTexts(1), gui.uiTogglePanels(1));
            gui.uiTexts(3).String               = 'Thumbnail only (fast)';                                  
            
            gui.uiButtons(3)                    = copyobj(gui.uiButtons(1), gui.uiTogglePanels(1));
            gui.uiButtons(3).String             = 'Update Thumbnail';
            gui.uiButtons(3).Callback           = @gui.actionUpdateThumbnailButtonClicked;                                  

%             gui.uiButtons(4)                    = copyobj(gui.uiButtons(1), gui.uiTogglePanels(1));
%             gui.uiButtons(4).String             = 'Make Movie';
%             gui.uiButtons(4).Callback           = @gui.actionMakeMovieButtonClicked;                                  

            %% Settings Panel
            gui.uiTexts(11)                     = copyobj(gui.uiTexts(1), gui.uiTogglePanels(2));
            gui.uiTexts(11).BackgroundColor     = gui.uiTexts(11).Parent.BackgroundColor;
            gui.uiTexts(11).String              = 'Selected Frames';

            gui.uiEdits(11)                     = copyobj(gui.uiEdits(1), gui.uiTogglePanels(2));
            gui.uiEdits(11).KeyPressFcn         = @gui.actionChangeSelectedFrames;            
            
            gui.uiButtons(11)                   = copyobj(gui.uiButtons(1), gui.uiTogglePanels(2));
            gui.uiButtons(11).String            = 'Clear';
            gui.uiButtons(11).Callback          = @gui.actionClearSelectedFrames;
            
            gui.uiButtons(12)                   = copyobj(gui.uiButtons(1), gui.uiTogglePanels(2));
            gui.uiButtons(12).String            = 'Update Images';
            gui.uiButtons(12).Callback          = @gui.actionUpdateImagesButtonClicked;                                  
            
            gui.uiButtons(13)                   = copyobj(gui.uiButtons(1), gui.uiTogglePanels(2));
            gui.uiButtons(13).String            = 'Delete Position';                                  
            gui.uiButtons(13).Callback          = @gui.actionDeletePosition;
                        
            %% Analysis Panel
            gui.uiButtons(21)                   = copyobj(gui.uiButtons(1), gui.uiTogglePanels(3));
            gui.uiButtons(21).String            = 'Stabilize';
            gui.uiButtons(21).Callback          = @gui.actionStabilizeButtonClicked;                                  

            gui.uiButtons(22)                   = copyobj(gui.uiButtons(1), gui.uiTogglePanels(3));
            gui.uiButtons(22).String            = 'Autodetect Channels';
            gui.uiButtons(22).Callback          = @gui.actionAutoDetectChannelsClicked;
            
            gui.uiButtons(23)                   = copyobj(gui.uiButtons(1), gui.uiTogglePanels(3));
            gui.uiButtons(23).String            = 'Create New Region';
            gui.uiButtons(23).Callback          = @gui.actionRegButtonClicked;

            gui.uiButtons(24)                   = copyobj(gui.uiButtons(1), gui.uiTogglePanels(3));
            gui.uiButtons(24).String            = 'Draw Region';
            gui.uiButtons(24).Callback          = @gui.actionDrawRegionButtonClicked;
            gui.uiButtons(24).KeyPressFcn       = @gui.actionKeyPressed; % ?

            gui.uiTexts(21)                     = copyobj(gui.uiTexts(1), gui.uiTogglePanels(3));
            gui.uiTexts(21).String              = 'Load Region';
            gui.uiTexts(21).BackgroundColor     = gui.uiTexts(21).Parent.BackgroundColor;

            gui.uiListboxes                     = uicontrol(gui.uiTogglePanels(3));
            gui.uiListboxes(1).Style            = 'listbox';
            gui.uiListboxes(1).Min              = 0;
            gui.uiListboxes(1).Max              = 2;
            gui.uiListboxes(1).Value            = [];
            gui.uiListboxes(1).String           = {''};
            gui.uiListboxes(1).Callback         = @gui.actionLoadRegion;                     

            %% Cache Panel
            gui.uiTexts(31)                     = copyobj(gui.uiTexts(1), gui.uiTogglePanels(4));
            gui.uiTexts(31).BackgroundColor     = gui.uiTexts(31).Parent.BackgroundColor;
            gui.uiTexts(31).String              = 'XX cached images (XX MB)';                                  

            gui.uiEdits(31)                     = copyobj(gui.uiEdits(11), gui.uiTogglePanels(4));
            gui.uiEdits(31).Enable              = 'inactive';
            gui.uiEdits(31).BackgroundColor     = gui.uiEdits(31).Parent.BackgroundColor;
            gui.uiEdits(31).String              = vect2colon( gui.position.cache.getCachedFrames() );
            
            gui.uiButtons(31)                   = copyobj(gui.uiButtons(1), gui.uiTogglePanels(4));
            gui.uiButtons(31).String            = 'Cache';
            gui.uiButtons(31).Callback          = @gui.actionCacheImages;                                  

            gui.uiEdits(32)                     = copyobj(gui.uiEdits(11), gui.uiTogglePanels(4));
            gui.uiEdits(32).KeyPressFcn         = @gui.actionCacheImages;            
            gui.uiEdits(32).String              = vect2colon( gui.position.frames' );
            
            gui.uiButtons(32)                   = copyobj(gui.uiButtons(1), gui.uiTogglePanels(4));
            gui.uiButtons(32).String            = 'Clear';
            gui.uiButtons(32).Callback          = @gui.actionCacheImages;                                  
            
            gui.uiButtons(33)                   = copyobj(gui.uiButtons(1), gui.uiTogglePanels(4));
            gui.uiButtons(33).String            = 'Delete Cache';
            gui.uiButtons(33).Callback          = @gui.actionCacheImages;                                  
            
            %% SET TOOLTIPS
            gui.uiEdits(1).TooltipString        = 'keyboard shortcut = g';
            gui.uiButtons(1).TooltipString      = 'keyboard shortcut = < or ,';            
            gui.uiButtons(2).TooltipString      = 'keyboard shortcut = > or , or SPACE';            
            
            %% SET CONTENTPANEL
            gui.contentPanel = ScrollPanel(gui.vanellusGUI.fig);
        end

        function guiPositionUpdate(gui,hObject,eventdata)
            % SET CONTROLPANEL BUTTONS
            % Position coordinates: [left bottom width height]
            
            gui.uiTogglePanels(1).Position  = [ 10 200 280 100]; % Display
            gui.uiTexts(1).Position         = [ 58  70  60  15];
            gui.uiButtons(1).Position       = [ 10  50  40  20];
            gui.uiEdits(1).Position         = [ 55  50  40  20];
            gui.uiButtons(2).Position       = [100  50  40  20];
            gui.uiCheckboxes(1).Position    = [170  50  20  20];
            gui.uiTexts(3).Position         = [190  40  80  30];
            gui.uiButtons(3).Position       = [170  10 100  20];
            
            gui.uiTogglePanels(2).Position  = [ 10 200 280  80]; % Settings
            gui.uiTexts(11).Position         = [ 10  28  75  30];
            gui.uiEdits(11).Position         = [ 85  40 145  20];
            gui.uiButtons(11).Position      = [230  40  40  20];
            gui.uiButtons(12).Position       = [ 10  10 100  20];
            gui.uiButtons(13).Position      = [120  10  80  20];
            
            gui.uiTogglePanels(3).Position  = [ 10 200 280 210]; % Analysis
            gui.uiButtons(21).Position       = [ 10 170 120  20];
            gui.uiButtons(23).Position       = [ 10 140 120  20];
            gui.uiButtons(24).Position       = [140 140  80  20];
            gui.uiTexts(21).Position         = [ 10 110 100  20];
            gui.uiListboxes(1).Position     = [ 10  10 260 100];
            gui.uiButtons(22).Position      = [140 170 120  20];

            gui.uiTogglePanels(4).Position  = [ 10 200 280  80]; % Caching
            gui.uiTexts(31).Position         = [ 10  38 160  20];
            gui.uiEdits(31).Position         = [170  40 100  20];
            gui.uiButtons(31).Position       = [ 10  10  45  20];
            gui.uiEdits(32).Position         = [ 60  10 100  20];
            gui.uiButtons(32).Position       = [160  10  35  20];
            gui.uiButtons(33).Position      = [200  10  70  20];

            % INITIALIZE TOGGLE PANELS
            gui.guiInitializeTogglePanels();            
        end

        function guiUpdate(gui,hObject,eventdata)
            % indicate that GUI is working
            gui.vanellusGUI.fig.Pointer = 'watch';
            drawnow;
            
            % SET LIST OF REGIONS
            regionList = gui.position.regionList;
            gui.uiListboxes(1).String = regionList;
            
            % COLOR BUTTONS RED
            if gui.position.getLocal('pos_isImgUpdated')
                gui.uiButtons(12).BackgroundColor = gui.uiButtons(23).BackgroundColor;
            else
                gui.uiButtons(12).BackgroundColor = [1 0 0]; 
            end
            if gui.position.getLocal('pos_isImgStabilized')
                gui.uiButtons(21).BackgroundColor = gui.uiButtons(23).BackgroundColor;
            else
                gui.uiButtons(21).BackgroundColor = [1 0 0]; 
            end

            % SET CACHE TEXT
            gui.uiTexts(31).String               = [ num2str(gui.position.cache.getNrCachedImages()) ...
                                                    ' cached images (' ...
                                                    num2str(round(gui.position.cache.getCacheFileSize())) ...
                                                    ' MB)'];
            
            % SET DISPLAY BUTTONS
            if gui.uiCheckboxes(1).Value
                % make frame control inactive
                gui.uiTexts(1).Enable     = 'off';
                gui.uiButtons(1).Enable   = 'off';
                gui.uiEdits(1).Enable     = 'off';
                gui.uiButtons(2).Enable   = 'off';

            else
                % make frame control active
                gui.uiTexts(1).Enable     = 'on';
                gui.uiButtons(1).Enable   = 'on';
                gui.uiEdits(1).Enable     = 'on';
                gui.uiButtons(2).Enable   = 'on';

                % UPDATE FRAME NR
                if isempty(gui.picture.parent.frames)
                    gui.uiEdits(1).String = '-';
                else
                    gui.uiEdits(1).String = gui.picture.parent.frames(gui.currentFrameIdx);
                end
            end
            
            % SET SELECTED FRAMES
            gui.uiEdits(11).String = vect2colon( gui.position.frames' );
            % coloring dependend on whether img_frames is set locally
            if isempty( gui.position.getLocal('img_frames') ) % not set here, but inherited from parent
                gui.uiEdits(11).ForegroundColor = [0.4 0.4 0.4];
            else
                gui.uiEdits(11).ForegroundColor = [0 0 0];
            end
            
            % UPDATE CONTENTPANEL (=SCROLLPANEL)
            rgb = gui.getPositionImage();
            hIm = gui.contentPanel.showImage(rgb, gui.vanellusGUI.currentMagnification);
            set(hIm, 'ButtonDownFcn', @gui.actionImageClicked);

            % indicate that GUI is finished
            gui.vanellusGUI.fig.Pointer = 'arrow';
        end
        
        %% Controller %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function rgb = getPositionImage(gui)

            % EITHER GET THUMBNAIL OR FRESH IMAGE
            if gui.uiCheckboxes(1).Value
                % get thumbnail
                thumbs = gui.position.getThumbnail();
                rgb = repmat(thumbs, [1 1 3]);
            else
                % get fresh image
                gui.picture.set('pic_imageFrame', gui.picture.parent.frames(gui.currentFrameIdx));
                rgb = gui.picture.getRGB();
            end
            
            % GET REGIONS RECT
            regionList      = gui.position.regionList;
            regionListRect  = gui.position.getRegionListRect();
            gui.vanellusGUI.guiUpdateNavPanel(); % required as loading of RegionListRect might change position (by storing of rects)
            
            % DRAW REGIONS IN RED AND NAME IN WHITE
            if ~isempty(regionList)
                rectMatrix = zeros([length(regionList) 4]);
                for i = 1:length(regionList)
                    rectMatrix(i,:) = regionListRect{i};
                end                
                rgb = insertShape( rgb, 'FilledRectangle', rectMatrix, ...
                                    'Color', 'red', ...
                                    'Opacity', 0.2);
                rgb = insertText( rgb, rectMatrix(:,[1 2]), regionList, ...
                                    'FontSize', 32, ...
                                    'TextColor', 'white', ...
                                    'BoxOpacity', 0);
            end                            
        end
        
        %% Image or Key Click %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function actionKeyPressed( gui, ~, eventdata)
            switch upper(eventdata.Key)
                case {'LEFTARROW','COMMA'}
                    gui.actionChangeFrame(gui.uiButtons(1));
                case {'RIGHTARROW','PERIOD','SPACE'}
                    gui.actionChangeFrame(gui.uiButtons(2));
                case {'G'}
                    disp(['Clicked key: ' eventdata.Key ' -> Goto frame']);
                    uicontrol( gui.uiEdits(1) );
            end
        end
        
        function actionImageClicked(gui, hObject, ~)
            contentPanelAx      = findall(gui.contentPanel.contentPanel, 'type', 'axes');
            hIm                 = contentPanelAx.Children;
            if hObject == hIm
                coor = uint16(get(contentPanelAx,'CurrentPoint')); % returns [col row]
                coor = coor(1,[2 1]);
                
                % loop over regions and check whether were inside one
                regionList      = gui.position.regionList;
                regionListRect  = gui.position.getRegionListRect();
                for i = 1:length(regionList)
                    if coor(2) >= regionListRect{i}(1) && ...
                       coor(2) <= regionListRect{i}(1) + regionListRect{i}(3) && ...
                       coor(1) >= regionListRect{i}(2) && ...
                       coor(1) <= regionListRect{i}(2) + regionListRect{i}(4)
                        % found region, try to load

                        % check whether everything is saved before leaving
                        if ~gui.vanellusGUI.continueWithoutSaving(), return; end

                        reg = VRegion( [VTools.getParentfolderpath(gui.position.filename) gui.position.regionList{i}] );
                        gui.vanellusGUI.changePanels( GUIRegion(gui.vanellusGUI, reg) );
                        return;
                    end
                end                
            end
        end
        
        
        %% Actions %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function actionChangeFrame(gui, hObject, eventdata)
            drawnow limitrate nocallbacks; % was: pause(0.1);
            if hObject == gui.uiEdits(1)
                if ~isequal( eventdata.Key, 'return'), return; end
                drawnow; % makes sure that uiEdits(2) is up to date
                frame = str2double(get(gui.uiEdits(1), 'String'));
                if ~isnan(frame)
                    idx = find(gui.picture.parent.frames==frame);
                    if ~isempty(idx)
                        gui.currentFrameIdx =idx(1);
                    end
                end
            elseif hObject == gui.uiButtons(1) && gui.currentFrameIdx > 1
                gui.currentFrameIdx = gui.currentFrameIdx - 1;
            elseif hObject == gui.uiButtons(2) && gui.currentFrameIdx < length(gui.picture.parent.frames)
                gui.currentFrameIdx = gui.currentFrameIdx + 1;
            end
            gui.guiUpdate();
        end        
        
        function actionRegButtonClicked( gui, hObject, ~)
            if hObject == gui.uiButtons(23) % Create Region
                disp(['Create Region clicked']);
                region_name = inputdlg({'Region Name','Rect [top left height width]'}, ...
                    'Enter a name for the region (eg. reg1) and its rectangle (eg. 1 1 40 40):', [1 30; 1 30]);                 
                
                % 2DO: better region_name checking
                if length(region_name) > 1
                    rect = str2num(region_name{2});
                    
                    reg = gui.position.createRegion(region_name{1}, rect);
                    gui.vanellusGUI.changePanels( GUIRegion(gui.vanellusGUI, reg) );
                end
            end
        end
        
        function actionLoadRegion( gui, hObject, ~)
            idx = get(hObject,'Value');
            if isempty(idx), return; end % no region selected
            if idx(1) > length(gui.position.regionList), return; end % should not happen
            
            % check whether everything is saved before leaving
            if ~gui.vanellusGUI.continueWithoutSaving(), return; end
            
            reg = VRegion( [VTools.getParentfolderpath(gui.position.filename) gui.position.regionList{idx(1)}] );
            gui.vanellusGUI.changePanels( GUIRegion(gui.vanellusGUI, reg) );
        end         
        
        function actionUpdateImagesButtonClicked(gui, ~, ~)
            gui.position.updateImages();
            gui.guiUpdate();
            gui.vanellusGUI.guiUpdateNavPanel();
        end
        
        function actionCacheImages( gui, hObject, eventdata)
            
            if hObject == gui.uiButtons(31) % 'Cache' button
                framesAction    = ['frames = [' gui.uiEdits(32).String '];'];
                eval(framesAction);
                types           = ''; % all
                gui.position.cacheImages( frames, types );
                
            elseif hObject == gui.uiEdits(32) % 'Cache' editbox
                if ~isequal( eventdata.Key, 'return'), return; end
                framesAction    = ['frames = [' gui.uiEdits(32).String '];'];
                eval(framesAction);
                types           = ''; % all
                gui.position.cacheImages( frames, types );
                
            elseif hObject == gui.uiButtons(32) % 'Clear' button (to clear editbox)
                gui.uiEdits(32).String               = vect2colon( gui.position.frames' );

            elseif hObject == gui.uiButtons(33) % 'Delete Cache' button
                gui.position.cache.clearCacheMatFile();
            end
        
            gui.uiEdits(31).String               = vect2colon( gui.position.cache.getCachedFrames() );
            gui.guiUpdate();
        end
        
        function actionStabilizeButtonClicked( gui, ~, ~)
            gui.position.stabilize();
            gui.guiUpdate();
            gui.vanellusGUI.guiUpdateNavPanel();
        end
        
        function actionDrawRegionButtonClicked( gui, ~, ~)
            % Create Region by drawing
            disp(['Draw Region clicked']);

            % make sure that no thumbnail is shown
            if gui.uiCheckboxes(1).Value
                gui.uiCheckboxes(1).Value = 0;
                gui.guiUpdate();
            end

%             % 2DO: Improve by making dragable rectangle
%             contentPanelAx                          = findall(gui.contentPanel.contentPanel, 'type', 'axes');
%             h = imrect( contentPanelAx );
            rect = getrect;  % saves rectangle as [left top width heigh]
            rectangle( 'Position', rect, 'EdgeColor', 'r'); %shows selected rectangle in red                

            region_name = inputdlg({'Region Name'}, 'Enter a name for the region (eg. reg1):', [1 30]);                 
            if isempty(region_name)
                % canceled
                disp(['Creation of Region canceled']);
                gui.guiUpdate();
                return;
            end

            % 2DO: better region_name checking
            reg = gui.position.createRegion(region_name{1}, rect);
            gui.vanellusGUI.changePanels( GUIRegion(gui.vanellusGUI, reg) );
        end
        
        function actionDeletePosition( gui, ~, ~)
            choice = questdlg('Are you sure that you want to delete this position (and its regions)?', 'Exit?', 'Yes', 'No', 'No');
            % Handle response
            switch choice
                case 'Yes'
                    disp(['Deleting position ' VTools.getParentfoldername(gui.position.filename) ]);
                    exp = gui.position.experiment;
                    gui.position.deletePosition('yes');
                    gui.vanellusGUI.changePanels( GUIExperiment(gui.vanellusGUI, exp) );
                case 'No'
                    disp(['Deletion canceled.']);
            end
        end        
        
        function actionChangeSelectedFrames( gui, ~, eventdata)
            drawnow limitrate nocallbacks; % was: pause(0.1);
            if ~isequal( eventdata.Key, 'return'), return; end
            drawnow; % makes sure that uiEdits(1) is up to date
            action = ['gui.position.set(''img_frames'', ' '[' gui.uiEdits(11).String ']' ');'];
            eval(action);
            gui.guiUpdate();
            gui.vanellusGUI.guiUpdateNavPanel();
        end

        function actionClearSelectedFrames( gui, ~, ~)
            gui.position.unset('img_frames');
            gui.guiUpdate();
            gui.vanellusGUI.guiUpdateNavPanel();
        end
        
        function actionAutoDetectChannelsClicked( gui, ~, ~)
            temp = gui.position.get('van_DEBUG');
            if temp
                gui.position.autoDetectChannels();
            else
                gui.position.set('van_DEBUG',true); 
                gui.position.autoDetectChannels();
                gui.position.set('van_DEBUG',false); 
            end
        end
        
        function actionUpdateThumbnailButtonClicked( gui, ~, ~)
            gui.position.updateThumbnail();
            gui.guiUpdate();
        end
        
    end
end


%             for i = 1:length(regionList)
%                 rect = regionListRect{i};
%                 rgb([rect(2)+[-1 0 1 rect(4)-2 rect(4)-1 rect(4)]],[rect(1):rect(1)+rect(3)-1], 1) = 256; % rectangle( 'Position', rect, 'EdgeColor', 'r'); 
%                 rgb([rect(2)+[-1 0 1 rect(4)-2 rect(4)-1 rect(4)]],[rect(1):rect(1)+rect(3)-1], 2) = 0;
%                 rgb([rect(2)+[-1 0 1 rect(4)-2 rect(4)-1 rect(4)]],[rect(1):rect(1)+rect(3)-1], 3) = 0;
% 
%                 rgb([rect(2):(rect(2)+rect(4)-1)],[rect(1)+[-1 0 +1 rect(3)-2 rect(3)-1 rect(3)]], 1) = 256;
%                 rgb([rect(2):(rect(2)+rect(4)-1)],[rect(1)+[-1 0 +1 rect(3)-2 rect(3)-1 rect(3)]], 2) = 0;
%                 rgb([rect(2):(rect(2)+rect(4)-1)],[rect(1)+[-1 0 +1 rect(3)-2 rect(3)-1 rect(3)]], 3) = 0;
%             end
