#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later


//Open folder in Sutter

Menu "DJW Sutter Macros", dynamic
"Delete current sweep sets for import",/Q, delete_sutter_files()
"Rearrange Sutter files",/Q, put_in_folders()
"Run Sutter analysis",/Q, check_and_run()
"Create KCNQ template folder",/Q,template_file_for_KCNQ3()
"Import KCNQ voltage template",/Q,import_template_wave()
End



Function put_in_folders()

string/g root:gCustomPath = "C:\\Users\\dw2471\\OneDrive - cumc.columbia.edu\\temp\\igor_output\\"

setdatafolder root:SutterPatch:Data


 
variable number_sweeps,i,k,num_sets
string start_sweep_name = "Record"
string complete_sweep_name


string list_sweep_sets = Wavelist("*_S1_*",";","")
list_sweep_sets = ListMatch(list_sweep_sets, "!*_min")

string current_mp_set_nm, current_cmd_set_nm

num_sets = Itemsinlist(list_sweep_sets)

print(list_sweep_sets)


For(k=0;k<num_sets;k+=1)

current_mp_set_nm = stringFromList(k,list_sweep_sets)
//print(current_mp_set_nm)
current_cmd_set_nm = ReplaceString("_S1_",current_mp_set_nm,"_S2_")
//print(current_cmd_set_nm)

string new_folder_name = current_mp_set_nm+"_set"

newdataFolder/O $new_folder_name


Wave current_mp_rec = $current_mp_set_nm
Wave current_cmd_rec = $current_cmd_set_nm

number_sweeps = DimSize(current_mp_rec,1)

For(i=0;i<number_sweeps;i+=1)

//if(Stringmatch(current_mp_set_nm,"*S1*"))
complete_sweep_name = "RecordA"+num2str(i)
Duplicate/O/R=[][i,i] current_mp_rec, $complete_sweep_name
MoveWave $complete_sweep_name,root:sutterPatch:Data:$(new_folder_name):

string complete_cmd_sweep_name = "RecordB"+num2str(i)
Duplicate/O/R=[][i,i] current_cmd_rec, $complete_cmd_sweep_name
MoveWave $complete_cmd_sweep_name,root:sutterPatch:Data:$(new_folder_name):

endfor

endfor


End




Function check_and_run()

String list_of_sets,list_working_mp_sweeps,working_mp_sweep,graph_name
variable number_sets,i,j,number_working_mp_sweeps

setdataFolder root:
variable/g run_sutter = 1
NVAR gKCNQ_template
NVAR gtemplate_is_complete 

setdataFolder root:sutterpatch:data


list_of_sets = datafolderlist("*_set",";")
//print(list_of_sets)
number_sets = Itemsinlist(list_of_sets)
For(i=0;i<number_sets;i+=1)
	
	setdataFolder root:sutterpatch:data
	setdatafolder(stringfromList(i,list_of_sets))
	//Get correct list
	if(gtemplate_is_complete==0)
	list_working_mp_sweeps = Wavelist("RecordB*",";","")
	else
	list_working_mp_sweeps = Wavelist("RecordA*",";","")
	endif
	number_working_mp_sweeps = Itemsinlist(list_working_mp_sweeps)
	graph_name = stringfromList(i,list_of_sets)
	Display/N=$graph_name 

	//Add all plots_to_trace
	For(j=0;j<Itemsinlist(list_working_mp_sweeps);j+=1)
		working_mp_sweep = stringfromList(j,list_working_mp_sweeps)
		print(working_mp_sweep)
		AppendtoGraph/W=$graph_name $working_mp_sweep
	endfor
	
	check_traces(graph_name)
	
	setdatafolder "::"
	
	endfor

End


Function check_traces(graph_name)

string graph_name


PauseUpdate; Silent 1 // building window …
NewPanel/N=check_panel/W=(150,50,450,212)
AutoPositionWindow/E/M=1/R=$graph_name
variable/g root:gRadioVal= 1
CheckBox check0,pos={52,25},size={78,15},title="Analyze"
CheckBox check0,value=0,mode=1,proc=check_trace_proc
CheckBox check1,value=0,mode=1,proc=check_trace_proc

Button button1,pos={75,120},size={161,35},proc= check_trace_button,title="Continue"
PauseForUser check_panel

End


Function check_trace_button(ctrlName) : ButtonControl
   String ctrlName   
    KillWindow check_panel
    KillAllGraphs()
End





Function check_trace_proc(name,value)


String name
Variable value
variable/g gRadioVal
NVAR/Z gKCNQ_template = root:gKCNQ_template

if (!NVAR_Exists(gKCNQ_template))	// No such global numeric variable?
	Variable/G root:gKCNQ_template = 0	// Create and initialize it
endif

if(gKCNQ_template==1)
print("*********************************************")
string current_df = getdatafolder(1)
DuplicateDataFolder $current_df, root:kcnq_template
string matchStr = "RecordB*"
Make_template_wave(matchStr)
KillAllGraphs()
KillWindow check_panel

Return value
endif





strswitch (name)
case "check0":
print("good")
KillAllGraphs()
KillWindow check_panel
choose_analysis()
break
case "check1":
gRadioVal= 2 
KillAllGraphs()
KillWindow check_panel
break
endswitch
CheckBox check0,value= gRadioVal ==1 
CheckBox check1,value= gRadioVal ==2 
End






Function choose_analysis()

newdatafolder/O root:cell_details

String analysis_type
String saveDF = GetDataFolder(1)
String cell_id = StrVarOrDefault("root:cell_details:gcell_id", "YYMMDD_cX_dx")
String genotype = StrVarOrDefault("root:cell_details:ggenotype", "WT")
String reporter = StrVarOrDefault("root:cell_details:greporter", "NA-NA")
String rmp = StrVarOrDefault("root:cell_details:grmp", "NA")
Prompt cell_id, "Cell ID"
Prompt genotype, "Genotype"
Prompt reporter, "Reporter"
Prompt rmp, "Resting membrane potential "

Prompt analysis_type,"Choose analysis type", popup "KCNQ;Passive properties;Action potentials"
DoPrompt "test",cell_id,genotype,reporter,RMP,analysis_type

String/G root:cell_details:gcell_id = cell_id
String/G root:cell_details:ggenotype = genotype
String/G root:cell_details:greporter = reporter
String/G root:cell_details:grmp = rmp 

String/g root:gCellFolderName = cell_id

SetDataFolder saveDF
do_analysis(analysis_type)
End




Function do_analysis(analysis_type)

String analysis_type

String/g root:ganalysis_type = analysis_type

string/g root:working_df = getdataFolder(1)

strswitch(analysis_type)
case "KCNQ":
variable/g root:grun_sutter = 1
print("do KCNQ analysis")
KCNQanalysis()
break
case "Passive properties":
print("do passive properties analysis")
hyperpolarizing_analysis()
break
case "Action potentials":
print("do action potential analysis")
DifferentiatePlot_S()
break
default:
print("not sure how that happened")
endswitch

End


