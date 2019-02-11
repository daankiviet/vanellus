classdef GUIMasks < GUITogglePanel
% GUIMasks

% Copyright Daan Kiviet 2018-
% Version : 2017-03-07

    properties (Constant = true)
        VIS_BGCOLOR             = [0.0 0.0 0.0];
        VIS_EDGECOLOR           = [1.0 1.0 1.0];
        VIS_MASKCOLOR           = [0.5 0.5 1.0];

        BUT_SELECTEDCOLOR       = [0.7 0.7 0.7];
    end
    
    properties (Transient) % not stored
        vanellusGUI
        masks

        contentPanel
        controlPanel

        uiTogglePanels
        uiTexts
        uiButtons
        uiEdits
        uiTables
        
        currentFrameIdx
        prevClickCoor
    end

    properties (Dependent) % calculated on the fly
        frames
    end    
   
    methods
        %% loading and gui building / updating %%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function gui = GUIMasks(vanellusGUI, masks)
            if nargin < 1, error('Need VanellusGUI as argument'); end
            if nargin < 2, error('Need masks as argument'); end

            gui.vanellusGUI     = vanellusGUI;
            gui.masks           = masks;
            gui.currentFrameIdx = 1;
            
            gui.guiBuild();
        end
 
        function guiBuild(gui)
            % SET CONTROLPANEL
            gui.controlPanel                        = uipanel(gui.vanellusGUI.fig);
            gui.controlPanel.BackgroundColor        = gui.vanellusGUI.CONTROLPANEL_BGCOLOR;
            gui.controlPanel.BorderType             = 'none';
            gui.controlPanel.Units                  = 'pixels';
            
            gui.uiTogglePanels                      = uipanel(gui.controlPanel);
            gui.uiTogglePanels(1).BackgroundColor   = gui.vanellusGUI.DISPLAYPANEL_BGCOLOR;
            gui.uiTogglePanels(1).Title             = 'Display';
            gui.uiTogglePanels(1).BorderType        = 'beveledin';
            gui.uiTogglePanels(1).BorderWidth       = 2;
            gui.uiTogglePanels(1).Units             = 'pixels';
            
            gui.uiTogglePanels(2)                   = copyobj(gui.uiTogglePanels(1), gui.controlPanel);
            gui.uiTogglePanels(2).BackgroundColor   = gui.vanellusGUI.EDITPANEL_BGCOLOR;
            gui.uiTogglePanels(2).Title             = 'Edit';
            
            gui.uiTogglePanels(3)                   = copyobj(gui.uiTogglePanels(1), gui.controlPanel);
            gui.uiTogglePanels(3).BackgroundColor   = gui.vanellusGUI.ANALYSISPANEL_BGCOLOR;
            gui.uiTogglePanels(3).Title             = 'Analysis';
            
            gui.uiTogglePanels(4)                   = copyobj(gui.uiTogglePanels(1), gui.controlPanel);
            gui.uiTogglePanels(4).Title             = 'Click behavior';

            gui.uiTogglePanels(5)                   = copyobj(gui.uiTogglePanels(1), gui.controlPanel);
            gui.uiTogglePanels(5).BackgroundColor   = gui.vanellusGUI.SETTINGSPANEL_BGCOLOR;
            gui.uiTogglePanels(5).Title             = 'Relevant settings';
            
            %% Display Panel
            gui.uiTexts                             = uicontrol(gui.uiTogglePanels(1));
            gui.uiTexts(1).Style                    = 'text';
            gui.uiTexts(1).String                   = 'Frame';
            gui.uiTexts(1).BackgroundColor          = gui.controlPanel.BackgroundColor;
            gui.uiTexts(1).HorizontalAlignment      = 'left';

            gui.uiButtons                           = uicontrol(gui.uiTogglePanels(1));
            gui.uiButtons(1).Style                  = 'pushbutton';
            gui.uiButtons(1).String                 = 'Prev';
            gui.uiButtons(1).Callback               = @gui.actionChangeFrame;
            
            gui.uiEdits                             = uicontrol(gui.uiTogglePanels(1));
            gui.uiEdits(1).Style                    = 'edit';
            gui.uiEdits(1).String                   = '';
            gui.uiEdits(1).KeyPressFcn              = @gui.actionChangeFrame;
                                    
            gui.uiButtons(2)                        = copyobj(gui.uiButtons(1), gui.uiTogglePanels(1));
            gui.uiButtons(2).String                 = 'Next';
            gui.uiButtons(2).Callback               = @gui.actionChangeFrame;                                  

            gui.uiButtons(4)                        = uicontrol(gui.uiTogglePanels(1));
            gui.uiButtons(4).Style                  = 'togglebutton';
            gui.uiButtons(4).Min                    = 0;
            gui.uiButtons(4).Max                    = 1;
            gui.uiButtons(4).Value                  = 0;
            gui.uiButtons(4).String                 = 'Edge';
            gui.uiButtons(4).Callback               = @gui.guiUpdate;

            gui.uiButtons(5)                        = copyobj(gui.uiButtons(4), gui.uiTogglePanels(1));
            gui.uiButtons(5).String                 = 'Mask';
            gui.uiButtons(5).Value                  = 1;
            gui.uiButtons(5).Callback               = @gui.guiUpdate;

            gui.uiButtons(6)                        = copyobj(gui.uiButtons(4), gui.uiTogglePanels(1));
            gui.uiButtons(6).String                 = 'Phase';
            gui.uiButtons(6).Value                  = 1;
            gui.uiButtons(6).Callback               = @gui.guiUpdate;
            
            %% Edit Panel
            gui.uiButtons(11)                       = copyobj(gui.uiButtons(1), gui.uiTogglePanels(2));
            gui.uiButtons(11).String                = 'Clear';
            gui.uiButtons(11).Callback              = @gui.actionClear;                                  

            gui.uiButtons(12)                       = copyobj(gui.uiButtons(1), gui.uiTogglePanels(2));
            gui.uiButtons(12).String                = 'Fill holes';
            gui.uiButtons(12).Callback              = @gui.actionFillHolesButtonPressed;                                  

            gui.uiButtons(13)                       = copyobj(gui.uiButtons(1), gui.uiTogglePanels(2));
            gui.uiButtons(13).String                = 'Add edges';
            gui.uiButtons(13).Callback              = @gui.actionAddEdges;                                  
            
            gui.uiButtons(14)                       = copyobj(gui.uiButtons(1), gui.uiTogglePanels(2));
            gui.uiButtons(14).String                = 'Undo';
            gui.uiButtons(14).Callback              = @gui.actionUndoButtonPressed;                                  
            
            %% Analysis Panel
            gui.uiButtons(21)                       = copyobj(gui.uiButtons(1), gui.uiTogglePanels(3));
            gui.uiButtons(21).String                = 'Recalculate';
            gui.uiButtons(21).Callback              = @gui.actionRecalculateButtonPressed;                                  

            gui.uiButtons(22)                       = copyobj(gui.uiButtons(1), gui.uiTogglePanels(3));
            gui.uiButtons(22).String                = 'Copy from Frame';
            gui.uiButtons(22).Callback              = @gui.actionCopyMaskButtonPressed;                                  
            
            gui.uiEdits(21)                         = copyobj(gui.uiEdits(1), gui.uiTogglePanels(3));
            
            %% Click Behavior Panel
            gui.uiTexts(31)                         = copyobj(gui.uiTexts(1), gui.uiTogglePanels(4));
            gui.uiTexts(31).BackgroundColor         = gui.uiTexts(31).Parent.BackgroundColor;
            gui.uiTexts(31).String                  = 'Left click   : Add';

            gui.uiTexts(32)                         = copyobj(gui.uiTexts(31), gui.uiTogglePanels(4));
            gui.uiTexts(32).String                  = 'Right click : Remove';
            
            gui.uiButtons(31)                       = copyobj(gui.uiButtons(4), gui.uiTogglePanels(4));
            gui.uiButtons(31).String                = 'P';
            gui.uiButtons(31).TooltipString         = 'Pixel';
            gui.uiButtons(31).Value                 = 0;
            gui.uiButtons(31).Callback              = @gui.actionChangeClickBehavior;
            
            gui.uiButtons(32)                       = copyobj(gui.uiButtons(31), gui.uiTogglePanels(4));
            gui.uiButtons(32).String                = 'L';
            gui.uiButtons(32).TooltipString         = 'Line';
            gui.uiButtons(32).Callback              = @gui.actionChangeClickBehavior;
            
            gui.uiButtons(33)                       = copyobj(gui.uiButtons(31), gui.uiTogglePanels(4));
            gui.uiButtons(33).String                = 'A';
            gui.uiButtons(33).TooltipString         = 'Area';
            gui.uiButtons(33).Callback              = @gui.actionChangeClickBehavior;

            gui.uiButtons(34)                       = copyobj(gui.uiButtons(31), gui.uiTogglePanels(4));
            gui.uiButtons(34).String                = 'E';
            gui.uiButtons(34).TooltipString         = 'Edgefill';
            gui.uiButtons(34).Callback              = @gui.actionChangeClickBehavior;
            gui.uiButtons(34).Value                 = 1;

            gui.uiButtons(35)                       = copyobj(gui.uiButtons(31), gui.uiTogglePanels(4));
            gui.uiButtons(35).String                = 'C';
            gui.uiButtons(35).TooltipString         = 'Connected area';
            gui.uiButtons(35).Callback              = @gui.actionChangeClickBehavior;
            
            %% Relevant Settings Panel
            gui.uiTables                            = uitable(gui.uiTogglePanels(5));
            gui.uiTables(1).ColumnName              = [];
            gui.uiTables(1).ColumnWidth             = {130 125};
            gui.uiTables(1).ColumnEditable          = [false true];
            gui.uiTables(1).Enable                  = 'on';
            gui.uiTables(1).RowStriping             = 'off';
            gui.uiTables(1).CellEditCallback        = @gui.actionEditedTable;
            
            %% SET TOOLTIPS
            gui.uiEdits(1).TooltipString            = 'keyboard shortcut = g';
            gui.uiButtons(1).TooltipString          = 'keyboard shortcut = < or ,';
            gui.uiButtons(2).TooltipString          = 'keyboard shortcut = > or , or SPACE';
            gui.uiButtons(4).TooltipString          = 'keyboard shortcut = 2';
            gui.uiButtons(5).TooltipString          = 'keyboard shortcut = 3';
            gui.uiButtons(6).TooltipString          = 'keyboard shortcut = 4';            
            gui.uiButtons(12).TooltipString         = 'keyboard shortcut = i';
            gui.uiButtons(21).TooltipString         = 'keyboard shortcut = SHIFT + R';
            gui.uiButtons(31).TooltipString         = 'add/remove a pixel (keyboard shortcut = p)';
            gui.uiButtons(32).TooltipString         = 'add/remove a line (keyboard shortcut = l)';
            gui.uiButtons(33).TooltipString         = 'add/remove an area (keyboard shortcut = a)';
            gui.uiButtons(34).TooltipString         = 'add/remove an edge bound region (keyboard shortcut = e)';
            gui.uiButtons(35).TooltipString         = 'add/remove a connected area (keyboard shortcut = c)';

            % SET CONTENTPANEL
            gui.contentPanel = ScrollPanel(gui.vanellusGUI.fig);
        end

        function guiPositionUpdate(gui, ~, ~)
            % SET CONTROLPANEL BUTTONS
            % Position coordinates: [left bottom width height]
            
            gui.uiTogglePanels(1).Position  = [ 10 200 280 120]; % Display
            gui.uiTexts(1).Position         = [ 58  90  60  15];
            gui.uiButtons(1).Position       = [ 10  70  40  20];
            gui.uiEdits(1).Position         = [ 55  70  40  20];
            gui.uiButtons(2).Position       = [100  70  40  20];
            gui.uiButtons(4).Position       = [180  85  80  20];
            gui.uiButtons(4).Position       = [180  60  80  20];
            gui.uiButtons(5).Position       = [180  35  80  20];
            gui.uiButtons(6).Position       = [180  10  80  20];            

            gui.uiTogglePanels(2).Position  = [ 10 200 280  50]; % Edit
            gui.uiButtons(11).Position      = [ 10  10  60  20];
            gui.uiButtons(12).Position      = [ 80  10  60  20];
            gui.uiButtons(13).Position      = [150  10  60  20];
            gui.uiButtons(14).Position      = [220  10  50  20];

            gui.uiTogglePanels(3).Position  = [ 10 200 280  50]; % Analysis
            gui.uiButtons(21).Position      = [ 10  10  80  20];
            gui.uiButtons(22).Position      = [100  10  90  20];
            gui.uiEdits(21).Position        = [190  10  40  20];
            
            gui.uiTogglePanels(4).Position  = [ 10 200 280 65]; % Click Behavior
            gui.uiTexts(31).Position        = [ 10  28 100  15];
            gui.uiTexts(32).Position        = [ 10   8 100  15];
            gui.uiButtons(31).Position      = [160  15  20  20];
            gui.uiButtons(32).Position      = [182  15  20  20];
            gui.uiButtons(33).Position      = [204  15  20  20];
            gui.uiButtons(34).Position      = [226  15  20  20];
            gui.uiButtons(35).Position      = [248  15  20  20];
            
            gui.uiTogglePanels(5).Position  = [ 10 200 280 280]; % Relevant Settings Panel
            gui.uiTables(1).Position        = [ 10  10 260 250];
            
            % INITIALIZE TOGGLE PANELS
            gui.guiInitializeTogglePanels();            
        end

        function guiUpdate(gui, ~, ~)
            % indicate that GUI is working
            gui.vanellusGUI.fig.Pointer = 'watch';
            drawnow;

            % UPDATE CONTROLPANEL
            if isempty(gui.masks.frames)
                gui.uiEdits(1).String = '-';
                gui.uiEdits(21).String = '-';
            else
                gui.uiEdits(1).String = gui.masks.frames(gui.currentFrameIdx);
                gui.uiEdits(21).String = gui.masks.frames( max(1, gui.currentFrameIdx - 1) );
            end                

            % update settings Table
            [~, ~, combined]            = gui.getSettingsData();
            gui.uiTables(1).RowName     = {};  % settingsList
            gui.uiTables(1).Data        = combined; % data;
            if gui.uiTables(1).Extent(3) < gui.uiTables(1).Position(3), gui.uiTables(1).Position(3) = gui.uiTables(1).Extent(3); end            
            
            % DRAW CLICK BEHAVIOR BUTTONS
            for i = 31:35
                if gui.uiButtons(i).Value
                    gui.uiButtons(i).BackgroundColor   = gui.BUT_SELECTEDCOLOR;
                    gui.uiButtons(i).FontWeight        = 'bold';
                else
                    gui.uiButtons(i).BackgroundColor   = gui.uiButtons(i).Parent.BackgroundColor;
                    gui.uiButtons(i).FontWeight        = 'normal';
                end
            end
            
            % COLOR RECALCULATE BUTTON, IN CASE SEGMENTATION NEEDS UPDATING
            frame1      = gui.masks.frames(gui.currentFrameIdx);
            if gui.masks.doesDataNeedUpdating( frame1 )
                gui.uiButtons(21).BackgroundColor     = [1 0 0];
            else
                gui.uiButtons(21).BackgroundColor     = gui.uiButtons(1).BackgroundColor;
            end
            
            % UPDATE CONTENTPANEL (=SCROLLPANEL)
            rgb = gui.getMaskImage();
            hIm = gui.contentPanel.showImage(rgb, gui.vanellusGUI.currentMagnification);
            set(hIm, 'ButtonDownFcn', @gui.actionImageClicked);

