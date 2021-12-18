@echo off
echo "************************************"
echo "*  AltBIOS BOOT LOGO MAKE UP TOOL  *"
echo "* -------------------------------- *"
echo "*  19th/Dec./2021 HRA!             *"
echo "************************************"
echo " "
echo "Logo data convert process [logo.bmp --> logo.bin]"
.\msx_boot_logo_converter\Release\msx_boot_logo_converter.exe logo.bmp logo.bin
if %errorlevel% geq 1 (
	echo "Failed."
	goto end_of_batch
)
move logo.bin source\logo.bin

echo "Generate ROM code [bootlogo.rom]"
pushd source
..\..\tool\zma ./altbios_boot_logo.asm altbios_boot_logo.bin
if %errorlevel% geq 1 (
	popd
	echo "Failed."
	goto end_of_batch
)

echo "Test program for MSX-DOS [BOOTLOGO.COM]"
..\..\tool\zma ./altbios_boot_logo_test.asm BOOTLOGO.COM
if %errorlevel% geq 1 (
	popd
	echo "Failed."
	goto end_of_batch
)

move altbios_boot_logo.bin ..
move BOOTLOGO.COM ..
popd

echo "************************************"
echo "*       SUCCESS OF ALL!!           *"
echo "************************************"

:end_of_batch

if exist zma.log (
	del zma.log
)
if exist zma.sym (
	del zma.sym
)
pause
