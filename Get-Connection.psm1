<#
.Synopsis
    Gets the Network TCP Connections and their associated processes information.
.DESCRIPTION
    The Get-Connection cmdlet gets a list of all current TCP connections on the local computer or a remote computer. 

    Without parameters, this cmdlet gets all of the internet TCP connections on the local computer. 
    You can also specify whether all tcp connections are displayed or only the Internet connections by using the AppliedSetting parameter.
.EXAMPLE
    PS C:\>Get-Connection

    This command gets a list of all current TCP connections on the local computer.
.EXAMPLE
    PS C:\>Get-Connection -ComputerName 'DC1', 'DC2', 'EXCHANGE'

    This command gets a list of all current TCP connections on the listed computers. 
.EXAMPLE
    PS C:\>$computer = 'DC1', 'DC2', 'IIS', 'EXCHANGE', 'WorkStation02'
    PS C:\>$computer | Get-Connection

    Get-Connetions allows for the piping of a list of computer names to it. 
.EXAMPLE
    PS C:\>Get-Connection -ComputerName 'DC1', 'EXCHANGE' -AppliedSetting All

    This command gets all connections for the DC1 and EXCHANGE computers. 
.EXAMPLE
    PS C:\>$x = (Get-Connection).id
    PS C:\> Get-Process -Id $x

    This command takes all of the processes with an internet connection and passes them to Get-Process
    using their process Id. From here one can dive deeper into all Get-Process has to offer regarding 
    those processes. 
.EXAMPLE
    PS C:\>$x = (Get-Connection).id
    PS C:\>(Get-Process -Id $x)[0].modules

    Here we combine the above commands with this to list all of the modules that are being used with
    the given process at location 0 in the array we made above. 
.EXAMPLE
    PS C:\>$x = (Get-Connection).id
    PS C:\>(Get-Process -Id $x)[0]
#>
function Get-Connection {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$False,
            ValueFromPipeLine=$True,
            ValueFromPipelineByPropertyName=$True,
            HelpMessage="Enter the Computer Name")]
            [Alias('Hostname','cn')]
        [string[]]$ComputerName = $env:computername,

        [Parameter(Mandatory=$False)]
            [ValidateSet('All', 'Internet')]
        [System.String]$AppliedSetting
    )

    BEGIN{
    }
    PROCESS {
        ForEach($computer in $ComputerName) {
            try {
                $session = New-CimSession -ComputerName $computer -ErrorAction Stop
                
                if ($AppliedSetting -eq 'All') { <# Setting the TCP applied setting to Internet or leaving it to pull all connections. #>
                    $NetTCPConnection = Get-NetTCPConnection -CimSession $session 
                } elseif ($AppliedSetting -eq 'Internet') {
                    $NetTCPConnection = Get-NetTCPConnection -CimSession $session -AppliedSetting Internet
                } else {
                    $NetTCPConnection = Get-NetTCPConnection -CimSession $session -AppliedSetting Internet
                } <# Others that may need to be added in later; Datacenter, Compat, DatacenterCustom, InternetCustom #>

                ForEach ($connection in $NetTCPConnection) {
                    $process = get-process -pid $connection.OwningProcess
                    $properties = @{Handles = $process.Handles
                        CreationTime = $connection.CreationTime
                        CPU = $process.CPU
                        ProcessName = $process.ProcessName
                        ID = $connection.OwningProcess
                        LocalAddress = $connection.LocalAddress
                        LocalPort = $connection.LocalPort
                        RemoteAddress = $connection.RemoteAddress
                        RemotePort = $connection.RemotePort
                        State = $connection.State
                        Session = $computer
                        Status = 'Connected'
                    } 
                    $obj = New-Object -TypeName PSObject -Property $properties
                    if (($ComputerName | Measure-Object).count -ge 2) {
                        $obj.psobject.typenames.insert(0,'Get.Connection.Multiple.Computer.Object')
                    } elseif (($ComputerName | Measure-Object).count -eq 1) {
                        $obj.psobject.typenames.insert(0,'Get.Connection.Single.Computer.Object')
                    } else {
                        Write-output ("Error: Less than one computer. This shouldn't happen.")
                    }
                    write-output $obj 
                } # ForEach $connection
            } catch { # sessions that couldn't be connected to
                Write-Verbose "Couldn't connect to $computer"
                $properties = @{Handles = $null
                    CPU = $null
                    ProcessName = $null
                    ID = $null
                    LocalAddress = $null
                    LocalPort = $null
                    RemoteAddress = $null
                    RemotePort = $null
                    State = $null
                    Session = $computer
                    Status = 'Disconnected'
                }
                $obj = New-Object -TypeName PSObject -Property $properties
                if (($ComputerName | Measure-Object).count -ge 2) {
                    $obj.psobject.typenames.insert(0,'Get.Connection.Multiple.Computer.Object')
                } elseif (($ComputerName | Measure-Object).count -eq 1) {
                    $obj.psobject.typenames.insert(0,'Get.Connection.Single.Computer.Object')
                } else {
                    Write-output ("Error: Less than one computer. This shouldn't happen.")
                }
                write-output $obj  
            } finally {
            }
        }
    } 
    END {}
}

Export-ModuleMember -Function Get-Connection
Update-FormatData -AppendPath .\MyViews.format.ps1xml