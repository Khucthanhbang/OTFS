function [FilesNames, LegendNames, Interph2dBs, InterpMsgs] = ...
    DrawBERandFERwithInterp(Input1, ProbVals, isDraw)
%
% ������ ���������� ������ ����������� ������� � �������� ������.
% ����� ������ ��������� ���������� �������� ��������� ������/���, ���
% ������� ����������� �������� ����������� ������.
%
% ������� ����������:
%   Input1 - �������������� ����������, ����������� �������
%       ������-�����������:
%       ) ���� Input1 = '' ��� [] ��� ����������� (�.�. ��� �������
%           ����������), �� ������������, ���� �� ����� Results �, ���� ���
%           ����, �� ����������� ���������� ���� ������������ � ���
%           ������-�����������;
%       ) ���� Input1 = '_dir' ����������� ���� ������ �����, �� �������
%           ���������� ��������� ���������� ���� ������������ � ���
%           ������-�����������;
%       ) ���� Input1 = '_files' ����������� ���� ������ ������-
%           �����������, ��� ������� ���������� ��������� ����������;
%       ) ���� Input1 - ��� �����, �� ����������� ���������� ����
%           ������������ � ��� ������-�����������
%       ) ���� Input1 - cell-������ ��� ������-�����������, �� �����������
%           �� ����������.
%   ProbVals - �������������� ����������, ������ �� ���� ��������
%       ������������ BER � FER, ��� ������� ����� ���������� ��������
%       h2db ���� �������� ������������ � ���� (10*lg(h2), lg(Pr)). ����
%       ���� ���������� ��� ��� ��� ����� [], �� ������������ �� ��������.
%   isDraw - �������������� ����������, ����, �����������, ����� �� ������
%       ���������� �������� (������ ������������, ����� ���������� ������
%       �������� ������ Interph2dBs � InterpMsgs). �� ��������� isDraw = 1.
%
% �������� ����������:
%   FilesNames - cell-������ � ������� ������� ������-�����������.
%   LegendNames - cell-������ � �������� (��� ����) ������� ������-
%       ����������� ��� ����������.
%   Interph2dBs - �������������� ����������, ������ (2 � NumFiles) ��
%       ���������� h2db, ����������� � ���������� ������������.
%   InterpMsgs - �������������� ����������, cell-������ (2 � NumFiles) �
%       ����������� �� ������� ������������.

% ������������� �������� ���������� �� ������ ������� ����������� �������
    FilesNames  = cell(0);
    LegendNames = cell(0);
    Interph2dBs = zeros(3, 0);
    InterpMsgs  = cell(3, 0);

% ������� ������� ����������, ���������� � ������ �������    
    % ������ �����, ���������, ����� � ��� ������� ������� �������
    % ������������ ������ ����������
        % ���������, �������� �� ��� ������� ��� ��������� �������� Input1
            isZeroAsumpt = 0;
            if nargin == 0
                isZeroAsumpt = 1;
            else
                if isempty(Input1)
                    isZeroAsumpt = 1;
                end
                if isstring(Input1)
                    if strcmp(Input1, '')
                        isZeroAsumpt = 1;
                    end
                end
            end

        % ���� ��, �� ������������ � ����� ��������
            if isZeroAsumpt
                DirName = 'Results';
                if ~isfolder(DirName)
                    error('����������� ���������� Results!')
                end
                isChoseDir = 0;
                isFindFilesInDir = 1;
                isChoseFiles = 0;
            end

        % ���� ���, �� ���������� ������ �������� � ������������ � ���
            if ~isZeroAsumpt % nargin > 0
                if iscell(Input1)
                    if sum(isfile(Input1)) ~= numel(Input1)
                        error(['�� ��� �������� cell-������� Input1 ', ...
                            '�������� ������� ������!'])
                    end
                    isChoseDir = 0;
                    DirName = '';
                    isFindFilesInDir = 0;
                    isChoseFiles = 0;
                    FilesNames = Input1(:);
                elseif ischar(Input1)
                    if isfolder(Input1)
                        isChoseDir = 0;
                        DirName = Input1;
                        isFindFilesInDir = 1;
                        isChoseFiles = 0;
                    elseif isfile(Input1)
                        isChoseDir = 0;
                        [DirName, ~, ~] = fileparts(Input1);
                        isFindFilesInDir = 0;
                        isChoseFiles = 0;
                        FilesNames = {Input1(length(DirName)+2:end)};
                    elseif strcmp(Input1, '_dir')
                        isChoseDir = 1;
                        isFindFilesInDir = 1;
                        isChoseFiles = 0;
                    elseif strcmp(Input1, '_files')
                        isChoseDir = 0;
                        isFindFilesInDir = 0;
                        isChoseFiles = 1;
                    else
                        error('�� ������� ���������� ��������� ��������!')
                    end
                else
                    error('�� ������� ���������� ��������� ��������!')
                end
            end

    % ������ �������, ����� �� ����� ��������� �������� h2dB, ��� �������
    % ����������� �������� �����������
        isNeedInterp = 0;
        if nargin > 1
            if ~isempty(ProbVals)
                isNeedInterp = 1;
            end
        end
        
    % ��������� �������� ���������� isDraw
        if nargin < 3
            isDraw = 1;
        end