%             uipan = uipanel(gui.vanellusGUI.fig);
%             ax = axes('Parent',uipan);
%             plot(ax, [1:5], [5:-1:1]);
%             xlabel(ax,'test');
%             gui.contentPanel.showPlot2( uipan, gui.vanellusGUI.currentMagnification );
            
            % UPDATE NAVPANEL
            gui.vanellusGUI.guiUpdateNavPanel();
            
            % indicate that GUI is finished
            gui.vanellusGUI.fig.Pointer = 'arrow';
        end
        
        function save(gui, ~, ~)
            if gui.masks.save()
                % set view to XX
%                 gui.uiButtons(4).Value              = 0;
%                 gui.uiButtons(5).Value              = 1;
%                 gui.uiButtons(6).Value              = 0;
            end
            
            gui.guiUpdate();
        end        
        
        
        %% Controller %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function rgb = getMaskImage(gui)
            segSize     = gui.masks.region.regionSize;
            frame1      = gui.masks.frames(gui.currentFrameIdx);

            % Set background color
            rgb = repmat(reshape(GUIMasks.VIS_BGCOLOR, [1 1 3]), segSize);
            
            % add mask
            if gui.uiButtons(5).Value
                mask1       = gui.masks.getData( frame1 );
                mask1RGB    = repmat(reshape(GUIMasks.VIS_MASKCOLOR, [1 1 3]), segSize); %                 tmp     = ones([segSize 3]) .* repmat(reshape(GUIMasks.COLOR_MASK, [1 1 3]), segSize);
                idx         = repmat( mask1, [1 1 3]);
                rgb( idx )  = mask1RGB( idx );
            end

            % add edge
            if gui.uiButtons(4).Value
                seg1Edge    = gui.masks.getMaskEdge( frame1 );
                seg1EdgeRGB = repmat(reshape(GUIMasks.VIS_EDGECOLOR, [1 1 3]), segSize);
                idx         = repmat( seg1Edge, [1 1 3]);
                rgb( idx )  = seg1EdgeRGB( idx );
            end
            
            % add phase
            if gui.uiButtons(6).Value
                seg1Image   = gui.masks.getMaskImage( frame1 );
                rgb = VTools.addPhaseOverlayToRGB(rgb, seg1Image);
            end
            
            % apply additional region rotation (only for visualization)
            rotationAdditional90Idx = gui.masks.region.rotationAdditional90Idx;
            if rotationAdditional90Idx ~= 4
                rgb_old = rgb; clear rgb;
                for i=1:3
                    rgb(:,:,i) = rot90( rgb_old(:,:,i), rotationAdditional90Idx);
                end
            end            
        end
        
        function [settingsList, data, combined] = getSettingsData(gui) 
            settings        = gui.masks.getCurrentDefaultSettings();
            settingsList    = settings(:,1);
            data            = cell( numel(settingsList), 1);
            combined        = cell( numel(settingsList), 2);
            for i = 1:numel(settingsList)
                text = VTools.convertValueToChar( settings{i,3} );
                data{i,1} = VTools.getHTMLColoredText( text, [0 0 0]);
                text2 = VTools.convertValueToChar( settings{i,1} );
                combined{i,1} = VTools.getHTMLColoredText( text2, [  0   0   0], [0.8 0.8 0.8]);
                combined{i,2} = text; %VTools.getHTMLColoredText( text , [0.2 0.2 0.2]);
            end
        end

        
        %% Image or Key Click %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function actionKeyPressed(gui, ~, eventdata)
            switch upper(eventdata.Key)
                case {'LEFTARROW','COMMA'}
                    gui.actionChangeFrame(gui.uiButtons(1));
                case {'RIGHTARROW','PERIOD','SPACE'}
                    gui.actionChangeFrame(gui.uiButtons(2));
                    
                case {'P'}
                    disp(['Clicked key: ' eventdata.Key ' -> Pixel']);
                    gui.actionChangeClickBehavior( gui.uiButtons(31) );
                case {'L'}
                    disp(['Clicked key: ' eventdata.Key ' -> Line']);
                    gui.actionChangeClickBehavior( gui.uiButtons(32) );
                case {'A'}
                    disp(['Clicked key: ' eventdata.Key ' -> Area']);
                    gui.actionChangeClickBehavior( gui.uiButtons(33) );
                case {'E'}
                    disp(['Clicked key: ' eventdata.Key ' -> Edgefill']);
                    gui.actionChangeClickBehavior( gui.uiButtons(34) );
                case {'C'}
                    disp(['Clicked key: ' eventdata.Key ' -> Connected area']);
                    gui.actionChangeClickBehavior( gui.uiButtons(35) );
                    
                case {'I'}
                    disp(['Clicked key: ' eventdata.Key ' -> filling holes (in cells)']);
                    gui.actionFillHolesButtonPressed();
                case {'R'}
                    if strcmp(eventdata.Modifier, 'shift')
                        disp(['Clicked key: shift + ' eventdata.Key ' -> recalculating']);
                        gui.actionRecalculateButtonPressed();
                    end
                case {'U'}
                    disp(['Clicked key: ' eventdata.Key ' -> Undo']);
                    gui.masks.undo( gui.masks.frames(gui.currentFrameIdx) );
                    gui.guiUpdate();
                case {'S'}
                    disp(['Clicked key: ' eventdata.Key ' -> saving']);
                    gui.actionSaveRegion();
                    
                case {'2'}
                    disp(['Clicked key: ' eventdata.Key ' -> toggling Edge in Display']);
                    gui.uiButtons(5).Value = ~gui.uiButtons(5).Value;
                    gui.guiUpdate();
                case {'3'}
                    disp(['Clicked key: ' eventdata.Key ' -> toggling Mask in Display']);
                    gui.uiButtons(6).Value = ~gui.uiButtons(6).Value;
                    gui.guiUpdate();
                case {'4'}
                    disp(['Clicked key: ' eventdata.Key ' -> toggling Phase in Display']);
                    gui.uiButtons(7).Value = ~gui.uiButtons(7).Value;
                    gui.guiUpdate();
                case {'G'}
                    disp(['Clicked key: ' eventdata.Key ' -> Goto frame']);
                    uicontrol( gui.uiEdits(1) );
            end
            
            gui.prevClickCoor = []; % forget previous clicks
        end        

        function actionImageClicked(gui, hObject, ~)
            mouseButtonType     = get(gui.vanellusGUI.fig, 'SelectionType');
            contentPanelAx      = findall(gui.contentPanel.contentPanel, 'type', 'axes');
            hIm                 = contentPanelAx.Children;

            if hObject == hIm
                coor = uint16(get(contentPanelAx,'CurrentPoint')); % returns [col row]
                coor = coor(1,[2 1]); % disp(['Screen coordinates             : (' num2str(coor(1)) ',' num2str(coor(2)) ') [ T, L ] ']);

                % in case image was shown with additional region rotation, will need to convert coor
                coor = VTools.rotateCoordinates( coor, gui.masks.region.rotationAdditional90Idx, gui.masks.region.regionSize); 
                % disp(['Rotated Screen coordinates     : (' num2str(coor(1)) ',' num2str(coor(2)) ') [ L, T ] ']);
                
                frame = gui.masks.frames(gui.currentFrameIdx);

                if mouseButtonType(1)=='n' % normal = left mouse button
                    if gui.uiButtons(31).Value % 'P'
                        disp(['Clicked mouse : left -> add pixel to mask @ ' num2str(coor)]);
                        gui.masks.editByAddingPixel(coor, frame);

                    elseif gui.uiButtons(32).Value % 'L'
                        if isempty( gui.prevClickCoor ) % first click
                            disp(['Clicked mouse : left -> add line to mask, 1st click at @ ' num2str(coor)]);
                            gui.prevClickCoor = coor;
                        else % second click
                            disp(['Clicked mouse : left -> add line to mask, 2nd click at @ ' num2str(coor)]);
                            gui.masks.editByAddingLine( gui.prevClickCoor, coor, frame);
                            gui.prevClickCoor   = [];
                        end

                    elseif gui.uiButtons(33).Value % 'A'
                        disp(['Clicked mouse : left -> draw area to add to mask']);
                        contentPanelAx  = gui.contentPanel.contentPanel.Children; % findall(gui.contentPanel.contentPanel, 'type', 'axes');
                        polygon         = impoly(contentPanelAx);
                        area            = polygon.getPosition();
                        polygon.delete();
                        mask = poly2mask( area(:,1), area(:,2), double(gui.masks.region.rotatedRegionSize(1)), double(gui.masks.region.rotatedRegionSize(2)));
                        mask = rot90(mask, -gui.masks.region.rotationAdditional90Idx); % in case image was shown with additional region rotation, will need to convert mask
                        gui.masks.editByAddingArea( mask, frame );

                    elseif gui.uiButtons(34).Value % 'E'
                        disp(['Clicked mouse : left -> add edgeFill to mask @ ' num2str(coor)]);
                        gui.masks.editByAddingEdgefill(coor, frame);

                    elseif gui.uiButtons(35).Value % 'C'
                        disp(['Clicked mouse : left -> add connected area to mask @ ' num2str(coor) ' -> not doing anything']);
                    end

                elseif mouseButtonType(1)=='a' % alternate = ctrl+left button or right mouse button

                    if gui.uiButtons(31).Value % 'P'
                        disp(['Clicked mouse : right -> remove pixel from mask @ ' num2str(coor)]);
                        gui.masks.editByRemovingPixel(coor, frame);

                    elseif gui.uiButtons(32).Value % 'L'
                        if isempty( gui.prevClickCoor ) % first click
                            disp(['Clicked mouse : right -> remove line from mask, 1st click at @ ' num2str(coor)]);
                            gui.prevClickCoor = coor;
                        else % second click
                            disp(['Clicked mouse : right -> remove line from mask, 2nd click at @ ' num2str(coor)]);
                            gui.masks.editByRemovingLine( gui.prevClickCoor, coor, frame);
                            gui.prevClickCoor   = [];
                        end

                    elseif gui.uiButtons(33).Value % 'A'
                        disp(['Clicked mouse : right -> draw area to remove from mask']);
                        contentPanelAx  = gui.contentPanel.contentPanel.Children; % findall(gui.contentPanel.contentPanel, 'type', 'axes');
                        polygon         = impoly(contentPanelAx);
                        area            = polygon.getPosition();
                        polygon.delete();
                        mask = poly2mask( area(:,1), area(:,2), double(gui.masks.region.rotatedRegionSize(1)), double(gui.masks.region.rotatedRegionSize(2)));
                        mask = rot90(mask, -gui.masks.region.rotationAdditional90Idx); % in case image was shown with additional region rotation, will need to convert mask
                        gui.masks.editByRemovingArea( mask, frame );

                    elseif gui.uiButtons(34).Value % 'E'
                        disp(['Clicked mouse : right -> remove edgeFill from mask @ ' num2str(coor)]);
                        gui.masks.editByRemovingEdgefill(coor, frame);

                    elseif gui.uiButtons(35).Value % 'C'
                        disp(['Clicked mouse : right -> remove connected area from mask @ ' num2str(coor)]);
                        gui.masks.editByRemovingConnectedarea(coor, frame);
                    end                        
                end
            end
            
            gui.guiUpdate();
        end
        
        
        %% Actions %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function actionChangeFrame(gui, hObject, eventdata)
            drawnow limitrate nocallbacks; % was: pause(0.1);
            if hObject == gui.uiEdits(1)
                if ~isequal( eventdata.Key, 'return'), return; end
                drawnow; % makes sure that uiEdits(1) is up to date
                frame = str2double( gui.uiEdits(1).String );
                if ~isnan(frame)
                    idx = find(gui.masks.frames==frame);
                    if ~isempty(idx)
                        gui.currentFrameIdx =idx(1);
                    end
                end
            elseif hObject == gui.uiButtons(1) && gui.currentFrameIdx > 1
                gui.currentFrameIdx = gui.currentFrameIdx - 1;
            elseif hObject == gui.uiButtons(2) && gui.currentFrameIdx < length(gui.masks.frames)
                gui.currentFrameIdx = gui.currentFrameIdx + 1;
            end
            gui.vanellusGUI.removeFocusFromObject(hObject); % remove focus from edit box / button
            gui.prevClickCoor = []; % forget previous clicks
            gui.guiUpdate();
        end        
        
        function actionSaveRegion(gui, ~, ~)
            gui.masks.region.save();
            gui.guiUpdate();
        end

        function actionClear(gui, ~, ~)
            gui.masks.editByClearingMask( gui.masks.frames(gui.currentFrameIdx) );
            gui.guiUpdate();
        end
        
        function actionAddEdges(gui, ~, ~)
            gui.masks.editByAddingEdges( gui.masks.frames(gui.currentFrameIdx) );
            gui.guiUpdate();
        end
        
        function actionRecalculateButtonPressed(gui, ~, ~)
            % indicate that GUI is working
            gui.vanellusGUI.fig.Pointer = 'watch';
            drawnow;

            gui.masks.calcAndSetData( gui.masks.frames(gui.currentFrameIdx) );
            gui.guiUpdate();

            % indicate that GUI is finished
            gui.vanellusGUI.fig.Pointer = 'arrow';
        end        

        function actionCopyMaskButtonPressed(gui, hObject, ~)
            drawnow limitrate nocallbacks; % was: pause(0.1);
            frame = str2double( gui.uiEdits(21).String );
            if ~isnan(frame)
                idx = find(gui.masks.frames==frame);
                if ~isempty(idx)
                    frame = gui.masks.frames(idx);

                    disp(['Copying mask from frame ' num2str(frame)]);
                    mask = gui.masks.getData(frame);
                    gui.masks.setData( gui.masks.frames(gui.currentFrameIdx), mask);

                    % remove focus from edit box
                    gui.vanellusGUI.removeFocusFromObject(hObject);
                end
            end
            gui.guiUpdate();            
        end        
        
        function actionFillHolesButtonPressed(gui, ~, ~)
            gui.masks.editByFillingHoles(gui.masks.frames(gui.currentFrameIdx));
            gui.guiUpdate();
        end        
        
        function actionEditedTable(gui, hObject, eventdata)
            if isempty(eventdata.Indices), return; end % avoid error when changing display while cell is selected
            
            if eventdata.Indices(2) == 2 % only respond to clicks in 2nd column
                [settingsList, ~, ~] = gui.getSettingsData(); 
                settingName = settingsList{eventdata.Indices(1)};
                
                if isempty(settingName), return; end % avoid empty row error
                
                try
                    oldValue = gui.masks.get(settingName);
                    newValue = eventdata.NewData; % newValue = cast( newValue, 'like', oldValue);
                    
                    if ischar(oldValue), newValue = ['''' newValue '''']; end
                    if isnumeric(oldValue), newValue = ['[' newValue ']']; end
                    eval(['gui.masks.set(''' settingName ''', ' newValue ');']); % gui.masks.set(settingName, newValue);
                    disp([ settingName ' changed']);
                catch
                    warning(['GUIMasks: something went wrong while trying to change a setting.']);
                end
            end
            gui.guiUpdate();
            gui.vanellusGUI.removeFocusFromObject(hObject);
        end
        
        function actionChangeClickBehavior(gui, hObject, ~)
            switch upper( hObject.String )
                case {'P','L','A','E','C'}
                    for i = 31:35
                        gui.uiButtons(i).Value  = 0;
                    end
                    hObject.Value  = 1;
                    
                    % turn edge display on
                    if strcmpi(hObject.String, 'E')
                        gui.uiButtons(4).Value              = 1;
                    end
                    
            end
            gui.vanellusGUI.removeFocusFromObject(hObject);
            gui.prevClickCoor = []; % forget previous clicks
            gui.guiUpdate();
        end        

        function actionUndoButtonPressed(gui, ~, ~)
            gui.masks.undo( gui.masks.frames(gui.currentFrameIdx) );
            gui.guiUpdate();
        end
        
    end
end

