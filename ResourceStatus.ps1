#Import-Module "C:\Program Files (x86)\Microsoft SDKs\Azure\PowerShell\ServiceManagement\Azure\Azure.psd1"
#Import-Module "C:\Program Files (x86)\Microsoft SDKs\Azure\PowerShell\ResourceManager\AzureResourceManager\AzureResourceManager.psd1"
if(!$myCred){
        $myCred = Get-Credential 
    }

    #Switch from the Service Management API to the Resource Management API 
Switch-AzureMode AzureResourceManager

Select-AzureSubscription -SubscriptionId ''
#Get a list of resources

# get all Resource Groups

#$resourceGroups = Get-AzureResourceGroup 
$consolidatedLog =@()


Foreach($resourceGroup in $resourceGroups)
{
    $resources =  Get-AzureResource -ResourceGroupName $resourceGroup   -OutputObjectFormat New  

    foreach($resource in $resources)
    {
    $resourceDetails=  Get-AzureResource -Name $resource.Name -ResourceGroupName $resourceGroup  -OutputObjectFormat New |
							Select-Object Name, ResourceId, ResourceName, ResourceGroupName, ResourceType , Location,SubscriptionId

        $ResourceInfo = New-Object PSObject 
		$ResourceInfo | add-member Noteproperty ResourceName        $resourceDetails.ResourceName
		#$ResourceInfo | add-member Noteproperty ResourceId          $resourceLog.ResourceId
		$ResourceInfo | add-member Noteproperty ResourceGroupName   $resourceDetails.ResourceGroupName
		$ResourceInfo | add-member Noteproperty ResourceType        $resourceDetails.ResourceType
		$ResourceInfo | add-member Noteproperty Location            $resourceDetails.Location
		$ResourceInfo | add-member Noteproperty SubscriptionID      $resourceDetails.SubscriptionID
		$ResourceInfo | add-member Noteproperty ProvisioningState      ''
		$ResourceInfo | add-member Noteproperty VMStatus            ''
		$ResourceInfo | add-member Noteproperty VMInstanceViewPowerState  ''
		$ResourceInfo | add-member Noteproperty StorageStatus           ''
		$ResourceInfo | add-member Noteproperty StorageStatusOfPrimaryRegion  		''
        $ResourceInfo | add-member Noteproperty WebSiteState  		''
        $ResourceInfo | add-member Noteproperty WebSiteEnabled  		''

                               

        
		                    if($resourceDetails.ResourceType -eq 'Microsoft.ClassicCompute/VirtualMachines')
		                    {  
                                $resourceVirtualMachineDetails=  Get-AzureResource -Name $resource.Name -ResourceGroupName $resource.ResourceGroupName -resourceType 'Microsoft.ClassicCompute/VirtualMachines' -ExpandProperties -OutputObjectFormat New|
							    Select-Object Name, ResourceId, ResourceName, ResourceGroupName, ResourceType , Location,SubscriptionId,Properties

                                $resourceProperties =$resourceVirtualMachineDetails.Properties
                                 
                                if($resourceProperties)
                                {
                                  try
                                    {                                
							                          $ResourceInfo.ProvisioningState = $resourceProperties.item("provisioningState")
                                        $resourceVirtualMachineDetailsInstanceView = $resourceProperties.item("instanceView")                                  
			                            
                                        if($resourceVirtualMachineDetailsInstanceView)
      			                            {
      				                            $ResourceInfo.VMStatus = $resourceVirtualMachineDetailsInstanceView.item("status")					   
      				                            $ResourceInfo.VMInstanceViewPowerState = $resourceVirtualMachineDetailsInstanceView.item("powerState")
      			                            }
                                    }
                                    catch [System.Exception]
									                  {                                    
                                        # DO nothing as we do not have data in the hash table
                                    }                                    	
                                 }
					                    
		                    }
        
                            elseif($resource.ResourceType -eq 'microsoft.insights/alertrules')
		                    {
			                          $resourceAlertRulesDetail	=  Get-AzureResource -Name $resource.Name -ResourceGroupName $resource.ResourceGroupName -resourceType 'Microsoft.Insights/Alertrules' -OutputObjectFormat New|
							                                    Select-Object Name, ResourceId, ResourceName, ResourceGroupName, ResourceType , Location,SubscriptionId,Properties
                                $resourceProperties =$resourceAlertRulesDetail.Properties
                                 
                                if($resourceProperties)
                                { 
                                    try
                                    {                                
							                          $ResourceInfo.ProvisioningState = $resourceProperties.item("provisioningState")
                                    }
                                    catch [System.Exception]
									                  {                                    
                                        # DO nothing as we do not have data in the hash table
                                    }
                                }

		                    }
        
      
	                      elseif($resource.ResourceType -eq 'Microsoft.ClassicStorage/storageAccounts')
		                    {
                                $resourceStorageDetails=  Get-AzureResource -Name $resource.Name -ResourceGroupName $resource.ResourceGroupName -resourceType 'Microsoft.ClassicStorage/storageAccounts' -ExpandProperties -OutputObjectFormat New|
							                  Select-Object Name, ResourceId, ResourceName, ResourceGroupName, ResourceType , Location,SubscriptionId,StorageServiceProperties,Properties
                                
                                $resourceProperties =$resourceStorageDetails.Properties
					
					                try
                                {                                
							                         if($resourceProperties)
                                        {
                                             $ResourceInfo.StorageStatus = $resourceProperties.item("status")
                                            $ResourceInfo.StorageStatusOfPrimaryRegion = $resourceProperties.item("statusOfPrimaryRegion")
                                         }
                                    }
                                    catch [System.Exception]
								                  	{                                    
                                        # DO nothing as we do not have data in the hash table
                                    }                               
					                    
		                    }
		                    elseif($resource.ResourceType -eq 'Microsoft.Web/sites')
		                    {
					                  $resourceWebSitesDetails=  Get-AzureResource -Name $resource.Name -ResourceGroupName $resource.ResourceGroupName -resourceType 'Microsoft.Web/sites' -ExpandProperties -OutputObjectFormat New|
							              Select-Object Name, ResourceId, ResourceName, ResourceGroupName, ResourceType , Location,SubscriptionId,StorageServiceProperties,Properties
                                
                                $resourceProperties =$resourceWebSitesDetails.Properties
					                   try
                                    {     
                                            if($resourceProperties)
                                            {
                                                 $ResourceInfo.WebSiteState = $resourceProperties.item("state")
                                                $ResourceInfo.WebSiteEnabled = $resourceProperties.item("enabled")
                                             }
                                    }
                                    catch [System.Exception]
									                  {                                    
                                        # DO nothing as we do not have data in the hash table
                                    } 
                               
					                    
		                    }
		                    elseif($resource.ResourceType -eq 'Microsoft.Cache/Redis')
		                    {
					                    $resourceRedisDetails=  Get-AzureRedisCache -Name $resource.Name -ResourceGroupName $resource.ResourceGroupName 
                                       $ResourceInfo.ProvisioningState = $resourceRedisDetails.ProvisioningState
					
		                    }
                            elseif($resource.ResourceType -eq 'Microsoft.Insights/components')
		                    {
                                $resourceInsightComponentsDetails=  Get-AzureResource -Name $resource.Name -ResourceGroupName $resource.ResourceGroupName -resourceType 'Microsoft.Insights/components' -ExpandProperties -OutputObjectFormat New|
							    Select-Object Name, ResourceId, ResourceName, ResourceGroupName, ResourceType , Location,SubscriptionId,StorageServiceProperties,Properties
                                
                                $resourceProperties =$resourceWebSitesDetails.Properties
					             try
                                    {     if($resourceProperties)
                                            {
                                                 $ResourceInfo.WebSiteState = $resourceProperties.item("state")
                                                $ResourceInfo.WebSiteEnabled = $resourceProperties.item("enabled")
                                             }
                                    }
                                    catch [System.Exception]
									{                                    
                                        # DO nothing as we do not have data in the hash table
                                    } 
                            }
        
		$consolidatedLog += $ResourceInfo 
		
        
    }

}

Write-host(" Number of  objects found are $($consolidatedLog.Count)")
#Write the data to a CSV file
    $consolidatedLog | Export-csv "C:\temp\AzureResourceStatusLog_Updated.csv" -notypeinformation

