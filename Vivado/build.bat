SET vivado=C:\Xilinx\Vivado\2018.2\bin\vivado.bat
@ECHO OFF
if exist %vivado% (
	%vivado% -mode batch -source build.tcl
) else (
	ECHO.
	ECHO ################################
	ECHO ###  ERROR Launching Vivado  ###
	ECHO ################################
	ECHO.
	pause
)