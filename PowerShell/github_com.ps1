#**************************************************************************************************#
#                                                                                                  #
#  @project     : LoC Counting PowerShell Scripts                                                  #
#  @package     :                                                                                  #
#  @subpackage  : github_com.ps1                                                                   #
#  @access      :                                                                                  #
#  @paramtype   : connectionToken,organization,cloc PATH                                           #
#  @argument    :                                                                                  #
#  @description : Get Number ligne of Code in GitHub DevOPS                                        #
#  @usage : ./github_com.ps1 <token> <org> <PATH for cloc binary>                                  #                                                              
#                                                                                                  #
#                                                                                                  #
#  @author Emmanuel COLUSSI                                                                        #
#  @version 1.02                                                                                   #
#                                                                                                  #
#**************************************************************************************************#

$BaseAPI="https://api.github.com"

if ($args.Length -lt 3) {
  Write-Output ('Usage: github_com.ps1 <token> <org> <Full PATH for cloc binary>')
} 
else {
    $connectionToken=$args[0]
    $organization=$args[1]
    $CLOCPATH=$args[2]

    $GetAPI="orgs/$organization/repos"

    if(Test-Path $CLOCPATH) {
      $Page=0
      $AllRepos = @()
      # Encode Authentification Token
      $base64AuthInfo= [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(":$($connectionToken)"))
      do {
        $Page += 1
        # Set API URL to Get Repositories
        $ProjectUrl="${BaseAPI}/${GetAPI}?page=${Page}"
        # Get List of Repositories
        $Repos = (Invoke-RestMethod -Uri $ProjectUrl -Method Get -UseDefaultCredential -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)})
        $AllRepos += $Repos    
        $RepoCount = @($Repos).count 
      } while($RepoCount -gt 0)
      # Display Number of Repositories
      $NumberRepositories= @($AllRepos).count
      Write-Host "`n Number of Repositories : ${NumberRepositories} `n"

      #Loop through repositories and count
      $j=0
      foreach ($Repo in $AllRepos) {
       
        # Display Repository Name and ID
        $RepoName= $Repo.name
        $IDrepo=$Repo.id
        $RepoNum=++$j
        Write-Host "-----------------------------------------------------------------"
        Write-Host "`n Repository Number :$RepoNum  Name : $RepoName id : $IDrepo`n"
     
        # Build repo URL
        $remoteUrl="https://oauth2:${connectionToken}@github.com/${organization}/${RepoName}"
       
        # Encode Repository Name
        $RepoName2=$RepoName.replace(" ","_").replace("/","_") 
        # Remove folder where repo will be checked out, if it exists
        if (Test-Path -Path $RepoName2) {
          Write-Host "Cleaning up ${RepoName}"
          Remove-Item $RepoName2 -Recurse -Force
        }
        #Clone repository to local name
        $cmdline0=" git clone '" + $remoteUrl.replace(" ","%20") + "' --depth 1 " + $RepoName2 
        Invoke-Expression -Command $cmdline0  

        # Run cloc on the local repository - output to REPONAM.cloc
        Write-Host "Counting ${RepoName}"
        $cmdparms2="${RepoName2} --force-lang-def=sonar-lang-defs.txt --ignore-case-ext --report-file=${RepoName2}.cloc --timeout 0"
        $cmdline2=$CLOCPATH + " " + $cmdparms2
        Invoke-Expression -Command $cmdline2
        
        # Remove local repo
        if (Test-Path -Path $RepoName2) {
          Write-Host "Cleaning up ${RepoName}"
          Remove-Item $RepoName2 -Recurse -Force
        }
      }
  
      #Run Summary report to generate .file and .land totals
      $cmdline3=$CLOCPATH + " --sum-reports --force-lang-def=sonar-lang-defs.txt --report-file=${organization} *.cloc"
      Invoke-Expression -Command $cmdline3

      #Clean up cloc files
      Remove-Item *.cloc
    } else {
            Write-Host "Error : PATH for cloc binary is wrong"
    }
}

