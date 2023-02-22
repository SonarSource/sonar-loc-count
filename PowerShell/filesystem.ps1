#******************************************************************#
#                                                                  #
#  @project     : LoC Counting PowerShell Scripts                  #
#  @package     :                                                  #
#  @subpackage  : filesystem.ps1                                   #
#  @access      :                                                  #
#  @paramtype   : connectionToken,organization,cloc PATH           #
#  @argument    :                                                  #
#  @description : Get Number ligne of Code in local Directory      #
#  @usage : ./filesystem.ps1 <directory> <PATH for cloc binary>    #                                                              
#                                                                  #
#                                                                  #
#  @author Emmanuel COLUSSI                                        #
#  @version 1.01                                                   #
#******************************************************************#


if ($args.Length -lt 2) {
  Write-Output ('Usage: filesystem.ps1 <directory> <PATH for cloc binary>')
} 
else {
      $CLOCPATH=$args[1] 
      $directory=$args[0]

      if (Test-Path -Path $args[0]) {
        if((Test-Path $CLOCPATH) || (Test-Path ($CLOCPATH+".exe"))) {
            $repname=Split-Path -Path $args[0] -Leaf
             # Run Analyse : run cloc on the local repository
            $cmdparms2="--force-lang-def=sonar-lang-defs.txt --ignore-case-ext --report-file="+$repname +".cloc " + $directory
            $cmdline2=$CLOCPATH + " " + $cmdparms2
            Write-Host "Analyse Counting ${directory}"
            Invoke-Expression -Command $cmdline2

            Write-Host "----------------------------------------------"
            Write-Host "The Analyse Result is in ${repname}.cloc file"
            Write-Host "----------------------------------------------"
        }    
        else {
              Write-Host "Error : PATH for cloc binary is wrong"
        }
      } 
      else {
         Write-Host 'Path :'$args[0] 'not exist.'
      }
} 

