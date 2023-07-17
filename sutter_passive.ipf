#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later

constant K_max_hyperpolarization = -95

Function hyperpolarizing_analysis()

string list_current_sweeps = Wavelist("RecordA*",";","")
variable number_current_sweeps = Itemsinlist(list_current_sweeps)
variable num_traces = number_current_sweeps
variable i,j,HCurrFound

Variable HCurrMin, HCurrMax, HCurrAmp,HCurrMaxTime,HCurrMinTime
Variable  YAxisMin,YAxisMax,MaxPos
Variable index

Wave W_FindLevels
Wave W_coef

SVAR HCurrTrace
NVAR NumWaves

Make/O/N=0 IClampCommand_current
Make/O/N=0 IClampVoltage

Make/O/N=0 TauRise
Make/O/N=0 TauFall
Make/O/N=0 UsedCalc
Make/O/N=0 GraphNo

Make/O/N=0 RiseTauCalc
Make/O/N=0 FallTauCalc




//Make folder for AP times
//string AP_times_folder_name = gCustompath+gcell_id+"_"+gGenotype+":"
//NewPath/C/O AP_times_folder, AP_times_folder_name


print "number of waves = "+num2str(number_current_sweeps)


Variable SamplesPerWave
Variable num_points
//Variable j,FirstAPOnly,k
string File_name,TrcPotNm,IClampTrcSmNm,TrcCmdCurrNm

Make/O/N=(Num_traces) NumberAPs
Make/O/N=(Num_traces) ComCurrValues


variable do_rescale = 1

if(do_rescale == 1)

//rescale all traces
for(j=0;j<Num_traces;j+=1)

	TrcPotNm = "RecordA" +num2str(j)
	Wave TracePot = $TrcPotNm
	TrcCmdCurrNm = "RecordB" +num2str(j)
	Wave TraceCmdCurr = $TrcCmdCurrNm
	variable v_trace_scale = dimdelta(TracePot,0)
	variable v_trace_scale_ms = v_trace_scale*1000
	setscale/P x,0,v_trace_scale_ms,"ms",TracePot
	variable max_x_val = rightx(TracePot)
	setscale/I x,0,max_x_val,"ms",TraceCmdCurr	
	//variable y_trace_scale = dimdelta(TracePot,1)
	//variable y_trace_scale_mV = y_trace_scale*1000
	setscale/P y,0,1,"mV",TracePot
	TracePot = TracePot*1000
	TraceCmdCurr = TraceCmdCurr*1e12

endfor

endif

 

//Define region of trace to take measurments based on Max Current Trace

//Max current trace ID
TrcCmdCurrNm = "RecordB" +num2str(num_traces-1)
Wave TraceCmdCurr = $TrcCmdCurrNm

//Smooth command current trace
IClampTrcSmNm = TrcCmdCurrNm+"_smth"
Duplicate/O  $TrcCmdCurrNm, $IClampTrcSmNm
Smooth 1000,  $IClampTrcSmNm
Wave smoothed_command = $IClampTrcSmNm

//Find step maximum and minimum and 1/2 max to determine threshold
Wavestats/Q smoothed_command
variable halfCurrStepval = (V_max+V_min)/2 

//Find times at which current crosses threshold (i.e. step region)
FindLevels/DEST=stepregiontimes/Q smoothed_command halfCurrStepval
Wave stepregiontimes

//Define time during step to do measurments (btw 20 ms after start step and 20 ms before end step)
variable stepstarttime = (stepregiontimes[0])
variable stependtime = (stepregiontimes[1])

print(stepstarttime)
print(stependtime)



//Manual step region times////////////////////////////////////////////// 

//variable stepstarttime = K_start_step_Hyp_time
//variable stependtime = K_end_step_Hyp_time

///////////////////////////////////////////////////////////////////////

variable HMeasStartTime = (stepregiontimes[0])+20
variable HMeasEndTime = (stepregiontimes[1])-20

variable baseline_time_start = (stepstarttime)-30
variable baseline_time_end = (stepstarttime)-15

Variable MidRegion = ((stependtime-stepstarttime)/2)+stepstarttime
variable begin_measure = MidRegion-200
variable end_measure = MidRegion+200



Display/N=H_Current_trace
Display/N=Hyperpolarizations
Display/N=CurrentSteps

variable q = 0

HCurrFound = 0


