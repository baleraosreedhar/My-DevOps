
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
	$RunbookName					=  	"RunbookName"
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
    

$jobs =Get-SmaJob -WebServiceEndpoint $SMA_URI -AuthenticationType Basic -Credential $myCred -Port $SMA_PORT -RunbookName $RunbookName 
Write-Host $jobs

Foreach($job in $jobs)
{

Write-Host " Job Status is $($job.JobStatus)"
    if($job.JobStatus -NE 'Completed' )
    {
        Stop-SmaJob -Id $job.JobId -WebServiceEndpoint $SMA_URI -AuthenticationType Basic -Credential $myCred -Port $SMA_PORT 
    }

}

}
