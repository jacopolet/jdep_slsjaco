/**********************************************************************************
 * @Author: Shahul
 * @Company: Accenture
 * @Description: Handles the Contents/file creation for Bizisland Account
 * @Created Date: Oct 4, 2018
 * @History:
 *      <Name>              <Date>          <Description>
 *      Shahul              10.04.2018       Created
 *      Keerthana           06.02.2019       v101-Defect 24391,Added agreement Mapping for Parent Account If child account doesn't have any agreement
 *      Mahesh              09.04.2019       v102-Defect 6626, Added agreement mapping condition to capture parent or self level agreement number.     
 * **********************************************************************************/
 global class APTS_AccountBizIsland implements Database.Batchable<sObject>, Database.Stateful {
   
    global String csvColumnHeader;
    global List<String> csvRowValues = new List<String>();

    global Database.QueryLocator start(Database.BatchableContext BC){

        Bonsai__c customSetting = Bonsai__c.getAll().values();
        String query;

        if(customSetting.Delta_Load__c){
            APTS_BizIsland__mdt bizmdt = [Select APTS_Query__c from APTS_BizIsland__mdt where DeveloperName= :'AccountDelta'][0];
            query = bizmdt.APTS_Query__c; 
        }else if(customSetting.Full_Load__c){
            APTS_BizIsland__mdt bizmdt = [Select APTS_Query__c from APTS_BizIsland__mdt where DeveloperName= :'AccountFull'][0];
            query = bizmdt.APTS_Query__c;
        }else{
            APTS_BizIsland__mdt bizmdt = [Select APTS_Query__c from APTS_BizIsland__mdt where DeveloperName= :'AccountDelta'][0];
            query = bizmdt.APTS_Query__c;
        }
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope){
        String Status;
        String salesorg = '';
        String disChan = '';
        String agreementNumber='';
        String address ='';
        String customername ='';
        string customernameline ='';
        string customercity='';
        string Pricelist='';
        Map<Id,Apttus__APTS_Agreement__c> agreementmap = new Map<Id,Apttus__APTS_Agreement__c>();
        Set<Id> parentId = new Set<Id>();
        // Retrieve all related Parent Id
        for (Account oAccount : (List<Account>) scope){
            //v102 - Start
            if(oAccount.APTS_Bonsai_ID_Level__c != ''){
                parentId.add(oAccount.id);
            }
            else if(oAccount.ParentId != null && oAccount.APTS_Bonsai_ID_Level__c == '') {
                parentId.add(oAccount.ParentId);
            }
           //v102 - End.
        }

        if(!parentId.isEmpty()){
             //v102 - Start
            for (Apttus__APTS_Agreement__c agreement : [SELECT Id,
                                                                APTS_Sold_To__c,
                                                                Apttus__FF_Agreement_Number__c
                                                            FROM Apttus__APTS_Agreement__c
                                                            WHERE APTS_Sold_To__c IN: parentId AND 
                                                                  Apttus__Status_Category__c = 'In Effect' AND
                                                                  Apttus__Status__c = 'Activated'
                                                          LIMIT 50000]) {
                //v102 - End.
                //v101 - Start
                if(!agreementmap.isEmpty() && !agreementmap.containsKey(agreement.APTS_Sold_To__c)){
                    agreementmap.put(agreement.APTS_Sold_To__c,agreement);
                }
                else if(agreementmap.isEmpty()) {
                    agreementmap.put(agreement.APTS_Sold_To__c,agreement);
                }
                //v101 - End
            }
        }
        
        for(Account a : (List<Account>) scope) {
        
           //v101, v102 - Start
           if(agreementmap.containskey(a.ParentId) && string.isBlank(a.APTS_Bonsai_ID_Level__c)) {
                agreementNumber = agreementmap.get(a.ParentId).Apttus__FF_Agreement_Number__c ;
            }
            else if(agreementmap.containskey(a.Id)) {
                agreementNumber = agreementmap.get(a.Id).Apttus__FF_Agreement_Number__c ;  
            }       

            //v101, v102 - End
      

            if(a.CreatedDate.date() ==System.Today())
                Status = 'New';
            else if(a.LastModifiedDate.date() ==System.Today())
                Status='Modified';
            else 
                Status='Not Modified';
            
            if((Status == 'Modified' || Status == 'New') && a.isDeleted == true)
                Status = 'Deleted';
            
            if(a.Sales_Organization__c != NULL && a.Sales_Organization__c.contains('SAP_')){
                salesorg =a.Sales_Organization__c.replace('SAP_',''); 
            }else if(a.Sales_Organization__c != NULL){
                salesorg = a.Sales_Organization__c;}                               
                    
            if(a.Distribution_Channel__c != NULL && a.Distribution_Channel__c.contains('SAP_')){
                disChan =a.Distribution_Channel__c.replace('SAP_','');
            }else if(a.Distribution_Channel__c != NULL){
                disChan =a.Distribution_Channel__c; }
            
            if(a.Main_Street_Only__c != NULL && a.Main_Street_Only__c.contains(',')){
                  address= a.Main_Street_Only__c.replace(',','.');
                  }else if(a.Main_Street_Only__c != NULL){
                  address =a.Main_Street_Only__c;}  
           
            if(a.Second_Account_Name__c != NULL && a.Second_Account_Name__c.contains(',')){
                  customernameline = a.Second_Account_Name__c.replace(',','.');
                  }else if(a.Second_Account_Name__c != NULL){
                  customernameline =a.Second_Account_Name__c;} 
                  
            if(a.Name != NULL && a.Name.contains(',')){
                  customername= a.Name.replace(',','.');
                  }else if(a.Name != NULL){
                  customername =a.Name;
                  } 
                  
                  if(a.Main_City__c != NULL && a.Main_City__c.contains(',')){
                  customercity= a.Main_City__c.replace(',','.');
                  }else if(a.Main_City__c != NULL){
                  customercity =a.Main_City__c; } 
                  
                 if(a.Sales_Office__c != NULL && a.Sales_Office__c.contains('SAP_')){
                Pricelist =a.Sales_Office__c.replace('SAP_','');
            }else if(a.Sales_Office__c != NULL){
                Pricelist =a.Sales_Office__c; }
                  
                  
            String rowStr =salesorg+','+disChan+','+a.SAP_Customer_ID__c+','+customername+','+customernameline+','+address+','+a.Account_Address__c+','+a.Main_Postal_Code__c+','+customercity+','+a.Phone+','+a.Email__c+','+a.APTS_Free_Freight_Charges__c+','+agreementNumber+','+a.CurrencyIsoCode+','+Pricelist+','+a.Apttus_Config2__TaxExempt__c+','+Status;
            csvRowValues.add(rowStr);
            salesorg ='';
            disChan ='';
            agreementNumber='';
            address='';
            customername ='';
            customernameline ='';
            customercity='';
            Pricelist='';
        }
    }

    global void finish(Database.BatchableContext BC){
   
        Bonsai__c cs = Bonsai__c.getAll().values();
        Date d=system.today();
        String Bon='Bonsai Request'+' '+d;
        list<BizIsland_Request__c> biz=[ SELECT Id, Name,Version__c FROM BizIsland_Request__c where name=:Bon];
        
        if(!biz.isEmpty()){
            csvColumnHeader ='Sales Organization,Distribution Channel,Customer Number,Customer Name,Customer Name Line2,Customer Address,Customer Address Line2,Zip Code,City,Phone,Company Email,Customer Handling Fee,Agreement Number,Customer Currency,Price List Type,Coffee Tax Applicable,Status\n';
            String csvFile =csvColumnHeader +String.join(csvRowValues,'\n');
            APTS_BizIslandContentGenerator bizz=new APTS_BizIslandContentGenerator();
            if(cs.Delta_Load__c){
                String documentName = 'DELTA REPORT CUSTS_TO_BONSAI';
                bizz.addAttachmentsToBonsai(biz[0],csvFile,documentName);
            }else if(cs.Full_Load__c){
                String documentName = 'FULL REPORT CUSTS_TO_BONSAI';
                bizz.addAttachmentsToBonsai(biz[0],csvFile,documentName);}
            
            APTS_ProductBizIsland prd = new APTS_ProductBizIsland();
            Database.executeBatch(prd,200); 
        } 
    }
}