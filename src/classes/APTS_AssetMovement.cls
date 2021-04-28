public with sharing class APTS_AssetMovement{

    public String selectedValue { get; set; }
    
    public Boolean Match {get; set;}
    public Boolean NoMatch {get; set;}
    public String serialNumber {get; set;}
    public List<Apttus_Config2__AssetLineItem__c> lstAsset {get; set;}
    public Boolean isDisabled {get; set;}
    public APTS_Order_LSP_Details__c oLSPDetail {get; set;}
    public Apttus_Config2__LineItem__c oLineItem {get; set;}
    Id cartId;
    Id aggrId;
    Id tempObjectId;
    String sFlow;
    Apttus__APTS_Agreement__c aggrObj;
    
    public APTS_AssetMovement(){
        cartId = Apexpages.currentPage().getParameters().get('id');
        aggrId = Apexpages.currentPage().getParameters().get('businessObjectId');
        tempObjectId = Apexpages.currentPage().getParameters().get('configRequestId');
        sFlow = Apexpages.currentPage().getParameters().get('flow');
        isDisabled = true;
        oLineItem = new Apttus_Config2__LineItem__c();
        oLSPDetail = new APTS_Order_LSP_Details__c();
    }


    public void fetchAsset(){
        Match=false;
        NoMatch=false;
        
        lstAsset = new List<Apttus_Config2__AssetLineItem__c>();
        if(!String.isEmpty(serialNumber)){
            lstAsset = [SELECT Id, Name, Apttus_Config2__AccountId__c, Apttus_CMConfig__AgreementId__r.Apttus__Account__c,Apttus_Config2__AccountId__r.Name,
                    Apttus_Config2__PriceListId__c, APTS_Physical_Asset__r.SerialNumber__c, Apttus_Config2__LineType__c, Apttus_Config2__AssetStatus__c 
                    FROM Apttus_Config2__AssetLineItem__c
                    WHERE APTS_Physical_Asset__r.SerialNumber__c = :serialNumber
                    AND Apttus_Config2__IsPrimaryLine__c = true];
        }
        else{
            isDisabled = true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Please enter Serial Number.'));
            return;
        }

        if(lstAsset.size()>0){
            aggrObj = [SELECT Id, Apttus_CMConfig__BillToAccountId__c, Apttus_CMConfig__ShipToAccountId__c, Apttus_CMConfig__PriceListId__c,
                                                    Apttus__Contract_Start_Date__c, Apttus__Contract_End_Date__c
                                                    FROM Apttus__APTS_Agreement__c
                                                    WHERE Id = :aggrId LIMIT 1][0];

            Match = true;
            if(lstAsset[0].Apttus_Config2__LineType__c == 'Product/Service'){
                isDisabled = false;
            }
            else{
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Line Type is not correct.'));
                return;
            }

            if(lstAsset.size() > 1){
                isDisabled = true;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'More than one asset with same serial number is not possbile.'));
                return;
            }
        }
        else{
            NoMatch = true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'No asset associated with the Serial Number.'));
            isDisabled = true;
        }

        if(lstAsset.size()>0 && lstAsset[0].Apttus_Config2__PriceListId__c != aggrObj.Apttus_CMConfig__PriceListId__c){
            Match = true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Price List of Asset Line Item and Agreement should be same.'));
            isDisabled = true;
        }
    }


    public PageReference createLineItem(){
        List<Id> lstUsedAssetLineItems = new List<Id>();
        lstUsedAssetLineItems.add(lstAsset[0].Id);
        
        Apttus_Config2.CPQStruct.ChangeAssetsRequestDO request = new Apttus_Config2.CPQStruct.ChangeAssetsRequestDO();
        request.AssetIds = lstUsedAssetLineItems;
        request.CartId = cartId;
        Apttus_Config2.CPQStruct.ChangeAssetsResponseDO response = Apttus_Config2.AssetService.changeAssets(request);

        //Update Pricing until isPricingPending flag becomes 'False'
        /**Boolean isPricePending = true;
        if(!Test.isRunningTest()){
            while (isPricePending) {
                isPricePending = APTS_OrderUtils.repriceCart(cartId);
                System.debug('isPricePending: ' + isPricePending);
                if (!isPricePending) {
                    break;
                }
            }
        }**/
        
        Database.insert(oLSPDetail);

        aggrObj = [SELECT Id, Apttus_CMConfig__BillToAccountId__c, Apttus_CMConfig__ShipToAccountId__c,
                                                    Apttus__Contract_Start_Date__c, Apttus__Contract_End_Date__c
                                                    FROM Apttus__APTS_Agreement__c
                                                    WHERE Id = :aggrId LIMIT 1][0];

        //System.debug('response++' + response);
        //System.debug('response.LineItemMap++' + response.LineItemMap.keySet());
        
        List<Apttus_Config2__LineItem__c> lstLineItems = [SELECT Id, Apttus_Config2__BillToAccountId__c, Apttus_Config2__ShipToAccountId__c, 
                                                            APTS_Serial_Number2__c, Apttus_Config2__IsPrimaryLine__c, Apttus_Config2__OptionId__c, Apttus_Config2__LineType__c
                                                            FROM Apttus_Config2__LineItem__c WHERE Apttus_Config2__ConfigurationId__c =:cartId
                                                            AND (Apttus_Config2__LineStatus__c = 'Amended' OR Apttus_Config2__LineStatus__c = 'Existing')];
        //system.debug('$$$$$$ lstLineItems '+lstLineItems);
        //ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.Info, '$$$$$$ lstLineItems '+lstLineItems));
        /*List<Apttus_Config2__LineItem__c> lstLineItems = [SELECT Id, Apttus_Config2__BillToAccountId__c, Apttus_Config2__ShipToAccountId__c
                                                            FROM Apttus_Config2__LineItem__c WHERE Id IN :response.LineItemMap.keySet()];*/
        
        for(Apttus_Config2__LineItem__c tmp : lstLineItems){
            tmp.Apttus_Config2__BillToAccountId__c = aggrObj.Apttus_CMConfig__BillToAccountId__c;
            //tmp.Apttus_Config2__BillToAccountId__c = null;
            tmp.Apttus_Config2__ShipToAccountId__c = aggrObj.Apttus_CMConfig__ShipToAccountId__c;
            //tmp.Apttus_Config2__ShipToAccountId__c = null;
            tmp.Apttus_Config2__StartDate__c = aggrObj.Apttus__Contract_Start_Date__c;
            tmp.Apttus_Config2__EndDate__c = aggrObj.Apttus__Contract_End_Date__c;
            tmp.Apttus_Config2__LineStatus__c = 'New';
            tmp.Apttus_Config2__AssetLineItemId__c = NULL;
            tmp.Apttus_Config2__AssetQuantity__c = NULL;
            
            if( tmp.Apttus_Config2__IsPrimaryLine__c == TRUE && tmp.Apttus_Config2__LineType__c == 'Product/Service'){ // tmp.Apttus_Config2__OptionId__c == NULL && && tmp.Apttus_Config2__LineType__c == 'Product/Service'
                tmp.APTS_Serial_Number2__c = serialNumber;
                if(String.IsNotBlank(selectedValue) && selectedValue != '--None--'){
                    tmp.APTS_Asset_Change_type__c = selectedValue;
                    tmp.Apttus_Config2__LocationId__c = oLineItem.Apttus_Config2__LocationId__c;
                    tmp.APTS_Order_LSP_Detail__c = oLSPDetail != null ? oLSPDetail.Id : null;
                }
            }
        }

        if(lstLineItems != null && lstLineItems.size() > 0){
            update lstLineItems;
        }

        PageReference returnPage = new PageReference('/apex/Apttus_Config2__Cart?configRequestId=' + tempObjectId + '&id=' + cartId + '&flow=' + sFlow + '#!/cart');
        return returnPage;
    }
    
    public List<SelectOption> getPicklistValues() {

        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('--None--', '--None--'));
        for(Schema.PicklistEntry value : Apttus_Config2__LineItem__c.APTS_Asset_Change_type__c.getDescribe().getPicklistValues()){
            if(value.getValue() == 'Non-Physical movement' || value.getValue() == 'Physical movement') {
                options.add(new SelectOption(value.getLabel(), value.getValue()));
            }
        }
        return options;
   }

    public PageReference goBack(){
        PageReference returnPage = new PageReference('/apex/Apttus_Config2__Cart?configRequestId=' + tempObjectId + '&id=' + cartId + '&flow=' + sFlow + '#!/assets');
        return returnPage;
    }
}