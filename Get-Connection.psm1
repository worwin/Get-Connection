function Get-Connection {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$False,
            ValueFromPipeLine=$True,
            ValueFromPipelineByPropertyName=$True,
            HelpMessage="Enter the Computer Name")]
            [Alias('Hostname','cn')]
        [string[]]$ComputerName = $env:computername
    )

    BEGIN{}
    PROCESS {
        ForEach($computer in $ComputerName) {
            try {
                $session = New-CimSession -ComputerName $computer -ErrorAction Stop
                $NetTCPConnection = Get-NetTCPConnection -CimSession $session -AppliedSetting Internet

                ForEach ($connection in $NetTCPConnection) {
                    $process = get-process -pid $connection.OwningProcess
                    $properties = @{#Handles = $process.Handles
                        CPU = $process.CPU
                        ProcessName = $process.ProcessName
                        PID = $connection.OwningProcess
                        RemoteAddress = $connection.RemoteAddress
                        LocalAddress = $connection.LocalAddress
                        LocalPort = $connection.LocalPort
                        RemotePort = $connection.RemotePort
                        State = $connection.State
                        Session = $computer
                        Status = 'Connected'}
                    $obj = New-Object -TypeName PSObject -Property $properties
		            #$obj.psobject.typenames.insert(0,'Get.Connection.Object')
                    Write-Output $obj
                }
            } catch {
                ForEach($connection in $NetTCPConnection) {
                    Write-Verbose "Couldn't connect to $computer"
                    $properties = @{#Handles = $null
                        CPU = $null
                        ProcessName = $null
                        PID = $null
                        RemoteAddress = $null
                        LocalAddress = $null
                        LocalPort = $null
                        RemotePort = $null
                        State = $null
                        Session = $computer
                        Status = 'Disconnected'}
                    $obj = New-Object -TypeName PSObject -Property $properties
		            #$obj.psobject.typenames.insert(0,'Get.Connection.Object')
                    Write-Output $obj
                }          
            } finally {
            }
        
        }
    } 
    END{
    }
}

Export-ModuleMember -Function Get-Connection 