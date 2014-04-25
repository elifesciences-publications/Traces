% function composite = CalcCombinedImage(tform,StartImg,EndImg,ShowResults)
%
% Given two images and the transformation encoded in the matlab-specific
% structure tform that maps from StartImg to EndImg, 
% calculate the transformed version of StartImg and return a
% composite of EndImg and the transformed image.
%
% This is called by smFRET so that you can find spots in a composite image
% from both channels, the idea being that medium-FRET spots will have
% decreased intensities in the two channels and may be missed by a
% spotfinding algorithm that only looks for spots in green and spots in red
% separately.
%
% NOTE this currently uses the built-in Matlab function imwarp, which was
% released with R2012a. Older Matlab versions cannot run this function.
%
% Steph 2/2014
% Copyright 2014 Stephanie Johnson, University of California, San Francisco

function composite = CalcCombinedImage(tform,StartImg,EndImg,ShowResults)

if ~exist('ShowResults','var') ShowResults = 0; end

try 
    Rfixed = imref2d(size(EndImg));
    alignedimgG = imwarp(StartImg,tform,'OutputView',Rfixed);
catch
    %alignedimgG = imtransform(StartImg,tform); % With R2011b and older, you
        %can use imtransform instead of imwarp, but there's no imfuse
        %equivalent (or imshowpair).
    disp('CalcCombinedImage: Your version of Matlab does not support this function.')
    composite = -1;
    return
end

composite = imfuse(EndImg,alignedimgG,'blend');

if ShowResults
    figure, imshowpair(EndImg,alignedimgG,'blend')
    title('Green overlayed on red')
end