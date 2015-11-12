Begin
{
    Write-Host("Start >> Scheduler Automation " )
    if(!$myCred){
        $myCred = Get-Credential 
    }
}

Process
{		
    
    $ManagementSubscription			=  	""
	$RunbookName					=  	""
      # Automation Account Name in SMA 
      $AutomationAccountName ="automation"
	  $SMA_URI =""
	  $SMA_PORT=443
	  # SMA Job recurring interval in minutes
      [int]$RecurringInterval = 5
	  # SMA Schedule Prefix
      $ScheduleNamePrefix = "Prefix"

	  # set the subscription
	   Set-AzureSubscription    -SubscriptionId $ManagementSubscription 
	   Select-AzureSubscription -SubscriptionId $ManagementSubscription
   
        $iterations = 1440 / $RecurringInterval
        $endDate   = Get-Date -Month 12 -Day 31 -year 9999 -Hour 5 -Minute 00 -second 00
        $StartDateUTC = Get-Date -Hour 00 -Minute 00 -Second 00
        $StartDateEST = Get-Date -Hour 04 -Minute 00 -Second 00
        
         # to set the runbooks to start from next day
      [DateTime] $RunbookStartDate= $StartDateUTC.AddDays(1)
    
		# remove existing Schedules
		foreach ($iteration in 1..$iterations) {
            [DateTime]$minuteIntervalDateTime = $RunbookStartDate.AddMinutes(($iteration*$RecurringInterval))
            $dateString = $minuteIntervalDateTime.ToString("HH-mm")
            $Name = "$($ScheduleNamePrefix)_$($dateString)"
            Write-Host "Iteration is $iteration and Name is $Name"
			$r = Get-SmaSchedule –WebServiceEndpoint $SMA_URI `
                                                         –Port       $SMA_PORT `
                                                         -Name       $Name `
                                                         -Credential $myCred `
                                                         -AuthenticationType Basic `
                                                         -ErrorAction SilentlyContinue 
                                                         

                                    if ($r) 
                                    {
                                         Write-Host ("Found schedule...{0}...Removing schedule asset!" -f $Name, $AutomationAccountName) 
                                         Remove-SmaSchedule –WebServiceEndpoint $SMA_URI `
                                                            –Port               $SMA_PORT `
                                                            -Name               $Name `
                                                            -AuthenticationType Basic `
                                                            -Credential         $myCred -Force
                                    }
			
			}
		

			# creating new schedules
		foreach ($iteration in 1..$iterations) {
            [DateTime]$minuteIntervalDateTime = $RunbookStartDate.AddMinutes(($iteration*$RecurringInterval))

            # Adjust for UTC Time
            $utcStartTime=$minuteIntervalDateTime.AddHours(-4)

            $dateString = $minuteIntervalDateTime.ToString("HH-mm")
            $Name = "$($ScheduleNamePrefix)_$($dateString)"
            Write-Host "Iteration is $iteration and Name is $Name and UTC timestamp to start is $utcStartTime"
			# Set the SMA SCHEDULE
            Set-SmaSchedule –WebServiceEndpoint $SMA_URI `
                            –Port               $SMA_PORT `
                            -Name               $Name `
                            -Credential         $myCred `
                            -ScheduleType       'DailySchedule' `
                            -Description        "SMA Schedule for $Name" `
                            -StartTime          $utcStartTime `
                            -ExpiryTime         $endDate  `
                            -DayInterval        1 `
                            -AuthenticationType Basic


    
            #$StartDateEST = $StartDateEST.AddMinutes($interval)
            #$StartDateUTC = $StartDateUTC.AddMinutes($interval)
			}
			
			# start the schedule
			foreach ($iteration in 1..$iterations) {
            [DateTime]$minuteIntervalDateTime = $RunbookStartDate.AddMinutes(($iteration*$RecurringInterval))
            $dateString = $minuteIntervalDateTime.ToString("HH-mm")
            $Name = "$($ScheduleNamePrefix)_$($dateString)"
            Write-Host "Iteration is $iteration and Name is $Name"
        Start-SmaRunbook -Name $RunbookName `
                        -ScheduleName       $Name `
                        -WebServiceEndpoint $SMA_URI `
                        –Port               $SMA_PORT `
                        -Credential         $myCred `
                        -AuthenticationType Basic
           
            #$StartDateUTC = $StartDateUTC.AddMinutes($RecurringInterval)
        }     	
}
