function DrawResults(DirName, isDrawTheory, WhatDrawStringArray, ...
    TargetBER, SpecialResDraw)
%
%   - WhatDrawStringArray: BER, FER, PAPR, Shennon;
%   - TargetBER - for spectral Shennon plane;
%   - SpecialResDraw - string array with results to draw. If empty, then
%       all to draw;

if (nargin < 5)
    SpecialResDraw = [];
end
if (nargin < 4)
    TargetBER = [];
end
if (nargin < 3) || isempty(WhatDrawStringArray)
    WhatDrawStringArray = "BER";
end
if (nargin < 2) || isempty(isDrawTheory)
    isDrawTheory = false;
end
if (nargin == 0) || isempty(DirName)
    DirName = '../Results';
end

IsLegend = false;
BERtag = "BER";
FERtag = "FER";
PAPRtag = "PAPR";
ShennonTag = "Shennon";
AmountFigures = 0;
if ~isempty(WhatDrawStringArray)
    if ~isempty(find(WhatDrawStringArray == BERtag, 1))
        AmountFigures = AmountFigures + 1;
    end
    if ~isempty(find(WhatDrawStringArray == FERtag, 1))
        AmountFigures = AmountFigures + 1;
    end
    if ~isempty(find(WhatDrawStringArray == PAPRtag, 1))
        AmountFigures = AmountFigures + 1;
    end
    if ~isempty(find(WhatDrawStringArray == ShennonTag, 1))
        AmountFigures = AmountFigures + 1;
    end
end

% Получим информацию о содержимом директории
Listing = dir(DirName);

% Инициализируем cell-массив для хранения имён файлов, из которых потом
% сделаем легенду
Names = cell(0);

% Цикл по всем файлам директории
for k = 1:length(Listing)
    % Надо проверять, чтобы рассматриваемый элемент был файлом и
    % имел расширение mat
    if ~Listing(k).isdir
        FName = Listing(k).name;
        if length(FName) > 4
            if isequal(FName(end-3:end), '.mat')
                Name = FName(1:end-4);
                if isempty(SpecialResDraw)
                    % Добавим имя файла к списку
                    Names{end+1} = Name; %#ok<AGROW>
                else
                    if ~isempty(find(SpecialResDraw == ...
                            convertCharsToStrings(Name), 1))
                        Names{end+1} = Name; %#ok<AGROW>
                    end
                end
            end
        end
    end
end

if isempty(Names)
    error('Не найдены файлы с результатами!');
end

AmountFiles = length(Names);

f  = cell(AmountFigures, 1);
ax = cell(AmountFigures, 1);
for k = 1:AmountFigures
    f{k} = figure('WindowStyle', 'Docked');
    ax{k} = axes;
end

