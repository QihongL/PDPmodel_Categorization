%% superordinate classfication
% the OVERALL GOAL of this program is to convert a 'neural response' from
% ANN (in the form of a time series) and outputs a 'class' that represents
% a superordinate level category
function [gs, param] = runClassifier(logParam,PATH,FILENAME,showPlot)
if nargin == 0
    showPlot = true;
end

%% set some paramters
% specifiy the number of folds for CV
K = 3;

%% load the data and the prototype
[output, param] = loadData(PATH, FILENAME);

%% data preprocessing
% get activation matrices
activationMatrix = getActivationMatrices(output, param);
numTimePoints = size(activationMatrix,1);

if numTimePoints~=logParam.nTimePoints
    error_msg = sprintf('numTimePoints is %d(incorrect)!', numTimePoints); 
    error(error_msg)
end
% get labels
[~, Y] = getLabels(param);

% loop over all categories
numCategories = size(Y,2);
for j = 1 : numCategories
    %% attach labels
    data = attachLabels(activationMatrix, Y(:,j));
    %% set up Cross validation blocks
    CVB = logical(mod(1:param.numStimuli,K) == 0);
    
    % preallocation
    accuracy = nan(numTimePoints, 1);
    deviation = nan(numTimePoints, 1);
    hitRate = nan(numTimePoints, 1);
    falseRate = nan(numTimePoints, 1);
    %% Run Logistic regression classification for all time points
    % loop over time
    for i = 1 : numTimePoints
        % compute the accuracy for every time points
        result = logisticReg(data{i}, CVB, logParam);
        accuracy(i) = result.accuracy;
        deviation(i) = result.deviation;
        hitRate(i) = result.hitRate;
        falseRate(i) = result.falseRate;
    end
    gs.accuracy{j} = accuracy;
    gs.deviation{j} = deviation;
    gs.hitRate{j} = hitRate;
    gs.falseRate{j} = falseRate;
end

% averaging the neural activities
[gs.averageScore] = averagingResults(gs,numCategories, numTimePoints);

%% A function that visualizes the results
if showPlot
    visualizeAccuracies(gs.averageScore)
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%% Helper functions %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% averaging the results across simulations
function [score] = averagingResults(gs,numCategories, numTimePoints)
% preallocate
accuracy = zeros(numTimePoints, 1);
deviation = zeros(numTimePoints, 1);
hitRate =  zeros(numTimePoints, 1);
falseRate =  zeros(numTimePoints, 1);

% accumulate
for i = 1 : numCategories
    accuracy = accuracy + gs.accuracy{i};
    deviation = deviation + gs.deviation{i};
    hitRate = hitRate  + gs.hitRate{i};
    falseRate = falseRate + gs.falseRate{i};
end

% take mean
score.accuracy = accuracy / numCategories;
score.deviation = deviation / numCategories;
score.hitRate = hitRate / numCategories;
score.falseRate = falseRate / numCategories; 
end