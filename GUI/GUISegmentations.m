classdef GUISegmentations < GUITogglePanel
% GUISegmentations

% Copyright Daan Kiviet 2018-
% Version : 2017-03-07

    properties (Constant = true)
        DIFFERENT_COLORS        = 250;

        COLORNR_BACKGROUND      = 0;
        COLORNR_EDGE            = GUISegmentations.DIFFERENT_COLORS + 1;
        COLORNR_MASK            = GUISegmentations.DIFFERENT_COLORS + 2;
        COLORNR_OUTLINE         = GUISegmentations.DIFFERENT_COLORS + 3;

        COLOR_BACKGROUND        = [0.0 0.0 0.0];
        COLOR_EDGE              = [1.0 1.0 1.0];
        COLOR_MASK              = [0.5 0.5 0.6];
        COLOR_OUTLINE           = [0.9 0.9 0.9];
%         COLOR_CELL              = [0.5 0.5 0.5];
%         COLOR_TEXT              = [1.0 1.0 1.0];

        BUT_SELECTEDCOLOR       = [0.7 0.7 0.7];
    end
    
    properties (Transient) % not stored
        vanellusGUI
        segmentations

        contentPanel
        controlPanel

        uiTogglePanels
        uiTexts
        uiButtons
        uiEdits
        uiTables
        
        currentFrameIdx
        prevClickCoor
        colorTable
        selectedSegNr
    end

    properties (Dependent) % calculated on the fly
        frames
    end    
   
    methods
        %% loading and gui building / updating %%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function gui = GUISegmentations(vanellusGUI, segmentations)
            if nargin < 1, error('Need VanellusGUI as argument'); end
            if nargin < 2, error('Need segmentations as argument'); end

            gui.vanellusGUI     = vanellusGUI;
            gui.segmentations    = segmentations;
            gui.currentFrameIdx = 1;
            
            gui.guiUpdateColorTable();
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

            gui.uiButtons(3)                        = uicontrol(gui.uiTogglePanels(1));
            gui.uiButtons(3).Style                  = 'togglebutton';
            gui.uiButtons(3).Min                    = 0;
            gui.uiButtons(3).Max                    = 1;
            gui.uiButtons(3).Value                  = 1;
            gui.uiButtons(3).String                 = 'Seg';
            gui.uiButtons(3).Callback               = @gui.guiUpdate;

            gui.uiButtons(4)                        = copyobj(gui.uiButtons(3), gui.uiTogglePanels(1));
            gui.uiButtons(4).String                 = 'Edge';
            gui.uiButtons(4).Value                  = 0;
            gui.uiButtons(4).Callback               = @gui.guiUpdate;
            
            gui.uiButtons(5)                        = copyobj(gui.uiButtons(3), gui.uiTogglePanels(1));
            gui.uiButtons(5).String                 = 'Mask';
            gui.uiButtons(5).Value                  = 0;
            gui.uiButtons(5).Callback               = @gui.guiUpdate;

            gui.uiButtons(6)                        = copyobj(gui.uiButtons(3), gui.uiTogglePanels(1));
            gui.uiButtons(6).String                 = 'Phase';
            gui.uiButtons(6).Value                  = 1;
            gui.uiButtons(6).Callback               = @gui.guiUpdate;
            
            gui.uiButtons(7)                        = copyobj(gui.uiButtons(3), gui.uiTogglePanels(1));
            gui.uiButtons(7).String                 = 'Seg #';
            gui.uiButtons(7).Value                  = 0;
            gui.uiButtons(7).Callback               = @gui.guiUpdate;
            
            %% Edit Panel
            gui.uiButtons(11)                       = copyobj(gui.uiButtons(1), gui.uiTogglePanels(2));
            gui.uiButtons(11).String                = 'Remove small cells';
            gui.uiButtons(11).Callback              = @gui.actionRemoveSmallCellsButtonPressed;                                  

            gui.uiButtons(12)                       = copyobj(gui.uiButtons(1), gui.uiTogglePanels(2));
            gui.uiButtons(12).String                = 'Fill holes';
            gui.uiButtons(12).Callback              = @gui.actionFillHolesButtonPressed;                                  

            gui.uiButtons(13)                       = copyobj(gui.uiButtons(1), gui.uiTogglePanels(2));
            gui.uiButtons(13).String                = 'Recolor';
            gui.uiButtons(13).Callback              = @gui.actionRecolorButtonPressed;                                  

            gui.uiButtons(14)                       = copyobj(gui.uiButtons(1), gui.uiTogglePanels(2));
            gui.uiButtons(14).String                = 'Undo';
            gui.uiButtons(14).Callback              = @gui.actionUndoButtonPressed;                                  
            
            %% Analysis Panel
            gui.uiButtons(21)                       = copyobj(gui.uiButtons(1), gui.uiTogglePanels(3));
            gui.uiButtons(21).String                = 'Recalculate';
            gui.uiButtons(21).Callback              = @gui.actionRecalculateButtonPressed;                                  

            gui.uiButtons(22)                       = copyobj(gui.uiButtons(1), gui.uiTogglePanels(3));
            gui.uiButtons(22).String                = 'Copy from Frame';
            gui.uiButtons(22).Callback              = @gui.actionCopySegButtonPressed;                                  
            
            gui.uiEdits(21)                         = copyobj(gui.uiEdits(1), gui.uiTogglePanels(3));
            
            %% Click Behavior Panel
            gui.uiButtons(31)                       = copyobj(gui.uiButtons(1), gui.uiTogglePanels(4));
            gui.uiButtons(31).String                = 'SEGMENTING';
            gui.uiButtons(31).UserData              = 1;
            gui.uiButtons(31).Callback              = @gui.actionChangeClickBehavior;

            gui.uiButtons(32)                       = copyobj(gui.uiButtons(1), gui.uiTogglePanels(4));
            gui.uiButtons(32).String                = 'DRAWING';
            gui.uiButtons(32).UserData              = 0;
            gui.uiButtons(32).Callback              = @gui.actionChangeClickBehavior;

            gui.uiButtons(33)                       = copyobj(gui.uiButtons(3), gui.uiTogglePanels(4));
            gui.uiButtons(33).String                = 'P';
            gui.uiButtons(33).TooltipString         = 'Pixel';
            gui.uiButtons(33).Value                 = 0;
            gui.uiButtons(33).Callback              = @gui.actionChangeClickBehavior;
            
            gui.uiButtons(34)                       = copyobj(gui.uiButtons(33), gui.uiTogglePanels(4));
            gui.uiButtons(34).String                = 'L';
            gui.uiButtons(34).TooltipString         = 'Line';
            gui.uiButtons(34).Callback              = @gui.actionChangeClickBehavior;
            
            gui.uiButtons(35)                       = copyobj(gui.uiButtons(33), gui.uiTogglePanels(4));
            gui.uiButtons(35).String                = 'A';
            gui.uiButtons(35).TooltipString         = 'Area';
            gui.uiButtons(35).Callback              = @gui.actionChangeClickBehavior;

            gui.uiButtons(36)                       = copyobj(gui.uiButtons(33), gui.uiTogglePanels(4));
            gui.uiButtons(36).String                = 'E';
            gui.uiButtons(36).TooltipString         = 'Edgefill';
            gui.uiButtons(36).Callback              = @gui.actionChangeClickBehavior;
            gui.uiButtons(36).Value                 = 1;

            gui.uiButtons(37)                       = copyobj(gui.uiButtons(33), gui.uiTogglePanels(4));
            gui.uiButtons(37).String                = 'C';
            gui.uiButtons(37).TooltipString         = 'Connected area';
            gui.uiButtons(37).Callback              = @gui.actionChangeClickBehavior; 
            
            gui.uiTexts(31)                         = copyobj(gui.uiTexts(1), gui.uiTogglePanels(4));
            gui.uiTexts(31).String                  = 'Left click   :';
            
            gui.uiTexts(32)                         = copyobj(gui.uiTexts(1), gui.uiTogglePanels(4));
            gui.uiTexts(32).String                  = 'merge';

            gui.uiTexts(33)                         = copyobj(gui.uiTexts(1), gui.uiTogglePanels(4));
            gui.uiTexts(33).String                  = 'Right click :';
            
            gui.uiTexts(34)                         = copyobj(gui.uiTexts(1), gui.uiTogglePanels(4));
            gui.uiTexts(34).String                  = 'cut';

            gui.uiTexts(35)                         = copyobj(gui.uiTexts(1), gui.uiTogglePanels(4));
            gui.uiTexts(35).String                  = 'Shift click  :';

            gui.uiTexts(36)                         = copyobj(gui.uiTexts(1), gui.uiTogglePanels(4));
            gui.uiTexts(36).String                  = 'delete';

            gui.uiTexts(37)                         = copyobj(gui.uiTexts(1), gui.uiTogglePanels(4));
            gui.uiTexts(37).String                  = 'seg pick';
            
            gui.uiTexts(38)                         = copyobj(gui.uiTexts(1), gui.uiTogglePanels(4));
            gui.uiTexts(38).String                  = '-';
            gui.uiTexts(38).HorizontalAlignment     = 'center';

            gui.uiButtons(38)                       = copyobj(gui.uiButtons(1), gui.uiTogglePanels(4));
            gui.uiButtons(38).String                = 'Clear';
            gui.uiButtons(38).Callback              = @gui.actionClearSelectedSegNr;            
            
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
            gui.uiButtons(13).TooltipString         = 'keyboard shortcut = r';
