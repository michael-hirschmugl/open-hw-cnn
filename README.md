# open-hw-cnn
A scalable, open source hardware accelerator for CNN processing on Xilinx platforms.

## How to Load Board Files
The Digilent board files are now integrated as a submodule. To load them, simply run the following command:

```bash
git submodule update --init --recursive
```

Once the board files are loaded, you can find a script in the `board_files` folder called `copy-board-files.bat`. This script will copy the board files to the following Vivado directory:

```
C:\Xilinx\Vivado\2024.1\data\xhub\boards\XilinxBoardStore\boards\Xilinx
```

**Note:** This script only works if Vivado was installed in the default directory. If you changed the installation path, you will need to manually copy the board files. Alternatively, you can download the board files directly from this link:  
[https://github.com/Digilent/vivado-boards/archive/master.zip](https://github.com/Digilent/vivado-boards/archive/master.zip)

For detailed information on where to place the board files, refer to Digilent's guide here:  
[https://digilent.com/reference/programmable-logic/guides/installing-vivado-and-vitis](https://digilent.com/reference/programmable-logic/guides/installing-vivado-and-vitis)

The repository for the board files is:  
[https://github.com/Digilent/vivado-boards.git](https://github.com/Digilent/vivado-boards.git)

This project uses commit `8ed4f9981da1d80badb0b1f65e250b2dbf7a564d` from September 2023.

### Verifying Installation
To verify if the board files were installed correctly, open the Vivado TCL console and run the following command:

```tcl
get_board_parts *arty-z7-20*
```

## Building the Project
To create the Vivado project from this repository, follow these steps:

1. Open Vivado.
2. Go to **Tools** and select **Run Tcl Script**.
3. Navigate to the repository directory and open the `build.tcl` file located in the root folder.
   
   Once the `build.tcl` script is executed, it will create a new directory called `OPEN-HW-CNN`. Inside this directory, Vivado will build the actual project using the VHDL files found under the `src` directory.

## Creating an IP Core

To create an IP core that can be imported into another project, follow these steps:

1. Run the `package_ip.tcl` script located in the root folder of the repository.
This script will generate an IP core based on the settings defined in the `config.tcl` file. The IP core will be saved in the `ip_output` directory.

## Configuration

The `config.tcl` file allows you to configure both the project and the IP core. You can modify:

- The project name (used when creating the project directory).
- The IP core name and other metadata, such as vendor, library, version, display name, description, etc.

## Running Both Build and Packaging

You can easily run both the build and package processes in sequence by using the `run_build_and_package.bat` file. This batch file will first execute the `build.tcl` script to build the project, and then the `package_ip.tcl` script to generate the IP core.

## Updates
- The library is now fully integrated into the `build.tcl` script. When the script is executed, the project will be created, and the library will be included as a library.
- Unnecessary synthesis runs have been removed.
- Unused source files have not been disabled yet, but this is not a priority at the moment.
- The `build.tcl` script has been adjusted to use the correct version of the board files.

## Vivado Version
This project is built with:

Vivado v2024.1 (64-bit)  
SW Build: 5076996 on Wed May 22 18:37:14 MDT 2024  
IP Build: 5075265 on Wed May 22 21:45:21 MDT 2024  
SharedData Build: 5076995 on Wed May 22 18:29:18 MDT 2024
