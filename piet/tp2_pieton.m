clearvars;
close all;
clc;

rootDir = fileparts(mfilename('fullpath'));
imageFiles = dir(fullfile(rootDir, 'PIETON*.bmp'));

if isempty(imageFiles)
    error('Aucune image PIETON*.bmp trouvee dans %s.', rootDir);
end

imageFiles = sortStructByNumericSuffix(imageFiles);
numFrames = numel(imageFiles);

firstFrame = imread(fullfile(rootDir, imageFiles(1).name));
if ndims(firstFrame) == 3
    firstFrame = rgb2gray(firstFrame);
end

[height, width] = size(firstFrame);
frames = zeros(height, width, numFrames, 'uint8');
frames(:, :, 1) = firstFrame;

for k = 2:numFrames
    frame = imread(fullfile(rootDir, imageFiles(k).name));
    if ndims(frame) == 3
        frame = rgb2gray(frame);
    end
    frames(:, :, k) = frame;
end

outputDir = fullfile(rootDir, 'sorties_tp2');
maskDir = fullfile(outputDir, 'masques');
trackedDir = fullfile(outputDir, 'frames_suivies');

ensureDir(outputDir);
ensureDir(maskDir);
ensureDir(trackedDir);

threshold = 20;
minArea = 120;
fps = 4;
maxDistance = 55;
maxMissedFrames = 2;
maxDetections = 2;

background = uint8(median(double(frames), 3));
imwrite(background, fullfile(outputDir, 'PIETON_fond_estime.png'));

originalVideo = VideoWriter(fullfile(outputDir, 'PIETON_sequence.avi'));
originalVideo.FrameRate = fps;
open(originalVideo);

trackingVideo = VideoWriter(fullfile(outputDir, 'PIETON_tracking.avi'));
trackingVideo.FrameRate = fps;
open(trackingVideo);

tracks = struct('id', {}, 'color', {}, 'lastCentroid', {}, 'trajectory', {}, 'bbox', {}, 'missedFrames', {});
allTracks = struct('id', {}, 'color', {}, 'trajectory', {});
nextTrackId = 1;

for frameIndex = 1:numFrames
    frame = frames(:, :, frameIndex);
    mask = segmentFrame(frame, background, threshold);
    detections = extractDetections(mask, minArea, maxDetections);
    [tracks, nextTrackId] = updateTracks(tracks, detections, nextTrackId, maxDistance, maxMissedFrames);
    allTracks = mergeTrackHistory(allTracks, tracks);

    maskPath = fullfile(maskDir, sprintf('masque_%02d.png', frameIndex));
    trackedPath = fullfile(trackedDir, sprintf('suivi_%02d.png', frameIndex));

    imwrite(uint8(mask) * 255, maskPath);
    writeMaskGif(mask, frameIndex, fullfile(outputDir, 'PIETON_masques.gif'));

    originalRgb = repmat(frame, [1, 1, 3]);
    trackedRgb = annotateFrame(frame, tracks);

    imwrite(trackedRgb, trackedPath);
    writeVideo(originalVideo, originalRgb);
    writeVideo(trackingVideo, trackedRgb);
end

close(originalVideo);
close(trackingVideo);

saveTrajectoryFigure(frames(:, :, end), allTracks, fullfile(outputDir, 'PIETON_trajectoires_finales.png'));

fprintf('Sequence creee : %s\n', fullfile(outputDir, 'PIETON_sequence.avi'));
fprintf('Video suivie   : %s\n', fullfile(outputDir, 'PIETON_tracking.avi'));
fprintf('Masques        : %s\n', maskDir);
fprintf('Trajectoires   : %s\n', fullfile(outputDir, 'PIETON_trajectoires_finales.png'));


function files = sortStructByNumericSuffix(files)
    values = zeros(numel(files), 1);
    for idx = 1:numel(files)
        token = regexp(files(idx).name, '(\d+)', 'tokens', 'once');
        values(idx) = str2double(token{1});
    end
    [~, order] = sort(values);
    files = files(order);
end


function ensureDir(pathValue)
    if ~exist(pathValue, 'dir')
        mkdir(pathValue);
    end
end


function mask = segmentFrame(frame, background, threshold)
    difference = abs(double(frame) - double(background));
    mask = difference > threshold;
    mask = imopen(mask, strel('square', 3));
    mask = imclose(mask, strel('square', 7));
    mask = imfill(mask, 'holes');
    mask = imerode(mask, strel('square', 5));
    mask = imdilate(mask, strel('square', 9));
end


