classdef ClassBERRuler < handle
% �����-��������, ����������� ������� ������ ��� ������ ������ ����������.
% ������������� ��� ��������� ������ - ������ ������ ������������������
% (BER � FER) � ������ ��������������� ��� (CCDF) ��� ���������� ��������
% �������� �������, ������������� �� ������� �������� � ���������� � ��.
%
% -------------------------------------------------------------------------
% � ������ ������� ������ ������������������ ������ ������� �����
% ���������������, ����
%   ) ��������� ��������� ���
%   ) ������� ����������� ���������� � ���������� ���������� ������
%     ������ ���� �����, ��� MinNumTrFrames
%
% �������� ������ ������ ������������������ ���������������, ����
%   ) ��������� ��������� ���
%   ) ��������� ����������� ������������� �������� h2
%
% ��������� ���������, ���� �������� ��� ������, ��� MaxNumTrBits, ���
%   �������� ������ ������, ��� MaxNumTrFrames.
%
% ������� ����������� ������ ����������, ���� ������ �����������
%   ������� ������ ������ ���� �����, ��� MinBER, � ������ �����������
%   �������� ������ ������ ���� �����, ��� MinFER.
%
% ���������� ��������� �����������, ���� ���������� ������� ������
%   ������ ���� �����, ��� MinNumErBits, � ���������� �������� ������
%   ������ ���� �����, ��� MinNumErFrames.
%
% �������������� ������ ����� ������ ������������������ ������ �� ���
%   ���, ���� ��� ���� �������� ����� ������ ������������������ ��
%   ����� �����, ���
%   ) ��������� ������������ ������� ������ ����� ��������� �������
%     ������ ���� �����, ��� MaxBERRate, ���
%   ) ������� h2 ����� ����� ������� ������ ���� ����� h2dBMinStep.
%
% -------------------------------------------------------------------------
% � ������ ������� ��������������� ��� ������ ������ ����� ��� �����
% ������������� ������ �������� ������������� ���������� �������� � �� -
% PAPRVals - � ���������������, ����
%   ) ��������� ��������� ���
%   ) ������� ����������� ���������� � ���������� ��������������� ������
%     ������ ���� �����, ��� MinNumPAPRFrames
% 
% ��������� ���������, ���� ������������� ��� ������, ��� MaxNumPAPRBits,
% ��� ������������� ������ ������, ��� MaxNumPAPRFrames ��� �����������
% �������� ������� ������, ��� MaxNumPAPRSamples.
%
% ���������� ��������� �����������, ���� ����� ��������������� ��������
% PAPRVals ������� ���� �� ����, ����������� ��������� �������� <= ��������
% ����������� MinPAPRProb � ���������� ��������� �������� ������ ����
% �����, ��� MinNumPAPRSamples, ����� ��� ���� ���������� ���������������
% ������ ������, ��� MinNumPAPRFrames.

properties (Constant)
    % [MCS, h2dB] 24...31 - TBD
    h2dB0_1BERperMCSnoLDPC = ...
       [0,  0; ...
        1,  0; ...
        2,  0; ...
        3,  0; ...
        4,  0; ...
        5,  0; ...
        6,  0; ...
        7,  0; ...
        8,  0; ...
        9,  0; ...
        10, 3; ...
        11, 3; ...
        12, 3; ...
        13, 3; ...
        14, 3; ...
        15, 3; ...
        16, 3; ...
        17, 6; ...
        18, 6; ...
        19, 6; ...
        20, 6; ...
        21, 6; ...
        22, 6; ...
        23, 6; ...
        24, 0; ...
        25, 0; ...
        26, 0; ...
        27, 0; ...
        28, 0; ...
        29, 0; ...
        30, 0; ...
        31, 0];
    h2dB0_1BERperMCSwithLDPC = ...
       [0,  0.2; ...
        1,  0.2; ...
        2,  0.2; ...
        3,  0.2; ...
        4,  0.2; ...
        5,  0.2; ...
        6,  0.2; ...
        7,  0.2; ...
        8,  0.2; ...
        9,  0.2; ...
        10, 1.6; ...
        11, 2.8; ...
        12, 2.8; ...
        13, 2.8; ...
        14, 2.8; ...
        15, 3.4; ...
        16, 3.4; ...
        17, 4; ...
        18, 4; ...
        19, 4.6; ...
        20, 5.2; ...
        21, 5.6; ...
        22, 5.6; ...
        23, 6; ...
        24, 0; ...
        25, 0; ...
        26, 0; ...
        27, 0; ...
        28, 0; ...
        29, 0; ...
        30, 0; ...
        31, 0];
    
    h2dBMaxStepNo_AWGN_LDPC = 1.6;
end

properties % ���������� �� ���������� �������� ������� � �� �������� ��
    % ��������� - ���������, �� ��������� � �������� ������
    % ������������������
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % ����� ������ ������
        isBER = true;
    % ������ ���������� ���-�������
    % 1 - � ������� Sig Symbol � ���������� ����������� ��� ��������
    %     ��������� ���������� �������� � �������
    % 2 - � ������� Sig Symbol � ���������� ����������� ���� ��������, �
    %     ������ - �������� ��������� ���������� �������� � �������
        PAPRType = 2;
    % ��� ����� ��� ���������� �����������
    % ���� � SaveFileName ������ '%xd', �� ��� �������� ������������ �����
    % ����� ������������ ������� sprintf('Results%02d', ParamsNumber), ���
    % ParamsNumber - ����� ������ ����������
        SaveFileName = 'Results%02d';
    % ��� ���������� ��� ���������� �����������
    % ����������� �����: 'TestRegressionResults' �
    % 'ReferenceRegressionResults'. �������� ����, ��� ��� ����� ��
    % ������������ ����������� � ReadSetup.
        SaveDirName = 'Results';
    % ���������� ������, ������������ � �������������� �� ���� ��������.
    % ��� ������������� Common.NumWorkers > 1 �������, �����
    % NumOneIterFrames �������� �� Common.NumWorkers ��� �������.
        NumOneIterFrames = 100;
    % ���������� ����, ������������ ��� ������������ ����������        
        NumWorkers = 1;
