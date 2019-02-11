classdef GUITrackings < GUITogglePanel
% GUITrackings

% Copyright Daan Kiviet 2018-
% Version : 2017-03-07

    properties (Constant = true)
        SEG_DIVIDER_HEIGHT      = 10;
        NR_DISPLAY_LABELS       = {'No #', 'Seg #', 'Cell #', 'Birth #'};
    end
    
    properties (Transient) % not stored
        vanellusGUI
        trackings

        contentPanel
        controlPanel
        sidePanel
        
        uiTogglePanels
        uiTexts
        uiButtons
        uiEdits
        uiTables
        uiListboxes
        
        currentFrameIdx
        seg2cell
        seg2parent        
        colorTable
        prevClickCoorAndFrame
        
        trackingsAnalysis
    end  
    
    methods
        %% loading and gui building / updating %%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function gui = GUITrackings(vanellusGUI, trackings)
            if nargin < 1, error('Need VanellusGUI as argument'); end
            if nargin < 2, error('Need trackings as argument'); end

            gui.vanellusGUI         = vanellusGUI;
            gui.trackings           = trackings;
            gui.trackings.correctTrackingOfFrames();
            gui.currentFrameIdx     = 1;
            
            gui.calcTree();
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
            gui.uiTogglePanels(1).BorderType        = 'beveledin'; % 'etchedin' (default) | 'etchedout' | 'beveledin' | 'beveledout' | 'line' | 'none'
            gui.uiTogglePanels(1).BorderWidth       = 2; % 1 (default)
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
            
            gui.uiEdits(2)                          = copyobj(gui.uiEdits(1), gui.uiTogglePanels(1));
            gui.uiEdits(2).Enable                   = 'off'; % inactive
            
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
            
            gui.uiButtons(5)                        = copyobj(gui.uiButtons(4), gui.uiTogglePanels(1));
            gui.uiButtons(5).String                 = 'Mask';
            gui.uiButtons(5).Callback               = @gui.guiUpdate;

            gui.uiButtons(6)                        = copyobj(gui.uiButtons(4), gui.uiTogglePanels(1));
            gui.uiButtons(6).String                 = 'Phase';
            gui.uiButtons(6).Callback               = @gui.guiUpdate;
            
            gui.uiButtons(7)                        = uicontrol(gui.uiTogglePanels(1));
            gui.uiButtons(7).Style                  = 'pushbutton';
            gui.uiButtons(7).String                 = gui.NR_DISPLAY_LABELS{3};
            gui.uiButtons(7).Callback               = @gui.actionChangeNrDisplay;
            
            %% Edit Panel
            gui.uiButtons(11)                       = copyobj(gui.uiButtons(1), gui.uiTogglePanels(2));
            gui.uiButtons(11).String                = 'Recolor';
            gui.uiButtons(11).Callback              = @gui.actionRecolorButtonPressed;                                  

            gui.uiButtons(14)                       = copyobj(gui.uiButtons(1), gui.uiTogglePanels(2));
            gui.uiButtons(14).String                = 'Undo';
            gui.uiButtons(14).Callback              = @gui.actionUndoButtonPressed;                                  
            
            %% Analysis Panel
            gui.uiButtons(21)                       = copyobj(gui.uiButtons(1), gui.uiTogglePanels(3));
            gui.uiButtons(21).String                = 'Recalculate';
            gui.uiButtons(21).Callback              = @gui.actionRecalculateButtonPressed;                                  

            gui.uiButtons(22)                       = copyobj(gui.uiButtons(3), gui.uiTogglePanels(3));
            gui.uiButtons(22).String                = 'Analyze';
            gui.uiButtons(22).Value                 = 0;
            gui.uiButtons(22).Callback              = @gui.actionToggleAnalyze;                                  

            gui.uiButtons(23)                       = copyobj(gui.uiButtons(1), gui.uiTogglePanels(3));
            gui.uiButtons(23).String                = 'Compile';
            gui.uiButtons(23).Callback              = @gui.actionCompileButtonPressed;                                  
            
            %% Click Behavior Panel
            gui.uiTexts(31)                         = copyobj(gui.uiTexts(1), gui.uiTogglePanels(4));
            gui.uiTexts(31).String                  = 'Left click : connect cells';
            
            gui.uiTexts(32)                         = copyobj(gui.uiTexts(1), gui.uiTogglePanels(4));
            gui.uiTexts(32).String                  = 'Right click: disconnect cell';
            
            gui.uiTexts(33)                         = copyobj(gui.uiTexts(1), gui.uiTogglePanels(4));
            gui.uiTexts(33).String                  = 'Shift + left click: ';
            
            %% Relevant Settings Panel
            gui.uiTables                            = uitable(gui.uiTogglePanels(5));
            gui.uiTables(1).ColumnName              = [];
            gui.uiTables(1).ColumnWidth             = {130 125};
            gui.uiTables(1).ColumnEditable          = [false true];
            gui.uiTables(1).Enable                  = 'on';
            gui.uiTables(1).RowStriping             = 'off';
            gui.uiTables(1).CellEditCallback        = @gui.actionEditedTable;            
            
            % SET TOOLTIPS
            gui.uiEdits(1).TooltipString            = 'keyboard shortcut = g';
            gui.uiButtons(1).TooltipString          = 'keyboard shortcut = < or ,';
            gui.uiButtons(2).TooltipString          = 'keyboard shortcut = > or ,';
            gui.uiButtons(11).TooltipString         = 'keyboard shortcut = r';