do

	string IClampTrcVoltNm = "RecordA"+num2str(q)
	Wave voltage_trace = $IClampTrcVoltNm
	string IClampTrcCurrNm = "RecordB" +num2str(q)
	Wave IClampTraceCurr = $IClampTrcCurrNm

//Measure command current amplitude


	Wavestats/Q/R=(baseline_time_start,baseline_time_end) IClampTraceCurr
	Variable baseline_current = V_avg
	
	//Remove baseline
	IClampTraceCurr=IClampTraceCurr-baseline_current
	WaveStats/Q/R=(begin_measure,end_measure) IClampTraceCurr

	print("Start Measure region " +num2str(HMeasStartTime))
	print("End Measure region" +num2str(HMeasEndTime))
	print("Trace ID "+IClampTrcCurrNm)
	print ("Maximum current "+num2str(V_min))
	print("***")
	
	
	
	
	
	
		if((V_min<-80)&HCurrFound == 0)

			HCurrFound = 1
			
			HCurrMin = V_min
			//Record amplitude at 100 ms before end of H current measurment region 
			WaveStats/Q/R=(HMeasEndTime-100,HMeasEndTime) voltage_trace
			
			HCurrMax = V_avg			
			HCurrAmp = HCurrMax-HCurrMin
			Print(HCurrAmp)
			Appendtograph/W=H_Current_trace, voltage_trace

			String/g HCurrTrace = IClampTrcVoltNm
			
		HCurrFound = 1
					

		endif
		
	
		
	//Raw Voltage measurement during measurement period 
	WaveStats/Q/R=(begin_measure,end_measure) voltage_trace	
	print(V_avg)
	//Appendtograph/W=CurrentSteps, voltage_trace
	Appendtograph/W=Hyperpolarizations, voltage_trace
	//ModifyGraph/W=Hyperpolarizations rgb(voltage_trace)=(43520,43520,43520)
	
	

		
	
	//Baseline
	Wavestats/Q/R=(baseline_time_start,baseline_time_end) voltage_trace
	Variable baseline_voltage = V_avg
	//Raw value
	Wavestats/Q/R=(begin_measure,end_measure) voltage_trace
	Variable raw_voltage = V_avg
	
	string subtracted_voltage_trace_name = IClampTrcVoltNm +"_subtracted"
	Duplicate/O voltage_trace,$subtracted_voltage_trace_name
	wave subtracted_voltage_trace = $subtracted_voltage_trace_name
	subtracted_voltage_trace = subtracted_voltage_trace - baseline_voltage
	
	WaveStats/Q/R=(begin_measure,end_measure) subtracted_voltage_trace 
	variable voltage_amplitude = V_avg
	
	print("/////////////////////////////////////start_bl measurement"+num2str(baseline_time_start)+"////////////////////////////////////////////")
	print("/////////////////////////////////////end_bl measurement"+num2str(baseline_time_end)+"////////////////////////////////////////////")
	print("/////////////////////////////////////bl////////////////"+num2str(baseline_voltage)+"////////////////////////////////////////////")
	print("//////////////////////////////////////////"+num2str(voltage_amplitude)+"////////////////////////////////////////////")
	
	
	
	if((V_avg>K_max_hyperpolarization))
	
	
		WaveStats/Q/R=(begin_measure,end_measure) IClampTraceCurr		
		InsertPoints Inf,1,IClampCommand_current
		IClampCommand_current[Inf] = V_avg
		
		
		//WaveStats/Q/R=(begin_measure,end_measure) $subtracted_voltage_trace_name
		InsertPoints Inf,1,IClampVoltage
		IClampVoltage[Inf] = voltage_amplitude
		
	endif
	
	
	Variable abs_voltage_change = abs(raw_voltage-baseline_voltage)
		
		//Print "Voltage Amplitude =" + num2str(AbsoluteVoltageAmp)
		
			if(abs_voltage_change>5)
		
		
			Print("*****************************Reaches Cap measurment threshold**************************")
		
		
		
			//Print "Baseline Voltage = "+ num2str(baseline_voltage)
			//Print "Maximum Voltage = "+num2str(raw_voltage)
		
		
			Variable EightyPercent = 0.8* (raw_voltage-baseline_voltage)
			Variable TwentyPercent = 0.2* (raw_voltage-baseline_voltage)
		
			//Print "Eighty Percent voltage change = "+num2str(EightyPercent)
			//Print "Twenty Percent voltage change = "+num2str(TwentyPercent)
		
			Variable EightyPercentRaw = (EightyPercent+baseline_voltage)
			Variable TwentyPercentRaw = (TwentyPercent+baseline_voltage)
			
			//Print "Eighty Percent raw voltage = "+num2str(EightyPercent+baseline_voltage)
			//Print "Twenty Percent raw voltage = "+num2str(TwentyPercent+baseline_voltage)			
		
		
			Variable LevelTwentyRise = 0
			Variable LevelEightyRise = 0
			Variable LevelTwentyFall = 0
			Variable LevelEightyFall = 0
		
			Print(IClampTrcVoltNm)
			
			//20% rise		
			FindLevel/Q/P/R=(stepstarttime,) voltage_trace, TwentyPercentRaw			
			if(V_flag ==0)	
				
				Variable TwentyPercentRising = V_LevelX			
				//print("Twenty Rise Point = "+ num2str(V_LevelX))						
				LevelTwentyRise = 1			
				
			endif
			
			//80% rise			
			FindLevel/Q/P/R=(stepstarttime,) voltage_trace, EightyPercentRaw			
			if(V_flag ==0)	
				
				Variable EightyPercentRising = V_LevelX			
				//print("Eighty Rise Point = "+ num2str(V_LevelX))						
				LevelEightyRise = 1			
				
			endif
			
			
			//80% fall			
			FindLevel/Q/P/R=(stependtime,) voltage_trace, EightyPercentRaw			
			if(V_flag ==0)	
				
				Variable EightyPercentFalling = V_LevelX			
				//print("Eighty Fall Point = "+ num2str(V_LevelX))						
				LevelEightyFall = 1			
				
			endif
			
			//20% fall			
			FindLevel/Q/P/R=(stependtime,) voltage_trace, TwentyPercentRaw				
			if(V_flag ==0)	
				
				Variable TwentyPercentFalling = V_LevelX			
				//print("Twenty Fall Point = "+ num2str(V_LevelX))						
				LevelTwentyFall = 1			
				
			endif	
		
			if(LevelTwentyRise+LevelEightyRise+LevelTwentyFall+LevelEightyFall==4)
			
			
			String CapPlotTraceNm = "Cap_trace_"+num2str(i)
			
			
			Display/N=$CapPlotTraceNm $IClampTrcVoltNm
		
		
				String RiseCoffNm  = IClampTrcVoltNm+"_Rise_Coeff"
				String FallCoffNm  = IClampTrcVoltNm+"_Fall_Coeff"
				String RiseFitNm  = IClampTrcVoltNm+"_Rise_fit"
				String FallFitNm  = IClampTrcVoltNm+"_Fall_fit"				
				
				//Duplicate/D $TrcPotNm,$RiseFitNm
				
				//Make/O/N=(numpnts($TrcPotNm)) $RiseFitNm
				//Make/O/N=200 $RiseFitNm
				
				
				//Tau calculations
				
					
		
				
				
				variable TauOneVal,TauTwoVal,V_AbortCode,CFerror,V_FitQuitReason,V_FitError, RisingTau,FallingTau
				string AutoFitNm
				
				//Rising Tau	
				
				V_FitError=0

				CurveFit/NTHR=0/Q exp_XOffset,voltage_trace[TwentyPercentRising,EightyPercentRising]/D

				Wave W_coef

				if (V_FitError)
			
						
					Print V_FitQuitReason
					RisingTau = NaN
					
			
				else
				
					AutoFitNm = "fit_"+IClampTrcVoltNm
				
					ModifyGraph  rgb($AutoFitNm)=(19712,0,39168)
				
					Rename $AutoFitNm $RiseFitNm				
															
					Duplicate/O W_coef,   $RiseCoffNm
				
					Wave RiseCoff = $RiseCoffNm
						
					RisingTau = RiseCoff[2]							

				endif	
						
				
				
				
				//Falling Tau	
				
				V_FitError=0		
				
		
				CurveFit/NTHR=0/Q exp_XOffset,voltage_trace[TwentyPercentFalling,EightyPercentFalling]/D
				
				if (V_FitError)
			
						
					Print V_FitQuitReason
					FallingTau = NaN
					
			
				else
				
				
					ModifyGraph  rgb($AutoFitNm)=(19712,0,39168)
				
					Rename $AutoFitNm $FallFitNm
				
				
					Duplicate/O W_coef, $FallCoffNm
				
					Wave FallCoff = $FallCoffNm
				
					FallingTau =  FallCoff[2]
				
				endif	
				
				
				
				
				
				
				//Print(TrcPotNm)
				//Print ("Rising Tau = " + num2str(RisingTau))
				//Print ("Falling Tau = " + num2str(FallingTau))
				
				String GlobalRisingTauNm = IClampTrcVoltNm+"RisingTau"
				String GlobalFallingTauNm = IClampTrcVoltNm+"FallingTau"
				
				//Variable/g $GlobalRisingTauNm = RisingTau
				//Variable/g $GlobalFallingTauNm = FallingTau
				
				
				
				InsertPoints Inf,1,  TauRise
				TauRise[Inf] = round((RisingTau)*10)/10
				
				InsertPoints Inf,1,  TauFall
				TauFall[Inf] = round((FallingTau)*10)/10
				
				InsertPoints Inf,1,  GraphNo	
				GraphNo[Inf] = i
				
				
				
				
				
				
				if((FallingTau+RisingTau)<400)
				
				
					InsertPoints Inf,1,  UsedCalc				
					UsedCalc[Inf] = 1	
					
					//Used for calculations
					InsertPoints Inf,1,  RiseTauCalc
					RiseTauCalc[Inf] = round((RisingTau)*10)/10
				
					InsertPoints Inf,1, FallTauCalc
					FallTauCalc[Inf] = round((FallingTau)*10)/10
				
				
				else
				
					InsertPoints Inf,1,  UsedCalc	
					UsedCalc[Inf] = 0			
				
				endif
				
				
				
				
		
			endif
			
			
		endif		
	

	q += 1
	
	
