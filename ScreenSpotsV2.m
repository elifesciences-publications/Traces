% function newspots = ScreenSpots(img,spotcenters,boxdim,varargin)
%
% Interactive function that allows user to choose spots, from those found by 
% FindSpotsV3, that they don't want included in further analyses.
%
% Inputs are the image that spots were found in, a vector of (x,y)
% coordinates where the spot centers are, and boxdim that determines the
% size of the circle to put around each spot.  The user should click in the
% circle in order to deselect or re-select a spot.  Output is a vector of 
% the kept spotcenters.
%
% Optional input is a string to put on the image, so you know what you're
% analyzing.
%
% Replaces an older version that used a different version of PutBoxesOnImage 
% that allows figure data to be replaced without replotting the whole thing--
% would have been much faster ... 
%
% The MIT License (MIT)
% 
% Copyright (c) 2014 Stephanie Johnson, University of California, San Francisco
% 
% Permission is hereby granted, free of charge, to any person obtaining a copy
% of this software and associated documentation files (the "Software"), to deal
% in the Software without restriction, including without limitation the rights
% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
% copies of the Software, and to permit persons to whom the Software is
% furnished to do so, subject to the following conditions:
% 
% The above copyright notice and this permission notice shall be included in all
% copies or substantial portions of the Software.
% 
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
% SOFTWARE.

function newspots = ScreenSpotsV2(img,spotcenters,boxdim,varargin)

if ~isempty(varargin) && ~ischar(varargin{1})
    disp('Spot screening: figure title must be a string.')
    newspots = -1;
    return
end

% Make sure the spots are listed as one spot per column:
if size(spotcenters,1)~=2
    spotcenters = transpose(spotcenters);
end

newspots = spotcenters; % Start out assuming user wants to keep all spots
badspots = [];

happy = 0;
coords=[];

PutBoxesOnImageV4(img,newspots,boxdim);
if ~isempty(varargin)
    title(strcat(varargin{1},'; Click on a spot to deselect; z to zoom; u to unzoom; return to end'));
else
    title('Click on a spot to deselect; z to zoom; u to unzoom; return to end');
end

while happy == 0     
    if ~isempty(coords)
        set(gca,'Xlim',[coords(1,1) coords(2,1)])
        set(gca,'Ylim',[coords(1,2) coords(2,2)])
    end
    [SelectedSpotx,SelectedSpoty,z] = ginput(1);
    if z==122 %User wants to zoom
        title('Click on upper left and lower right areas to zoom to:')
        coords = ginput(2);
    elseif z==117 %User wants to un-zoom
        set(gca,'Xlim',[1 size(img,2)])
        set(gca,'Ylim',[1 size(img,1)])
        coords=[];
    elseif isempty(SelectedSpotx)
        happy = 1;
    else
        % Find the nearest spot center to the user's click.  Start by
        % finding the distance from user's click to every spot:
        dists = FindSpotDists([SelectedSpotx;SelectedSpoty],spotcenters);
        [~,closest] = min(dists,[],2);
        % The closest spot to the click is the one at
        % spotcenters(closest,:).
        % If this spot is in newspots, deselect and move to badspots:
        if ~isempty(find(ismember(newspots,spotcenters(closest,:))))
            badspots(end+1,:) = spotcenters(closest,:);
            badspots = sortrows(badspots);
            spotind = find(ismember(newspots,spotcenters(closest,:)));
            tempspots = newspots;
            clear newspots
            newspots = [tempspots(1:spotind(1)-1,:); tempspots(spotind(1)+1:end,:)];
            clear tempspots spotind
            % Don't need to sort, the newspots vector should still be sorted
        % if it's in badspots, re-select and move to newspots:
        elseif ~isempty(find(ismember(badspots,spotcenters(closest,:))))
            newspots(end+1,:) = spotcenters(closest,:);
            newspots = sortrows(newspots);
            spotind = find(ismember(badspots,spotcenters(closest,:)));
            tempspots = badspots;
            clear badspots
            badspots = [tempspots(1:spotind(1)-1,:); tempspots(spotind(1)+1:end,:)];
            clear tempspots spotind
        else
            disp('Spot is not in newspots or bad spots.  Problem!')
            keyboard
        end
       PutBoxesOnImageV4(img,newspots,boxdim); 
       if ~isempty(varargin)
           title(strcat(varargin{1},'; Click on a spot to deselect; z to zoom; u to unzoom; return to end'));
       else
           title('Click on a spot to deselect; z to zoom; u to unzoom; return to end');
       end
       
    end
end
close