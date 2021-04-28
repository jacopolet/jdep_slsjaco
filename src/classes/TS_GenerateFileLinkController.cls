public with sharing class TS_GenerateFileLinkController {
    public List<ContentDistribution>  contentList { get; set; }
    public String recordId { get; set; }
    public static Boolean hasException = false;
    public class TS_GenerateFileLinkControllerException extends Exception {  }
    
    public TS_GenerateFileLinkController() {
        CustomLogging.push('TS_GenerateFileLinkController', 'TS_GenerateFileLinkController');
        
        try{
            contentList = [Select Id, Name, DistributionPublicUrl from ContentDistribution where RelatedRecordId =:  recordId];
            
            //Exception for test class purposes
            if (Test.isRunningTest() && hasException) {
                throw new TS_GenerateFileLinkControllerException('Force to throw an exception');
            }
        }
        catch(Exception ex){
            CustomLogging.debugException(ex);
            CustomLogging.pop();
        }
        
        CustomLogging.pop();
    }
}