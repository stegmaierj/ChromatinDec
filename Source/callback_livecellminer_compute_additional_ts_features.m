%%
% LiveCellMiner.
% Copyright (C) 2020 D. Moreno-Andres, A. Bhattacharyya, W. Antonin, J. Stegmaier
%
% Licensed under the Apache License, Version 2.0 (the "License");
% you may not use this file except in compliance with the License.
% You may obtain a copy of the Liceense at
%
%     http://www.apache.org/licenses/LICENSE-2.0
%
% Unless required by applicable law or agreed to in writing, software
% distributed under the License is distributed on an "AS IS" BASIS,
% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
% See the License for the specific language governing permissions and
% limitations under the License.
%
% Please refer to the documentation for more information about the software
% as well as for installation instructions.
%
% If you use this application for your work, please cite the repository and one
% of the following publications:
%
% TBA
%
%%

%% preload image files if not done yet
if (~exist('rawImagePatches', 'var') || isempty(rawImagePatches))
   callback_livecellminer_load_image_files; 
end

numCells = size(d_orgs,1);
numFrames = size(d_orgs,2);

circularityFeature = zeros(numCells, numFrames);
eccentricityFeature = zeros(numCells, numFrames);
solidityFeature = zeros(numCells, numFrames);
convexAreaFeature = zeros(numCells, numFrames);
equivDiameterFeature = zeros(numCells, numFrames);
extentFeature = zeros(numCells, numFrames);

f = waitbar(0, ['Computing additional time series features for all cells ...']);

for i=1:size(d_orgs,1)
    parfor j=1:size(d_orgs,2)
        currentMask = maskImagePatches{i,j};
        
        currentRegionProps = regionprops(currentMask > 0, 'circularity', 'eccentricity', 'perimeter', 'area', 'solidity', 'convexarea', 'equivdiameter', 'extent');
        
        circularityFeature(i,j) = sqrt(1.0 / currentRegionProps(1).Circularity);
        eccentricityFeature(i,j) = currentRegionProps(1).Eccentricity;
        solidityFeature(i,j) = currentRegionProps(1).Solidity;
        convexAreaFeature(i,j) = currentRegionProps(1).ConvexArea;
        equivDiameterFeature(i,j) = currentRegionProps(1).EquivDiameter;
        extentFeature(i,j) = currentRegionProps(1).Extent;
    end
    
    waitbar((i / numCells), f, ['Computing additional time series features for all cells ...']);
end

close(f);

d_orgs(:,:,end+1) = circularityFeature;
d_orgs(:,:,end+1) = eccentricityFeature;
d_orgs(:,:,end+1) = solidityFeature;
d_orgs(:,:,end+1) = convexAreaFeature;
d_orgs(:,:,end+1) = equivDiameterFeature;
d_orgs(:,:,end+1) = extentFeature;

if (strcmp(kill_lz(var_bez(end,:)), 'y') == 1)
    var_bez = var_bez(1:end-1, :);
end
var_bez = char(var_bez, 'Circularity2', 'Eccentricity', 'Solidity', 'ConvexArea', 'EquivDiameter', 'Extent');
aktparawin;