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

function [] = callback_livecellminer_show_combined_boxplots(parameter, d_org, d_orgs, dorgbez, var_bez, ind_auswahl, bez_code, code_alle, zgf_y_bez, showHistogram)

    %% get the parameters from the GUI
    IPTransition = parameter.gui.livecellminer.IPTransition;
    MATransition = parameter.gui.livecellminer.MATransition;
    alignedLength = parameter.gui.livecellminer.alignedLength;
    alignPlots = parameter.gui.livecellminer.alignPlots;
    errorStep = parameter.gui.livecellminer.errorStep;
    showErrorBars = parameter.gui.livecellminer.showErrorBars;

    if (~exist('showHistogram', 'var'))
       showHistogram = false;
    end

    darkMode = parameter.gui.livecellminer.darkMode;
    summarizeSelectedExperiments = parameter.gui.livecellminer.summarizeSelectedExperiments;

    %% set visualization mode
    if (~exist('visualizationMode', 'var'))
        visualizationMode = 2;
    end
    timeRange = parameter.gui.zeitreihen.segment_start:parameter.gui.zeitreihen.segment_ende;

    %% get the selected cells
    selectedCells = ind_auswahl;

    %% find the manual synchronization index
    synchronizationIndex = callback_livecellminer_find_time_series(var_bez, 'manualSynchronization');

    %% identify the contained features, experiments and positions
    experimentId = callback_livecellminer_find_output_variable(bez_code, parameter.gui.livecellminer.summaryOutputVariable);
    selectedExperiments = unique(code_alle(selectedCells, experimentId));
    selectedOutputVariable = parameter.gui.merkmale_und_klassen.ausgangsgroesse;
    selectedPositionsOrOligos = unique(code_alle(selectedCells, selectedOutputVariable));
    selectedFeatures = parameter.gui.merkmale_und_klassen.ind_em;

    %% compute the number of required subplots
    numSubPlots = 1;
    if (summarizeSelectedExperiments == false)
        numSubPlots = numSubPlots * length(selectedExperiments);
    end
    [numRows, numColumns] = compute_subplot_layout(numSubPlots);

    %% specify the color map and the line styles
    colorMap = lines(length(selectedPositionsOrOligos));
    lineStyles = {'-', '--', ':', '-.'};

    %% box plots
    dataPoints = [];
    grouping = [];

    %% plot separate figures for each feature
    for f = generate_rowvector(selectedFeatures)

        %% open new figure and initialize it with the selected color mode
        if (parameter.gui.livecellminer.darkMode == true)
            colordef black;
            markerColor = 'w';
        else
            markerColor = 'k';
            colordef white;
        end
        fh = figure; clf; hold on;
        if (parameter.gui.livecellminer.darkMode == true)
            set(fh, 'color', 'black');
        else
            set(fh, 'color', 'white');
        end


        %% summarize the results of each position either as a heat map, box plots or line plots
        minValue = inf;
        maxValue = -inf;
        globalMinValue = min(d_org(:, f));
        globalMaxValue = max(d_org(:, f));
        intensityHistogramStep = (globalMaxValue - globalMinValue) / 100;

        currentLegend = char();
        currentSubPlot = 1;

        if (summarizeSelectedExperiments == false)
            for e=generate_rowvector(selectedExperiments)

                %% select subplot
                subplot(numRows, numColumns, currentSubPlot); hold on;

                %% reset data points
                dataPoints = [];
                grouping = [];    

                %% plot dummy lines for the proper visualization of the legend
                for i=1:length(selectedPositionsOrOligos)
                    if (visualizationMode == 1)
                        plot([1,1], [1, 1], '-r', 'Color', colorMap(i, :));
                    else
                        plot([1,1], [1, 1], lineStyles{mod(i, 4)+1}, 'Color', colorMap(i, :));
                    end
                end

                currentCodeValue = 1;
                for p=generate_rowvector(selectedPositionsOrOligos)

                    %% get stage transitions
                    if (synchronizationIndex > 0 && alignPlots == true)
                        stageTransitions = squeeze(d_orgs(ind_auswahl, 1, synchronizationIndex)) >= 0;
                    end

                    %% get the valid cells for the current combination of experiment and position
                    if (synchronizationIndex == 0 || alignPlots == false)
                        validIndices = ind_auswahl(find(code_alle(ind_auswahl, experimentId) == e & code_alle(ind_auswahl, selectedOutputVariable) == p));
                    else
                        validIndices = ind_auswahl(find(code_alle(ind_auswahl, experimentId) == e & code_alle(ind_auswahl, selectedOutputVariable) == p & stageTransitions));
                    end

                    %% continue if no valid cells are present in this combination
                    if (isempty(validIndices))
                        continue;
                    end

                    %% fill heat map values to an array and remember the group association
                    dataPoints = [dataPoints; d_org(validIndices, f)];
                    grouping = [grouping; ones(size(validIndices)) * currentCodeValue];

                    %% assemble the name for the current plot entity
                    plotName = [zgf_y_bez(selectedOutputVariable,p).name];

                    %% set axis labels
                    if (visualizationMode ~= 1)
                        %% set the axis labels
                        xlabel('Frame Number');
                        ylabel(strrep(kill_lz(var_bez(f,:)), '_', '\_'));
                        box off;
                    end

                    plotName = strrep(plotName, '_', '\_');
                    if (currentCodeValue == 1)
                        currentLegend = plotName;
                    else
                        currentLegend = char(currentLegend, plotName);
                    end

                    currentCodeValue = currentCodeValue + 1;
                end

                %% plot the data in box plot format
                numGroups = length(unique(grouping));
                groupColors = colorMap(1:numGroups, :);
                if (numGroups == 1)
                    groupColors = [];
                end

                minValue = min(minValue, min(dataPoints(:)));
                maxValue = max(maxValue, max(dataPoints(:)));

                if (showHistogram == false)
                    boxplot(dataPoints, grouping, 'notch', 'on', 'BoxStyle', 'outline', 'Labels', currentLegend, 'ColorGroup', groupColors, 'PlotStyle', 'compact', 'Jitter', 0.2);
                    box off;

                    %% adjust the boxplot colors depending on the color mode
                    upperWhiskers = findobj(gcf, 'type', 'line', 'Tag', 'Upper Whisker');
                    lowerWhiskers = findobj(gcf, 'type', 'line', 'Tag', 'Lower Whisker');
                    upperAdjacentValue = findobj(gcf, 'type', 'line', 'Tag', 'Upper Adjacent Value');
                    lowerAdjacentValue = findobj(gcf, 'type', 'line', 'Tag', 'Lower Adjacent Value');
                    set(upperWhiskers, 'Color', markerColor);
                    set(lowerWhiskers, 'Color', markerColor);
                    set(upperAdjacentValue, 'Color', markerColor);
                    set(lowerAdjacentValue, 'Color', markerColor);
                    %xtickangle(15);        