%             gui.uiButtons(XX).TooltipString     = 'keyboard shortcut = u';
            gui.uiButtons(7).TooltipString          = 'keyboard shortcut = BACKQUOTE';
            gui.uiButtons(3).TooltipString          = 'keyboard shortcut = 1';
            gui.uiButtons(4).TooltipString          = 'keyboard shortcut = 2';
            gui.uiButtons(5).TooltipString          = 'keyboard shortcut = 3';
            gui.uiButtons(6).TooltipString          = 'keyboard shortcut = 4';
            
            % SET CONTENTPANEL
            gui.contentPanel = ScrollPanel(gui.vanellusGUI.fig);
            
            % SET SIDEPANEL
            gui.sidePanel                           = uipanel(gui.vanellusGUI.fig);
            gui.sidePanel.BackgroundColor           = gui.vanellusGUI.CONTROLPANEL_BGCOLOR;
            gui.sidePanel.BorderType                = 'none';
            gui.sidePanel.Units                     = 'pixels';
            gui.sidePanel.Visible                   = 'off';
            
            gui.uiButtons(51)                       = uicontrol(gui.sidePanel);
            gui.uiButtons(51).Style                 = 'pushbutton';
            gui.uiButtons(51).String                = 'Analyze';
            gui.uiButtons(51).Callback              = @gui.actionAnalyzeButtonPressed;
    
            gui.uiTexts(51)                         = uicontrol(gui.sidePanel);
            gui.uiTexts(51).Style                   = 'text';
            gui.uiTexts(51).String                  = 'Min';
            gui.uiTexts(51).BackgroundColor         = gui.sidePanel.BackgroundColor;
            gui.uiTexts(51).HorizontalAlignment     = 'left';

            gui.uiTexts(52)                         = copyobj(gui.uiTexts(1), gui.sidePanel);
            gui.uiTexts(52).String                  = 'Max';                                  

            gui.uiButtons(52)                       = uicontrol(gui.sidePanel);
            gui.uiButtons(52).Style                 = 'checkbox';
            gui.uiButtons(52).Value                 = 1;
            gui.uiButtons(52).BackgroundColor       = gui.sidePanel.BackgroundColor;
            gui.uiButtons(52).Callback              = @gui.guiUpdate;            
            
            gui.uiTexts(53)                         = copyobj(gui.uiTexts(1), gui.sidePanel);
            gui.uiTexts(53).String                  = 'Size change (pixels)';                                  
            
            gui.uiEdits(51)                         = uicontrol(gui.sidePanel);
            gui.uiEdits(51).Style                   = 'edit';
            gui.uiEdits(51).String                  = VTrackingsAnalysis.DEFAULT_SETTINGS_SIZECHANGE(1);

            gui.uiEdits(52)                         = copyobj(gui.uiEdits(1), gui.sidePanel);
            gui.uiEdits(52).String                  = VTrackingsAnalysis.DEFAULT_SETTINGS_SIZECHANGE(2);

            gui.uiListboxes                         = uicontrol(gui.sidePanel);
            gui.uiListboxes(1).Style                = 'listbox';
            gui.uiListboxes(1).Min                  = 0;
            gui.uiListboxes(1).Max                  = 2;
            gui.uiListboxes(1).Value                = [];
            gui.uiListboxes(1).String               = {''};
            gui.uiListboxes(1).Callback             = @gui.actionShowCell;                  
        end

        function guiPositionUpdate(gui, ~, ~)
            % SET CONTROLPANEL BUTTONS
            % Position coordinates: [left bottom width height]
            
            gui.uiTogglePanels(1).Position  = [ 10 200 280 120]; % Display
            gui.uiTexts(1).Position         = [ 58  90  60  15];
            gui.uiButtons(1).Position       = [ 10  70  40  20];
            gui.uiEdits(1).Position         = [ 55  70  40  20];
            gui.uiButtons(2).Position       = [100  70  40  20];
            gui.uiEdits(2).Position         = [ 55  45  40  20];
            gui.uiButtons(3).Position       = [180  85  80  20];
            gui.uiButtons(4).Position       = [180  60  80  20];
            gui.uiButtons(5).Position       = [180  35  80  20];
            gui.uiButtons(6).Position       = [180  10  80  20];            
            gui.uiButtons(7).Position       = [ 80  10  80  20];            

            gui.uiTogglePanels(2).Position  = [ 10 200 280  50]; % Edit
            gui.uiButtons(11).Position      = [ 10  10  80  20];
            gui.uiButtons(14).Position      = [100  10  50  20];

            gui.uiTogglePanels(3).Position  = [ 10 200 280  50];% Analysis
            gui.uiButtons(21).Position      = [ 10  10  80  20];
            gui.uiButtons(22).Position      = [100  10  80  20];
            gui.uiButtons(23).Position      = [190  10  80  20];
            
            gui.uiTogglePanels(4).Position  = [ 10 200 280 100];% Click Behavior
            gui.uiTexts(31).Position        = [ 10  65 160  15];
            gui.uiTexts(32).Position        = [ 10  40 160  15];
            gui.uiTexts(33).Position        = [ 10  15 160  15];

            gui.uiTogglePanels(5).Position  = [ 10 200 280 280];    % Relevant Settings Panel        
            gui.uiTables(1).Position        = [ 10  10 260 250];
            
            % SET SIDEPANEL POSITIONS
            sidePanelPosition               = gui.sidePanel.Position; %[left bottom width height]
            gui.uiButtons(51).Position      = [ 10 sidePanelPosition(4)-30  80  20];
            
            gui.uiTexts(51).Position        = [170 sidePanelPosition(4)-40  80  20];
            gui.uiTexts(52).Position        = [230 sidePanelPosition(4)-40  80  20];
            
            gui.uiButtons(52).Position      = [ 10 sidePanelPosition(4)-60+2  15  15];
            gui.uiTexts(53).Position        = [ 30 sidePanelPosition(4)-60-4 120  20];
            gui.uiEdits(51).Position        = [160 sidePanelPosition(4)-60  40  21];
            gui.uiEdits(52).Position        = [220 sidePanelPosition(4)-60  40  21];
            
            gui.uiListboxes(1).Position     = [ 10 10 sidePanelPosition(3)-20 sidePanelPosition(4)-80];
            
            % INITIALIZE TOGGLE PANELS
            gui.guiInitializeTogglePanels();            
        end

        function guiUpdate(gui, ~, ~)
            % make sure currentFrameIdx is within 1:numel(frames)-1
            if isempty(gui.trackings.frames)
                warning(['GUITrackings.guiUpdate() -> no frames are selected']);
                gui.currentFrameIdx = 1;
            end
            if gui.currentFrameIdx < 1 || gui.currentFrameIdx > numel(gui.trackings.frames) - 1
                gui.currentFrameIdx = 1;
            end                

            % UPDATE CONTROLPANEL
            if isempty(gui.trackings.frames)
                gui.uiEdits(1).String   = '-';
                gui.uiEdits(2).String   = '-';
            else
                gui.uiEdits(1).String = gui.trackings.frames(gui.currentFrameIdx);
                gui.uiEdits(2).String = gui.trackings.frames(gui.currentFrameIdx+1);
            end                

            % update settings Table
            [~, ~, combined]            = gui.getSettingsData();
            gui.uiTables(1).RowName     = {};  % settingsList
            gui.uiTables(1).Data        = combined; % data;
            if gui.uiTables(1).Extent(3) < gui.uiTables(1).Position(3), gui.uiTables(1).Position(3) = gui.uiTables(1).Extent(3); end            
            
            % UPDATE CONTENTPANEL (=SCROLLPANEL)
            rgb = gui.getTrackingImage();
            hIm = gui.contentPanel.showImage(rgb, gui.vanellusGUI.currentMagnification);
            set(hIm, 'ButtonDownFcn', @gui.actionImageClicked);
            
            % UPDATE NAVPANEL
            gui.vanellusGUI.guiUpdateNavPanel();
            
            % UPDATE SIDEPANEL
            if strcmp(gui.sidePanel.Visible, 'on')
                if gui.uiButtons(52).Value
                    gui.uiTexts(53).Enable = 'on';
                    gui.uiEdits(51).Enable = 'on';
                    gui.uiEdits(52).Enable = 'on';
                else
                    gui.uiTexts(53).Enable = 'off';
                    gui.uiEdits(51).Enable = 'off';
                    gui.uiEdits(52).Enable = 'off';
                end            
                gui.uiListboxes(1).String = gui.trackingsAnalysis.problems;            
            end
            
            % COLOR RECALCULATE BUTTON, IN CASE SEGMENTATION NEEDS UPDATING
            frame1      = gui.trackings.frames(gui.currentFrameIdx);
            frame2      = gui.trackings.frames(gui.currentFrameIdx+1);
            if gui.trackings.doesDataNeedUpdating( [frame1 frame2] )
                gui.uiButtons(21).BackgroundColor     = [1 0 0];
            else
                gui.uiButtons(21).BackgroundColor     = gui.uiButtons(1).BackgroundColor;
            end
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
            if gui.trackings.region.save()
                if 0 % 2DO: set view to XX
                    gui.uiButtons(1).Value              = 1;
                    gui.uiButtons(2).Value              = 0;
                    gui.uiButtons(21).Value              = 1;
                    gui.uiButtons(4).Value              = 0;
                end
            end
            
            gui.guiUpdate();
        end                
        
        
        %% Controller %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function rgb = getTrackingImage(gui)
 
            % setup output
            segSize     = gui.trackings.region.regionSize;
            rgb1        = repmat(reshape(GUISegmentations.COLOR_BACKGROUND, [1 1 3]), segSize);
            rgb2        = repmat(reshape(GUISegmentations.COLOR_BACKGROUND, [1 1 3]), segSize);

            % get frames
            if isempty(gui.trackings.frames) || gui.currentFrameIdx < 1 || gui.currentFrameIdx > numel(gui.trackings.frames), rgb = rgb1; return; end
            frame1      = gui.trackings.frames(gui.currentFrameIdx);
            frame2      = gui.trackings.frames(gui.currentFrameIdx+1);
            
            % add mask
            if gui.uiButtons(5).Value
                mask1       = gui.trackings.region.getMask( frame1 );
                maskRGB     = repmat(reshape(GUISegmentations.COLOR_MASK, [1 1 3]), segSize);
                idx1        = repmat( mask1, [1 1 3]);
                rgb1(idx1)  = maskRGB(idx1);

                mask2       = gui.trackings.region.getMask( frame2 );
                idx2        = repmat( mask2, [1 1 3]);
                rgb2(idx2)  = maskRGB(idx2);
            end

            % add edge
            if gui.uiButtons(4).Value
                seg1Edge    = gui.trackings.region.segmentations.getSegEdge( frame1 );
                edgeRGB     = repmat(reshape(GUISegmentations.COLOR_EDGE, [1 1 3]), segSize);
                idx1        = repmat( seg1Edge, [1 1 3]);
                rgb1(idx1)  = edgeRGB(idx1);

                seg2Edge    = gui.trackings.region.segmentations.getSegEdge( frame2 ); 
                idx2        = repmat( seg2Edge, [1 1 3]);
                rgb2(idx2)  = edgeRGB(idx2);
            end

            % add seg
            if gui.uiButtons(3).Value
                seg1            = gui.trackings.region.getSeg( frame1 );
                outline1        = GUISegmentations.getOutlineFromSeg( seg1 );