% ����������� FilesNames � LegendNames
    % ��� ������������� ������� ������ ������ ���������� � ������������
        if isChoseDir
            DirName = uigetdir();
            if isempty(DirName)
                return
            end
        end

    % ��� ������������� � ���������� DirName ����� ��� *.mat �����
        if isFindFilesInDir
            % ������� ���������� � ���������� ����������
                Listing = dir(DirName);

            % �������������� cell-������ ��� �������� ��� ������
                FilesNames = cell(0);

            % ���� �� ���� ������ ����������
                for k = 1:length(Listing)
                % ���� ���������, ����� ��������������� ������� ���
                % ������ � ���� ���������� mat
                    if ~Listing(k).isdir
                        FName = Listing(k).name;
                        if length(FName) > 4
                            if isequal(FName(end-3:end), '.mat')
                            % ������� ��� ����� � ������
                                FilesNames{end+1} = FName; %#ok<AGROW>
                            end
                        end
                    end
                end

            % ���� ����� �� �������
                if isempty(FilesNames)
                    error(['� ���������� %s �� ������� ����� � ', ...
                        '������������!'], DirName);
                end
        end

    % ��� ������������� ������� ������ ������ ������ � ������������
        if isChoseFiles
            [FilesNames, DirName] = uigetfile('*.mat', ...
                'Select a File or Files', 'MultiSelect', 'on');
            if isequal(FilesNames, 0)
                return
            end
            if ~iscell(FilesNames)
                FilesNames = {FilesNames};
            end
        end

    % ��������, ����� � ������������ ������ ������ ���� ������ *.mat �����
    % ����������, �������� ����� ���������� ������ ��� ������ ������ �����
    % isChoseFiles (���� ������������ ���� ������) ��� ��� ����� ��������
    % �����(��).
        if ~isFindFilesInDir
            Buf = FilesNames;
            FilesNames = cell(0);
            for k = 1:length(Buf)
                isOk = 0;
                if length(Buf{k}) > 4
                    if strcmp(Buf{k}(end-3:end), '.mat')
                        isOk = 1;
                    end
                end
                if isOk
                    FilesNames{end+1} = Buf{k}; %#ok<AGROW>
                end
            end

            if isempty(FilesNames)
                error('����� ��������� ������ ��� �� ������ *.mat �����!');
            end
        end
        
    % ���������� ������ ����� ������ � ������� ��� �������, ���������
    % ������ �� ����� ����� ��� ���� � ����������
        LegendNames = cell(size(FilesNames));
        for k = 1:length(FilesNames)
            LegendNames{k} = FilesNames{k}(1:end-4);
            FilesNames{k} = fullfile(DirName, FilesNames{k});
        end
        NumFiles = length(FilesNames);
        
