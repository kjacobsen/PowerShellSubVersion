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
    [string]$username,
	[string]$password,
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

#lets perform a diff command, run this against the HEAD version and the working copy.
$svncommand = "svn diff --non-interactive"
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
$svncommand = $svncommand + " 2>&1"

$svnresult = Invoke-Expression $svncommand

if ($LASTEXITCODE -eq 0)
{	
	#the merge command will return nothing if it has no changes/actions to merge, hence we wouldn't need to do an update
	if ($svnresult -eq $null)
	{
		#there is no reason to perform an update
		Write-Verbose "Nothing to do here, go home"
	} 
	else 
	{
		Write-Verbose "Changes made locally that we need to revert"
		Write-Verbose "Reverting..."
		$svncommand = "svn revert -R --username $username --password $password --non-interactive"
		if ($trustCertificates)
		{
			$svncommand = $svncommand + " --trust-server-cert"
		}
		$svncommand = $svncommand + " $workingcopy 2>&1"
		
		$svnresult = Invoke-Expression $svncommand
		
		if ($LASTEXITCODE -eq 0)
		{
			#revert worked
			Write-Verbose "Files were sucessfully reverted to match repository"
		}
		else 
		{
			#revert failed
			#SVN ran successfully but had some sort of graceful error code
			throw "A error occured with svn diff, The command ran was:$svncommand, output was: $svnresult" 
		}	
	}
} 
else 
{
	#SVN ran successfully but had some sort of graceful error code
	throw "A error occured with svn diff, The command ran was: $svncommand, output was: $svnresult"
}

}
