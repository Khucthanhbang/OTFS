classdef ClassSchSource < handle
% In this class all the default cell parameters are defined, and Transport
% block size is calculated. Step function generates data bits. See 5.1.3.2
% in 38.214 for detailed description of transport block size calculation
% algorithm.
%
properties % Constants
    % Downlink (DL)/Uplink (UL) (default is DL, UL is not supported yet!)
        SchDirection = 'DL';
    % Physical Cell ID (range: 0..1007)
        CellID = 1;
    % Number of layers (number of MIMO layers) (range: 1..8). Only value 1
    % is supported now! 
        NumLayers = 1;
    % MCS Table 1 38.214 5.1.3.1-1
    % Columns:
    % MCS Index, Number of bits per modulation symbol, 
    % Target code Rate x 1024, Spectr.eff-cy
        MCSTable1 = [ ...
             0, 2, 120, 0.2344; ...
             1, 2, 157, 0.3066; ...
             2, 2, 193, 0.3770; ...
             3, 2, 251, 0.4902; ...
             4, 2, 308, 0.6016; ...
             5, 2, 379, 0.7402; ...
             6, 2, 449, 0.8770; ...
             7, 2, 526, 1.0273; ...
             8, 2, 602, 1.1758; ...
             9, 2, 679, 1.3262; ...
            10, 4, 340, 1.3281; ...
            11, 4, 378, 1.4766; ...
            12, 4, 434, 1.6953; ...
            13, 4, 490, 1.9141; ...
            14, 4, 553, 2.1602; ...
            15, 4, 616, 2.4063; ...
            16, 4, 658, 2.5703; ...
            17, 6, 438, 2.5664; ...
            18, 6, 466, 2.7305; ...
            19, 6, 517, 3.0293; ...
            20, 6, 567, 3.3223; ...
            21, 6, 616, 3.6094; ...
            22, 6, 666, 3.9023; ...
            23, 6, 719, 4.2129; ...
            24, 6, 772, 4.5234; ...
            25, 6, 822, 4.8164; ...
            26, 6, 873, 5.1152; ...
            27, 6, 910, 5.3320; ...
            28, 6, 948, 5.5547; ...
            29, 2,  -1,     -1; ...
            30, 4,  -1,     -1; ...
            31, 6   -1,     -1];
        
    % MCSTable2 38.214 5.1.3.1-2 (QAM256 support)
        MCSTable2 = [0, 2, 120, 0.2344; ...
             1, 2,   193, 0.3770; ...
             2, 2,   308, 0.6016; ...
             3, 2,   449, 0.8770; ...
             4, 2,   602, 1.1758; ...
             5, 4,   378, 1.4766; ...
             6, 4,   434, 1.6953; ...
             7, 4,   490, 1.9141; ...
             8, 4,   553, 2.1602; ...
             9, 4,   616, 2.4063; ...
            10, 4,   658, 2.5703; ...
            11, 6,   466, 2.7305; ...
            12, 6,   517, 3.0293; ...
            13, 6,   567, 3.3223; ...
            14, 6,   616, 3.6094; ...
            15, 6,   666, 3.9023; ...
            16, 6,   719, 4.2129; ...
            17, 6,   772, 4.5234; ...
            18, 6,   822, 4.8164; ...
            19, 6,   873, 5.1152; ...
            20, 8, 682.5, 5.3320; ...
            21, 8,   711, 5.5547; ...
            22, 8,   754, 5.8906; ...
            23, 8,   797, 6.2266; ...
            24, 8,   841, 6.5703; ...
            25, 8,   885, 6.9141; ...
            26, 8, 916.5, 7.1602; ...
            27, 8,   948, 7.4063; ...
            28, 2,    -1,     -1; ...
            29, 4,    -1,     -1; ...
            30, 6,    -1,     -1; ...
            31, 8,    -1,     -1];
        
    % MCSTable3 38.214 5.1.3.3-3
        MCSTable3 = [0, 2, 30, 0.0586; ...
             1, 2,  40, 0.0781; ...
             2, 2,  50, 0.0977; ...
             3, 2,  64, 0.1250; ...
             4, 2,  78, 0.1523; ...
             5, 2,  99, 0.1934; ...
             6, 2, 120, 0.2344; ...
             7, 2, 157, 0.3066; ...
             8, 2, 193, 0.3770; ...
             9, 2, 251, 0.4902; ...
            10, 2, 308, 0.6016; ...
            11, 2, 379, 0.7402; ...
            12, 2, 449, 0.8770; ...
            13, 2, 526, 1.0273; ...
            14, 2, 602, 1.1758; ...
            15, 4, 340, 1.3281; ...
            16, 4, 378, 1.4766; ...
            17, 4, 434, 1.6953; ...
            18, 4, 490, 1.9141; ...
            19, 4, 553, 2.1602; ...
            20, 4, 616, 2.4063; ...
            21, 6, 438, 2.5664; ...
            22, 6, 466, 2.7305; ...
            23, 6, 517, 3.0293; ...
            24, 6, 567, 3.3223; ...
            25, 6, 616, 3.6094; ...
            26, 6, 666, 3.9023; ...
            27, 6, 719, 4.2129; ...
            28, 6, 772, 4.5234; ...
            29, 2,  -1,     -1; ...
            30, 4,  -1,     -1; ...
            31, 6,  -1,     -1];
        
    % Parameters for MCS table selection: see 38.214 5.1.3.1 for values
        % For Table 1 select All values     = "None"
        % For Table 2 select McsTableDCI1_2 = "qam256", ...
            %                McsDCIFormat   = "1_2", ...
            %                McsCRCRNTI     = "C-RNTI"
            %                Other values   = "None"
        % For Table 3 select McsMcs_Table   = "qam256", ...
            %                McsDCIFormat   = "1_1", ...
            %                McsCRCRNTI     = "C-RNTI"
            %                Other values   = "None"
    
        McsTableDCI1_2 = "None"; % {None, qam256, qam64LowSE}
        McsDCIFormat = "None"; % {None, 1_1, 1_2}
        McsCRCRNTI = "None"; % {None, C-RNTI, MCS-C-RNTI, CS-RNTI}
        McsMcs_Table = "None"; % {None, qam256, qam64LowSE, SPS-Config_qam64LowSE}
        Mcs_C_RNTI = "None"; % {None, No, Yes}
        Mcs_SPS_PdschFormat = "None"; % {None, 1_1, 1_2, Without_SPS}
        
    % Scaling factor for Info bits
    % The function uses this value in calculating the intermediate number
    % of  information bits, N_info, as defined in TS 38.214 Section
    % 5.1.3.2. The nominal value of the scaling factor is 0.25, 0.5, or 1,
    % as defined in TS 38.214 Table 5.1.3.2-2.
        PdschScaling = 1;
    % The total number of allocated PRBs for the UE (full bandwidth)
        % AG: ???
    % DM-RS type 1, mapping type A (symbol 2, every second subcarrier,
    % L0 = 2 (number of the first subcarrier, only one CDM group for 1 UE
    % case)
        DmrsCdmGroups = 1;
        DmrsMappingType = 'A';
        DmrsType = 1;
        DmrsStartSymb = 2;
        DmrsAdditionalPoses = 0; % {0,1,2,3}
        DmrsLen = 1;
    % User Equipment RNTI value [0..65535]
        UeRNTI = 6143;   
    % The overhead configured by higher layer (parameter xOverhead in
    % PDSCHServingCellConfig message) = number of the reserved REs for
    % other purposes. Equal to zero by default.
        NumOverheadPerPRB = 0; % No overhead
    % TBS table for Ninfo < 3824 (38.214 Table 5.1.3.2-1)
        TbsTable = [24:8:192 208:16:384 408:24:576 608:32:736 ...
            768:40:928 984 1032 1064 1128:32:1352 1416:64:1928 ...
            2024:64:2280 2408:64:2856 2976 3104 3240 3368 3496 3624 ...
            3752 3824];
end
properties % Variable parameters of the current object (with default
        % values)
    % MCS table number: 1, 2, or 3
        McsTabNum = 1;
    % MCS table index (range: 0..28) (see 38.214 5.1.3.1 for parameters)
        McsIndex = 5; % influence on ClassBERRuler.h2dBInit
    % TBS calculation type: 'Auto' || 'Manual'
        TbsCalcType = 'Auto';
    % Cell bandwidth
        CellBw = 20*10^6; %Hz (equal to 106 available PRBs with SCS 15 kHz)
    % Guard band
        CellGB = 460 * 10^3; %Hz
    % Numerology (determines OFDM subcarrier spacing (SCS)) (range: 0..4)
        CellScsU = 0;
    % Number of PRBs for UE (active bandwidth part size)
    % (range: 4..CellBWinPRB)
        NumPRBForUE = 106; 
    % Number of symbols of PDSCH allocation within the slot (symbols 2-14,
    % symbol 1 is for PDCCH)
        StartSymbNum = 1;
        NumPdschSymbPerSlot = 13;
end
properties % Variable parameters or calculated parameters of other
        % objects (without default values)
end
properties % Calculated parameters of the current object (without default
        % values)
    % Selected MCS table
        McsTable;
    % MCS parameters (determined from MCS 38.214 tables 5.1.3.1)
        PdschCodeRate; % table 1 MCS Index 16 (TBD as table)
    % Number of bits per modulation symbol = Log2(M), where M is modulation
    % order
        PdschModNumBits;
    % Subcarrier spacing (based on numerology)
        CellSCS;
    % Number of PRBs (based on cell bandwidth, SCS and guard band)
        NumPRBs;
    % Number of REs for DMRS per PRB in the scheduled duration including
    % the overhead of the DMRS CDM groups without data
        NumDmrsPerPRB;
    % DM-RS frequency poses (depend on number of CDM groups = number of
    % UEs)
        DmrsFreqPoses;
    % DM-RS time poses (depend on DM-RS type)
        DmrsTimePos;
    % The number of REs allocated for PDSCH within a PRB
        NumRePerPRB;
    % The total number of REs allocated for PDSCH
        NumReTotal;
    % Intermediate number of information bits
        NumInfo;
    % Transport block Size
        TbSize;
    % Modulation type
        ModType;
    % Cell Carrier configuration object
        CellCarrier;
    % Nr SCH Configuration objects/parameters
        NrSchConfig;
        NrSchIndices; % not a object!
        NrSchInfo; % not a object!
    % NR SCH DMRS Configuration objects/parameters
        NrDmrsConfig;
        NrDmrsIndices; % not a object!
        NrDmrsSymbols; % not a object!
end
methods
    function obj = ClassSchSource(Params)
    % Constructor. For all variable parameters of the current object, one
    % need to check for the presence of a user defined value in Setup. If
    % it is present then it should replace the default value. Each variable
    % parameters value of the current object should be checked for
    % validity. It is also wise to cross-check parameters.

        % String with the name of the function in which an error occurred
        % while validating the parameter value
            funcName = 'ClassSchSource.constructor';

        % To shorten the code, select the required field(s) from Params
            if isfield(Params, 'SchSource')
                SchSource = Params.SchSource;
            else
                SchSource = [];
            end
        % McsTabNum
            if isfield(SchSource, 'McsTabNum')
                obj.McsTabNum = SchSource.McsTabNum;
            end
            ValidateAttributes(obj.McsTabNum, {'double'}, ...
                {'scalar', 'integer', '>=', 1, '<=', 3}, funcName, ...
                'McsTabNum');
        % McsIndex
            if isfield(SchSource, 'McsIndex')
                obj.McsIndex = SchSource.McsIndex;
            end
            ValidateAttributes(obj.McsIndex, {'double'}, ...
                {'scalar', 'integer', '>=', 0, '<=', 28}, funcName, ...
                'McsIndex');
        % TbsCalcType
            if isfield(SchSource, 'TbsCalcType')
                obj.TbsCalcType = SchSource.TbsCalcType;
            end
            obj.TbsCalcType = ValidateString(obj.TbsCalcType, {'Auto', ...
                'Manual'}, funcName, 'TbsCalcType');
            
        if isfield(SchSource, 'CellBw')
            obj.CellBw = SchSource.CellBw;
        end
        ValidateAttributes(obj.CellBw, {'double'}, ...
            {'scalar', 'integer', '>=', 5*10^6, '<=', 100*10^6}, funcName, ...
            'CellBw');
        if isfield(SchSource, 'CellGB')
            obj.CellGB = SchSource.CellGB;
        end
        ValidateAttributes(obj.CellGB, {'double'}, ...
            {'scalar', 'integer', '>=', 0, '<', obj.CellBw/2}, funcName, ...
            'CellGB');
        if isfield(SchSource, 'CellScsU')
            obj.CellScsU = SchSource.CellScsU;
        end
        ValidateAttributes(obj.CellScsU, {'double'}, ...
            {'scalar', 'integer', '>=', 0, '<=', 4}, funcName, ...
            'CellScsU');
        if isfield(SchSource, 'NumPRBForUE')
            obj.NumPRBForUE = SchSource.NumPRBForUE;
        end
        ValidateAttributes(obj.NumPRBForUE, {'double'}, ...
            {'scalar', 'integer', '>=', 1, '<=', 275}, funcName, ...
            'NumPRBForUE');
        if isfield(SchSource, 'NumPdschSymbPerSlot')
            obj.NumPdschSymbPerSlot = SchSource.NumPdschSymbPerSlot;
        end
        ValidateAttributes(obj.NumPdschSymbPerSlot, {'double'}, ...
            {'scalar', 'integer', '>=', 1, '<=', 100}, funcName, ...
            'NumPdschSymbPerSlot');
    end
    
    function SelectMCSTable(obj)
        % MCS table selection algorithm as described in 38.214 5.1.3.1
            if (isequal(obj.McsTableDCI1_2, "qam256") && ...
                    isequal(obj.McsDCIFormat, "1_2") && ...
                    isequal(obj.McsCRCRNTI, "C-RNTI"))
                obj.McsTable = obj.MCSTable2;
            elseif (isequal(obj.Mcs_C_RNTI, "No") && ...
                    isequal(obj.McsTableDCI1_2, "qam64LowSE") && ...
                    isequal(obj.McsDCIFormat, "1_2") && ...
                    isequal(obj.McsCRCRNTI, "C-RNTI"))
                obj.McsTable = obj.MCSTable3;
            elseif (isequal(obj.McsMcs_Table, "qam256") && ...
                    isequal(obj.McsDCIFormat, "1_1") && ...
                    isequal(obj.McsCRCRNTI, "C-RNTI"))
                obj.McsTable = obj.MCSTable2;
            elseif (isequal(obj.Mcs_C_RNTI, "No") && ...
                    isequal(obj.McsMcs_Table, "qam64LowSE") && ...
                    ~isequal(obj.McsDCIFormat, "1_2") && ...
                    isequal(obj.McsCRCRNTI, "C-RNTI"))
                obj.McsTable = obj.MCSTable3;
            elseif (isequal(obj.Mcs_C_RNTI, "Yes") && ...
                    isequal(obj.McsCRCRNTI, "MCS-C-RNTI"))
                obj.McsTable = obj.MCSTable3;
            elseif (~isequal(obj.McsMcs_Table, "SPS-Config_qam64LowSE") && ...
                    isequal(obj.McsTableDCI1_2, "qam256"))
                if ((isequal(obj.McsDCIFormat, "1_2") && ...
                    isequal(obj.McsCRCRNTI, "CS-RNTI")) || ...
                    isequal(obj.Mcs_SPS_PdschFormat, "1_2"))
                    obj.McsTable = obj.MCSTable2;
                end
            elseif (~isequal(obj.McsMcs_Table, "SPS-Config_qam64LowSE") && ...
                    isequal(obj.McsMcs_Table, "qam256"))
                if ((isequal(obj.McsDCIFormat, "1_1") && ...
                    isequal(obj.McsCRCRNTI, "CS-RNTI")) || ...
                    isequal(obj.Mcs_SPS_PdschFormat, "1_1"))
                    obj.McsTable = obj.MCSTable2;
                end
            elseif (isequal(obj.McsMcs_Table, "SPS-Config_qam64LowSE"))
                if ((isequal(obj.McsCRCRNTI, "CS-RNTI")) || ...
                    isequal(obj.Mcs_SPS_PdschFormat, "Without_SPS"))
                    obj.McsTable = obj.MCSTable3;
                end
            else
                obj.McsTable = obj.MCSTable1;
            end
    end
    
    function CalcIntParams(obj)
    % Determining the values of calculated parameters that do not require
    % information about the values of parameters from other objects
        % MCS table selection (TBD in future versions)
            obj.SelectMCSTable();
        % MCS parameters (determined from MCS 38.214 tables 5.1.3.1)
            obj.PdschCodeRate = obj.McsTable(obj.McsIndex+1, 3) / 1024;
                % table 1 MCS Index 16 (TBD as table)
        % Number of bits per modulation symbol = Log2(M), where M is
        % modulation order
            obj.PdschModNumBits = obj.McsTable(obj.McsIndex+1, 2);
        % SCS
            obj.CellSCS = 2.^obj.CellScsU * 15000; %Hz
        % Num of PRBs
            obj.NumPRBs = (obj.CellBw - 2*obj.CellGB) / (12 * obj.CellSCS);
        % Determine time poses of DM-RS
                if strcmp(obj.DmrsMappingType,'A')
                   obj.DmrsTimePos = 2;
                end
            % Determine frequency poses of DM-RS
                if (obj.DmrsType == 1)
                    if (obj.DmrsCdmGroups == 1)
                        obj.DmrsFreqPoses = 2:2:12;
                    else
                       obj.DmrsFreqPoses = 1:1:12;
                    end
                end

        % Determine modulation type
            switch obj.PdschModNumBits
                case 1
                    obj.ModType = 'pi/2-BPSK'; % UL only (not used in this
                        % version)
                case 2
                    obj.ModType = 'QPSK';
                case 4
                    obj.ModType = '16QAM';
                case 6
                    obj.ModType = '64QAM';
                case 8
                    obj.ModType = '256QAM';
            end

        % Determine number of REs for DMRS
            obj.NumDmrsPerPRB = length(obj.DmrsTimePos) * ...
                length(obj.DmrsFreqPoses);
        % Cell Carrier configuration object
            obj.CellCarrier = nrCarrierConfig('SubcarrierSpacing', ...
                obj.CellSCS/1000, 'NSizeGrid', obj.NumPRBs, 'NCellID', ...
                obj.CellID);
        % Create DM-RS Configuration object
            if strcmp(obj.SchDirection, 'DL')
                obj.NrDmrsConfig = nrPDSCHDMRSConfig;
            elseif strcmp(obj.SchDirection, 'UL')
                error('UL is not supported in this version!');
                % obj.NrDmrsConfig = nrPUSCHDMRSConfig;
                % NR PUSCH DMRS specific parameters TBD
            end
            obj.NrDmrsConfig.DMRSConfigurationType = obj.DmrsType;
            obj.NrDmrsConfig.DMRSTypeAPosition = obj.DmrsStartSymb;
            obj.NrDmrsConfig.DMRSAdditionalPosition = ...
                obj.DmrsAdditionalPoses;
            obj.NrDmrsConfig.DMRSLength = obj.DmrsLen;
            obj.NrDmrsConfig.NumCDMGroupsWithoutData = obj.DmrsCdmGroups;      
        % Create Sch configuration object
            if strcmp(obj.SchDirection, 'DL')
                obj.NrSchConfig = nrPDSCHConfig;
            elseif strcmp(obj.SchDirection, 'UL')
                error('UL is not supported in this version!');
                % obj.NrSchConfig = nrPUSCHConfig;
                % NR PUSCH specific parameters TBD
            end
        % NrSCHConfig object preparation based on defined parameters        
            obj.NrSchConfig.NSizeBWP = obj.NumPRBForUE;
            obj.NrSchConfig.NStartBWP = 0; % obj.NumPRBs/2 - 
                % obj.NumPRBForUE/2;
                % AG: Please explain this note!
            obj.NrSchConfig.Modulation = obj.ModType;
            obj.NrSchConfig.NumLayers = obj.NumLayers;
            obj.NrSchConfig.MappingType = obj.DmrsMappingType;
            obj.NrSchConfig.SymbolAllocation = [obj.StartSymbNum ...
                obj.NumPdschSymbPerSlot];
            obj.NrSchConfig.PRBSet = 0 : obj.NumPRBForUE-1;
            obj.NrSchConfig.RNTI = obj.UeRNTI;
            obj.NrSchConfig.DMRS = obj.NrDmrsConfig;

        % SCH DM-RS/SCH Indices and symbols determination
            if strcmp(obj.SchDirection, 'DL')
                [obj.NrSchIndices, obj.NrSchInfo] = nrPDSCHIndices( ...
                    obj.CellCarrier, obj.NrSchConfig);
                obj.NrDmrsSymbols = nrPDSCHDMRS(obj.CellCarrier, ...
                    obj.NrSchConfig);
                obj.NrDmrsIndices = nrPDSCHDMRSIndices(obj.CellCarrier, ...
                    obj.NrSchConfig);
            elseif strcmp(obj.SchDirection, 'UL')
                error('UL is not supported in this version');
                % [obj.NrSchIndices, obj.NrSchInfo] = nrPUSCHIndices( ...
                %     obj.CellCarrier, obj.NrSchConfig);
                % obj.NrDmrsSymbols = nrPUSCHDMRS(obj.CellCarrier, ...
                %     obj.NrSchConfig);
                % obj.NrDmrsIndices = nrPUSCHDMRSIndices;
                % NR PUSCH specific parameters TBD
            end

        % Calc transport block size
            obj.CalcTbSize();
    end
    function CalcIntParamsFromExtParams(obj, Objs) %#ok<INUSD>
    % Getting parameters from other objects and determining the values of
    % calculated parameters of the current object that do require
    % information about the values of parameters from other objects
    end
    function DeleteSubObjs(obj)
    % Removing of internal (sub) objects
        delete(obj.CellCarrier);
        delete(obj.NrSchConfig);
        delete(obj.NrDmrsConfig);
    end
    function OutData = Step(obj)
    % Data sequence generation, length is based on TBS
        OutData = randi(2, obj.TbSize, 1) - 1;
    end
    function CalcTbSize(obj)
    % Function calculates transport block size according to the algorithm
    % defined in 38.214 5.1.3.2
        % First determine number of available REs in one slot (see 38.214
        % 5.1.3.2)
            obj.NumRePerPRB = 12 * obj.NumPdschSymbPerSlot - ...
                obj.NumDmrsPerPRB - obj.NumOverheadPerPRB;
            obj.NumReTotal = min(156, obj.NumRePerPRB) * obj.NumPRBForUE;
            obj.NumInfo = obj.NumReTotal * obj.PdschCodeRate * ...
                obj.PdschModNumBits * obj.NumLayers;

            if strcmp(obj.TbsCalcType, 'Manual')
            % Manual calculation of TBS based on algorithm described in
            % 38.214 5.1.3.2
                if (obj.NumInfo <= 3834)
                    tmpVar = max(3, floor(log2(obj.NumInfo)) - 6);
                    tmpNumInfo = max(24, 2.^(tmpVar) * floor( ...
                        obj.NumInfo / 2.^tmpVar) );
                    tmpIdxUpper = (tmpNumInfo < obj.TbsTable);
                    tmpIdx = (tmpNumInfo >= obj.TbsTable) .* ...
                        [tmpIdxUpper(2:end) 1];
                    obj.TbSize = obj.TbsTable(tmpIdx > 0);
                else
                    tmpVar = floor(log2(obj.NumInfo - 24)) - 5;
                    tmpNumInfo = max(3840, round((obj.NumInfo - 24) / ...
                        2.^tmpVar) * 2.^tmpVar);
                    if (obj.PdschCodeRate <= 0.25)
                       tmpC = ceil((tmpNumInfo + 24) / 3816);
                       obj.TbSize = 8*tmpC * ceil((tmpNumInfo + 24) / ...
                           (8*tmpC)) - 24;
                    else
                        if (tmpNumInfo >= 8424)
                           tmpC = ceil((tmpNumInfo + 24) / 8424);
                           obj.TbSize = 8*tmpC * ceil( ...
                               (tmpNumInfo + 24) / (8*tmpC)) - 24;
                        else
                           obj.TbSize = 8*ceil((tmpNumInfo + 24) / 8) - 24;
                        end
                    end
                end
            elseif strcmp(obj.TbsCalcType, 'Auto')
            % TBS calculation using nrTBS function from NRToolbox in Matlab
                obj.TbSize = nrTBS(obj.ModType, obj.NumLayers, ...
                    obj.NumPRBForUE, obj.NumRePerPRB, ...
                    obj.PdschCodeRate, obj.NumOverheadPerPRB, ...
                    obj.PdschScaling);
            end
    end
    function ShowDmrsGrid(obj)
	% Function draws configured DMRS grid (for test purposes only)
        grid = complex(zeros([obj.CellCarrier.NSizeGrid * 12 ...
            obj.CellCarrier.SymbolsPerSlot obj.NrSchConfig.NumLayers]));
        grid(ind+1) = obj.NrDmrsSymbols;
        imagesc(abs(grid(:,:,1)));
        axis xy;
        xlabel('OFDM Symbols');
        ylabel('Subcarriers');
        title(['PDSCH DM-RS Resource Elements in the Carrier ', ...
            'Resource Grid']);
    end
end
end