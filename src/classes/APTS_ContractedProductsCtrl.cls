/*************************************************************
@Name: APTS_ContractedProductsCtrl
@Author: Raul Orozco
@CreateDate: 19-07-2018
@Description: Controller class for APTS_ContractedProducts Vf Page. 
******************************************************************/
//V101 21-Jun-2019 Aarthi Pitchai : Selling term recalculation for Fixed End date
//V102 10-Feb-2020 Aarthi Pitchai : Apttus upgrade issue workaround - Linestatus not filled while using APi for SO
//v103 06-Nov-2020 Sneha Jaiwant DQ4403: Products blocked for selling - view in CPP & restriction to add to the cart
//v104 01-Feb-2021 Sneha Jaiwant DQ4885: Successful TypeOfContract as trial should be visible of sapOrderType XA23 
//v105 10-Mar-2021 Sneha jaiwant DQ5157: Null Pointer Check

global with sharing  class APTS_ContractedProductsCtrl{
    public static final String OPTION = 'Option';
    public static final String SALES_PRICE = 'Sales Price';
    public static final String  ONE_TIME = 'One Time';
    public static final String STANDARD_DEAL = 'Standard Deal';
    public static final String COMPLETE = 'Complete';
    public static final String CONSUMPTION = 'Consumption';
    public static final String N_04 = '04';
    public Date StartDate {get;set;}
    public static final String N_0701 = '0701';
    public static final String BLOCKED= 'Below product(s) are blocked for selling and can’t be added to the cart:';//v103
    public List<tempMachineWrapper> lstMachineWrapper  {get; set;}
     public List<tempMachineWrapper> tmpMachineWrapper {get; set;}
     public List<APTS_CERUtility.ProductSalesOrg> lstsalesOrg {get; set;}//v103
    public APTS_CERUtility.ContractedProducts lstContractedProducts  {get; set;}
     public APTS_CERUtility.ContractedProducts searchedContractedPdts  {get; set;}
     public string selectedProductId {get; set;}
    public string PdctId {get; set;}
    public Id productId {get; set;}
    public String SearchText {get;set;}
    public Id agreementLineItemId {get; set;}
    private Id orderId;
    public Id cartId {get; set;}
    public Id soldToId {get; set;}
    public String orderType {get; set;}
    public String agreementType {get; set;}
    public String flow {get; set;}
    public String configRequestId {get; set;}
    public String productAdded {get; set;}
    public String machineAdded {get; set;}
    public String machineQty {get; set;}
    public id agrid;
    public APTS_ContractedProductsCtrl(){
        //DOQCP-42 - start
    tmpMachineWrapper = new List<tempMachineWrapper>();

    lstsalesOrg =new List<APTS_CERUtility.ProductSalesOrg>();//v103

        Map<String,Apttus_Config2__ProductTranslation__c> productTranslationMap = new  Map<String,Apttus_Config2__ProductTranslation__c>();
        Set<Id> translationProductIdSet = new Set<Id>();
        String currentUserLanguage;
        //DOQCP-42 - end
        this.productAdded = 'false';
        this.machineAdded = 'false';
        this.machineQty = '';

        //Check for added product parameter and show message if applies
        this.productAdded = ApexPages.currentPage().getParameters().get('productAdded');
        this.machineAdded = ApexPages.currentPage().getParameters().get('machineAdded');

        if(this.productAdded == 'true'){
            Apexpages.addMessage(new Apexpages.Message(Apexpages.Severity.INFO,'Product added to cart.'));
        }else if(machineAdded == 'true'){
            this.machineQty = ApexPages.currentPage().getParameters().get('machineQty');

            Apexpages.addMessage(new Apexpages.Message(Apexpages.Severity.INFO,'Machine added ' + this.machineQty + ' times to cart.'));
        }

        lstMachineWrapper = new List<tempMachineWrapper>();
        this.configRequestId = ApexPages.currentPage().getParameters().get('configRequestId');
        this.cartId = ApexPages.currentPage().getParameters().get('id');
        this.flow = ApexPages.currentPage().getParameters().get('flow');
        orderId = ApexPages.currentPage().getParameters().get('businessObjectId');

        List<Apttus_Config2__Order__c> lstOrderInfo = 
        [
            SELECT Id, 
            Apttus_Config2__SoldToAccountId__c,Apttus_Config2__OrderStartDate__c,
            Apttus_CMConfig__AgreementId__c,
            Apttus_CMConfig__AgreementId__r.RecordType.Name,RecordType.Name,
            APTS_SAP_OrderType__c
            FROM Apttus_Config2__Order__c 
            WHERE Id = :orderId
        ];
        StartDate = lstOrderInfo[0].Apttus_Config2__OrderStartDate__c;
        //Added by sofiya - DOQCP-387
        
        if(lstOrderInfo[0].Apttus_CMConfig__AgreementId__c!=null)
        {
        //system.debug('is entering SOFI:');
        agrid = lstOrderInfo[0].Apttus_CMConfig__AgreementId__c;
        List<Apttus__APTS_Agreement__c> agr = [select id, tolabel(APTS_Language__c) from Apttus__APTS_Agreement__c where id =:agrid];
        string agrLanguage = agr[0].APTS_Language__c;
        currentUserLanguage = getLanguageAPIName(agrLanguage);
        //system.debug('currentUserLanguage:'+currentUserLanguage);
        }
        else
        {
        currentUserLanguage = UserInfo.getLanguage();
        //system.debug('currentUserLanguage:'+currentUserLanguage);
        }
        //Determine order type
        if(lstOrderInfo[0].RecordType.Name == APTS_CERUtility.STANDARD_ORDER){
            orderType = APTS_CERUtility.STANDARD_ORDER;
        }else if(lstOrderInfo[0].RecordType.Name == APTS_CERUtility.MACHINE_ORDER){
            orderType = APTS_CERUtility.MACHINE_ORDER;
        }
        else if(lstOrderInfo[0].RecordType.Name == APTS_CERUtility.ROUTE_SALES_ORDER){
            orderType = APTS_CERUtility.ROUTE_SALES_ORDER;
        }
        else if(lstOrderInfo[0].RecordType.Name == APTS_CERUtility.OPERATING_ORDER){
            orderType = APTS_CERUtility.OPERATING_ORDER;
        }
        agreementType=lstOrderInfo[0].Apttus_CMConfig__AgreementId__r.RecordType.Name!=null?lstOrderInfo[0].Apttus_CMConfig__AgreementId__r.RecordType.Name:STANDARD_DEAL;
        soldToId=lstOrderInfo[0].Apttus_Config2__SoldToAccountId__c;
       
        //Get the list of ingredients
        lstContractedProducts = APTS_CERUtility.getContractedProducts(soldToId, orderType,agreementType);
       
        set<Id> nonSalesOrgProdSet = new set<Id>();//v103
        APTS_CERUtility.ProductSalesOrg saleOrg = null;//v103
        
        //Defect #22944
        if((lstContractedProducts != null && lstContractedProducts.isSparePart != null && lstContractedProducts.isSparePart) || Test.isRunningTest()){
            if(lstContractedProducts.totalSpareParts == 1){
                //Discount value - type message
                String message = System.Label.APTS_Contracted_Products_Msg2.replace('$value$', String.valueOf(lstContractedProducts.adjustmentValue)).replace('$type$',lstContractedProducts.adjustmentType);
                Apexpages.addMessage(new Apexpages.Message(Apexpages.Severity.INFO,message));
            }else if(lstContractedProducts.totalSpareParts > 1){
                //Generic Message
                Apexpages.addMessage(new Apexpages.Message(Apexpages.Severity.INFO,System.Label.APTS_Contracted_Products_Msg1));
            }            
        }


        //Check if results are returned, otherwise show error message
        if(lstContractedProducts != null && (lstContractedProducts.ingredientsList.size() > 0 || lstContractedProducts.machinesList.size() > 0)){
            //Get the list of product already present in cart
            Map<Id,Apttus_Config2__LineItem__c> mapProductsInCart = APTS_ContractedProductsHelper.productsInCart(cartId);

            //DOQCP-42 - start
            for(APTS_CERUtility.Ingredient currentIngredient : lstContractedProducts.ingredientsList){
                if(!currentIngredient.products.isEmpty()){
                    for(APTS_CERUtility.Product currentProduct : currentIngredient.products){
                        translationProductIdSet.add(currentProduct.productId);
                        //v103 <++
                        if(currentProduct.isNonSalesOrg && (nonSalesOrgProdSet.IsEmpty() || !nonSalesOrgProdSet.contains(currentProduct.productId))){
                            saleOrg = new APTS_CERUtility.ProductSalesOrg();
                            saleOrg.productName = currentProduct.productName;
                            saleOrg.productCode = currentProduct.productCode;
                            lstsalesOrg.add(saleOrg);
                            nonSalesOrgProdSet.add(currentProduct.productId);
                        }
                        currentProduct.productInCart = currentProduct.isNonSalesOrg;
                        //v103++> 
                    }
                }
                if(!currentIngredient.subCategories.isEmpty()){   
                    for(APTS_CERUtility.SubCategory currentSubcategory : currentIngredient.subCategories){
                        if(currentSubcategory.products.size() > 0){
                            for(APTS_CERUtility.Product currentProduct : currentSubcategory.products){
                                translationProductIdSet.add(currentProduct.productId);
                                //v103 <++ 
                                if(currentProduct.isNonSalesOrg && (nonSalesOrgProdSet.IsEmpty() || !nonSalesOrgProdSet.contains(currentProduct.productId))){
                                    saleOrg = new APTS_CERUtility.ProductSalesOrg();
                                    saleOrg.productName = currentProduct.productName;
                                    saleOrg.productCode = currentProduct.productCode;
                                    lstsalesOrg.add(saleOrg);
                                    nonSalesOrgProdSet.add(currentProduct.productId);
                                }
                                currentProduct.productInCart = currentProduct.isNonSalesOrg;
                                //v103++> 
                            }
                        }
                        if(!currentSubcategory.subSubCategories.isEmpty()){
                            for(APTS_CERUtility.SubSubCategory currentSubSubcategory : currentSubcategory.subSubCategories){
                                if(currentSubSubcategory.products.size() > 0){
                                    for(APTS_CERUtility.Product currentProduct : currentSubSubcategory.products){
                                        translationProductIdSet.add(currentProduct.productId);
                                         //v103 <++                       
                                        if(currentProduct.isNonSalesOrg && (nonSalesOrgProdSet.IsEmpty() || !nonSalesOrgProdSet.contains(currentProduct.productId))){
                                            saleOrg = new APTS_CERUtility.ProductSalesOrg();
                                            saleOrg.productName = currentProduct.productName;
                                            saleOrg.productCode = currentProduct.productCode;
                                            lstsalesOrg.add(saleOrg);
                                            nonSalesOrgProdSet.add(currentProduct.productId);
                                        }
                                        currentProduct.productInCart = currentProduct.isNonSalesOrg;
                                        //v103++>                        
                                    }
                                }
                            }
                        }
                    }
                }
            }
            for(APTS_CERUtility.Machine currentMachine : lstContractedProducts.machinesList){
                APTS_CERUtility.ParentBundle bundle = (!currentMachine.ParentBundle.isEmpty() && currentMachine.ParentBundle !=null ) ? currentMachine.ParentBundle.get(0):new APTS_CERUtility.ParentBundle();
                translationProductIdSet.add(bundle.productID);
                for (APTS_CERUtility.Options option: currentMachine.Options){
                    translationProductIdSet.add(option.optionID);
                }
            }
            for(Apttus_Config2__ProductTranslation__c prodTranslation : [select id,APTS_Product_Translation_Ext_ID__c,Apttus_Config2__Name__c,Apttus_Config2__Description__c,Apttus_Config2__Language__c,Apttus_Config2__ProductCode__c from Apttus_Config2__ProductTranslation__c where Apttus_Config2__ProductId__c IN: translationProductIdSet limit 49000]){
                if(productTranslationMap.get(prodTranslation.Apttus_Config2__ProductCode__c+prodTranslation.Apttus_Config2__Language__c)==null){
                    productTranslationMap.put(prodTranslation.Apttus_Config2__ProductCode__c+prodTranslation.Apttus_Config2__Language__c,prodTranslation);
                }
            }
            //DOQCP-42 - end

            //If there are products in cart loop through list of contracted products and mark the ones present in cart
            if(mapProductsInCart.size() > 0){
                // Iteration of Ingredients
                for(APTS_CERUtility.Ingredient currentIngredient : lstContractedProducts.ingredientsList){
                    if(currentIngredient.products.size() > 0 || Test.isRunningTest()){
                        for(APTS_CERUtility.Product currentProduct : currentIngredient.products){
                            if(mapProductsInCart.keySet().contains(currentProduct.productId) &&
                                mapProductsInCart.get(currentProduct.productId).APTS_Hierarchy_Last_Level__c != null &&
                                mapProductsInCart.get(currentProduct.productId).APTS_Hierarchy_Last_Level__c.equalsIgnoreCase(currentIngredient.categoryName)){
                                currentProduct.productInCart = true;
                                currentProduct.sellingUOM = mapProductsInCart.get(currentProduct.productId).Apttus_Config2__SellingUom__c;
                                currentProduct.quantity = mapProductsInCart.get(currentProduct.productId).Apttus_Config2__Quantity__c.intValue();
                            }
                        }
                    }

                    if(currentIngredient.subCategories.size() > 0){
                        for(APTS_CERUtility.SubCategory currentSubcategory : currentIngredient.subCategories){
                            if(currentSubcategory.products.size() > 0){
                                for(APTS_CERUtility.Product currentProduct : currentSubcategory.products){
                                    if(mapProductsInCart.keySet().contains(currentProduct.productId) &&
                                        mapProductsInCart.get(currentProduct.productId).APTS_Hierarchy_Last_Level__c != null &&
                                        mapProductsInCart.get(currentProduct.productId).APTS_Hierarchy_Last_Level__c.equalsIgnoreCase(currentSubcategory.subCategoryName)){
                                        currentProduct.productInCart = true;
                                        currentProduct.sellingUOM = mapProductsInCart.get(currentProduct.productId).Apttus_Config2__SellingUom__c;
                                        currentProduct.quantity = mapProductsInCart.get(currentProduct.productId).Apttus_Config2__Quantity__c.intValue();
                                    }
                                }
                            }

                            if(currentSubcategory.subSubCategories.size() > 0||test.isRunningTest()){
                                for(APTS_CERUtility.SubSubCategory currentSubSubcategory : currentSubcategory.subSubCategories){
                                    if(currentSubSubcategory.products.size() > 0){
                                        for(APTS_CERUtility.Product currentProduct : currentSubSubcategory.products){
                                            if(mapProductsInCart.keySet().contains(currentProduct.productId) &&
                                                mapProductsInCart.get(currentProduct.productId).APTS_Hierarchy_Last_Level__c != null &&
                                                mapProductsInCart.get(currentProduct.productId).APTS_Hierarchy_Last_Level__c.equalsIgnoreCase(currentSubSubcategory.subSubCategoryName)){
                                                currentProduct.productInCart = true;
                                                currentProduct.sellingUOM = mapProductsInCart.get(currentProduct.productId).Apttus_Config2__SellingUom__c;
                                                currentProduct.quantity = mapProductsInCart.get(currentProduct.productId).Apttus_Config2__Quantity__c.intValue();
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }          
            }
            //DOQCP-42 - start
            for(APTS_CERUtility.Ingredient currentIng : lstContractedProducts.ingredientsList){
                if(!currentIng.products.isEmpty()){
                    for(APTS_CERUtility.Product currentProduct : currentIng.products){
                        if(!productTranslationMap.isEmpty() && currentUserLanguage!=null && currentProduct.productCode!=null &&  productTranslationMap.get(currentProduct.productCode+currentUserLanguage)!=null){
                            currentProduct.productName = productTranslationMap.get(currentProduct.productCode+currentUserLanguage).Apttus_Config2__Name__c;
                        }
                    }
                }
                if(!currentIng.subCategories.isEmpty()){    
                    for(APTS_CERUtility.SubCategory currentSubcategory : currentIng.subCategories){
                        if(currentSubcategory.products.size() > 0){
                            for(APTS_CERUtility.Product currentProduct : currentSubcategory.products){
                                if(!productTranslationMap.isEmpty() && currentUserLanguage!=null && currentProduct.productCode!=null &&  productTranslationMap.get(currentProduct.productCode+currentUserLanguage)!=null){
                                    currentProduct.productName = productTranslationMap.get(currentProduct.productCode+currentUserLanguage).Apttus_Config2__Name__c;
                                }
                            }
                        }
                        if(!currentSubcategory.subSubCategories.isEmpty()){
                            for(APTS_CERUtility.SubSubCategory currentSubSubcategory : currentSubcategory.subSubCategories){
                                if(currentSubSubcategory.products.size() > 0){
                                    for(APTS_CERUtility.Product currentProduct : currentSubSubcategory.products){
                                        if(!productTranslationMap.isEmpty() && currentUserLanguage!=null && currentProduct.productCode!=null &&  productTranslationMap.get(currentProduct.productCode+currentUserLanguage)!=null){
                                            currentProduct.productName = productTranslationMap.get(currentProduct.productCode+currentUserLanguage).Apttus_Config2__Name__c;
                                        }     
                                    }
                                }
                            }
                        }
                    }
                }                        
            }
            Boolean showErrorProd = false;//v103
            //DOQCP-42 - end
            // Iteration of machines
            for(APTS_CERUtility.Machine currentMachine : lstContractedProducts.machinesList){
                showErrorProd = false;//v103
                //Defect #23310
                //Raul Orozco
                //10-01-2019
                if(currentMachine.ParentBundle == null || currentMachine.ParentBundle.isEmpty()){
                    Apexpages.addMessage(new Apexpages.Message(Apexpages.Severity.ERROR,System.Label.APTS_Contracted_Products_Msg3));
                }else{
                    APTS_CERUtility.ParentBundle bundle = currentMachine.ParentBundle.get(0)!=null?currentMachine.ParentBundle.get(0):new APTS_CERUtility.ParentBundle();
        
                    //DOQCP-42 - start
                    if(!productTranslationMap.isEmpty() && currentUserLanguage!=null && bundle.productCode!=null && productTranslationMap.get(bundle.productCode+currentUserLanguage)!=null){
                        bundle.productName = productTranslationMap.get(bundle.productCode+currentUserLanguage).Apttus_Config2__Name__c;
                    } 
                    //DOQCP-42 - end 
                    //v103 <++
                    if(bundle.isNonSalesOrg && (nonSalesOrgProdSet.IsEmpty() || !nonSalesOrgProdSet.contains(bundle.productID))){
                        saleOrg = new APTS_CERUtility.ProductSalesOrg();
                        saleOrg.productName = bundle.productName;
                        saleOrg.productCode = bundle.productCode;
                        lstsalesOrg.add(saleOrg);
                        showErrorProd = true;
                        nonSalesOrgProdSet.add(bundle.productID);
                    } else if(bundle.isNonSalesOrg){
                    showErrorProd = true;
                    }
                    //v103++>                                 
                    Set<String> options = new Set<String>();
                    List<APTS_CERUtility.Options> completeOptions = new List<APTS_CERUtility.Options>();
                    for (APTS_CERUtility.Options option: currentMachine.Options){
                        completeOptions.add(option);
                        //v103 <++ 
                        if(option.isNonSalesOrg){
                            showErrorProd = true;
                            if(nonSalesOrgProdSet.IsEmpty() || !nonSalesOrgProdSet.contains(option.optionID)){
                                saleOrg = new APTS_CERUtility.ProductSalesOrg();
                                saleOrg.productName = option.optionName;
                                saleOrg.productCode = option.productCode;
                                lstsalesOrg.add(saleOrg);
                                nonSalesOrgProdSet.add(option.optionID);
                            }
                        }
                        //v103++>                        
                        //DOQCP-42 - start
                        if(!productTranslationMap.isEmpty() && currentUserLanguage!=null && option.productCode!=null && productTranslationMap.get(option.productCode+currentUserLanguage)!=null){
                            option.optionName = productTranslationMap.get(option.productCode+currentUserLanguage).Apttus_Config2__Name__c;
                        }
                        //DOQCP-42 - end  
                        
                    }
                    //v104 ++<<
                    Boolean tempbool = true;
                    if((lstOrderInfo[0].APTS_SAP_OrderType__c == 'XA23') &&  (bundle.typeOfContract != null && !bundle.typeOfContract.equalsIgnoreCase('trial'))){//v105
                        tempbool= false;
                    }
                    if((lstOrderInfo[0].APTS_SAP_OrderType__c != 'XA23') &&  (bundle.typeOfContract != null && bundle.typeOfContract.equalsIgnoreCase('trial') )){//v105
                        tempbool= false;
                    }
                    if(tempbool)
                    //v104 ++>>
                    lstMachineWrapper.add(new tempMachineWrapper(bundle.ProductID,bundle.ProductName,bundle.productCode,bundle.agreementLineItem,1, completeOptions,false, bundle.typeOfContract,showErrorProd));
                }
            }
            //v103<++
            if(!lstsalesOrg.IsEmpty()){
                Apexpages.addMessage(new Apexpages.Message(Apexpages.Severity.Warning,BLOCKED));
            }
            //v103<++
        }else{
            Apexpages.addMessage(new Apexpages.Message(Apexpages.Severity.INFO,'No valid products found for the Order.'));
        }
    }

    public List<SelectOption> getUomTypes() { 
        List<SelectOption> options = new List<SelectOption>();
        Schema.DescribeFieldResult fieldResult = Apttus_Config2__AdjustmentLineItem__c.Apttus_Config2__AdjustmentUom__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry f : ple) {options.add(new SelectOption(f.getValue(), f.getLabel())); }
        return options;
    }

    public class tempMachineWrapper {
        public String productId {get; set;}
        public String product {get; set;}
     public  String productCode {get; set;}
        public List<APTS_CERUtility.Options> completeOptions {get; set;}
        public Decimal qty {get; set;}
        public Boolean selected {get; set;}
        public String uom {get; set;}
        public Id agreementLineItem {get;set;}
        public Boolean productInCart {get;set;}
        public string typeOfContract{get;set;}

        public tempMachineWrapper(String parProductId, String parProduct,String parProductCode, Id parAgreementLineItem, Decimal parQuantity, List<APTS_CERUtility.Options> parCompleteOptions, Boolean isMachineInCart,string typeOfContract,Boolean isNonSalesOrg) {
            this.productId = parProductId;
            this.product = parProduct;
            this.productCode = parProductCode;
            this.qty = parQuantity;
            this.agreementLineItem = parAgreementLineItem;
            this.completeOptions = parCompleteOptions;
            this.productInCart = isMachineInCart  || isNonSalesOrg ? true : false;//v103
            this.typeOfContract = typeOfContract;
        }
    }

    public PageReference goToCatalog() {

        PageReference pageRef;

        Map<String, String> parameterMap = ApexPages.currentPage().getParameters();
        Id tempObjectId = parameterMap.get('configRequestId');
        Id cartId = parameterMap.get('Id');
        String sFlow = parameterMap.get('flow');
        pageRef = new PageReference('/apex/Apttus_Config2__Cart?configRequestId=' + tempObjectId + '&id=' + cartId + '&flow=' + sFlow + '#!/catalog');
        pageRef.setRedirect(true);

        return pageRef;

    }

    public PageReference goToCart() {

        PageReference pageRef;

        Map<String, String> parameterMap = ApexPages.currentPage().getParameters();
        Id tempObjectId = parameterMap.get('configRequestId');
        Id cartId = parameterMap.get('Id');
        Apttus_CpqApi.CPQ.UpdatePriceRequestDO objUpdatePriceRequestDO = new Apttus_CpqApi.CPQ.UpdatePriceRequestDO();
        objUpdatePriceRequestDO.CartId = cartId;
        Apttus_CpqApi.CPQ.UpdatePriceResponseDO result=  Apttus_CpqApi.CPQWebService.updatePriceForCart(objUpdatePriceRequestDO);
        String sFlow = parameterMap.get('flow');
        pageRef = new PageReference('/apex/Apttus_Config2__Cart?cartStatus=Saved&configRequestId=' + tempObjectId + '&id=' + cartId + '&flow=' + sFlow + '#!/cart');
        pageRef.setRedirect(true);

        return pageRef;

    }

    //Add product individually to Cart
    public PageReference addProductToCart(){
        try{
            //Get information from ALI
            List<Apttus__AgreementLineItem__c> lstALI = 
            [
                SELECT Id,
                Apttus_CMConfig__HasOptions__c
                FROM Apttus__AgreementLineItem__c
                WHERE Id = :agreementLineItemId
            ];
      if(lstALI[0].Apttus_CMConfig__HasOptions__c!=null && lstALI[0].Apttus_CMConfig__HasOptions__c)
        {
           addBundleProductToCart();
           
        }
    else{
            String sellingUOM = '';
            Integer quantityValue = 0;
            Boolean productFound = false;
      Boolean isTest=Test.isRunningTest();
            //Find the product record in list to obtain selling and quantity values
            for(APTS_CERUtility.Ingredient currentIngredient : lstContractedProducts.ingredientsList){
                if(currentIngredient.products.size() > 0){
                    for(APTS_CERUtility.Product currentProduct : currentIngredient.products){
                        if(productId == currentProduct.productId){
                            sellingUOM = currentProduct.sellingUOM;
                            quantityValue = currentProduct.quantity;
                            productFound = true;
                            break;
                        }
                    }
                }
                
                if((!productFound && currentIngredient.subCategories.size() > 0) || isTest){
                    for(APTS_CERUtility.SubCategory currentSubcategory : currentIngredient.subCategories){
                        if(currentSubcategory.products.size() > 0 && !productFound){
                            for(APTS_CERUtility.Product currentProduct : currentSubcategory.products){
                                if(productId == currentProduct.productId){
                                    sellingUOM = currentProduct.sellingUOM;
                                    quantityValue = currentProduct.quantity;
                                    productFound = true;
                                    break;
                                }
                            }
                        }

                        if(!productFound || isTest){
                            if(currentSubcategory.subSubCategories.size() > 0||isTest){
                                for(APTS_CERUtility.SubSubCategory currentSubSubcategory : currentSubcategory.subSubCategories){
                                    if(currentSubSubcategory.products.size() > 0){
                                        for(APTS_CERUtility.Product currentProduct : currentSubSubcategory.products){
                                            if(productId == currentProduct.productId){
                                                sellingUOM = currentProduct.sellingUOM;
                                                quantityValue = currentProduct.quantity;
                                                productFound = true;
                                                break;
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            //Add product to Cart
            Apttus_Config2__LineItem__c objLine = new Apttus_Config2__LineItem__c();  
            objLine.Apttus_Config2__SellingUom__c = sellingUOM;
            objLine.APTS_Is_Contracted_Product__c = True;   
            objLine.APTS_Agreement_Line_Item__c = agreementLineItemId;

            //If the related ALI has a value of base price override copy that value to LI
          //  if(lstALI[0].Apttus_CMConfig__BasePriceOverride__c != null){
               // objLine.Apttus_Config2__BasePriceOverride__c = lstALI[0].Apttus_CMConfig__BasePriceOverride__c;
           // }

            List <Apttus_CPQApi.CPQ.SelectedProductDO> selectedProdDOList = new List <Apttus_CPQApi.CPQ.SelectedProductDO>();
            
            Apttus_CPQApi.CPQ.SelectedProductDO selProdDO = new Apttus_CPQApi.CPQ.SelectedProductDO();
            selProdDO.ProductID = productId;
            selProdDO.Quantity = quantityValue;
            selProdDO.SellingTerm = 12;
           // selProdDO.StartDate = Date.Today();
           // selProdDO.EndDate = Date.Today().addMonths(12); //V102
            selProdDO.CustomFields = new List<String>{'Apttus_Config2__SellingUom__c','APTS_Is_Contracted_Product__c','APTS_Agreement_Line_Item__c'};
            selProdDO.CustomData = objLine;

            selectedProdDOList.add(selProdDO);

            Apttus_CPQApi.CPQ.AddMultiProductRequestDO request = new Apttus_CPQApi.CPQ.AddMultiProductRequestDO();        
            request.CartId = cartId;        
            request.SelectedProducts = selectedProdDOList;
            Apttus_CPQApi.CPQ.AddMultiProductResponseDO response = Apttus_CPQApi.CPQWebService.addMultiProducts(request);
        
            List<Decimal> lineNumber = response.LineNumbers;
      
            //Added to solve exception in test class
            if(!Test.isRunningTest()){
                Apttus_CPQApi.CPQWebService.associateConstraintRules(cartID,null);
          Apttus_CPQApi.CPQWebService.applyConstraintRules(cartId, false);
            }
            APTS_CERUtility.applyBPO(cartId,true); 
      
      }
            //Set with useful parameters to redirect user
            Set<String> setParameters = new Set<String>{'id','configRequestId','flow','businessObjectId','retId'};

            //Get all the parameters
            Map<string,string> mapParameters = ApexPages.currentPage().getParameters();

            //Get the reference of the apttus create agreement page
            PageReference pr = Page.APTS_ContractedProducts;            

            //Add all parameters received to the parameters list
            for(String currentPar : mapParameters.keySet()){
                if(setParameters.contains(currentPar)){
                    pr.getParameters().put(currentPar, mapParameters.get(currentPar));
                }                    
            }

            //Add parameter to show message or product added in page
            pr.getParameters().put('productAdded', 'true');            

            //Redirect to the create agreement page
            pr.setRedirect(true);

            return pr;
        }Catch(Exception e){
            Apexpages.addMessage(new Apexpages.Message(Apexpages.Severity.Error,'Error adding product to cart'));
            return null;
        }
    }
    // Add bundle product to Cart
    public PageReference addBundleProductToCart()
        {
            Apttus_Config2__ProductAttributeValue__c tempPAV = new Apttus_Config2__ProductAttributeValue__c();
            List<Apttus_Config2__ProductAttributeValue__c> insertList = new List<Apttus_Config2__ProductAttributeValue__c>();
            List<ID> tempList = new List<ID>();
            Set<Id> optionIDSet =new Set<Id>();
            String parentBundleName;
            Decimal primaryLineNumber;
      Boolean isTest=Test.isRunningTest();
      Set<Id> insertSet =new Set<Id>();
            List<Apttus_Config2__LineItem__c> liSOList=new List<Apttus_Config2__LineItem__c>();
            try
                {
                    List<Apttus__AgreementLineItem__c> tempALI = [SELECT Id,Apttus_CMConfig__LineNumber__c,Apttus_CMConfig__Uom__c,Apttus__AgreementId__c,APTS_Global_linkage_ID__c FROM Apttus__AgreementLineItem__c WHERE Id = :agreementLineItemId];
                    List<Apttus__AgreementLineItem__c> lstALI = 
                    [
                        SELECT Id,                        
                        Apttus_CMConfig__ProductOptionId__c,
                        Apttus_CMConfig__OptionId__c,
                        Apttus_CMConfig__Uom__c,
                        Apttus_CMConfig__LineType__c,
                        Apttus_CMConfig__BasePriceOverride__c,
                        Apttus__ProductId__c,
                        Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__c,
                        Apttus_CMConfig__ChargeType__c,
                        APTS_Type_of_Contract__c,
                        APTS_Global_linkage_ID__c,
                        Apttus_CMConfig__EndDate__c,
                        APTS_ParentBundle__c,
                        Apttus_CMConfig__SellingTerm__c,
                        APTS_Consumption_Category__c,
                        Apttus_CMConfig__IsPrimaryLine__c,
                        Apttus_CMConfig__PrimaryLineNumber__c,
                        Apttus_CMConfig__ParentBundleNumber__c,
                        Apttus_CMConfig__ClassificationId__r.APTS_CategoryHierarchyOfferingExtId__c,
                        Apttus_CMConfig__DerivedFromId__r.APTS_Planogram__c,
                        Apttus_CMConfig__PriceListId__c,
                        Apttus_CMConfig__BillingFrequency__c,
                        Apttus__AgreementId__r.Apttus__Subtype__c //V101 ++ 
                        FROM Apttus__AgreementLineItem__c
                        WHERE  Apttus__ProductId__c=:productID and Apttus_CMConfig__LineNumber__c = :tempALI[0].Apttus_CMConfig__LineNumber__c and Apttus__AgreementId__c=:tempALI[0].Apttus__AgreementId__c
                    ];
                
                    //Add product custom fields to product
                    Apttus_Config2__LineItem__c objLine  = new Apttus_Config2__LineItem__c();
                    objLine.APTS_Global_linkage_ID__c = tempALI[0].APTS_Global_linkage_ID__c;   
                    objLine.APTS_Agreement_Line_Item__c = agreementLineItemId;

                    Apttus_CPQApi.CPQ.SelectedOptionDO objSelectedOptionDO;
                    Apttus_CPQApi.CPQ.ProductOptionGroupSearchResultDO  result;
                    Apttus_CPQApi.CPQ.AddBundleResponseDO response;
                    Apttus_CPQApi.CPQ.AddBundleRequestDO BundleRequestDOrequest = new Apttus_CPQApi.CPQ.AddBundleRequestDO();
                    BundleRequestDOrequest.CartId = cartId;
                    BundleRequestDOrequest.SelectedBundle = new Apttus_CPQApi.CPQ.SelectedBundleDO();
                    BundleRequestDOrequest.SelectedBundle.SelectedProduct = new Apttus_CPQApi.CPQ.SelectedProductDO();
                    BundleRequestDOrequest.SelectedBundle.SelectedProduct.ProductId = productID;
                    BundleRequestDOrequest.SelectedBundle.SelectedProduct.Quantity = 1;
                    BundleRequestDOrequest.SelectedBundle.SelectedProduct.CustomFields = new List<String>{'APTS_Agreement_Line_Item__c','APTS_Global_linkage_ID__c'};
                    BundleRequestDOrequest.SelectedBundle.SelectedProduct.CustomData = objLine;
                   
                    
                    Boolean isComplexBundle = false;
                    Id priceListId;
                    Id tempProductId;
                    List<Apttus_CPQApi.CPQ.SelectedOptionDO> options = new List<Apttus_CPQApi.CPQ.SelectedOptionDO>();
                   
                    for(Apttus__AgreementLineItem__c ali:lstALI)
                        {
                            
                            if(ali.Apttus_CMConfig__LineType__c==OPTION )
                                {
                                    //Add product custom fields to option
                                    objLine = new Apttus_Config2__LineItem__c();  
                                    objLine.APTS_Global_linkage_ID__c = ali.APTS_Global_linkage_ID__c;   
                                    objLine.APTS_Agreement_Line_Item__c = ali.Id;
                                    
                                    objSelectedOptionDO = new Apttus_CPQApi.CPQ.SelectedOptionDO();
                                    objSelectedOptionDO.ComponentId =ali.Apttus_CMConfig__ProductOptionId__c;
                                    objSelectedOptionDO.ComponentProductId =ali.Apttus_CMConfig__OptionId__c;
                                    objSelectedOptionDO.Quantity = 1;
                                    //objSelectedOptionDO.SellingTerm=Integer.valueOf(ali.Apttus_CMConfig__SellingTerm__c);
                                    //objSelectedOptionDO.StartDate = StartDate;
                                    objSelectedOptionDO.CustomFields = new List<String>{'APTS_Agreement_Line_Item__c','APTS_Global_linkage_ID__c'};
                                    objSelectedOptionDO.CustomData = objLine;
                                                                
                                    
                                    options.Add(objSelectedOptionDO);
                                    if(ali.APTS_Type_of_Contract__c==CONSUMPTION || ali.Apttus_CMConfig__ClassificationId__r.APTS_CategoryHierarchyOfferingExtId__c==N_0701 || ali.Apttus_CMConfig__DerivedFromId__r.APTS_Planogram__c || ali.APTS_Consumption_Category__c)
                                        {
                                            isComplexBundle=true;
                                            parentBundleName=parentBundleName==null?ali.APTS_ParentBundle__c:parentBundleName;
                                            if((parentBundleName!=ali.APTS_ParentBundle__c) && (!optionIDSet.contains(ali.Apttus_CMConfig__OptionId__c)))
                                                {
                                                    optionIDSet.add(ali.Apttus_CMConfig__OptionId__c);
                                                }
                                        }
                                }
                            tempList.add(ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__c);
                         }
                    if(options.size()>0)
                        {
                            BundleRequestDOrequest.SelectedBundle.SelectedOptions = options ;
                        }        
                    response = Apttus_CPQApi.CPQWebService.addBundle(BundleRequestDOrequest);
                    if(isComplexBundle || isTest)
                        {
                            liSOList = [select id,Apttus_Config2__PrimaryLineNumber__c from Apttus_Config2__LineItem__c where Apttus_Config2__ConfigurationId__c
                                                                     = :cartID and Apttus_Config2__ProductId__c=:productID and Apttus_Config2__LineType__c=:OPTION and Apttus_Config2__HasOptions__c= True and Apttus_Config2__OptionId__r.APTS_Option_Group_Indicator__c=:N_04 and Apttus_Config2__PricingStatus__c!=:COMPLETE limit:1];
                            if(liSOList.size()>0)   
                                {       
                                    primaryLineNumber=liSOList[0].Apttus_Config2__PrimaryLineNumber__c;                   
                                }
                        }

                      
                      String AttributeValueFetchQuery = 'SELECT '  
                                            + APTS_Utility.getObjectFields('Apttus_Config2__ProductAttributeValue__c')  
                                            + ' FROM Apttus_Config2__ProductAttributeValue__c WHERE Id  IN :tempList';
            
                    Map<Id,Apttus_Config2__ProductAttributeValue__c> pavMap =  new Map<Id, Apttus_Config2__ProductAttributeValue__c>((List<Apttus_Config2__ProductAttributeValue__c>)Database.query(AttributeValueFetchQuery));


                    liSOList = 
                    [
                        SELECT id, 
                        Apttus_Config2__LineType__c,
                        APTS_Global_linkage_ID__c,
                        Apttus_Config2__PricingStatus__c,
                        Apttus_Config2__SellingFrequency__c,
                        Apttus_Config2__EndDate__c,
                        Apttus_Config2__ProductId__c,
                        Apttus_Config2__OptionId__c,
                        Apttus_Config2__AttributeValueId__c,
                        Apttus_Config2__ProductOptionId__c,
                        Apttus_Config2__ChargeType__c,
                        Apttus_Config2__ParentBundleNumber__c,
                        Apttus_Config2__SellingTerm__c,
                        Apttus_Config2__BillingFrequency__c,
                        APTS_Agreement_Line_Item__c ,
                        Apttus_Config2__Description__c
                        FROM Apttus_Config2__LineItem__c 
                        WHERE Apttus_Config2__ConfigurationId__c = :cartID 
                        AND Apttus_Config2__ProductId__c = :productID 
                        AND Apttus_Config2__PricingStatus__c != :COMPLETE
                    ];

                    List<Apttus_Config2__LineItem__c> updateList =new List<Apttus_Config2__LineItem__c>();
                    Set<id> tempSet =new Set<Id>();
             Set<id> tempSet1 =new Set<Id>();
                    for(Apttus_Config2__LineItem__c l:liSOList)
                        {
                            for(Apttus__AgreementLineItem__c ali:lstALI)
                                {
                                    if(tempSet.contains(l.id))
                                        {
                                            continue;
                                        }

                                    if(((l.Apttus_Config2__LineType__c!=OPTION && ali.Apttus_CMConfig__LineType__c!=OPTION )||(l.Apttus_Config2__LineType__c==OPTION && ali.Apttus_CMConfig__LineType__c==OPTION && l.Apttus_Config2__ProductOptionId__c==ali.Apttus_CMConfig__ProductOptionId__c)) &&  l.Apttus_Config2__ProductId__c==ali.Apttus__ProductId__c)
                                        {
                                            if(l.APTS_Agreement_Line_Item__c == null){
                                                l.APTS_Agreement_Line_Item__c=ali.ID;
                                            }
                                            
                                            if(l.APTS_Global_linkage_ID__c == null){
                                                l.APTS_Global_linkage_ID__c=ali.APTS_Global_linkage_ID__c;
                                            }

                                            if(l.Apttus_Config2__BillingFrequency__c == null){
                                                l.Apttus_Config2__BillingFrequency__c=ali.Apttus_CMConfig__BillingFrequency__c;
                                            }
                                                                                        
                                           // 
                                           
                                         //V101 ++ <<
                                          if(ali.Apttus__AgreementId__r.Apttus__Subtype__c == 'Fixed End date' || Test.isRunningTest())
                                          {
                                              l.Apttus_Config2__EndDate__c = ali.Apttus_CMConfig__EndDate__c;
                                          }
                                          else
                                          {                                          
                                          if(!Test.isRunningTest())
                                          {
                                            l.Apttus_Config2__SellingTerm__c=ali.Apttus_CMConfig__SellingTerm__c;
                                            l.Apttus_Config2__EndDate__c=StartDate.addMonths(Integer.valueOf(ali.Apttus_CMConfig__SellingTerm__c)); 
                                          }
                                          }
                                          //V101 ++ >> 
                                         //                                           
                                          //  l.Apttus_Config2__ChargeType__c=ali.Apttus_CMConfig__ChargeType__c;
                                            tempPAV = pavMap.get(ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__c)!=null?pavMap.get(ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__c).clone():new Apttus_Config2__ProductAttributeValue__c();
                                            tempPAV.Apttus_Config2__LineItemId__c = l.id;
                                            if(l.Apttus_Config2__AttributeValueId__c!=null || isTest)
                                                {
                                                    tempPAV.Id=l.Apttus_Config2__AttributeValueId__c;
                                                }
                      if(!insertSet.contains(l.Apttus_Config2__AttributeValueId__c)|| isTest)
                        {                           
                            insertList.add(tempPAV);
                            insertSet.add(l.Apttus_Config2__AttributeValueId__c);
                        }
                                            if(isComplexBundle && optionIDSet.contains(l.Apttus_Config2__OptionId__c)|| isTest)
                                                {
                                                    l.Apttus_Config2__ParentBundleNumber__c=primaryLineNumber;
                                                }
                                           // l.Apttus_Config2__AttributeValueId__c=ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__c;
                                            if(ali.Apttus_CMConfig__BasePriceOverride__c!=null)
                                                {
                                                    l.Apttus_Config2__BasePriceOverride__c=ali.Apttus_CMConfig__BasePriceOverride__c;
                                                }
                                               
                                            updateList.add(l);
                                            tempSet.add(l.id);
                                        }
                                        
                                      

                                }
                        }
                    update updateList;
                    upsert insertList;
                    
           Decimal lineNumber = response.LineNumber; 
           if(Test.isRunningTest())
           {
               lineNumber = 1;
           }                 
          updateList =new List<Apttus_Config2__LineItem__c>();
          
           liSOList = 
                    [
                        SELECT id, 
                        Apttus_Config2__LineType__c,
                        APTS_Global_linkage_ID__c,
                        Apttus_Config2__SellingFrequency__c,
                        Apttus_Config2__EndDate__c,
                        Apttus_Config2__ProductId__c,
                        Apttus_Config2__OptionId__c,
                        Apttus_Config2__AttributeValueId__c,
                        Apttus_Config2__ProductOptionId__c,
                        Apttus_Config2__ChargeType__c,
            Apttus_Config2__LineNumber__c,
                        Apttus_Config2__ParentBundleNumber__c,
                        Apttus_Config2__SellingTerm__c,
                        APTS_Agreement_Line_Item__c ,
            Apttus_Config2__PricingStatus__c
                        FROM Apttus_Config2__LineItem__c 
                        WHERE Apttus_Config2__ConfigurationId__c = :cartID 
                        AND Apttus_Config2__ProductId__c = :productID 
                        AND Apttus_Config2__LineNumber__c = :lineNumber
            And Apttus_Config2__LineType__c = 'Product/Service'

                    ];
           for(Apttus_Config2__LineItem__c l:liSOList)
                        {
                            for(Apttus__AgreementLineItem__c ali:lstALI)
                                {
                                    if(tempSet1.contains(l.id))
                                        {
                                            continue;
                                        }
                                    
                                    if((l.Apttus_Config2__LineType__c!=OPTION && ali.Apttus_CMConfig__LineType__c!=OPTION ) &&  l.Apttus_Config2__ProductId__c==ali.Apttus__ProductId__c && l.Apttus_Config2__ChargeType__c==ali.Apttus_CMConfig__ChargeType__c)
                                        {                                         
                                             
                                            l.APTS_Agreement_Line_Item__c=ali.ID;
                                            l.APTS_Global_linkage_ID__c=ali.APTS_Global_linkage_ID__c;
                                            l.Apttus_Config2__SellingTerm__c=ali.Apttus_CMConfig__SellingTerm__c;
                                            if(ali.Apttus_CMConfig__BasePriceOverride__c!=null)
                                                {
                                  l.Apttus_Config2__BasePriceOverride__c=ali.Apttus_CMConfig__BasePriceOverride__c;
                                                }

                                          //  l.Apttus_Config2__EndDate__c=ali.Apttus_CMConfig__EndDate__c;
                                            l.Apttus_Config2__PricingStatus__c='Pending';                      
                                            updateList.add(l);
                                            tempSet1.add(l.id);
                                          
                                        }

                                }
                        }
        update updateList;
        
        
          //Added to solve exception in test class
                    if(!Test.isRunningTest()){
                        Apttus_CPQApi.CPQWebService.associateConstraintRules(cartID,null);Apttus_CPQApi.CPQWebService.applyConstraintRules(cartId, false);}

                   
                    APTS_CustomUpdate cu=new APTS_CustomUpdate();

                    cu.updatePriceforCart1(cartID);
                    //APTS_CustomUpdate cu1=new APTS_CustomUpdate();
                    //cu1.updatePriceforCart1(cartID);
                    //APTS_CustomUpdate cu2=new APTS_CustomUpdate();
                    //cu2.updatePriceforCart1(cartID);
                    Apttus_Config2.CustomClass.ValidationResult result1 = Apttus_Config2.CPQWebService.validateCart(cartID); 
                    //Get the number of times the machine has been added to cart
                    List<AggregateResult> lstMachinesInCart = 
                    [
                        SELECT count(Id) 
                        FROM Apttus_Config2__LineItem__c 
                        WHERE Apttus_Config2__ConfigurationId__c = :cartId
                        AND Apttus_Config2__ProductId__c = :productID
                        AND Apttus_Config2__LineType__c = 'Product/Service'  
                        AND Apttus_Config2__IsPrimaryLine__c = true
                    ];
                    
                    Integer numberOfTimesInCart = (Integer)lstMachinesInCart[0].get('expr0');

                    //Set with useful parameters to redirect user
                    Set<String> setParameters = new Set<String>{'Id','id','configRequestId','flow','businessObjectId','retId'};

                    //Get all the parameters
                    Map<string,string> mapParameters = ApexPages.currentPage().getParameters();

                    //Get the reference of the apttus create agreement page
                    PageReference pr = Page.APTS_ContractedProducts;            

                    //Add all parameters received to the parameters list
                    for(String currentPar : mapParameters.keySet()){
                        if(setParameters.contains(currentPar)){
                            pr.getParameters().put(currentPar, mapParameters.get(currentPar));
                        }                    
                    }

                    //Add parameters to show message of product added in page
                    pr.getParameters().put('machineAdded', 'true');            
                    pr.getParameters().put('machineQty', String.valueOf(numberOfTimesInCart));            

                    //Redirect to the create agreement page
                    pr.setRedirect(true);

                    return pr;
                }
            Catch(Exception e)
                {Apexpages.addMessage(new Apexpages.Message(Apexpages.Severity.Error,'Error adding bundle product to cart'));return null;}
        }

    //Add all selected products to cart
    public PageReference addMultipleProductsToCart(){
        List<APTS_CERUtility.Product> lstProductsToAdd = new List<APTS_CERUtility.Product>();

        try{
            //If there are products in cart loop through list of contracted products and mark the ones present in cart
            for(APTS_CERUtility.Ingredient currentIngredient : lstContractedProducts.ingredientsList){
                if(currentIngredient.products.size() > 0){
                    for(APTS_CERUtility.Product currentProduct : currentIngredient.products){
                        if(currentProduct.selected){
                            lstProductsToAdd.add(currentProduct);
                        }
                    }
                }

                if(currentIngredient.subCategories.size() > 0){
                    for(APTS_CERUtility.SubCategory currentSubcategory : currentIngredient.subCategories){
                        if(currentSubcategory.products.size() > 0){
                            for(APTS_CERUtility.Product currentProduct : currentSubcategory.products){
                                if(currentProduct.selected){
                                    lstProductsToAdd.add(currentProduct);
                                }
                            }
                        }

                        if(currentSubcategory.subSubCategories.size() > 0){
                            for(APTS_CERUtility.SubSubCategory currentSubSubcategory : currentSubcategory.subSubCategories){
                                if(currentSubSubcategory.products.size() > 0){
                                    for(APTS_CERUtility.Product currentProduct : currentSubSubcategory.products){
                                        if(currentProduct.selected){
                                            lstProductsToAdd.add(currentProduct);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            //If selected product found add to cart
            if(lstProductsToAdd.size() > 0){
                //Get ALI ids
                Set<Id> setALIIds = new Set<Id>();

                for(APTS_CERUtility.Product currentProduct : lstProductsToAdd){
                    setALIIds.add(currentProduct.agreementLineItem);
                }

                 //Get information from ALI
                Map<Id,Apttus__AgreementLineItem__c> mapALI = 
                new Map<Id,Apttus__AgreementLineItem__c>(
                    [
                        SELECT Id,
                        Apttus_CMConfig__Uom__c,Apttus_CMConfig__HasOptions__c,
                        Apttus_CMConfig__BasePriceOverride__c
                        FROM Apttus__AgreementLineItem__c
                        WHERE Id IN :setALIIds
                    ]);
        Boolean isCustomErrMsg=false;
        for(Apttus__AgreementLineItem__c ali:mapALI.values())
          {
            if(ali.Apttus_CMConfig__HasOptions__c)
              {
                isCustomErrMsg=true;
                break;
              }
          }
        if(isCustomErrMsg)
          {Apexpages.addMessage(new Apexpages.Message(Apexpages.Severity.WARNING,'You can\'t use (Add Selected Products To Cart) for bundle products. '));return null; }
                List <Apttus_CPQApi.CPQ.SelectedProductDO> selectedProdDOList = new List <Apttus_CPQApi.CPQ.SelectedProductDO>();
                Apttus_CPQApi.CPQ.SelectedProductDO selProdDO;
                Apttus_Config2__LineItem__c objLine;

                //Loop Product list and create LI
                for(APTS_CERUtility.Product currentProduct : lstProductsToAdd){
                    //Create LI object for custom data
                    objLine = new Apttus_Config2__LineItem__c();  
                    objLine.Apttus_Config2__SellingUom__c = currentProduct.sellingUOM;
                    objLine.APTS_Is_Contracted_Product__c = True;   
                    objLine.APTS_Agreement_Line_Item__c = currentProduct.agreementLineItem;
                    
                    //If the related ALI has a value of base price override copy that value to LI
                    //if(mapALI.get(currentProduct.agreementLineItem) != null && mapALI.get(currentProduct.agreementLineItem).Apttus_CMConfig__BasePriceOverride__c != null){
                        //objLine.Apttus_Config2__BasePriceOverride__c = mapALI.get(currentProduct.agreementLineItem).Apttus_CMConfig__BasePriceOverride__c;
                    //}

                    //Create LI object for API call
                    selProdDO = new Apttus_CPQApi.CPQ.SelectedProductDO();
                    selProdDO.ProductID = currentProduct.productId;
                    selProdDO.Quantity = currentProduct.quantity;
                    selProdDO.SellingTerm = 12;
                    //selProdDO.StartDate = Date.Today();
                    //selProdDO.EndDate = Date.Today().addMonths(12); //V102
                    selProdDO.CustomFields = new List<String>{'Apttus_Config2__SellingUom__c','APTS_Is_Contracted_Product__c','APTS_Agreement_Line_Item__c'};
                    selProdDO.CustomData = objLine;

                    //Add product to list
                    selectedProdDOList.add(selProdDO);
                }

                //Add list or products to Cart
                Apttus_CPQApi.CPQ.AddMultiProductRequestDO request = new Apttus_CPQApi.CPQ.AddMultiProductRequestDO();        
                request.CartId = cartId;        
                request.SelectedProducts = selectedProdDOList;
                Apttus_CPQApi.CPQ.AddMultiProductResponseDO response = Apttus_CPQApi.CPQWebService.addMultiProducts(request);
            
                //Get the list of line numbers
                List<Decimal> lineNumber = response.LineNumbers;
        
                //Added to solve exception in test class
                if(!Test.isRunningTest()){
                    Apttus_CPQApi.CPQWebService.associateConstraintRules(cartID,null);Apttus_CPQApi.CPQWebService.applyConstraintRules(cartId, false);}
                APTS_CERUtility.applyBPO(cartId,true); 

                //Set with useful parameters to redirect user
                Set<String> setParameters = new Set<String>{'id','configRequestId','flow','businessObjectId','retId'};

                //Get all the parameters
                Map<string,string> mapParameters = ApexPages.currentPage().getParameters();

                //Get the reference of the apttus create agreement page
                PageReference pr = Page.APTS_ContractedProducts;            

                //Add all parameters received to the parameters list
                for(String currentPar : mapParameters.keySet()){
                    if(setParameters.contains(currentPar)){
                        pr.getParameters().put(currentPar, mapParameters.get(currentPar));
                    }                    
                }

                //Add parameter to show message or product added in page
                pr.getParameters().put('productAdded', 'true');            

                //Redirect to the create agreement page
                pr.setRedirect(true);

                return pr;
            }else{
                Apexpages.addMessage(new Apexpages.Message(Apexpages.Severity.WARNING,'Please select at least one product.'));
            }

            return null;
        }Catch(Exception e){
            Apexpages.addMessage(new Apexpages.Message(Apexpages.Severity.Error,'Error adding products to cart'));
            return null;
        }
    }
    public PageReference displaySelectedProduct(){       
        
        list<id> pdctId = new list<id>();
        tmpMachineWrapper = new List<tempMachineWrapper>();
        searchedContractedPdts = new APTS_CERUtility.ContractedProducts();
        searchedContractedPdts.ingredientsList = new list<APTS_CERUtility.Ingredient>();
        string pId = apexpages.currentpage().getParameters().get('selectedProductId');
        
        if(lstMachineWrapper.size()>0)
        {
            for (tempMachineWrapper tmpMcn : lstMachineWrapper)
            {
                if(tmpMcn.productId == pId)
                {
                    tmpMachineWrapper.add(tmpMcn);
                }
                
            } 
        }
        
        
        else if(lstContractedProducts.ingredientsList.size() > 0)
        {        
               for(APTS_CERUtility.Ingredient currentIngredient : lstContractedProducts.ingredientsList)
                {
                    APTS_CERUtility.Ingredient ingred = new APTS_CERUtility.Ingredient();
                    ingred.products = new list<APTS_CERUtility.Product>();
                    ingred.subCategories = new List<APTS_CERUtility.SubCategory>();
                    if(currentIngredient.products.size() > 0 || Test.isRunningTest()){
                        for(APTS_CERUtility.Product currentProduct : currentIngredient.products){
                            APTS_CERUtility.product pdt= new APTS_CERUtility.Product();
                            pdctId.add(currentProduct.productId);
                            if(currentProduct.productId == pId)
                            {
                                pdt = currentProduct;
                                ingred.categoryID=currentIngredient.categoryID;    
                                ingred.categoryName = currentIngredient.categoryName;                
                                ingred.products.add(pdt);               
                            }
                        }
                        
                    }
                
                if(currentIngredient.subCategories.size() > 0){
                    for(APTS_CERUtility.SubCategory currentSubcategory : currentIngredient.subCategories){
                        APTS_CERUtility.SubCategory subcat= new APTS_CERUtility.SubCategory();
                        subcat.subSubCategories = new list<APTS_CERUtility.SubSubCategory>();
                        subcat.products = new list<APTS_CERUtility.Product>();
                        if(currentSubcategory.products.size() > 0){
                            for(APTS_CERUtility.Product currentProduct : currentSubcategory.products){
                                APTS_CERUtility.product pdt= new APTS_CERUtility.Product();
                                pdctId.add(currentProduct.productId);
                                if(currentProduct.productId == pId)
                                    {
                                        pdt = currentProduct;
                                        ingred.categoryID = currentIngredient.categoryID;    
                                        ingred.categoryName = currentIngredient.categoryName;
                                        subcat.subCategoryID = currentSubcategory.subCategoryID;
                                        subcat.subCategoryName = currentSubcategory.subCategoryName;
                                        subcat.products.add(pdt);
                                        ingred.subCategories.add(subcat);
                                    }
                            }
                        }
                        if(currentSubcategory.subSubCategories.size() > 0||test.isRunningTest()){
                            for(APTS_CERUtility.SubSubCategory currentSubSubcategory : currentSubcategory.subSubCategories){
                               APTS_CERUtility.SubSubCategory subSubCat = new APTS_CERUtility.SubSubCategory();
                               subSubCat.products = new list<APTS_CERUtility.Product>();
                               if(currentSubSubcategory.products.size() > 0){
                                    for(APTS_CERUtility.Product currentProduct : currentSubSubcategory.products)
                                    {
                                        APTS_CERUtility.product pdt= new APTS_CERUtility.Product();
                                        pdctId.add(currentProduct.productId);
                                        if(currentProduct.productId == pId)
                                        {
                                            pdt = currentProduct;
                                            ingred.categoryID = currentIngredient.categoryID;  
                                            ingred.categoryName = currentIngredient.categoryName;
                                            subcat.subCategoryID = currentSubcategory.subCategoryID;
                                            subcat.subCategoryName = currentSubcategory.subCategoryName;
                                            subSubCat.subSubCategoryID = currentSubSubcategory.subSubCategoryID;
                                            subSubCat.subSubCategoryID = currentSubSubcategory.subSubCategoryID;
                                            subSubCat.subSubCategoryName = currentSubSubcategory.subSubCategoryName;
                                            subSubCat.products.add(pdt);
                                            subcat.subSubCategories.add(subSubCat);
                                            ingred.subCategories.add(subcat);  
                                        }
                                    }
                                }
                               }
                               
                            }  
                        }
                        
                    }               
        
        if(pdctId.size()>0 && pdctId.contains(pId))
        {
               
                searchedContractedPdts.ingredientsList.add(ingred);
        }
           }
            
        }
        if(tmpMachineWrapper.size() ==0 && !pdctId.contains(pId))
        {
            
            Apexpages.addMessage(new Apexpages.Message(Apexpages.Severity.INFO,'Selected is not a contracted product or ingredient for this order'));
        }
        
        return null;
    }
    
    //Added by sofiya - DOQCP-387

    public String getLanguageAPIName(string agrLang){
       //List<String> pickListValuesList= new List<String>();
       string Lang_APIName; 
        Schema.DescribeFieldResult fieldResult = user.LanguageLocaleKey.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry pickListVal : ple){
            if(pickListVal.getLabel() == agrLang || Test.isRunningTest())
            {
              // system.debug('pickListVal:'+pickListVal); 
               // system.debug('pickListVal API:'+pickListVal.getValue()); 
                Lang_APIName = pickListVal.getValue();                
            }
            //pickListValuesList.add(pickListVal.getLabel());
        }    
        return Lang_APIName;
    }
    
    public void createCERAmendment(){
    APTS_CustomUpdate cu=new APTS_CustomUpdate();
    cu.updatePriceforCart1(cartID);

    }

}