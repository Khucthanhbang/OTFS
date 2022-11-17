%% OFDM
    % PAPR
        BER.MinPAPRProb = 10^-5; BER.PAPRType = 1; Common.SaveFileName = 'OFDM_PAPR_Type1__QPSK'; SchSource.McsIndex =  5; BER.isBER = false; Common.NumWorkers = 4; % End of Params
        BER.MinPAPRProb = 10^-5; BER.PAPRType = 1; Common.SaveFileName = 'OFDM_PAPR_Type1_16QAM'; SchSource.McsIndex = 16; BER.isBER = false; Common.NumWorkers = 4; % End of Params
        BER.MinPAPRProb = 10^-5; BER.PAPRType = 1; Common.SaveFileName = 'OFDM_PAPR_Type1_64QAM'; SchSource.McsIndex = 21; BER.isBER = false; Common.NumWorkers = 4; % End of Params
        BER.MinPAPRProb = 10^-2; BER.PAPRType = 2; Common.SaveFileName = 'OFDM_PAPR_Type2__QPSK'; SchSource.McsIndex =  5; BER.isBER = false; Common.NumWorkers = 4; % End of Params
        BER.MinPAPRProb = 10^-2; BER.PAPRType = 2; Common.SaveFileName = 'OFDM_PAPR_Type2_16QAM'; SchSource.McsIndex = 16; BER.isBER = false; Common.NumWorkers = 4; % End of Params
        BER.MinPAPRProb = 10^-2; BER.PAPRType = 2; Common.SaveFileName = 'OFDM_PAPR_Type2_64QAM'; SchSource.McsIndex = 21; BER.isBER = false; Common.NumWorkers = 4; % End of Params

    % AWGN
        BER.MinBER = 10^-4; Common.SaveFileName = 'OFDM_AWGN_NoLDPC_16QAM___ZF'; NrSch.isTransparent = 1; NrOFDM.EqType =   'ZF'; SchSource.McsIndex = 16; NrChannel.Type = 'AWGN'; Common.NumWorkers = 4; % End of Params
        BER.MinBER = 10^-4; Common.SaveFileName = 'OFDM_AWGN___LDPC_16QAM_MMSE';                          NrOFDM.EqType = 'MMSE'; SchSource.McsIndex = 16; NrChannel.Type = 'AWGN'; Common.NumWorkers = 4; BER.h2dBInit = 4.0; BER.h2dBMax = 5.7; % End of Params

    % ETU300
        BER.MinBER = 10^-4; Common.SaveFileName = 'OFDM_ETU300_NoLDPC_16QAM___ZF'; NrSch.isTransparent = 1; NrOFDM.EqType =   'ZF'; SchSource.McsIndex = 16; NrChannel.FadingType = 'ETU'; NrChannel.MaxDopShift = 300; Common.NumWorkers = 4; % End of Params
        BER.MinBER = 10^-4; Common.SaveFileName = 'OFDM_ETU300___LDPC_16QAM___ZF';                          NrOFDM.EqType =   'ZF'; SchSource.McsIndex = 16; NrChannel.FadingType = 'ETU'; NrChannel.MaxDopShift = 300; Common.NumWorkers = 4; BER.h2dBInit = 8; BER.h2dBMax = 13.2; % End of Params
        BER.MinBER = 10^-4; Common.SaveFileName = 'OFDM_ETU300___LDPC_16QAM_MMSE';                          NrOFDM.EqType = 'MMSE'; SchSource.McsIndex = 16; NrChannel.FadingType = 'ETU'; NrChannel.MaxDopShift = 300; Common.NumWorkers = 4; BER.h2dBInit = 8; BER.h2dBMax = 14.0; % End of Params

    % FreqRespAtt
        BER.MinBER = 10^-4; Common.SaveFileName = 'OFDM_AWGN_NoLDPC_16QAM___ZF_FreqRespAtt0'; NrSch.isTransparent = 1; NrOFDM.EqType =   'ZF'; SchSource.McsIndex = 16; NrChannel.Type = 'AWGN';                                   Common.NumWorkers = 4;                                       NrChannel.FreqRespNoiseAttenuation = 0; % End of Params
        BER.MinBER = 10^-4; Common.SaveFileName = 'OFDM_AWGN_NoLDPC_16QAM_MMSE_FreqRespAtt0'; NrSch.isTransparent = 1; NrOFDM.EqType = 'MMSE'; SchSource.McsIndex = 16; NrChannel.Type = 'AWGN';                                   Common.NumWorkers = 4;                                       NrChannel.FreqRespNoiseAttenuation = 0; % End of Params
        BER.MinBER = 10^-4; Common.SaveFileName = 'OFDM_ETU300___LDPC_16QAM___ZF_FreqRespAtt0';                        NrOFDM.EqType =   'ZF'; SchSource.McsIndex = 16; NrChannel.FadingType = 'ETU'; NrChannel.MaxDopShift = 300; Common.NumWorkers = 4; BER.h2dBInit = 8; BER.h2dBMax = 15.0; NrChannel.FreqRespNoiseAttenuation = 0; % End of Params
        BER.MinBER = 10^-4; Common.SaveFileName = 'OFDM_ETU300___LDPC_16QAM_MMSE_FreqRespAtt0';                        NrOFDM.EqType = 'MMSE'; SchSource.McsIndex = 16; NrChannel.FadingType = 'ETU'; NrChannel.MaxDopShift = 300; Common.NumWorkers = 4; BER.h2dBInit = 8; BER.h2dBMax = 16.0; NrChannel.FreqRespNoiseAttenuation = 0; % End of Params
        
