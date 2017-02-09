/*

This is a sample of PowerShell craziness.
We used this as a form of CI (and on-demand integration) for a custom in-house dev environment.

The code was anonymized, so there may be discrepancies. This is for work product sharing only.

*/


#############################################################################################

$VS = "12.0";

$msbuild="C:\Windows\Microsoft.NET\Framework\v4.0.30319\msbuild.exe";
$tfs="C:\`"Program Files (x86)`"\`"Microsoft Visual Studio $VS`"\Common7\IDE\tf.exe";
#$ZIP_PATH="C:\`"Program Files (x86)`"\WinZip";
$zip="C:\`"Program Files`"\7-Zip\7z.exe";

$LOC_PATH="C:\Code\IntegrationServer";
$DEP_PATH="$LOC_PATH\BuildAndDeploy";


$SRC_SERVER_PATH="$LOC_PATH\Server";
$TAR_SERVER_PATH="$DEP_PATH\Server";

$SRC_AGENT_PATH="$LOC_PATH\Agents\Real";

$PROD_FTP= @( "{ip goes here}", "{username goes here}", "{password goes here}" );
$TEST_FTP= @( "{ip goes here}", "{username goes here}", "{password goes here}" );

$deleteZipFileAfterFTP     = $true;
$deleteBuildFolderAfterZip = $true;

$ScriptRoot = Split-Path $MyInvocation.MyCommand.Path
"$ScriptRoot\Build-Local.ps1"
#so you can see that your file will supercede the settings above
write-host $test;
#############################################################################################

$SERVER = "Server";
$AGENT_AD = "ActiveDirectoryAgent";
$AGENT_CRM = "SalesforceCRMAgent";
$AGENT_SOR = "SORAgent";
$AGENT_FS = "FileAgent";
$AGENT_SMTP = "SMTPAgent"
$AGENT_SF = "SalesforceAgent"
$AGENT_WD = "WorkdayAgent"
$AGENT_TE = "TenroxAgent"


#
# TFS options
#
$latestOptions = New-Object 'System.Collections.Generic.Dictionary[String,String]';
$latestOptions.Add( "Y", "Yes, Get latest from TFS before building");
$latestOptions.Add( "N", "No, Build with what I have locally only");

#
# a very ugly list of all the projects supported
#
$buildOptions = New-Object 'System.Collections.Generic.Dictionary[String,Object]';
$entry = New-Object PSObject -Property @{ Name = "Server + Agents"; Build = @( $SERVER, $AGENT_AD, $AGENT_CRM, $AGENT_SOR, $AGENT_FS, $AGENT_SMTP, $AGENT_SF, $AGENT_WD, $AGENT_TE )  };
$buildOptions.Add( "A", $entry );
$entry = New-Object PSObject -Property @{ Name = "Server"; Build = @( $SERVER )  };
$buildOptions.Add( "B", $entry );
$entry = New-Object PSObject -Property @{ Name = "All Agents"; Build = @( $AGENT_AD, $AGENT_CRM, $AGENT_SOR, $AGENT_FS, $AGENT_SMTP, $AGENT_SF )  };
$buildOptions.Add( "C", $entry );
$entry = New-Object PSObject -Property @{ Name = "Active Directory Agent"; Build = @( $AGENT_AD )  };
$buildOptions.Add( "D", $entry );
$entry = New-Object PSObject -Property @{ Name = "Salesforce Agent"; Build = @( $AGENT_CRM )  };
$buildOptions.Add( "E", $entry );
$entry = New-Object PSObject -Property @{ Name = "SOR Agent"; Build = @( $AGENT_SOR )  };
$buildOptions.Add( "G", $entry );
$entry = New-Object PSObject -Property @{ Name = "Files Agent"; Build = @( $AGENT_FS )  };
$buildOptions.Add( "H", $entry );
$entry = New-Object PSObject -Property @{ Name = "SMTP Agent"; Build = @( $AGENT_SMTP )  };
$buildOptions.Add( "I", $entry );
$entry = New-Object PSObject -Property @{ Name = "Salesforce TCX Agent"; Build = @( $AGENT_SF )  };
$buildOptions.Add( "J", $entry );
$entry = New-Object PSObject -Property @{ Name = "Workday Agent"; Build = @( $AGENT_WD )  };
$buildOptions.Add( "K", $entry );
$entry = New-Object PSObject -Property @{ Name = "Tenrox Agent"; Build = @( $AGENT_TE )  };
$buildOptions.Add( "L", $entry );
#
# deployment options
#
$deployOptions = New-Object 'System.Collections.Generic.Dictionary[String,String]';
$deployOptions.Add( "T", "Deploy to Test only");
$deployOptions.Add( "P", "Deploy to Production only");
$deployOptions.Add( "B", "Deploy to both Production + Test");
$deployOptions.Add( "N", "Don't FTP anything anywhere");

#
############################ PROMPT FOR TFS UPDATE OR NOT ############################
#
Write-Host "Get Latest Source Options: `r`n";
foreach( $item in $latestOptions.Keys ) { Write-Host "`t$item =" $latestOptions[$item]; }
Write-Host "`r`n";
$GET_LATEST = ( Read-Host "Select your TFS update preference and press enter" ).ToUpper();
if( $latestOptions.ContainsKey( $GET_LATEST ) -eq $false )
{
    Write-Host "Invalid TFS get latest selection. Aborting."; exit;
}
else
{
    Write-Host "You selected: " $latestOptions[$GET_LATEST];
}

