classdef GUIRegion < GUITogglePanel
% GUIRegion

% Copyright Daan Kiviet 2018-
% Version : 2017-03-07

    properties (Transient) % not stored
        vanellusGUI
        region

        contentPanel
        controlPanel

        uiTabgroup
        uiTabs
        uiTogglePanels
        uiTexts
        uiButtons
        uiEdits
        uiPopups
        uiCheckboxes

        picture
        currentFrameIdx
        currentTypeIdx
    end

    methods
        %% loading and gui building / updating %%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function gui = GUIRegion(vanellusGUI, region)
            if nargin < 1, error('Need VanellusGUI as argument'); end
            if nargin < 2, error('Need region as argument'); end

            gui.vanellusGUI = vanellusGUI;
            gui.region = region;
            
            gui.picture         = VPicture( gui.region );
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
            gui.uiTogglePanels(1).BackgroundColor     = gui.vanellusGUI.CONTROLPANEL_BGCOLOR;
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
            gui.uiTexts(1).String               = 'Frame';
            gui.uiTexts(1).BackgroundColor      = gui.uiTexts(1).Parent.BackgroundColor;
            gui.uiTexts(1).HorizontalAlignment  = 'left';

            gui.uiButtons                       = uicontrol(gui.uiTogglePanels(1));
            gui.uiButtons(1).Style              = 'pushbutton';
            gui.uiButtons(1).String             = 'Prev';                                  
            gui.uiButtons(1).Callback           = @gui.actionChangeFrame;
            
            gui.uiEdits                         = uicontrol(gui.uiTogglePanels(1));
            gui.uiEdits(1).Style                = 'edit';
            gui.uiEdits(1).String               = '';
            gui.uiEdits(1).KeyPressFcn          = @gui.actionChangeFrame;

            gui.uiButtons(2)                   = copyobj(gui.uiButtons(1), gui.uiTogglePanels(1));
            gui.uiButtons(2).String            = 'Next';
            gui.uiButtons(2).Callback          = @gui.actionChangeFrame;             
            
            gui.uiCheckboxes                    = uicontrol(gui.uiTogglePanels(1));
            gui.uiCheckboxes(1).Style           = 'checkbox';
            gui.uiCheckboxes(1).Value           = 1;
            gui.uiCheckboxes(1).BackgroundColor = gui.uiCheckboxes(1).Parent.BackgroundColor;
            gui.uiCheckboxes(1).Callback        = @gui.guiUpdate;                                  
            
            gui.uiTexts(2)                     = copyobj(gui.uiTexts(1), gui.uiTogglePanels(1));
            gui.uiTexts(2).BackgroundColor     = gui.uiTexts(2).Parent.BackgroundColor;
            gui.uiTexts(2).String              = 'Thumbnail only (fast)';                

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

            gui.uiEdits(11)                      = copyobj(gui.uiEdits(1), gui.uiTogglePanels(2));
            gui.uiEdits(11).KeyPressFcn          = @gui.actionChangeSelectedFrames;            
            
            gui.uiButtons(11)                   = copyobj(gui.uiButtons(1), gui.uiTogglePanels(2));
            gui.uiButtons(11).String            = 'Clear';
            gui.uiButtons(11).Callback          = @gui.actionClearSelectedFrames;            
            
            gui.uiTexts(12)                      = copyobj(gui.uiTexts(11), gui.uiTogglePanels(2));
            gui.uiTexts(12).String               = 'Rotation';                                  
            
            gui.uiPopups                        = uicontrol(gui.uiTogglePanels(2));
            gui.uiPopups(1).Style               = 'popup';
            gui.uiPopups(1).String              = VRegion.ADDITIONAL_ROTATIONS;
            gui.uiPopups(1).KeyPressFcn         = @gui.actionChangeAdditionalRotation;
            gui.uiPopups(1).Callback            = @gui.actionChangeAdditionalRotation;
            
            gui.uiButtons(12)                    = copyobj(gui.uiButtons(1), gui.uiTogglePanels(2));
            gui.uiButtons(12).String             = 'Delete Region';                                  
            gui.uiButtons(12).Callback           = @gui.actionDeleteRegion;

            gui.uiTexts(13)                      = copyobj(gui.uiTexts(11), gui.uiTogglePanels(2));
            gui.uiTexts(13).String               = 'Rect';
            gui.uiTexts(13).BackgroundColor      = gui.uiTexts(13).Parent.BackgroundColor;

            gui.uiTexts(14)                      = copyobj(gui.uiTexts(11), gui.uiTogglePanels(2));
            gui.uiTexts(14).String               = 'left';                                  
            gui.uiTexts(15)                      = copyobj(gui.uiTexts(11), gui.uiTogglePanels(2));
            gui.uiTexts(15).String               = 'top';                                  
            gui.uiTexts(16)                      = copyobj(gui.uiTexts(11), gui.uiTogglePanels(2));
            gui.uiTexts(16).String               = 'width';                                  
            gui.uiTexts(17)                      = copyobj(gui.uiTexts(11), gui.uiTogglePanels(2));
            gui.uiTexts(17).String               = 'height';                                  
            
            gui.uiEdits(12)                      = copyobj(gui.uiEdits(1), gui.uiTogglePanels(2));
            gui.uiEdits(12).String              = '';
            gui.uiEdits(12).KeyPressFcn          = @gui.actionChangeRect;
            
            gui.uiEdits(13)                      = copyobj(gui.uiEdits(12), gui.uiTogglePanels(2));
            gui.uiEdits(13).KeyPressFcn          = @gui.actionChangeRect;                                  
            
            gui.uiEdits(14)                      = copyobj(gui.uiEdits(12), gui.uiTogglePanels(2));
            gui.uiEdits(14).KeyPressFcn          = @gui.actionChangeRect;                                  

            gui.uiEdits(15)                      = copyobj(gui.uiEdits(12), gui.uiTogglePanels(2));
            gui.uiEdits(15).KeyPressFcn          = @gui.actionChangeRect;                                  
            
            %% Analysis Panel
            gui.uiTexts(21)                     = copyobj(gui.uiTexts(1), gui.uiTogglePanels(3));
            gui.uiTexts(21).String              = 'Masks set : ';
            gui.uiTexts(21).BackgroundColor     = gui.uiTexts(21).Parent.BackgroundColor;

            gui.uiTexts(22)                      = copyobj(gui.uiTexts(21), gui.uiTogglePanels(3));
            gui.uiTexts(22).String               = 'Frames segmented : ';

            gui.uiTexts(23)                      = copyobj(gui.uiTexts(21), gui.uiTogglePanels(3));
            gui.uiTexts(23).String               = 'Frames tracked : ';

            gui.uiButtons(21)                    = copyobj(gui.uiButtons(1), gui.uiTogglePanels(3));
            gui.uiButtons(21).String             = 'Calc Regionmask';                                  
            gui.uiButtons(21).Callback           = @gui.actionCalcRegionmask;

            gui.uiButtons(22)                    = copyobj(gui.uiButtons(1), gui.uiTogglePanels(3));
            gui.uiButtons(22).String             = 'Clear Regionmask';                                  
            gui.uiButtons(22).Callback           = @gui.actionClearRegionmask;
            
            gui.uiButtons(23)                    = copyobj(gui.uiButtons(1), gui.uiTogglePanels(3));
            gui.uiButtons(23).String             = 'Calc Masks';
            gui.uiButtons(23).Callback           = @gui.actionCalcMasks;
            
            gui.uiButtons(24)                    = copyobj(gui.uiButtons(1), gui.uiTogglePanels(3));
            gui.uiButtons(24).String             = 'Clear Masks';                                  
            gui.uiButtons(24).Callback           = @gui.actionClearMasks;

            gui.uiButtons(25)                    = copyobj(gui.uiButtons(1), gui.uiTogglePanels(3));
            gui.uiButtons(25).String             = 'Segment All';                                  
            gui.uiButtons(25).Callback           = @gui.actionSegmentFrames;

            gui.uiButtons(26)                    = copyobj(gui.uiButtons(1), gui.uiTogglePanels(3));
            gui.uiButtons(26).String             = 'Clear Segmentations';                                  
            gui.uiButtons(26).Callback           = @gui.actionClearSegmentation;

            gui.uiButtons(27)                    = copyobj(gui.uiButtons(1), gui.uiTogglePanels(3));
            gui.uiButtons(27).String             = 'Track All';                                  
            gui.uiButtons(27).Callback           = @gui.actionTrackFrames;

            gui.uiButtons(28)                    = copyobj(gui.uiButtons(1), gui.uiTogglePanels(3));
            gui.uiButtons(28).String             = 'Clear Trackings';                                  
            gui.uiButtons(28).Callback           = @gui.actionClearTracking;

            %% Cache Panel
            gui.uiTexts(31)                      = copyobj(gui.uiTexts(1), gui.uiTogglePanels(4));
            gui.uiTexts(31).BackgroundColor      = gui.uiTexts(31).Parent.BackgroundColor;
            gui.uiTexts(31).String               = 'XX cached images (XX MB)';                                  

            gui.uiEdits(31)                      = copyobj(gui.uiEdits(1), gui.uiTogglePanels(4));
            gui.uiEdits(31).Enable               = 'inactive';
            gui.uiEdits(31).BackgroundColor      = gui.uiEdits(31).Parent.BackgroundColor;
            gui.uiEdits(31).String               = vect2colon( gui.region.cache.getCachedFrames() );

            gui.uiButtons(31)                   = copyobj(gui.uiButtons(1), gui.uiTogglePanels(4));
            gui.uiButtons(31).String            = 'Cache';
            gui.uiButtons(31).Callback          = @gui.actionCacheImages;                                  

            gui.uiEdits(32)                      = copyobj(gui.uiEdits(1), gui.uiTogglePanels(4));
            gui.uiEdits(32).KeyPressFcn          = @gui.actionCacheImages;            
            gui.uiEdits(32).String               = vect2colon( gui.region.frames' );
            
            gui.uiButtons(32)                    = copyobj(gui.uiButtons(31), gui.uiTogglePanels(4));
            gui.uiButtons(32).String             = 'Clear';
            gui.uiButtons(32).Callback           = @gui.actionCacheImages;                                  
            
            gui.uiButtons(33)                   = copyobj(gui.uiButtons(1), gui.uiTogglePanels(4));
            gui.uiButtons(33).String            = 'Delete Cache';
            gui.uiButtons(33).Callback          = @gui.actionCacheImages;            
            
            % SET TOOLTIPS
            gui.uiEdits(1).TooltipString        = 'keyboard shortcut = g';
            gui.uiButtons(1).TooltipString      = 'keyboard shortcut = < or ,';            
            gui.uiButtons(2).TooltipString      = 'keyboard shortcut = > or , or SPACE';            
            
            % SET CONTENTPANEL
            gui.contentPanel = ScrollPanel(gui.vanellusGUI.fig);
        end

        function guiPositionUpdate(gui, ~, ~)
            % SET CONTROLPANEL BUTTONS
            % Position coordinates: [left bottom width height]
            
            gui.uiTogglePanels(1).Position  = [ 10 200 280 100]; % Display
            gui.uiTexts(1).Position         = [ 58  70  60  15];
            gui.uiButtons(1).Position       = [ 10  50  40  20];
            gui.uiEdits(1).Position         = [ 55  50  40  20];
            gui.uiButtons(2).Position       = [100  50  40  20];
            gui.uiCheckboxes(1).Position    = [170  50  20  20];
            gui.uiTexts(2).Position         = [190  40  80  30];
            gui.uiButtons(3).Position       = [170  10 100  20];
            
            gui.uiTogglePanels(2).Position  = [ 10 200 280 130]; % Settings
            gui.uiTexts(11).Position        = [ 10  88  75  20];
            gui.uiEdits(11).Position        = [ 85  90 145  20];
            gui.uiButtons(11).Position      = [230  90  40  20];
            gui.uiTexts(12).Position        = [ 10  55  50  20];
            gui.uiPopups(1).Position        = [ 55  60 100  20];
            gui.uiButtons(12).Position      = [165  60  80  20];
            gui.uiTexts(14).Position        = [ 50  25  40  20];
            gui.uiTexts(15).Position        = [100  25  40  20];
            gui.uiTexts(16).Position        = [150  25  40  20];
            gui.uiTexts(17).Position        = [200  25  40  20];
            gui.uiTexts(13).Position        = [ 10   8  30  20];
            gui.uiEdits(12).Position        = [ 50  10  40  20];
            gui.uiEdits(13).Position        = [100  10  40  20];
            gui.uiEdits(14).Position        = [150  10  40  20];
            gui.uiEdits(15).Position        = [200  10  40  20];
            
            gui.uiTogglePanels(3).Position  = [ 10 200 280 210]; % Analysis
            gui.uiTexts(21).Position        = [ 10 165 260  20];
            gui.uiTexts(22).Position        = [ 10 145 260  20];
            gui.uiTexts(23).Position        = [ 10 125 260  20];
            gui.uiButtons(21).Position      = [ 10 100 100  20];
            gui.uiButtons(22).Position      = [120 100 120  20];
            gui.uiButtons(23).Position      = [ 10  70 100  20];
            gui.uiButtons(24).Position      = [120  70 120  20];
            gui.uiButtons(25).Position      = [ 10  40 100  20];
            gui.uiButtons(26).Position      = [120  40 120  20];
            gui.uiButtons(27).Position      = [ 10  10 100  20];
            gui.uiButtons(28).Position      = [120  10 120  20];

            gui.uiTogglePanels(4).Position  = [ 10 200 280  80]; % Caching
            gui.uiTexts(31).Position        = [ 10  38 160  20];
            gui.uiEdits(31).Position        = [170  40 100  20];
            gui.uiButtons(31).Position      = [ 10  10  45  20];
            gui.uiEdits(32).Position        = [ 60  10 100  20];
            gui.uiButtons(32).Position      = [160  10  35  20];
            gui.uiButtons(33).Position      = [200  10  70  20];            
            
            % INITIALIZE TOGGLE PANELS
            gui.guiInitializeTogglePanels();
        end

        function guiUpdate(gui, ~, ~)
            % UPDATE CONTROLPANEL
            gui.uiEdits(12).String   = num2str( gui.region.rect(1) );
            gui.uiEdits(13).String   = num2str( gui.region.rect(2) );
            gui.uiEdits(14).String   = num2str( gui.region.rect(3) );
            gui.uiEdits(15).String   = num2str( gui.region.rect(4) );

            gui.uiPopups(1).Value   = gui.region.rotationAdditional90Idx;

            gui.uiTexts(21).String  = ['Masks set               : ' num2str(gui.region.masks.getNrData()) ' / ' num2str(numel(gui.region.masks.frames))];
            gui.uiTexts(22).String   = ['Frames segmented : ' num2str(gui.region.segmentations.getNrData()) ' / ' num2str(numel(gui.region.segmentations.frames))];
            trackedFrames           = gui.region.trackings.getNrData() + 1;
            if trackedFrames == 1 && numel(gui.region.trackings.frames) > 1
                trackedFrames = 0;
            end
            gui.uiTexts(23).String   = ['Frames tracked       : ' num2str( trackedFrames ) ' / ' num2str( numel(gui.region.trackings.frames) )];
            
            % SET SELECTED FRAMES
            gui.uiEdits(11).String = vect2colon( gui.region.frames' );
            % coloring dependend on whether img_frames is set locally
            if isempty( gui.region.getLocal('img_frames') ) % not set here, but inherited from parent
                gui.uiEdits(11).ForegroundColor = [0.4 0.4 0.4];
            else
                gui.uiEdits(11).ForegroundColor = [0 0 0];
            end

            % SET CACHE TEXT
            gui.uiTexts(31).String      = [ num2str(gui.region.cache.getNrCachedImages()) ...
                                            ' cached images (' ...
                                            num2str(round(gui.region.cache.getCacheFileSize())) ...
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
            
            % UPDATE CONTENTPANEL (=SCROLLPANEL)
            rgb = gui.getRegionImage();
            gui.contentPanel.showImage(rgb, gui.vanellusGUI.currentMagnification);            
        end
        
        %% Controller %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function rgb = getRegionImage(gui)
            
            % EITHER GET THUMBNAIL OR FRESH IMAGE
            if gui.uiCheckboxes(1).Value
                % get thumbnail
                thumbs = gui.region.getThumbnail();
                rgb = repmat(thumbs, [1 1 3]);
            else
                % get fresh image
                gui.picture.set('pic_imageFrame', gui.picture.parent.frames(gui.currentFrameIdx));
                rgb = gui.picture.getRGB();
            end
            
            % apply additional region rotation (only for visualization)
            rotationAdditional90Idx = gui.region.rotationAdditional90Idx;
            if rotationAdditional90Idx ~= 4
                rgb_old = rgb; clear rgb;
                for i=1:3
                    rgb(:,:,i) = rot90( rgb_old(:,:,i), rotationAdditional90Idx);
                end
            end
        end
        
        %% Image or Key Click %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function actionKeyPressed( gui, ~, eventdata)
            switch upper(eventdata.Key)
                case {'LEFTARROW','COMMA'}
                    gui.actionChangeFrame(gui.uiButtons(1));
                case {'RIGHTARROW','PERIOD','SPACE'}
                    gui.actionChangeFrame(gui.uiButtons(2));
                case {'S'}
                    disp(['Clicked key: ' eventdata.Key ' -> saving']);
                    gui.actionSaveRegion();
                case {'G'}
                    disp(['Clicked key: ' eventdata.Key ' -> Goto frame']);
                    uicontrol( gui.uiEdits(1) );
                    
            end
        end        
        
        %% Actions %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function actionChangeFrame(gui, hObject, eventdata)
            drawnow limitrate nocallbacks; % was: pause(0.1);
            if hObject == gui.uiEdits(1)
                if ~isequal( eventdata.Key, 'return'), return; end
                drawnow; % makes sure that uiEdits(5) is up to date
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
        
        function actionSaveRegion( gui, ~, ~)
            gui.region.save();
            gui.vanellusGUI.guiUpdateNavPanel();
        end        
        
        function actionChangeRect( gui, ~, eventdata)
            drawnow limitrate nocallbacks; % was: pause(0.1);
            if ~isequal( eventdata.Key, 'return')
                return;
            end
            drawnow; % makes sure that uiEdits(1) is up to date
            rect = str2double({ get(gui.uiEdits(12), 'String'), get(gui.uiEdits(13), 'String'), get(gui.uiEdits(14), 'String'), get(gui.uiEdits(15), 'String') });
            gui.region.changeRect(rect);

            % delete old thumbnails
            gui.region.deleteThumbnails();

            gui.guiUpdate();
            gui.vanellusGUI.guiUpdateNavPanel();
        end        

        function actionChangeAdditionalRotation( gui, hObject, ~)
            pause(0.1);
            idx = get(hObject,'Value');
            gui.region.set('reg_rotation90', VRegion.ADDITIONAL_ROTATIONS{idx}); % gui.region.changeAdditionalRotation(VRegion.ADDITIONAL_ROTATIONS{idx});
            gui.guiUpdate();
            gui.vanellusGUI.guiUpdateNavPanel();
        end

        function actionCalcRegionmask( gui, ~, ~)
            gui.region.regionmask.calcAndSetRegionmask();
            gui.guiUpdate();
            gui.vanellusGUI.guiUpdateNavPanel();
        end        
        
        function actionCalcMasks( gui, ~, ~)
            gui.region.masks.calcMasks();
            gui.guiUpdate();
            gui.vanellusGUI.guiUpdateNavPanel();
        end
        
        function actionSegmentFrames( gui, ~, ~)
            gui.region.segmentations.segmentFrames();
            gui.guiUpdate();
            gui.vanellusGUI.guiUpdateNavPanel();
        end        
        
        function actionTrackFrames( gui, ~, ~)
            gui.region.trackings.trackFrames();
            gui.guiUpdate();
            gui.vanellusGUI.guiUpdateNavPanel();
        end        
        
        function actionClearRegionmask( gui, ~, ~)
            gui.region.regionmask = [];
            gui.region.update();
            gui.guiUpdate();
            gui.vanellusGUI.guiUpdateNavPanel();
        end
        
        function actionClearMasks( gui, ~, ~)
            gui.region.masks = [];
            gui.region.update();
            gui.guiUpdate();
            gui.vanellusGUI.guiUpdateNavPanel();
        end
        
        function actionClearSegmentation( gui, ~, ~)
            gui.region.segmentations = [];
            gui.region.update();
            gui.guiUpdate();
            gui.vanellusGUI.guiUpdateNavPanel();
        end
        
        function actionClearTracking( gui, ~, ~)
            gui.region.trackings = [];
            gui.region.update();
            gui.guiUpdate();
            gui.vanellusGUI.guiUpdateNavPanel();
        end
        
        function actionDeleteRegion( gui, ~, ~)
            choice = questdlg('Are you sure that you want to delete this region?', 'Exit?', 'Yes', 'No', 'No');
            % Handle response
            switch choice
                case 'Yes'
                    disp(['Deleting region ' VTools.getParentfoldername(gui.region.filename) ]);
                    pos = gui.region.position;
                    gui.region.deleteRegion('yes');
                    gui.vanellusGUI.changePanels( GUIPosition(gui.vanellusGUI, pos) );
                case 'No'
                    disp(['Deletion canceled.']);
            end
        end        
        
        function actionChangeSelectedFrames( gui, ~, eventdata)
            drawnow limitrate nocallbacks; % was: pause(0.1);
            if ~isequal( eventdata.Key, 'return'), return; end
            drawnow; % makes sure that uiEdits(6) is up to date
            action = ['gui.region.set(''img_frames'', ' '[' gui.uiEdits(11).String ']' ');'];
            eval(action);
            gui.guiUpdate();
            gui.vanellusGUI.guiUpdateNavPanel();
        end

        function actionClearSelectedFrames( gui, ~, ~)
            gui.region.unset('img_frames');
            gui.guiUpdate();
            gui.vanellusGUI.guiUpdateNavPanel();
        end
        
        function actionCacheImages( gui, hObject, eventdata)
            
            if hObject == gui.uiButtons(31) % 'Cache' button
                framesAction    = ['frames = [' gui.uiEdits(32).String '];'];
                eval(framesAction);
                types           = ''; % all
                gui.region.cacheImages( frames, types );
                
            elseif hObject == gui.uiEdits(32) % 'Cache' editbox
                if ~isequal( eventdata.Key, 'return'), return; end
                framesAction    = ['frames = [' gui.uiEdits(32).String '];'];
                eval(framesAction);
                types           = ''; % all
                gui.region.cacheImages( frames, types );
                
            elseif hObject == gui.uiButtons(32) % 'Clear' button (to clear editbox)
                gui.uiEdits(32).String               = vect2colon( gui.region.frames' );

            elseif hObject == gui.uiButtons(33) % 'Delete Cache' button
                gui.region.cache.clearCacheMatFile();
            end
        
            gui.uiEdits(31).String               = vect2colon( gui.region.cache.getCachedFrames() );
            gui.guiUpdate();
        end
        
        function actionUpdateThumbnailButtonClicked( gui, ~, ~)
            gui.region.updateThumbnail();
            gui.guiUpdate();
        end
    end
end

