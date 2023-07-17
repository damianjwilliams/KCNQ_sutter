-///////////////////////////////Changed so works with mutant////////////////////
/////Change back for WT


#include <Waves Average>
//#include <AnnotationInfo Procs>



Constant kKCNQAmpStart = 1900
Constant kKCNQLengthMeasure = 50

Constant kKCNQTCstart = 2185
Constant kKCNQTCLength = 10

Constant kKCNQLeakStart = 400
Constant kKCNQLeakLength =  20

Constant kIVPlotStart = 500
Constant kIVPlotEnd =  2400

Constant kOtherPlotStart = 250
Constant kOtherPlotEnd =  1850



Function KCNQanalysis()

NVAR/Z grun_sutter =root:grun_sutter
if(!NVAR_Exists(grun_sutter))
Variable/g  grun_sutter = 0
endif 

if(grun_sutter == 1)

Cell_Info_KCNQ_sutter()
else
Cell_Info_KCNQ_neuromatic()
endif

end



Function Cell_Info_KCNQ_sutter()

setdatafolder root:cell_details
SVAR cell_id = gcell_id

setdatafolder root:

renameDataFolder cell_details $(cell_id)

NVAR gCapacitance,gRm,gRa,gHold
SVAR gGenotype

variable Capacitance = NumVarOrDefault("gCapacitance",NaN)
variable Rm = NumVarOrDefault("gRm",NaN)
variable Hold = NumVarOrDefault("gHold",NaN)
variable Ra = NumVarOrDefault("gRa",NaN)



Prompt Capacitance, "Capacitance (pF)"
Prompt Rm, "Input Resistance (pF)"
Prompt Ra, "Series Resistance (MOhm)"
Prompt Hold, "Holding current -75 mV (pF)"

DoPrompt "Cell Information" Capacitance, Rm, Ra, Hold


variable/g gCapacitance,gRm,gRa,ghold

gCapacitance = Capacitance
gRm = Rm
gRa = Ra
gHold = Hold

//Add all the wave to the cell id folder

SVAR working_df = root:working_df

DFREF currdf = getdataFolderDFR()

setdatafolder $working_df

string all_waves = WaveList("*",";","")

variable number_waves = Itemsinlist(all_waves)


variable i
For(i=0;i<number_waves;i+=1)

string curr_wave = stringfromList(i,all_waves)

movewave $curr_wave, root:$(cell_id):

endfor

KCNQCalcs(cell_id)

end










Function Cell_Info_KCNQ_neuromatic()


Variable  Capacitance,Rm, Ra,Hold
Variable refNum
setdataFolder root:
SVAR gCustomPath

String message = "Select Delayed Rectifier recording file"
String outputPath
String fileFilters = "Axon stats files (*.abf):.abf;"
fileFilters += "All Files:.*;"
Open /D /R /F=fileFilters /M=message refNum
outputPath = S_fileName
string folder_name = ParseFilePath(0, outputPath, ":", 1, 1)
string folder_path = ParseFilePath(1, outputPath, ":", 1, 0)

newpath/O stafolder,folder_path


string FileList = IndexedFile(stafolder, -1, "????")
string StaFileNameSemi =GrepList(FileList,".*\.sta")

variable twlen = strlen(StaFileNameSemi)
string sta_file_name_clean = StaFileNameSemi[0,twlen-2]

if(GrepString(sta_file_name_clean,".*\.sta" )==1)

//string sta_file_name = stringfromlist(0,StaFileNameSemi)
string full_path_sta = folder_path+sta_file_name_clean

get_sta_details(full_path_sta)

endif

String expr, Date_id, Dish, Cell, Genotype
expr = "([a-zA-Z0-9-]+)_([a-zA-Z0-9-]+)_([a-zA-Z0-9-]+)_([a-zA-Z0-9-]+)"
SplitString /E=expr folder_name,Date_id, Dish, Cell, Genotype
string cell_id = Date_id+"_"+Dish+"_"+Cell


String/g root:gcell_id = cell_id

