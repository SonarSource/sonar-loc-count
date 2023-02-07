#******************************************************************************************#
#                                                                                          #
#  @project     : LoC Counting PowerShell Scripts                                          #
#  @package     :                                                                          #
#  @subpackage  : azuredevops.ps1                                                          #
#  @access      :                                                                          #
#  @paramtype   : connectionToken,organization,cloc PATH                                   #
#  @argument    :                                                                          #
#  @description : Get Number ligne of Code in Azure DevOPS                                 #
#  @usage : ./azuredevops.ps1 <token> <org> <PATH for cloc binary> and optional <projects> #                                                              
#                                                                                          #
#                                                                                          #
#  @author Emmanuel COLUSSI                                                                #
#  @version 1.02                                                                           #
#                                                                                          #
#******************************************************************************************#



# Set Variables CLOCBr (object: [NBR_LINE_CODE][BRANCHE_NAME]), cpt, NBCLOC, BaeAPI
#--------------------------------------------------------------------------------------#

$CLOCBr=@([PSCustomObject]@{ })
$NBCLOC="cpt.txt"
$cpt=0
$BaseAPI="https://dev.azure.com"

if ($args.Length -lt 3) {
  Write-Output ('Usage: azuredevops.ps1 <token> <org> <PATH for cloc binary> optional <projects>')
} 
else {

    # Set Variables token, organization and PATH for cloc binary
    #--------------------------------------------------------------------------------------#
    $connectionToken=$args[0]
    $organization=$args[1]
    $CLOCPATH=$args[2]

    # Test if request for for 1 Project or more Project 
    if ($args.Length -eq 4) {
      $Project=$args[3]
      $GetAPI="${organization}/_apis/projects/${Project}?api-version=7.0"
    } else {
         $GetAPI="${organization}/_apis/projects?api-version=7.0"
    }

    if(Test-Path $CLOCPATH) {

      # Encode Authentification Token
      $base64AuthInfo= [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(":$($connectionToken)"))
      # Set API URL to Get Project
      $ProjectUrl = "${BaseAPI}/${GetAPI}" 
      # Get List of Project
      $Projects = (Invoke-RestMethod -Uri $ProjectUrl -Method Get -UseDefaultCredential -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)})
      # Get Number of Repositories
      if ($args.Length -eq 4) { $NumberProjects= $Projects.count }
      else { $NumberProjects= $Projects.value.count }

      Write-Host "`n Number of Project : ${NumberProjects} `n"

      # Parse Project : Get Repositories
      #--------------------------------------------------------------------------------------#

      for ($j=0; $j -lt $NumberProjects;$j++) {
       
        # Get Project Name and ID
        if ($args.Length -eq 4) { 
          $ProjectName= $Projects.name
          $IDProject=$Projects.id
        }
        else {
          $ProjectName= $Projects.value[$j].name
          $IDProject=$Projects.value[$j].id
        }
        Write-Host "--------------------------------------------------------------------------------------"
        Write-Host "`n Project Number :$j  Name : $ProjectName id : $IDProject`n"
     
        # Set API URL to Get Repo
    
        $ProjetRepoUrl1="${BaseAPI}/${organization}/${ProjectName}/_apis/git/repositories?api-version=7.0"
       # [uri]::EscapeDataString( $ProjetBranchUrl)
        $ProjetRepoUrl= $ProjetRepoUrl1.replace(" ","%20")

        # Get List of Repositories
        try {
         $Repo = (Invoke-RestMethod -Uri $ProjetRepoUrl -Method Get -UseDefaultCredential -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)})
        } Catch {
            if($_.ErrorDetails.Message) {
              # Write-Host $_.ErrorDetails.Message
            } else {
              # Get Number of Repo
               $NumberRepo=$Repo.value.count
            }
         }
        $NumberRepo=$Repo.value.count
     
        # Parse Repositories
        #--------------------------------------------------------------------------------------#

        for ($i = 0; $i -lt $NumberRepo; $i++) {

             # Get Repositorie Name and ID
            if ($args.Length -eq 4) { 
                 $RepoName= $Repo.value[$i].name
                 $IDrepo=$Repo.value[$i].id
             }
                else {
                        $RepoName= $Repo.value[$i].name
                        $IDrepo=$Repo.value[$i].id
                }
          Write-Host "--------------------------------------------------------------------------------------"
          Write-Host "`n Repository Number :$i  Name : $RepoName id : $IDrepo`n"
       
          # Set API URL to Get Branches
          $ProjetBranchUrl1="${BaseAPI}/${organization}/${ProjectName}/_apis/git/repositories/${IDrepo}/refs?filter=heads/&api-version=7.0"
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
       
          # Parse Repositories/Branches 
          #--------------------------------------------------------------------------------------#
          
          for ($i2 = 0; $i2 -lt $NumberBranch; $i2++) { 

             # Get Branche Name 
            $BranchePathName=$Branch.value[$i2].name.replace('refs/heads/','')
            $BranchList= $Branch.value[$i2].name.Split("/")
            $BrancheName=$BranchList[$BranchList.count -1 ]
         
        
            # Clone Repository locally
            Write-Host "`n      Branche Name : ${RepoName}/${BrancheName} `n"
            $remoteUrl="https://${connectionToken}@dev.azure.com/${organization}/${ProjectName}/_git/${RepoName}"
            # Create Commad Git clone and replace space by %20
            $RepoName2=$RepoName.replace(" ","_").replace("/","_") 

            if (Test-Path -Path $RepoName2) {
                Remove-Item $RepoName2 -Recurse -Force
            } else {}
            $cmdline0=" git clone '" + $remoteUrl.replace(" ","%20") + "' --depth 1 --branch '" + $BranchePathName + "' " + $RepoName2
            Invoke-Expression -Command $cmdline0  

            # Run Analyse : run cloc on the local repository
            Write-Host "Analyse Counting ${RepoName}/${BrancheName}"
            $cmdparms2="${RepoName2} --force-lang-def=sonar-lang-defs.txt --ignore-case-ext --report-file=${RepoName2}_${BrancheName}.cloc  --timeout 0"
            $cmdline2=$CLOCPATH + " " + $cmdparms2
            Invoke-Expression -Command $cmdline2

            If ( -not (Test-Path -Path ${RepoName2}_${BrancheName}.cloc) )  {
             "0 Files Analyse in ${RepoName2}/${BrancheName}" | Out-File ${RepoName2}_${BrancheName}.cloc
            }
         
            # Generate report
            "Result Analyse Counting ${RepoName2} / ${BrancheName}" | Out-File -Append "${RepoName2}.txt"
            Get-content ${RepoName2}_${BrancheName}.cloc | Out-File -Append "${RepoName2}.txt"
        }   
        
      }
         #--------------------------------------------------------------------------------------#

        Write-Host "`nBuilding final report for projet $ProjectName : $ProjectName.txt"


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