%                     
%                     hold on;
%                     scatter(ones(size(dataPoints))*currentCodeValue, dataPoints, 5, 0.1 * ones(size(dataPoints), 3), '.');
                    

                    ylabel(strrep(kill_lz(dorgbez(f,:)), '_', '\_'));
                else
                    if (length(unique(grouping)) > 1)
                        hist3([dataPoints, grouping], 'Ctrs', {globalMinValue:intensityHistogramStep:globalMaxValue unique(grouping)'}, 'CDataMode','auto','FaceColor','interp');
                    else
                        hist(dataPoints, globalMinValue:intensityHistogramStep:globalMaxValue);
                    end
                    set(gca, 'YTick', unique(grouping), 'YTickLabels', currentLegend);
                    xlabel(strrep(kill_lz(dorgbez(f,:)), '_', '\_'));
                    ylabel('Grouping');
                    zlabel('Number of Cells'); 
                    axis tight; box off;
                end

                title(strrep(zgf_y_bez(experimentId,e).name, '_', '\_'));

                %% increment subplot counter
                currentSubPlot = currentSubPlot + 1;
            end
        else

            %% plot dummy lines for the proper visualization of the legend
            for i=1:length(selectedPositionsOrOligos)
                if (visualizationMode == 1)
                    plot([1,1], [1, 1], '-r', 'Color', colorMap(i, :));
                else
                    plot([1,1], [1, 1], lineStyles{mod(i, 4)+1}, 'Color', colorMap(i, :));
                end
            end

            currentCodeValue = 1;
            for p=generate_rowvector(selectedPositionsOrOligos)

                %% get stage transitions
                if (synchronizationIndex > 0 && alignPlots == true)
                    stageTransitions = squeeze(d_orgs(ind_auswahl, 1, synchronizationIndex)) >= 0;
                end

                %% get the valid cells for the current combination of experiment and position
                if (synchronizationIndex == 0 || alignPlots == false)
                    validIndices = ind_auswahl(find(code_alle(ind_auswahl, selectedOutputVariable) == p));
                else
                    validIndices = ind_auswahl(find(code_alle(ind_auswahl, selectedOutputVariable) == p & stageTransitions));
                end

                %% continue if no valid cells are present in this combination
                if (isempty(validIndices))
                    continue;
                end

                %% fill heat map values to an array and remember the group association
                dataPoints = [dataPoints; d_org(validIndices, f)];
                grouping = [grouping; ones(size(validIndices)) * currentCodeValue];

                %% assemble the name for the current plot entity
                plotName = [zgf_y_bez(selectedOutputVariable,p).name];

                %% set axis labels
                if (visualizationMode ~= 1)
                    %% set the axis labels
                    xlabel('Frame Number');
                    ylabel(strrep(kill_lz(var_bez(f,:)), '_', '\_'));
                    box off;
                end

                plotName = strrep(plotName, '_', '\_');
                if (currentCodeValue == 1)
                    currentLegend = plotName;
                else
                    currentLegend = char(currentLegend, plotName);
                end

                %% increment subplot counter
                currentCodeValue = currentCodeValue + 1;
            end

            %% add legends to the figures
            %% plot the data in box plot format
            numGroups = length(unique(grouping));
            groupColors = colorMap(1:numGroups, :);
            if (numGroups == 1)
                groupColors = [];
            end

            minValue = min(minValue, min(dataPoints(:)));
            maxValue = max(minValue, max(dataPoints(:)));

            if (showHistogram == false)
                
%                 scatter(grouping + 0.1*randn(length(grouping), 1), dataPoints, 10, 0.8*[ones(length(dataPoints),1), ones(length(dataPoints),1), ones(length(dataPoints),1)], 'filled');
%                 hold on;
                
                boxplot(dataPoints, grouping, 'notch', 'on', 'BoxStyle', 'outline', 'Labels', currentLegend, 'ColorGroup', groupColors, 'PlotStyle', 'compact', 'Jitter', 0.2);
                box off;

                %% adjust the boxplot colors depending on the color mode
                upperWhiskers = findobj(gcf, 'type', 'line', 'Tag', 'Upper Whisker');
                lowerWhiskers = findobj(gcf, 'type', 'line', 'Tag', 'Lower Whisker');
                upperAdjacentValue = findobj(gcf, 'type', 'line', 'Tag', 'Upper Adjacent Value');
                lowerAdjacentValue = findobj(gcf, 'type', 'line', 'Tag', 'Lower Adjacent Value');
                set(upperWhiskers, 'Color', markerColor);
                set(lowerWhiskers, 'Color', markerColor);
                set(upperAdjacentValue, 'Color', markerColor);
                set(lowerAdjacentValue, 'Color', markerColor);
               
                
                ylabel(strrep(kill_lz(dorgbez(f,:)), '_', '\_'));
            else
                histgramRange = globalMinValue:intensityHistogramStep:globalMaxValue;
                
                if (length(unique(grouping)) > 1)
                    if (~isempty(histgramRange))
                        hist3([dataPoints, grouping], 'Ctrs', {globalMinValue:intensityHistogramStep:globalMaxValue [unique(grouping)']}, 'CDataMode','auto','FaceColor','interp');
                    else
                        hist3([dataPoints, grouping], 'CDataMode','auto','FaceColor','interp');
                    end
                else
                    if (~isempty(histgramRange))
                        hist(dataPoints, globalMinValue:intensityHistogramStep:globalMaxValue);
                    else
                        hist(dataPoints);
                    end
                end
                set(gca, 'YTick', unique(grouping), 'YTickLabels', currentLegend);
                xlabel(strrep(kill_lz(dorgbez(f,:)), '_', '\_'));
                ylabel('Grouping');
                zlabel('Number of Cells');
                axis tight; box off;
            end

            title('Combined Experiments');
        end
    end

    colordef white;

end