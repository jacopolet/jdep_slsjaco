/**
 * Created by ataullah.a.khan on 21-2-2019.
 */

public without sharing class TS_PDFContentEmailLink_Controller {
    public static Boolean hasException = false;
    public class TS_PDFContentEmailLink_ControllerException extends Exception {  }

    public ContentDistribution  getcontent (){
        CustomLogging.push('getcontent', 'TS_PDFContentEmailLink_Controller');
        List <ContentDistribution> cdr_list = new List <ContentDistribution> () ;

        try{
            if (WoliID!=null&&!WoliID.equals('')) {
                System.debug('fileName::'+fileName);
                System.debug('WoliID::'+WoliID);
                List <ContentDocumentLink> cdl_list = [select id, contentdocumentid from contentdocumentlink where linkedentityid = :WoliID ];
                Set<id> cd_id_set = new set<id>();
                System.debug('cdl_list:::'+cdl_list);
                if (cdl_list!=null && cdl_list.size() >0){
                    for (contentdocumentlink cdl:cdl_list){
                        cd_id_set.add(cdl.contentdocumentid);
                    }
                    list <ContentVersion> cv_list = [select id from ContentVersion where contentdocumentid in :cd_id_set];
                    System.debug('cv_list::'+cv_list);
                    Set<id> cv_id_set = new set<id>();
                    if (cv_list!=null && cv_list.size()>0) {
                        for (ContentVersion cv:cv_list){
                            cv_id_set.add(cv.id);
                        }
                        cdr_list  = [select id, Name, DistributionPublicUrl,PdfDownloadUrl from contentdistribution where contentversionid in : cv_id_set];
                    }
                    System.debug('cdr_list::'+cdr_list);
                }
            }

            //Exception for test class purposes
            if (Test.isRunningTest() && hasException) {
                throw new TS_PDFContentEmailLink_ControllerException('Force to throw an exception');
            }
        }
        catch(Exception ex){
            CustomLogging.debugException(ex);
            CustomLogging.pop();
        }

        CustomLogging.pop();
        ContentDistribution conDist = new ContentDistribution();
        If(cdr_list != null && cdr_list.size() > 0){
            for(ContentDistribution c:cdr_list){
                if(c.Name.contains(fileName)){
                    conDist= c;
                    break;
                }
            }
        }

        return conDist;
    }

    public String WoliID {get; set;}
    public String fileName {get; set;}

    public TS_PDFContentEmailLink_Controller() {
        //contentdistributionList = new List<ContentDistribution>;
    }

}