while (q<num_traces)



if(HCurrFound==1)

	DoUpdate/W=H_Current_trace

	DoWindow/F H_Current_trace

	GetAxis/W=H_Current_trace left
	YAxisMin = V_min
	YAxisMax = V_max

	SetDrawEnv dash = 3
	SetDrawEnv linepat=4
	SetDrawEnv xcoord= bottom,ycoord= left
	DrawLine/W=H_Current_trace stepstarttime+20, YAxisMax, stepstarttime+20, YAxisMin

	SetDrawEnv dash = 3
	SetDrawEnv linepat=4
	SetDrawEnv xcoord= bottom,ycoord= left
	DrawLine/W=H_Current_trace stependtime-20, YAxisMax, stependtime-20, YAxisMin

	SetDrawEnv dash = 3
	SetDrawEnv linepat=4
	SetDrawEnv xcoord= bottom,ycoord= left
	DrawLine/W=H_Current_trace stepstarttime+20, HCurrMin, stependtime-20, HCurrMin


	SetDrawEnv dash = 3
	SetDrawEnv linepat=4
	SetDrawEnv xcoord= bottom,ycoord= left
	DrawLine/W=H_Current_trace stependtime-220, HCurrMax, stependtime-20,HCurrMax

	Variable Midpoint = ((stependtime-220)+(stependtime-20))/2
	SetDrawEnv arrow=3
	SetDrawEnv arrowlen=5
	SetDrawEnv xcoord= bottom,ycoord= left
	DrawLine/W=H_Current_trace Midpoint, HCurrMin, Midpoint,HCurrMax
	
	TextBox/W=H_Current_trace/C/N=text1/F=0/A=MC "H current = "+num2str(round(HCurrAmp))+" mV"
	
	
	Label/W=H_Current_trace Left "Membrane Potential (mV)"
	Label/W=H_Current_trace bottom "Time (ms)"

