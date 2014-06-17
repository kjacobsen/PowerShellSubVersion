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


#get the directory where we are starting from, as this script needs to change the directory, we want to be polite
$start = (Get-Location).path

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

#change to the working directory
cd $workingcopy

$svncommand = "svn merge --dry-run -r BASE:HEAD . --non-interactive"

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


$drymerge = Invoke-Expression $svncommand

if ($LASTEXITCODE -eq 0)
{	
	#the merge command will return nothing if it has no changes/actions to merge, hence we wouldn't need to do an update
	if ($drymerge -eq $null)
	{
		#there is no reason to perform an update
		Write-Verbose "No Updates were performed as there were no changes"
	} else {
		#we have some output from the merge command, so	we need to continue"
		Write-Verbose "Processing Merge output..."
		
		#is there any conflicts?
		$conflictdetected = $false
		
		#check each line to see if it is highlighting a conflict, these start with C in the merge output
		foreach ($line in $drymerge)
		{
			Write-Verbose $line
			if ($line[0] -eq "C")
			{
				Write-Verbose "Conflict Detected!"
				$conflictdetected = $true
			}
		}
		
		if ($conflictdetected)
		{
			#go back to where we started just to be polite!
			cd $start
			Throw "Conflicts were detected, ples resolve conflicts before running this command again"
		}
		else
		{
			#lets perform an SVN UPDATE!
			Write-Verbose "Updating from SVN"
			
			$svncommand = "svn update --username $username --password $password --non-interactive"

			if ($trustCertificates)
			{
				$svncommand = $svncommand + " --trust-server-cert"
			}
			
			$svncommand = $svncommand + " . 2>&1"
			
			$svnupdate = Invoke-Expression $svncommand
			
			if ($LASTEXITCODE -eq 0)
			{	
				throw "An error occured running SVN Update command $svncommand"
			}
		}
	}
} else {
	#go back to where we started just to be polite!
	cd $start
	#SVN ran successfully but had some sort of graceful error code
	throw "A error occured with svn diff, The command ran was: $svncommand in directory: $workingcopy, output was $drymerge"

}

#go back to where we started just to be polite!
cd $start

}
