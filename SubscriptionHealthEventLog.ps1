if(!$myCred){
        $myCred = Get-Credential 
    }

 #-Credential:$myCred; #if you remove -Credential it will prompt for Username/Password and non-Org Accounts can be used 
 
 #The Azure command shell startup turns Verbose output on so we are going to suppress it for a cleaner runtime experience 
$Global:VerbosePreference = 'SilentlyContinue'; 
 
#Switch from the Service Management API to the Resource Management API 
Switch-AzureMode AzureResourceManager; 


#Get a list of all the subscriptions and iterate the Azure.Health events for each 
#$AzureSubscriptions = Get-AzureSubscription; 
# subscription collection speperated  by ;
$azureSubscriptionCollection=' ' 

 # split the subscription collection from asset library, seperated by semicolon
 $subscriptions=  $azureSubscriptionCollection.Split(';')
			
$StartDate					=	Get-Date (Get-Date).AddDays(-5).ToString("MM/dd/yyyy") 
$EndDate 					=	Get-Date(Get-Date).ToString("MM/dd/yyyy HH:mm:ss")
        	  
foreach ($AzureSubscription in $subscriptions) { 
     Clear-AzureProfile -Force
    #add the account to the local account manager 
    Add-AzureAccount -Credential $myCred

    #Get some metadata about the subscription we are currently working with 
    $msg = '> Currently enumerating Azure Service Health events for the subscription named {0}.' -f $AzureSubscription; 
    Write-Host $msg -ForegroundColor magenta; 
                 
    #Let's just make sure the currently selected subscription is the one we expect to be working with 
    Select-AzureSubscription -SubscriptionId $AzureSubscription -Current $True
                 
    #Query for the specific Resource Provider log data for the given time frame 
    $AzureHealthEvents = Get-AzureResourceProviderLog -ResourceProvider 'Azure.Health' -StartTime:$StartTime -EndTime:$EndTime -DetailedOutput
    #$AzureHealthEvents = Get-AzureResourceProviderLog -ResourceProvider:'Microsoft.ResourceHealth ' -StartTime:$StartTime -EndTime:$EndTime -DetailedOutput;
    
   $SubscriptionHealthCheckData = @()  
                           Write-Warning(" Subscription Id is $AzureSubscription")
					  if ($AzureHealthEvents) 
					  {
						   #We apparently have some health events returned so let's begin processing them 
							foreach ($AzureHealthEvent in $AzureHealthEvents) 
							{ 
								#Create New PS object holding the Diagnostic information for each azure health event
								$AzureSubscriptionHealthCheckEvent = New-Object PSObject 
								$AzureSubscriptionHealthCheckEvent | add-member Noteproperty Status    	        $AzureHealthEvent.Status.ToString()
								$AzureSubscriptionHealthCheckEvent | add-member Noteproperty OperationName      $AzureHealthEvent.OperationName.ToString()                                   
								$AzureSubscriptionHealthCheckEvent | add-member Noteproperty EventTimestamp    	$AzureHealthEvent.EventTimeStamp            
								$AzureSubscriptionHealthCheckEvent | add-member Noteproperty Severity    	    $AzureHealthEvent.Level.ToString()
								
								$AzureSubscriptionHealthCheckEvent | add-member Noteproperty Description    	$AzureHealthEvent.Description.trim().ToString()
                                
                                $AzureSubscriptionHealthCheckEvent | add-member Noteproperty SubscriptionId    	$subscriptionId
												
								# Add the Diagnostic status object to collection for each individual instance of web role
							   $SubscriptionHealthCheckData+=$AzureSubscriptionHealthCheckEvent    
							}
					  }
					  else
					  {
                          Write-Warning(" No health check events found for subscription ID of $subscriptionId")
							$CurrentDate = get-date
							$ToEasternTimeZone=[System.TimeZoneInfo]::FindSystemTimeZoneById("Eastern Standard Time")
							$EasternTime=[System.TimeZoneInfo]::ConvertTimeFromUtc($CurrentDate.ToUniversalTime(), $ToEasternTimeZone)
						
								$AzureSubscriptionHealthCheckEventNoData = New-Object PSObject 
								$AzureSubscriptionHealthCheckEventNoData | add-member Noteproperty Status    	        ''
								$AzureSubscriptionHealthCheckEventNoData | add-member Noteproperty OperationName      	''
								$AzureSubscriptionHealthCheckEventNoData | add-member Noteproperty EventTimestamp    	$EasternTime
								$AzureSubscriptionHealthCheckEventNoData | add-member Noteproperty Severity    	    	''								
								$AzureSubscriptionHealthCheckEventNoData | add-member Noteproperty Description    		'No Events Found'
                                
								$AzureSubscriptionHealthCheckEventNoData | add-member Noteproperty SubscriptionId    	$subscriptionId
								# Add the Diagnostic status object to collection for each individual instance of web role
							   $SubscriptionHealthCheckData+=$AzureSubscriptionHealthCheckEventNoData    
						
					  }

Write-Host("*********************************************************")
Write-Host(" Health check for subscription $AzureSubscription")

$SubscriptionHealthCheckData |Sort-Object EventTimestamp -descending | 
					Select-Object Status, OperationName, EventTimestamp,Severity,Description,SubscriptionId| format-table -auto

Write-Host("*********************************************************")					
} 