%             gui.uiButtons(XX).TooltipString     = 'keyboard shortcut = u';
            gui.uiButtons(7).TooltipString          = 'keyboard shortcut = BACKQUOTE';
            gui.uiButtons(3).TooltipString          = 'keyboard shortcut = 1';
            gui.uiButtons(4).TooltipString          = 'keyboard shortcut = 2';
            gui.uiButtons(5).TooltipString          = 'keyboard shortcut = 3';
            gui.uiButtons(6).TooltipString          = 'keyboard shortcut = 4';            
            gui.uiButtons(21).TooltipString         = 'keyboard shortcut = SHIFT + R';
            gui.uiButtons(33).TooltipString         = 'add/remove a pixel (keyboard shortcut = p)';
            gui.uiButtons(34).TooltipString         = 'add/remove a line (keyboard shortcut = l)';
            gui.uiButtons(35).TooltipString         = 'add/remove an area (keyboard shortcut = a)';
            gui.uiButtons(36).TooltipString         = 'add/remove an edge bound region (keyboard shortcut = e)';
            gui.uiButtons(37).TooltipString         = 'add/remove a connected area (keyboard shortcut = c)';
            gui.uiButtons(12).TooltipString         = 'keyboard shortcut = i';
            gui.uiButtons(31).TooltipString         = 'keyboard shortcut = d';
            gui.uiButtons(32).TooltipString         = 'keyboard shortcut = d';

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
            gui.uiButtons(3).Position       = [180  85  80  20];
            gui.uiButtons(4).Position       = [180  60  80  20];
            gui.uiButtons(5).Position       = [180  35  80  20];
            gui.uiButtons(6).Position       = [180  10  80  20];            
            gui.uiButtons(7).Position       = [ 80  10  80  20];            

            gui.uiTogglePanels(2).Position  = [ 10 200 280  80]; % Edit
            gui.uiButtons(11).Position      = [ 10  40 100  20];
            gui.uiButtons(12).Position      = [120  40  60  20];
            gui.uiButtons(13).Position      = [190  40  60  20];
            gui.uiButtons(14).Position      = [ 10  10  50  20];

            gui.uiTogglePanels(3).Position  = [ 10 200 280  50]; % Analysis
            gui.uiButtons(21).Position      = [ 10  10  80  20];
            gui.uiButtons(22).Position      = [100  10  90  20];
            gui.uiEdits(21).Position        = [190  10  40  20];
            
            gui.uiTogglePanels(4).Position  = [ 10 200 280 105]; % Click Behavior
            gui.uiButtons(31).Position      = [ 80  65  75  20];
            gui.uiButtons(32).Position      = [160  65 110  20];
            gui.uiTexts(31).Position        = [ 10  48  60  15];
            gui.uiTexts(33).Position        = [ 10  28  60  15];
            gui.uiTexts(35).Position        = [ 10   8  60  15];
            gui.uiTexts(32).Position        = [100  48  60  15];
            gui.uiTexts(34).Position        = [100  28  60  15];
            gui.uiTexts(36).Position        = [100   8  60  15];
            gui.uiButtons(33).Position      = [160  35  20  20];
            gui.uiButtons(34).Position      = [182  35  20  20];
            gui.uiButtons(35).Position      = [204  35  20  20];
            gui.uiButtons(36).Position      = [226  35  20  20];
            gui.uiButtons(37).Position      = [248  35  20  20];
            gui.uiTexts(37).Position        = [160   8  40  15];
            gui.uiTexts(38).Position        = [205   6  30  17];
            gui.uiButtons(38).Position      = [240   5  30  20];
            
            gui.uiTogglePanels(5).Position  = [ 10 200 280 280]; % Relevant Settings Panel
            gui.uiTables(1).Position        = [ 10  10 260 250];
            
            % INITIALIZE TOGGLE PANELS
            gui.guiInitializeTogglePanels();            
        end

        function guiUpdate(gui, ~, ~)

            % UPDATE CONTROLPANEL
            if isempty(gui.segmentations.frames)
                gui.uiEdits(1).String = '-';
                gui.uiEdits(21).String = '-';
            else
                gui.uiEdits(1).String = gui.segmentations.frames(gui.currentFrameIdx);
                gui.uiEdits(21).String = gui.segmentations.frames( max(1, gui.currentFrameIdx - 1) );
            end                

            % update settings Table
            [~, ~, combined]            = gui.getSettingsData();
            gui.uiTables(1).RowName     = {};  % settingsList
            gui.uiTables(1).Data        = combined; % data;
            if gui.uiTables(1).Extent(3) < gui.uiTables(1).Position(3), gui.uiTables(1).Position(3) = gui.uiTables(1).Extent(3); end            
            
            % DRAW CLICK BEHAVIOR BUTTONS
            if gui.uiButtons(31).UserData % SEGMENTING
                gui.uiButtons(31).BackgroundColor   = gui.BUT_SELECTEDCOLOR;
                gui.uiButtons(31).ForegroundColor   = [0 0 0];
                gui.uiButtons(32).BackgroundColor   = gui.uiButtons(32).Parent.BackgroundColor;
                gui.uiButtons(32).ForegroundColor   = gui.BUT_SELECTEDCOLOR;

