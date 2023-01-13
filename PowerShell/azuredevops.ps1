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
#                                                                  #
#******************************************************************#


$CLOCBr=@([PSCustomObject]@{ })
$NBCLOC="cpt.txt"
$cpt=0

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
      $ProjectUrl = "https://dev.azure.com/${organization}/_apis/git/repositories?api-version=7.0" 
      # Get List of Repositories
      $Repo = (Invoke-RestMethod -Uri $ProjectUrl -Method Get -UseDefaultCredential -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)})
      # Get Number of Repositories
      $NumberRepositories=$Repo.value.count 

      Write-Host "`n Number of Repositories : ${NumberRepositories} `n"

      for ($j=0; $j -lt $NumberRepositories;$j++) {
       
        # Get Repositorie Name and ID
        $RepoName= $Repo.value[$j].name
        $IDrepo=$Repo.value[$j].id
        Write-Host "-----------------------------------------------------------------"
        Write-Host "`n Repository Number :$j  Name : $RepoName id : $IDrepo`n"
     
        # Set API URL to Get Branches
        $ProjetBranchUrl1="https://dev.azure.com/${organization}/${RepoName}/_apis/git/repositories/${IDrepo}/refs?filter=heads/&api-version=7.0"
       # [uri]::EscapeDataString( $ProjetBranchUrl)
        $ProjetBranchUrl= $ProjetBranchUrl1.replace(" ","%20")
       
        # Get List of Branches
        try {
         $Branch = (Invoke-RestMethod -Uri $ProjetBranchUrl -Method Get -UseDefaultCredential -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)})
        } Catch {
            if($_.ErrorDetails.Message) {
              # Write-Host $_.ErrorDetails.Message
            } else {
              # Get Number of Branches
               $NumberBranch=$Branch.value.count
            }
         }
        $NumberBranch=$Branch.value.count
     

        for ($i = 0; $i -lt $NumberBranch; $i++) {
          # Get Branche Name 
          $BranchePathName=$Branch.value[$i].name.replace('refs/heads/','')
          $BranchList= $Branch.value[$i].name.Split("/")
          $BrancheName=$BranchList[$BranchList.count -1 ]
         
        
          # Clone Repository locally
          Write-Host "`n      Branche Name : ${RepoName}/${BrancheName} `n"
          $remoteUrl="https://${connectionToken}@dev.azure.com/${organization}/${RepoName}/_git/${RepoName}"
          # Create Commad Git clone and replace space by %20
          $RepoName2=$RepoName.replace(" ","_").replace("/","_") 

          if (Test-Path -Path $RepoName2) {
            Remove-Item $RepoName2 -Recurse -Force
          } else {
            
          }
          $cmdline0=" git clone '" + $remoteUrl.replace(" ","%20") + "' --depth 1 --branch '" + $BranchePathName + "' " + $RepoName2
          Invoke-Expression -Command $cmdline0  

          # Run Analyse : run cloc on the local repository
          Write-Host "Analyse Counting ${RepoName}/${BrancheName}"
          $cmdparms2="${RepoName2} --force-lang-def=sonar-lang-defs.txt --report-file=${RepoName2}_${BrancheName}.cloc"
          $cmdline2=$CLOCPATH + " " + $cmdparms2
          Invoke-Expression -Command $cmdline2

          If ( -not (Test-Path -Path ${RepoName2}_${BrancheName}.cloc) )  {
            "0 Files Analyse in ${RepoName2}/${BrancheName}" | Out-File ${RepoName2}_${BrancheName}.cloc
          }
         
       
          # Generate report
          "Result Analyse Counting ${RepoName2} / ${BrancheName}" | Out-File -Append "${RepoName2}.txt"
          Get-content ${RepoName2}_${BrancheName}.cloc | Out-File -Append "${RepoName2}.txt"
       
        }

        Write-Host "`nBuilding final report for projet $RepoName : $RepoName.txt"



        Get-ChildItem -Path .\* -Include *.cloc |ForEach-Object { $NMCLOCB=Get-content $_.Name |Select-String "SUM:";$NMCLOCB-replace "\s{2,}" , " "| ForEach-Object{$NMCLOCB1=$_.ToString().split(" ");$CLOCBr+=@([PSCustomObject]@{ CLOC=$NMCLOCB1[4] ; BRANCH=${BrancheName}})};Remove-Item $_.Name -Recurse -Force} 
        $CLOCBr | Select-Object | Sort-Object -Property CLOC -Descending -OutVariable Sorted | Out-Null

        $clocmax=$($Sorted[0].CLOC -as [decimal]).ToString('N2')
        $Branchmax=$Sorted[0].BRANCH

        Remove-Item $RepoName2 -Recurse -Force
      
        

        If($NumberBranch -eq 0) {$RepoName2=$RepoName}
        Write-Host "-------------------------------------------------------------------------------------------------------"
        Write-Host "`nThe maximum lines of code in the ${RepoName2} project is : < $clocmax > for the branch : $Branchmax `n"
        Write-Host "-------------------------------------------------------------------------------------------------------"
        "-------------------------------------------------------------------------------------------------------"| Out-File -Append "${RepoName2}.txt"
        "The maximum lines of code in the ${RepoName2} project is : < $clocmax > for the branch : $Branchmax `n"| Out-File -Append "${RepoName2}.txt"
        "-------------------------------------------------------------------------------------------------------"| Out-File -Append "${RepoName2}.txt"

        $clocmax | Out-File -Append "$NBCLOC"
      }  
      # Generate Gobal report


      if (Test-Path -Path $NBCLOC) {
        foreach($line in Get-Content .\${NBCLOC}) {
          $cpt=$cpt + $line    
        }

        $cpt=$($cpt -as [decimal]).ToString('N2')
      
        Remove-Item $NBCLOC -Recurse -Force

        Write-Host "`n-------------------------------------------------------------------------------------------------------"
        Write-Host  "`nThe maximum lines of code on the organization is : < $cpt > result in <global.txt>`n"
        Write-Host  "`n-------------------------------------------------------------------------------------------------------"


       "-------------------------------------------------------------------------------------------------------n" | Out-File -Append global.txt
       "`nThe maximum lines of code on the organization is : < $cpt >`n"| Out-File -Append global.txt
       "-------------------------------------------------------------------------------------------------------" | Out-File -Append global.txt
      }

    }    
    else {
            Write-Host "Error : PATH for cloc binary is wrong"
    }
}

