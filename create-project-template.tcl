### Template for tcl scripting ###
## BEGIN script parameters
## Change the value of these variables
set project_dir "/path/to/project/dir"
set project_name "your-project-name"
set board_path "/path/to/board/files"
set ip_location_folder "/path/to/ip/dependencies"
set bd_location_folder "/path/to/bd/location"
## END script parameters 

puts "Project directory is $project_dir"
puts "Project name is $project_name"

puts "Including board specifications from $board_path ..."
set_param board.repoPaths [list $board_path ]
puts "Include complete"
puts "Boards included are:"
get_board_parts *digilentinc*

# Always create a project before adding repo paths
puts "Creating project ..."
create_project $project_name "${project_dir}" -part xc7z010clg400-1
puts "Project created"

puts "Getting custom interfaces and abstractions"
set_property ip_repo_paths [concat [get_property ip_repo_paths [current_project]] [list "${ip_location_folder}/tmds_v1_0"]] [current_fileset]
set_property ip_repo_paths "[get_property ip_repo_paths [current_project]] {${ip_location_folder}/rgb2dvi}" [current_project]
update_ip_catalog -rebuild
puts "Interfaces and abstractions OK"

set_property target_language VHDL [current_project]
set_property simulator_language VHDL [current_project]
set_property board_part digilentinc.com:zybo-z7-10:part0:1.2 [current_project]

add_files -norecurse "${bd_location_folder}/FirstCameraIP/FirstCameraIP.bd"
add_files -norecurse "${bd_location_folder}/HDMI_INT/HDMI_INT.bd"
add_files -norecurse "${bd_location_folder}/XVCLK_PLL/XVCLK_PLL.bd"
add_files -norecurse "${bd_location_folder}/FC_DM/FC_DM.bd"

