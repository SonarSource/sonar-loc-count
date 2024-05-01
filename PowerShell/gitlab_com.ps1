#**************************************************************************************************#
#                                                                                                  #
#  @project     : LoC Counting PowerShell Scripts                                                  #
#  @package     :                                                                                  #
#  @subpackage  : gitlab_com.ps1                                                                   #
#  @access      :                                                                                  #
#  @paramtype   : connectionToken,groupName or path_with_namespace                                 #
#  @argument    :                                                                                  #
#  @description : Get Number ligne of Code in GitLab DevOPS                                        #
#  @usage : ./gitlab_com.sh <token> <groupName>                                                    #                                                              
#                                                                                                  #
#                                                                                                  #
#                                                                         #
#  @version 1.01                                                                                   #
#                                                                                                  #
#**************************************************************************************************#


# Set Variables CLOCBr (object: [NBR_LINE_CODE][BRANCHE_NAME]), cpt, NBCLOC,BaseAPI
#--------------------------------------------------------------------------------------#

$CLOCBr=@([PSCustomObject]@{ })
$NBCLOC="cpt.txt"
$cpt=0
$BaseAPI="https://gitlab.com/api/v4"

if ($args.Length -lt 3) {
  Write-Output ('Usage: gitlab_com.ps1 <token> <org> <PATH for cloc binary> optional <projects>')
} 
else {

    # Set Variables token, organization and PATH for cloc binary
    #--------------------------------------------------------------------------------------#
    $connectionToken=$args[0]
    $groupname=$args[1]
    $CLOCPATH=$args[2]


    $StSubgroupName=$groupname | Select-String -Pattern '/'
    if ($StSubgroupName.MAtches.Success -eq "True") { $Namespace=1 } else { $Namespace=0 }  
   
    # Test if request for for 1 Project or more Project in GroupName
    if ($Namespace -eq 1 ) {
            $groupname1=$groupname.replace("/","%2f")
            $GetAPI="/projects/$groupname1"
    }

    else  {
            $GetAPI="/groups/$groupname/projects?include_subgroups=true"
  
    }


    if(Test-Path $CLOCPATH) {

      # Encode Authentification Token
      $base64AuthInfo= [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(":$($connectionToken)"))
      # Set API URL to Get Repositories
      $ProjectUrl="${BaseAPI}${GetAPI}"  
     
      # Get List of Repositories
      $Repo = (Invoke-RestMethod -Uri $ProjectUrl -Method Get -UseDefaultCredential -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)})
      # Get Number of Repositories
      $NumberRepositories=@($Repo).count

      Write-Host "`n Number of Repositories : ${NumberRepositories} `n"
      
      # Parse Repositories
      #--------------------------------------------------------------------------------------#

      for ($j=0; $j -lt $NumberRepositories;$j++) {
       
        # Get Repositorie Name and ID
        if ( $NumberRepositories -eq 1) { 
                $RepoName= $Repo.name
                $IDrepo=$Repo.id
                $Repourl=$Repo.http_url_to_repo
        }
        else {
                $RepoName= $Repo.name[$j]
                $IDrepo=$Repo.id[$j]
                $Repourl=$Repo.http_url_to_repo[$j]
          
        }
        Write-Host "-----------------------------------------------------------------"
        Write-Host "`n Repository Number :$j  Name : $RepoName id : $IDrepo`n"
    
        # Set API URL to Get Branches
        $ProjetBranchUrl1="${BaseAPI}/projects/${IDrepo}/repository/branches" 
  
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
               $NumberBranch=@($Branch).count
            }
         }
        $NumberBranch=@($Branch).count
     
        # Parse Repositories/Branches 
        #--------------------------------------------------------------------------------------#

        for ($i = 0; $i -lt $NumberBranch; $i++) {
          # Get Branche Name 
          if($NumberBranch -ne 1) { 
            $BrancheName=$Branch.name[$i]
            }
             else { $BrancheName=$Branch.name
            }    
        
          # Clone Repository locally
          Write-Host "`n      Branche Name : ${RepoName}/${BrancheName} `n"

          $Repourl=$Repourl.replace(" ","%20")
        
          # Create Commad Git clone and replace space by %20
          $RepoName2=$RepoName.replace(" ","_").replace("/","_") 

          if (Test-Path -Path $RepoName2) {
             Remove-Item $RepoName2 -Recurse -Force
          } else {}
          #$cmdline0=" git clone '" + $remoteUrl.replace(" ","%20") + "' --depth 1 --branch '" + $BrancheName + "' " + $RepoName2
          $cmdline0=" git clone '" + $Repourl + "' --depth 1 --branch '" + $BrancheName + "' " + $RepoName2
          Invoke-Expression -Command $cmdline0  

          # Run Analyse : run cloc on the local repository
          Write-Host "Analyse Counting ${RepoName}/${BrancheName}"
          $cmdparms2="${RepoName2} --force-lang-def=sonar-lang-defs.txt --report-file=${RepoName2}_${BrancheName}.cloc  --timeout 0 --sum-one"
          $cmdline2=$CLOCPATH + " " + $cmdparms2
          Invoke-Expression -Command $cmdline2

          If ( -not (Test-Path -Path ${RepoName2}_${BrancheName}.cloc) )  {
            "0 Files Analyse in ${RepoName2}/${BrancheName}" | Out-File ${RepoName2}_${BrancheName}.cloc
          }
         
       
          # Generate report
          "Result Analyse Counting ${RepoName2} / ${BrancheName}" | Out-File -Append "${RepoName2}.txt"
          Get-content ${RepoName2}_${BrancheName}.cloc | Out-File -Append "${RepoName2}.txt"
       
        }
         #--------------------------------------------------------------------------------------#

        Write-Host "`nBuilding final report for projet $RepoName : $RepoName.txt"


        Get-ChildItem -Path .\* -Include *.cloc |ForEach-Object { $NMCLOCB=Get-content $_.Name |Select-String "SUM:";$NMCLOCB-replace "\s{2,}" , " "| ForEach-Object{$NMCLOCB1=$_.ToString().split(" ");$CLOCBr+=@([PSCustomObject]@{ CLOC=$NMCLOCB1[4] ; BRANCH=${BrancheName}})};Remove-Item $_.Name -Recurse -Force} 
        $CLOCBr | Select-Object | Sort-Object -Property CLOC -Descending -OutVariable Sorted | Out-Null

        $clocmax=$($Sorted[0].CLOC -as [decimal]).ToString('N2')
        $Branchmax=$Sorted[0].BRANCH

        # Remove local repos
        if (Test-Path -Path $RepoName2) {
          Remove-Item $RepoName2 -Recurse -Force
        } else {}
       
        # Reset object
        $CLOCBr=@([PSCustomObject]@{ })
      
        

        If($NumberBranch -eq 0) {$RepoName2=$RepoName}
        Write-Host "-------------------------------------------------------------------------------------------------------"
        Write-Host "`nThe maximum lines of code in the ${RepoName2} project is : < $clocmax > for the branch : $Branchmax `n"
        Write-Host "-------------------------------------------------------------------------------------------------------"
        "-------------------------------------------------------------------------------------------------------"| Out-File -Append "${RepoName2}.txt"
        "The maximum lines of code in the ${RepoName2} project is : < $clocmax > for the branch : $Branchmax `n"| Out-File -Append "${RepoName2}.txt"
        "-------------------------------------------------------------------------------------------------------"| Out-File -Append "${RepoName2}.txt"

        $clocmax | Out-File -Append "$NBCLOC"
      }  
       #--------------------------------------------------------------------------------------#

      # Generate Gobal report
       #--------------------------------------------------------------------------------------#

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
      #--------------------------------------------------------------------------------------#

    }    
    else {
            Write-Host "Error : PATH for cloc binary is wrong"
    }
}

