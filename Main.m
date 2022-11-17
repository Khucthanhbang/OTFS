function Main(FirstParamsNum, Step4ParamsNum, isRegression)
%
% ������� ����������� ���� ������
%   ������� ���������� ����� ���� 0, 1, 2 ��� 3. �������� �� ���������:
%       FirstParamsNum = 1;
%       Step4ParamsNum = 1;
%       isRegression = 0;
%
% ������� ����������:
%   ���� ������� ������ ���� ������� ����������, �� FirstParamsNum - ������
%       �������� ������� ������� ����������, ��� ������� ����� ���������
%       �������������.
%   ���� ������� ���������� ���, �� FirstParamsNum - ����� ������� ������
%       ����������, Step4ParamsNum - ��� ��� �������� � ������������
%       ������ ����������. ���� ���� ���������� �������������, ������
%       �����, ��� ������� ������ �� ���������� �����.

    % ������� command window, �������� �����
        clc;
        close all;
        
    % ������������� ���� ��������� �����������
        rng('default');

    % �������� ���������� ������� ����������
        if ~(nargin >= 0 && nargin <= 3)
            error(['The number of input arguments to the Main should ', ...
                'be equal to 0, 1, 2, or 3']);
        end

    % ��������� �������� FirstParamsNum, Step4ParamsNum   
        if nargin == 0
            FirstParamsNum = 1;
            Step4ParamsNum = 1;
            isRegression = 0;
        elseif nargin == 1
            Step4ParamsNum = 1;
            isRegression = 0;
        elseif nargin == 2
            isRegression = 0;
        else
        end
        
    % �������� ������������ �������� ������� ����������
        validateattributes(FirstParamsNum, {'double'}, {'vector', ...
            'integer', 'positive'});
        if nargin == 1
            validateattributes(FirstParamsNum, {'double'}, {'scalar'})
        end
        validateattributes(Step4ParamsNum, {'double'}, {'scalar', ...
            'integer', 'positive'});
        validateattributes(isRegression, {'double', 'logical'},...
            {'scalar', 'binary'});
        
    % ���������� ���������� ���������� Ruler � Objs ��� ����������� �������
    % ���������� ��� ������� ������ �� ����� ����� ���������, � �����
    % FieldNames ��� ��������� �������� ������� �������� ��� ������
    % ��������
        global Ruler Objs FieldNames
        
        FieldNames = { ...
            'SchSource', ...
            'NrSch', ...
            'NrSML', ...
            'NrOFDM', ...
            'NrOTFS', ...
            'SEFDM', ...
            'Sig', ...
            'NrChannel' ...
        };
    
    % ���������� ����������, �������� ������� ���������� �� �������� ��
    % ���������
        if isRegression
            Params = ReadSetup('RegressionSetup');
        else
            Params = ReadSetup('AllSetup');
        end

    % ��������� ������ �������� kVals - ������� ����������, ��� �������
    % ������ ���� �������� ������ (�� ������ ����)
        % ����� ���������� ������� ����������
            NumParams = length(Params);
        if nargin == 1
            kVals = FirstParamsNum;
        else
            kVals = FirstParamsNum : Step4ParamsNum : NumParams;
        end

    % �������� �������� kVals
        if (min(kVals) < 1) || (max(kVals) > NumParams)
            error('Invalid value of number for parameters set');
        end
        
    % ���� �� ������ ����������
        for k = kVals
            % �������� Ruler, ������������� � �������� ���������� Common �
            % BER
                Ruler = ClassBERRuler(Params{k}, k, NumParams);

            % �������� ��������� ��������, ������������� � �������� ��
            % ����������, ������������� ����������, ��������� ����������,
            % ��������� � ��������� ���������� ���������� ����������
            % ��������
                Objs = PrepareObjects(Ruler, Params{k});

            % ������� � ����� ������������ ���������� (��� �������������)
                Ruler.StartParallel();

            % ����� ����������� ��������� ����� � ��������� ���������
                Ruler.ResetRandStreams();
                
            % ���� ��� ������ ������ ����������
                while ~Ruler.isStop
                    % ��������� ���������� ����� ������
                        if Ruler.NumWorkers > 1
                            parfor n = 1:Ruler.NumWorkers
                                Objs{n} = LoopFun(Objs{n}, Ruler, n); %#ok<PFGV,PFGP>
                            end
                        else
                            Objs{1} = LoopFun(Objs{1}, Ruler, 1);
                        end
                    % ��������� �����������
                        isPointFinished = Ruler.Step(Objs);
                        
                    % ���������� ����������� ��� ��������� �������
                    % ��������� �����
                        if isPointFinished
                            Ruler.Saves(Objs, Params{k});
                        end
                end

            % ����� �� ������������ ���������� (��� �������������)
                if isequal(k, kVals(end))
                    Ruler.StopParallel();
                end

            % �������� ���� ��������
                DeleteObjects();
        end
        
        clear global Ruler Objs FieldNames
        
        restoredefaultpath;
end
function Objs = LoopFun(inObjs, Ruler, WorkerNum)
% ���� ��� ������ ������ ����������

    % ���� ��� ������� � ������ ���� handle, �.�. ���������� ��� ���������,
    % ��� �� �����, ��� ���������� ������ parfor ���� ������ �����
    % �������������� ����������� �� ����� (https://www.mathworks.com/help/
    % distcomp/objects-and-handles-in-parfor-loops.html)
        Objs = inObjs;

    % ���� �� ���������� ������
        for k = 1:Ruler.OneWorkerNumOneIterFrames(WorkerNum)
            % ����������
                % ������������� �������� ������
                    Frame.TxData = Objs.SchSource.Step();
                    
                % SCH Encoder
                    Frame.TxDataTmp = Objs.NrSch.StepTx(Frame.TxData);
                    
                % ����������� �� ������������� ������� + scrambling + ...
                % LayerMapping
                    Frame.TxModSymbols = Objs.NrSML.StepTx( ...
                        Frame.TxDataTmp);
                    
                % ������������� ������� (OFDM, ...)
                    Frame.TxSignal = Objs.Sig.StepTx( ...
                        Frame.TxModSymbols);

            if Ruler.isBER
            % �����
                [Frame.RxSignal, InstChan] = Objs.NrChannel.Step( ...
                    Objs, Frame.TxSignal, Ruler.h2dB);

            % �������
                % ��������� ��������� ������� - ����������
                % ������������� ��������
                    [Frame.RxModSymbols, VarVals] = Objs.Sig.StepRx( ...
                        Frame.RxSignal, InstChan);

                % Demodulation + descrambling
                    Frame.RxDataTmp = Objs.NrSML.StepRx( ...
                        Frame.RxModSymbols, VarVals);
                    
                % Decoding
                    [Frame.RxData, ~] = Objs.NrSch.StepRx( ...
                        Frame.RxDataTmp);
            end

            % ���������� ���������� �� �������� Frame
                Objs.Stat.Step(Frame, Objs.Sig);
        end
end