% ���������� BER � FER � ������������ ��� �������������
    % �������� ������� � ���
        if isDraw
            f  = cell(2, 1);
            ax = cell(2, 1);
            for k = 1:2
                f{k} = figure;
                    ax{k} = axes;
            end
        end

    % ��������� ����� ��������
        CurvesNames = {'BER', 'FER'};
        
    % ���������� ���������� � ������������ ������������
        if isNeedInterp
            Interph2dBs = zeros(2, NumFiles);
            InterpMsgs = cell(2, NumFiles);
        end
            
    % ���� �� ���� ��� ��������� ������
        % ���������� ��� �������� ������ BER, FER
            Probs = cell(1, 2);
        for k = 1:NumFiles
            % �������� �����������
                load(FilesNames{k}, 'Res', 'Params');

            % ��������� �������, ��� ���������� �������� ��������
                Poses = (Res.NumErBits >= ...
                    Params.BER.MinNumErBits) & (Res.NumErFrames ...
                    >= Params.BER.MinNumErFrames);

            % ��������� ����������� ������
                Probs{1} = Res.NumErBits(Poses) ./ Res.NumTrBits(Poses);
                Probs{2} = Res.NumErFrames(Poses) ./ ...
                    Res.NumTrFrames(Poses);

            % ������� �������� ���
                h2dBs = Res.h2dBs(Poses);

            % ���������� ��� ��������� ������ ��������
                if isDraw
                    for n = 1:2
                        figure(f{n});
                        hold on;
                        plot(h2dBs, Probs{n}, 'LineWidth', 1, 'Marker', ...
                            '.', 'MarkerSize', 8);
                    end
                end

            % ��� ������������� ��������� �������� h2dB, ��� �������
            % ����������� �������� �����������
                if isNeedInterp
                    for n = 1:2
                        [Interph2dBs(n, k), InterpMsgs{n, k}] = ...
                            BERLinInterp(ProbVals(n), h2dBs, ...
                            Probs{n});
                        if ~isempty(InterpMsgs{n, k})
                            fprintf('���������� %s, ������ %s:\n', ...
                                LegendNames{k}, CurvesNames{n});
                            disp(InterpMsgs{n, k});
                        end
                    end
                end
        end

    % ������� �����, ��������, ������� � ����������� ������
        if isDraw
            for k = 1:2
                figure(f{k});

                % ������� �����
                    grid on;

                % ������� ������������ ������� �� ��� �������
                    set(ax{k}, 'YScale', 'log');

                % �������� ������� � ��� �������
                    title(CurvesNames{k});
                    xlabel('{\ith}^2 (dB)');

                % ���������� ����������� BER ��� QAM4 � QAM16 ��
                % ����������� 1e-6
                    BufNames = LegendNames;
%                     if k == 1
%                         h2dB = 0:0.1:10.5;
%                         BER = berawgn(h2dB, 'qam', 4);
%                         plot(h2dB, BER);
% 
%                         h2dB = 0:0.1:14.4;
%                         BER = berawgn(h2dB, 'qam', 16);
%                         plot(h2dB, BER);
% 
%                         h2dB = 0:0.1:18.8;
%                         BER = berawgn(h2dB, 'qam', 64);
%                         plot(h2dB, BER);
%                         
%                         BufNames{end+1} = 'QPSK'; %#ok<AGROW>
%                         BufNames{end+1} = '16PSK'; %#ok<AGROW>
%                         BufNames{end+1} = '64QAM'; %#ok<AGROW>
%                     end
% 
                % ������� �������
                    legend(BufNames, 'Interpreter', 'none', ...
                        'AutoUpdate', 'off');
            end
        end

    % ���������� ����� ������������
        if isDraw
            if isNeedInterp
                for k = 1:NumFiles
                    for n = 1:2
                        if isempty(InterpMsgs{n, k})
                            figure(f{n});
                            plot(Interph2dBs(n, k), ProbVals(n), ...
                                'LineWidth', 1, 'Marker', '.', ...
                                'MarkerSize', 15, 'Color', 'r');
                        end
                    end
                end
            end
        end

    % ������� ����� � ���� ����� ����
        if isDraw
            for k = 1:2
                set(f{k}, 'WindowStyle', 'Docked');
            end
        end