/**
* @author        Paul Jarred Aguiling
* @date          12.06.2017           
* @description   Controller for TS_EmailUtilityLink that is use to display generated links
* @revision(s)
*/
public with sharing class TS_EmailUtilityLinkController {
	public List<ContentDistribution>  contentList { get; set; }
	public String recordId { get; set; }
    public static Boolean hasException = false;
    public class TS_EmailUtilityLinkControllerException extends Exception {  }
    
	/**
	* @author        Paul Jarred Aguiling
	* @date          12.06.2017           
	* @description   Constructor of the class
	* @revision(s)
	*/
	public TS_EmailUtilityLinkController() {
        CustomLogging.push('TS_EmailUtilityLinkController', 'TS_EmailUtilityLinkController');
        
        try{
            contentList = new List<ContentDistribution>();
            contentList = [SELECT Id, Name, DistributionPublicUrl FROM ContentDistribution WHERE RelatedRecordId =: recordId AND ContentVersionId != NULL];
            
            //Exception for test class purposes
            if (Test.isRunningTest() && hasException) {
                throw new TS_EmailUtilityLinkControllerException('Force to throw an exception');
            }
        }
        catch(Exception ex){
            CustomLogging.debugException(ex);
            CustomLogging.pop();
        }
        
        CustomLogging.pop();
	}
}