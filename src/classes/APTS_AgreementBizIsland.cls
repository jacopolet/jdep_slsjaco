/**********************************************************************************
 * @Author: Keerthana
 * @Company: Accenture
 * @Description: Handles the Contents/file creation for Bizisland Agreement
 * @Created Date: Oct 9, 2018
 * @History:
 *      <Name>              <Date>          <Description>
 *      Keerthana              10.09.2018       Created
 **********************************************************************************/
global class APTS_AgreementBizIsland implements Database.Batchable<sObject>, Database.Stateful {
   
    global String csvColumnHeader;
    global List<String> csvRowValues = new List<String>();
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        Bonsai__c customSetting = Bonsai__c.getAll().values();
        String query;
        if(customSetting.Delta_Load__c){
            APTS_BizIsland__mdt bizmdt = [Select APTS_Query__c from APTS_BizIsland__mdt where DeveloperName= :'AgreementBizIslandDelta'][0];
            query = bizmdt.APTS_Query__c; 
        }else if(customSetting.Full_Load__c){
            APTS_BizIsland__mdt bizmdt = [Select APTS_Query__c from APTS_BizIsland__mdt where DeveloperName= :'AgreementBizIslandFull'][0];
            query = bizmdt.APTS_Query__c;
        }else{
            APTS_BizIsland__mdt bizmdt = [Select APTS_Query__c from APTS_BizIsland__mdt where DeveloperName= :'AgreementBizIslandDelta'][0];
            query = bizmdt.APTS_Query__c;
        }
            return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope){
        String status;
        String salesorg = '';
        String disChan = '';
        String agrname='';
        Pattern p = Pattern.compile('[^0-9]');
        for(Apttus__APTS_Agreement__c agr : (List<Apttus__APTS_Agreement__c>) scope){
            if(agr.CreatedDate.date()==System.Today())
            Status = 'New';
            else if(agr.LastModifiedDate.date() ==System.Today())
            Status='Modified';
            else 
            Status='Not Modified';
            if((Status == 'Modified' || Status == 'New') && agr.isDeleted == true)
            Status = 'Deleted';
            
            if(agr.APTS_Region__c != NULL && agr.APTS_Region__c.contains('SAP_')){
                salesorg = agr.APTS_Region__c.replace('SAP_','');
            }else if(agr.APTS_Region__c != NULL){
                salesorg = agr.APTS_Region__c;
            }
            if(agr.APTS_Sold_To__r.Distribution_Channel__c != NULL && agr.APTS_Sold_To__r.Distribution_Channel__c.contains('SAP_')){
                disChan =agr.APTS_Sold_To__r.Distribution_Channel__c.replace ('SAP_','');
                }
                else if(agr.APTS_Sold_To__r.Distribution_Channel__c != NULL){
                disChan = agr.APTS_Sold_To__r.Distribution_Channel__c;
            }
            
              if(agr.Name != NULL && agr.Name.contains(',')){
                agrname= agr.Name.replace(',','.');
            }else if (agr.Name!= NULL){
                agrname = agr.Name;
            }  
                
                String rowStrn = salesorg+','+disChan+','+agr.Apttus__FF_Agreement_Number__c+','+agrname+','+Status;
                csvRowValues.add(rowStrn);
                salesorg = '';
                disChan = '';
                agrname ='';
        }
    
    }
    global void finish(Database.BatchableContext BC){
                Bonsai__c cs = Bonsai__c.getAll().values();
                Date d=system.today();
                String Bon='Bonsai Request'+' '+d;
                list<BizIsland_Request__c> biz=[ SELECT Id, Name,Version__c FROM BizIsland_Request__c where name=:Bon];
                if(!biz.isEmpty()){
                csvColumnHeader ='Sales Organization,Distribution Channel,Agreement Number,Agreement Name,Status\n';
                String csvFile = csvColumnHeader + String.join(csvRowValues,'\n');
                APTS_BizIslandContentGenerator bizz=new APTS_BizIslandContentGenerator();
                    if(cs.Delta_Load__c){
                        String documentName = 'DELTA REPORT AGRMNT_TO_BONSAI';
                        bizz.addAttachmentsToBonsai(biz[0],csvFile,documentName);
                    }else if(cs.Full_Load__c){
                        String documentName = 'FULL REPORT AGRMNT_TO_BONSAI';
                        bizz.addAttachmentsToBonsai(biz[0],csvFile,documentName);
                    }
                    APTS_CERBizIsland cer = new APTS_CERBizIsland();
                    Database.executeBatch(cer,100);
                    }
            
        }
    }