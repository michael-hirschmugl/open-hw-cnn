# Load the configuration file (assumed to be in the same directory as the script)
set config_file [file join [file dirname [info script]] "config.tcl"]
if {[file exists $config_file]} {
    source $config_file
} else {
    puts "Error: Configuration file not found: $config_file"
    exit 1
}

# Output the loaded configuration values for debugging
puts "Loaded configuration:"
puts "Project name: $project_name"
puts "IP name: $ip_name"
puts "Vendor: $vendor"
puts "Library: $library"
puts "Name: $name"
puts "Version: $version"
puts "Display Name: $display_name"
puts "Description: $description"
puts "Vendor Display Name: $vendor_display_name"
puts "Company URL: $company_url"

# Determine the directory where the script is being executed
set current_dir [file dirname [info script]]
puts "Script directory: $current_dir"

# Create the tmp directory in the script's directory
set tmp_dir "$current_dir/tmp"
puts "Creating tmp directory: $tmp_dir"
file mkdir $tmp_dir

# Open the existing project and create the IP-Core project in the tmp directory
open_project "$current_dir/$project_name/$project_name.xpr"

# Package IP in the "tmp" directory
puts "Creating IP in tmp directory: $tmp_dir"
ipx::package_project -root_dir $tmp_dir -vendor $vendor -library $library -taxonomy /UserIP -import_files -set_current false

# Check if files exist in the tmp directory
puts "Contents of tmp directory:"
foreach f [glob -directory $tmp_dir *] {
    puts $f
}

# Unload the current IP configuration
puts "Unloading IP configuration"
ipx::unload_core $tmp_dir/component.xml

# Edit the IP in a temporary project to perform an upgrade
puts "Editing IP in temporary project"
ipx::edit_ip_in_project -upgrade true -name tmp_edit_project -directory $tmp_dir $tmp_dir/component.xml

# Set the IP identification parameters from the configuration file
puts "Setting IP parameters"
set_property vendor $vendor [ipx::current_core]
set_property library $library [ipx::current_core]
set_property name $name [ipx::current_core]
set_property version $version [ipx::current_core]
set_property display_name $display_name [ipx::current_core]
set_property description $description [ipx::current_core]
set_property vendor_display_name $vendor_display_name [ipx::current_core]
set_property company_url $company_url [ipx::current_core]

# Save the IP
puts "Saving IP"
ipx::save_core [ipx::current_core]

# Close the temporary project
puts "Closing project"
close_project

# Create the directory for the IP in "ip_output" and name it after the IP
set ip_output_dir "$current_dir/ip_output/$ip_name"
puts "Creating ip_output directory: $ip_output_dir"
file mkdir -p $ip_output_dir

# Check if the ip_output directory was created
if {[file exists $ip_output_dir]} {
    puts "The ip_output directory was successfully created."
} else {
    puts "Error: The ip_output directory was not created."
}

# Copy the relevant files (except "tmp") to the new IP directory
puts "Copying files from tmp to ip_output"
proc copy_directory {src dest} {
    foreach file_or_dir [glob -nocomplain -directory $src *] {
        if {![regexp {^tmp} [file tail $file_or_dir]]} {
            set dest_path "$dest/[file tail $file_or_dir]"
            if {[file isdirectory $file_or_dir]} {
                file mkdir $dest_path
                copy_directory $file_or_dir $dest_path
            } else {
                puts "Copying file: $file_or_dir to $dest_path"
                file copy -force $file_or_dir $dest_path
            }
        }
    }
}

# Copy all files except "tmp"
copy_directory $tmp_dir $ip_output_dir

# Function to recursively delete the tmp directory
proc delete_directory {dir} {
    foreach file_or_dir [glob -nocomplain -directory $dir *] {
        if {[file isdirectory $file_or_dir]} {
            delete_directory $file_or_dir
        } else {
            puts "Deleting file: $file_or_dir"
            file delete -force $file_or_dir
        }
    }
    puts "Deleting directory: $dir"
    file delete -force $dir
}

# Recursively delete the tmp directory
delete_directory $tmp_dir

# Mit diesem Befehl wird das Package IP Fenster in Vivado geöffnet
# ipx::open_ipxact_file C:/Users/michael/Desktop/asd/component.xml