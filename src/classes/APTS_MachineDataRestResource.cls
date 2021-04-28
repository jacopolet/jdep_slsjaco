/*******************************************************************************************
Name            : APTS_MachineDataRestResource 
Created By      : Amit
Created Date    : 02/22/2018
Description     : Rest Resource Class to send data to VIANET when callout comes from VIANET Endpoint 
Test Class      : APTS_MachineDataRestResourceTest 
********************************************************************************************/
//v102 05-Dec-2018 Balashanthi : Defect# 22018 Added the logic for sitename format (SAP Customer ID - Org Name, City, Street house number )
//v103 03-Jul-2019 Renuka: QTCFLEX1-172 - Removed Asset Status=Cancelled from query. 
//v104 11-Mar-2021 Renuka: DQ-5645 - Adding active status check in 2nd query.
@RestResource(urlMapping='/getAssetDetails/*')
global with sharing class APTS_MachineDataRestResource {
    private static boolean bolTRUE = true;
    private static string ACTIVATED= 'Activated';
    //private static string CANCELLED= 'Cancelled';
    private static String MACHINE = 'Machine';
    private static string PLANNOGRAM = 'Menu';
    private static string YES = 'Yes';
    private static integer allowedHeapSize = 4000000;
    private static String PICO_0104 = '0104';
    private static String PICO_0101 = '0101';
    private static String PRODUCT_SERVICE = 'Product/Service';

    @HttpGet
    global static list<APTS_VIINETInterfacePojo> doGet() {
        APTS_VIINETInterfacePojo vintfc;
        Apttus_Config2__AssetLineItem__c astln;
        list<APTS_VIINETInterfacePojo> lstVet = new list<APTS_VIINETInterfacePojo>();
        map<Id,list<Apttus_Config2__AssetLineItem__c>> mapAssetLine = new map<Id,list<Apttus_Config2__AssetLineItem__c>>();
        map<Id,Apttus_Config2__AssetLineItem__c> mapParentAssetLine = new map<Id,Apttus_Config2__AssetLineItem__c>();
        APTS_Error_Object__c errorObj = new APTS_Error_Object__c();  
        try{
            RestRequest req = RestContext.request;
            RestResponse res = RestContext.response;
            Datetime toDateTimeval;
            Datetime fromDateTimeval;
            
            if(string.isNotBlank(RestContext.request.params.get('fromDateTime')))
                fromDateTimeval = Datetime.valueOfGmt(RestContext.request.params.get('fromDateTime'));
            if(string.isNotBlank(RestContext.request.params.get('toDateTime')))
                toDateTimeval= Datetime.valueOfGmt(RestContext.request.params.get('toDateTime'));
            string serialNumber = String.valueOf(RestContext.request.params.get('serialNumber'));

            Id machineRecTypeId = Schema.SObjectType.PhysicalAsset__c.getRecordTypeInfosByName().get(MACHINE).getRecordTypeId();
            String picoUnitStr = system.label.APTS_PICOUnit;
            
            String phyAssetQry = '';
            String phyAssetQryFinal = '';
            phyAssetQry = 'select id,Apttus_Config2__AccountId__c,Apttus_Config2__AccountId__r.Name,APTS_Physical_Asset__r.UniqueNumber__c,APTS_Physical_Asset__r.SerialNumber__c, toLabel(Apttus_Config2__AccountId__r.Segment__c), toLabel(Apttus_Config2__AccountId__r.Mini_Company_Code__c),\n'+
                                                            'APTS_Physical_Asset__r.Product__r.Name,APTS_Physical_Asset__r.Product__r.APTS_Vendor_Code__c,APTS_Physical_Asset__r.AssetStatus__c,APTS_Physical_Asset__r.Building__c,Apttus_Config2__OptionId__r.ProductCode,\n'+
                                                            'APTS_Physical_Asset__r.Street__c,APTS_Physical_Asset__r.Floor__c,APTS_Physical_Asset__r.City__c,Apttus_Config2__ProductId__r.ProductCode,Apttus_Config2__BillToAccountId__r.SAP_Customer_ID__c,\n'+   
                                                            'APTS_Physical_Asset__r.PostalCode__c,APTS_Physical_Asset__r.Country__c,APTS_Physical_Asset__r.OptionType__c, APTS_Physical_Asset__r.SoldTo__c, APTS_Physical_Asset__r.SoldTo__r.ParentId, APTS_Physical_Asset__r.SoldTo__r.Parent.name, APTS_Physical_Asset__r.SoldTo__r.Ultimate_Parent_Account__c, \n'+
                                                            'APTS_Physical_Asset__r.AccountLocation__r.Apttus_Config2__Type__c,APTS_Physical_Asset__r.AccountLocation__r.SAP_Customer_ID__c,Apttus_Config2__ParentAssetId__c,APTS_Is_Primary_L1_Asset__c,Apttus_Config2__BundleAssetId__c,\n'+
                                                            'APTS_Physical_Asset__r.AccountLocation__r.Name,APTS_Physical_Asset__r.AccountLocation__r.Apttus_Config2__City__c,APTS_Physical_Asset__r.AccountLocation__r.Apttus_Config2__Street__c,APTS_Physical_Asset__r.AccountLocation__r.Shipping_Street_Only__c,APTS_Physical_Asset__r.AccountLocation__r.Shipping_Country_ISO__c,\n'+
                                                            'APTS_Physical_Asset__r.AccountLocation__r.Shipping_House_Number__c,APTS_Physical_Asset__r.AccountLocation__r.House_Number_Supplement__c,APTS_Physical_Asset__r.AccountLocation__c,\n'+
                                                            'APTS_Physical_Asset__r.AccountLocation__r.Mini_Distribution_Channel__c,LastModifiedDate,APTS_Physical_Asset__c,APTS_Option_Group_Text__c ';
            /*if(!string.isBlank(serialNumber) && !(fromDateTimeval==null || toDateTimeval==null)){
               phyAssetQryFinal = phyAssetQry+' from Apttus_Config2__AssetLineItem__c where ((APTS_Physical_Asset__r.RecordTypeId =:machineRecTypeId and APTS_Physical_Asset__r.LastModifiedDate >= :fromDateTimeval and LastModifiedDate <= :APTS_Physical_Asset__r.toDateTimeval) OR APTS_Physical_Asset__r.OptionType__c =: picoUnitStr OR APTS_Physical_Asset__r.OptionType__c =: PICO_0104 OR APTS_Physical_Asset__r.OptionType__c =: PICO_0101 OR APTS_Option_Group_Text__c =: PLANNOGRAM ) and  (Apttus_Config2__AssetStatus__c=:ACTIVATED or Apttus_Config2__AssetStatus__c=:CANCELLED) and (APTS_Physical_Asset__r.UniqueNumber__c=:serialNumber) and (APTS_Physical_Asset__r.Connected__c = :YES)';
            }
            else if(!string.isBlank(serialNumber)){
                phyAssetQryFinal = phyAssetQry+' from Apttus_Config2__AssetLineItem__c where (APTS_Physical_Asset__r.RecordTypeId =:machineRecTypeId OR APTS_Physical_Asset__r.OptionType__c =: picoUnitStr OR APTS_Physical_Asset__r.OptionType__c =: PICO_0104 OR APTS_Physical_Asset__r.OptionType__c =: PICO_0101 OR APTS_Option_Group_Text__c =: PLANNOGRAM ) and (Apttus_Config2__AssetStatus__c=:ACTIVATED or Apttus_Config2__AssetStatus__c=:CANCELLED) and (APTS_Physical_Asset__r.UniqueNumber__c=:serialNumber ) and (APTS_Physical_Asset__r.Connected__c = :YES )';
            }
            else{
                phyAssetQryFinal= phyAssetQry+' from Apttus_Config2__AssetLineItem__c where ((APTS_Physical_Asset__r.RecordTypeId =:machineRecTypeId and APTS_Physical_Asset__r.LastModifiedDate >= :fromDateTimeval and APTS_Physical_Asset__r.LastModifiedDate <= :toDateTimeval) OR APTS_Physical_Asset__r.OptionType__c =: picoUnitStr OR APTS_Physical_Asset__r.OptionType__c =: PICO_0104 OR APTS_Option_Group_Text__c =: PLANNOGRAM )  and  (Apttus_Config2__AssetStatus__c=:ACTIVATED or Apttus_Config2__AssetStatus__c=:CANCELLED) and (APTS_Physical_Asset__r.Connected__c = :YES )';
                
            }*/
            if(!string.isBlank(serialNumber) && !(fromDateTimeval==null || toDateTimeval==null)){
               phyAssetQryFinal = phyAssetQry+' from Apttus_Config2__AssetLineItem__c where (APTS_Physical_Asset__r.RecordTypeId =:machineRecTypeId and APTS_Physical_Asset__r.LastModifiedDate >= :fromDateTimeval and LastModifiedDate <= :APTS_Physical_Asset__r.toDateTimeval)  and  (Apttus_Config2__AssetStatus__c=:ACTIVATED) and (APTS_Physical_Asset__r.UniqueNumber__c=:serialNumber) and (APTS_Physical_Asset__r.Connected__c = :YES) and APTS_Is_Primary_L1_Line__c = true and Apttus_Config2__LineType__c =: PRODUCT_SERVICE';
            }
            else if(!string.isBlank(serialNumber)){
                phyAssetQryFinal = phyAssetQry+' from Apttus_Config2__AssetLineItem__c where APTS_Physical_Asset__r.RecordTypeId =:machineRecTypeId  and (Apttus_Config2__AssetStatus__c=:ACTIVATED) and (APTS_Physical_Asset__r.UniqueNumber__c=:serialNumber ) and (APTS_Physical_Asset__r.Connected__c = :YES ) and APTS_Is_Primary_L1_Line__c = true and Apttus_Config2__LineType__c =: PRODUCT_SERVICE';
            }
            else{
                phyAssetQryFinal= phyAssetQry+' from Apttus_Config2__AssetLineItem__c where (APTS_Physical_Asset__r.RecordTypeId =:machineRecTypeId and APTS_Physical_Asset__r.LastModifiedDate >= :fromDateTimeval and APTS_Physical_Asset__r.LastModifiedDate <= :toDateTimeval )  and  (Apttus_Config2__AssetStatus__c=:ACTIVATED) and (APTS_Physical_Asset__r.Connected__c = :YES ) and APTS_Is_Primary_L1_Line__c = true and Apttus_Config2__LineType__c =: PRODUCT_SERVICE';
                
            }
            phyAssetQryFinal=phyAssetQryFinal+' LIMIT 50000';
            system.debug('phyAssetQryFinal == > '+phyAssetQryFinal);
            
            list<Apttus_Config2__AssetLineItem__c> lstParentAstLn = database.query(phyAssetQryFinal);
            Set<Id> phyAssetIdSet = new Set<Id>();
            system.debug('lstParentAstLn size == > '+lstParentAstLn.size());
            system.debug('lstParentAstLn == > '+lstParentAstLn);
            
            
            for(Apttus_Config2__AssetLineItem__c lineItem : lstParentAstLn){
                phyAssetIdSet.add(lineItem.Id);
            }
            
            string query ='';
            string finalQuery='';
            system.debug('fromDateTimeval ==>'+fromDateTimeval+ ' toDateTimeval == > '+toDateTimeval +' serialNumber==>'+serialNumber);
            query = 'select id,Apttus_Config2__AccountId__c,Apttus_Config2__AccountId__r.Name,APTS_Physical_Asset__r.UniqueNumber__c,APTS_Physical_Asset__r.SerialNumber__c, toLabel(Apttus_Config2__AccountId__r.Segment__c), toLabel(Apttus_Config2__AccountId__r.Mini_Company_Code__c),\n'+
                                                            'APTS_Physical_Asset__r.Product__r.Name,APTS_Physical_Asset__r.Product__r.APTS_Vendor_Code__c,APTS_Physical_Asset__r.AssetStatus__c,APTS_Physical_Asset__r.Building__c,Apttus_Config2__OptionId__r.ProductCode,\n'+
                                                            'APTS_Physical_Asset__r.Street__c,APTS_Physical_Asset__r.Floor__c,APTS_Physical_Asset__r.City__c,Apttus_Config2__ProductId__r.ProductCode,Apttus_Config2__BillToAccountId__r.SAP_Customer_ID__c,\n'+   
                                                            'APTS_Physical_Asset__r.PostalCode__c,APTS_Physical_Asset__r.Country__c,APTS_Physical_Asset__r.OptionType__c, APTS_Physical_Asset__r.SoldTo__c, APTS_Physical_Asset__r.SoldTo__r.ParentId, APTS_Physical_Asset__r.SoldTo__r.Parent.name, APTS_Physical_Asset__r.SoldTo__r.Ultimate_Parent_Account__c, \n'+
                                                            'APTS_Physical_Asset__r.AccountLocation__r.Apttus_Config2__Type__c,APTS_Physical_Asset__r.AccountLocation__r.SAP_Customer_ID__c,Apttus_Config2__ParentAssetId__c,APTS_Is_Primary_L1_Asset__c,Apttus_Config2__BundleAssetId__c,\n'+
                                                            'APTS_Physical_Asset__r.AccountLocation__r.Name,APTS_Physical_Asset__r.AccountLocation__r.Apttus_Config2__City__c,APTS_Physical_Asset__r.AccountLocation__r.Apttus_Config2__Street__c,APTS_Physical_Asset__r.AccountLocation__r.Shipping_Street_Only__c,APTS_Physical_Asset__r.AccountLocation__r.Shipping_Country_ISO__c,\n'+
                                                            'APTS_Physical_Asset__r.AccountLocation__r.Shipping_House_Number__c,APTS_Physical_Asset__r.AccountLocation__r.House_Number_Supplement__c,APTS_Physical_Asset__r.AccountLocation__c,\n'+
                                                            'APTS_Physical_Asset__r.AccountLocation__r.Mini_Distribution_Channel__c,LastModifiedDate,APTS_Physical_Asset__c,APTS_Option_Group_Text__c\n';
                                                            
            /*if(!string.isBlank(serialNumber) && !(fromDateTimeval==null || toDateTimeval==null)){
               finalQuery = query+' from Apttus_Config2__AssetLineItem__c where ((APTS_Physical_Asset__r.RecordTypeId =:machineRecTypeId and APTS_Physical_Asset__r.LastModifiedDate >= :fromDateTimeval and LastModifiedDate <= :APTS_Physical_Asset__r.toDateTimeval) OR APTS_Physical_Asset__r.OptionType__c =: picoUnitStr OR APTS_Physical_Asset__r.OptionType__c =: PICO_0104 OR APTS_Option_Group_Text__c =: PLANNOGRAM ) and  (Apttus_Config2__AssetStatus__c=:ACTIVATED or Apttus_Config2__AssetStatus__c=:CANCELLED) and (APTS_Physical_Asset__r.UniqueNumber__c=:serialNumber OR Apttus_Config2__BundleAssetId__r.APTS_Physical_Asset__r.UniqueNumber__c=:serialNumber) and (APTS_Physical_Asset__r.Connected__c = :YES OR Apttus_Config2__BundleAssetId__r.APTS_Physical_Asset__r.Connected__c = :YES)';
                //finalQuery = query+' from Apttus_Config2__AssetLineItem__c where Apttus_Config2__ProductId__r.Family =:MACHINE and (LastModifiedDate >= :fromDateTimeval and LastModifiedDate <= :toDateTimeval) and  (Apttus_Config2__AssetStatus__c=:ACTIVATED or Apttus_Config2__AssetStatus__c=:CANCELLED) and APTS_Physical_Asset__r.UniqueNumber__c=:serialNumber';
            }
            else if(!string.isBlank(serialNumber)){
                finalQuery = query+' from Apttus_Config2__AssetLineItem__c where (APTS_Physical_Asset__r.RecordTypeId =:machineRecTypeId OR APTS_Physical_Asset__r.OptionType__c =: picoUnitStr OR APTS_Physical_Asset__r.OptionType__c =: PICO_0104 OR APTS_Option_Group_Text__c =: PLANNOGRAM ) and (Apttus_Config2__AssetStatus__c=:ACTIVATED or Apttus_Config2__AssetStatus__c=:CANCELLED) and (APTS_Physical_Asset__r.UniqueNumber__c=:serialNumber OR Apttus_Config2__BundleAssetId__r.APTS_Physical_Asset__r.UniqueNumber__c=:serialNumber) and (APTS_Physical_Asset__r.Connected__c = :YES OR Apttus_Config2__BundleAssetId__r.APTS_Physical_Asset__r.Connected__c = :YES)';
                //finalQuery = query+' from Apttus_Config2__AssetLineItem__c where Apttus_Config2__ProductId__r.Family =:MACHINE and (Apttus_Config2__AssetStatus__c=:ACTIVATED or Apttus_Config2__AssetStatus__c=:CANCELLED) and APTS_Physical_Asset__r.UniqueNumber__c=:serialNumber';
            }
            else{
                finalQuery= query+' from Apttus_Config2__AssetLineItem__c where ((APTS_Physical_Asset__r.RecordTypeId =:machineRecTypeId and APTS_Physical_Asset__r.LastModifiedDate >= :fromDateTimeval and APTS_Physical_Asset__r.LastModifiedDate <= :toDateTimeval) OR APTS_Physical_Asset__r.OptionType__c =: picoUnitStr OR APTS_Physical_Asset__r.OptionType__c =: PICO_0104 OR APTS_Option_Group_Text__c =: PLANNOGRAM )  and  (Apttus_Config2__AssetStatus__c=:ACTIVATED or Apttus_Config2__AssetStatus__c=:CANCELLED) and (APTS_Physical_Asset__r.Connected__c = :YES OR Apttus_Config2__BundleAssetId__r.APTS_Physical_Asset__r.Connected__c = :YES)';
                
                //finalQuery= query+' from Apttus_Config2__AssetLineItem__c where Apttus_Config2__ProductId__r.Family =:MACHINE and (LastModifiedDate >= :fromDateTimeval and LastModifiedDate <= :toDateTimeval) and  (Apttus_Config2__AssetStatus__c=:ACTIVATED or Apttus_Config2__AssetStatus__c=:CANCELLED)';
            }*/
            Integer lim = Limits.getLimitQueryRows() - Limits.getQueryRows();
            finalQuery=query+' from Apttus_Config2__AssetLineItem__c where (APTS_Is_Primary_L1_Asset__c IN: phyAssetIdSet ) and Apttus_Config2__AssetStatus__c =: ACTIVATED and (((APTS_Physical_Asset__r.OptionType__c =: picoUnitStr OR APTS_Physical_Asset__r.OptionType__c =: PICO_0104 OR APTS_Physical_Asset__r.OptionType__c =: PICO_0101) and APTS_Physical_Asset__r.Connected__c =: YES) OR APTS_Option_Group_Text__c =: PLANNOGRAM) LIMIT '+lim;
            system.debug('finalQuery == > '+finalQuery);
            list<Apttus_Config2__AssetLineItem__c> lstAstLn = database.query(finalQuery);
            system.debug('lstAstLn size for options == > '+lstAstLn.size());
            //system.debug('lstAstLn == > '+lstAstLn);
            //Add all the Primary Asset Line Items to the Option Line items list
            lstAstLn.addall(lstParentAstLn);
            system.debug('lstAstLn size after adding primary assets == > '+lstAstLn.size());
            
            
            for(Apttus_Config2__AssetLineItem__c lineItem : lstAstLn){
                
                if(lineItem.APTS_Is_Primary_L1_Asset__c ==null && lineItem.APTS_Physical_Asset__c!=null){

                    mapParentAssetLine.put(lineItem.Id,lineItem);
                }else{
                    if(!mapAssetLine.isEmpty() && mapAssetLine.containskey(lineItem.APTS_Is_Primary_L1_Asset__c) ){
                        list<Apttus_Config2__AssetLineItem__c> lstAst = mapAssetLine.get(lineItem.APTS_Is_Primary_L1_Asset__c);
                        lstAst.add(lineItem);
                        if(lineItem.APTS_Is_Primary_L1_Asset__c!=null)
                        mapAssetLine.put(lineItem.APTS_Is_Primary_L1_Asset__c,lstAst);    
                    }else{
                        list<Apttus_Config2__AssetLineItem__c> lstAstLnnew = new list<Apttus_Config2__AssetLineItem__c>();
                        lstAstLnnew.add(lineItem);
                        if(lineItem.APTS_Is_Primary_L1_Asset__c!=null)
                        mapAssetLine.put(lineItem.APTS_Is_Primary_L1_Asset__c,lstAstLnnew); 
                    }
                }

                
            }   
            
            for(Id key : mapParentAssetLine.keyset()){
                
                vintfc = new APTS_VIINETInterfacePojo();
                astln = new Apttus_Config2__AssetLineItem__c();
                String siteName = '';
                astln = !mapParentAssetLine.isEmpty() ? mapParentAssetLine.get(key) : Null;
                list<Apttus_Config2__AssetLineItem__c> lstAln =  new list<Apttus_Config2__AssetLineItem__c>();

                if(!mapAssetLine.isEmpty()){
                    lstAln = mapAssetLine.get(key);
                    
                    if(lstAln!=null){
                        for(Apttus_Config2__AssetLineItem__c astlnv : lstAln){
                            //Check if Pico unit is null and not set to 0106 LI
                            if(vintfc.TelemetrySerial == null && astlnv.APTS_Physical_Asset__r.OptionType__c == PICO_0101)
                                vintfc.TelemetrySerial = astlnv.APTS_Physical_Asset__r.SerialNumber__c;
                            if(vintfc.TelemetrySerial == null && astlnv.APTS_Physical_Asset__r.OptionType__c == PICO_0104)
                                vintfc.TelemetrySerial = astlnv.APTS_Physical_Asset__r.SerialNumber__c;
                            if(astlnv.APTS_Physical_Asset__r.OptionType__c == system.label.APTS_PICOUnit)
                                vintfc.TelemetrySerial = astlnv.APTS_Physical_Asset__r.SerialNumber__c;
                            if(astlnv.APTS_Option_Group_Text__c != Null && 
                            PLANNOGRAM.equalsIgnoreCase(astlnv.APTS_Option_Group_Text__c))
                            if(null != astlnv.Apttus_Config2__OptionId__r)
                                vintfc.PlanogramID = astlnv.Apttus_Config2__OptionId__r.ProductCode;
                        } 
                    }   
                }
                
                //Added as part of defect #21991
                vintfc.SiteReference =astln.APTS_Physical_Asset__r.AccountLocation__r.SAP_Customer_ID__c;
                //if(null != astln.Apttus_Config2__BillToAccountId__r)
                    //vintfc.SiteReference = astln.Apttus_Config2__BillToAccountId__r.SAP_Customer_ID__c;
                    
                vintfc.SerialNumber = astln.APTS_Physical_Asset__r.UniqueNumber__c;
                vintfc.MachineModel = astln.APTS_Physical_Asset__r.Product__r.Name;
                vintfc.OrganisationName = astln.APTS_Physical_Asset__r.SoldTo__c != null && astln.APTS_Physical_Asset__r.SoldTo__r.ParentId != null ? astln.APTS_Physical_Asset__r.SoldTo__r.Parent.name : astln.APTS_Physical_Asset__r.SoldTo__r.Ultimate_Parent_Account__c;
                vintfc.Status = astln.APTS_Physical_Asset__r.AssetStatus__C;
                
                //vintfc.SiteName = astln.APTS_Physical_Asset__r.Building__c +' '+ astln.APTS_Physical_Asset__r.Street__C;
                //v101 ++ << Changes for Defect# 22018 Added the logic for sitename format
                if(astln.APTS_Physical_Asset__c != null
                    && astln.APTS_Physical_Asset__r.AccountLocation__c != null){
                    // SAP Customer Id
                    if(astln.APTS_Physical_Asset__r.AccountLocation__r.SAP_Customer_ID__c != null){
                        siteName = astln.APTS_Physical_Asset__r.AccountLocation__r.SAP_Customer_ID__c;
                    }
                    // Account Name
                    if(astln.APTS_Physical_Asset__r.AccountLocation__r.Name != null){
                        if(String.isNotBlank(siteName)){
                            siteName += '-'+astln.APTS_Physical_Asset__r.AccountLocation__r.Name;
                        }else{
                            siteName += astln.APTS_Physical_Asset__r.AccountLocation__r.Name;
                        } 
                    }
                    // City
                    if(astln.APTS_Physical_Asset__r.AccountLocation__r.Apttus_Config2__City__c != null){
                        if(String.isNotBlank(siteName)){
                            siteName += ','+astln.APTS_Physical_Asset__r.AccountLocation__r.Apttus_Config2__City__c;
                        }else{
                            siteName += astln.APTS_Physical_Asset__r.AccountLocation__r.Apttus_Config2__City__c;
                        }
                    }
                    // Street
                    if(astln.APTS_Physical_Asset__r.AccountLocation__r.Apttus_Config2__Street__c != null){
                        if(String.isNotBlank(siteName)){
                            siteName += ','+astln.APTS_Physical_Asset__r.AccountLocation__r.Apttus_Config2__Street__c;
                        }else{
                            siteName += astln.APTS_Physical_Asset__r.AccountLocation__r.Apttus_Config2__Street__c;
                        }
                    }
                    // House Number
                    if(astln.APTS_Physical_Asset__r.AccountLocation__r.Shipping_House_Number__c != null){
                        siteName += ' '+astln.APTS_Physical_Asset__r.AccountLocation__r.Shipping_House_Number__c;
                    }
                    // House Number Supplement
                    if(astln.APTS_Physical_Asset__r.AccountLocation__r.House_Number_Supplement__c != null){
                        siteName += ' '+astln.APTS_Physical_Asset__r.AccountLocation__r.House_Number_Supplement__c;
                    }
                }
                system.debug('==>siteName==>'+siteName);
                if(string.isNotBlank(siteName)){
                  vintfc.SiteName =  siteName;
                }
                //v101 ++ >> Changes for Defect# 22018 Added the logic for sitename format
                //vintfc.SiteName = astln.APTS_Physical_Asset__r.AccountLocation__r.Apttus_Config2__City__c+','+
                vintfc.OnsiteLocation  = astln.APTS_Physical_Asset__r.Floor__c;
                vintfc.City = astln.APTS_Physical_Asset__r.City__c;
                vintfc.PostCode = astln.APTS_Physical_Asset__r.PostalCode__C;
                vintfc.Country = astln.APTS_Physical_Asset__r.AccountLocation__r.Shipping_Country_ISO__c;
                //vintfc.DatetimeResponse = String.valueOfGmt(Datetime.now());
                //Modified below line as part of defect #21602
                vintfc.Manufacturer = astln.APTS_Physical_Asset__r.Product__r.APTS_Vendor_Code__c ;
                
                /*list<Apttus_Config2__AssetAttributeValue__c> atrval =  astln.Apttus_Config2__AssetAttributeValues__r;
                if(!atrval.isEmpty() && atrval.size() ==1){
                    
                    vintfc.Manufacturer = atrval[0].Apttus_Config2__Vendor__c;
                    
                    
                }*/

                vintfc.SiteType = astln.APTS_Physical_Asset__r.AccountLocation__r.Apttus_Config2__Type__c;
                vintfc.Channel = astln.Apttus_Config2__AccountId__r.Segment__c;
                vintfc.CompanyCode = astln.Apttus_Config2__AccountId__r.Mini_Company_Code__c;
                //Serialize the POJO list to calculate the charactercount
                //vintfc.ResponseSize = String.valueOf((JSON.serialize(vintfc)).length());
                lstVet.add(vintfc);

                //Check the heap size. If exceeded, break, else continue. Heap limit kept as 4MB, 2MB buffer for further processing of response
                //if(Limits.getHeapSize() > allowedHeapSize) // commented by Amit
                    //break;
               //}      
            }
            
        }catch(Exception e){
            
            vintfc = new APTS_VIINETInterfacePojo();
            vintfc.customErrorMessage = e.getMessage();
            //Serialize the POJO list to calculate the charactercount
            //vintfc.ResponseSize = String.valueOf((JSON.serialize(vintfc)).length());
            lstVet.add(vintfc); 
            system.debug('exception occurred in **** ===> '+e);
            system.debug('e===> '+e.getLineNumber());
            errorObj = APTS_CustomLogging.createErrorLog(e.getTypeName(), 
                        'Apex', e.getStackTraceString() ,'Apttus_Config2__AssetLineItem__c', 'BIR_Email' ,
                        'BIR', False, False,' ', false);
                        
            if(errorObj != null){
                Database.Insert(errorObj);
            }
         }
         
         return lstVet;
    }        


}