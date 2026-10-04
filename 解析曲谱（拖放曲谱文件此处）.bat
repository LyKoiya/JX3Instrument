@echo off

:: 检查是否拖放了文件
if "%~1"=="" (
    echo 请将文件拖放到此脚本上，而不是打开
    pause
    exit /b
)

:: 声明Lua解释器及脚本路径
set "INFILE=%~1"
set "NAMEPATH=%~dp1%~n1"
set "EXT=%~x1"
set "LUA_EXE=%~dp0bin\lua.exe"
set "LUA_SCRIPT=%~dp0src\instrument2csv.lua"

:: 验证Lua解释器是否存在
if not exist "%LUA_EXE%" (
    echo 错误：找不到Lua解释器（%LUA_EXE%）
    echo 请修改脚本中的 LUA_EXE 变量为您的Lua路径
    pause
    exit /b
)

:: 执行转换
if "%EXT%" == ".dat" (
    echo 解析曲谱：%INFILE%
    "%LUA_EXE%" "%LUA_SCRIPT%" "%INFILE%" "%NAMEPATH%.csv"
    echo 生成带公式的xlsx
    powershell -ExecutionPolicy Bypass -File "%~dp0src\csv2xlsx.ps1" "%NAMEPATH%.csv"
    del "%NAMEPATH%.csv"
) else if "%EXT%" == ".mid" (
    echo 解析MIDI：%INFILE%
    "%LUA_EXE%" "%~dp0src\midi2csv.lua" "%INFILE%" "%NAMEPATH%.csv"
    echo 生成带公式的xlsx
    powershell -ExecutionPolicy Bypass -File "%~dp0src\csv2xlsx.ps1" "%NAMEPATH%.csv"
    del "%NAMEPATH%.csv"
    echo 将表格转为曲谱：%INFILE%
    powershell -ExecutionPolicy Bypass -File "%~dp0src\xlsx2instrument.ps1" "%NAMEPATH%.xlsx"
) else if "%EXT%" == ".midi" (
    echo 解析MIDI：%INFILE%
    "%LUA_EXE%" "%~dp0src\midi2csv.lua" "%INFILE%" "%NAMEPATH%.csv"
    echo 生成带公式的xlsx
    powershell -ExecutionPolicy Bypass -File "%~dp0src\csv2xlsx.ps1" "%NAMEPATH%.csv"
    del "%NAMEPATH%.csv"
    echo 将表格转为曲谱：%INFILE%
    powershell -ExecutionPolicy Bypass -File "%~dp0src\xlsx2instrument.ps1" "%NAMEPATH%.xlsx"
) else (
    echo 将表格转为曲谱：%INFILE%
    powershell -ExecutionPolicy Bypass -File "%~dp0src\xlsx2instrument.ps1" "%INFILE%"
)

exit