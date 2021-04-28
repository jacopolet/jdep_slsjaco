/**********************************************************************************
 * @Author: Lavanya Ravindran
 * @Company: Accenture
 * @Description: Handles the Contents/file creation for Bizisland Account
 * @Created Date: Oct 4, 2018
 * @History:
 *      <Name>              <Date>          <Description>
 *      Lavanya              10.04.2018       Created
 **********************************************************************************/
global class APTS_AgreementLineItemBizIsland implements Database.Batchable<sObject>,Database.Stateful{
    
    global String csvColumnHeader;
    global List<String> csvRowValues = new List<String>();
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        /* && Apttus__AgreementId__r.isBonsai__c=true  &&   AND (Apttus_CMConfig__LineType__c =\'Product/Service\' OR Apttus_CMConfig__HasOptions__c = false)*/
        Bonsai__c customSetting = Bonsai__c.getAll().values();
        String query;
        if(customSetting.Delta_Load__c){
            APTS_BizIsland__mdt bizmdt = [Select APTS_Query__c from APTS_BizIsland__mdt where DeveloperName= :'AgreementLineItemBizIslandDelta'][0];
            query = bizmdt.APTS_Query__c; 
        }else if(customSetting.Full_Load__c){
            APTS_BizIsland__mdt bizmdt = [Select APTS_Query__c from APTS_BizIsland__mdt where DeveloperName= :'AgreementLineItemBizIslandFull'][0];
            query = bizmdt.APTS_Query__c;
        }else{
            APTS_BizIsland__mdt bizmdt = [Select APTS_Query__c from APTS_BizIsland__mdt where DeveloperName= :'AgreementLineItemBizIslandDelta'][0];
            query = bizmdt.APTS_Query__c;
        }
           return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Apttus__AgreementLineItem__c> scope) {
        String ProductNumber;
        String IDField;
        String Status;
        String salesorg ='';
        String disChan='';
        string uom='';
        string netpriceincl ='';
        string indirecttaxamt ='';
        decimal myindirecttaxamt;
        decimal mynetpriceincl;
        string discountcustomcurrency='';
        set<id> prodid = new set<id>();
        map<id,product2> prodmap; 
        
        for(Apttus__AgreementLineItem__c instAgreement : scope){
    if(instAgreement.Apttus__ProductId__c != null){
        prodid.add(instAgreement.Apttus__ProductId__c);
    }
    }
    if(prodid.size()>0){
            prodmap = new map<id,product2>([select id,(select id,Apttus_Config2__FromUom__c,Apttus_Config2__ToUom__c,Apttus_Config2__ConversionFactor__c from Apttus_Config2__FrequencyUOMConversionRates__r ) from Product2 where id in :prodid]); 
    }
        Pattern p = Pattern.compile('[^0-9]');
        for(Apttus__AgreementLineItem__c instAgreementLI : scope){
            // Build Product Code 
            IF(instAgreementLI.Apttus_CMConfig__OptionId__c != NULL)
                ProductNumber = instAgreementLI.Apttus_CMConfig__OptionId__r.ProductCode;
            else
                ProductNumber = instAgreementLI.Apttus__ProductId__r.ProductCode;
            IF(instAgreementLI.Apttus_CMConfig__BasePriceOverride__c != NULL)
                IDField='AGGR' ;
            else
                IDField='CUST';
            if(instAgreementLI.CreatedDate.date()==System.Today())
            Status = 'New';
            else if(instAgreementLI.LastModifiedDate.date() ==System.Today())
            Status='Modified';
            else 
            Status='Not Modified';
            if((Status == 'Modified' || Status == 'New') && instAgreementLI.isDeleted == true)
            Status = 'Deleted';
            
            if(prodmap != null && prodmap.containskey(instAgreementLI.Apttus__ProductId__c) && prodmap.get(instAgreementLI.Apttus__ProductId__c).Apttus_Config2__FrequencyUOMConversionRates__r.size()>0){
            
            for(integer i=0; i<prodmap.get(instAgreementLI.Apttus__ProductId__c).Apttus_Config2__FrequencyUOMConversionRates__r.size();i++){
            if(instAgreementLI.Apttus_CMConfig__SellingUom__c == prodmap.get(instAgreementLI.Apttus__ProductId__c).Apttus_Config2__FrequencyUOMConversionRates__r[i].Apttus_Config2__ToUom__c && instAgreementLI.Apttus_CMConfig__PriceListItemId__r.Apttus_Config2__PriceUom__c =='SAP_PCE'){
            
              
              netpriceincl = string.valueof(instAgreementLI.Apttus__NetPrice__c + (instAgreementLI.Apttus_CMConfig__PriceListItemId__r.APTS_TAX_DK_specific_UOM__c *prodmap.get(instAgreementLI.Apttus__ProductId__c).Apttus_Config2__FrequencyUOMConversionRates__r[i].Apttus_Config2__ConversionFactor__c *instAgreementLI.Apttus__Quantity__c));
               indirecttaxamt = string.valueof(instAgreementLI.Apttus_CMConfig__PriceListItemId__r.APTS_TAX_DK_specific_UOM__c *prodmap.get(instAgreementLI.Apttus__ProductId__c).Apttus_Config2__FrequencyUOMConversionRates__r[i].Apttus_Config2__ConversionFactor__c *instAgreementLI.Apttus__Quantity__c);  
                myindirecttaxamt = Decimal.valueOf(indirecttaxamt);
                if(myindirecttaxamt != 0)
                {
                myindirecttaxamt = myindirecttaxamt.setScale(19);
                }
                else {
                myindirecttaxamt = 0;
                }
                mynetpriceincl = Decimal.valueOf(netpriceincl); 
                if(mynetpriceincl != 0)
                {
                mynetpriceincl = mynetpriceincl.setScale(19);
                }
                else {
                mynetpriceincl = 0;
                }
                 
                //myindirecttaxamt.toPlainString();
                
            }
                //if(instAgreementLI.Apttus_CMConfig__PriceListItemId__r.Apttus_Config2__PriceUom__c =='Piece' && instAgreementLI.Apttus_CMConfig__SellingUom__c == prodmap.get(instAgreementLI.Apttus__ProductId__c).Apttus_Config2__FrequencyUOMConversionRates__r[i].Apttus_Config2__ToUom__c ){
                
            //}
    }
    
    }
            if(instAgreementLI.APTS_Sales_Org__c != NULL && instAgreementLI.APTS_Sales_Org__c.contains('SAP_')){
                salesorg = instAgreementLI.APTS_Sales_Org__c.replace('SAP_','');
            }else if(instAgreementLI.APTS_Sales_Org__c != NULL){
                salesorg = instAgreementLI.APTS_Sales_Org__c;
            }
            if(instAgreementLI.Apttus_CMConfig__PriceListItemId__r.APTS_Related_sales_org_data__r.APTS_Distribution_channel__c != NULL && instAgreementLI.Apttus_CMConfig__PriceListItemId__r.APTS_Related_sales_org_data__r.APTS_Distribution_channel__c.contains('SAP_')){
                disChan = instAgreementLI.Apttus_CMConfig__PriceListItemId__r.APTS_Related_sales_org_data__r.APTS_Distribution_channel__c.replace('SAP_','');
            }
            else if (instAgreementLI.Apttus_CMConfig__PriceListItemId__r.APTS_Related_sales_org_data__r.APTS_Distribution_channel__c != NULL){
                disChan = instAgreementLI.Apttus_CMConfig__PriceListItemId__r.APTS_Related_sales_org_data__r.APTS_Distribution_channel__c;
                }
           
             if(instAgreementLI.Apttus_CMConfig__SellingUom__c!= NULL && instAgreementLI.Apttus_CMConfig__SellingUom__c.contains('SAP_')){
                uom = instAgreementLI.Apttus_CMConfig__SellingUom__c.replace('SAP_','');
            }else if (instAgreementLI.Apttus_CMConfig__SellingUom__c!= NULL){
                uom = instAgreementLI.Apttus_CMConfig__SellingUom__c;
                }
               //system.debug('keer',+disChan);
               if(instAgreementLI.Apttus__NetPrice__c !=null && instAgreementLI.Apttus__ExtendedPrice__c !=null){
              discountcustomcurrency = string.valueof(instAgreementLI.Apttus__ExtendedPrice__c - instAgreementLI.Apttus__NetPrice__c);
              } 
                 //system.debug('kk' +instAgreementLI.Apttus__NetPrice__c);
                 //system.debug('kk' +instAgreementLI.Apttus__ExtendedPrice__c);
                 
                    
            String rowStr = salesorg+','+disChan+','+IDField+','+instAgreementLI.Apttus__AgreementId__r.Apttus__FF_Agreement_Number__c+','+instAgreementLI.Apttus__AgreementId__r.Apttus__Account__r.SAP_Customer_ID__c+','+ProductNumber+','+mynetpriceincl+','+instAgreementLI.CurrencyISOCode+','+uom+','+discountcustomcurrency+','+myindirecttaxamt+','+Status;
            csvRowValues.add(rowStr);
            salesorg = '';
            disChan = '';
            uom='';
            netpriceincl='';
            //indirecttaxamt='';
        }
    
    }
    
    global void finish(Database.BatchableContext BC) {
        Bonsai__c cs = Bonsai__c.getAll().values();
        Date d=system.today();
        String Bon='Bonsai Request'+' '+d;
        list<BizIsland_Request__c> biz=[ SELECT Id, Name,Version__c FROM BizIsland_Request__c where name=:Bon];
        if(!biz.isEmpty()){
        csvColumnHeader ='Sales Organization,Distribution Channel,ID Level,Agreement Number,Customer Number,Product Number,Net Price Incl. Indirect Tax,Customer Currency,Base unit of measure,Discount in customer currency,Indirect tax amount in customer currency,Status\n';
        String csvFile = csvColumnHeader + String.join(csvRowValues,'\n');
        APTS_BizIslandContentGenerator bizz=new APTS_BizIslandContentGenerator();
            if(cs.Delta_Load__c){
                String documentName = ' DELTA REPORT CUSTPRICE_WEBSHOP';
                bizz.addAttachmentsToBonsai(biz[0],csvFile,documentName);
            }else if(cs.Full_Load__c){
                String documentName = 'FULL REPORT CUSTPRICE_WEBSHOP';
                bizz.addAttachmentsToBonsai(biz[0],csvFile,documentName);
            }
     
                APTS_PriceListitemBizIsland prc = new APTS_PriceListitemBizIsland();
                Database.executeBatch(prc,200);

            }
    
        }
    }