% N-OFDM
Common.SaveFileName = 'EPA5SEFDM0_9MCS6SIC0VarRec0'; Common.SaveDirName = 'FadingSICvarRec'; BER.MinBER = 10^-2; Common.NumWorkers = 2; NrChannel.Type = 'Fading'; NrChannel.FadingType = 'EPA'; NrChannel.MaxDopShift = 5; Sig.Type = 'SEFDM'; SEFDM.FormType = 'Insert'; SEFDM.AlphaFreq = 0.9; SEFDM.AlphaTime = 1; SchSource.McsIndex = 6; SEFDM.isRecalcVar = 0; % End of Params
Common.SaveFileName = 'ETU300TOFDM0_9MCS6SIC1VarRec1'; Common.SaveDirName = 'FadingSICvarRec'; BER.MinBER = 10^-2; Common.NumWorkers = 2; NrChannel.Type = 'Fading'; NrChannel.FadingType = 'ETU'; NrChannel.MaxDopShift = 300; Sig.Type = 'SEFDM'; SEFDM.FormType = 'Trunc'; SEFDM.AlphaTime = 0.9; SEFDM.AlphaFreq = 1; SchSource.McsIndex = 6; SEFDM.isSIC = 1; % End of Params
Common.SaveFileName = 'AWGN_TOFDM0_8MCS10NCCP'; Common.SaveDirName = 'Results/SymbAdd'; BER.MinBER = 10^-2; Common.NumWorkers = 1; NrChannel.Type = 'AWGN'; Sig.Type = 'SEFDM'; SEFDM.FormType = 'Trunc'; SEFDM.AlphaTime = 0.8; SEFDM.AlphaFreq = 1; SchSource.McsIndex = 10; SEFDM.SymbAdd = 'CP'; SEFDM.CPtype = 'NOFDM'; % End of Params
Common.SaveFileName = 'ETU300SEFDM0_7MCS5ZP'; Common.SaveDirName = 'Results/SymbAdd'; BER.MinBER = 10^-2; Common.NumWorkers = 1; NrChannel.Type = 'Fading'; NrChannel.FadingType = 'ETU'; NrChannel.MaxDopShift = 300; Sig.Type = 'SEFDM'; SEFDM.FormType = 'Insert'; SEFDM.AlphaTime = 1; SEFDM.AlphaFreq = 0.7; SchSource.McsIndex = 5; SEFDM.SymbAdd = 'ZP'; % End of Params