function detections = extractDetections(mask, minArea, maxDetections)
    cc = bwconncomp(mask);
    stats = regionprops(cc, 'BoundingBox', 'Centroid', 'Area');
    stats = stats([stats.Area] >= minArea);

    if isempty(stats)
        detections = struct('bbox', {}, 'centroid', {}, 'area', {});
        return;
    end

    [~, order] = sort([stats.Area], 'descend');
    stats = stats(order(1:min(maxDetections, numel(order))));

    detections = struct('bbox', cell(1, numel(stats)), 'centroid', cell(1, numel(stats)), 'area', cell(1, numel(stats)));
    for idx = 1:numel(stats)
        box = stats(idx).BoundingBox;
        x0 = floor(box(1)) + 1;
        y0 = floor(box(2)) + 1;
        x1 = min(x0 + floor(box(3)) - 1, size(mask, 2));
        y1 = min(y0 + floor(box(4)) - 1, size(mask, 1));
        detections(idx).bbox = [x0, y0, x1, y1];
        detections(idx).centroid = stats(idx).Centroid;
        detections(idx).area = stats(idx).Area;
    end
end


function [tracks, nextTrackId] = updateTracks(tracks, detections, nextTrackId, maxDistance, maxMissedFrames)
    if isempty(tracks)
        for idx = 1:numel(detections)
            tracks(end + 1) = createTrack(nextTrackId, detections(idx)); %#ok<AGROW>
            nextTrackId = nextTrackId + 1;
        end
        return;
    end

    numTracks = numel(tracks);
    numDetections = numel(detections);
    unmatchedTracks = true(1, numTracks);
    unmatchedDetections = true(1, numDetections);
    pairs = zeros(0, 3);

    for trackIndex = 1:numTracks
        for detectionIndex = 1:numDetections
            distance = norm(tracks(trackIndex).lastCentroid - detections(detectionIndex).centroid);
            if distance <= maxDistance
                pairs(end + 1, :) = [distance, trackIndex, detectionIndex]; %#ok<AGROW>
            end
        end
    end

    if ~isempty(pairs)
        pairs = sortrows(pairs, 1);
        for pairIndex = 1:size(pairs, 1)
            trackIndex = pairs(pairIndex, 2);
            detectionIndex = pairs(pairIndex, 3);
            if unmatchedTracks(trackIndex) && unmatchedDetections(detectionIndex)
                tracks(trackIndex) = applyDetectionToTrack(tracks(trackIndex), detections(detectionIndex));
                unmatchedTracks(trackIndex) = false;
                unmatchedDetections(detectionIndex) = false;
            end
        end
    end

    survivors = struct('id', {}, 'color', {}, 'lastCentroid', {}, 'trajectory', {}, 'bbox', {}, 'missedFrames', {});
    for trackIndex = 1:numTracks
        if unmatchedTracks(trackIndex)
            tracks(trackIndex).missedFrames = tracks(trackIndex).missedFrames + 1;
        end
        if tracks(trackIndex).missedFrames <= maxMissedFrames
            survivors(end + 1) = tracks(trackIndex); %#ok<AGROW>
        end
    end

    for detectionIndex = 1:numDetections
        if unmatchedDetections(detectionIndex)
            survivors(end + 1) = createTrack(nextTrackId, detections(detectionIndex)); %#ok<AGROW>
            nextTrackId = nextTrackId + 1;
        end
    end

    tracks = survivors;
end


function track = createTrack(trackId, detection)
    track.id = trackId;
    track.color = trackColor(trackId);
    track.lastCentroid = detection.centroid;
    track.trajectory = detection.centroid;
    track.bbox = detection.bbox;
    track.missedFrames = 0;
end


function track = applyDetectionToTrack(track, detection)
    track.lastCentroid = detection.centroid;
    track.trajectory(end + 1, :) = detection.centroid;
    track.bbox = detection.bbox;
    track.missedFrames = 0;
end


function color = trackColor(trackId)
    palette = [
        220, 20, 60;
        0, 128, 255;
        34, 139, 34;
        255, 140, 0;
        148, 0, 211
    ];
    index = mod(trackId - 1, size(palette, 1)) + 1;
    color = uint8(palette(index, :));
end


function allTracks = mergeTrackHistory(allTracks, activeTracks)
    for idx = 1:numel(activeTracks)
        match = find([allTracks.id] == activeTracks(idx).id, 1);
        if isempty(match)
            allTracks(end + 1).id = activeTracks(idx).id; %#ok<AGROW>
            allTracks(end).color = activeTracks(idx).color;
            allTracks(end).trajectory = activeTracks(idx).trajectory;
        else
            allTracks(match).trajectory = activeTracks(idx).trajectory;
        end
    end
