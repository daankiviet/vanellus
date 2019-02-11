classdef ScrollPanel < handle %% C
% ScrollPanel Object

% Copyright Daan Kiviet 2018-
% Version : 2017-03-07

    properties (Constant = true)
        SCROLLBAR_WIDTH         = 16;
    end
    
    properties (Transient)
        panel
        scrollPanel
        contentPanel

        scrollBarX
        scrollBarY
    end

    properties (Dependent)
        Position
    end
    
    methods
        %% loading and gui building / updating %%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function gui = ScrollPanel(parent, contentPanel)
            if nargin < 1
                error(['ScrollPanel requires a parent (figure or panel) and content panel as arguments']);
            end
            if nargin < 2
                contentPanel            = uipanel();
                contentPanel.Units      = 'Pixels';
                contentPanel.BorderType = 'none';
                contentPanel.Position   = [1 1 100 100];
            end
            
            gui.guiBuild(parent);
            gui.guiContentPanelUpdate(contentPanel);
        end
        
        function guiBuild(gui, parent)
            gui.panel                   = uipanel();
            gui.panel.Parent            = parent;
            gui.panel.BackgroundColor   = 'white';
            gui.panel.BorderType        = 'none';
            gui.panel.Units             = 'pixels';

            gui.scrollPanel             = uipanel();
            gui.scrollPanel.Parent      = gui.panel;
            gui.scrollPanel.Units       = 'Pixels';
            gui.scrollPanel.BorderType  = 'none';

            gui.scrollBarX              = uicontrol();
            gui.scrollBarX.Style        = 'Slider';
            gui.scrollBarX.Parent       = gui.panel;
            gui.scrollBarX.Min          = 0;
        	gui.scrollBarX.Max          = 1;
            gui.scrollBarX.Value        = 0;
            gui.scrollBarX.Callback     = @gui.guiScrollPanelUpdate;

            gui.scrollBarY              = uicontrol();
            gui.scrollBarY.Style        = 'Slider';
            gui.scrollBarY.Parent       = gui.panel;
            gui.scrollBarY.Min          = 0;
        	gui.scrollBarY.Max          = 1;
            gui.scrollBarY.Value        = 0;
            gui.scrollBarY.Callback     = @gui.guiScrollPanelUpdate;            
        end

        function guiContentPanelUpdate(gui, contentPanel)
            contentPanel.Parent         = gui.scrollPanel;
            addlistener(contentPanel, 'SizeChanged', @(src, event) gui.guiScrollPanelUpdate(src, event) );

            gui.contentPanel = contentPanel;

            gui.guiPositionUpdate();
            gui.guiScrollPanelUpdate();
        end         
        
        function guiPositionUpdate(gui, hObject, eventdata)
            gui.scrollPanel.Position    = [ 1                                                       ...
                                            1 + ScrollPanel.SCROLLBAR_WIDTH                         ...
                                            gui.panel.Position(3) - ScrollPanel.SCROLLBAR_WIDTH     ...
                                            gui.panel.Position(4) - ScrollPanel.SCROLLBAR_WIDTH];
            gui.scrollBarX.Position     = [ 1                                                       ...
                                            1                                                       ...
                                            gui.panel.Position(3) - ScrollPanel.SCROLLBAR_WIDTH     ...
                                            ScrollPanel.SCROLLBAR_WIDTH];
            gui.scrollBarY.Position     = [ gui.panel.Position(3) - ScrollPanel.SCROLLBAR_WIDTH     ...
                                            1 + ScrollPanel.SCROLLBAR_WIDTH                         ...
                                            ScrollPanel.SCROLLBAR_WIDTH                             ...
                                            gui.panel.Position(4) - ScrollPanel.SCROLLBAR_WIDTH]; 
        end

        function guiScrollPanelUpdate(gui, hObject, eventdata)
            visibleSize         = gui.scrollPanel.Position(3:4);
            contentPanelSize    = gui.contentPanel.Position(3:4);
            invisibleSize       = contentPanelSize - visibleSize;

            valX = gui.scrollBarX.Value;
            valY = gui.scrollBarY.Value;

            if invisibleSize(1) <= 1, valX = 0.5; end
            if invisibleSize(2) <= 1, valY = 0.5; end
            
            gui.contentPanel.Position = [   1 - valX*invisibleSize(1)       ...
                                            1 - valY*invisibleSize(2)       ...
                                            gui.contentPanel.Position(3)    ...
                                            gui.contentPanel.Position(4) ];

            fractionVisible = min([1 1], visibleSize ./ contentPanelSize);
            sliderstep2 = fractionVisible ./ (1 - fractionVisible);
            
            gui.scrollBarX.SliderStep = [0.1 sliderstep2(1)];
            gui.scrollBarY.SliderStep = [0.1 sliderstep2(2)];

            if invisibleSize(1) <= 1 
                gui.scrollBarX.Visible = 'off';
                gui.scrollPanel.Position(2) = 1; 
                gui.scrollPanel.Position(4) = gui.panel.Position(4);
                gui.scrollBarY.Position(2) = 1;
                gui.scrollBarY.Position(4) = gui.panel.Position(4); 
            else
                gui.scrollBarX.Visible = 'on';
                gui.scrollPanel.Position(2) = 1 + ScrollPanel.SCROLLBAR_WIDTH;
                gui.scrollPanel.Position(4) = gui.panel.Position(4) - ScrollPanel.SCROLLBAR_WIDTH;
                gui.scrollBarY.Position(2) = 1 + ScrollPanel.SCROLLBAR_WIDTH;
                gui.scrollBarY.Position(4) = gui.panel.Position(4) - ScrollPanel.SCROLLBAR_WIDTH; 
            end
            
            if invisibleSize(2) <= 1
                gui.scrollBarY.Visible = 'off';
                gui.scrollPanel.Position(3) = gui.panel.Position(3);
                gui.scrollBarX.Position(3) = gui.panel.Position(3);
            else
                gui.scrollBarY.Visible = 'on';
                gui.scrollPanel.Position(3) = gui.panel.Position(3) - ScrollPanel.SCROLLBAR_WIDTH;
                gui.scrollBarX.Position(3) = gui.panel.Position(3) - ScrollPanel.SCROLLBAR_WIDTH;
            end
            
        end        

        function gui = set.Position(gui, value)
            gui.panel.Position = value;
            gui.guiPositionUpdate();
            gui.guiScrollPanelUpdate();
        end
        
        function value = get.Position(gui)
            value = gui.panel.Position;
        end 
        
        function centerPanel(gui)
            gui.scrollBarX.Value = 0.5;
            gui.scrollBarY.Value = 0.5;
            
            gui.guiScrollPanelUpdate();
        end
        
        function hIm = showImage(gui, rgb, magnification)
            if nargin < 3, magnification = 1; end
            
            newContentPanelSize = round(magnification * [size(rgb,2) size(rgb,1)]);
            gui.contentPanel.Position               = [1 1 newContentPanelSize(1) newContentPanelSize(2)];

            contentPanelAx                          = findall(gui.contentPanel, 'type', 'axes');
            if isempty(contentPanelAx)
                contentPanelAx = axes('parent', gui.contentPanel, 'Units', 'Pixels'); 
            end
            contentPanelAx.Position                 = [1 1 newContentPanelSize(1) newContentPanelSize(2)];
            
            if magnification*size(rgb,1)*size(rgb,2)*magnification > 2500*2500
                warning(['ScrollPanel: Reducing magnfication in order to avoid crash. image size = ' num2str([size(rgb,1) size(rgb,2)]) '. Display Size = ' num2str(magnification*[size(rgb,1) size(rgb,2)])]);
                magnification = sqrt( 2500*2500 / (size(rgb,1)*size(rgb,2)));
            end
            
            hIm = imshow(rgb, 'Parent', contentPanelAx, 'initialMagnification', magnification, 'Border', 'tight');
            gui.guiScrollPanelUpdate();
        end
        
        function showPlot(gui, magnification)
            if nargin < 2, magnification = 1; end
            rgb = ones([300 300]);
            
            newContentPanelSize = round(magnification * [size(rgb,2) size(rgb,1)]);
            gui.contentPanel.Position               = [1 1 newContentPanelSize(1) newContentPanelSize(2)];

            contentPanelAx                          = findall(gui.contentPanel, 'type', 'axes');
            if isempty(contentPanelAx)
                contentPanelAx = axes('parent', gui.contentPanel, 'Units', 'Pixels'); 
            end
            contentPanelAx.Position                 = [40 40 newContentPanelSize(1)-40 newContentPanelSize(2)-40];
            
            if magnification*size(rgb,1)*size(rgb,2)*magnification > 2500*2500
                warning(['ScrollPanel: Reducing magnfication in order to avoid crash. image size = ' num2str([size(rgb,1) size(rgb,2)]) '. Display Size = ' num2str(magnification*[size(rgb,1) size(rgb,2)])]);
                magnification = sqrt( 2500*2500 / (size(rgb,1)*size(rgb,2)));
            end
            
            plot(contentPanelAx, [1:5], [5:-1:1]);
            xlabel(contentPanelAx,'test');
            gui.guiScrollPanelUpdate();
        end

        function showPlot2(gui, contentPanel, magnification)
            if nargin < 2, magnification = 1; end
            rgb = ones([300 300]);
            
            gui.contentPanel = contentPanel;
            newContentPanelSize = round(magnification * [size(rgb,2) size(rgb,1)]);
            gui.contentPanel.Position               = [1 1 newContentPanelSize(1) newContentPanelSize(2)];

            contentPanelAx                          = findall(gui.contentPanel, 'type', 'axes');
            if isempty(contentPanelAx)
                contentPanelAx = axes('parent', gui.contentPanel, 'Units', 'Pixels'); 
            end
            contentPanelAx.Position                 = [40 40 newContentPanelSize(1)-40 newContentPanelSize(2)-40];

            gui.guiScrollPanelUpdate();
        end
        
    end
end