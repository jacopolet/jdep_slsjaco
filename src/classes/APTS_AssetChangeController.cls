public with sharing class APTS_AssetChangeController {
    
    public Id cartId;
    public Id aggrId;
    public Id tempObjectId;
    public String sFlow {get;set;}
    public List<Apttus_Config2__LineItem__c> lineitemlist{get; set;}
    public Boolean isDisable {get; set;}
    public List<SelectOption> assetChangeType {get; set;}

    public APTS_AssetChangeController() {

        this.cartId = Apexpages.currentPage().getParameters().get('id');
        this.aggrId = Apexpages.currentPage().getParameters().get('businessObjectId');
        this.tempObjectId = Apexpages.currentPage().getParameters().get('configRequestId');
        this.sFlow = Apexpages.currentPage().getParameters().get('flow');
        lineitemlist = new List<Apttus_Config2__LineItem__c>();
        assetChangeType = new List<SelectOption>();
        Schema.DescribeFieldResult fieldResult = Apttus_Config2__LineItem__c.APTS_Asset_Change_type__c.getDescribe();
        List<Schema.PicklistEntry> picklistEntryList = fieldResult.getPicklistValues();
        assetChangeType.add(new SelectOption('', ''));   
        for( Schema.PicklistEntry entry : picklistEntryList)
        {
            
            if(sFlow == 'RegisterMachineFlow' && entry.getLabel() == 'Registration')
            {
                assetChangeType.add(new SelectOption(entry.getLabel(), entry.getValue()));
            }
            else if(sFlow != 'RegisterMachineFlow' && entry.getLabel() != 'Registration')
            {
                assetChangeType.add(new SelectOption(entry.getLabel(), entry.getValue()));
            }
        }
        
        system.debug('cartId=='+cartId+'==aggrId=='+aggrId+'==tempObjectId=='+tempObjectId+'==sFlow=='+sFlow);
        try {
             if(sFlow == 'RegisterMachineFlow')
            {
               lineitemlist = [select id,Apttus_Config2__ProductId__r.Description,APTS_Serial_Number__c,APTS_Type_of_Contract__c,
                            APTS_Asset_Change_type__c, APTS_Serial_Number2__c,
                            Apttus_Config2__LineNumber__c
                            FROM Apttus_Config2__LineItem__c 
                            WHERE Apttus_Config2__ConfigurationId__c =:cartId 
                            AND Apttus_Config2__LineType__c = 'Product/Service' 
                            AND Apttus_Config2__ChargeType__c ='Sales Price'];
            }
            else
            {
                lineitemlist = [select id,Apttus_Config2__Description__c,APTS_Serial_Number__c,APTS_Type_of_Contract__c,
                            APTS_Asset_Change_type__c, APTS_Serial_Number2__c from Apttus_Config2__LineItem__c where Apttus_Config2__ConfigurationId__c =:cartId 
                            and APTS_Serial_Number__c != null and Apttus_Config2__LineType__c = 'Product/Service' and 
                            Apttus_Config2__AssetLineItemId__c != null];
            }
            

            if(!lineitemlist.isEmpty()) {
                isDisable = true;
            }else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'No Suitable Record Avaialble'));
                isDisable = false;
                return;
            }   
        } Catch(Exception e) {
            APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() ,'Aggrement',aggrId ,'CLM',false,true, 'sankumar@apttus.com', true);
          }
    }

    public PageReference updateLineItem() {
        try 
        {
            if(sFlow == 'RegisterMachineFlow')
            {
                Set<String> serialNumberSet = new Set<String>();

                for(Apttus_Config2__LineItem__c lineSO : lineitemlist)
                {
                    if(lineSO.APTS_Serial_Number2__c != null)
                        serialNumberSet.add(lineSO.APTS_Serial_Number2__c);
                }
                if(serialNumberSet.size() > 0)
                {
                    List<PhysicalAsset__c> physicalAssetList = [Select ID  from PhysicalAsset__c where SerialNumber__c IN:serialNumberSet and AssetStatus__c ='Activated'];
                    if(physicalAssetList.size() > 0)
                    {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Cannot change active physical asset'));
                        return null;
                    }
                }    
            }
            if(Apttus_Config2__LineItem__c.sObjectType.getDescribe().isUpdateable())//Performance issue fixes by Ajith
                update lineitemlist;
            PageReference returnPage = new PageReference('/apex/Apttus_Config2__Cart?configRequestId=' + tempObjectId + '&id=' + cartId + '&flow=' + sFlow + '&launchState=cart#/cart');
            return returnPage;
        }
        Catch(Exception ex){
            APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', String.valueOf(ex),'Agreement', aggrId,'CLM', false, false, null, true);
            return null;
        }

    }

    public PageReference goBack(){
        PageReference returnPage = new PageReference('/apex/Apttus_Config2__Cart?configRequestId=' + tempObjectId + '&id=' + cartId + '&flow=' + sFlow + '&launchState=cart#/cart');
        return returnPage;
    }       
}