public with sharing class TS_TaskClosureEmailLink_Controller {
    public static Boolean hasException = false;
    public class TS_TaskClosureEmailLink_ControllerException extends Exception {  }
    
    public List<ContentDistribution>  getcontentdistributionList (){
        CustomLogging.push('getcontentdistributionList', 'TS_TaskClosureEmailLink_Controller');
        List <ContentDistribution> cdr_list = new List <ContentDistribution> () ;
        
        try{
            if (WoliID!=null&&!WoliID.equals('')) {
                
                List <ContentDocumentLink> cdl_list = [select id, contentdocumentid from contentdocumentlink where linkedentityid = :WoliID ];
                Set<id> cd_id_set = new set<id>(); 
                
                
                if (cdl_list!=null && cdl_list.size() >0) {
                    for (contentdocumentlink cdl:cdl_list){
                        cd_id_set.add(cdl.contentdocumentid);
                    }
                    list <ContentVersion> cv_list = [select id from ContentVersion where contentdocumentid in :cd_id_set];
                    Set<id> cv_id_set = new set<id>(); 
                    if (cv_list!=null && cv_list.size()>0) {
                        for (ContentVersion cv:cv_list){
                            cv_id_set.add(cv.id);
                        }				
                        cdr_list  = [select id, Name, DistributionPublicUrl,PdfDownloadUrl from contentdistribution where contentversionid in : cv_id_set];
                    }
                    
                }
                
            }
            
            //Exception for test class purposes
            if (Test.isRunningTest() && hasException) {
                throw new TS_TaskClosureEmailLink_ControllerException('Force to throw an exception');
            }
        }
        catch(Exception ex){
            CustomLogging.debugException(ex);
            CustomLogging.pop();
        }
        
        CustomLogging.pop();
        return cdr_list; 
    }
    
    
    
    
    public String WoliID { get; set; }
    
    public TS_TaskClosureEmailLink_Controller() {
        //contentdistributionList = new List<ContentDistribution>;
    }
    
}