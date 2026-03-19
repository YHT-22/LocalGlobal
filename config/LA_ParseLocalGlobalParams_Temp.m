function MSTIparams = LA_ParseLocalGlobalParams_Temp(ProtocolStr)

% get params
MSTIparams.Protocol = ProtocolStr;
MSTIparams.Window = [-500, 1200];
MSTIparams.ICAWindow = [-500, 1200];
MSTIparams.plotWin = [0, 500];
MSTIparams.compareWin = [0, 500];
MSTIparams.sigTestWin = [0, 200];
MSTIparams.BaselineWin = [-100, 0];
MSTIparams.chPlotFcn = @MLA_PlotRasterLfp_LocalGlobalProcess;
MSTIparams.sigTestMethod = "ttest2";

end
