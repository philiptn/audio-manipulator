:: Made by Philip Tønnessen
:: 09.02.2021 - 03.02.2022

@echo off

:: Sets active code page to unicode,
:: allowing the script to deal with special 
:: characters in filenames.
chcp 65001
echo.

SET ffmpeg=bin\ffmpeg-n4.4-latest-win64-lgpl-4.4\bin\ffmpeg.exe

IF NOT EXIST original mkdir original

:: Sets the log verbose level to the terminal
SET loglevel=panic
:: Output samplerate
SET samplerate=44100
:: MP3 output bitrate
SET bitrate=320
:: General variable bitrate preset value
SET audioquality=6
:: Only lets frequenies over 120Hz through.
:: Used in Vaporwave preset.
SET highpass=120
:: Cuts off all frequencies over 5500Hz
:: Used in Vaporwave preset.
SET lowpass=5500

:: Default percentage used in vaporwave preset
SET vpr_p=-9
:: Default percentage used in upspeed preset
SET upsp_p=6.73
:: Default percentage used in downspeed preset
SET dwnsp_p=-5

:input_filetype
SET /P ext="Enter the filetype of files to be processed: (ex: "mp3" for .mp3 files etc.): "

:output_folder_q
echo. 
SET /P output_q="Would you like to save the file(s) in a separate folder? (y/n): "
IF /I "%output_q%" == "y" (
goto folder_sel
) ELSE IF /I "%output_q%" == "n" (
SET output_folder=exports
goto processing_options
) ELSE (
echo. 
echo Error: Invalid input
goto output_folder_q)

:folder_sel
echo. 
SET /P folder="Specify folder name: "
SET output_folder=exports\%folder%
IF NOT EXIST "exports\%folder%" mkdir "exports\%folder%"

:processing_options
echo.
echo Audio transformation options:
echo (1) Vaporwavify
echo (2) +%upsp_p%%% speed shift
echo (3) %dwnsp_p%%% speed shift
echo (4) All of the above (separate files)
echo (5) Custom speed shift
echo.
SET /P t_input="Select transformation option (1-5): "
IF "%t_input%" == "1" (
SET transformation="highpass=f=%highpass%,lowpass=f=%lowpass%,asetrate=%samplerate%*(1+%vpr_p%*0.01),aresample=%samplerate%"
SET prefix=Vaporwaved
SET export_folder="%output_folder%"
SET conversion=process
goto ext_list
) ELSE IF "%t_input%" == "2" (
SET transformation="asetrate=%samplerate%*(1+%upsp_p%*0.01),aresample=%samplerate%"
SET prefix=Upspeed +%upsp_p%%%
SET export_folder="%output_folder%"
SET conversion=process
goto ext_list
) ELSE IF "%t_input%" == "3" (
SET transformation="asetrate=%samplerate%*(1+%dwnsp_p%*0.01),aresample=%samplerate%"
SET prefix=Downspeed %dwnsp_p%%%
SET export_folder="%output_folder%"
SET conversion=process
goto ext_list
) ELSE IF "%t_input%" == "4" (
SET export_folder="%output_folder%\All"
SET conversion=process1
goto ext_list
) ELSE IF "%t_input%" == "5" (
goto custom_speed
) ELSE (
echo.
echo Error: Invalid input
goto processing_options)

:custom_speed
echo.
echo -------------------------------------------------------
echo Note: Percentage is based on shift from original speed,
echo       In order to play the file at 80%% speed,          
echo       "-20" would be the correct input.                
echo -------------------------------------------------------
echo.
SET /P percent="Enter a custom speed shift (in %%): "
IF %percent% GTR 0 SET prefix=Upspeed %percent%%%
IF %percent% LSS 0 SET prefix=Downspeed %percent%%%
SET transformation="asetrate=%samplerate%*(1+%percent%*0.01),aresample=%samplerate%"
SET export_folder="%output_folder%\Speed-shifted\Custom"
SET conversion=process
goto ext_list

:ext_list
IF NOT EXIST %export_folder% mkdir %export_folder%
IF "%t_input%" == "4" (
IF NOT EXIST %export_folder%\Vaporwaved mkdir %export_folder%\Vaporwaved
IF NOT EXIST %export_folder%\Upspeed mkdir %export_folder%\Upspeed
IF NOT EXIST %export_folder%\Downspeed mkdir %export_folder%\Downspeed
)

:bitrate_options
IF "%ext%" == "mp3" (
SET bitrate_opt=-b:a %bitrate%k
) ELSE IF "%ext%" == "m4a" (
SET bitrate_opt=-aq %audioquality%
) ELSE IF "%ext%" == "flac" (
SET bitrate_opt=
)

:conv
FOR /F "tokens=*" %%G IN ('dir /b input\*.%ext%') DO %ffmpeg% -i "input\%%G" -ar %samplerate% %bitrate_opt% "%%G" && move "input\%%G" original && goto %conversion%

:process
echo.
echo -------------------------------------------
echo Processing '%prefix%' audio filter...
echo -------------------------------------------
FOR /F "tokens=*" %%G IN ('dir /b *.%ext%') DO %ffmpeg% -loglevel %loglevel% -i "%%G" -map_metadata -1 -filter:a %transformation% -y -vn %bitrate_opt% "%%~nG (%prefix%).%ext%" && DEL /F "%%G" && move "%%~nG (%prefix%).%ext%" %export_folder% && goto navigate

:process1
echo.
echo ---------------------------------------
echo Processing 'Vaporwaved' audio filter...
echo ---------------------------------------
FOR /F "tokens=*" %%G IN ('dir /b *.%ext%') DO %ffmpeg% -loglevel %loglevel% -i "%%G" -map_metadata -1 -filter:a "highpass=f=%highpass%,lowpass=f=%lowpass%,asetrate=%samplerate%*(1+%vpr_p%*0.01),aresample=%samplerate%" -y -vn %bitrate_opt% "%%~nG (Vaporwaved).%ext%" && move "%%~nG (Vaporwaved).%ext%" %export_folder%\Vaporwaved && goto process2

:process2
echo.
echo -------------------------------------------
echo Processing 'Upspeed +%upsp_p%%%' audio filter...
echo -------------------------------------------
FOR /F "tokens=*" %%G IN ('dir /b *.%ext%') DO %ffmpeg% -loglevel %loglevel% -i "%%G" -map_metadata -1 -filter:a "asetrate=%samplerate%*(1+%upsp_p%*0.01),aresample=%samplerate%" -y -vn %bitrate_opt% "%%~nG (Upspeed +%upsp_p%%%).%ext%" && move "%%~nG (Upspeed +%upsp_p%%%).%ext%" %export_folder%\Upspeed && goto process3

:process3
echo.
echo ------------------------------------------
echo Processing 'Downspeed %dwnsp_p%%%' audio filter...
echo ------------------------------------------
FOR /F "tokens=*" %%G IN ('dir /b *.%ext%') DO %ffmpeg% -loglevel %loglevel% -i "%%G" -map_metadata -1 -filter:a "asetrate=%samplerate%*(1+%dwnsp_p%*0.01),aresample=%samplerate%" -y -vn %bitrate_opt% "%%~nG (Downspeed %dwnsp_p%%%).%ext%" && move "%%~nG (Downspeed %dwnsp_p%%%).%ext%" %export_folder%\Downspeed && DEL /F "%%G" && goto navigate

:navigate
IF NOT EXIST input\*.%ext% start "" "%cd%\%export_folder%" && exit
goto conv