LegendArray = cell(0);
for k = 1 : AmountFiles
    % Загрузка результатов
    load([DirName, '\', Names{k}, '.mat'], 'Res');
    for FigNum = 1 : AmountFigures
        figure(f{FigNum});
        BERs = Res.NumErBits ./ Res.NumTrBits;
        switch WhatDrawStringArray(FigNum)
            case BERtag
                if ~Res.isBER
                    error('The results contain only PAPR statistics - not BER!');
                end
                hold on;
                plot(Res.h2dBs, BERs, ...
                    'LineWidth', 1, 'MarkerSize', 8, ...
                    'Marker', '.');
                LegendArray{end+1} = Names{k};
            case FERtag
                if ~Res.isBER
                    error('The results contain only PAPR statistics - not FER!');
                end
                hold on;
                plot(Res.h2dBs, Res.NumErFrames ./ ...
                    Res.NumTrFrames, 'LineWidth', 1, ...
                    'MarkerSize', 8, 'Marker', '.');
                LegendArray{end+1} = Names{k};
            case PAPRtag
                if Res.isBER
                    error('The results contain only BER statistics - not PAPR!');
                end
                hold on;
                plot(Res.PAPRVals, Res.NumCaptPAPRSamples ./ ...
                    Res.NumPAPRSamples, 'LineWidth', 1, ...
                    'MarkerSize', 8, 'Marker', '.');
                LegendArray{end+1} = Names{k};
            case ShennonTag
                hold on;
                [Interph2dB, Msg] = BERLinInterp(TargetBER, Res.h2dBs, BERs);
                if isempty(Msg)
                    TestName = convertStringsToChars(Names{k});
                    MCS = DeriveMCSfromName(TestName);
                    Font = DeriveFontAddSymb(TestName);
                    if ~isempty(strfind(Names{k}, 'SEFDM')) || ...
                            ~isempty(strfind(Names{k}, 'TOFDM'))
                        if ~isempty(strfind(Names{k}, '0_7'))
                            Color = 'b';
                        end
                        if ~isempty(strfind(Names{k}, '0_8'))
                            Color = 'r';
                        end
                        if ~isempty(strfind(Names{k}, '0_9'))
                            Color = 'g';
                        end
                        
                        if ~isempty(strfind(Names{k}, 'SEFDM'))
                            Marker = '*';
                        end
                        if ~isempty(strfind(Names{k}, 'TOFDM'))
                            Marker = 'o';
                        end
                    elseif ~isempty(strfind(Names{k}, 'OFDM'))
                        Color = 'm';
                        Marker = '+';
                    end
                    text(Interph2dB, Res.SpectralEfficiency, ...
                        [Font, num2str(MCS)], 'FontSize', 6);
                    plot(Interph2dB, Res.SpectralEfficiency, [Marker, Color], ...
                        'MarkerSize', 3);
                    LegendArray{end+1} = Names{k};
                else
                    warning([Names{k}, Msg{1}]);
                end
            otherwise
                error('Incorrect WhatDrawStringArray type!')
        end
    end
end

% Draw references and add information
for FigNum = 1 : AmountFigures
    figure(f{FigNum});
    switch WhatDrawStringArray(FigNum)
        case BERtag
            title('BER');
            xlabel('{\ith}^2 (dB)');
            if isDrawTheory
                hold on;
                h2dB = 0:0.1:10.5;
                BER = berawgn(h2dB, 'qam', 4);
                plot(h2dB, BER);
                LegendArray{end+1} = 'QPSK';
                
                hold on;
                h2dB = 0:0.1:14.4;
                BER = berawgn(h2dB, 'qam', 16);
                plot(h2dB, BER);
                LegendArray{end+1} = 'QAM-16';
                
                hold on;
                h2dB = 0:0.1:18.8;
                BER = berawgn(h2dB, 'qam', 64);
                plot(h2dB, BER);
                LegendArray{end+1} = 'QAM-64';
            end
        case FERtag
            title('FER');
            xlabel('{\ith}^2 (dB)');
        case PAPRtag
            title('CCDF');
            xlabel('PAPR (dB)');
        case ShennonTag
            xlabel('{\itSNR, dB}', 'FontSize', 8);
            ylabel('{\itSE, bits/s/Hz}', 'FontSize', 8);
            if isDrawTheory
                hold on;
                h2dB = 0:0.1:18.8;
                Throughput = log2(1 + h2dB);
                plot(h2dB, Throughput, '-r');
                text(0.4, 3.5, 'Shannon limit', 'FontSize', 8);
                text(8, 0.4, 'Text', 'FontSize', 8);
            end
        otherwise
            error('Incorrect WhatDrawStringArray type!')
    end
    set(ax{FigNum}, 'YScale', 'log');
    grid on;
end

% Add legend
if IsLegend
    for FigNum = 1 : AmountFigures
        legend(LegendArray, 'Interpreter', 'none');
    end
end

end

function MCS = DeriveMCSfromName(TestName)
MCSpos = strfind(TestName, 'MCS') + 3;
MCSend = MCSpos;
if MCSend ~= length(TestName)
if ~isempty(str2num(TestName(MCSpos+1)))
    MCSend = MCSend + 1;
end
end
MCS = TestName(MCSpos : MCSend);
end

function Font = DeriveFontAddSymb(TestName)
Font = '';
if contains(TestName, 'NCCP')
    Font = '\it';
elseif contains(TestName, 'ZP')
    Font = '\bf';
end
end

