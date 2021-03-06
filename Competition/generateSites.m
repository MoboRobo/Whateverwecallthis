function [pullSites, dropSites] = generateSites(real)
global ft
    if real
        pullSites = [
            pose(6*ft, -4*ft, 0),...
            pose(6*ft, -5*ft, 0),...
            pose(6*ft, -3*ft, 0),...
            pose(6*ft, -2*ft, 0),...
            pose(6*ft, -1*ft, 0),...
            ...
            pose(11*ft, -7*ft, 0),...
            pose(11*ft, -6*ft, 0),...
            ...
            pose(6*ft, -6*ft, 0),... % 7 is too close
            pose(2*ft, -7*ft, -pi/2),...
            pose(3*ft, -7*ft, -pi/2),...
            pose(4*ft, -7*ft, -pi/2)...
        ];
        pullSites = [pullSites pullSites]; % Double

        startDropY = -1.5*ft; dropYIncrement = -0.75*ft;

        dropSites = [
            pose(1*ft+0.12, startDropY +3*dropYIncrement, pi), ... 
            pose(1*ft+0.12, startDropY +4*dropYIncrement, pi), ...
            pose(1*ft+0.12, startDropY +2*dropYIncrement, pi),...
            pose(1*ft+0.12, startDropY +1*dropYIncrement, pi),...
            pose(1*ft+0.12, startDropY +0*dropYIncrement, pi),...
            pose(1*ft+0.12, startDropY +5*dropYIncrement, pi),...
            pose(1*ft+0.12, startDropY +6*dropYIncrement, pi)
        ];
        dropSites = [dropSites dropSites];
    else
        pullSites = [
            pose(6*ft, -4*ft, 0),...
            pose(6*ft, -3*ft, 0),...
            pose(6*ft, -2*ft, 0),...
            pose(6*ft, -5*ft, 0),...
            pose(6*ft, -6*ft, 0),...
            pose(6*ft, -1*ft, 0),...
            ...
            pose(11*ft, -7*ft, 0),...
            pose(11*ft, -6*ft, 0),...
            ...
            pose(6*ft, -7*ft, 0),... % 7 is too close
            pose(2*ft, -7*ft, -pi/2),...
            pose(3*ft, -7*ft, -pi/2),...
            pose(4*ft, -7*ft, -pi/2)...
        ];
        pullSites = [pullSites pullSites]; % Double

        startDropY = -1.5*ft; dropYIncrement = -0.75*ft;

        dropSites = [
            pose(1*ft+0.12, startDropY +0*dropYIncrement, pi), ... 
            pose(1*ft+0.12, startDropY +1*dropYIncrement, pi), ...
            pose(1*ft+0.12, startDropY +2*dropYIncrement, pi),...
            pose(1*ft+0.12, startDropY +3*dropYIncrement, pi),...
            pose(1*ft+0.12, startDropY +4*dropYIncrement, pi),...
            pose(1*ft+0.12, startDropY +5*dropYIncrement, pi),...
            pose(1*ft+0.12, startDropY +6*dropYIncrement, pi)
        ];
        dropSites = [dropSites dropSites];
    end
end % #generateSites