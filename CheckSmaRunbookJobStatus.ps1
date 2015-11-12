Begin
{
    Write-Host("Start >> Scheduler Automation " )
    if(!$myCred){
        $myCred = Get-Credential 
    }
}

Process
{      


        $ManagementSubscription                =      ""
        $RunbookName                            =      ""
        # Automation Account Name in SMA 
        $AutomationAccountName ="automation"
         $SMA_URI =""
         $SMA_PORT=443
         

         # set the subscription
          Set-AzureSubscription    -SubscriptionId $ManagementSubscription 
          Select-AzureSubscription -SubscriptionId $ManagementSubscription
   
       
# include the runbook name to get the list of all jobs invoking the runbook
$jobs =Get-SmaJob -WebServiceEndpoint $SMA_URI -AuthenticationType Basic -Credential $myCred -Port $SMA_PORT #-RunbookName $RunbookName 
Write-Host $jobs
# filter the jobs status 
$QueuedJobs =$jobs | Where-Object {$_.JobStatus -eq 'Queued'}

$QueuedJobs | Format-Table -AutoSize

} 