%                 core1           = GUISegmentations.getCoreFromSeg( seg1 );
                seg1_ori        = gui.convertSegToCell(seg1, frame1);
%                 seg1_ori        = GUISegmentations.prepareSeg(seg1_ori);
%                 seg1            = gui.convertSegToCellWithDivision(seg1, frame1);
                seg1            = GUISegmentations.prepareSeg(seg1_ori);
                seg1(outline1)  = GUISegmentations.COLORNR_OUTLINE;
%                 seg1(core1)     = seg1_ori(core1);
                seg1RGB         = ind2rgb(seg1, gui.colorTable);
                idx1            = repmat( logical(seg1), [1 1 3]);
                rgb1(idx1)      = seg1RGB(idx1);

                seg2            = gui.trackings.region.getSeg( frame2 );
                outline2        = GUISegmentations.getOutlineFromSeg( seg2 );
                core2           = GUISegmentations.getCoreFromSeg( seg2 );
                seg2_ori        = gui.convertSegToCell(seg2, frame2);
                seg2_ori        = GUISegmentations.prepareSeg(seg2_ori);
                seg2            = gui.convertSegToCellWithDivision(seg2, frame2);
                seg2            = GUISegmentations.prepareSeg(seg2);
                seg2(outline2)  = GUISegmentations.COLORNR_OUTLINE;
                seg2(core2)     = seg2_ori(core2);
                seg2RGB         = ind2rgb(seg2, gui.colorTable);
                idx2            = repmat( logical(seg2), [1 1 3]);
                rgb2(idx2)      = seg2RGB(idx2);
            end            
            
            % add phase
            if gui.uiButtons(6).Value
                seg1Image   = gui.trackings.region.segmentations.getSegImage( frame1 );
                seg2Image   = gui.trackings.region.segmentations.getSegImage( frame2 );
                rgb1 = VTools.addPhaseOverlayToRGB(rgb1, seg1Image);
                rgb2 = VTools.addPhaseOverlayToRGB(rgb2, seg2Image);
            end
            
            % add seg numbers
            nrDisplayIdx = find( strcmp(gui.NR_DISPLAY_LABELS, gui.uiButtons(7).String) );
            if nrDisplayIdx > 1
                % get rotated seg
                seg1        = gui.trackings.region.getSeg( frame1 );
                seg1        = rot90( seg1, gui.trackings.region.rotationAdditional90Idx);
                seg2        = gui.trackings.region.getSeg( frame2 );
                seg2        = rot90( seg2, gui.trackings.region.rotationAdditional90Idx);
            end
            if nrDisplayIdx == 3
                % convert segnrs into cellnrs
                seg1        = gui.convertSegToCell(seg1, frame1);
                seg2        = gui.convertSegToCell(seg2, frame2);
            elseif nrDisplayIdx == 4
                % convert segnrs into cellnrs in first frame
                seg1        = gui.convertSegToCellWithDivision2(seg1, frame1);
                seg2        = gui.convertSegToCellWithDivision2(seg2, frame2);
            end
            if nrDisplayIdx > 1
                % get nr image and rotate back
                seg1Nrs     = GUISegmentations.getSegNrsImFromSeg( seg1 );
                seg1Nrs     = rot90( seg1Nrs, -gui.trackings.region.rotationAdditional90Idx);
                seg2Nrs     = GUISegmentations.getSegNrsImFromSeg( seg2 );
                seg2Nrs     = rot90( seg2Nrs, -gui.trackings.region.rotationAdditional90Idx);

                seg1NrsRGB  = repmat(reshape(GUISegmentations.COLOR_EDGE, [1 1 3]), segSize);
                idx         = repmat( seg1Nrs, [1 1 3]);
                rgb1( idx ) = seg1NrsRGB( idx );
                seg2NrsRGB  = repmat(reshape(GUISegmentations.COLOR_EDGE, [1 1 3]), segSize);
                idx         = repmat( seg2Nrs, [1 1 3]);
                rgb2( idx ) = seg2NrsRGB( idx );
            end

            
            % apply additional region rotation (only for visualization)
            rotationAdditional90Idx = gui.trackings.region.rotationAdditional90Idx;
            if rotationAdditional90Idx ~= 4
                rgb1 = VTools.rot90_3D(rgb1, rotationAdditional90Idx);
                rgb2 = VTools.rot90_3D(rgb2, rotationAdditional90Idx);
            end
            
            % combine rgb1 and rgb2
            combinedSize    = uint16([2 1]) .* uint16( gui.trackings.region.rotatedRegionSize ) + uint16([GUITrackings.SEG_DIVIDER_HEIGHT 0]);
            rgb(1,1,:) = gui.contentPanel.contentPanel.BackgroundColor; % set divider to panel background color
            rgb = repmat(rgb, combinedSize);
            rgb(1:gui.trackings.region.rotatedRegionSize(1), :, :)                                     = rgb1;
            rgb(gui.trackings.region.rotatedRegionSize(1)+GUITrackings.SEG_DIVIDER_HEIGHT+1:end, :, :)  = rgb2;
        end
        
        function [settingsList, data, combined] = getSettingsData(gui) 
            settings        = gui.trackings.getCurrentDefaultSettings();
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

        
        %% Key or Image Clicked %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function actionKeyPressed(gui, ~, eventdata)
            switch upper(eventdata.Key)
                case {'LEFTARROW','COMMA'}
                    gui.actionChangeFrame(gui.uiButtons(1));
                case {'RIGHTARROW','PERIOD'}
                    gui.actionChangeFrame(gui.uiButtons(2));
                    
