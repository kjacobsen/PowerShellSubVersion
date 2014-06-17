function 
{
<#
.SYNOPSIS

.DESCRIPTION

.PARAMETER 

.INPUTS
Nothing can be piped directly into this function

.OUTPUTS
Output will be an object representing the ini file.

.EXAMPLE

.NOTES
NAME: 
AUTHOR: 
LASTEDIT: 
KEYWORDS:

.LINK 

#>

[CMDLetBinding()]
param(
    #<application specific params>
    [Parameter(Mandatory=$true)][string]$workingcopy,
    [Alias("C")][switch]$commit,
    [Alias("D")][switch]$deletemissing,
    [Alias("A")][switch]$addnew,
    [Alias("M")][string]$message = "Another Update by some PowerShell User",
    [string]$username,
	[string]$password=,
	[Switch]$trustCertificates
)

#test to see if svn is installed and available
if ((Get-Command "svn.exe" -ErrorAction silentlycontinue) -eq $null)
{
	#SVN command not found
	throw "Could not find svn.exe"
}

#test to see  if the working copy is valid.
if ((Test-Path $workingcopy) -ne $true)
{
	throw "The path to the working copy $workingcopy doesn't exist"
}

Write-Verbose "Getting an SVN status for the working copy"

$svncommand = "svn status --non-interactive"
if ($username)
{
	if ($password)
	{
		$svncommand = $svncommand + " --username $username --password $password"
	}
	else
	{
		throw "Username but no password specified"
	}
}
if ($trustCertificates)
{
	$svncommand = $svncommand + " --trust-server-cert"
}
$svncommand = $svncommand + " $workingcopy 2>&1"

$svnresult = Invoke-Expression $svncommand

if ($LASTEXITCODE -eq 0)
{	
	if ($svnresult -ne $null)
	{
		Write-Verbose "There is work to be done."
			
		#add unversioned files
		if ($addnew)
		{
			Write-Verbose "Performing Add (A) action"
			$notversioned = $null
			$notversioned = $svnresult | Where-Object {$_.startswith("?")}
			#if the notversioned returned nothing, ie null, then there are no unversioned files
			if ($notversioned -ne $null)
			{
				Write-Verbose "We have files to add"
				foreach ($file in $notversioned)
				{
					#remove the ? and white space from the file name
					$filename = $file.remove(0,1).trim()
					#add the file name
					$svncommand = "svn add --username $username --password $password --non-interactive"
					if ($trustCertificates)
					{
						$svncommand = $svncommand + " --trust-server-cert"
					}
					$svncommand = $svncommand + " $filename 2>&1"
										
					$svnaddresult = Invoke-Expression $svncommand
					
					if ($LASTEXITCODE -eq 0)
					{
						Write-Verbose "add $filename was successfull"
					}
					else
					{
						Write-Verbose "add $filename failed, error: $svnaddresult"
					}
				}
			} else {	
				Write-Verbose "no unversioned files to add"
			}
		}
		
		#delete missing files
		if ($deletemissing)
		{
			Write-Verbose "Performing Delete (D) action"
			$missing = $null
			$missing = $svnresult | Where-Object {$_.startswith("!")}
			if ($missing -ne $null)
			{
				Write-Verbose "we have files to remove"
				foreach ($file in $missing)
				{
					#remove the ! and white space from the file name
					$filename = $file.remove(0,1).trim()

					$svncommand = "svn remove --username $username --password $password --non-interactive"
					if ($trustCertificates)
					{
						$svncommand = $svncommand + " --trust-server-cert"
					}
					$svncommand = $svncommand + " $filename 2>&1"
										
					$svnremresult = Invoke-Expression $svncommand	
					
					if ($LASTEXITCODE -eq 0)
					{
						Write-Verbose "remove $filename was successful"
					}
					else
					{
						Write-Verbose "remove $filename failed, error: $svnremresult"
					}
				}
			} else {	
				Write-Verbose "no missing files to delete"
			}
		}
		
		#commit changes
		if ($commit)
		{
			Write-Verbose "Performing Commit (C) action"
		
			$svncommand = "svn commit --username $username --password $password --non-interactive"
			if ($trustCertificates)
			{
				$svncommand = $svncommand + " --trust-server-cert"
			}
			$svncommand = $svncommand + " -m $message $workingcopy 2>&1"
			$svncomresult = Invoke-Expression $svncommand	
						
			if ($LASTEXITCODE -eq 0)
			{
				Write-Verbose "commit successful"
			}
			else
			{
				Write-Verbose "commit unsuccessful, error: $svncomresult"
			}
		}
	}
	else
	{
		Write-Verbose  "nothing to do as there are no changes to commit or items to add or remove"
	}
}
else
{
	Write-Verbose "A error occured with svn status, The command ran was: $svncommand, output was: $svnresult`n" 
}
