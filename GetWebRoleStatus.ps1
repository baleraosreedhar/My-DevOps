		                          $serviceName = $webRoleDataInfo.ServiceName
															
															 #Write-Warning(" Service Name is {0} and  the web role name is {1}" -f $serviceName, $webRoleName)
														
																	$webRoleInstanceData=    Get-AzureRole -ServiceName $serviceName -Slot Production -InstanceDetails  -ErrorVariable a -ErrorAction silentlycontinue																
																	
																		   foreach($roleInstance in $webRoleInstanceData)
																		   {
    																				$ipAddressKey 	=	$serviceName
    																				$ipAddressValue	=	$roleInstance.IPAddress
    																				$roleName 		= 	$roleInstance.RoleName
    																				$instanceName	=	$roleInstance.InstanceName
    																				$instanceStatus = 	$roleInstance.InstanceStatus
    																				$ipAddress 		=	$roleInstance.IPAddress
    																				$instanceSize 	= 	$roleInstance.InstanceSize
    																				
    																				Write-Warning(" WebRole instance Data is    Role Name {0} InstanceName {1} status is {2} IP Address {3}" -f $($roleInstance.RoleName),$($roleInstance.InstanceName),$($roleInstance.InstanceStatus),$($roleInstance.IPAddress))
																				}
