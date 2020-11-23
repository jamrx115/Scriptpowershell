#Subir ficheros al servidor FTP
#especificamos el directoro donde se encuentran los archivos
$Dir="C:/bk_bd"   

#dirección del ftp donde se subiran los archivos
$ftp = "ftp://alltic.co/" 
$user = "sql@alltic.co" 
$pass = "@lltic2018" 

$webclient = New-Object System.Net.WebClient



$webclient.Credentials = New-Object System.Net.NetworkCredential($user,$pass) 

	
foreach($item in (dir $Dir "*.BAK"))
{
	"Uploading $item..."
	$uri = New-Object System.Uri($ftp+$item.Name)
	$webclient.UploadFile($uri, $item.FullName) 	
 }

 Remove-Item C:\bk_bd\*.*