#----------------------------------------------------------------
$vCenter1 = “VCENTER1.VCENTER.COM”
$vCenter2 = “VCENTER2.VCENTER.COM”
$Username = “domain\username”
$Password = convertto-securestring “password” -asplaintext -force #better to encrypt this.
$Creds = New-Object System.Management.Automation.PSCredential -ArgumentList $Username, $Password
$To = ‘EMAIL@EMAIL.COM’
$Cc = ‘OTHEREMAIL@EMAIL.COM”
$From = ‘EMAIL@EMAIL.COM’
$Subject = "VMware Guests with Snapshot(s)"
$MailServer = ‘SMTPSERVER.EMAIL.COM’
$30DaysAgo = (Get-Date).AddDays(-30)
$Date = Get-Date $30DaysAgo -Format "M/d/yyyy hh:mm:ss tt"
#----------------------------------------------------------------
#-----------------------------------------------------------------------
$CSS = @"
<style>
h1, h5, th, p { text-align: center; }
table { margin: auto; font-family: Segoe UI; box-shadow: 10px 10px 5px #888; border: 1px solid black; border-collapse: collapse; }
table tbody tr td table { box-shadow: 0px 0px 0px #888 }
table tbody tr td table tbody { width: aut; }
th { border: 1px solid black; background: #dddddd; color: #000000; max-width: 400px; padding: 5px 10px; }
td { border: 1px solid black; font-size: 11px; padding: 5px 20px; color: #000000; }
tr { background: #b8d1f3; }
tr:nth-child(even) { background: #fff000; }
tr:nth-child(odd) { background: #f9fbfe; }
</style>
"@
#-----------------------------------------------------------------------
#-----------------------------------------------------------------------
$body = @"
<h1>VM's with Snapshot(s)</h1>
<p>Please clean up old snapshots.</p>
"@
#-----------------------------------------------------------------------
Add-Type -AssemblyName System.Web
Import-Module VMware.PowerCLI
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false

Connect-VIServer -Server $vCenter1 -Credential $Creds
$VMSWithSnaps1 = get-vm | get-snapshot | Select-Object Created,VM,Name
$VMsToAlert1 = Foreach ($VM1 in $VMSWithSnaps1)
{
        $Name1 = $VM1.VM
        $Created1 = $VM1.Created
        $Reason1 = $VM1.Name
        If ($VM1.Created -gt $Date)
        {
            $OLD1 = "OKAY, to keep."
        }
        Else
        {
            $OLD1 = "OLDER THAN 30 DAYS! Please Remove!"
        }
    [PSCustomObject]@{
        VM = $Name1
        Created = $Created1
        Comment = $Reason1
        OLD = $OLD1
    }
}
Disconnect-VIServer -Server $vCenter1 -Confirm:$False -Force

Connect-VIServer -Server $vCenter2 -Credential $Creds
$VMSWithSnaps2 = get-vm | get-snapshot | Select-Object Created,VM,Name
$VMsToAlert2 = Foreach ($VM2 in $VMSWithSnaps2)
{
        $Name2 = $VM2.VM
        $Created2 = $VM2.Created
        $Reason2 = $VM2.Name 
        If ($VM2.Created -gt $Date)
        {
            $OLD2 = "OKAY, to keep."
        }
        Else
        {
            $OLD2 = "OLDER THAN 30 DAYS! Please Remove!"
        }
    [PSCustomObject]@{
        VM = $Name2
        Created = $Created2
        Comment = $Reason2
        OLD = $OLD2
    }
}
Disconnect-VIServer -Server $vCenter2 -Confirm:$False -Force

$VMsToAlert = $VMsToAlert1 + $VMsToAlert2

$HTML = $VMsToAlert | ConvertTo-Html -Head $CSS -Body $body | Foreach-Object {$PSItem -replace "<td style='background-color:#BDB76B;color:#FFF'>" -replace "<td>OKAY, to keep.</td>", "<td style='background-color:#008000;color:#FFF'>OKAY, to keep.</td>" -replace "<td>OLDER THAN 30 DAYS! Please Remove!</td>", "<td style='background-color:#FF0000;color:#FFF'>OLDER THAN 30 DAYS! Please Remove!</td>"}
$Body = [System.Web.HttpUtility]::HtmlDecode($HTML)


$message = new-object System.Net.Mail.MailMessage 
$message.From = $From
$message.To.Add($To)
$message.Cc.Add($Cc) 
$message.IsBodyHtml = $True 
$message.Subject = $Subject 
$message.body = $body 
$smtp = new-object Net.Mail.SmtpClient($MailServer) 
$smtp.Send($message)
