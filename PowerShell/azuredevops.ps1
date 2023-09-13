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
#  @version 1.03                                                                           #
#                                                                                          #
#******************************************************************************************#


# Set Language 
function Set-CultureWin([System.Globalization.CultureInfo] $culture) { 
  [System.Threading.Thread]::CurrentThread.CurrentUICulture = $culture ; [System.Threading.Thread]::CurrentThread.CurrentCulture = $culture 
} 

function Remove-Files {
  param (
    [string]$Path
  )
  
  Write-Host "Remote-Files"

  if (Test-Path -Path $Path) {
    Write-Host "`nRemove item : ${Path}"
    Remove-Item $Path -Recurse -Force
  } else {
    Write-Host "`nCant remove item : ${Path}"
  }
}

# Set Variables CLOCBr (object: [NBR_LINE_CODE][BRANCHE_NAME]), cpt, NBCLOC, BaseAPI
#--------------------------------------------------------------------------------------#
$CLOCBr=@([PSCustomObject]@{ })
$NBCLOC="cpt.txt"
$cpt=0
$BaseAPI="https://dev.azure.com"

if ($args.Length -lt 3) {
  Write-Output ('Usage: azuredevops.ps1 <token> <org> <PATH for cloc binary> optional <projects>')
} else {

  # Set Variables token, organization and PATH for cloc binary and Language Environment
  #--------------------------------------------------------------------------------------#
  $connectionToken=$args[0]
  $organization=$args[1]
  $CLOCPATH=$args[2]

  # Set Language en-US
  Set-CultureWin en-US 

  # Remove cpt.txt file
  Remove-Files $NIBLOC
  #if (Test-Path -Path $NBCLOC) {
  #  Remove-Item $NBCLOC -Recurse -Force    
  #}
    
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
    if ($args.Length -eq 4) { 
      $NumberProjects= @($Projects).count 
    } else { 
      $NumberProjects= $Projects.value.count 
    }

    Write-Host "Number of Project : ${NumberProjects} for Organization : $organization`n"

    # Parse Project : Get Repositories
    #--------------------------------------------------------------------------------------#

    for ($j=0; $j -lt $NumberProjects;$j++) {
    
      # Get Project Name and ID
      if ($args.Length -eq 4) { 
        $ProjectName= $Projects.name
        $IDProject=$Projects.id
      } else {
        $ProjectName= $Projects.value[$j].name
        $IDProject=$Projects.value[$j].id
      }
      Write-Host "--------------------------------------------------------------------------------------"
      Write-Host "Project Number:  $j"
      Write-Host "Name : $ProjectName"
      Write-Host "ID : $IDProject"
      
      # Set API URL to Get Repo
      $ProjetRepoUrl="${BaseAPI}/${organization}/${ProjectName}/_apis/git/repositories?api-version=7.0"
      # [uri]::EscapeDataString( $ProjetBranchUrl)
      $ProjetRepoUrl= $ProjetRepoUrl.replace(" ","%20")
      Write-Host "project repo url: ${ProjectRepoUrl}"
      # Get List of Repositories
      try {
        $Repo = (Invoke-RestMethod -Uri $ProjetRepoUrl -Method Get -UseDefaultCredential -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)})
      } catch {
        if($_.ErrorDetails.Message) {
          Write-Host $_.ErrorDetails.Message
        } else {
          # Get Number of Repo
          $NumberRepo=$Repo.value.count
        }
      }
      $NumberRepo=$Repo.value.count
      Write-Host "`nNumber of Repositories : ${NumberRepo}  for Project : ${ProjectName}`n"
      
      # Parse Repositories
      #--------------------------------------------------------------------------------------#
      for ($i = 0; $i -lt $NumberRepo; $i++) {

        # Get Repositorie Name and ID
        if ($args.Length -eq 4) { 
          $RepoName= $Repo.value[$i].name
          $IDrepo=$Repo.value[$i].id
        } else {
          $RepoName= $Repo.value[$i].name
          $IDrepo=$Repo.value[$i].id
        }
        Write-Host "--------------------------------------------------------------------------------------"
        Write-Host "Repository Number : $i"
        Write-Host "Name : $RepoName"
        Write-Host "ID : $IDrepo`n"
        
        # Set API URL to Get Branches
        $ProjetBranchUrl1="${BaseAPI}/${organization}/${ProjectName}/_apis/git/repositories/${IDrepo}/refs?filter=heads/&api-version=7.0"
        # [uri]::EscapeDataString( $ProjetBranchUrl)
        $ProjetBranchUrl= $ProjetBranchUrl1.replace(" ","%20")
    
        # Get List of Branches
        try {
          $Branch = (Invoke-RestMethod -Uri $ProjetBranchUrl -Method Get -UseDefaultCredential -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)})
        } catch {
          if($_.ErrorDetails.Message) {
            # Write-Host $_.ErrorDetails.Message
          } else {
            # Get Number of Branches
            $NumberBranch=$Branch.value.count
          }
        }
        $NumberBranch=$Branch.value.count
        Write-Host "`nNumber of Branches : ${NumberBranch} for Repository : ${RepoName}`n"
            
        if($NumberBranch -gt 0) {             
          # Parse Repositories/Branches 
          #--------------------------------------------------------------------------------------#  
          for ($i2 = 0; $i2 -lt $NumberBranch; $i2++) { 

            # Get Branch Name 
            $BranchPathName=$Branch.value[$i2].name.replace('refs/heads/','')
            $BranchList= $Branch.value[$i2].name.Split("/")
            $BranchName=$BranchList[$BranchList.count -1 ]
            Write-Host "Branch path name : ${BranchPathName}"         
            Write-Host "Branch list : ${BranchList}"         
            Write-Host "Branch name : ${BranchName}"         

            # Clone Repository locally
            Write-Host "`nBranch Name : ${RepoName}/${BranchName} `n"
            $remoteUrl="https://${connectionToken}@dev.azure.com/${organization}/${ProjectName}/_git/${RepoName}"
            # Create Commad Git clone and replace space by %20
            $RepoName2=$RepoName.replace(" ","_").replace("/","_") 

            Remove-Files $RepoName2
            # temp remote-repo
            #if (Test-Path -Path $RepoName2) {
            #  Write-Host "`nRemove item : ${RepoName2}"
            #  Remove-Item $RepoName2 -Recurse -Force
            #} else {
            #  Write-Host "`nCant remove item : ${RepoName2}"
            #}

            # fix : filename too long
            $cmdline0="git clone -c core.longpaths=true '" + $remoteUrl.replace(" ","%20") + "' --depth 1 --branch '" + $BranchPathName + "' " + $RepoName2
            Invoke-Expression -Command $cmdline0  

            # Run Analyse : run cloc on the local repository
            Write-Host "Analyse Counting ${RepoName}/${BranchName}"
            $cmdparms2="${RepoName2} --force-lang-def=sonar-lang-defs.txt --ignore-case-ext --report-file=${RepoName2}_${BranchName}.cloc  --timeout 0 --sum-one"
            $cmdline2=$CLOCPATH + " " + $cmdparms2
            Invoke-Expression -Command $cmdline2

            if ( -not (Test-Path -Path ${RepoName2}_${BranchName}.cloc) )  {
              "0 Files Analyse in ${RepoName2}/${BranchName}" | Out-File ${RepoName2}_${BranchName}.cloc
              Remove-Files RepoName2
              #if (Test-Path -Path $RepoName2) {
              #  Write-Host "`nRemoving local Repo : ${RepoName2}"
              #  Remove-Item $RepoName2 -Recurse -Force
              #}
            }

            # Generate report
            "Result Analyse Counting ${RepoName2} / ${BranchName}" | Out-File -Append "Report_${RepoName2}.txt"
            Get-Content ${RepoName2}_${BranchName}.cloc | Out-File -Append "Report_${RepoName2}.txt"
          }   
          #--------------------------------------------------------------------------------------#
        } else { 
          Write-Host "`nRepository has no branch`n" 
        }
      }
      #--------------------------------------------------------------------------------------#

      Write-Host "`nBuilding final report for projet $ProjectName : $ProjectName.txt"

      Get-ChildItem -Path .\* -Include *.cloc |
        ForEach-Object { 
          $NMCLOCB=Get-Content $_.Name |
            Select-String "SUM:";
          $NMCLOCB-replace "\s{2,}" , " "| 
            ForEach-Object{
              $NMCLOCB1=$_.ToString().split(" ");
              $CLOCBr+=@([PSCustomObject]@{ CLOC=$NMCLOCB1[4] ; BRANCH=${BranchName}})
            };
          Remove-Item $_.Name -Recurse -Force
        }
      $CLOCBr | Select-Object | Sort-Object -Property CLOC -Descending -OutVariable Sorted | Out-Null

      $clocmax=$($Sorted[0].CLOC -as [decimal]).ToString('N2')
      Write-Host "clocmax: ${clocmax}"
      $Branchmax=$Sorted[0].BRANCH
      Write-Host "branchmax: ${branchmax}"

      if ($NumberBranch -gt 0) {
        Remove-Files $RepoName
        # Remove local repos
        #if (Test-Path -Path $RepoName2) {
        #  Write-Host "`nRemoving local Repo : ${RepoName2}"
        #  Remove-Item $RepoName2 -Recurse -Force
        #} else {
        #  Write-Host "Cant remove repo : ${RepoName}"
        #}
        
        # Reset object
        $CLOCBr=@([PSCustomObject]@{ })
      }

      Write-Host "Branch number: ${NumberBranch}"
      if ($NumberBranch -eq 0) {
        $RepoName2=$RepoName
        Write-Host "-------------------------------------------------------------------------------------------------------"
        Write-Host "`nThe maximum lines of code in the ${RepoName2} project is : < $clocmax > `n"
        Write-Host "-------------------------------------------------------------------------------------------------------"
        "-------------------------------------------------------------------------------------------------------"| Out-File -Append "Report_${RepoName2}.txt"
        "The maximum lines of code in the ${RepoName2} project is : < $clocmax > `n"| Out-File -Append "${RepoName2}.txt"
        "-------------------------------------------------------------------------------------------------------"| Out-File -Append "Report_${RepoName2}.txt"
      } else {
        Write-Host "-------------------------------------------------------------------------------------------------------"
        Write-Host "`nThe maximum lines of code in the ${RepoName2} project is : < $clocmax > for the branch : $Branchmax `n"
        Write-Host "-------------------------------------------------------------------------------------------------------"
        "-------------------------------------------------------------------------------------------------------"| Out-File -Append "Report_${RepoName2}.txt"
        "The maximum lines of code in the ${RepoName2} project is : < $clocmax > for the branch : $Branchmax `n"| Out-File -Append "Report_${RepoName2}.txt"
        "-------------------------------------------------------------------------------------------------------"| Out-File -Append "Report_${RepoName2}.txt"          
      }

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
      Write-Host "`n-------------------------------------------------------------------------------------------------------"
      Write-Host  "`nThe maximum lines of code on the organization is : < $cpt > result in <Report_global.txt>`n"
      Write-Host  "`n-------------------------------------------------------------------------------------------------------"
      "-------------------------------------------------------------------------------------------------------n" | Out-File -Append "Report_global.txt"
      "`nThe maximum lines of code on the organization is : < $cpt >`n"| Out-File -Append "Report_global.txt"
      "-------------------------------------------------------------------------------------------------------" | Out-File -Append "Report_global.txt"
    }
    #--------------------------------------------------------------------------------------#
  } else {
    Write-Host "Error : PATH for cloc binary is wrong"
  }
}