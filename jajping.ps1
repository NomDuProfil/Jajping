Param(  [Alias("IPRange")] 
        [string]$iprangge="Rien",
        [Alias("FilePath")] 
        [string]$fileepath="Rien")

function IP-toINT64($ip) { 
  $octets = $ip.split(".") 
  return [int64]([int64]$octets[0]*16777216 +[int64]$octets[1]*65536 +[int64]$octets[2]*256 +[int64]$octets[3]) 
} 
 
function INT64-toIP($int) { 
  return (([math]::truncate($int/16777216)).tostring()+"."+([math]::truncate(($int%16777216)/65536)).tostring()+"."+([math]::truncate(($int%65536)/256)).tostring()+"."+([math]::truncate($int%256)).tostring() )
}

function getStringRange($IPAdressCIDR) { 

    Write-Host $IPAdressCIDR" en cours..."

    if ($IPAdressCIDR -like "*/*") {
        $IPAdress = [Net.IPAddress]::Parse($IPAdressCIDR.Split('/')[0])
        $Mask = [convert]::ToInt32($IPAdressCIDR.Split("/")[1])
        if ($Mask -le 32 -and $Mask -ne 0) {
            $MaskAddress = [Net.IPAddress]::Parse((INT64-toIP(([convert]::ToInt64(("1"*$Mask+"0"*(32-$Mask)),2)))))
            $NetworkAddr = new-object net.ipaddress ($MaskAddress.address -band $IPAdress.address)
            $BroadcastAddr = new-object net.ipaddress (([system.net.ipaddress]::parse("255.255.255.255").address -bxor $MaskAddress.address -bor $NetworkAddr.address))
            $beginaddr = IP-toINT64($NetworkAddr.ipaddresstostring)
            $endaddr = IP-toINT64($BroadcastAddr.ipaddresstostring)
        }
        else {
            Write-Host "Mask invalid"
            Exit
        }
    }
    else {
        Write-Host "Invalide masque"
        Exit
    }

    $totalstring = ""
    for ($i = $beginaddr; $i -le $endaddr; $i++) 
    { 
      $ipcurrent = INT64-toIP($i)
      try {
        $pingresult = ping -n 1 -w 30 $ipcurrent | Select-String ttl | Out-String
        if ($pingresult) {
            if($pingresult -like "*from*")
            {
                Write-Host $pingresult.Replace("`n"," ").Split('from')[4].Split(':')[0].Replace('ÿ', '').Replace(' ', '')" up"
                if ($totalstring -eq "")
                {
                    $totalstring = $pingresult.Replace("`n"," ").Split('from')[4].Split(':')[0].Replace('ÿ', '').Replace(' ', '')
                }
                else
                {
                    $totalstring = $totalstring+', '+$pingresult.Replace("`n"," ").Split('from')[4].Split(':')[0].Replace('ÿ', '').Replace(' ', '')
                }
            }
            else
            {
                Write-Host $pingresult.Replace("`n"," ").Split('de')[3].Split(':')[0].Replace('ÿ', '').Replace(' ', '')
                if ($totalstring -eq "")
                {
                    $totalstring = $pingresult.Replace("`n"," ").Split('de')[3].Split(':')[0].Replace('ÿ', '').Replace(' ', '')
                }
                else
                {
                    $totalstring = $totalstring+', '+$pingresult.Replace("`n"," ").Split('de')[3].Split(':')[0].Replace('ÿ', '').Replace(' ', '')
                }
            }
        }
      }catch{
     }
    }
    return $totalstring
}

if (($iprangge -eq "Rien") -and ($fileepath -eq "Rien"))
{
    Write-Host "Usage : jajping.ps1 -FilePath PATH_TO_FILE"
    Write-Host "Usage : jajping.ps1 -IPRange 0.0.0.0/00"
    Exit
}

$finalstring = ""

if ($iprangge -ne "Rien") {
    $finalstring = getStringRange($iprangge)
}

elseif ($fileepath -ne "Rien") {
    foreach($line in Get-Content $fileepath) {
        $currentline = $line.Replace("`n","")
        if($finalstring -eq "") {
            $finalstring = getStringRange($currentline).Replace("`n","")
        }
        else {
            $tmpresult = getStringRange($currentline).Replace("`n","")
            $finalstring = $finalstring+', '+$tmpresult
        }
    }
}

Write-Host $finalstring.Replace("`n","")

$towrite = $finalstring.Replace("`n","")

$pathfile = $PSScriptRoot+"\result.txt"

$stream = [System.IO.StreamWriter] $pathfile
$stream.WriteLine($towrite)
$stream.Close()

Write-Host "Result in "$pathfile