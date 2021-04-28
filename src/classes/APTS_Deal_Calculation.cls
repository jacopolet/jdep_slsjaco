//V101 Aarthi : 18-Nov-2020 Removed custom label refrence APTS_JDE_URL for CICD
public with sharing class APTS_Deal_Calculation{
    
    public static List<String> primaryLineItemList{get;set;}
    public static Id agreementId {get;set;}
    public static boolean configExist {get;set;}
    public static boolean machineExist {get;set;}
    public static string hostUrl {get;set;}
    public static string appId {get;set;}
    public static final String APPNAME = 'Deal Calculation';
    public static final String COFFEE_KITCHEN = '0701';
    public static final String MACHINECODE = '04';

    
    public String primaryLineItemJson {
        get {
            String[] plis = new String[] {};
                for(Id pliId : primaryLineItemList){
                    plis.add(pliId);
                }
            
            return JSON.serialize(plis);
        }
    }
    
    public APTS_Deal_Calculation() {
        primaryLineItemList = new List<String>();
        agreementId = ApexPages.currentPage().getParameters().get(APTS_CPQConstants.BSN_OBJ_ID);
        configExist = false;
        machineExist = false;
       // hostUrl = Label.APTS_JDE_URL; //V101++ <<>>
       hostUrl = 'https://jdep--qas3.my.salesforce.com'; //V101++ <<>>
        appId = [Select Apttus_XApps__UniqueId__c from Apttus_XApps__Application__c where Name =: APPNAME ][0].Apttus_XApps__UniqueId__c; //PI Issue#190276 - Limit Removed
        system.debug('********** '+ hostUrl + '******** '+ appId);
        
        try{
          for(Apttus_Config2__ProductConfiguration__c 
              prodConfig : [select id,(select id,Apttus_Config2__ConfigurationId__c,Apttus_Config2__ProductId__c,Apttus_Config2__ClassificationHierarchy__c,
                                        Apttus_Config2__ClassificationId__c, Apttus_Config2__ClassificationId__r.APTS_CategoryHierarchyOfferingExtId__c,
                                       Apttus_Config2__LineNumber__c,Apttus_Config2__IsPrimaryLine__c, 
                                       Apttus_Config2__OptionId__c from Apttus_Config2__LineItems__r)
                            from Apttus_Config2__ProductConfiguration__c 
                            where Apttus_CMConfig__AgreementId__c =: agreementId order by createddate desc limit 1 ]){
                                configExist = true;
                                system.debug('prodConfig : '+ prodConfig);
                                // Modified by Saranya Rajagopal Date: 12th sep 2018
                                for(Apttus_Config2__LineItem__c lineItem : prodConfig.Apttus_Config2__LineItems__r){
                                    if(lineItem.Apttus_Config2__IsPrimaryLine__c && lineItem.Apttus_Config2__ClassificationId__c != null && (lineItem.Apttus_Config2__ClassificationId__r.APTS_CategoryHierarchyOfferingExtId__c == COFFEE_KITCHEN || lineItem.Apttus_Config2__ClassificationId__r.APTS_CategoryHierarchyOfferingExtId__c.Startswith(MACHINECODE)) && lineItem.Apttus_Config2__OptionId__c == null){
                                        //system.debug('lineItem: '+lineItem);
                                        primaryLineItemList.add(lineItem.Id);
                                        machineExist = true;
                                        system.debug('machine exist: '+lineItem.Id);
                                    }
                                }
                            }

          if(!configExist){
          // Modified by Saranya Rajagopal Date: 12th sep 2018
              ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,APTS_CPQConstants.LABEL_Exist_Agreement));
              system.debug('No config found');
          }
          else if(!machineExist){
          // Modified by Saranya Rajagopal Date: 12th sep 2018
              ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,APTS_CPQConstants.LABEL_Message));
          }
        }catch(Exception e){
            //Get the object Id
            Schema.DescribeSObjectResult r = Apttus_Config2__ProductConfiguration__c.sObjectType.getDescribe();
            String keyPrefix = r.getKeyPrefix();
            APTS_CustomLogging.createErrorLog(e.getTypeName(), APTS_CPQConstants.APEX_NAME, e.getStackTraceString() , APTS_CPQConstants.PRD_CONFIG, keyPrefix, APTS_CPQConstants.LABEL_BIR,false,true,APTS_CPQConstants.EX_JO_MAIL,true);
        }
    }

    public void updateCartStatus(){
     String cartId = ApexPages.currentPage().getParameters().get(APTS_CPQConstants.NRML_ID);
     // Modified by Saranya Rajagopal Date: 12th sep 2018
      Apttus_Config2__ProductConfiguration__c cart = new Apttus_Config2__ProductConfiguration__c(id=cartId, Apttus_Config2__Status__c=APTS_CPQConstants.LABEL_Saved);
      update cart;

    }
    
    public PageReference returnToAgreement()
    {
    /*** PI fix # 190216***/
            PageReference backToAgreement = new PageReference( '/'+ApexPages.currentPage().getParameters().get('businessObjectId'));
            return backToAgreement;
    }
    
}