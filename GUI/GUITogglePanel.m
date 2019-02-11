classdef (Abstract) GUITogglePanel < handle %% C
% GUITogglePanel
%
% uiPanels(1).UserData(2) = 100    (height of opened uipanel)

% Copyright Daan Kiviet 2018-
% Version : 2017-03-07

    properties (Constant)
        UIPANEL_Y_SPACING           = 10;
    end
    
    properties (Abstract, Transient) % not stored
        controlPanel
        uiTogglePanels
    end

    methods (Sealed)        
        
        %% updating position of togglePanels %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function guiUpdateTogglePanels(gui)

            % Position coordinates: [left bottom width height]
            currentTop  = gui.controlPanel.Position(4) - gui.UIPANEL_Y_SPACING;
            
            for i = 1:length(gui.uiTogglePanels)
                % in case empty, move to next one
                if isa( gui.uiTogglePanels(i), 'matlab.graphics.GraphicsPlaceholder'), continue; end

                gui.uiTogglePanels(i).Position(4)       = gui.uiTogglePanels(i).UserData(2);
                gui.uiTogglePanels(i).Position(2)       = currentTop - gui.uiTogglePanels(i).Position(4);
                currentTop                              = currentTop - gui.uiTogglePanels(i).Position(4) - gui.UIPANEL_Y_SPACING;
            end
        end
        
        function guiInitializeTogglePanels(gui)
            % loop over togglePanels
            for i = 1:length(gui.uiTogglePanels)
                % in case empty, move to next one
                if isa( gui.uiTogglePanels(i), 'matlab.graphics.GraphicsPlaceholder'), continue; end
                
                % store heights
                gui.uiTogglePanels(i).UserData  = [1 gui.uiTogglePanels(i).Position(4)]; % [toggledOn height]
            end
            
            % update togglePanels
            gui.guiUpdateTogglePanels();
        end
    end
end