end


function writeMaskGif(mask, frameIndex, gifPath)
    [indexedImage, colorMap] = gray2ind(uint8(mask) * 255, 256);
    if frameIndex == 1
        imwrite(indexedImage, colorMap, gifPath, 'gif', 'LoopCount', inf, 'DelayTime', 0.25);
    else
        imwrite(indexedImage, colorMap, gifPath, 'gif', 'WriteMode', 'append', 'DelayTime', 0.25);
    end
end


function rgb = annotateFrame(frame, tracks)
    rgb = repmat(frame, [1, 1, 3]);
    for idx = 1:numel(tracks)
        rgb = drawRectangle(rgb, tracks(idx).bbox, tracks(idx).color, 2);
        rgb = drawTrajectory(rgb, tracks(idx).trajectory, tracks(idx).color);
        rgb = drawCross(rgb, round(tracks(idx).lastCentroid), tracks(idx).color, 4);
    end
end


function rgb = drawRectangle(rgb, bbox, color, lineWidth)
    x0 = max(1, bbox(1));
    y0 = max(1, bbox(2));
    x1 = min(size(rgb, 2), bbox(3));
    y1 = min(size(rgb, 1), bbox(4));

    for offset = 0:(lineWidth - 1)
        top = min(size(rgb, 1), y0 + offset);
        bottom = max(1, y1 - offset);
        left = min(size(rgb, 2), x0 + offset);
        right = max(1, x1 - offset);

        rgb(top, left:right, 1) = color(1);
        rgb(top, left:right, 2) = color(2);
        rgb(top, left:right, 3) = color(3);

        rgb(bottom, left:right, 1) = color(1);
        rgb(bottom, left:right, 2) = color(2);
        rgb(bottom, left:right, 3) = color(3);

        rgb(top:bottom, left, 1) = color(1);
        rgb(top:bottom, left, 2) = color(2);
        rgb(top:bottom, left, 3) = color(3);

        rgb(top:bottom, right, 1) = color(1);
        rgb(top:bottom, right, 2) = color(2);
        rgb(top:bottom, right, 3) = color(3);
    end
end


function rgb = drawTrajectory(rgb, trajectory, color)
    if size(trajectory, 1) < 2
        return;
    end

    for idx = 1:(size(trajectory, 1) - 1)
        pointA = round(trajectory(idx, :));
        pointB = round(trajectory(idx + 1, :));
        rgb = drawLine(rgb, pointA, pointB, color);
    end
end


function rgb = drawLine(rgb, pointA, pointB, color)
    numSteps = max(abs(pointB - pointA)) + 1;
    xs = round(linspace(pointA(1), pointB(1), numSteps));
    ys = round(linspace(pointA(2), pointB(2), numSteps));

    xs = min(max(xs, 1), size(rgb, 2));
    ys = min(max(ys, 1), size(rgb, 1));

    for idx = 1:numel(xs)
        rgb(ys(idx), xs(idx), 1) = color(1);
        rgb(ys(idx), xs(idx), 2) = color(2);
        rgb(ys(idx), xs(idx), 3) = color(3);
    end
end


function rgb = drawCross(rgb, centroid, color, radius)
    x = centroid(1);
    y = centroid(2);
    xRange = max(1, x - radius):min(size(rgb, 2), x + radius);
    yRange = max(1, y - radius):min(size(rgb, 1), y + radius);

    rgb(y, xRange, 1) = color(1);
    rgb(y, xRange, 2) = color(2);
    rgb(y, xRange, 3) = color(3);

    rgb(yRange, x, 1) = color(1);
    rgb(yRange, x, 2) = color(2);
    rgb(yRange, x, 3) = color(3);
end


function saveTrajectoryFigure(lastFrame, tracks, outputPath)
    figureHandle = figure('Visible', 'off');
    imshow(lastFrame, []);
    hold on;
    title('Trajectoires finales des pietons');

    for idx = 1:numel(tracks)
        trajectory = tracks(idx).trajectory;
        color = double(tracks(idx).color) / 255;
        plot(trajectory(:, 1), trajectory(:, 2), '-', 'Color', color, 'LineWidth', 2);
        plot(trajectory(end, 1), trajectory(end, 2), 'o', 'Color', color, 'MarkerFaceColor', color);
        text(trajectory(end, 1) + 4, trajectory(end, 2), sprintf('P%d', tracks(idx).id), 'Color', color, 'FontWeight', 'bold');
    end

    hold off;
    exportgraphics(gca, outputPath, 'Resolution', 150);
    close(figureHandle);
end