SVAR gcell_id
NVAR gCapacitance,gRm,gRa,gHold
SVAR gGenotype

Capacitance = NumVarOrDefault("gCapacitance",NaN)
Rm = NumVarOrDefault("gRm",NaN)
Hold = NumVarOrDefault("gHold",NaN)
Ra = NumVarOrDefault("gRa",NaN)



Prompt Capacitance, "Capacitance (pF)"
Prompt Rm, "Input Resistance (pF)"
Prompt Ra, "Series Resistance (MOhm)"
Prompt Hold, "Holding current -75 mV (pF)"

DoPrompt "Cell Information" Capacitance, Rm, Ra, Hold


NMImportFile("new", outputPath, nmPrefix=0)

String NeuromaticFolderNameStr = GetDataFolder(1)

setdataFolder root:
renameDataFolder $NeuromaticFolderNameStr,$cell_id
setdataFolder root:$(cell_id)

variable/g gCapacitance,gRm,gRa,ghold
string/g gGenotype

gCapacitance = Capacitance
gRm = Rm
gRa = Ra
gHold = Hold
gGenotype = Genotype 

KCNQCalcs(cell_id)

End


Function KCNQCalcs(cell_id)

string cell_id

SVAR gCustomPath = root:gCustomPath

NVAR grun_sutter = root:grun_sutter


setdatafolder root:$(cell_id)

SVAR gcell_id
SVAR gGenotype
NVAR gRm
NVAR gHold
NVAR gRa
NVAR gCapacitance



Variable refNum,j,k, TenCrossVal,Startcross,EndCross,NumAbfFiles,idx,Recording_type,idx1,IVNo
Variable num_traces_to_remove_end

String CurrentAbfFile,Current_treatment,RawCurrNm,NormCurrNm,TailCurrNm,ConductancePlotNm
String TailCurrTblNm, TailComTblNm

string Command_V_name,I_mem_name,I_mem_list_name,Command_V_list_name


I_mem_name = "RecordA"
Command_V_name = "RecordB"
//num_traces_to_remove_end = 2



I_mem_list_name = I_mem_name+"*"
Command_V_list_name = Command_V_name+"*"


j=0
idx = 0
idx1 = 0




Make/O/N=0 current_amplitude_table
Make/O/N=0 command_voltage_table
Make/O/N=0 sweep_number_table
Make/O/N=0 tail_current_table

string list_current_sweeps = Wavelist(I_mem_list_name,";","")
variable number_current_sweeps = Itemsinlist(list_current_sweeps)


variable current_amplitude, command_voltage, tail_current_amplitude



variable y1,x1,y2,x2,gradient,intercept

display/N=leak_adjusted_plots
display/N=raw_current_plots



if(dataFolderExists("root:kcnq_template"))

duplicateDataFolder/O=1 root:kcnq_template,root:temp_command_folder

endif



for(j=0;j< number_current_sweeps;j+=1)

string TrcCrrNm = I_mem_name +num2str(j)
string TrcCmdNm = Command_V_name +num2str(j)


if(dataFolderExists("root:kcnq_template"))

DFREF currDF = getdataFolderDFR()
setdataFolder root:temp_command_folder
Wave TraceCmd = $TrcCmdNm
setdataFolder currdf

else
		
Wave TraceCmd = $TrcCmdNm

endif


Wave TraceCurr = $TrcCrrNm




if(grun_sutter == 1)

	variable i_trace_scale = dimdelta(TraceCurr,0)
	variable i_trace_scale_ms = i_trace_scale*1000
	setscale/P x,0,i_trace_scale_ms,"ms",TraceCurr	
	variable max_x_val = rightx(TraceCurr)
	setscale/I x,0,max_x_val,"ms",TraceCmd
	TraceCmd = TraceCmd*1000
	
endif



y1 = 0
x1 = 0
WaveStats/Q/R=(kKCNQLeakStart,kKCNQLeakStart+kKCNQLeakLength) TraceCurr
y2 = V_avg
WaveStats/Q/R=(kKCNQLeakStart,kKCNQLeakStart+kKCNQLeakLength) TraceCmd
x2 = V_avg
gradient = ((y2-y1)/(x2-x1))
intercept = y2-(gradient*x2)

