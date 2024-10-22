# Öffne das bestehende Projekt
open_project C:/Users/michael/Documents/git/open-hw-cnn/OPEN-HW-CNN/OPEN-HW-CNN.xpr

# Erstelle das IP-Core-Projekt und speichere es im Zielverzeichnis
ipx::package_project -root_dir C:/Users/michael/Desktop/asd -vendor xilinx.com -library user -taxonomy /UserIP -import_files -set_current false

# Entlade die aktuelle IP-Konfiguration
ipx::unload_core c:/Users/michael/Desktop/asd/component.xml

# Bearbeite die IP in einem temporären Projekt, um ein Upgrade durchzuführen
ipx::edit_ip_in_project -upgrade true -name tmp_edit_project -directory C:/Users/michael/Desktop/asd c:/Users/michael/Desktop/asd/component.xml

# Setze die Identifikationsparameter für die IP
set_property vendor "xilinx.com" [ipx::current_core]
set_property library "user" [ipx::current_core]
set_property name "seq_cnn_hw_acc" [ipx::current_core]
set_property version "1.0" [ipx::current_core]
set_property display_name "seq_cnn_hw_acc_v1_0" [ipx::current_core]
set_property description "seq_cnn_hw_acc_v1_0" [ipx::current_core]
set_property vendor_display_name "" [ipx::current_core]
set_property company_url "" [ipx::current_core]

# Speichere die Änderungen und schließe das temporäre Projekt
ipx::save_core [ipx::current_core]
close_project

# Kopiere die IP in den Zielordner
#file mkdir C:/Users/michael/Desktop/ip_output
# Funktion zum rekursiven Kopieren, mit Filter für 'tmp'
proc copy_directory {src dest} {
    foreach file_or_dir [glob -nocomplain -directory $src *] {
        if {![regexp {^tmp} [file tail $file_or_dir]]} {
            set dest_path "$dest/[file tail $file_or_dir]"
            if {[file isdirectory $file_or_dir]} {
                file mkdir $dest_path
                copy_directory $file_or_dir $dest_path
            } else {
                file copy -force $file_or_dir $dest_path
            }
        }
    }
}

# Führe den rekursiven Kopiervorgang aus, aber kopiere keine Dateien oder Verzeichnisse, die mit 'tmp' beginnen
copy_directory C:/Users/michael/Desktop/asd C:/Users/michael/Desktop/ip_output

# Mit diesem Befehl wird das Package IP Fenster in Vivado geöffnet
# ipx::open_ipxact_file C:/Users/michael/Desktop/asd/component.xml