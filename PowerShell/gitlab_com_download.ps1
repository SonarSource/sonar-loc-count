#**************************************************************************************************#
#                                                                                                  #
#  @project     : LoC Counting PowerShell Scripts                                                  #
#  @package     :                                                                                  #
#  @subpackage  : gitlab_com_download.ps1                                                                   #
#  @access      :                                                                                  #
#  @paramtype   : connectionToken,groupName or path_with_namespace                                 #
#  @argument    :                                                                                  #
#  @description : Get Number ligne of Code in GitLab DevOPS                                        #
#  @usage : ./gitlab_com.sh <token> <groupName>                                                    #                                                              
#                                                                                                  #
#                                                                                                  #
#  @author Sylvain COMBE                                                                        #
#  @version 1.0                                                                                   #
#                                                                                                  #
#**************************************************************************************************#


# Set Variables
#--------------------------------------------------------------------------------------#

$BaseAPI="https://gitlab.com/api/v4"

if ($args.Length -lt 2) {
  Write-Output ('Usage: gitlab_com_download.ps1 <token> <org>')
} 
else {

    # Set Variables token, organization and PATH for cloc binary
    #--------------------------------------------------------------------------------------#
    $connectionToken=$args[0]
    $groupname=$args[1]

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


      # Clone Repository locally
      Write-Host "`n      Branche Name : ${RepoName}/${BrancheName} `n"
      $Repourl=$Repourl.replace(" ","%20")
     
      # Create Command Git clone and replace space by %20
      $RepoName2=$RepoName.replace(" ","_").replace("/","_") 
      if (Test-Path -Path $RepoName2) {
          Remove-Item $RepoName2 -Recurse -Force
      } else {}
      $cmdline0=" git clone '" + $Repourl + "' " + $RepoName2
      Invoke-Expression -Command $cmdline0 
      #--------------------------------------------------------------------------------------#
    }
}

