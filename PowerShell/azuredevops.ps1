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
    [string[]]$Paths
  )
  
  foreach ($Path in $Paths) { 
    if (Test-Path -Path $Path) {
      Remove-Item $Path -Recurse -Force
    }
  }
}

# Set Variables CLOCBr (object: [NBR_LINE_CODE][BRANCHE_NAME]), cpt, NBCLOC, BaseAPI
$CLOCBr = @([PSCustomObject]@{ })
$NBCLOC = "Report_cpt.txt"
$cpt = 0
$BaseAPI = "https://dev.azure.com"

if ($args.Length -lt 3) {
  Write-Output ('Usage: azuredevops.ps1 <token> <org> <PATH for cloc binary> optional <projects>')
} else {

  # Set Variables token, organization and PATH for cloc binary and Language Environment
  $connectionToken = $args[0]
  $organization = $args[1]
  $CLOCPATH = $args[2]

  # Set Language en-US
  Set-CultureWin en-US 

  # Remove cpt.txt file
  Remove-Files $NIBLOC
    
  # Test if request for for 1 Project or more Project 
  if ($args.Length -eq 4) {
    $Project = $args[3]
    $GetAPI = "${organization}/_apis/projects/${Project}?api-version=7.0"
  } else {
    $GetAPI = "${organization}/_apis/projects?api-version=7.0"
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
      $NumberOfProjects = @($Projects).count 
    } else { 
      $NumberOfProjects = $Projects.value.count 
    }

    Write-Host "Number of projects : ${NumberOfProjects} for Organization : ${organization}`n"

    # Parse Project : Get Repositories
    for ($i=0; $i -lt $NumberOfProjects; $i++) {
      # Get Project Name and ID
      if ($args.Length -eq 4) { 
        $ProjectName = $Projects.name
        $IDProject = $Projects.id
      } else {
        $ProjectName = $Projects.value[$i].name
        $IDProject = $Projects.value[$i].id
      }
      Write-Host "--------------------------------------------------------------------------------------"
      Write-Host "Project name : ${ProjectName}"
      Write-Host "Project Id : ${IDProject}"
      
      # Set API URL to Get Repo
      $ProjectRepoUrl = "${BaseAPI}/${organization}/${ProjectName}/_apis/git/repositories?api-version=7.0"
      # [uri]::EscapeDataString( $ProjetBranchUrl)
      $ProjectRepoUrl = $ProjectRepoUrl.replace(" ","%20")
      
      # Get List of Repositories
      try {
        $Repo = (Invoke-RestMethod -Uri $ProjectRepoUrl -Method Get -UseDefaultCredential -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)})
      } catch {
        if($_.ErrorDetails.Message) {
          Write-Host $_.ErrorDetails.Message
        } else {
          # Get Number of Repo
          $NumberOfRepos=$Repo.value.count
        }
      }

      $NumberOfRepos = $Repo.value.count
      Write-Host "`nNumber of repositories : ${NumberOfRepos}`n"
      
      for ($j = 0; $j -lt $NumberOfRepos; $j++) {
        # Get Repositorie Name and ID
        if ($args.Length -eq 4) { 
          $RepoName = $Repo.value[$j].name
          $IDrepo = $Repo.value[$j].id
        } else {
          $RepoName = $Repo.value[$j].name
          $IDrepo = $Repo.value[$j].id
        }
        Write-Host "`n--------------------------------------------------------------------------------------"
        Write-Host "Repository name: ${RepoName}"
        Write-Host "Repository Id : $IDrepo"
        
        # Set API URL to Get Branches
        $ProjetBranchUrl1="${BaseAPI}/${organization}/${ProjectName}/_apis/git/repositories/${IDrepo}/refs?filter=heads/&api-version=7.0"
        # [uri]::EscapeDataString( $ProjetBranchUrl)
        $ProjetBranchUrl= $ProjetBranchUrl1.replace(" ","%20")
    
        # Get List of Branches
        try {
          $Branch = (Invoke-RestMethod -Uri $ProjetBranchUrl -Method Get -UseDefaultCredential -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)})
        } catch {
          if($_.ErrorDetails.Message) {
            Write-Host $_.ErrorDetails.Message
          } else {
            # Get Number of Branches
            $NumberOfBranches=$Branch.value.count
          }
        }
        $NumberOfBranches=$Branch.value.count
        Write-Host "Number of branches : ${NumberOfBranches}"
            
        if($NumberOfBranches -gt 0) {             
          # Parse Repositories/Branches 
          for ($z = 0; $z -lt $NumberOfBranches; $z++) { 
            # Get Branch Name 
            $BranchPathName = $Branch.value[$z].name.replace('refs/heads/','')
            $BranchList = $Branch.value[$z].name.Split("/")
            $BranchName = $BranchList[$BranchList.count -1 ]

            # Clone Repository locally
            $remoteUrl="https://${connectionToken}@dev.azure.com/${organization}/${ProjectName}/_git/${RepoName}"
            # Create Commad Git clone and replace space by %20
            $RepoName=$RepoName.replace(" ","_").replace("/","_") 
            
            # BugFix : filename too long
            $cmdline = "git clone -c core.longpaths=true '" + $remoteUrl.replace(" ","%20") + "' --depth 1 --branch '" + $BranchPathName + "' " + $RepoName
            Invoke-Expression -Command $cmdline

            # Run Analyse : run cloc on the local repository
            Write-Host "`nAnalyse branch ${RepoName}/${BranchName}"
            $cmdparms="${RepoName} --force-lang-def=sonar-lang-defs.txt --ignore-case-ext --report-file=${RepoName}_${BranchName}.cloc  --timeout 0 --sum-one"

            $cmdline = $CLOCPATH + " " + $cmdparms
            Invoke-Expression -Command $cmdline
            if ( -not (Test-Path -Path ${RepoName}_${BranchName}.cloc) )  {
              "0 Files Analyse in ${RepoName}/${BranchName}" | Out-File ${RepoName}_${BranchName}.cloc
            }

            "Result Analyse Counting ${RepoName} / ${BranchName}" | Out-File -Append "Report_${RepoName}.txt"
            Get-Content ${RepoName}_${BranchName}.cloc | Out-File -Append "Report_${RepoName}.txt"
            
            # Remove local repo
            Remove-Files $RepoName
          }   
        }
      }

      Write-Host "`nBuilding final report for project $ProjectName : Report_$ProjectName.txt"

      Get-ChildItem -Path .\* -Include *.cloc |
        ForEach-Object { $NMCLOCB=Get-content $_.Name |
          Select-String "SUM:"; $NMCLOCB-replace "\s{2,}", " " | 
            ForEach-Object{
              $NMCLOCB1=$_.ToString().split(" ");
              $CLOCBr+=@([PSCustomObject]@{ 
                CLOC=$NMCLOCB1[4]; 
                BRANCH=${BranchName}
              })
            };
            Remove-Files $_.Name
        }
      $CLOCBr | Select-Object | Sort-Object -Property CLOC -OutVariable Sorted | Out-Null

      $clocmax=$($Sorted[0].CLOC -as [decimal]).ToString('N2')
      $Branchmax=$Sorted[0].BRANCH
      
      if ($NumberOfBranches -gt 0) {        
        # Reset object
        $CLOCBr=@([PSCustomObject]@{})
      } 

      if ($NumberOfBranches -eq 0) {
        Write-Host "-------------------------------------------------------------------------------------------------------"
        Write-Host "The maximum lines of code in the ${RepoName} project is : < $clocmax >"
        Write-Host "-------------------------------------------------------------------------------------------------------"
        "-------------------------------------------------------------------------------------------------------"| Out-File -Append "Report_${RepoName}.txt"
        "The maximum lines of code in the ${RepoName} project is : < $clocmax > `n"| Out-File -Append "Report_${RepoName}.txt"
        "-------------------------------------------------------------------------------------------------------"| Out-File -Append "Report_${RepoName}.txt"
      } else {
        Write-Host "-------------------------------------------------------------------------------------------------------"
        Write-Host "The maximum lines of code in the ${RepoName} project is : < $clocmax > for the branch : $Branchmax"
        Write-Host "-------------------------------------------------------------------------------------------------------"
        "-------------------------------------------------------------------------------------------------------"| Out-File -Append "Report_${RepoName}.txt"
        "The maximum lines of code in the ${RepoName} project is : < $clocmax > for the branch : $Branchmax `n"| Out-File -Append "Report_${RepoName}.txt"
        "-------------------------------------------------------------------------------------------------------"| Out-File -Append "Report_${RepoName}.txt"          
      }

      $clocmax | Out-File -Append "$NBCLOC"
    }  
    
    #--------------------------------------------------------------------------------------#
    # Generate Gobal report
    #--------------------------------------------------------------------------------------#
    if (Test-Path -Path $NBCLOC) {
      foreach($line in Get-Content .\${NBCLOC}) {
        $cpt=$cpt+$line    
      }
      $cpt=$($cpt -as [decimal]).ToString('N2')

      Write-Host "`n-------------------------------------------------------------------------------------------------------"
      Write-Host "The maximum lines of code on the organization is : < $cpt > result in <Report_global.txt>"
      Write-Host "-------------------------------------------------------------------------------------------------------"
      "-------------------------------------------------------------------------------------------------------n" | Out-File -Append "Report_global.txt"
      "`nThe maximum lines of code on the organization is : < $cpt >`n"| Out-File -Append "Report_global.txt"
      "-------------------------------------------------------------------------------------------------------" | Out-File -Append "Report_global.txt"
    }
    #--------------------------------------------------------------------------------------#
  } else {
    Write-Host "Error : PATH for cloc binary is wrong"
  }
}