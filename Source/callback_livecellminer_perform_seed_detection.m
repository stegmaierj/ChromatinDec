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

function [d_orgs, var_bez] = callback_livecellminer_perform_seed_detection(parameters)

    %% get list of current seed files
    detectionFiles = dir([parameters.detectionFolder parameters.detectionFilter]);
    numFrames = min(length(detectionFiles), parameters.numFrames);
        
    %% initialize d_orgs
    d_orgs = zeros(0, numFrames, 11);
    var_bez = char('id', 'scale', 'xpos', 'ypos', 'zpos', 'prevXPos', 'prevYPos', 'prevZPos', 'clusterCutoff', 'trackletId', 'predecessorId');
    
    %% loop through all seed files and extract the raw seed points
    for i=1:numFrames
       
        if (parameters.seedBasedDetection == true)
            try
                currentSeeds = dlmread([parameters.detectionFolder detectionFiles(i).name], ';', 1, 0);
            catch
                currentSeeds = [];
            end
            
            %% if current frame is empty try to load the next one
            if (size(currentSeeds, 1) == 0)
               for j=1:parameters.allowedEmptyFrames
                   
                   %% check if next seed file exists
                   if (~exist([parameters.detectionFolder detectionFiles(i+j).name], 'file'))
                       continue;
                   end
                   
                   %% load the next seed file
                   currentSeeds = dlmread([parameters.detectionFolder detectionFiles(i+j).name], ';', 1, 0);
                   
                   %% break the loop if seeds are found
                   if (size(currentSeeds, 1) > 0)
                       break;
                   end                  
               end
            end            
            
            currentSeeds(:,1) = currentSeeds(:,1) + 1;
            currentSeeds(:,3:4) = currentSeeds(:,3:4) / parameters.micronsPerPixel;
            currentSeeds(:,5) = 0; %% set z-coordinate to 0 as we're only processing 2D images.
            d_orgs(1:size(currentSeeds,1), i, :) = [currentSeeds(:,1:5), currentSeeds(:,3:5), sqrt(2) * currentSeeds(:,2) / parameters.micronsPerPixel, zeros(size(currentSeeds,1),2)];
        else
            maskImage = imread([parameters.detectionFolder detectionFiles(i).name]);
            regionProps = regionprops(maskImage, 'Centroid', 'Area', 'EquivDiameter');
            
            %% TODO: CHECK IF THE CENTROID COORDINATES NEED TO BE SWAPPED!!!
            for j=1:length(regionProps)
               d_orgs(j, i, :) = [j, regionProps(j).Area, round(regionProps(j).Centroid), 0, round(regionProps(j).Centroid), 0, 0.5*regionProps(j).EquivDiameter, 0, 0]; 
            end
        end
        
        fprintf('Finished importing seed image %i / %i\n', i, length(detectionFiles));        
    end
end