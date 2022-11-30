#******************************************************************#
#                                                                  #
#  @project     : LoC Counting PowerShell Scripts                  #
#  @package     :                                                  #
#  @subpackage  : azuredevops.ps1                                  #
#  @access      :                                                  #
#  @paramtype   : connectionToken,organization,cloc PATH           #
#  @argument    :                                                  #
#  @description : Get Number ligne of Code in Azure DevOPS         #
#  @usage : ./azuredevops.ps1 <token> <org> <PATH for cloc binary> #                                                              
#                                                                  #
#                                                                  #
#  @author Emmanuel COLUSSI                                        #
#  @version 1.01                                                   #
#******************************************************************#


if ($args.Length -lt 3) {
  Write-Output ('Usage: azuredevops.ps1 <token> <org> <PATH for cloc binary>')
} 
else {

    # Set Variables token, organization and PATH for cloc binary
  
    $connectionToken=$args[0]
    $organization=$args[1]
    $CLOCPATH=$args[2]

    if(Test-Path $CLOCPATH) {

      # Encode Authentification Token
      $base64AuthInfo= [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(":$($connectionToken)"))
      # Set API URL to Get Repositories
      $ProjectUrl = "https://dev.azure.com/${organization}/_apis/git/repositories?api-version=6.1-preview.1" 
      # Get List of Repositories
       try {
        $Repo = (Invoke-RestMethod -Uri $ProjectUrl -Method Get -UseDefaultCredential -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)} -Verbose -ErrorAction Stop)
       }
       catch { Write-Error -Message $_} 
      # Get Number of Repositories
      $NumberRepositories=$Repo.value.count

      for ($j=0; $j -lt $NumberRepositories;$j++) {
        Write-Host "Number of Repositories : ${NumberRepositories}"
        # Get Repositorie Name and ID
        $RepoName= $Repo.value[$j].name
        $IDrepo=$Repo.value[$j].id
     
        # Set API URL to Get Branches
        $ProjetBranchUrl="https://dev.azure.com/${organization}/${RepoName}/_apis/git/repositories/${IDrepo}/refs?filter=heads/&api-version=7.0"
        Write-Host  $ProjetBranchUrl
        # Get List of Branches
        try {
         $Branch = (Invoke-RestMethod -Uri $ProjetBranchUrl -Method Get -UseDefaultCredential -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)} -Verbose -ErrorAction Stop)
        }
        catch { Write-Error -Message $_} 
        # Get Number of Branches
        $NumberBranch=$Branch.value.count
      

        for ($i = 0; $i -lt $NumberBranch; $i++) {
          # Get Branche Name 
          $BranchePathName=$Branch.value[$i].name.replace('refs/heads/','')
          $BranchList= $Branch.value[$i].name.Split("/")
          $BrancheName=$BranchList[$BranchList.count -1 ]
        
          # Clone Repository locally
          Write-Host "Get ${RepoName}/${BrancheName}"
          $remoteUrl="https://${connectionToken}@dev.azure.com/${organization}/${RepoName}/_git/${RepoName}"
          git clone $remoteUrl --depth 1 --branch $BranchePathName $RepoName

          # Run Analyse : run cloc on the local repository
          Write-Host "Analyse Counting ${RepoName}/${BrancheName}"
          $cmdparms2="${RepoName} --force-lang-def=sonar-lang-defs.txt --report-file=${RepoName}_${BrancheName}.cloc"
          $cmdline2=$CLOCPATH + " " + $cmdparms2
          Invoke-Expression -Command $cmdline2
       
          # Generate report
          "Result Analyse Counting ${RepoName}/${BrancheName}" | Out-File -Append "${RepoName}.cloc"
          Get-content ${RepoName}_${BrancheName}.cloc | Out-File -Append "${RepoName}.cloc"
          Remove-Item ${RepoName}_${BrancheName}.cloc -Recurse -Force
          Remove-Item $RepoName -Recurse -Force
       
        }
        Write-Host "----------------------------------------------"
        Write-Host "The Analyse Result is in ${RepoName}.cloc file"
        Write-Host "----------------------------------------------"
      }  
    }    
    else {
            Write-Host "Error : PATH for cloc binary is wrong"
    }
}