string leak_adjusted_name = TrcCrrNm+"_leak_adjusted"

Duplicate/O $TrcCrrNm, $leak_adjusted_name

Wave leak_adjusted_trace = $leak_adjusted_name

leak_adjusted_trace = TraceCurr - (TraceCmd*gradient+intercept)

if(grun_sutter == 1)

	variable leak_adjusted_trace_scale = dimdelta(leak_adjusted_trace,0)
	variable leak_adjusted_trace_scale_ms = leak_adjusted_trace_scale*1000
	setscale/P x,0,leak_adjusted_trace_scale_ms,"ms",leak_adjusted_trace	
	
	
endif





//Raw current 
WaveStats/Q/R=(kKCNQAmpStart,kKCNQAmpStart+kKCNQLengthMeasure) leak_adjusted_trace
current_amplitude = V_avg

print ("Current amplitude "+num2str(current_amplitude))

WaveStats/Q/R=(kKCNQAmpStart,kKCNQAmpStart+kKCNQLengthMeasure) TraceCmd
command_voltage = V_avg
print ("Command voltage "+num2str(command_voltage))


//Tail current
WaveStats/Q/R=(kKCNQTCstart,kKCNQTCstart+kKCNQTCLength) leak_adjusted_trace
tail_current_amplitude = V_avg

print ("Tail current amplitude "+num2str(tail_current_amplitude))






//Insert measurments into Cell table
//Sweep Number
InsertPoints Inf,1, sweep_number_table
sweep_number_table[Inf] =  j+1

InsertPoints Inf,1, current_amplitude_table
current_amplitude_table[Inf] =  current_amplitude

InsertPoints Inf,1, command_voltage_table
command_voltage_table[Inf] =   command_voltage

InsertPoints Inf,1, tail_current_table
tail_current_table[Inf] =   tail_current_amplitude


AppendToGraph/W=leak_adjusted_plots  leak_adjusted_trace
AppendToGraph/W=raw_current_plots  TraceCurr

endfor







//Add the -20 mV amplitude
Findlevel/P command_voltage_table -22
variable minus_twenty_trace_pnt = round(V_LevelX)
string  minus_twenty_trace_nm = I_mem_name+num2str(minus_twenty_trace_pnt)+"_leak_adjusted"
string  minus_twenty_voltage_nm = Command_V_name+num2str(minus_twenty_trace_pnt)

wave  minus_twenty_trace = $minus_twenty_trace_nm 
wave  minus_twenty_voltage = $minus_twenty_voltage_nm


WaveStats/Q/R=(kKCNQAmpStart,kKCNQAmpStart+kKCNQLengthMeasure) minus_twenty_trace
variable minus_twenty_amp = V_avg

WaveStats/Q/R=(kKCNQAmpStart,kKCNQAmpStart+kKCNQLengthMeasure)minus_twenty_voltage
variable minus_twenty_volt = V_avg

Display/N=minus_twenty minus_twenty_trace
Label/W=minus_twenty bottom "Time mS"
Label/W=minus_twenty left "Current (pA)"
TextBox/W=minus_twenty/C/N=titleX/F=0/A=MT/E=1/B=1 cell_id+"\tVoltage: "+num2str(minus_twenty_volt)+"\tCurrent: "+num2str(minus_twenty_amp)

variable/g gminus_twenty_amp = minus_twenty_amp
variable/g gminus_twenty_volt = minus_twenty_volt



duplicate tail_current_table tail_conductance_table


Wavestats/Q tail_conductance_table
tail_conductance_table = tail_conductance_table-V_min

Wavestats/Q tail_conductance_table
tail_conductance_table = tail_conductance_table/V_max




//Conductance plot
Display/N= conductance_plot tail_conductance_table vs command_voltage_table

Variable Rate_measure,x_half,V_half_measure

