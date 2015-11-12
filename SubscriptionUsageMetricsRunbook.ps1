workflow New-SubscriptionUsageMetricsRunbook
{
  
      $Subscription=   Get-AutomationVariable -Name "CollectionOfAllSubscriptionsUsedForProvisioning"
      $StorageAccountName=   Get-AutomationVariable -Name "SubscriptionUsageBlobStorageAccountName"
      $StorageAccountKey=   Get-AutomationVariable -Name "SubscriptionUsageBlobStorageAccountkey"
      $StorageContainer=   Get-AutomationVariable -Name "SubscriptionUsageStorageContainer"
      $targetSubscriptionCrdential = Get-AutomationPSCredential  -Name "TargetSubscriptionCredential"
      
       # Authenticate to Azure
        Add-AzureAccount -Credential $targetSubscriptionCrdential 
        Write-Warning(" Azure account is " )
        Write-Warning(Get-AzureAccount)
 inlinescript{
     
      $Subscription=   $using:Subscription
      $StorageAccountName=   $using:StorageAccountName
      $StorageAccountKey=   $using:StorageAccountKey
      $StorageContainer=   $using:StorageContainer
    
      
        Write-Warning(" Start >>  Usage report for  -Subscription {0} -StorageAccountName {1} -StorageAccountKey {2}" -f $Subscription, $StorageAccountName, $StorageAccountKey)
        $connection = @{"StorageAccountName" = "$StorageAccountName"; "StorageAccountKey" = "$StorageAccountKey"}
      
        $Granularity = "Daily" # Can be Hourly or Daily
        $StartDate=Get-Date (Get-Date).AddDays(-7).ToString("MM/dd/yyyy") 
        $EndDate =Get-Date -Format MM/dd/yyyy 
               
        # collection object holding the subscription usage metrics data for all subscriptionss
        $SubscriptionUsageCollection = @()
        
         # collection object holding the subscription usage metrics data for all subscriptionss
        $SubscriptionUsageMonthlyCollection = @()
       
        # split the subscription collection from asset library, seperated by semicolon
       $subscriptionCollection=  $Subscription.Split(';')  

        $showDetails = $true
       
       
       
       # loop through all subscriptions and find the subscription usage data
       foreach($subscriptionId in $subscriptionCollection)          
       {        
        $showDetails = $true
        Set-AzureSubscription    -SubscriptionId $subscriptionId -CurrentStorageAccountName $StorageAccountName
        Select-AzureSubscription -SubscriptionId $subscriptionId

        Switch-AzureMode -Name AzureResourceManager
       
        # get the storage subscription data based on the UsageAggregates API
        $usageData = get-UsageAggregates -ReportedStartTime $StartDate -ReportedEndTime $EndDate -AggregationGranularity $granularity -ShowDetails:$showDetails 
        Write-Warning("fetching usage data for date range $StartDate - $EndDate count of records found $usageData.Count" )
        # date to be used for Suffixing the blob name
        $usageDate = Get-Date -Format "MM-dd-yyyy"
		Switch-AzureMode -Name AzureServiceManagement
        # File name of the JSON to be saving to local folder
        $fileName ="$usageDate.json"
        
        $fileName = "$($Env:Temp)\$($fileName)" 
        Write-Warning("Created temporary file name $fileName" )
  
       # Get the subscription usage data
        $result = $usageData.UsageAggregations.Properties | 
        Select-Object `
         @{n='UsageStartTime';e={$_.UsageStartTime.ToString("s")}},`
        @{n='UsageEndTime';e={$_.UsageEndTime.ToString("s")}},`
           @{n='SubscriptionId';e={$subscriptionId}}, `
            MeterCategory, `
            MeterId, `
            MeterName, `
            MeterSubCategory, `
            MeterRegion, `
            Unit, `
            Quantity, `
            InfoFields,`
            @{n='Project';e={$_.InfoFields.Project}}, `
            InstanceData 
            
            Write-Warning(" Added the subscription usage data to hash table collection for subscription Id {0}" -f $subscriptionId)
            # add the subscription data to hash table collection
            foreach ($appUsage in $result)
              {
                $SubscriptionUsageCollection +=$appUsage
              }
        }
      
      $SubscriptionUsageCollection|ConvertTo-Json |out-file $fileName      
      Write-Warning("Uploaded JSON to  temporary file name $fileName" )

                try{
                                                     
                        #Create the Context
                        $azureContext = New-AzureStorageContext $StorageAccountName -StorageAccountKey $StorageAccountKey
                           Write-Warning("Created azure context to upload blob for storage account $StorageAccountName" )                   

                            try
                            {
                             # Create a new container.
                                Write-Warning('Try create Container')
                                
                                # $StorageContainer ="$($StorageContainer)-01"
                             Write-Warning("Creating container for storage account $StorageAccountName  with container name $StorageContainer" )                   
                                
                                $newcontainer = New-AzureStorageContainer -Context $azureContext `
                                                                      -Container $StorageContainer `
                                                                      -Verbose `
                                                                      -WarningAction Ignore `
                                                                      -ErrorVariable $e `
                            }
                            catch
                            { 
                                Write-Warning('Container already exists $StorageContainer')
                            }
                       
                        $BlobName ="subscriptionusage-$usageDate"
                        Write-Warning("Creating blob $BlobName" )                   
                            
                        $blobProperties = @{"ContentType" = "application/json"};

                        # Upload a blob into a container.
                        Set-AzureStorageBlobContent -File $fileName -Container $StorageContainer  -Blob $BlobName -Properties $blobProperties -Context $azureContext -Force
                        Write-Warning("inserted the blob record into storage container $StorageContainer" )                    
                        
                        # cleanup file, remove the temp file created
                        if(Test-Path $fileName)
                        {
                             Write-Warning("Cleanup temporary created usage json file by deleting $fileName" )   
                             Remove-Item $fileName
                        }

                }                
                 
           catch{   
                if(Test-Path $fileName)
                {
					Remove-Item $fileName
                }
                  
                         write-Warning $_.Exception 
                        ## error handling code 
                        Write-Error -Message ("Unable to insert data into storage Table {0} with Storage Account...{1}...Exception {2}" -f $TableName,$StorageAccountName,$_.Exception.Message)     
                }
           
 } 
     
    }