end
properties % ���������� �� ���������� �������� ������� � �� �������� ��
    % ��������� - ���������, ��������� � �������� ������ ������������������

    % ���������� ����������� ������ ����� ������� ��� �������� � ������ �
    % ��� ��������, ��������� � h2
        h2Precision = 2;
    % ���������� ������ ����� ������� ��� �������� BER, ����������� � ����    
        BERPrecision = 8;
    % ���������� ��������, ������������ ��� ����������� ����� ���������� �
    % ����� ��������� ��� � ����
        BERNumRateDigits = 10;
    % ���������� ��������, ������������ ��� ����������� ����� ���������� �
    % ����� ��������� ������ � ����
        FERNumRateDigits = 7;
        
    % ---------------------------------------------------------
    
    % ����������� ���������� ������������ ��� ������ ����� ������
    % ������������������ ������ (��� ����������� ����� ���������� ���
    % ����������� ������������� � �������� ��������������)
        MinNumTrFrames = 100;

    % ---------------------------------------------------------
    
    % �������� h2 (��) ������ ����� ��� ������� ������������������
        h2dBInit = 0;
    % ��������� �������� ���� (��) ��� �������� � ����� ������ ��� �������
    % ������������������
        h2dBInitStep = 0.2;
    % ������������ �������� ���� (��) ��� �������� � ����� ������ ���
    % ������� ������ ������������������
        h2dBMaxStep = 0.4;
    % ����������� �������� ���� (��)
        h2dBMinStep = 0.1;
    % ������������ �������� ���������������� ��������� ������/��� (����
    % ������ ������������������ ������ �� ��������� �� ��������� BER ������
    % ����������, �� ��� ����������� �������� �������� �����������
    % ����������)
        h2dBMax = 30;

    % ---------------------------------------------------------
    
    % ��������� ����������� �������� BER, �� ���������� �������� ����������
    % ����� ����������� (����, �������, ����������� �� ���������
    % (BER.MaxNumTrBits) ��� ���� ����������� �� �������� ������)
        MinBER = 10^-3;
    % ����������� ���������� ��������� ��� � ������ �����
        MinNumErBits = 5*10^2;
    % ��������� ����������� �������� FER, �� ���������� �������� ����������
    % ����� �����������
        MinFER = 1;
    % ����������� ���������� ��������� ������ � ������ �����
        MinNumErFrames = 10^2;

    % ---------------------------------------------------------
    
    % ������������ ���������� ���������� ���
        MaxNumTrBits = inf;
    % ������������ ���������� ���������� ������
        MaxNumTrFrames = 10^4;

    % ---------------------------------------------------------
    
    % ������������ ��������� ������������ ������� ������ � ��������
    % ������, ������ �������� ���������� ���������� ���� h2dB. �������, ���
    % ���� ��� ���������� "����������" ������ ������������������, ��
    % �������� ����� �������� ����������� ������ ��� ������, ��� ������
    % �������� h2 (��). ��� ���� ������ ����� ����������� ������
    % ��������� �������� ����������� ������. �������, ���� ���
    % ���������� ���� ��������� ������������ ������ ���� �������, ��
    % ��� ��������� ���� ��� ����� ��� ������ �, ����� ������
    % ���������� ������ ������������������ (����, �� ���� � ����������� ��
    % ���������!), ���� ��������� ��� �� ��� h2 (��).
        MaxBERRate = 5;
    % ����������� ��������� ������������ ������� ������ � ��������
    % ������, ������ �������� ���������� ���������� ���� h2dB. �������� �
    % �������� ��������, ����� ������ �������� �������� �� �������
    % ����� ������ ������������������. � ����� �������� ����� �����
    % ����������� ��� �� ��� h2 (��), �� ����� �������� ���������� ��
    % ��������� ����������� ������.
        MinBERRate = 2;
        
    % ---------------------------------------------------------
    % ����� �� ������ ���������� ���� command window ��� ������ �����
    % ������ ����������� NumOneIterFrames ������
        isRealTimeLogCWin = 1;
    % ����� �� ������ ���������� ���� � ����� ��� ������ �����
    % ������ ����������� NumOneIterFrames ������
        isRealTimeLogFile = 0;
end

properties % ���������� �� ���������� �������� ������� � �� �������� ��
    % ��������� - ���������, ��������� � �������� ��������������� ���
    
    % ���������� ��������, ������������ ��� ����������� ����� �������������
    % � ���������� �������� ������� � ����
        NumSamplesDigits = 10;
    % ���������� ��������, ������������ ��� ����������� ����� �������������
    % ������ ������� � ����
        NumFramesDigits = 6;
    % ���������� ��������, ������������ ��� ����������� �����
    % �������������� ��� � ����
        NumBitsDigits = 10;
    % ���������� ������ ����� ������� ��� �������� PAPR, ������������ �
    % ����
        PAPRPrecision = 2;
    % ���������� ������ ����� ������� ��� �������� �����������,
    % ����������� � ����
        ProbPrecision = 6;
    
    % ---------------------------------------------------------
    
    % ��������������� �������� ���-������� � ��
        PAPRVals = 0:0.1:15;
    % ������� �����������
        MinPAPRProb = 10^-2;
    % ��������� ����������� ���������� �������� ������� � ����� � �������
    % ������������
        MinNumPAPRSamples = 1000;
        
    % ---------------------------------------------------------
    
    % ����������� ���������� ������������ ������
        MinNumPAPRFrames = 100;
    % ������������ ���������� �������������� ���
        MaxNumPAPRBits = inf;
    % ������������ ���������� ��������������� ������
        MaxNumPAPRFrames = inf;
    % ������������ ���������� ������������� �������� �������
        MaxNumPAPRSamples = 10^10;
end

properties % ���������� �� ���������� ��� ����������� ���������� ������
    % �������� ��� �������� �� ���������
end
properties % ����������� ���������� - �����
    % ����������, ������������ �������
        isStop;
        OneWorkerNumOneIterFrames;
    % ���, ������ ����� ������ ��� ����������
        Log;
        FullSaveFileName;
        FullLogFileName;
