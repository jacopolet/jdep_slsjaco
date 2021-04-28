/*************************************************************
@Name: APTS_IntegrationRecordsSelectorCtrl
@Author: Raul Orozco
@CreateDate: 03-27-2018
@Description: Helper class for Integration Records Selector page. 
@UsedBy: APTS_IntegrationRecordsSelector
******************************************************************/
// 08-10-2019 - v101 LAE/RAR - Removed APTS_Serial_Number__c field from level3Items()  query. This field is never used.

public without sharing class APTS_IntegrationRecordsSelectorCtrl {
    // the record that is being edited
    private RTR_LAE_Staging_Data__c opp;

    // the values of the selected items
    public List<string> selectedLevel1 {get; set;}
    public List<string> selectedLevel2 {get; set;}
    public List<string> selectedLevel3 {get; set;}

    //Data list
    public List<wrapperStagingData> lstWrapperStagingData {get; set;}
    public List<wrapperStagingData> lstWrapperSelected {get; set;}
    public Boolean showDataTable {get; set;}
    public List<RTR_LAE_Staging_Data__c> lstStagingRecords {get;set;}

    //Pagination variables
    public Integer numberOfRecordsForPage {get;set;}
    public ApexPages.StandardSetController con {get;set;}
    public Boolean showFirst {get;set;}
    public Boolean showLast {get;set;}
    public Integer intCantidadReg {get; set;}
    public Map<Id,wrapperStagingData> selectedRecordsMap;
    public Integer recordsQuantity {get; set;}
    public static String objectName = 'objectName';

    public APTS_IntegrationRecordsSelectorCtrl() {
        this.showDataTable = false;
        this.selectedLevel1 = new List<string>();
        this.selectedLevel2 = new List<string>();
        this.selectedLevel3 = new List<string>();
        this.numberOfRecordsForPage = 10;
        this.recordsQuantity = 0;
        this.lstStagingRecords = new List<RTR_LAE_Staging_Data__c>();
        this.con = new ApexPages.StandardSetController(lstStagingRecords);
        this.selectedRecordsMap = new Map<Id,wrapperStagingData>();
    }

    //Method to populate number of records per page select
    public List<selectOption> recordsXPage {
        get {
            List<selectOption> options = new List<selectOption>();
            options.add(new SelectOption('5','5'));
            options.add(new SelectOption('10','10'));
            options.add(new SelectOption('20','20'));
            options.add(new SelectOption('30','30'));
            options.add(new SelectOption('50','50'));
            options.add(new SelectOption('100','100'));
            return options;
        }
        set;
    }

    //Method to populate Sales Organizations multiselect
    public List<selectOption> level1Items {
        get {
            List<SelectOption> options = new List<SelectOption>();

            //Clean Agreement selected records
            selectedLevel2 = new List<string>();

            options.add(new SelectOption('','-- Please Select --',true));

            Schema.DescribeFieldResult fieldResult = Account.Sales_Organization__c.getDescribe();
            List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();

            for (Schema.PicklistEntry f : ple) {

                options.add(new SelectOption(f.getValue(),f.getLabel()));
            
            }

            return options;
        }
        set;
    }

    //Method to populate Agreements multiselect
    public List<selectOption> level2Items {
        get {
            List<selectOption> options = new List<selectOption>();
            Set<String> setLevel2 = new Set<String>();

            //Clean Finance Id selected records
            selectedLevel3 = new List<string>();

            //Populate multiselect options
            if (selectedLevel1.size() > 0) {
                options.add(new SelectOption('','-- Please Select --',true));
                for (RTR_LAE_Staging_Data__c cat : [SELECT Id, APTS_Sales_Org__c,
                                                    APTS_Asset_Line_Item__r.Apttus_CMConfig__AgreementId__r.Apttus__FF_Agreement_Number__c, 
                                                    APTS_Asset_Line_Item__r.Apttus_CMConfig__AgreementId__c 
                                                    FROM RTR_LAE_Staging_Data__c 
                                                    WHERE APTS_Sales_Org__c IN :selectedLevel1 
                                                    AND APTS_Asset_Line_Item__r.Apttus_CMConfig__AgreementId__c != null                                                        
                                                    ORDER BY APTS_Sales_Org__c,APTS_Asset_Line_Item__r.Apttus_CMConfig__AgreementId__r.Apttus__FF_Agreement_Number__c
                                                    LIMIT 1000]){
                    //Validate that values are not null before options are created
                    if(cat.APTS_Asset_Line_Item__r.Apttus_CMConfig__AgreementId__c != null && 
                        cat.APTS_Sales_Org__c != null && 
                        cat.APTS_Asset_Line_Item__r.Apttus_CMConfig__AgreementId__r.Apttus__FF_Agreement_Number__c != null &&
                        setLevel2.add(cat.APTS_Asset_Line_Item__r.Apttus_CMConfig__AgreementId__c +
                            cat.APTS_Sales_Org__c +
                            cat.APTS_Asset_Line_Item__r.Apttus_CMConfig__AgreementId__r.Apttus__FF_Agreement_Number__c)){
                        options.add(new SelectOption(cat.APTS_Asset_Line_Item__r.Apttus_CMConfig__AgreementId__c,cat.APTS_Sales_Org__c + ' - ' + cat.APTS_Asset_Line_Item__r.Apttus_CMConfig__AgreementId__r.Apttus__FF_Agreement_Number__c));
                    }
                }
            }

            return options;  
        }
        set;
    }   

    //Method to populate Finance Id Multiselect
    public List<selectOption> level3Items {
        get {
            List<selectOption> options = new List<selectOption>();
            Set<String> setLevel3 = new Set<String>();

            //Populate multiselect options
            if (selectedLevel2.size() > 0) {
                options.add(new SelectOption('','-- Please Select --',true));
                Integer counter = 1;
               // v101 - Removed APTS_Serial_Number__c field from Query.
                for (RTR_LAE_Staging_Data__c cat : [SELECT Id, APTS_Asset_Line_Item__r.APTS_Physical_Asset__r.APTS_FinanceId__c                                                    
                                                    FROM RTR_LAE_Staging_Data__c 
                                                    WHERE APTS_Asset_Line_Item__r.Apttus_CMConfig__AgreementId__c IN :selectedLevel2 
                                                    ORDER BY APTS_Asset_Line_Item__r.APTS_Physical_Asset__r.APTS_FinanceId__c
                                                    LIMIT 1000]){
                    if(cat.APTS_Asset_Line_Item__r.APTS_Physical_Asset__r.APTS_FinanceId__c != null &&
                        setLevel3.add(cat.APTS_Asset_Line_Item__r.APTS_Physical_Asset__r.APTS_FinanceId__c)){
                        options.add(new SelectOption(cat.APTS_Asset_Line_Item__r.APTS_Physical_Asset__r.APTS_FinanceId__c, cat.APTS_Asset_Line_Item__r.APTS_Physical_Asset__r.APTS_FinanceId__c));
                    }  
                }
            }

            return options;
        }
        set;
    }    

    //Wrapper class for Staging Data
    public class wrapperStagingData{
        public RTR_LAE_Staging_Data__c data{get; set;}
        public Boolean checked{get; set;}

        public wrapperStagingData(RTR_LAE_Staging_Data__c parStagingData, Boolean parChecked){
            data = parStagingData;
            checked = parChecked;
        }

        public wrapperStagingData(RTR_LAE_Staging_Data__c parStagingData){
            data = parStagingData;
            checked = false;
        }
    }

    //Method to search for Staging records using filters Sales Organization, Agreements, Finance Id
    public void searchRecords(){
        try{
            //Initialize standard set
            if(this.con == null) {
                this.con = new ApexPages.StandardSetController(lstStagingRecords);
            }

            //Wrapper to store records
            lstWrapperStagingData = new List<wrapperStagingData>();

            //Build initial query
            String query = ' SELECT Id, Name, APTS_Sales_Org__c,'+
            'APTS_Asset_Line_Item__c,'+ 
            'APTS_Asset_Line_Item__r.Apttus_CMConfig__AgreementId__c,'+
            'APTS_Billing_Condition1__c,'+
            'APTS_Billing_Condition2__c, '+
            'APTS_Asset_Line_Item__r.APTS_Physical_Asset__r.APTS_FinanceId__c, '+
            'APTS_AssetProcessed__c, '+
            'APTS_Integration_Log_Id__c, '+
            'APTS_Grouping_Key__c, '+
            'APTS_Asset_Line_Item__r.APTS_Physical_Asset__c '+
            'FROM RTR_LAE_Staging_Data__c ' +
            'WHERE APTS_AssetProcessed__c = false ' +
            'AND APTS_Asset_Line_Item__r.Apttus_Config2__BundleAssetId__c = null ';

            //Add conditions to query
            if(selectedLevel3.size() > 0){
                query += ' AND APTS_Asset_Line_Item__r.APTS_Physical_Asset__r.APTS_FinanceId__c IN :selectedLevel3';
            }else if(selectedLevel2.size() > 0){
                query += ' AND APTS_Asset_Line_Item__r.Apttus_CMConfig__AgreementId__c IN :selectedLevel2';
            }else if(selectedLevel1.size() > 0){
                query += ' AND APTS_Sales_Org__c IN :selectedLevel1';
            }

            query += ' ORDER BY Name LIMIT 10000';

            //Pagination initialization
            this.con = new ApexPages.StandardSetController(Database.getQueryLocator(query));
            this.con.setPageSize(numberOfRecordsForPage);
            this.recordsQuantity = con.getResultSize();

            //Construct structure to show records in page
            getWrapperRecords();        
        }catch(Exception ex){
            this.showDataTable = false;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Error occured searching info. Try again please.'));
            system.debug('Error: ' + ex.getMessage() + '<>' + ex.getStackTraceString());
            APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', ex.getMessage() + '<>' + ex.getStackTraceString(), objectName, null, 'CLM', false, false, null, true);
        }
    }

    //Method to create Integration Log records
    public void createRecords(){
        Boolean errorsInserting = false;
        Integer numberRecords = 0;
        List<RTR_LAE_Staging_Data__c> lstToUpdate = new List<RTR_LAE_Staging_Data__c>();

        //List of records to create
        List<Integration_Log__c> lstIntegrationLogRecords = new List<Integration_Log__c>();

        //Check selected records
        checkSelected();

        //Loop through selected records
        for(wrapperStagingData currentRecord : selectedRecordsMap.values()){
                lstIntegrationLogRecords.add(new Integration_Log__c(
                                                Agreement__c = currentRecord.data.APTS_Asset_Line_Item__r.Apttus_CMConfig__AgreementId__c,
                                                Object_Id__c = currentRecord.data.Id,//Temp value, required for record creation, updated later
                                                Object__c = 'RTR_LAE_Staging_Data__c',
                                                RTR_LAE_Staging__c = currentRecord.data.Id,
                                                Integration_Status__c = INT_Constants.PAUSED
                                            ));
                numberRecords++;
        }

        //Create records
        Database.SaveResult[] srList = Database.insert(lstIntegrationLogRecords, false);

        Set<Id> setIntegrationLogIds = new Set<Id>();

        // Iterate through each returned result
        for (Database.SaveResult sr : srList) {
            if (sr.isSuccess()) {
                // Operation was successful, so get the ID of the record that was processed
                System.debug('Successfully created staging record. Record Id: ' + sr.getId());
                setIntegrationLogIds.add(sr.getId());
            }
            else {
                errorsInserting = true;
                for(Database.Error err : sr.getErrors()) {
                    // Operation failed, so get all errors                
                    system.debug('Error occurred: ' + err.getStatusCode() + ': ' + err.getMessage() + '<>' + err.getFields());  
                }                
            }
        }

        //Check if integration records were created successfully
        if(setIntegrationLogIds.size() > 0){
            Map<String,String> mapAssetIdGroupingKey = new Map<String,String>();

            for(Id currentId : setIntegrationLogIds){
                for(Integration_Log__c currentIL : lstIntegrationLogRecords){
                    if(currentId == currentIL.Id){
                        for(wrapperStagingData currentRecord : selectedRecordsMap.values()){
                            if(currentIL.RTR_LAE_Staging__c == currentRecord.data.Id){
                                currentRecord.data.APTS_AssetProcessed__c = true;
                                currentRecord.data.APTS_Integration_Log_Id__c = currentIL.Id;
                                lstToUpdate.add(currentRecord.data);
                                mapAssetIdGroupingKey.put(currentRecord.data.APTS_Grouping_Key__c, currentIL.Id);
                            }
                        }
                        //Set the value of object id with the Integration Log record id
                        currentIL.Object_Id__c = currentIL.Id;

                        //Change integration status value
                        currentIL.Integration_Status__c = INT_Constants.INITIAL;
                    }
                }
            }

            //If records found update
            if(lstToUpdate.size() > 0){
                update lstToUpdate;
                update lstIntegrationLogRecords;
            }

            //Search related bundle records to add 
            List<RTR_LAE_Staging_Data__c> lstRTRStagingRecords = 
            [
                SELECT Id,
                APTS_Integration_Log_Id__c,
                APTS_Grouping_Key__c,
                APTS_AssetProcessed__c
                FROM RTR_LAE_Staging_Data__c                
                WHERE APTS_Grouping_Key__c IN :mapAssetIdGroupingKey.keySet()
                AND APTS_Integration_Log_Id__c = null
            ];

            if(lstRTRStagingRecords.size() > 0){
                List<RTR_LAE_Staging_Data__c> lstRTRStagingRecordsToUpdate = new List<RTR_LAE_Staging_Data__c>(); 

                for(RTR_LAE_Staging_Data__c currentRTR : lstRTRStagingRecords){
                    if(mapAssetIdGroupingKey.get(currentRTR.APTS_Grouping_Key__c) != null){
                        currentRTR.APTS_Integration_Log_Id__c = mapAssetIdGroupingKey.get(currentRTR.APTS_Grouping_Key__c);

                        //Set the asset processed flag to all the related lines
                        if(!currentRTR.APTS_AssetProcessed__c){
                            currentRTR.APTS_AssetProcessed__c = true;
                        }

                        lstRTRStagingRecordsToUpdate.add(currentRTR);
                    }
                }

                if(lstRTRStagingRecordsToUpdate.size() > 0){
                    update lstRTRStagingRecordsToUpdate;
                }
            }
        }

        if(errorsInserting){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING,'Errors occurred creating Integration Log Records.'));
            this.showDataTable = false;
        }else{
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM,'Records created succesfully.' + ' -- ' + numberRecords));
            clearFilters();
            this.showDataTable = false;
        }
    }

    //Clear filters and found data
    public void clearFilters(){
        this.selectedLevel1 = new List<string>();
        this.selectedLevel2 = new List<string>();
        this.selectedLevel3 = new List<string>();
        this.lstWrapperStagingData = new List<wrapperStagingData>();
        this.selectedRecordsMap = new Map<Id,wrapperStagingData>();
        this.recordsQuantity = 0;
        //this.con.cancel();
        this.con = new ApexPages.StandardSetController(lstStagingRecords);
        this.showDataTable = false;
        this.numberOfRecordsForPage = 10;
    }   

    //Pagination methods
    
    //Returns the wrapper with the list of records
    public List<wrapperStagingData> getWrapperRecords() {
        lstWrapperStagingData = new List<wrapperStagingData>(); 
        Integer noSelected = 0;
        
        for (RTR_LAE_Staging_Data__c currentRecord : (List<RTR_LAE_Staging_Data__c>)con.getRecords()){
            if(selectedRecordsMap.containsKey(currentRecord.Id)){
                lstWrapperStagingData.add(new wrapperStagingData(currentRecord, true));
            }
            else{
                lstWrapperStagingData.add(new wrapperStagingData(currentRecord));
                noSelected++;
            }
        }

        //Show data table or info message if no records found
        if(lstWrapperStagingData.size() > 0){
            this.showDataTable = true;
        }else{
            this.showDataTable = false;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,'No records found.'));
        } 
        
        return lstWrapperStagingData;
    }

    //Check if there are more records
    public Boolean hasNext {
        get {
            if(con.getHasNext())
                this.showLast = true;
            else
                this.showLast = false;
            return con.getHasNext();
        }
        set;
    }

    //Check if there are previous records
    public Boolean hasPrevious {
        get {
            if(con.getHasPrevious())
                this.showFirst = true;
            else
                this.showFirst = false;
            return con.getHasPrevious();
        }
        set;
    }

    //Actual page number
    public Integer pageNumber {
        get {
            return con.getPageNumber();
        }
        set;
    }

    //Total number of pages
    public Integer totalPages{
        get{
            Decimal totalSize = con.getResultSize();
            Decimal pageSize = con.getPageSize();
            Decimal pages = totalSize/pageSize;
            return (Integer)pages.round(System.RoundingMode.CEILING);
        }
        set;
    }

    //Records from first page
     public void first() {
        checkSelected();
        con.first();
        getWrapperRecords();
     }

     //Records from last page
     public void last() {
        checkSelected();
        con.last();
        getWrapperRecords();
     }

     //Previous page records
     public void previous() {
        checkSelected();
        con.previous();
        getWrapperRecords();
     }

    //Next page records
    public void next() {
        checkSelected();
        con.next();
        getWrapperRecords();
    }

    //Method to keep selected records
    public void checkSelected(){
        if(lstWrapperStagingData != null && !lstWrapperStagingData.isEmpty()){
            for (wrapperStagingData currentWrapper : lstWrapperStagingData) {
                if(selectedRecordsMap.containsKey(currentWrapper.data.Id)){
                    if (!currentWrapper.checked){
                        selectedRecordsMap.remove(currentWrapper.data.Id);
                    }
                }else{
                    if (currentWrapper.checked){
                        selectedRecordsMap.put(currentWrapper.data.Id,currentWrapper);
                    }
                }
            }
        }
    }       
}