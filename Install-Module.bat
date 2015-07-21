SET modulespath="%homedrive%%homepath%\Documents\WindowsPowerShell\Modules\Run-Tests"
rd /s /q %modulespath%
md %modulespath%
copy *.ps?1 %modulespath%