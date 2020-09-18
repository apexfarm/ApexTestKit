sfdx force:package:version:create -p ApexTestKit -x -c --wait 10
sfdx force:package:version:list
sfdx force:package:version:promote -p 04t2v000007GQuwAAG
sfdx force:package:version:report -p 04t2v000007GQuwAAG