end
properties % ����������� ���������� - ��������� � �������� ������
    % ������������������ 

    % ����������, ������������ �������
        h2dB;  
    % ���������� ����������
        strh2Precision;
        strh2NumDigits;
        strBERPrecision;
        strBERNumRateDigits;
        strFERNumRateDigits;
    % ����������, ������������ ��� ���������� ����������
        h2dBs;
        NumTrBits;
        NumTrFrames;
        NumErBits;
        NumErFrames;
    % ���������, ������������ ��� �������� ����� ����������� ������� ������
    % ������������������
        isMainCalcFinished;
        h2dBStep;
        Addh2dBs;
    % ����������, ���������� ������������ ���������� isRealTimeLogCWin �
    % isRealTimeLogFile
        isRealTimeLog;
end
properties % ����������� ���������� - ��������� � �������� ���������������
    % ���
    
    % ���������� ����������
        strNumSamplesDigits;
        strNumFramesDigits;
        strNumBitsDigits;
        strPAPRPrecision;
        strProbPrecision;
    % ����������, ������������ ��� ���������� ����������
        NumCaptPAPRSamples;
        NumPAPRSamples;
        NumPAPRFrames;
        NumPAPRBits;
end
methods
    function obj = ClassBERRuler(Params, ParamsNum, NumParams)
    % �����������. ����� ���������������� �������� ���������� �� ����������
    % �������. ��� ���� ���������� �� ����������, ������ ���� �������������
    % �������� �� ���������, ��������� � ������ properties. ��� ����
    % ���������� �� ���������� ����� ��������� �������� ������� �������� ��
    % Setup, ���� � Setup ���� ��������, �� ��� �������� �������� ��
    % ���������. ������ �������� ���������� �� ���� ������� �� �� Setup ���
    % ��������� �� ��������� ������ ���� �������� �� ������������. ����� �
    % ������������ ����� ���� ����������� �������� ���������/����
    % ����������� ����������.

        % ������������� �������� ���������� �� ����������
            % ��� ���������� ������ ������� ������ ����/���� �� Params
                if isfield(Params, 'Common')
                    Common = Params.Common;
                else
                    Common = [];
                end
                if isfield(Params, 'BER')
                    BER = Params.BER;
                else
                    BER = [];
                end
            % ---------------------------------------------------------    
                if isfield(BER, 'isBER')
                    obj.isBER = BER.isBER;
                end
                if isfield(BER, 'PAPRType')
                    obj.PAPRType = BER.PAPRType;
                end
                if isfield(Common, 'SaveFileName')
                    obj.SaveFileName = Common.SaveFileName;
                end
                if ~isempty(regexp(obj.SaveFileName, '%\d+d', 'once'))
                    obj.SaveFileName = sprintf(obj.SaveFileName, ...
                        ParamsNum);
                end
                if isfield(Common, 'SaveDirName')
                    obj.SaveDirName = Common.SaveDirName;
                end
                if isfield(Common, 'NumOneIterFrames')
                    obj.NumOneIterFrames = Common.NumOneIterFrames;
                end
                if isfield(Common, 'NumWorkers')
                    obj.NumWorkers = Common.NumWorkers;
                end
            % ---------------------------------------------------------
                if isfield(BER, 'h2Precision')
                    obj.h2Precision = BER.h2Precision;
                end
                if isfield(BER, 'BERPrecision')
                    obj.BERPrecision = BER.BERPrecision;
                end
                if isfield(BER, 'BERNumRateDigits')
                    obj.BERNumRateDigits = BER.BERNumRateDigits;
                end
                if isfield(BER, 'FERNumRateDigits')
                    obj.FERNumRateDigits = BER.FERNumRateDigits;
                end
            % ---------------------------------------------------------
                if isfield(BER, 'MinNumTrFrames')
                    obj.MinNumTrFrames = BER.MinNumTrFrames;
                end
            % ---------------------------------------------------------
                if isfield(BER, 'h2dBInit')
                    obj.h2dBInit = BER.h2dBInit;
                elseif isfield(Params, 'SchSource')
                if isfield(Params.SchSource, 'McsIndex')
                    if isfield(Params, 'NrSch')
						if isfield(Params.NrSch, 'isTransparent')
							if Params.NrSch.isTransparent
								obj.h2dBInit = obj.h2dB0_1BERperMCSnoLDPC(...
									Params.SchSource.McsIndex+1, 2);
							else
								obj.h2dBInit = obj.h2dB0_1BERperMCSwithLDPC(...
									Params.SchSource.McsIndex+1, 2);
							end
						else
							obj.h2dBInit = obj.h2dB0_1BERperMCSwithLDPC(...
								Params.SchSource.McsIndex+1, 2);
						end
					else
						obj.h2dBInit = obj.h2dB0_1BERperMCSwithLDPC(...
								Params.SchSource.McsIndex+1, 2);
                    end
					
                end
                end
                if isfield(BER, 'h2dBInitStep')
                    obj.h2dBInitStep = BER.h2dBInitStep;
                end
                if isfield(BER, 'h2dBMaxStep')
                    obj.h2dBMaxStep = BER.h2dBMaxStep;
                elseif isfield(Params, 'NrSch')
                if isfield(Params.NrSch, 'isTransparent')
				if  Params.NrSch.isTransparent
					obj.h2dBMaxStep = obj.h2dBMaxStepNo_AWGN_LDPC;
				end
                end
				elseif isfield(Params, 'NrChannel')
                if isfield(Params.NrChannel, 'Type')
				if  strcmp(Params.NrChannel.Type, 'Fading')
					obj.h2dBMaxStep = obj.h2dBMaxStepNo_AWGN_LDPC;
				end
                end
                end
                if isfield(BER, 'h2dBMinStep')
                    obj.h2dBMinStep = BER.h2dBMinStep;
                end
                if isfield(BER, 'h2dBMax')
                    obj.h2dBMax = BER.h2dBMax;
                end
            % ---------------------------------------------------------
                if isfield(BER, 'MinBER')
                    obj.MinBER = BER.MinBER;
                end
                if isfield(BER, 'MinNumErBits')
                    obj.MinNumErBits = BER.MinNumErBits;
                end
                if isfield(BER, 'MinFER')
                    obj.MinFER = BER.MinFER;
                end
                if isfield(BER, 'MinNumErFrames')
                    obj.MinNumErFrames = BER.MinNumErFrames;
                end
            % ---------------------------------------------------------
                if isfield(BER, 'MaxNumTrBits')
                    obj.MaxNumTrBits = BER.MaxNumTrBits;
                end
                if isfield(BER, 'MaxNumTrFrames')
                    obj.MaxNumTrFrames = BER.MaxNumTrFrames;
                end
            % ---------------------------------------------------------
                if isfield(BER, 'MaxBERRate')
                    obj.MaxBERRate = BER.MaxBERRate;
                end
                if isfield(BER, 'MinBERRate')
                    obj.MinBERRate = BER.MinBERRate;
                end
            % ---------------------------------------------------------
                if isfield(Common, 'isRealTimeLogCWin')
                    obj.isRealTimeLogCWin = Common.isRealTimeLogCWin;
                end
                if isfield(Common, 'isRealTimeLogFile')
                    obj.isRealTimeLogFile = Common.isRealTimeLogFile;
                end
            % ---------------------------------------------------------
                if isfield(BER, 'NumSamplesDigits')
                    obj.NumSamplesDigits = BER.NumSamplesDigits;
                end
                if isfield(BER, 'NumFramesDigits')
                    obj.NumFramesDigits = BER.NumFramesDigits;
                end
                if isfield(BER, 'NumBitsDigits')
                    obj.NumBitsDigits = BER.NumBitsDigits;
                end
                if isfield(BER, 'PAPRPrecision')
                    obj.PAPRPrecision = BER.PAPRPrecision;
                end
                if isfield(BER, 'ProbPrecision')
                    obj.ProbPrecision = BER.ProbPrecision;
                end
            % ---------------------------------------------------------
                if isfield(BER, 'PAPRVals')
                    obj.PAPRVals = BER.PAPRVals;
                end
                if isfield(BER, 'MinPAPRProb')
                    obj.MinPAPRProb = BER.MinPAPRProb;
                end
                if isfield(BER, 'MinNumPAPRSamples')
                    obj.MinNumPAPRSamples = BER.MinNumPAPRSamples;
                end
            % ---------------------------------------------------------
                if isfield(BER, 'MinNumPAPRFrames')
                    obj.MinNumPAPRFrames = BER.MinNumPAPRFrames;
                end
                if isfield(BER, 'MaxNumPAPRBits')
                    obj.MaxNumPAPRBits = BER.MaxNumPAPRBits;
                end
                if isfield(BER, 'MaxNumPAPRFrames')
                    obj.MaxNumPAPRFrames = BER.MaxNumPAPRFrames;
                end
                if isfield(BER, 'MaxNumPAPRSamples')
                    obj.MaxNumPAPRSamples = BER.MaxNumPAPRSamples;
                end

        % ����������� �������� ����������� ���������� - �����
            % ������������� ����������, ������������ �������:
                obj.isStop = false;
                % ����������� ����� ������, �������������� �� ���� ��������
                % ��� ������� worker
                    obj.OneWorkerNumOneIterFrames = zeros(1, ...
                        obj.NumWorkers) + round(obj.NumOneIterFrames ...
                        / obj.NumWorkers);
                    obj.OneWorkerNumOneIterFrames(end) = ...
                        obj.NumOneIterFrames - ...
                        sum(obj.OneWorkerNumOneIterFrames(1:end-1));

            % ��� ������������� �������� ����� ��� ���������� �����������
                if ~isfolder(obj.SaveDirName)
                    mkdir(obj.SaveDirName);
                end

            % ��� ����� ��� ���������� ����
                if isunix % Linux platform
                    % Code to run on Linux platform
                    PathDelimiter = '/';
                elseif ispc % Windows platform
                    % Code to run on Windows platform
                    PathDelimiter = '\';
                else
                    DeleteObjects();
                    error('Cannot recognize platform!');
                end            
                obj.FullLogFileName = [obj.SaveDirName, PathDelimiter, ...
                    obj.SaveFileName, '.log'];

            % ��� ����� ��� ���������� �����������
                obj.FullSaveFileName = [obj.SaveDirName, PathDelimiter, ...
                    obj.SaveFileName, '.mat'];

            % isRealTimeLog
                obj.isRealTimeLog(1) = obj.isRealTimeLogCWin;
                obj.isRealTimeLog(2) = obj.isRealTimeLogFile;

            % ���
            % �� ����� ���� ������� ��� ����, ������ ��� ������ �� �����,
            % ������ - ��� ���������� � ����
                % ������ ������
                    LogStr1 = sprintf(['%s Start of calculation the ', ...
                        'curve %s (%d of %d).\n'], datestr(now), ...
                        obj.SaveFileName, ParamsNum, NumParams);
                % ������ ������
                    LogStr2 = sprintf(['%s   Start of the main ', ...
                        'calculations.\n'], datestr(now));

                % �������� ������ � ���
                    obj.Log = cell(2, 1); % ��������� ��� ��� ����
                    obj.Log{1} = {LogStr1; LogStr2};
                    obj.Log{2} = obj.Log{1}; % �������� ������ ��� ��
                        % ������

                    for k = 1:2
                        if k == 1
                            obj.PrintLog(k, obj.isRealTimeLog(k));
                        else
                            obj.PrintLog(k, 1);
                        end
                        if obj.isRealTimeLog(k)
                            % ��������� ��� ��������� ������
                            obj.Log{k}{3} = '';
                        else
                            obj.Log{k} = cell(0);
                        end
                    end

        % ����������� �������� ����������� ���������� - BER
            % ������������� ����������, ������������ �������: h2dB � isStop
                obj.h2dB   = obj.h2dBInit;

            % ��������� ��������� ������� �����, ����������� �����������
            % �������� �������� ��� ������ ����
                obj.strh2Precision = sprintf('%d', obj.h2Precision);
                if obj.h2Precision == 0
                    obj.strh2NumDigits = sprintf('%d', ...
                        obj.h2Precision + 2);
                else
                    obj.strh2NumDigits = sprintf('%d', ...
                        obj.h2Precision + 3);
                end
                obj.strBERPrecision     = sprintf('%d', obj.BERPrecision);
                obj.strBERNumRateDigits = sprintf('%d', ...
                    obj.BERNumRateDigits);
                obj.strFERNumRateDigits = sprintf('%d', ...
                    obj.FERNumRateDigits);

            % �������� ��� �������� h2
                obj.h2dBInit     = obj.Round(obj.h2dBInit);
                obj.h2dBInitStep = obj.Round(obj.h2dBInitStep);
                obj.h2dBMaxStep  = obj.Round(obj.h2dBMaxStep);
                obj.h2dBMinStep  = obj.Round(obj.h2dBMinStep);
                obj.h2dBMax      = obj.Round(obj.h2dBMax);

            % ������������� ����������, ������������ ��� ����������
            % ����������
                obj.h2dBs       = obj.h2dB;
                obj.NumTrBits   = 0;
                obj.NumTrFrames = 0;
                obj.NumErBits   = 0;
                obj.NumErFrames = 0;

            % ������������� ����������, ������������ ��� �������� �����
            % ����������� ������� ������ ������������������
                obj.isMainCalcFinished = false;
                obj.h2dBStep = obj.h2dBInitStep;
                obj.Addh2dBs = [];

        % ����������� �������� ����������� ���������� - PAPR
            % ��������� ��������� ������� �����, ����������� �����������
            % �������� �������� ��� ������ ����
                obj.strNumSamplesDigits = sprintf('%d', ...
                    obj.NumSamplesDigits);
                obj.strNumFramesDigits  = sprintf('%d', ...
                    obj.NumFramesDigits);
                obj.strNumBitsDigits    = sprintf('%d', ...
                    obj.NumBitsDigits);
                obj.strPAPRPrecision    = sprintf('%d', ...
                    obj.PAPRPrecision);
                obj.strProbPrecision    = sprintf('%d', ...
                    obj.ProbPrecision);
                
            % ������������� ����������, ������������ ��� ����������
            % ����������
                obj.NumCaptPAPRSamples = zeros(size(obj.PAPRVals));
                obj.NumPAPRSamples = 0;
                obj.NumPAPRFrames  = 0;
                obj.NumPAPRBits    = 0;
    end
    function isPointFinished = Step(obj, Objs)
        if obj.isBER
            isPointFinished = StepBER(obj, Objs);
        else
            isPointFinished = true;
            StepPAPR(obj, Objs);
        end
    end
    function StepPAPR(obj, Objs)
        % ���������� ����������
            for k = 1:length(Objs)
                obj.NumCaptPAPRSamples = obj.NumCaptPAPRSamples + ...
                    Objs{k}.Stat.NumCaptPAPRSamples;
                obj.NumPAPRSamples = obj.NumPAPRSamples + ...
                    Objs{k}.Stat.NumPAPRSamples;
                obj.NumPAPRFrames = obj.NumPAPRFrames + ...
                    Objs{k}.Stat.NumPAPRFrames;
                obj.NumPAPRBits = obj.NumPAPRBits + ...
                    Objs{k}.Stat.NumPAPRBits;

                Objs{k}.Stat.Reset();
            end

        % ���������, ��������� �� ��������� �������
            isComplexityExceeded = false;
            if obj.NumPAPRBits > obj.MaxNumPAPRBits || ...
                    obj.NumPAPRFrames > obj.MaxNumPAPRFrames || ...
                    obj.NumPAPRSamples > obj.MaxNumPAPRSamples
                obj.isStop = true;
                isComplexityExceeded = true;
            end
            
        % ���������, ������� �� ����������� ����������
            PAPRProbs = obj.NumCaptPAPRSamples ./ obj.NumPAPRSamples;
            isFinished = false;
            if obj.NumPAPRFrames > obj.MinNumPAPRFrames
                Poses1 = PAPRProbs <= obj.MinPAPRProb;
                Poses2 = obj.NumCaptPAPRSamples >= obj.MinNumPAPRSamples;
                if sum(Poses1 & Poses2) > 0
                    obj.isStop = true;
                    isFinished = true;
                end
            end
            
            if isComplexityExceeded
                isFinished = true;
            end
            
        % ���
            % ��������� ������� �����, � ������� ������� �����������
            % ���������� � ��� ���� � �� ����������� �������� PAPR
                Poses = obj.NumCaptPAPRSamples >= obj.MinNumPAPRSamples;
                if sum(Poses) > 0
                    BufPAPRProbs = PAPRProbs(Poses);
                    BufPAPRVals = obj.PAPRVals(Poses);
                    BufNumCaptPAPRSamples = obj.NumCaptPAPRSamples(Poses);
                    
                    [BufPAPRProbs, Pos] = min(BufPAPRProbs);
                    BufPAPRVals = BufPAPRVals(Pos(1));
                    BufNumCaptPAPRSamples = BufNumCaptPAPRSamples(Pos(1));
                else
                    BufPAPRProbs = 0;
                    BufPAPRVals = 0;
                    BufNumCaptPAPRSamples = 0;
                end
        
            % ����� ������
                LogStr = sprintf(['%s     NumSam = %', ...
                    obj.strNumSamplesDigits, 'd; NumFr = %', ...
                    obj.strNumFramesDigits, 'd; NumBits = %', ...
                    obj.strNumBitsDigits, 'd; PAPR = %0.', ...
                    obj.strPAPRPrecision, 'f; Prob = %0.', ...
                    obj.strProbPrecision, 'f = %', ...
                    obj.strNumSamplesDigits, 'd/%' , ...
                    obj.strNumSamplesDigits, 'd.'], datestr(now), ...
                    obj.NumPAPRSamples, obj.NumPAPRFrames, ...
                    obj.NumPAPRBits, BufPAPRVals, BufPAPRProbs, ...
                    BufNumCaptPAPRSamples, obj.NumPAPRSamples ...
                );

                if isFinished
                    SubS = ' Completed';
                    if isComplexityExceeded
                        SubS = [SubS, ' (complexity exceeded)'];
                    end
                    LogStr = [LogStr, SubS, '.'];
                end
                
                LogStr = sprintf('%s\n', LogStr);

            % ������� ����� ������ � ����
                for k = 1:2
                    obj.Log{k} = cell(0);
                    obj.Log{k}{1} = LogStr;
                end

        % ����� ���� �� ����� � ���������� ���� � ����
            for k = 1:2
                obj.PrintLog(k, false);
            end
    end
    function isPointFinished = StepBER(obj, Objs)
        % ���������� ����������
            for k = 1:length(Objs)
                obj.NumTrBits(end)   = obj.NumTrBits(end)   + ...
                    Objs{k}.Stat.NumTrBits;
                obj.NumTrFrames(end) = obj.NumTrFrames(end) + ...
                    Objs{k}.Stat.NumTrFrames;

                obj.NumErBits(end)   = obj.NumErBits(end)   + ...
                    Objs{k}.Stat.NumErBits;
                obj.NumErFrames(end) = obj.NumErFrames(end) + ...
                    Objs{k}.Stat.NumErFrames;

                Objs{k}.Stat.Reset();
            end

        % ���������, ��������� �� ��������� ������� ����� �����
            isComplexityExceeded = false;
            if (obj.NumTrBits(end) > obj.MaxNumTrBits) || ...
                    (obj.NumTrFrames(end) > obj.MaxNumTrFrames)
                isComplexityExceeded = true;
            end

        % ��������� �������� �� ������ ��� ������� ����� - ����
        % ���������� ����������� ����������, ���� ��������� ���������
        % �������
            isPointFinished = false;
            if ((obj.NumErBits(end) >= obj.MinNumErBits) && ...
                    (obj.NumErFrames(end) >= obj.MinNumErFrames) && ...
                    (obj.NumTrFrames(end) >= obj.MinNumTrFrames)) || ...
                    isComplexityExceeded
                isPointFinished = true;
            end

        % ���
            % ����� ������
                LogStr = sprintf(['%s     h2 = %', ...
                    obj.strh2NumDigits, '.', obj.strh2Precision, ...
                    'f dB; h2Step = %', obj.strh2NumDigits, '.', ...
                    obj.strh2Precision, 'f dB; BER = %0.', ...
                    obj.strBERPrecision, 'f = %', ...
                    obj.strBERNumRateDigits, 'd/%', ...
                    obj.strBERNumRateDigits, 'd; FER = %', ...
                    obj.strFERNumRateDigits, 'd/%', ...
                    obj.strFERNumRateDigits, 'd\n'], datestr(now), ...
                    obj.h2dB, obj.h2dBStep, obj.NumErBits(end) / ...
                    obj.NumTrBits(end), obj.NumErBits(end), ...
                    obj.NumTrBits(end), obj.NumErFrames(end), ...
                    obj.NumTrFrames(end));

                if isPointFinished
                    SubS = ' Completed';
                    if isComplexityExceeded
                        SubS = [SubS, ' (complexity exceeded)'];
                    end
                    LogStr = [LogStr(1:end-1), SubS, LogStr(end)];
                end

            % ������� ����� ������ � ����
                for k = 1:2
                    if obj.isRealTimeLog(k)
                        obj.Log{k}{end} = LogStr;
                    else
                        if isPointFinished
                            obj.Log{k} = {LogStr};
                        end
                    end
                end

        % ���� �� ��������� � �������� �������, �� �� ��������� BER,
        % FER � isComplexityExceeded ��������, �� ���������� �� ��
            isMainCalcJustFinished = false; % ��� ���� ����
            if isPointFinished && ~obj.isMainCalcFinished
                BER = obj.NumErBits   ./ obj.NumTrBits;
                FER = obj.NumErFrames ./ obj.NumTrFrames;

                if ((BER(end) <= obj.MinBER) && ...
                    (FER(end) <= obj.MinFER)) || ...
                    isComplexityExceeded
                    obj.isMainCalcFinished = true;
                    obj.h2dBStep = nan; % ���������
                    isMainCalcJustFinished = true; % ��� ���� ����
                end

                if length(BER) > 1
                    BERRate = BER(1:end-1) ./ BER(2:end);
                else
                    BERRate = 0.5*(obj.MinBERRate + obj.MaxBERRate);
                end
            end

        % ������� � ����� ����� ��� ������ ��������� ������� �����
            if isPointFinished && ~obj.isMainCalcFinished
                % ������� �������� h2dBStep
                    if BERRate(end) > obj.MaxBERRate
                        % ������� 1: �����������
                            % Buf = obj.Round(0.5*obj.h2dBStep);
                            % obj.h2dBStep = max(Buf, obj.h2dBMinStep);
                        % ������� 2: ����� �������� � ������
                        % ����������� ���������������� �����
                            RRate = BERRate(end) / obj.MaxBERRate;
                            if                      (RRate <  4)
                                DecFact = 1/2;
                            elseif (RRate >=  4) && (RRate < 16)
                                DecFact = 1/4;
                            elseif (RRate >= 16) && (RRate < 64)
                                DecFact = 1/8;
                            elseif (RRate >= 64)
                                DecFact = 1/16;
                            end
                            Buf = obj.Round(DecFact*obj.h2dBStep);
                            obj.h2dBStep = max(Buf, obj.h2dBMinStep);
                    elseif BERRate(end) < obj.MinBERRate
                        Buf = obj.Round(2*obj.h2dBStep);
                        obj.h2dBStep = min(Buf, obj.h2dBMaxStep);
                    end
                % ������� �������� h2dB
                    obj.h2dB = obj.h2dB + obj.h2dBStep;
                % �������� �� ��������� �� �������� h2dBMax
                    if obj.h2dB > obj.h2dBMax
                        obj.isMainCalcFinished = true;
                        isMainCalcJustFinished = true; % ��� ���� ����
                    end
                % ��������, �� ���������� �� ��-�� ����������
                % obj.h2dBStep = 0
                    if obj.h2dBStep < eps
                        obj.isMainCalcFinished = true;
                        isMainCalcJustFinished = true; % ��� ���� ����
                    end
            end

        % ���
            if isMainCalcJustFinished
                LogStr = '   The main calculations are completed.';
                if obj.h2dB > obj.h2dBMax
                    LogStr = [LogStr, ' (Maximum SNR is exceeded)'];
                end
                if obj.h2dBStep < eps
                    LogStr = [LogStr, ' (Zero h2 step obtained)'];
                end
                LogStr = sprintf('%s%s\n', datestr(now), LogStr);
                for k = 1:2
                    obj.Log{k}{end+1} = LogStr;
                end
            end

        % ���� �� ��������� � ������� �������������� ����� � ������
        % ��������� ����� ���������� ��-�� ���������� ���������, ��
        % ����� ��������� ��� ����� � �������� ���������� h2
            if isPointFinished && obj.isMainCalcFinished && ...
                    isComplexityExceeded && ~isMainCalcJustFinished
                % ������� ���������� � �������� ���������� h2
                    Poses = (obj.h2dBs <= obj.h2dB);
                    obj.h2dBs       = obj.h2dBs      (Poses);
                    obj.NumTrBits   = obj.NumTrBits  (Poses);
                    obj.NumTrFrames = obj.NumTrFrames(Poses);
                    obj.NumErBits   = obj.NumErBits  (Poses);
                    obj.NumErFrames = obj.NumErFrames(Poses);
                    NumDeleted1 = length(Poses) - sum(Poses);
                % ������� �� ������������ ������ Addh2dBs
                    Poses = (obj.Addh2dBs <= obj.h2dB);
                    obj.Addh2dBs = obj.Addh2dBs(Poses);
                    NumDeleted2 = length(Poses) - sum(Poses);
                % ���
                    LogStr = sprintf(['%s     %d results are deleted ', ...
                        'from main calculations and %d values of h2 ', ...
                        'are deleted from the set for additional ', ...
                        'calculations .\n'], datestr(now), NumDeleted1, ...
                        NumDeleted2);
                    for k = 1:2
                        obj.Log{k}{end+1} = LogStr;
                    end
            end

        % ������� � ����� ����� ��� ������ ������� �������������� �����
            if isPointFinished && obj.isMainCalcFinished
                % ��������� ��������� ��� ������� ��������������
                % �������� h2dB ��� ����� ������������ �����������
                % �����
                    if isempty(obj.Addh2dBs)
                        % ���������� ���������� �� ����������� h2dBs
                            [obj.h2dBs, I]  = sort(obj.h2dBs);
                            obj.NumTrBits   = obj.NumTrBits  (I);
                            obj.NumTrFrames = obj.NumTrFrames(I);
                            obj.NumErBits   = obj.NumErBits  (I);
                            obj.NumErFrames = obj.NumErFrames(I);
                        % ���������� BER � BERRate
                            BER = obj.NumErBits ./ obj.NumTrBits;
                            if length(BER) > 1
                                BERRate = BER(1:end-1) ./ BER(2:end);
                            else
                                BERRate = 0.5*(obj.MinBERRate + ...
                                    obj.MaxBERRate);
                            end
                        % ����� �����, ��� ���� ���������
                        % �������������� �����
                            Poses = find(BERRate > obj.MaxBERRate);
                            obj.Addh2dBs = (obj.h2dBs(Poses+1) + ...
                                obj.h2dBs(Poses)) / 2;
                            obj.Addh2dBs = obj.Round(obj.Addh2dBs);
                        % �������� �� ������, ��� ����������
                        % ������� ��������� �������� ���� �� ��� h2
                            % ������� 1 ������� �������� ����
                                % h2dBSteps = (obj.h2dBs(Poses+1) - ...
                                %     obj.h2dBs(Poses)) / 2;
                            % ������� 2 ������� �������� ����
                                h2dBSteps = min([obj.Addh2dBs - ...
                                    obj.h2dBs(Poses); ...
                                    obj.h2dBs(Poses+1) - ...
                                    obj.Addh2dBs]);
                                % ������� 2 - ����� ���������� ��-��
                                % ���������� obj.Addh2dBs
                            Poses = (h2dBSteps + 1000*eps >= ...
                                obj.h2dBMinStep);
                                % + 1000*eps ��� ����� ����������
                                % ������ � ������, ���� h2dBSteps �����
                                % obj.h2dBMinStep
                            obj.Addh2dBs = obj.Addh2dBs(Poses);
                        % ��������� � �����
                            if ~isempty(obj.Addh2dBs)
                                LogStr = sprintf([' %0.', ...
                                    obj.strh2Precision, 'f'], ...
                                    obj.Addh2dBs);
                                LogStr = sprintf(['%s   Start of the ', ...
                                    'additional calculations [%s].\n'], ...
                                    datestr(now), LogStr(2:end));
                                for k = 1:2
                                    obj.Log{k}{end+1} = LogStr;
                                end
                            end
                    end

                % ��������� � ���������� �������� Addh2dBs
                    if isempty(obj.Addh2dBs)
                        obj.isStop = true;

                        % ���
                            if ~isMainCalcJustFinished
                                LogStr = sprintf(['%s   The ', ...
                                    'additional calculations are ', ...
                                    'completed.\n'], datestr(now));
                                for k = 1:2
                                    obj.Log{k}{end+1} = LogStr;
                                end
                            end
                            LogStr = sprintf(['%s Calculations are ', ...
                                'completed.\n'], datestr(now));
                            for k = 1:2
                                obj.Log{k}{end+1} = LogStr;
                                obj.Log{k}{end+1} = newline;
                            end
                    else
                        obj.h2dB = obj.Addh2dBs(1);
                        obj.Addh2dBs = obj.Addh2dBs(2:end);
                    end
            end

        % ���������� � ������� ����� ����� - ���������� ������ ��������
        % � ������� � ����� ����������� ��������� ����� � ���������
        % ���������
            if isPointFinished && ~obj.isStop
                obj.h2dBs       = [obj.h2dBs, obj.h2dB];
                obj.NumTrBits   = [obj.NumTrBits,   0];
                obj.NumTrFrames = [obj.NumTrFrames, 0];
                obj.NumErBits   = [obj.NumErBits,   0];
                obj.NumErFrames = [obj.NumErFrames, 0];
                obj.ResetRandStreams();
            end

        % ����� ���� �� ����� � ���������� ���� � ����
            for k = 1:2
                obj.PrintLog(k, obj.isRealTimeLog(k));
                if obj.isRealTimeLog(k)
                    if isPointFinished && ~obj.isStop
                        obj.Log{k}{end+1} = '';
                    end
                else
                    obj.Log{k} = cell(0);
                end
            end
    end
    function Saves(obj, Objs, Params)
        % ����� ������ ��������� ��� ������� � ���������:
        % save(obj.FullSaveFileName, 'Objs', 'obj', 'Params');
        % ������ � ���� ������ ����� ����� ������������ �������
        % �������� ������� ��� �������� ������������� � ���� ���������
        % MATLAB. ������� ���� �� ������� ���� - ��������� ������
        % ������������������ � ��� ���������. ����� ����, ���� �
        % ���������� ����������� �����-������ ����� ������� ������� ���
        % ���������, �� �� ����� �������������� �������.
            
            % �������� � Params ��� ��������� BER. ��� �����������, �����
            % �� ����� ���������� ����������� ����� ������ � �������������
            % �����������
                Names = properties(obj);
                for k = 1:length(Names)
                    Params.BER.(Names{k}) = obj.(Names{k});
                end
        
            Res.isBER       = obj.isBER;
            
            Res.h2dBs       = obj.h2dBs;
            Res.NumErBits   = obj.NumErBits;
            Res.NumTrBits   = obj.NumTrBits;
            Res.NumErFrames = obj.NumErFrames;
            Res.NumTrFrames = obj.NumTrFrames;
            
            Res.PAPRVals           = obj.PAPRVals;
            Res.NumCaptPAPRSamples = obj.NumCaptPAPRSamples;
            Res.NumPAPRSamples     = obj.NumPAPRSamples;
            
            AlphaFreq = 1;
            if strcmp(Objs{1}.Sig.Type, 'SEFDM')
                if strcmp(Objs{1}.SEFDM.FormType, 'Insert') || ...
                        strcmp(Objs{1}.SEFDM.FormType, 'Oscill')
                    AlphaFreq = Objs{1}.SEFDM.AlphaFreq;
                end
            end
            AlphaTime = 1;
            if strcmp(Objs{1}.Sig.Type, 'SEFDM')
                if strcmp(Objs{1}.SEFDM.FormType, 'Trunc')
                    AlphaTime = Objs{1}.SEFDM.AlphaTime;
                end
            end
            CodeRate = 1;
            if ~Objs{1}.NrSch.isTransparent
                CodeRate = Objs{1}.NrSch.PdschCodeRate;
            end
            switch Objs{1}.Sig.Type
                case {'OFDM', 'OTFS'}
                    L = Objs{1}.NrOFDM.L;
                case 'SEFDM'
                    L = Objs{1}.SEFDM.L;
            end
            switch Objs{1}.Sig.Type
                case {'OFDM', 'OTFS'}
                    N = Objs{1}.NrOFDM.NFFT;
                case 'SEFDM'
                    N = Objs{1}.SEFDM.NFFT;
            end
            switch Objs{1}.Sig.Type
                case {'OFDM', 'OTFS'}
                    Ncps = Objs{1}.NrOFDM.CPLengths;
                case 'SEFDM'
                    Ncps = Objs{1}.SEFDM.CPLengths;
            end
            Res.SpectralEfficiency = CodeRate * ...
                Objs{1}.SchSource.PdschModNumBits / AlphaFreq * ...
                L * N / (L * N * AlphaTime + sum(Ncps));
            
            save(obj.FullSaveFileName, 'Res', 'Params');
    end
    function StartParallel(obj)
    %
    % ������� � ����� ������������ ���������� (��� �������������)

        % ��������� ��������� ����������� pool, ���� �� ����
            P = gcp('nocreate');

        % ���� pool ����, �� �� ������ ���� ������������ � ����������
        % worker ������ ��������� � ���������. ���� pool �����������,
        % �� ���������� ��������� worker ������ ���� ����� 1.
            % ���� ������������ ����������� pool ������ ����������
                isOk = false;
            if ~isempty(P)
                if P.Connected
                    if isequal(P.NumWorkers, obj.NumWorkers)
                        isOk = true;
                    end
                end
            else
                if isequal(obj.NumWorkers, 1)
                    isOk = true;
                end
            end

        % ���� ��������� pool �� ������������� �������� ���������� ���
        % ��� ���, �� ����� ��� �������
            if ~isOk
                % ������ pool, ���� �� ����
                    if ~isempty(P)
                        delete(P);
                    end

                if obj.NumWorkers > 1
                    % ���������� ������� pool
                        P = parpool(obj.NumWorkers);

                    % ��������, ��� ������� ������� ���������� pool
                        isOk = false;
                        if P.Connected
                            if isequal(P.NumWorkers, obj.NumWorkers)
                                isOk = true;
                            end
                        end

                    % ���� �� �������, ������� ������
                        if ~isOk
                            DeleteObjects();
                            error(['Failed to start the pool with ', ...
                                'the specified parameters']);
                        end
                end
            end

    end
    function StopParallel(obj) %#ok<MANU>
    % ����� �� ������������ ���������� (��� �������������)

        % ��������� ��������� ����������� pool, ���� �� ����
            P = gcp('nocreate');

        % ���� ������� pool, �� ��� ����� �������
            if ~isempty(P)
                delete(P);
            end
    end
    function ResetRandStreams(obj)
    % ������� ������ ����������� ��������� ����� � ��������� ���������
        if obj.NumWorkers > 1
            spmd
                Stream = RandStream.getGlobalStream;
                reset(Stream);
            end
        else
            Stream = RandStream.getGlobalStream;
            reset(Stream);
        end
    end
    function PrintLog(obj, LogNum, isClear)
    % ����� �� �����/������ � ���� ���� ����� LogNum, ��� LogNum = 1
    % ������������� ������, � LogNum = 2 - �����. isClear - ����
    % ������������� ������� ������/�����.
        if isempty(obj.Log{LogNum})
            return
        end

        if LogNum == 1 % ����� ���� �� �����
            if isClear
                clc;
            end

            for k = 1:length(obj.Log{1})
                fprintf('%s', obj.Log{1}{k});
            end
        elseif LogNum == 2 % ���������� ���� � ����
            if isClear
                fileID = fopen(obj.FullLogFileName, 'w');
            else
                fileID = fopen(obj.FullLogFileName, 'a');
            end

            if fileID < 0
                DeleteObjects();
                error('Failed to open file to save log!');
            end

            for k = 1:length(obj.Log{2})
                fprintf(fileID, '%s\r\n', obj.Log{2}{k}(1:end-1));
            end

            fclose(fileID);
        end
    end
    function Out = Round(obj, In)
    % ������� ���������� ����� �� ��������� ����� ���������� ������
    % ����� �������
        Out = round(10^obj.h2Precision*In) / 10^obj.h2Precision;
    end
end
end