Make/O Whatever = {0,1,-45,11}

CurveFit/H="1100"/NTHR=0 Sigmoid kwCWave=Whatever,  tail_conductance_table /X=command_voltage_table /D 

V_half_measure = Whatever[2]
Rate_measure =  Whatever[3]

variable/g gV_half_measure,gRate_measure

gV_half_measure = V_half_measure
gRate_measure = Rate_measure

String conducantance_fit_trace = "fit_tail_conductance_table"
Variable RelMeasure = 4.0

ModifyGraph/W=conductance_plot mode=3,marker=19,gfRelSize= RelMeasure
ModifyGraph/W=conductance_plot mode($conducantance_fit_trace)=0,rgb($conducantance_fit_trace)=(0,0,65535)

Label/W=conductance_plot bottom "Command Voltage (mV)"
Label/W=conductance_plot left "Conductance"
TextBox/W=conductance_plot/C/N=titleX/F=0/A=MT/E=1/B=1 cell_id
TextBox/W=conductance_plot/C/B=1/N=CF_Conductance/F=0/A=RB/X=1.83/Y=4.76 "\\Zr100V1/2: "+num2str(V_half_measure )+" mV\rRate: "+num2str(Rate_measure)+" mV/efold"
DoWindow/F conductance_plot




wavestats/q current_amplitude_table
variable max_height = (V_max*1.1)
variable min_height = (V_min*0.9)

//Raw Currrent
//SetAxis/W=raw_current_plots left min_height, max_height
ModifyGraph/W=raw_current_plots gfRelSize= RelMeasure
//SetAxis/W=$CondRawCurrNm bottom 2040,2250
Label/W=raw_current_plots left "Current (pA)"
Label/W=raw_current_plots bottom "Time (ms)"
TextBox/W=raw_current_plots/C/N=titleC/F=0/A=MT/E=1/B=1 "Raw current"



//Add lines to show measurment position

Wavestats/Q current_amplitude_table

setaxis/W=leak_adjusted_plots left,V_min*1.4,V_max*1.4
setaxis/W=minus_twenty left,V_min*1.4,V_max*1.4


getAxis/W=leak_adjusted_plots left

SetDrawEnv/W=leak_adjusted_plots xcoord= bottom,ycoord= left,dash=2,linethick=1
DrawLine/W=leak_adjusted_plots kKCNQTCstart,V_max,kKCNQTCstart,V_min

SetDrawEnv/W=leak_adjusted_plots xcoord= bottom,ycoord= left,dash=2,linethick=1
DrawLine/W=leak_adjusted_plots (kKCNQTCstart+kKCNQTCLength),V_max,(kKCNQTCstart+kKCNQTCLength),V_min


Display/N=cell_details_1
TextBox/W=cell_details_1/C/B=1/N=Tinfo/F=0/A=MC "\\Zr130Conductance\rCell_ID\t" + cell_id+"\r"+"Genotype\t" +gGenotype

Display/N=cell_details_2
TextBox/W=cell_details_2/C/B=1/N=Passive/F=0/A=MC "\\Zr130Cap_pF\t" +num2str(gCapacitance)+"\r"+"Hold_current:\t" +num2str(gHold)+" pA\r"+"Series_resistance=\t"+num2str(gRa)+" MOhm\r"+"Input_resistance =\t"+num2str(gRm)+" MOhm"

ConductanceLayout(gcell_id)

End


Function ConductanceLayout(gcell_id)

string gcell_id

setdatafolder root:


SVAR gCustomPath



	
	NewLayout/N=data_layout/W=(369,63,875,417)
	if (IgorVersion() >= 7.00)
		LayoutPageAction size=(612,792),margins=(18,18,18,18)
	endif
	ModifyLayout mag=0.25
	AppendLayoutObject/W=data_layout/F=1/T=0/R=(309,184,588,372) Graph leak_adjusted_plots
	AppendLayoutObject/W=data_layout/F=1/T=0/R=(16,180,308,376) Graph raw_current_plots
	AppendLayoutObject/W=data_layout/F=1/T=0/R=(84,371,479,560) Graph conductance_plot
	AppendLayoutObject/W=data_layout/F=1/T=0/R=(16,24,308,180) Graph cell_details_1
	AppendLayoutObject/W=data_layout/F=1/T=0/R=(308,24,616,184) Graph cell_details_2
	AppendLayoutObject/W=data_layout/F=1/T=0/R=(82,565,479,775) Graph minus_twenty