%                 case {'P'}
%                     disp(['Clicked key: ' eventdata.Key ' -> Pixel']);
%                     gui.actionChangeClickBehavior( gui.uiButtons(52) );
%                 case {'L'}
%                     disp(['Clicked key: ' eventdata.Key ' -> Line']);
%                     gui.actionChangeClickBehavior( gui.uiButtons(23) );
%                 case {'A'}
%                     disp(['Clicked key: ' eventdata.Key ' -> Area']);
%                     gui.actionChangeClickBehavior( gui.uiButtons(14) );
%                 case {'E'}
%                     disp(['Clicked key: ' eventdata.Key ' -> Edgefill']);
%                     gui.actionChangeClickBehavior( gui.uiButtons(15) );
%                 case {'C'}
%                     disp(['Clicked key: ' eventdata.Key ' -> Connected area']);
%                     gui.actionChangeClickBehavior( gui.uiButtons(16) );
                    
                case {'R'}
                    disp(['Clicked key: ' eventdata.Key ' -> recoloring']);
                    gui.actionRecolorButtonPressed();
                case {'U'}
                    disp(['Clicked key: ' eventdata.Key ' -> Undo']);
                    frame1      = gui.trackings.frames(gui.currentFrameIdx);
                    frame2      = gui.trackings.frames(gui.currentFrameIdx+1);
                    tf = gui.trackings.undo( [frame1 frame2] );
                    if tf
                        % update local frameTracks
                        gui.trackings.frameTracks{gui.currentFrameIdx} = gui.trackings.getData([frame1 frame2]);
                        gui.trackings.region.tree.calcTree(); % need to do this, because gui.calcTree calls updateTree, which does not work after undo (as timestamp is old)
                        gui.calcTree(); 
                        gui.guiUpdate();
                    end
                case {'S'}
                    disp(['Clicked key: ' eventdata.Key ' -> saving']);
                    gui.actionSaveRegion();
                    
                case {'BACKQUOTE'}
                    disp(['Clicked key: ' eventdata.Key ' -> toggling # in Display']);
                    gui.actionChangeNrDisplay();
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
        end        
        
        function actionImageClicked(gui, hObject, ~)
            mouseButtonType     = get(gui.vanellusGUI.fig, 'SelectionType');
            contentPanelAx      = findall(gui.contentPanel.contentPanel, 'type', 'axes');
            hIm                 = contentPanelAx.Children;

            if hObject == hIm
                coor = uint16(get(contentPanelAx,'CurrentPoint')); % returns [col row]
                coor = coor(1,[2 1]); 
                % disp(['Screen coordinates             : (' num2str(coor(1)) ',' num2str(coor(2)) ') [ T, L ] ']);
                
                % first determine in which of the two frames was clicked
                frameClicked = 0;
                if coor(1) <= gui.trackings.region.rotatedRegionSize(1)
                    frameClicked = 1;
                    frameCoor = coor;
                    % disp('in frame1');
                elseif coor(1) > gui.trackings.region.rotatedRegionSize(1) + GUITrackings.SEG_DIVIDER_HEIGHT
                    frameClicked = 2;
                    frameCoor = coor - uint16( [(gui.trackings.region.rotatedRegionSize(1) + GUITrackings.SEG_DIVIDER_HEIGHT) 0] );
                    % disp('in frame2');
                else
                    disp('Not clicked inside frame');
                    return;
                end
                
                % in case image was shown with additional region rotation, will need to convert coor
                frameCoor = VTools.rotateCoordinates( frameCoor, gui.trackings.region.rotationAdditional90Idx, gui.trackings.region.regionSize); 
                % disp(['Rotated Screen coordinates     : (' num2str(frameCoor(1)) ',' num2str(frameCoor(2)) ') [ L, T ] ']);
                
                if mouseButtonType(1)=='n' % normal = left mouse button
                    if isempty( gui.prevClickCoorAndFrame )
                        % first click
                        disp(['Clicked mouse : left -> linking 2 cells together, 1st click at @ ' num2str(frameCoor)]);
                        gui.prevClickCoorAndFrame = [frameCoor frameClicked];
                    else
                        % second click
                        disp(['Clicked mouse : left -> linking 2 cells together, 2nd click at @ ' num2str(frameCoor)]);
                        if frameClicked ~= gui.prevClickCoorAndFrame(3)
                            frame1  = gui.trackings.frames(gui.currentFrameIdx);
                            frame2  = gui.trackings.frames(gui.currentFrameIdx+1);
                            if frameClicked == 1
                                coor1 = frameCoor;
                                coor2 = gui.prevClickCoorAndFrame(1:2);
                            else
                                coor1 = gui.prevClickCoorAndFrame(1:2);
                                coor2 = frameCoor;
                            end
                            
                            tf = gui.trackings.editBylinkingCells(coor1, coor2, frame1, frame2);
                            if tf, gui.calcTree(); end
                        else
                            disp(['Clicked the same frame twice -> not doing anything']);
                        end
                        gui.prevClickCoorAndFrame   = [];
                    end                    

                elseif mouseButtonType(1)=='a' % alternate = ctrl+left button or right mouse button
                    disp(['Clicked mouse : right  -> clicked in frame ' num2str(frameClicked) ' @ ' num2str(frameCoor)]);
                    
                    if frameClicked
                        frame1  = gui.trackings.frames(gui.currentFrameIdx);
                        frame2  = gui.trackings.frames(gui.currentFrameIdx+1);
                        coor1 = []; coor2 = []; 
                        if frameClicked == 1, coor1 = frameCoor; end
                        if frameClicked == 2, coor2 = frameCoor; end

                        tf = gui.trackings.editByUnlinkingCell(coor1, coor2, frame1, frame2);
                        if tf, gui.calcTree(); end
                    end                    
                    
                elseif mouseButtonType(1)=='e' % extend = shift+left button
                    disp(['Clicked mouse : shift+left -> not doing anything for the moment @ ' num2str(coor)]);
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
                frame = str2double(get(gui.uiEdits(1), 'String'));
                if ~isnan(frame)
                    idx = find(gui.trackings.frames==frame);
                    if ~isempty(idx)
                        gui.currentFrameIdx =idx(1);
                    end
                end
            elseif hObject == gui.uiButtons(1) && gui.currentFrameIdx > 1
                gui.currentFrameIdx = gui.currentFrameIdx - 1;
            elseif hObject == gui.uiButtons(2) && gui.currentFrameIdx < length(gui.trackings.frames) - 1
                gui.currentFrameIdx = gui.currentFrameIdx + 1;
            end
            gui.vanellusGUI.removeFocusFromObject(hObject); % remove focus from edit box / button
            gui.guiUpdate();
        end        
        
        function actionSaveRegion(gui, ~, ~)
            gui.trackings.region.save();
            gui.guiUpdate();
        end

        function actionRecalculateButtonPressed(gui, ~, ~)
            frame1      = gui.trackings.frames(gui.currentFrameIdx);
            frame2      = gui.trackings.frames(gui.currentFrameIdx+1);

            gui.trackings.calcAndSetData( [frame1 frame2] );
            gui.calcTree();
            gui.guiUpdateColorTable();
            gui.guiUpdate();
        end        

        function actionSaveButtonPressed(gui, ~, ~)
            disp('XX');
            gui.guiUpdate();
        end        

        function actionShowHelp(gui, ~, ~)
            disp('------------------------------------------------------------------');
            disp('* GUITrackings ------------------------------------------------');
            disp('  - LEFT MOUSE BUTTON  : Link cells');
            disp('  - RIGHT MOUSE BUTTON : Unlink cell');
            disp('');
            disp('  - KEYBOARD Q         : Exit');
            disp('');
            disp('  - KEYBOARD , / .     : Prev frame / Next frame');
            disp('------------------------------------------------------------------');
        end
        
        function actionEditedTable(gui, ~, eventdata)
            if isempty(eventdata.Indices), return; end % avoid error when changing display while cell is selected
            
            if eventdata.Indices(2) == 2 % only respond to clicks in 2nd column
                [settingsList, ~, ~] = gui.getSettingsData(); 
                settingName = settingsList{eventdata.Indices(1)};
                
                if isempty(settingName), return; end % avoid empty row error
                
                try
                    oldValue = gui.trackings.get(settingName);
                    newValue = eventdata.NewData;
                    
                    if ischar(oldValue), newValue = ['''' newValue '''']; end
                    if isnumeric(oldValue), newValue = ['[' newValue ']']; end
                    eval(['gui.trackings.set(''' settingName ''', ' newValue ');']);
                    disp([ settingName ' changed']);
                catch
                    warning(['GUITrackings: something went wrong while trying to change a setting.']);
                end
            end
            gui.guiUpdate();
        end
        
        function actionChangeNrDisplay(gui, ~, ~)
            idx = find( strcmp(gui.NR_DISPLAY_LABELS, gui.uiButtons(7).String) );
            if isempty(idx), idx = 1; end
            idx = idx + 1;
            if idx > numel(gui.NR_DISPLAY_LABELS), idx = 1; end
            gui.uiButtons(7).String             = gui.NR_DISPLAY_LABELS{idx};
            gui.guiUpdate();
        end        
        
        function actionToggleAnalyze(gui, ~, ~)
            if gui.uiButtons(22).Value
                gui.trackingsAnalysis           = VTrackingsAnalysis( gui.trackings );
                gui.sidePanel.Visible           = 'on';
            else
                gui.trackingsAnalysis           = [];
                gui.sidePanel.Visible           = 'off';
            end
            gui.vanellusGUI.guiPositionUpdate();
        end
        
        function actionAnalyzeButtonPressed(gui, ~, ~)
            % indicate that GUI is working
            gui.vanellusGUI.fig.Pointer = 'watch';
            drawnow;
            
            micronPerPixel = gui.trackings.get('img_micronPerPixel');
            sizeChange(1) = str2double( gui.uiEdits(51).String ) * micronPerPixel;
            sizeChange(2) = str2double( gui.uiEdits(52).String ) * micronPerPixel;

            gui.trackingsAnalysis.actionAnalyze( gui.uiButtons(52).Value, sizeChange);

            gui.guiUpdate();

            % indicate that GUI is finished
            gui.vanellusGUI.fig.Pointer = 'arrow';            
        end
        
        function actionShowCell(gui, hObject, ~)
            idx = get(hObject,'Value');
            if isempty(idx), return; end % no line selected
            idx = idx(1); % avoid error when multiple lines are selected
            if idx > length(gui.trackingsAnalysis.problems), return; end % should not happen
            
            % extract frame
            frame = str2double(regexpi(gui.trackingsAnalysis.problems{idx},'Fr (\d+).*','tokens','once'));
            
            % tell parent to go to frame
            idx = find( gui.trackings.frames==frame );
            if ~isempty(idx)
                gui.currentFrameIdx =idx(1);
                gui.guiUpdate();
            end            
        end        
        
        function actionCompileButtonPressed(gui, ~, ~)
            % indicate that GUI is working
            gui.vanellusGUI.fig.Pointer = 'watch';
            drawnow;
            
            gui.trackings.region.tree.calcAllData();

            gui.guiUpdate();

            % indicate that GUI is finished
            gui.vanellusGUI.fig.Pointer = 'arrow';            
        end
        
        function actionRecolorButtonPressed(gui, ~, ~)
            gui.guiUpdateColorTable();
            gui.guiUpdate();
        end        
        
        function actionUndoButtonPressed(gui, ~, ~)
            frame1      = gui.trackings.frames(gui.currentFrameIdx);
            frame2      = gui.trackings.frames(gui.currentFrameIdx+1);
            tf          = gui.trackings.undo( [frame1 frame2] );
            if tf
                % update local frameTracks
                gui.trackings.frameTracks{gui.currentFrameIdx} = gui.trackings.getData([frame1 frame2]);
                gui.trackings.region.tree.calcTree(); % need to do this, because gui.calcTree calls updateTree, which does not work after undo (as timestamp is old)
                gui.calcTree(); 
                gui.guiUpdate();
            end
        end
        
        function delete(gui)
            delete( gui.trackingsAnalysis );
        end
        
        
        %% Tree coloring %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function calcTree(gui)
            gui.trackings.region.tree.updateTree();
            gui.seg2cell = gui.trackings.region.tree.seg2cell;
            gui.seg2parent = gui.trackings.region.tree.seg2parent;
            
%            [gui.seg2cell, gui.seg2parent] = gui.trackings.calcColorTools();
%            [~, gui.segToCell] = gui.trackings.calcTree();
%            gui.segToCellWithDivision = gui.trackings.calcSegToCellWithDivision();
        end
        
        function seg_out = convertSegToCell(gui, seg, frame)
            % seg2cell        { frame }  ( segno )  = cellno
            seg_out = seg;
            us = setdiff(unique(seg),[0]);
            for u = reshape(us,1,length(us))
                if frame <= numel(gui.seg2cell) && u <= numel( gui.seg2cell{frame} )
                    seg_out(seg==u) = gui.seg2cell{frame}(u);
                end
            end
        end
        
        function seg_out = convertSegToCellWithDivision(gui, seg, frame)
            % seg2parent      { frame }  ( segno )  = cellno (with cellno = parent_cellno in first frame)
            seg_out = seg;
            us = setdiff(unique(seg),[0]);
            for u = reshape(us,1,length(us))
                if frame <= numel(gui.seg2parent) && u <= numel( gui.seg2parent{frame} )
                    seg_out(seg==u) = gui.seg2parent{frame}(u);
                end
            end
        end        
       
        function seg_out = convertSegToCellWithDivision2(gui, seg, frame)
            % seg2cell        { frame }  ( segno )  = cellno
            % seg2parent      { frame }  ( segno )  = cellno (with cellno = parent_cellno in first frame)
            seg_out = zeros(size(seg));
            us = setdiff(unique(seg),[0]);
            for u = reshape(us,1,length(us))
                if frame <= numel(gui.seg2cell) && u <= numel( gui.seg2cell{frame} ) && frame <= numel(gui.seg2parent) && u <= numel( gui.seg2parent{frame} )
                    if gui.seg2cell{frame}(u) ~= gui.seg2parent{frame}(u)
                        seg_out(seg==u) = gui.seg2cell{frame}(u);
                    end
                end
            end
        end        
        
        
    end
end
