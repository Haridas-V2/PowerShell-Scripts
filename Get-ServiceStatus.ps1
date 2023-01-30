<#
.SYNOPSIS
Check the status of service and start it if it's not running.
Update below Variables with correct values and run the script.
service_name, To, From, mail_relay, log_file, wait_time

.Description
Created by Haridas V2.
Date - 19-Jan-2022

.Example
Update below veriable values and run the script or schedule to run it periodically. 
service_name, To, From, mail_relay, log_file, wait_time

.\Get-ServiceStatus.ps1

#>
#====================== Update Veriables ======================#
#Update below Variables as per your environments.
$service_name = "WindowsServiceName"

#some service may take longer to start, adjust this time based on service startup time.
$wait_time = 120

$To = "Email.To@example.com"

$from = "Email.From@example.com"
$mail_realy = "relay.Example.com"

$log_file = "C:\windows\Temp\" + $service_name + "_ServiceStatus.log"
 
#====================== ====================== ======================#
#Set Functions
function LogIt {
    param (        
        [Parameter(Mandatory = $false)]
        [String]$logfile,
        [Parameter(Mandatory = $true)]
        [String]$message
    )
    
    if (!$logfile) { $logfile = $log_file }

    try {
        $logMsg = (Get-Date).ToString() + " - " + $service_name + " - " + $message
        Add-Content -Path $logfile -Value $logMsg 
    }
    catch {
        Write-Host "$($_.Exception.Message) - Failed to write Log" -ForegroundColor Red
    }
}

function Send-Email {
    param (
        [Parameter(Mandatory=$true)]
        [String]$mail_msg        
    )
    $body = "<h4>$mail_msg</h4>"
    $body += "<a>Thanks,<br>HaridasV2</a>"
     
    Send-MailMessage -From $from -To $To -Subject $mail_msg -Body $body -SmtpServer $mail_realy -BodyAsHtml
}
#====================== ====================== ======================#
function Get-ServiceStatus {
    param (        
        [Parameter(Mandatory = $true)]
        [String]$Service_Name
    )
    
    try {
        Write-Host "Getting service Status"
        Start-Sleep 5
        $service_info = Get-Service -Name $service_name

        if ( $service_info.Status -eq "Running" ) {
            $msg = "Info - $service_name - Service is already running"
            Write-Host $msg -ForegroundColor Green
            LogIt -message $msg
            #
            Send-Email -mail_msg $msg
        }
        else {
            #Run this if servie not running
            $msg = "Warning - $service_name - Service is NOT running"
            Write-Host $msg -ForegroundColor Red
            LogIt -message $msg
            Start-Sleep 10

            #Try to start the service
            $retry_count = 2
            $count = 0
            while ($count -le $retry_count) {
                $msg = "Info - $service_name - Starting Service..... " + $count
                Write-Host $msg -ForegroundColor Yellow
                LogIt -message $msg
                Start-Service $Service_Name
                
                Start-Sleep -Seconds $wait_time
                $service_info.Refresh()

                if ( $service_info.Status -eq "Running" ) {
                    $msg = "Info - $service_name - Service has been started"
                    Write-Host $msg -ForegroundColor Green
                    LogIt -message $msg
                    #
                    Send-Email -mail_msg $msg
                    Break
                }
                $count += 1
            }
            
            #send email if failed service to start.
            $service_info.Refresh()
            if ( $service_info.Status -ne "Running" ) {
                $msg = "Error - $service_name - Failed to Start Service"
                Write-Host " "
                Write-Host $msg -ForegroundColor Red
                LogIt -message $msg
                #
                Send-Email -mail_msg $msg                
            }
        }        
    }
    catch {
        $msg = "Error - $service_name - Failed to get Service. " + $_.Exception.Message
        LogIt -message $msg
        Write-Host "$($_.Exception.Message) - Failed to get service status, check service status or service name."
    }
}
#====================== ====================== ======================#
#Run the function
Get-ServiceStatus -Service_Name $service_name  
