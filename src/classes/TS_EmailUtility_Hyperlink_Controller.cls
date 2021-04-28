/**
* @author        Archi Delphinanto
* @date          9.25.2017          
* @description   Controller class for TS_EmailUtility_Hyperlink
* @revision(s)   
*/
public with sharing class TS_EmailUtility_Hyperlink_Controller {
	public List<ContentDistribution>  contentList { get; set; }
	public boolean showAsPDF { get; set; }
    public static Boolean hasException = false;
    public class TS_EmailUtility_Hyperlink_ControllerException extends Exception {  }
    
	public TS_EmailUtility_Hyperlink_Controller() {
        CustomLogging.push('execute', 'ScheduleApiLogin');
        
        try{
            showAsPDF = true;
            Id linkEntityID = ApexPages.currentPage().getParameters().get('id');
            String sPDF = ApexPages.currentPage().getParameters().get('showAsPDF');
            
            if (sPDF!=null && sPDF.equals('false')){
                showAsPDF = false;
            }
            
            contentList = [Select Id, Name,  DistributionPublicUrl from ContentDistribution where RelatedRecordId =:  linkEntityID];
            
            //Exception for test class purposes
            if (Test.isRunningTest() && hasException) {
                throw new TS_EmailUtility_Hyperlink_ControllerException('Force to throw an exception');
            }
        }
        catch(Exception ex){
            CustomLogging.debugException(ex);
            CustomLogging.pop();
        }
        
        CustomLogging.pop();
	}
}