//If voltage trace doesn't reach -80 mV then ignore
	Variable/g gHCurrent = HCurrAmp

else
	Variable/g gHCurrent = NaN
	TextBox/W=H_Current_trace/C/N=text1/F=0/A=MC "No H Current Measurement"
endif




Label/W=Hyperpolarizations Left "Membrane Potential (mV)"
Label/W=Hyperpolarizations bottom "Time (ms)"
TextBox/W=Hyperpolarizations/C/N=text1/F=0/A=MT "Hyperpolarizing steps"


Display/N=IV_plot IClampVoltage vs IClampCommand_current
ModifyGraph mode=3
Label left "Voltage change (mV)"
Label bottom "Current injection (pA)"



Display/N=Taus RiseTauCalc vs FallTauCalc
ModifyGraph/W=Taus mode=3
ModifyGraph/W=Taus marker=19
ModifyGraph/W=Taus rgb=(0,0,65280)
Label/W=Taus left "Tau fall (ms)"
Label/W=Taus bottom "Tau rise (ms)"



V_FitError=0		

Variable InputResistance	


try
	CurveFit/NTHR=1/Q line  IClampVoltage /X=IClampCommand_current /D; AbortOnRTE
	
	if (V_FitError)
			
		Print V_FitQuitReason
		InputResistance = NaN
					
	else
				
		Wave W_coef
		InputResistance = (W_coef[1]*1e3)
				
	endif	

