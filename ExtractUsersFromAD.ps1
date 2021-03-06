/*

This is a sample of PowerShell craziness.
We used this to retrieve out specific user information across multiple domains. 

The code was anonymized, so there may be discrepancies. This is for work product sharing only.

*/


Import-Module ActiveDirectory

##################################################################################################################
$domain = "{domain name}";
$ad_svr = "{domain server ip}";
$ad_usr = "{fully qualified username}";
$ad_pwd = "{password}";
$db_svr = 'localhost'; 

###################################################################################################################
$Error.Clear();

$run = [DateTime]::Now;

$domains = @();
$domains += New-Object PSObject -Property @{ 
                                            Enabled  = $true; 
                                            Name     = $domain; 
                                            Server   = $ad_svr;  
                                            Username = $ad_usr;
                                            Password = $ad_pwd;
                                            };


#$Users = get-aduser -credential $creds -LDAPFilter $filter -properties * | select adspath,distinguishedName,cn,name,sAMAccountName, msNPAllowDialin,givenName,middleName,sn,info,employeeID,employeeNumber,employeeType,userPrincipleName,displayName,description,mail,maxPwdAge,whenCreated,accountExpires,pwdLastSet,streetAddress,postOfficeBox,l,st,postalCode,co,c,countryCode,title,physicalDeliveryOfficeName,department,company,manager,mobile,telephoneNumber,homeMDB,msExchHomeServerName,mailNickname,msExchHideFromAddressLists,altRecipient,deliverAndRedirect,userAccountControl,extensionAttribute1,extensionAttribute2,extensionAttribute3,extensionAttribute5,proxyAddresses,memberOf;

# First, clear existing table