%                 gui.uiTexts(32).Enable              = 'on';
%                 gui.uiTexts(34).Enable              = 'on';
%                 gui.uiTexts(36).Enable              = 'on';
           
                gui.uiButtons(33).Enable            = 'off';
                gui.uiButtons(34).Enable            = 'off';
                gui.uiButtons(35).Enable            = 'off';
                gui.uiButtons(36).Enable            = 'off';
                gui.uiButtons(37).Enable            = 'off';
                gui.uiTexts(37).Enable              = 'off';
                gui.uiTexts(38).Enable              = 'off';
                gui.uiButtons(38).Enable            = 'off';
                
            else  % DRAWING
                gui.uiButtons(31).BackgroundColor   = gui.uiButtons(31).Parent.BackgroundColor;
                gui.uiButtons(31).ForegroundColor   = gui.BUT_SELECTEDCOLOR;
                gui.uiButtons(32).BackgroundColor   = gui.BUT_SELECTEDCOLOR;
                gui.uiButtons(32).ForegroundColor   = [0 0 0];
                
%                 gui.uiTexts(32).Enable              = 'off';
%                 gui.uiTexts(34).Enable              = 'off';
%                 gui.uiTexts(36).Enable              = 'off';
           
                gui.uiButtons(33).Enable            = 'on';
                gui.uiButtons(34).Enable            = 'on';
                gui.uiButtons(35).Enable            = 'on';
                gui.uiButtons(36).Enable            = 'on';
                gui.uiButtons(37).Enable            = 'on';
                gui.uiTexts(37).Enable              = 'on';
                gui.uiTexts(38).Enable              = 'on';
                gui.uiButtons(38).Enable            = 'on';
                
                for i = 33:37
                    if gui.uiButtons(i).Value
                        gui.uiButtons(i).BackgroundColor   = gui.BUT_SELECTEDCOLOR;
                        gui.uiButtons(i).FontWeight        = 'bold';
                    else
                        gui.uiButtons(i).BackgroundColor   = gui.uiButtons(i).Parent.BackgroundColor;
                        gui.uiButtons(i).FontWeight        = 'normal';
                    end
                end
                
                gui.uiTexts(38).String              = num2str(gui.selectedSegNr);
                if isempty(gui.selectedSegNr)
                    selectedColor                   = [1 1 1];
                else
                    selectedColor                   = ind2rgb(GUISegmentations.prepareSeg(gui.selectedSegNr), gui.colorTable);
                end
                gui.uiTexts(38).BackgroundColor     = selectedColor;
            end
            
            % COLOR RECALCULATE BUTTON, IN CASE SEGMENTATION NEEDS UPDATING
            frame1      = gui.segmentations.frames(gui.currentFrameIdx);
            if gui.segmentations.doesDataNeedUpdating( frame1 )
                gui.uiButtons(21).BackgroundColor     = [1 0 0];
            else
                gui.uiButtons(21).BackgroundColor     = gui.uiButtons(1).BackgroundColor;
            end
            
            % UPDATE CONTENTPANEL (=SCROLLPANEL)
            rgb = gui.getSegmentationImage();
            hIm = gui.contentPanel.showImage(rgb, gui.vanellusGUI.currentMagnification);
            set(hIm, 'ButtonDownFcn', @gui.actionImageClicked);
            
            % UPDATE NAVPANEL
            gui.vanellusGUI.guiUpdateNavPanel();
        end
        
        function guiUpdateColorTable(gui)
            disp('updating colorTable');
            
            % note that ind2rgb on uint16 will set 0->1 and 1->2 in colorMap
            
            % get segColormap
            gui.colorTable = VTools.segColormap( GUISegmentations.DIFFERENT_COLORS );

            % randomize segColorMap
            gui.colorTable(2:end+1,:) = gui.colorTable(randperm(GUISegmentations.DIFFERENT_COLORS)',:);
            
            % add additional color
            gui.colorTable(GUISegmentations.COLORNR_BACKGROUND+1,:)    = GUISegmentations.COLOR_BACKGROUND;
            gui.colorTable(GUISegmentations.COLORNR_EDGE+1,:)          = GUISegmentations.COLOR_EDGE;
            gui.colorTable(GUISegmentations.COLORNR_MASK+1,:)          = GUISegmentations.COLOR_MASK;
            gui.colorTable(GUISegmentations.COLORNR_OUTLINE+1,:)       = GUISegmentations.COLOR_OUTLINE;
        end        
        
        function save(gui, ~, ~)
            if gui.segmentations.save()
                % set view to XX
%                 gui.uiButtons(1).Value              = 1;
%                 gui.uiButtons(2).Value              = 0;
%                 gui.uiButtons(21).Value              = 1;
%                 gui.uiButtons(3).Value              = 0;
            end
            
            gui.guiUpdate();
        end        
        
        
        %% Controller %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function rgb = getSegmentationImage(gui)
            segSize     = gui.segmentations.region.regionSize;
            frame1      = gui.segmentations.frames(gui.currentFrameIdx);

            % Setup output
            rgb = repmat(reshape(GUISegmentations.COLOR_BACKGROUND, [1 1 3]), segSize);
            
            % add mask
            if gui.uiButtons(5).Value
                mask1       = gui.segmentations.region.getMask( frame1 );
                mask1RGB    = repmat(reshape(GUISegmentations.COLOR_MASK, [1 1 3]), segSize); %                 tmp     = ones([segSize 3]) .* repmat(reshape(GUISegmentations.COLOR_MASK, [1 1 3]), segSize);
                idx         = repmat( mask1, [1 1 3]);
                rgb( idx )  = mask1RGB( idx );
            end

            % add edge
            if gui.uiButtons(4).Value
                seg1Edge    = gui.segmentations.getSegEdge( frame1 );
                seg1EdgeRGB = repmat(reshape(GUISegmentations.COLOR_EDGE, [1 1 3]), segSize);
                idx         = repmat( seg1Edge, [1 1 3]);
                rgb( idx )  = seg1EdgeRGB( idx );
            end
            
            % add seg
            if gui.uiButtons(3).Value
                seg1        = gui.segmentations.getData( frame1 );
                seg1        = GUISegmentations.prepareSeg(seg1);
                seg1RGB     = ind2rgb(seg1, gui.colorTable);
                idx         = repmat( logical(seg1), [1 1 3]);
                rgb( idx )  = seg1RGB( idx );
            end
            
            % add phase
            if gui.uiButtons(6).Value
                seg1Image   = gui.segmentations.getSegImage( frame1 );
%                 seg1Image_f = imfilter(im2double(seg1Image), fspecial('log', [100 100], 1), 'replicate');
%                 seg1Image = seg1Image_f - min(min(seg1Image_f));
%                 seg1Image = VTools.scaleRange(seg1Image, [max(max(seg1Image)) min(min(seg1Image))], [0 1]);
                rgb = VTools.addPhaseOverlayToRGB(rgb, seg1Image);
            end
            
            % add seg numbers
            if gui.uiButtons(7).Value
                % get rotated seg
                seg1        = gui.segmentations.getData( frame1 );
                seg1        = rot90( seg1, gui.segmentations.region.rotationAdditional90Idx);
                
                % get nr image and rotate back
                seg1Nrs     = gui.getSegNrsImFromSeg( seg1 );
                seg1Nrs     = rot90( seg1Nrs, -gui.segmentations.region.rotationAdditional90Idx);
                
                seg1NrsRGB  = repmat(reshape(GUISegmentations.COLOR_EDGE, [1 1 3]), segSize);
                idx         = repmat( seg1Nrs, [1 1 3]);
                rgb( idx )  = seg1NrsRGB( idx );
            end
    
            % apply additional region rotation (only for visualization)
            rotationAdditional90Idx = gui.segmentations.region.rotationAdditional90Idx;
            if rotationAdditional90Idx ~= 4
                rgb = VTools.rot90_3D(rgb, rotationAdditional90Idx);
            end            
        end
        
        function [settingsList, data, combined] = getSettingsData(gui) 
            settings        = gui.segmentations.getCurrentDefaultSettings();
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
                    gui.actionChangeClickBehavior( gui.uiButtons(33) );
                case {'L'}
                    disp(['Clicked key: ' eventdata.Key ' -> Line']);
                    gui.actionChangeClickBehavior( gui.uiButtons(34) );
                case {'A'}
                    disp(['Clicked key: ' eventdata.Key ' -> Area']);
                    gui.actionChangeClickBehavior( gui.uiButtons(35) );
                case {'E'}
                    disp(['Clicked key: ' eventdata.Key ' -> Edgefill']);
                    gui.actionChangeClickBehavior( gui.uiButtons(36) );
                case {'C'}
                    disp(['Clicked key: ' eventdata.Key ' -> Connected area']);
                    gui.actionChangeClickBehavior( gui.uiButtons(37) );
                    
                case {'I'}
                    disp(['Clicked key: ' eventdata.Key ' -> filling holes (in cells)']);
                    gui.actionFillHolesButtonPressed();
                case {'R'}
                    if strcmp(eventdata.Modifier, 'shift')
                        disp(['Clicked key: shift + ' eventdata.Key ' -> recalculating']);
                        gui.actionRecalculateButtonPressed();
                    else
                        disp(['Clicked key: ' eventdata.Key ' -> recoloring']);
                        gui.actionRecolorButtonPressed();
                    end
                case {'D'}
                    disp(['Clicked key: ' eventdata.Key ' -> changing click behavior']);
                    if gui.uiButtons(31).UserData
                        gui.actionChangeClickBehavior(gui.uiButtons(32));
                    else
                        gui.actionChangeClickBehavior(gui.uiButtons(31));
                    end
                case {'U'}
                    disp(['Clicked key: ' eventdata.Key ' -> Undo']);
                    gui.segmentations.undo( gui.segmentations.frames(gui.currentFrameIdx) );
                    gui.guiUpdate();
                case {'S'}
                    disp(['Clicked key: ' eventdata.Key ' -> saving']);
                    gui.actionSaveRegion();
                    
                case {'BACKQUOTE'}
                    disp(['Clicked key: ' eventdata.Key ' -> toggling # in Display']);
                    gui.uiButtons(7).Value = ~gui.uiButtons(7).Value;
                    gui.guiUpdate();
                case {'1'}
                    disp(['Clicked key: ' eventdata.Key ' -> toggling Seg in Display']);
                    gui.uiButtons(3).Value = ~gui.uiButtons(3).Value;
                    gui.guiUpdate();
                case {'2'}
                    disp(['Clicked key: ' eventdata.Key ' -> toggling Edge in Display']);
                    gui.uiButtons(4).Value = ~gui.uiButtons(4).Value;
                    gui.guiUpdate();
                case {'3'}
                    disp(['Clicked key: ' eventdata.Key ' -> toggling Mask in Display']);
                    gui.uiButtons(5).Value = ~gui.uiButtons(5).Value;
                    gui.guiUpdate();
                case {'4'}
                    disp(['Clicked key: ' eventdata.Key ' -> toggling Phase in Display']);
                    gui.uiButtons(6).Value = ~gui.uiButtons(6).Value;
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
                coor = VTools.rotateCoordinates( coor, gui.segmentations.region.rotationAdditional90Idx, gui.segmentations.region.regionSize); 
                % disp(['Rotated Screen coordinates     : (' num2str(coor(1)) ',' num2str(coor(2)) ') [ L, T ] ']);
                
                if gui.uiButtons(31).UserData % SEGMENTING
                    if mouseButtonType(1)=='n' % normal = left mouse button
                        if isempty( gui.prevClickCoor )
                            % first click
                            disp(['Clicked mouse : left -> join 2 cells together, 1st click at @ ' num2str(coor)]);
                            gui.prevClickCoor = coor;
                        else
                            % second click
                            disp(['Clicked mouse : left -> join 2 cells together, 2nd click at @ ' num2str(coor)]);
                            gui.segmentations.editByJoiningCells( gui.prevClickCoor, coor, gui.segmentations.frames(gui.currentFrameIdx));
                            gui.prevClickCoor   = [];
                        end                    

                    elseif mouseButtonType(1)=='a' % alternate = ctrl+left button or right mouse button

                        % check whether cell or background was clicked
                        seg                 = gui.segmentations.getData( gui.segmentations.frames(gui.currentFrameIdx) );
                        segNr               = seg( coor(1), coor(2) );
                        if segNr > 0
                            disp(['Clicked mouse : right  -> cut cell @ ' num2str(coor)]);
                            gui.segmentations.editByCuttingCell(coor, gui.segmentations.frames(gui.currentFrameIdx));
                            gui.prevClickCoor = []; % forget previous clicks
                        else
                            if isempty( gui.prevClickCoor )
                                % first click
                                disp(['Clicked mouse : right -> cut cell, 1st click at @ ' num2str(coor)]);
                                gui.prevClickCoor = coor;
                            else
                                % second click
                                disp(['Clicked mouse : right -> cut cells, 2nd click at @ ' num2str(coor)]);
                                coor1               = gui.prevClickCoor;
                                gui.prevClickCoor   = [];
                                coor2               = coor;

                                gui.segmentations.editByCuttingCellUsingLine(coor1, coor2, gui.segmentations.frames(gui.currentFrameIdx));
                            end                    
                        end

                    elseif mouseButtonType(1)=='e' % extend = shift+left button
                        disp(['Clicked mouse : shift+left -> removing cell @ ' num2str(coor)]);
                        gui.segmentations.editByRemovingCell(coor, gui.segmentations.frames(gui.currentFrameIdx));
                        gui.prevClickCoor = []; % forget previous clicks

                    end
                else
                    frame = gui.segmentations.frames(gui.currentFrameIdx);

                    % get selectedSegNr
                    seg = gui.segmentations.getData(frame);
                    segNrs = unique(seg);
                    segNrs(segNrs==0) = [];
                    if isempty(gui.selectedSegNr) || isempty(segNrs==gui.selectedSegNr)
                        selSegNr = max(segNrs) + 1;
                    else
                        selSegNr = gui.selectedSegNr;
                    end
                    if isempty(selSegNr), selSegNr = 1; end
                    
                    if mouseButtonType(1)=='n' % normal = left mouse button
                        if gui.uiButtons(33).Value % 'P'
                            disp(['Clicked mouse : left -> add pixel to seg @ ' num2str(coor)]);
                            gui.segmentations.editByAddingPixel(coor, frame, selSegNr);

                        elseif gui.uiButtons(34).Value % 'L'
                            if isempty( gui.prevClickCoor ) % first click
                                disp(['Clicked mouse : left -> add line to seg, 1st click at @ ' num2str(coor)]);
                                gui.prevClickCoor = coor;
                            else % second click
                                disp(['Clicked mouse : left -> add line to seg, 2nd click at @ ' num2str(coor)]);
                                gui.segmentations.editByAddingLine( gui.prevClickCoor, coor, frame, selSegNr);
                                gui.prevClickCoor   = [];
                            end

                        elseif gui.uiButtons(35).Value % 'A'
                            disp(['Clicked mouse : left -> draw area to add to seg']);
                            contentPanelAx  = gui.contentPanel.contentPanel.Children; % findall(gui.contentPanel.contentPanel, 'type', 'axes');
                            polygon         = impoly(contentPanelAx);
                            area            = polygon.getPosition();
                            polygon.delete();
                            mask = poly2mask( area(:,1), area(:,2), double(gui.segmentations.region.rotatedRegionSize(1)), double(gui.segmentations.region.rotatedRegionSize(2)));
                            mask = rot90(mask, -gui.segmentations.region.rotationAdditional90Idx); % in case image was shown with additional region rotation, will need to convert mask
                            gui.segmentations.editByAddingArea( mask, frame, selSegNr );

                        elseif gui.uiButtons(36).Value % 'E'
                            disp(['Clicked mouse : left -> add edgeFill to seg @ ' num2str(coor)]);
                            gui.segmentations.editByAddingEdgefill(coor, frame, selSegNr);

                        elseif gui.uiButtons(37).Value % 'C'
                            disp(['Clicked mouse : left -> add connected area to seg @ ' num2str(coor) ' -> not doing anything']);

                        end
                    
                    elseif mouseButtonType(1)=='a' % alternate = ctrl+left button or right mouse button

                        if gui.uiButtons(33).Value % 'P'
                            disp(['Clicked mouse : right -> remove pixel from seg @ ' num2str(coor)]);
                            gui.segmentations.editByRemovingPixel(coor, frame);

                        elseif gui.uiButtons(34).Value % 'L'
                            if isempty( gui.prevClickCoor ) % first click
                                disp(['Clicked mouse : right -> remove line from seg, 1st click at @ ' num2str(coor)]);
                                gui.prevClickCoor = coor;
                            else % second click
                                disp(['Clicked mouse : right -> remove line from seg, 2nd click at @ ' num2str(coor)]);
                                gui.segmentations.editByRemovingLine( gui.prevClickCoor, coor, frame);
                                gui.prevClickCoor   = [];
                            end

                        elseif gui.uiButtons(35).Value % 'A'
                            disp(['Clicked mouse : right -> draw area to remove from seg']);
                            contentPanelAx  = gui.contentPanel.contentPanel.Children; % findall(gui.contentPanel.contentPanel, 'type', 'axes');
                            polygon         = impoly(contentPanelAx);
                            area            = polygon.getPosition();
                            polygon.delete();
                            mask = poly2mask( area(:,1), area(:,2), double(gui.segmentations.region.rotatedRegionSize(1)), double(gui.segmentations.region.rotatedRegionSize(2)));
                            mask = rot90(mask, -gui.segmentations.region.rotationAdditional90Idx); % in case image was shown with additional region rotation, will need to convert mask
                            gui.segmentations.editByRemovingArea( mask, frame );

                        elseif gui.uiButtons(36).Value % 'E'
                            disp(['Clicked mouse : right -> remove edgeFill from seg @ ' num2str(coor)]);
                            gui.segmentations.editByRemovingEdgefill(coor, frame);

                        elseif gui.uiButtons(37).Value % 'C'
                            disp(['Clicked mouse : right -> remove connected area from seg @ ' num2str(coor)]);
                            gui.segmentations.editByRemovingConnectedarea(coor, frame);

                        end                        
                        
                    elseif mouseButtonType(1)=='e' % extend = shift+left button
                        seg                 = gui.segmentations.getData( frame );
                        segNr               = seg( coor(1), coor(2) );
                        if segNr > 0
                            gui.selectedSegNr = segNr;
                        else
                            gui.selectedSegNr = [];
                        end
                        
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
                    idx = find(gui.segmentations.frames==frame);
                    if ~isempty(idx)
                        gui.currentFrameIdx =idx(1);
                    end
                end
            elseif hObject == gui.uiButtons(1) && gui.currentFrameIdx > 1
                gui.currentFrameIdx = gui.currentFrameIdx - 1;
            elseif hObject == gui.uiButtons(2) && gui.currentFrameIdx < length(gui.segmentations.frames)
                gui.currentFrameIdx = gui.currentFrameIdx + 1;
            end
            gui.vanellusGUI.removeFocusFromObject(hObject); % remove focus from edit box / button
            gui.prevClickCoor = []; % forget previous clicks
            gui.selectedSegNr = []; % forget previous selection
            gui.guiUpdate();
        end        
        
        function actionSaveRegion(gui, ~, ~)
            gui.segmentations.region.save();
            gui.guiUpdate();
        end

        function actionRecalculateButtonPressed(gui, ~, ~)
            % indicate that GUI is working
            gui.vanellusGUI.fig.Pointer = 'watch';
            drawnow;

            gui.segmentations.calcAndSetData( gui.segmentations.frames(gui.currentFrameIdx) );
            gui.guiUpdate();

            % indicate that GUI is finished
            gui.vanellusGUI.fig.Pointer = 'arrow';
        end        

        function actionCopySegButtonPressed(gui, hObject, ~)
            drawnow limitrate nocallbacks; % was: pause(0.1);
            frame = str2double( gui.uiEdits(21).String );
            if ~isnan(frame)
                idx = find(gui.segmentations.frames==frame);
                if ~isempty(idx)
                    frame = gui.segmentations.frames(idx);

                    disp(['Copying segmentation from frame ' num2str(frame)]);
                    seg = gui.segmentations.getData(frame);
                    gui.segmentations.setData( gui.segmentations.frames(gui.currentFrameIdx), seg);

                    % remove focus from edit box
                    gui.vanellusGUI.removeFocusFromObject(hObject);
                end
            end
            gui.guiUpdate();            
        end        
        
        function actionRemoveSmallCellsButtonPressed(gui, ~, ~)
            gui.segmentations.editByRemovingSmallCells( gui.segmentations.frames(gui.currentFrameIdx) );
            gui.guiUpdate();
        end        
        
        function actionFillHolesButtonPressed(gui, ~, ~)
            gui.segmentations.editByFillingCells(gui.segmentations.frames(gui.currentFrameIdx));
            gui.guiUpdate();
        end        
        
        function actionRecolorButtonPressed(gui, ~, ~)
            gui.guiUpdateColorTable();
            gui.guiUpdate();
        end        
        
        function actionEditedTable(gui, hObject, eventdata)
            if isempty(eventdata.Indices), return; end % avoid error when changing display while cell is selected
            
            if eventdata.Indices(2) == 2 % only respond to clicks in 2nd column
                [settingsList, ~, ~] = gui.getSettingsData(); 
                settingName = settingsList{eventdata.Indices(1)};
                
                if isempty(settingName), return; end % avoid empty row error
                
                try
                    oldValue = gui.segmentations.get(settingName);
                    newValue = eventdata.NewData; % newValue = cast( newValue, 'like', oldValue);
                    
                    if ischar(oldValue), newValue = ['''' newValue '''']; end
                    if isnumeric(oldValue), newValue = ['[' newValue ']']; end
                    eval(['gui.segmentations.set(''' settingName ''', ' newValue ');']); % gui.segmentations.set(settingName, newValue);
                    disp([ settingName ' changed']);
                catch
                    warning(['GUISegmentations: something went wrong while trying to change a setting.']);
                end
            end
            gui.guiUpdate();
            gui.vanellusGUI.removeFocusFromObject(hObject);
        end
        
        function actionChangeClickBehavior(gui, hObject, ~)
            switch upper( hObject.String )
                case {'P','L','A','E','C'}
                    for i = 33:37
                        gui.uiButtons(i).Value  = 0;
                    end
                    hObject.Value  = 1;
                    
                    % turn edge display on
                    if strcmpi(hObject.String, 'E')
                        gui.uiButtons(2).Value              = 1;
                    end
                    
                case {'SEGMENTING'}
                    gui.uiButtons(31).UserData = 1;
                    gui.uiButtons(32).UserData = 0;
                    gui.uiTexts(32).String     = 'merge';
                    gui.uiTexts(34).String     = 'cut';
                    gui.uiTexts(36).String     = 'delete';
                    
                case {'DRAWING'}
                    gui.uiButtons(31).UserData = 0;
                    gui.uiButtons(32).UserData = 1;
                    gui.uiTexts(32).String     = 'Add';
                    gui.uiTexts(34).String     = 'Remove';
                    gui.uiTexts(36).String     = '';
                    
            end
            gui.vanellusGUI.removeFocusFromObject(hObject);
            gui.prevClickCoor = []; % forget previous clicks
            gui.guiUpdate();
        end        
        
        function actionClearSelectedSegNr(gui, ~, ~)
            gui.selectedSegNr = [];
            gui.guiUpdate();
        end
        
        function actionUndoButtonPressed(gui, ~, ~)
            gui.segmentations.undo( gui.segmentations.frames(gui.currentFrameIdx) );
            gui.guiUpdate();
        end
        
    end
    
    methods (Static)
        function seg = prepareSeg(seg_in)
            seg             = mod(seg_in, GUISegmentations.DIFFERENT_COLORS)+1;
            seg(seg_in==0)  = GUISegmentations.COLORNR_BACKGROUND;
        end
        
        function seg = addOutlineToSeg(seg)
            % onle run after prepareSeg has run
            
%             temp = seg;
%             temp( seg == GUISegmentations.COLORNR_BACKGROUND) = 0;
%             temp( seg == GUISegmentations.COLORNR_EDGE) = 0;
%             temp( seg == GUISegmentations.COLORNR_MASK) = 0;
%             temp( seg == GUISegmentations.COLORNR_OUTLINE) = 0;
%             temp = bwperim(temp, 4);
%             seg(temp) = GUISegmentations.COLORNR_OUTLINE;
                                           
            cellNrs = setdiff( unique(seg)', [   GUISegmentations.COLORNR_BACKGROUND ...
                                                GUISegmentations.COLORNR_EDGE ...
                                                GUISegmentations.COLORNR_MASK ...
                                                GUISegmentations.COLORNR_OUTLINE ]);
            perim = VSegmentations.doForEachCell(seg, @(x) bwperim(x, 4), cellNrs);
            seg( find(perim) ) = GUISegmentations.COLORNR_OUTLINE;
%             figure; imshow(logical(perim));

%             function x = test(x)
%                 x( bwperim(x, 4) ) = GUISegmentations.COLORNR_OUTLINE;
%             end
%             seg = VSegmentations.doForEachCell(seg, @test, cellNrs');
        end
        
        function perim = getOutlineFromSeg(seg)
            cellNrs = setdiff( unique(seg)', [   GUISegmentations.COLORNR_BACKGROUND ...
                                                GUISegmentations.COLORNR_EDGE ...
                                                GUISegmentations.COLORNR_MASK ...
                                                GUISegmentations.COLORNR_OUTLINE ]);
            perim = logical( VSegmentations.doForEachCell(seg, @(x) bwperim(x, 4), cellNrs) );
        end
        
        function core = getCoreFromSeg(seg)
            cellNrs = setdiff( unique(seg)', [   GUISegmentations.COLORNR_BACKGROUND ...
                                                GUISegmentations.COLORNR_EDGE ...
                                                GUISegmentations.COLORNR_MASK ...
                                                GUISegmentations.COLORNR_OUTLINE ]);
%             core = logical( VSegmentations.doForEachCell(seg, @(x) imerode(x, strel('disk',6) ), cellNrs) );
            core = logical( VSegmentations.doForEachCell(seg, @(x) imdilate( bwmorph( bwmorph(x,'thin',Inf) ,'spur',3) , strel('disk',1) ), cellNrs) );
        end
        
        function segNrsIm = getSegNrsImFromSeg(seg)
            % prepare output image
            segNrsIm = zeros(size(seg));
            
%             % get coordinates of seg
%             rp = regionprops(seg, 'Centroid');
%                 tree(cellNr).rp_cenX(age)       = rp(segNr).Centroid(1) + obj.segmentations.region.rect(2) - 1;
%                 tree(cellNr).rp_cenY(age)       = rp(segNr).Centroid(2) + obj.segmentations.region.rect(1) - 1;                
            
            % determine segNrs
%   			segNrs = unique(seg);
%   			segNrs(segNrs==0) = [];
            segNrs = VTools.uniqueExcluding(seg, [0 NaN]);
            
            % loop over segs in this frame
            for i = 1:numel(segNrs)
                % location of segNr
                [y,x]   = find(seg == segNrs(i)); % note: returns (row, column), which will be used as (y,x)
                x       = mean(x);
                y       = mean(y);
                
                % image of nr
                im      = VTools.getImageOfNr( segNrs(i) );
                
                % place in segNrsIm
                segNrsIm = VTools.implace(segNrsIm, im, x, y);
            end
            
            segNrsIm = logical( segNrsIm );
        end
    end
end

