% function [RefinedCenters, Vars,varargout] = FindRefinedSpotCenters(imgs,spots,bkgnd_tolerance,params,debug)
%
% Given a frame (best to have it be an average of ~10 frames) and the locations of
% bright pixels identified as spots in that movie, fit a 2D Gaussian to 
% each spot to obtain a sub-pixel location of the center and variance of
% each spot. 
%
% The assumption is that this is called separately on spots in each
% channel.
%
% This also implements several further refinements of spots that used to be
% part of FindSpotsV5: (1) check that the new spot center isn't too far
% away from the old one; (2) check that each spot is surrounded by a
% sufficiently low background; (3) check that the maximum isn't just one
% pixel big.
%
% Inputs:
% imgs: x-by-y or x-by-y-by-frame total fields of view in which spots have
%   already been located
% spots: (x,y)-by-number locations of spots in imgs
% bkgnd_tolerance: mean intensity value around the spot has to go to less than the
    % fitted background value plus this tolerance. For beads, a good number is 0.01;
    % for DNAs with background subtracted, 0.01 is also good; for non-background subtracted,
    % 0.2 is better.
% params: file saved by smFRETsetup
% debug: If this is 1, plots the figures in Fit2DGaussToSpot. Default is 0.
%
% Outputs:
% RefinedCenters: (xcen,ycen)-by-spots sub-pixel resolution spot centers
% Vars: (xvar,yvar)-by-spots variances, which are the mean values of these
%   variances across however many frames are in imgs
% optional output: amplitudes from the fits, in case that information is
%   used to choose which set of variances (red channel vs green channel) to
%   keep in the function that calls this one.
%
% Stephanie 5/2014
% Copyright 2014 Stephanie Johnson, University of California, San Francisco

function [RefinedCenters, Vars,varargout] = FindRefinedSpotCenters(imgs,spots,bkgnd_tolerance,params,debug)

if ~exist('debug','var') debug = 0; end
if size(imgs,3)>1 imgs = mat2gray(mean(imgs,3)); end

cen_tolerance = 2; % To judge the goodness of Gaussian fit, don't let the 
    % refined center position differ from the maximum pixel by more than
    % this value. Realistically 1 is probably fine too, the refinement is
    % usually within 1 pixel.
VarTolerance = 1;

ROIsize = params.DNASize;
symGauss = params.UseSymGauss;

defaultXvar = 0.7; %If the fit fails, set the spot variance to this value
    % For now taking this value (0.3) from the Ha lab IDL code, but it's probably
    % system (camera, microscope, etc) specific.
    % Update 5/2014: Changed default to 0.7 which is more consistent with
    % our setup
defaultYvar = defaultXvar;

tempCenters = zeros(2,size(spots,2));
tempVars = zeros(2,size(spots,2)); % Vars will be:
    % First row will contain xvars, second row yvars
    % Columns will be spots
tempbkgnd = zeros(1,size(spots,2));
tempAmps = zeros(1,size(spots,2));

RefinedCenters = [];
Vars = [];
bkgnd = [];
Amps = [];

    for ss = 1:size(spots,2)
       % Extract an ROI over which to calculate the fit:
       [spotimg,localcen] = ExtractROI(imgs,ROIsize,spots(:,ss));
       % Note if the fit fails, Fit2DGaussToSpot will return the
       % StartParams, so make sure the StartParams for xvar and yvar are
       % the defaults hardcoded above
       [RefinedLocalCenX,RefinedLocalCenY,tempVars(1,ss),tempVars(2,ss),tempbkgnd(ss),tempAmps(ss)] = Fit2DGaussToSpot(spotimg,'Full',...
           'StartParams',[localcen(1),localcen(2),defaultXvar,defaultYvar,min(spotimg(:)),max(spotimg(:))],...
           'Debug',debug,'symGauss',symGauss);
       tempCenters(:,ss) = GlobalToROICoords([],[RefinedLocalCenX;RefinedLocalCenY],ceil(spots(:,ss)),ROIsize,ROIsize);
       % for debugging
       % figure
%        imshow(imgs,[])
%        hold on
%        plot(spots(2,ss),spots(1,ss),'og')
%        plot(RefinedCenters(2,ss,i),RefinedCenters(1,ss,i),'xr')
%        pause 
%        close

        % Some further refinements:
        % Check that the maximum is surrounded by a sufficiently low
        % background:
        spotboundary = (sum(spotimg(:,1))+sum(spotimg(:,end))+...
            sum(spotimg(1,:))+sum(spotimg(end,:)))/(2*size(spotimg,1)+2*size(spotimg,2));
        % And check that the fit didn't fail and move the spot center somewhere
        % ridiculuous and that this isn't a one-pixel maximum by checking
        % the variance:
        if (FindSpotDists(tempCenters(:,ss),spots(:,ss))<cen_tolerance) && ... 
                spotboundary<=tempbkgnd(ss)+bkgnd_tolerance && ...
                tempVars(1,ss) < VarTolerance
            RefinedCenters(:,end+1) = tempCenters(:,ss);
            Vars(:,end+1) = tempVars(:,ss);
            bkgnd(end+1) = tempbkgnd(ss);
            Amps(end+1) = tempAmps(ss);
        % For debugging:
%         else
%             if FindSpotDists(tempCenters(:,ss),spots(:,ss))>cen_tolerance
%                 disp(sprintf('Removing spot at (%d,%d) from bad fit convergence: new spot center is %d away',...
%                     spots(1,ss),spots(2,ss),FindSpotDists(tempCenters(:,ss),spots(:,ss))))
%             elseif spotboundary>bkgnd+bkgnd_tolerance
%                 disp(sprintf('Removing spot at (%d,%d) from too high background: boundary background is %d',...
%                     spots(1,ss),spots(2,ss),spotboundary))
%             else
%                 disp(sprintf('Removing spot at (%d,%d) because variance is %d',...
%                     spots(1,ss),spots(2,ss),tempVars(1,ss)))
%             end
        end
        clear spotimg localcen tempVars tempCenters spotboundary empbkgnd
    end

varargout{1} = bkgnd;
varargout{2} = Amps;