Write-Host "`r`n";

#
############################ PROMPT FOR BUILD OPTIONS ############################
#
Write-Host "Build Options: ";
Write-Host "`r`n";
foreach( $item in $buildOptions.Keys ) { Write-Host "`t$item =" $buildOptions.Item($item).Name; }
Write-Host "`r`n";

$BUILD_OPTION = ( Read-Host "Select your build preference and press enter" ).ToUpper();

Write-Host "`r`n";

if( $buildOptions.ContainsKey( $BUILD_OPTION ) -eq $false )
{
    Write-Host "Invalid Build selection. Aborting."; exit;
}
else
{
    Write-Host "You selected: " $buildOptions.Item($BUILD_OPTION).Name;
}


Write-Host "`r`n";

#
############################ PROMPT FOR FTP/DEPLOYMENT OPTIONS ############################
#
Write-Host "Deploy Options: `r`n";
foreach( $item in $deployOptions.Keys ) { Write-Host "`t$item =" $deployOptions[$item]; }
Write-Host "`r`n";
$DEPLOY_OPTION = ( Read-Host "Select your deployment preference and press enter" ).ToUpper();

Write-Host "`r`n";

if( $deployOptions.ContainsKey( $DEPLOY_OPTION ) -eq $false )
{
    Write-Host "Invalid Deployment selection. Aborting."; exit;
}
else
{
    Write-Host "You selected: " $deployOptions[$DEPLOY_OPTION];
}

Write-Host "`r`n";
Write-Host "---------- SELECTED OPTIONS ----------";
Write-Host "Get Latest      =" $latestOptions[$GET_LATEST];
Write-Host "Build Selection =" $buildOptions.Item($BUILD_OPTION).Name;
Write-Host "Deploy Option   =" $deployOptions[$DEPLOY_OPTION];
Write-Host "`r`n";
$CONTINUE = ( Read-Host "Do you want to continue with your settings (Y or N)" ).ToUpper();
IF( $CONTINUE -ne "Y" ) { exit; }

#
############################################# TFS #############################################
#
if( $GET_LATEST -eq "Y" )
{
    $options = $buildOptions.Item($BUILD_OPTION).Build;
    foreach( $option in $options )
    {
        if($option -eq $SERVER )
        {
            Write-Host "Preparing to get latest of $option from TFS`r`n";

            $options = "`$/IntegrationServer/Source/Server /force /recursive";
            $command = "$tfs get " + $options;
            $output = Invoke-Expression $command;
        }
        else
        {
            Write-Host "Preparing to get latest of $option from TFS`r`n";
            $options = "`$/IntegrationServer/Source/Agents/$option /force /recursive";
            $command = "$tfs get " + $options;
            $output = Invoke-Expression $command;
        }

        Write-Host "TFS Result for $option = $output`r`n";
    }
}

