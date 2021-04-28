/**********************************************************************************
* @Author: Keerthana
* @Company: Accenture
* @Description: Handles the Contents/file creation for Bizisland Product with level number
* @Created Date: Oct 10, 2018
* @History:
*      <Name>              <Date>          <Description>
*      Keerthana          10.10.2018       Created
**********************************************************************************/
global class APTS_ProductBizIslandlevel implements Database.Batchable<sObject>, Database.Stateful {
   
    global String csvColumnHeader;
    global List<String> csvRowValues = new List<String>();
   
    global Database.QueryLocator start(Database.BatchableContext BC){
        Bonsai__c customSetting = Bonsai__c.getAll().values();
        String query;
        if(customSetting.Delta_Load__c){
            APTS_BizIsland__mdt bizmdt = [Select APTS_Query__c from APTS_BizIsland__mdt where DeveloperName= :'ProductBizIslandlevelDelta'][0];
            query = bizmdt.APTS_Query__c; 
        }else if(customSetting.Full_Load__c){
            APTS_BizIsland__mdt bizmdt = [Select APTS_Query__c from APTS_BizIsland__mdt where DeveloperName= :'ProductBizIslandlevelFull'][0];
            query = bizmdt.APTS_Query__c;
        }else{
            APTS_BizIsland__mdt bizmdt = [Select APTS_Query__c from APTS_BizIsland__mdt where DeveloperName= :'ProductBizIslandlevelDelta'][0];
            query = bizmdt.APTS_Query__c;
        }
           return Database.getQueryLocator(query);
    }
      
    global void execute(Database.BatchableContext BC, List<sObject> scope){
        String Status;
        String prodname ='';
        //Decimal Level;
        for(Product2 pro : (List<Product2>) scope){
           
                    if(pro.CreatedDate.date()==System.Today())
                    Status = 'New';
                    else if(pro.LastModifiedDate.date() ==System.Today())
                    Status='Modified';
                    else 
                    Status='Not Modified';
                    if((Status == 'Modified' || Status == 'New') && pro.isDeleted == true)
                    Status = 'Deleted';
                    
                    if(pro.Name != NULL && pro.Name.contains(',')){
                     prodname= pro.Name.replace(',','.');
                    }else if (pro.Name!= NULL){
                    prodname = pro.Name;
                    }
                    String rowStrn = pro.APTS_Global_Product_Hierarchy__c+','+pro.APTS_Level_Number__c+','+prodname+','+Status;
                    csvRowValues.add(rowStrn);
                    prodname ='';
                    
                    
        }
   
    }
    
    global void finish(Database.BatchableContext BC){
        Bonsai__c cs = Bonsai__c.getAll().values();
        Date d=system.today();
        String Bon='Bonsai Request'+' '+d;
        list<BizIsland_Request__c> biz=[ SELECT Id, Name,Version__c FROM BizIsland_Request__c where name=:Bon];
        if(!biz.isEmpty()){
            csvColumnHeader ='Product Hierarchy,Level,Description,Status\n';
            String csvFile = csvColumnHeader + String.join(csvRowValues,'\n');
            APTS_BizIslandContentGenerator bizz=new APTS_BizIslandContentGenerator();
            if(cs.Delta_Load__c){
                String documentName = 'DELTA REPORT PRODH_TO_BONSAI';
                bizz.addAttachmentsToBonsai(biz[0],csvFile,documentName);
            }else if(cs.Full_Load__c){
                String documentName = 'FULL REPORT PRODH_TO_BONSAI';
                bizz.addAttachmentsToBonsai(biz[0],csvFile,documentName);
            }
 
            APTS_AgreementBizIsland agr = new APTS_AgreementBizIsland();
            Database.executeBatch(agr,200);
        }
            
    }
}