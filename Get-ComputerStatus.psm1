#Script name: Get-ComputerStatus.psm1
#Author: Ethan J. Jennings
#Date: 12-10-2020
#Email: ejjennings@madisoncollege.edu

#Script purpose:  The prupose of this module is to be used as an information gathering tool for Windows servers on the network.
#Once imported and given a computername via a mandatory parameter or objects passed in via the pipeline, this module will iterate through each computer name and retireve the information
#A warning will be given if the computer cannot be connected to.  The resulting information will be outputted in object format and can be used in the pipeline after that.

#Declare a function
function Get-ComputerStatus { 
    #Signifies an advanced function
    [CmdletBinding()]
    #Parameter section
    Param(
    #Make the parameter mandatory and allow input from the pipeline
    [Parameter(Mandatory=$True,
                ValueFromPipelineByPropertyName=$True,
                ValueFromPipeline=$True)]
    #Assign to variable
    [string[]]$computername
    )

    Write-Verbose "Gathered input from commandline.  Value: $computername"

    #Begin the foreach loop to iterate through the computer(s) given
    ForEach ($computer in $computername) {
        Write-Verbose "Beginning ForEach for computer $computer"
        
        #start a try block to watch for errors
        try {
            #Create a session to the desired computer
            #Use -ErrorAction to stop the script completly if an exception occurs on the connection, so only custom exceptions are shown.
            Write-Verbose "Creating Session"
            $session = New-PSSession -ComputerName $computer -ErrorAction Stop

            #Get OS information and assign it to a variable
            Write-Verbose "Gathering OS information"
            $osinfo = Invoke-Command -session $session -command {Get-CimInstance -ClassName Win32_OperatingSystem | Select Name, BuildNumber, Version}

            #Get processor information and assign it to a variable
            Write-Verbose "Gathering Processor information"
            $procinfo = Invoke-Command -session $session -command {Get-CimInstance -ClassName Win32_Processor | Select Name}

            #Get IP information and assign it to a variable
            Write-Verbose "Gathering IP Address information"
            $ipinfo = Invoke-Command -session $session -command {Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration | select IPAddress, DHCPEnabled | where IPAddress}

            #Get information on the DNS configuration and assign it to a variable
            Write-Verbose "Gathering DNS information"
            $dnsinfo = Invoke-Command -session $session -command {Get-DnsClientServerAddress -InterfaceAlias "Ethernet0" | where ServerAddresses  | select ServerAddresses}

            #Get information on the memory, convert it into GB, and assign it to a variable
            Write-Verbose "Gathering information on memory, converting it to GB"
            $meminfo = Invoke-Command -session $session -command {Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object @{l='MemoryGB' ;e={$_.TotalPhysicalMemory/1000000000}}}

            #Get information on the freediskspace, convert it to GB, and assign it to a variable
            Write-Verbose "Gathering disk information, converting it to GB"
            $diskinfo = Invoke-Command -computer Server1 -command {Get-CimInstance -ClassName Win32_LogicalDisk | where DeviceID -eq C: | Select-Object @{l='FreeSpaceGB' ;e={$_.FreeSpace/1000000000}}}
            
            #Get the last boot up time ans assign it to a variable
            Write-Verbose "Gathering information on system boot"
            $bootinfo = Invoke-Command -session $session -command {Get-CimInstance -ClassName Win32_OperatingSystem | select LastBootUpTime}

            #End the session created earlier
            Write-Verbose "Ending and removing remote PowerShell Session"
            $session | Remove-PSSession

            #Organize the gathered information into a proper format for object output
            Write-Verbose "Assembling information for output"
            $props = @{'ComputerName'=$computer
                   'RemoteIPAddress'=$ipinfo.IPAddress
                   'RemoteUsesDHCP'=$ipinfo.DHCPEnabled
                   'RemoteDNSClientServerAddress'=$dnsinfo.ServerAddresses
                   'RemoteOSName'=$osinfo.Name
                   'RemoteOSBuildNumber'=$osinfo.BuildNumber
                   'RemoteOSVersion'=$osinfo.Version
                   'RemoteMemoryinGB'=$meminfo.MemoryGB
                   'RemoteProcessorName'=$procinfo.Name[0]
                   'RemoteFreeSpace'=$diskinfo.FreeSpaceGB
                   'RemoteLastReboot'=$bootinfo.LastBootUpTime
            } #end of $props formatting

            #Create the Object ot output with the specified information
            Write-Verbose "Creating a new object for output"
            $obj = New-Object -TypeName PSObject -Property $props
            #Output the object
            Write-Verbose "Outputting object"
            Write-Output $obj

            } #end of try

            #Cath block for code to execte if a exception occurs
            catch{
                Write-Warning "Unable to connect to $computer.  Please check the computer name."
            } #end of catch
        Write-Verbose "End of ForEach loop"
    } #end of foreach
    Write-Verbose "End of script"
} #end of function
#End of script