catch
	
	if (V_AbortCode == -4)
		
		Print "Error during curve fit:"
		cfError = GetRTError(1) // 1 to clear the error
		Print GetErrMessage(cfError,3)
		InputResistance = NaN
	
	endif

endtry		
		

TextBox/W=IV_plot/C/N=text2/F=0/A=LT "R\Bmem\M = "+num2str(round(InputResistance))+" \[0M\F'Symbol'W\]0"

//No scale
variable/g gRmOrig =  InputResistance



if(numpnts(RiseTauCalc)>0)
	WaveStats/Q/Z RiseTauCalc
	Variable/g gAvRiseTau = V_avg
	Variable AvRiseTau = V_avg
	Duplicate/O RiseTauCalc, RiseRmCalc
	RiseRmCalc = ((RiseRmCalc/1e3)/(InputResistance*1e6))*1e12
	WaveStats/Q/Z  RiseRmCalc
	Variable AvRiseCap =V_avg
	Variable AvRiseCapSEM =V_sem
	Variable/g gAvRiseCap = AvRiseCap
	Variable/g gAvRiseCapSEM = AvRiseCapSEM
else
	Variable/g gAvRiseTau = NaN
	Variable/g gAvRiseCap = NaN
	Variable/g gAvRiseCapSEM = NaN
	
endif

if(numpnts(FallTauCalc)>0)
	WaveStats/Q/Z FallTauCalc
	Variable/g gAvFallTau = V_avg
	Variable AvFallTau = V_avg
	Duplicate/O FallTauCalc, FallRmCalc
	FallRmCalc = ((FallRmCalc/1e3)/(InputResistance*1e6))*1e12
	WaveStats/Q/Z  FallRmCalc
	Variable AvFallCap =V_avg
	Variable AvFallCapSEM =V_sem
	Variable/g gAvFallCap = AvFallCap
	Variable/g gAvFallCapSEM = AvFallCapSEM
	
else
	Variable/g gAvFallTau = NaN
	Variable/g gAvFallCap = NaN
	Variable/g gAvFallCapSEM = NaN

endif



Variable/g gCapTauOrig = ((AvFallTau/1e3)/(InputResistance*1e6))*1e12



Add_capacitance_labels()


End


//Add values to Cap traces

Function Add_capacitance_labels()

SetDataFolder root:


NVAR gInputResistance




Wave TauRise,TauFall,UsedCalc,GraphNo


variable i,RisingTau,FallingTau,Used,corrRisingTau,corrFallingTau,corrRm,CapRise,CapFall
String GraphNm



for(i=0;i<numpnts(GraphNo);i+=1)

	GraphNm = "Cap_trace_"+num2str(GraphNo[i])

	CorrRm = gInputResistance*1e6
	
	RisingTau = TauRise[i]
	CorrRisingTau = RisingTau*1e-3

	FallingTau = TauFall[i]
	CorrFallingTau = FallingTau*1e-3
	
	CapRise = (CorrRisingTau/CorrRm)*1e12
	CapFall = (CorrFallingTau/CorrRm)*1e12
	
	
	
	
	Used = UsedCalc[i]

	if(Used==1)
		TextBox/W=$GraphNm/C/N=text0/A=MT/X=-5.32/Y=6.64  "\K(0,0,65280)Falling Tau: "+num2str(FallingTau)+" (ms)\tCap Fall: "+num2str(CapFall)+" (pF)\rRising Tau: "+num2str(RisingTau)+" (ms) \tCap Fall: "+num2str(CapRise)+" (pF)"
	else
		TextBox/W=$GraphNm/C/N=text0/A=MT/X=-5.32/Y=6.64  "\K(65280,0,0)Falling Tau: "+num2str(FallingTau)+" (ms)\tCap Fall:"+num2str(CapFall)+" (pF)\rRising Tau: "+num2str(RisingTau)+" (ms) \tCap Fall:"+num2str(CapRise)+" (pF)"
	endif

endfor


Datatable_S()

End