#
############################################# BUILD #############################################
#
$projects = $buildOptions.Item($BUILD_OPTION).Build;
foreach( $project in $projects )
{
    if( [System.IO.Directory]::Exists( "$DEP_PATH\$project" ) -eq $true )
    {
        [System.IO.Directory]::Delete( "$DEP_PATH\$project", $true );
    }

    if($project -eq $SERVER )
    {
        Write-Host "Preparing to build: $project`r`n";
        $proj = "$SRC_SERVER_PATH\IntegrationServer.csproj";
        $opts = "/p:VisualStudioVersion=$VS /t:publish $proj /t:PipelinePreDeployCopyAllFilesToOneFolder /p:Configuration=Release /p:_PackageTempDir=$TAR_SERVER_PATH /target:Build";
        $cmd  = "$msbuild " + $opts;
        $output = Invoke-Expression $cmd;
    }
    else
    {
        Write-Host "Preparing to build: $project`r`n";

        $opts = "/p:Configuration=Release /p:OutputPath=$DEP_PATH\$project /target:Build";
        $proj = "$SRC_AGENT_PATH\$project\$project.csproj";
        $cmd  = "$msbuild $proj " + $opts;
        $output = Invoke-Expression $cmd;
    }

    $ok = $false;
    foreach($row in $output)
    {
        if($row.Trim().Contains( "0 Error(s)"))
        {
            $ok = $true;
            $break;
        }
    }

    if( $ok )
    {
        Write-Host "Build Successful for: $project `r`n";
    }
    else
    {
        Write-Host "----------------------------------------------------------------";
        Write-Host "(ABORTING) Build Failed for: $project. Output: $output";
        Write-Host "----------------------------------------------------------------";
        exit;
    }
}


#
############################################# ZIP #############################################
#
foreach( $project in $projects )
{

    if( [System.IO.Directory]::Exists( "$DEP_PATH\$project" ) -eq $true )
    {
        if( [System.IO.File]::Exists( "$DEP_PATH\$project.zip" ) -eq $true )
        {
            [System.IO.File]::Delete( "$DEP_PATH\$project.zip" )
        }

        Write-Host "Preparing to Zip build: $project`r`n";

        if($project -eq "Hub" )
        {
            $opts = @( "a", "-tzip", "$DEP_PATH\$project.zip", "$DEP_PATH\$project\*.*", "-r", "-x!$DEP_PATH\$project\*.xml", "-x!$DEP_PATH\$project\*.config" );
        }
        else
        {
            $opts = @( "a", "-tzip", "$DEP_PATH\$project.zip", "$DEP_PATH\$project\*.*", "-x!$DEP_PATH\$project\*.xml", "-x!$DEP_PATH\$project\*.config" );
        }

        $cmd = "$zip $opts"
        $output = Invoke-Expression $cmd;

        if($output.Contains("Everything is Ok"))
        {
            Write-Host "ZIP Successful for: $project. Deleting Build Folder.`r`n";
            if( $deleteBuildFolderAfterZip -eq $true )
            {
                [System.IO.Directory]::Delete( "$DEP_PATH\$project", $true );
            }
        }
        else
        {
            Write-Host "----------------------------------------------------------------";
            Write-Host "(ABORTING) ZIP Failed for: $project. Output: $output";
            Write-Host "----------------------------------------------------------------";
            exit;
        }
    }

}

#
############################################# FTP #############################################
#
IF( $DEPLOY_OPTION -ne "N" )
{
    Write-Host "Preparing to FTP file(s)`r`n";

    foreach( $project in $projects )
    {
        if( $DEPLOY_OPTION -eq "T" -or $DEPLOY_OPTION -eq "B" )
        {
            $opts = "-V -u " + $TEST_FTP[1] + " -p " + $TEST_FTP[2] + " -m " + $TEST_FTP[0] + " /Integrations $DEP_PATH\$project.zip";
            $cmd = "ncftpput " + $opts;
            $output = Invoke-Expression $cmd;

            if($output -eq $null)
            {
                Write-Host "Test FTP Successful for: $project, File: $project.zip`r`n";
            }
            else
            {
                Write-Host "----------------------------------------------------------------";
                Write-Host "(ABORTING) FTP Failed for: $project. Output: $output";
                Write-Host "----------------------------------------------------------------";
                exit;
            }
        }

        #force a clear out of the command buffer. an issue occurs when attempting to ftp the same file twice in a row..
        $output = Invoke-Expression "dir";

        if( $DEPLOY_OPTION -eq "P" -or $DEPLOY_OPTION -eq "B" )
        {
            $opts = "-V -u " + $PROD_FTP[1] + " -p " + $PROD_FTP[2] + " -m " + $PROD_FTP[0] + " /Integrations $DEP_PATH\$project.zip";
            $cmd = "ncftpput " + $opts;
            $output = Invoke-Expression $cmd;

            if($output -eq $null)
            {
                Write-Host "Prod FTP Successful for: $project, File: $project.zip`r`n";
            }
            else
            {
                Write-Host "----------------------------------------------------------------";
                Write-Host "(ABORTING) FTP Failed for: $project. Output: $output";
                Write-Host "----------------------------------------------------------------";
                exit;
            }
        }

        if( $deleteZipFileAfterFTP -eq $true )
        {
            [System.IO.File]::Delete( "$DEP_PATH\$project.zip" );
        }


    }
}