SavePict/E=-8/O/WIN=data_layout as  gCustomPath+gcell_id+"_conductance.pdf"


setdataFolder root:$gcell_id


SVAR gGenotype
NVAR gRm
NVAR gHold
NVAR gRa
NVAR gCapacitance,gV_half_measure,gRate_measure,gminus_twenty_amp,gminus_twenty_volt


string notebookname = "Data_"+gcell_id


NewNotebook/N=$NotebookName/F=0/V=1/K=0 as " General Data"

Notebook $NotebookName defaultTab=75

Notebook $NotebookName, fstyle=1, text = "Cell_ID\t" + gcell_id+"\r"
Notebook $NotebookName text = "Genotype\t" +gGenotype+"\r"
Notebook $NotebookName text = "Cap_VC_pA\t" +num2str(gCapacitance)+"\r"
Notebook $NotebookName text = "Rm_VC_MOhm\t" + num2str(gRm) +"\r"
Notebook $NotebookName text = "Ra_VC_MOhm\t" + num2str(gRa) +"\r"
Notebook $NotebookName text = "Leak_at_-80_mV\t" + num2str(gHold) +"\r"
Notebook $NotebookName text = "V_half_mV\t" + num2str(gV_half_measure) +"\r"
Notebook $NotebookName text = "Rate_mV_efold\t" + num2str(gRate_measure) +"\r"
Notebook $NotebookName text = "Amp_at_-20_mV\t" + num2str(gminus_twenty_amp) +"\r"
Notebook $NotebookName text = "Voltage_check_mV\t" + num2str(gminus_twenty_volt) +"\r"


SaveNotebook/O/S=6 $NoteBookName as gCustomPath+gcell_id+"_data.txt"


end






Function KillAllGraphs()
    string fulllist = WinList("*", ";","WIN:23")
    string name, cmd
    variable i
   
    for(i=0; i<itemsinlist(fulllist); i +=1)
        name= stringfromlist(i, fulllist)
        name= stringfromlist(i, fulllist)
		Dowindow/K $name   
    endfor
end

macro  killGraphs()
KillAllGraphs()
end



Function get_sta_details(full_path_sta)

string full_path_sta

LoadWave/G/A/W/Q full_path_sta

Wave Memb_Test_0_Memb_Test_Ra__MOhm_
Wavestats/Q Memb_Test_0_Memb_Test_Ra__MOhm_
Variable/g gRa = V_avg

Wave Memb_Test_0_Memb_Test_Cm__pF_
Wavestats/Q Memb_Test_0_Memb_Test_Cm__pF_
Variable/g gCapacitance = V_avg

Wave Memb_Test_0_Memb_Test_Holding__pA_
Wavestats/Q Memb_Test_0_Memb_Test_Holding__pA_
Variable/g gHold = V_avg


end


Function Make_template_wave(matchStr)
	String matchStr	// As for the WaveList function.	
	String list
	setDataFolder root:kcnq_template
	list = WaveList(matchStr, ";", "")
	concatenate/O/NP=1/DL list,out_wave
	
	Save/O/J/I out_wave as "export_wave.txt"
	
End




Function import_template_wave()

newdatafolder/S/O root:kcnq_template

LoadWave/A=RecordB/J/I/O/N

string all_waves = WaveList("*",";","")
variable number_waves = Itemsinlist(all_waves)

variable i

For(i=0;i<number_waves;i+=1)

string curr_wave = stringfromList(i,all_waves)
setscale/P x,0,1e-5,"s",$curr_wave
SetScale d 0,0,"V", $curr_wave	

endfor





end
	
	