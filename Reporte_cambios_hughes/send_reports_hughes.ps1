$Logfile= "LogCarga.log"
$date =  Get-Date -Format "MM/dd/yyyy HH:mm:ss"
$date_name =  Get-Date -Format "MM-dd-yyyy-HHmmss"
# Funcion para conectarce a una instancia de sql server

function ConnectToDB {
    # Define parametros
    param(
        [string]
        $servername,

        [string]
        $database,

        [string]
        $sqluser,

        [string]
        $sqlpassword
    )

    # crea la conexion y la guarda en una variable global
    $global:Connection = New-Object System.Data.SQLClient.SQLConnection
    $Connection.ConnectionString = "server='$servername';database='$database';trusted_connection=false; user id = '$sqluser'; Password = '$sqlpassword'; integrated security='False'"
    $Connection.Open()

    $MsgCarga= $date + " Conexion BD establecida"
    Add-Content D:\Reporte_cambios_hughes\LogCarga.log  $MsgCarga
}

# Fuuncion para ejecutar los comandos sql

function ExecuteSqlQuery {
    # Define Parametros
    param(
     
        [string]
        $sqlquery
    
    )
    
    Begin {
        If (!$Connection) {
            Throw "No connection to the database detected. Run command ConnectToDB first."
            $MsgCarga= $date + " No connection to the database detected. Run command ConnectToDB first."
            Add-Content D:\Reporte_cambios_hughes\LogCarga.log  $MsgCarga
        }
        elseif ($Connection.State -eq 'Closed') {
            
            $MsgCarga= $date + " Connection to the database is closed. Re-opening connection..."
            Add-Content D:\Reporte_cambios_hughes\LogCarga.log  $MsgCarga
            try {
                
                $Connection.Open()
            }
            catch {
               
                $MsgCarga= $date + " Error re-opening connection. Removing connection variable."
                Add-Content D:\Reporte_cambios_hughes\LogCarga.log  $MsgCarga
                Remove-Variable -Scope Global -Name Connection
                throw "Unable to re-open connection to the database. Please reconnect using the ConnectToDB commandlet. Error is $($_.exception)."
            }
        }
    }
    
    Process {
        
        $command = $Connection.CreateCommand()
        $command.CommandText = $sqlquery
    
        
         $MsgCarga= $date + " Running SQL query"
         Add-Content D:\Reporte_cambios_hughes\LogCarga.log  $MsgCarga
        try {
            $result = $command.ExecuteReader()      
        }
        catch {
            $Connection.Close()
        }
        $Datatable = New-Object "System.Data.Datatable"
        $Datatable.Load($result)
        return $Datatable          
    }
    End {
        
        $MsgCarga= $date + " Finished running SQL query."
         Add-Content D:\Reporte_cambios_hughes\LogCarga.log  $MsgCarga
    }
}

# Genera el archivo en fromato csv

$delimiter = ";"
ConnectToDB -servername '18.216.179.61' -database 'alltic' -sqluser 'sa' -sqlpassword '@lltic2017'
ExecuteSqlQuery -sqlquery 'select * from RESULTADOS_ESTADOS_PARA_REPORTS_HUGHES_FTP where id=''i-009314''' | export-csv -Delimiter $delimiter -Path "D:\Reporte_cambios_hughes\Creados\reports.csv" -NoTypeInformation         # use Format-Table for pretier listing
$MsgCarga= $date + " Genera Archivo"
Add-Content D:\Reporte_cambios_hughes\LogCarga.log  $MsgCarga

# ejecuta la conexion sftp y carga el archivo.

# Carga WinSCP .NET assembly
Add-Type -Path "D:\Reporte_cambios_hughes\WinSCP\WinSCP-5.15.9-Automation\WinSCPnet.dll"

# Inicia opciones de session
$sessionOptions = New-Object WinSCP.SessionOptions -Property @{
    Protocol = [WinSCP.Protocol]::Sftp
    HostName = "66.82.22.233"
    UserName = "alltic"
    Password = "Allt1cus3r!"
    SshHostKeyFingerprint = "ssh-ed25519 256 n7tbACbTQK67LeadiKD912mq7cTMLY0N0uh2I/UTMVA="
}

$sessionOptions.AddRawSettings("ProxyPort", "0")

$session = New-Object WinSCP.Session

try
{
    # Conexion
    $session.Open($sessionOptions)
    # Carga archivo 
    $session.PutFiles("D:\Reporte_cambios_hughes\Creados\reports.csv", "/home/").Check()
    
    
    
}
catch 
{
    $MsgCarga= $date + "Error en la carga"
   
    Add-Content D:\Reporte_cambios_hughes\LogCarga.log  $MsgCarga
}
finally
{
    $MsgCarga= $date +" "+ $session.Output
    $nombre= "reporte_"+$date_name+".csv"
    
    $session.Dispose()
    Add-Content D:\Reporte_cambios_hughes\LogCarga.log  $MsgCarga
    Copy-Item -Path D:\Reporte_cambios_hughes\Creados\reports.csv -Destination D:\Reporte_cambios_hughes\Cargados\$nombre
    $MsgCarga2= $date +" Pasa archivo a carpeta Cargados"
    Add-Content D:\Reporte_cambios_hughes\LogCarga.log  $MsgCarga2
    Remove-Item  D:\Reporte_cambios_hughes\Creados\*.*
    $MsgCarga3= $date +" Elimina archivo de carpeta Creados"
    Add-Content D:\Reporte_cambios_hughes\LogCarga.log  $MsgCarga3
}


