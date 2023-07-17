#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later


Function delete_sutter_files()

variable i,num_sets

string list_sweep_sets,current_sweep_set,list_sweep_folders,current_sweep_folder

setdatafolder root:SutterPatch:Data
list_sweep_sets = Wavelist("R*",";","")
num_sets = Itemsinlist(list_sweep_sets)
//print("Number of sets = " + num2str(num_sets))
//print("sweep sets in data folder")
//print(list_sweep_sets)

for(i=0;i<num_sets;i+=1)

	current_sweep_set = stringFromList(i,list_sweep_sets)
	print(current_sweep_set)
	//killWaves/Z $current_sweep_set

endfor


//Remove sweep folders
setdatafolder root:SutterPatch:Data

list_sweep_folders = DataFolderList("R*",";")

num_sets = Itemsinlist(list_sweep_folders)
print("number of set data folders  = " + num2str(num_sets))

print(list_sweep_folders)

for(i=0;i<num_sets;i+=1)

	current_sweep_folder = stringFromList(i,list_sweep_folders)
	print(current_sweep_set)	
	
	if(Stringmatch(current_sweep_folder,"!Routines"))
		
		print("yes")		
		KillDataFolder/Z $current_sweep_folder
	
	endif
	

	
	
endfor



setdataFolder Analysis
list_sweep_sets = Wavelist("R*",";","")
num_sets = Itemsinlist(list_sweep_sets)

//print("sweep sets in analysis folder")
//print(list_sweep_sets)

for(i=0;i<num_sets;i+=1)

	current_sweep_set = stringFromList(i,list_sweep_sets)
	print(current_sweep_set)
	killWaves/Z $current_sweep_set

endfor

//remove metadata
setdatafolder root:SutterPatch:Data:Meta
KillWaves/A/Z

End


Function template_file_for_KCNQ3()

variable/g root:gKCNQ_template = 1 

check_and_run()


End


Function Rescale_voltage_trace()



string command_V_traces,working_command_V_trace
variable number_command_I_traces,j

setdataFolder root:kcnq_template
command_V_traces = Wavelist("RecordA*",";","")
number_command_I_traces = Itemsinlist(command_V_traces)
For(j=0;j<number_command_I_traces;j+=1)	
	working_command_V_trace = stringfromList(j,command_V_traces)
	
	Wave command_V_wave  = $working_command_V_trace	
	//variable V_trace_scale = dimdelta(command_V_wave,0)
	//variable V_trace_scale_ms = V_trace_scale*1000
	//setscale/P x,0,V_trace_scale_ms,"ms",command_V_wave
	
	command_V_wave = command_V_wave*1000
	
	
		
endfor

End


