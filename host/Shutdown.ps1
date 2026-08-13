####################################################################################################
# Title       : Shutdown
# Version     : 1.0
# Author      : TBJr
# Description : Schedules a Windows shutdown after a 10-second delay
####################################################################################################

Write-Host 'Shutting down Windows...'
shutdown.exe /s /t 10
