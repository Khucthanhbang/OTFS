clc;
clear all;
close all;

DirName = '../Results/SymbAdd';
isDrawTheory = true;
TargetBER = 10^-2;
WhatDrawStringArray = ["Shennon"];

SpecialResDraw = [...
"AWGN_TOFDM0_9MCS0CCP", ...
"AWGN_TOFDM0_9MCS0NCCP", ...
"AWGN_TOFDM0_9MCS0ZP", ...
"AWGN_TOFDM0_9MCS5CCP", ...
"AWGN_TOFDM0_9MCS5NCCP", ...
"AWGN_TOFDM0_9MCS5ZP", ...
"AWGN_TOFDM0_9MCS10CCP", ...
"AWGN_TOFDM0_9MCS10NCCP", ...
"AWGN_TOFDM0_9MCS10ZP", ...
"AWGN_TOFDM0_8MCS0CCP", ...
"AWGN_TOFDM0_8MCS0NCCP", ...
"AWGN_TOFDM0_8MCS0ZP", ...
"AWGN_TOFDM0_8MCS5CCP", ...
"AWGN_TOFDM0_8MCS5NCCP", ...
"AWGN_TOFDM0_8MCS5ZP", ...
"AWGN_TOFDM0_8MCS10CCP", ...
"AWGN_TOFDM0_8MCS10NCCP", ...
"AWGN_TOFDM0_8MCS10ZP", ...
"AWGN_TOFDM0_7MCS0CCP", ...
"AWGN_TOFDM0_7MCS0NCCP", ...
"AWGN_TOFDM0_7MCS0ZP", ...
"AWGN_TOFDM0_7MCS5CCP", ...
"AWGN_TOFDM0_7MCS5NCCP", ...
"AWGN_TOFDM0_7MCS5ZP", ...
"AWGN_TOFDM0_7MCS10CCP", ...
"AWGN_TOFDM0_7MCS10NCCP", ...
"AWGN_TOFDM0_7MCS10ZP", ...
"AWGN_SEFDM0_9MCS0CCP", ...
"AWGN_SEFDM0_9MCS0NCCP", ...
"AWGN_SEFDM0_9MCS0ZP", ...
"AWGN_SEFDM0_9MCS5CCP", ...
"AWGN_SEFDM0_9MCS5NCCP", ...
"AWGN_SEFDM0_9MCS5ZP", ...
"AWGN_SEFDM0_9MCS10CCP", ...
"AWGN_SEFDM0_9MCS10NCCP", ...
"AWGN_SEFDM0_9MCS10ZP", ...
"AWGN_SEFDM0_8MCS0CCP", ...
"AWGN_SEFDM0_8MCS0NCCP", ...
"AWGN_SEFDM0_8MCS0ZP", ...
"AWGN_SEFDM0_8MCS5CCP", ...
"AWGN_SEFDM0_8MCS5NCCP", ...
"AWGN_SEFDM0_8MCS5ZP", ...
"AWGN_SEFDM0_8MCS10CCP", ...
"AWGN_SEFDM0_8MCS10NCCP", ...
"AWGN_SEFDM0_8MCS10ZP", ...
"AWGN_SEFDM0_7MCS0CCP", ...
"AWGN_SEFDM0_7MCS0NCCP", ...
"AWGN_SEFDM0_7MCS0ZP", ...
"AWGN_SEFDM0_7MCS5CCP", ...
"AWGN_SEFDM0_7MCS5NCCP", ...
"AWGN_SEFDM0_7MCS5ZP", ...
"AWGN_SEFDM0_7MCS10CCP", ...
"AWGN_SEFDM0_7MCS10NCCP", ...
"AWGN_SEFDM0_7MCS10ZP", ...
];

DrawResults(DirName, isDrawTheory, WhatDrawStringArray, ...
    TargetBER, SpecialResDraw);