foreach( $domain in $domains )
{
    $domainName = $domain.Name;

    if( $domain.Enabled -eq $false )
    {
        continue;
    }

    #connect to active directory and get the users we need to process
    #(note: using this instead of get-aduser because this code will work on a machine not on the domain. get-aduser doesn't...
    $ctx = New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext( [System.DirectoryServices.ActiveDirectory.DirectoryContextType]::DirectoryServer, $domain.Server, $domain.Username, $domain.Password );
    [System.DirectoryServices.ActiveDirectory.DomainController]$controller = $null;
    try
    {
        $controller =  [System.DirectoryServices.ActiveDirectory.DomainController]::GetDomainController( $ctx );
    }
    catch
    {
        Write-Output $Error[0].Exception 
        exit;
    }
 
    $searcher = $controller.GetDirectorySearcher();
    $searcher.SearchScope = [System.DirectoryServices.SearchScope]::Subtree;
    $searcher.PropertiesToLoad.Add( "adspath" );
    $searcher.PropertiesToLoad.Add( "distinguishedname" );
    $searcher.PropertiesToLoad.Add( "cn" );
    $searcher.PropertiesToLoad.Add( "name" );
    $searcher.PropertiesToLoad.Add( "samaccountname" );
    $searcher.PropertiesToLoad.Add( "msnpallowdialin" );
    $searcher.PropertiesToLoad.Add( "givenname" );
    $searcher.PropertiesToLoad.Add( "middlename" );
    $searcher.PropertiesToLoad.Add( "sn" );
    $searcher.PropertiesToLoad.Add( "info" );
    $searcher.PropertiesToLoad.Add( "employeeid" );
    $searcher.PropertiesToLoad.Add( "employeenumber" );
    $searcher.PropertiesToLoad.Add( "employeetype" );
    $searcher.PropertiesToLoad.Add( "userprinciplename" );
    $searcher.PropertiesToLoad.Add( "displayname" );
    $searcher.PropertiesToLoad.Add( "description" );
    $searcher.PropertiesToLoad.Add( "mail" );
    $searcher.PropertiesToLoad.Add( "whencreated" );
    $searcher.PropertiesToLoad.Add( "accountexpires" );
    $searcher.PropertiesToLoad.Add( "pwdlastset" );
    $searcher.PropertiesToLoad.Add( "countrycode" );
    $searcher.PropertiesToLoad.Add( "title" );
    $searcher.PropertiesToLoad.Add( "manager" );
    $searcher.PropertiesToLoad.Add( "mobile" );
    $searcher.PropertiesToLoad.Add( "telephonenumber" );
    $searcher.PropertiesToLoad.Add( "homemdb" );
    $searcher.PropertiesToLoad.Add( "msexchhomeservername" );
    $searcher.PropertiesToLoad.Add( "mailNickname" );
    $searcher.PropertiesToLoad.Add( "msexchhidefromaddresslists" );
    $searcher.PropertiesToLoad.Add( "altrecipient" );
    $searcher.PropertiesToLoad.Add( "deliverandredirect" );
    $searcher.PropertiesToLoad.Add( "useraccountcontrol" );
    $searcher.PropertiesToLoad.Add( "extensionattribute1" );
    $searcher.PropertiesToLoad.Add( "extensionattribute2" );
    $searcher.PropertiesToLoad.Add( "extensionattribute3" );
    $searcher.PropertiesToLoad.Add( "extensionattribute5" );
    $searcher.PropertiesToLoad.Add( "proxyaddresses" );
    $searcher.PropertiesToLoad.Add( "memberof" );
    $searcher.PropertiesToLoad.Add( "userPrincipalName" );
    


    #Need to increase if terms goes over 999
    $searcher.PageSize = 999;
    $searcher.SizeLimit = 999;



    $searcher.Filter = "(&(objectClass=user)(employeeNumber=*))";
    $results = New-Object Collections.Generic.List[System.DirectoryServices.SearchResult];

    #this gets around odd issues of doing bigger code inside the search results loop (buggy)
    $src = $searcher.FindAll();
    foreach ( $sr in $src )
    {
        $results.Add( $sr );
    }

    if($results.Count -eq 0 )
    {
        continue;
    }


    $conn = New-Object System.Data.SqlClient.SqlConnection("Data Source=$db_svr;Initial Catalog=ADJobs;Timeout=10;User Id={omitted};Password={omitted}")
    $conn.Open()
    Write-Host 'Connected to SQL Server';

    foreach ($record In $results)
    {
        $adspath = "";
        $distinguishedname = "";
        $cn = "";
        $name = "";
        $samaccountname = "";
        $msnpallowdialin = $false;
        $givenname = "";
        $middlename = "";
        $sn = "";
        $employeeid = "";
        $employeenumber = "";
        $employeetype = "";
        $displayname = "";
        $mail = "";
        $whencreated = $null;
        $accountexpires = 0;
        $pwdlastset = 0;
        $countrycode = "";
        $manager = "";
        $telephonenumber = "";
        $mobile = "";
        $homemdb = "";
        $msexchhomeservername = "";
        $mailnickname = "";
        $msexchhidefromaddresslists = $false;
        $altrecipient = "";
        $deliverandredirect = "";
        $useraccountcontrol = 0;
        $extensionattribute1 = "";
        $extensionattribute2 = "";
        $extensionattribute3 = "";
        $extensionattribute5 = "";    
        $proxyaddresses = "";
        $memberof = "";
        $userPrincipalName = "";

        # walk through each property we're expecting, see if it exists, and if so, grab it
        if( $record.Properties.Contains("adspath") )                    { $adspath = $record.Properties["adspath"][0] };
        if( $record.Properties.Contains("distinguishedname") )          { $distinguishedname = $record.Properties["distinguishedname"][0] };
        if( $record.Properties.Contains("cn") )                         { $cn = $record.Properties["cn"][0] };
        if( $record.Properties.Contains("name") )                       { $name = $record.Properties["name"][0] };
        if( $record.Properties.Contains("samaccountname") )             { $samaccountname = $record.Properties["samaccountname"][0] };
        if( $record.Properties.Contains("msnpallowdialin") )            { $msnpallowdialin = [bool]$record.Properties["msnpallowdialin"][0] };
        if( $record.Properties.Contains("givenname") )                  { $givenname = $record.Properties["givenname"][0] };
        if( $record.Properties.Contains("middlename") )                 { $middlename = $record.Properties["middlename"][0] };
        if( $record.Properties.Contains("employeeid") )                 { $employeeid = $record.Properties["employeeid"][0] };
        if( $record.Properties.Contains("employeenumber") )             { $employeenumber = $record.Properties["employeenumber"][0] };
        if( $record.Properties.Contains("employeetype") )               { $employeetype = $record.Properties["employeetype"][0] };
        if( $record.Properties.Contains("displayname") )                { $displayname = $record.Properties["displayname"][0] };
        if( $record.Properties.Contains("mail") )                       { $mail = $record.Properties["mail"][0] };
        if( $record.Properties.Contains("whencreated") )                { $whencreated = $record.Properties["whencreated"][0] };
        if( $record.Properties.Contains("accountexpires") )             { $accountexpires = $record.Properties["accountexpires"][0] };
        if( $record.Properties.Contains("pwdlastset") )                 { $pwdlastset = $record.Properties["pwdlastset"][0] };
        if( $record.Properties.Contains("countrycode") )                { $countrycode = $record.Properties["countrycode"][0] };
        if( $record.Properties.Contains("manager") )                    { $manager = $record.Properties["manager"][0] };
        if( $record.Properties.Contains("telephonenumber") )            { $telephonenumber = $record.Properties["telephonenumber"][0] };
        if( $record.Properties.Contains("mobile") )                     { $mobile = $record.Properties["mobile"][0] };
        if( $record.Properties.Contains("homemdb") )                    { $homemdb = $record.Properties["homemdb"][0] };
        if( $record.Properties.Contains("msexchhomeservername ") )      { $msexchhomeservername  = $record.Properties["msexchhomeservername"][0] };
        if( $record.Properties.Contains("mailnickname") )               { $mailnickname = $record.Properties["mailnickname"][0] };
        if( $record.Properties.Contains("msexchhidefromaddresslists") ) { $msexchhidefromaddresslists = $record.Properties["msexchhidefromaddresslists"][0] };
        if( $record.Properties.Contains("altrecipient") )               { $altrecipient = $record.Properties["altrecipient"][0] };
        if( $record.Properties.Contains("deliverandredirect") )         { $deliverandredirect = $record.Properties["deliverandredirect"][0] };
        if( $record.Properties.Contains("useraccountcontrol") )         { $useraccountcontrol = $record.Properties["useraccountcontrol"][0] };
        if( $record.Properties.Contains("extensionattribute1") )        { $extensionattribute1 = $record.Properties["extensionattribute1"][0] };
        if( $record.Properties.Contains("extensionattribute2") )        { $extensionattribute2 = $record.Properties["extensionattribute2"][0] };
        if( $record.Properties.Contains("extensionattribute3") )        { $extensionattribute3 = $record.Properties["extensionattribute3"][0] };
        if( $record.Properties.Contains("extensionattribute5") )        { $extensionattribute5 = $record.Properties["extensionattribute5"][0] };
        if( $record.Properties.Contains("userPrincipalName") )          { $userPrincipalName = $record.Properties["userPrincipalName"][0] };

        if( $record.Properties.Contains("proxyaddresses" ) )
        {
            $proxyaddresses = [system.String]::Join(",", ( $record.Properties["proxyaddresses"] | Sort-Object ) )

        } 
        if( $record.Properties.Contains("memberof" ) )
        {
            $memberof = [system.String]::Join(",", ( $record.Properties["memberof"] | foreach {$_.split(",")[0].trim("CN=") } | Sort-Object ) )
        } 

        # no time to create stored procedure, so going lazy style..
        $sql_query = "INSERT INTO users VALUES ( @a0, @a1, @a2, @a3, @a4, @a5, @a6, @a7, @a8, @a9, @a10, @a11, @a12, @a13, @a14, @a15, @a16, @a17, @a18, @a19, @a20, @a21, @a22, @a23, @a24, @a25, @a26, @a27, @a28, @a29, @a30, @a31, @a32, @a33, @a34, @a35 )";

        try
        {
            $cmd = $conn.CreateCommand()
            $cmd.CommandText = $sql_query;
            
            $e = $cmd.Parameters.Add( "@a0", [datetime]$run );
            $e = $cmd.Parameters.Add( "@a1", [string]$domainName );
            $e = $cmd.Parameters.Add( "@a2", [string]$distinguishedname );
            $e = $cmd.Parameters.Add( "@a3", [string]$adspath );
            $e = $cmd.Parameters.Add( "@a4", [string]$cn );
            $e = $cmd.Parameters.Add( "@a5", [string]$name );
            $e = $cmd.Parameters.Add( "@a6", [string]$samaccountname );
            $e = $cmd.Parameters.Add( "@a7", [bool]$msnpallowdialin );
            $e = $cmd.Parameters.Add( "@a8", [string]$givenname );
            $e = $cmd.Parameters.Add( "@a9", [string]$sn );
            $e = $cmd.Parameters.Add( "@a10", [string]$employeeid );
            $e = $cmd.Parameters.Add( "@a11", [string]$employeenumber );
            $e = $cmd.Parameters.Add( "@a12", [string]$employeetype );
            $e = $cmd.Parameters.Add( "@a13", [string]$displayname );
            $e = $cmd.Parameters.Add( "@a14", [string]$mail );
            $e = $cmd.Parameters.Add( "@a15", [datetime]$whencreated );
            $e = $cmd.Parameters.Add( "@a16", [long]$accountexpires );
            $e = $cmd.Parameters.Add( "@a17", [long]$pwdlastset );
            $e = $cmd.Parameters.Add( "@a18", [long]$countrycode );
            $e = $cmd.Parameters.Add( "@a19", [string]$manager );
            $e = $cmd.Parameters.Add( "@a20", [string]$telephonenumber );
            $e = $cmd.Parameters.Add( "@a21", [string]$telephonenumber );
            $e = $cmd.Parameters.Add( "@a22", [string]$homemdb );
            $e = $cmd.Parameters.Add( "@a23", [string]$msexchhomeservername );
            $e = $cmd.Parameters.Add( "@a24", [string]$mailnickname );
            $e = $cmd.Parameters.Add( "@a25", [bool]$msexchhidefromaddresslists );
            $e = $cmd.Parameters.Add( "@a26", [string]$altrecipient );
            $e = $cmd.Parameters.Add( "@a27", [string]$deliverandredirect );
            $e = $cmd.Parameters.Add( "@a28", [long]$useraccountcontrol );
            $e = $cmd.Parameters.Add( "@a29", [string]$extensionattribute1 );
            $e = $cmd.Parameters.Add( "@a30", [string]$extensionattribute2 );
            $e = $cmd.Parameters.Add( "@a31", [string]$extensionattribute3 );
            $e = $cmd.Parameters.Add( "@a32", [string]$extensionattribute5 );   
            $e = $cmd.Parameters.Add( "@a33", [string]$proxyaddresses );
            $e = $cmd.Parameters.Add( "@a34", [string]$memberof );
            $e = $cmd.Parameters.Add( "@a35", [string]$userPrincipalName );
            
            $e = $cmd.ExecuteNonQuery();
        }
        catch
        {
           Write-Output $Error[0].Exception 
           exit;
        }
    }

    if($conn.State -ne [System.Data.ConnectionState]::Closed )
    {
        $conn.Close()
    }

}