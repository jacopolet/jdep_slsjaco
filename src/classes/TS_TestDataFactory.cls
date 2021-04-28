/**
* @author        Paul Jarred Aguiling
* @date          3.20.2017           
* @description   Class responsible for Technical Services Workstream 
*                test data creation
* @revision(s)f
*/
//@isTest
public without sharing class TS_TestDataFactory {
    
    public static List<Account> createAccounts(Integer i) {
        List<Account> accList = new List<Account>();
        
        for(integer x = 0; x<=i; x++){
            Account acc = new Account();
            acc.Name = 'accName' + i;
            acc.Phone = '+31302979111';
            accList.add(acc);
        }
        
        return accList;
    }
    
    public static List<Apttus_Config2__Order__c> createOrders(Integer i){
        List<Apttus_Config2__Order__c> orderList = new List<Apttus_Config2__Order__c>();
        
        for(integer x = 0; x<=i; x++){
            Apttus_Config2__Order__c order = new Apttus_Config2__Order__c();
            orderList.add(order);
        }
        
        return orderList;
    }
    
    public static List<WorkOrder> createWorkOrderList(Integer i)
    {
        List<WorkOrder> woList = new List<WorkOrder>();
        
        for(integer x = 0; x<=i; x++){
            WorkOrder wo = new WorkOrder();
            woList.add(wo);
        }
        
        return woList;
    }
    
    public static List<WorkOrderLineItem> createWorkOrderLineItemList(Integer i, Id woId)
    {
        List<WorkOrderLineItem> woliList = new List<WorkOrderLineItem>();
        
        for(integer x = 0; x<=i; x++){
            WorkOrderLineItem woli = new WorkOrderLineItem(ParentWorkOrderLineItemId = woId);
            woliList.add(woli);
        }
        
        return woliList;
    }
    
    public static Resource__c createResourceSingle(String resourceName)
    {
        return new Resource__c(Name = resourceName);
    }

    /**
    * @author         Paul Jarred Aguiling
    * @date           04.04.2017
    * @param          sProfile : Value for User profile
    * @return         User object
    * @description    This Method will called from the test class with the respective
    *                 parameters it will instantiate the object and return it to the
    *                 test class
    */
    public static user createUser(string sProfile) {
        UserRole usrRole = [SELECT id, Name from UserRole LIMIT 1];
        profile prof = [SELECT Id FROM Profile WHERE Name = : sProfile LIMIT 1];
        User usr = new User(Alias = 'test01', Email = 'testemail@test.jdecoffee.com',
                            EmailEncodingKey = 'UTF-8', LastName = 'Testing01',
                            LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US',
                            ProfileId = prof.Id, TimeZoneSidKey = 'America/Los_Angeles',
                            UserName = 'username@jdecoffee.com' 
                            //.Elevated_Access_Reason__c = 'Manual deployment', 
                            //Elevated_Access_Reference__c = 'Test Class Running User'
                            );
        insert usr;
        return usr;
    }
      /**
    * @author         Archi Delphinanto
    * @date           04.04.2018
    * @param          sProfile : Value for User profile
    * @return         User object for click
    * @description    This Method will called from the test class with the respective
    *                 parameters it will instantiate the object and return it to the
    *                 test class
    */
    public static user createClickUser(string sProfile) {
        UserRole usrRole = [SELECT id, Name from UserRole LIMIT 1];
        profile prof = [SELECT Id FROM Profile WHERE Name = : sProfile LIMIT 1];
        User usr = new User(Alias = 'capi', Email = 'testemail@test.jdecoffee.com',
                            EmailEncodingKey = 'UTF-8', 
                            LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US',
                            ProfileId = prof.Id, TimeZoneSidKey = 'America/Los_Angeles',
                            UserName = 'capiuser@jde.com'
                            //,Elevated_Access_Reason__c = 'Manual deployment', 
                            //Elevated_Access_Reference__c = 'Test Class Running User'
                            );
        usr.FirstName= 'ClickSoftware';
        usr.LastName ='API User';// IntegrationUserAndProfile__c.getInstance().Click_Integration_Name__c ;
        insert usr;
        return usr;
    }

    /**
    * @author         Paul Jarred Aguiling
    * @date           04.04.2017
    * @param          caseType : Value for Case type
    * @param          caseSub : Value for Case Subject
    * @return         Case object
    * @description    This Method will called from the test class with the respective
    *                 parameters it will instantiate the object and return it to the
    *                 test class
    */
    public static Case createCase(String caseSubj) {
        Case cse = new Case();
        cse.Subject = caseSubj;
        cse.Status = Label.TS_Status_New;

        insert cse;
        return cse;
    }

    /**
    * @author         Paul Jarred Aguiling
    * @date           04.04.2017
    * @return         Work Order object
    * @description    This Method will called from the test class with the respective
    *                 parameters it will instantiate the object and return it to the
    *                 test class
    */
    public static WorkOrder createWorkOrder() {
        WorkOrder wo = new WorkOrder();
        wo.Status = Label.TS_Status_New;
        wo.Priority = Label.TS_WO_Priority_Low;

        //insert wo;
        return wo;
    }

    /**
    * @author         Paul Jarred Aguiling
    * @date           04.04.2017
    * @param          workOrdrId : Id of Work Order Id
    * @return         Work Order Line Item object
    * @description    This Method will called from the test class with the respective
    *                 parameters it will instantiate the object and return it to the
    *                 test class
    */
    public static WorkOrderLineItem createWorkOrderLineItem(Id workOrdrId) {
        WorkOrderLineItem woli = new WorkOrderLineItem();
        woli.Status = Label.TS_Status_Open;
        woli.WorkOrderId = workOrdrId;

        //insert woli;
        return woli;
    }

    /**
    * @author         Paul Jarred Aguiling
    * @date           23.05.2017
    * @return         Work Order Line Item object
    * @description    This Method will called from the test class with the respective
    *                 parameters it will instantiate the object and return it to the
    *                 test class
    */
    public static Apttus_Config2__Order__c createOrderRecord(String status, String type) {
        Apttus_Config2__Order__c ord = new Apttus_Config2__Order__c();
        ord.Apttus_Config2__Status__c = status;
        ord.Apttus_Config2__Type__c = type;
        return ord;
    }

    /**
    * @author         Paul Jarred Aguiling
    * @date           23.05.2017
    * @return         Work Order Line Item object
    * @description    This Method will called from the test class with the respective
    *                 parameters it will instantiate the object and return it to the
    *                 test class
    */
    public static Apttus_Config2__OrderLineItem__c createOrderLineItem(String status, Id prodId, Id orderId, Id optionProdId) {
        Apttus_Config2__OrderLineItem__c ord = new Apttus_Config2__OrderLineItem__c();
        ord.Apttus_Config2__LineStatus__c = status;
        ord.Apttus_Config2__ProductId__c = prodId;
        ord.Apttus_Config2__OrderId__c = orderId;
        ord.Apttus_Config2__OptionId__c = optionProdId;
        return ord;
    }

    /**
    * @author         Paul Jarred Aguiling
    * @date           23.05.2017
    * @return         Work Order Line Item object
    * @description    This Method will called from the test class with the respective
    *                 parameters it will instantiate the object and return it to the
    *                 test class
    */
    public static Product2 createProduct(String name, String familyName) {
        Product2 prod = new Product2();
        prod.Name = name;
        prod.Family = 'familyName';
        prod.Apttus_Config2__ConfigurationType__c = 'Bundle';
        return prod;
    }


    /**
    * @author         Rey Austral
    * @date           30.05.2017
    * @return         Case object
    * @description    This Method will called from the test class with the respective
    *                 parameters it will instantiate the object and return it to the
    *                 test class
    */
    public static Case createFieldServiceCase() {
        Case cse = new Case();
        cse.Type = Label.TS_Case_Type_FieldService;
        cse.Origin = Label.TS_Case_Origin_Telefoon;
        cse.SubType__c = Label.TS_Case_SubType_CorrectMaintAPI;
        cse.RecordTypeId = TS_UtilityClass.getRecordTypeIdByName('Case', Label.TS_Case_RecordType_Field);        
        return cse;
    }

    /**
    * @author         Rey Austral
    * @date           30.05.2017
    * @return         Case object
    * @description    This Method will called from the test class with the respective
    *                 parameters it will instantiate the object and return it to the
    *                 test class
    */
    public static Contact createContact() {
        Contact con = new Contact();
        con.LastName = 'test';
        con.Phone = '+31302979111';     
        return con;
    }

    public static String createBase64() {
        return '/9j/4AAQSkZJRgABAQEAYABgAAD/2wBDAAgGBgcGBQgHBwcJCQgKDBQNDAsLDBkSEw8UHRofHh0aHBwgJC4nICIsIxwcKDcpLDAxNDQ0Hyc5PTgyPC4zNDL/2wBDAQkJCQwLDBgNDRgyIRwhMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjL/wAARCAA9APoDASIAAhEBAxEB/8QAHwAAAQUBAQEBAQEAAAAAAAAAAAECAwQFBgcICQoL/8QAtRAAAgEDAwIEAwUFBAQAAAF9AQIDAAQRBRIhMUEGE1FhByJxFDKBkaEII0KxwRVS0fAkM2JyggkKFhcYGRolJicoKSo0NTY3ODk6Q0RFRkdISUpTVFVWV1hZWmNkZWZnaGlqc3R1dnd4eXqDhIWGh4iJipKTlJWWl5iZmqKjpKWmp6ipqrKztLW2t7i5usLDxMXGx8jJytLT1NXW19jZ2uHi4+Tl5ufo6erx8vP09fb3+Pn6/8QAHwEAAwEBAQEBAQEBAQAAAAAAAAECAwQFBgcICQoL/8QAtREAAgECBAQDBAcFBAQAAQJ3AAECAxEEBSExBhJBUQdhcRMiMoEIFEKRobHBCSMzUvAVYnLRChYkNOEl8RcYGRomJygpKjU2Nzg5OkNERUZHSElKU1RVVldYWVpjZGVmZ2hpanN0dXZ3eHl6goOEhYaHiImKkpOUlZaXmJmaoqOkpaanqKmqsrO0tba3uLm6wsPExcbHyMnK0tPU1dbX2Nna4uPk5ebn6Onq8vP09fb3+Pn6/9oADAMBAAIRAxEAPwD0PwZ4M8K3XgXw9cXHhnRpp5dMtnkkksImZ2MSkkkrkknvW5/wgng//oVND/8ABdD/APE0eBP+SeeGf+wVa/8Aopa6CgDn/wDhBPB//QqaH/4Lof8A4mj/AIQTwf8A9Cpof/guh/8Aia6CigDn/wDhBPB//QqaH/4Lof8A4mj/AIQTwf8A9Cpof/guh/8Aia6CigDn/wDhBPB//QqaH/4Lof8A4mj/AIQTwf8A9Cpof/guh/8Aia6CigDn/wDhBPB//QqaH/4Lof8A4mj/AIQTwf8A9Cpof/guh/8Aia6CigDn/wDhBPB//QqaH/4Lof8A4mj/AIQTwf8A9Cpof/guh/8Aia6CigDn/wDhBPB//QqaH/4Lof8A4mj/AIQTwf8A9Cpof/guh/8Aia6CigDn/wDhBPB//QqaH/4Lof8A4mj/AIQTwf8A9Cpof/guh/8Aia6CigDn/wDhBPB//QqaH/4Lof8A4mj/AIQTwf8A9Cpof/guh/8Aia6Cuf8A+E78H/8AQ16H/wCDGH/4qgA/4QTwf/0Kmh/+C6H/AOJo/wCEE8H/APQqaH/4Lof/AImj/hO/B/8A0Neh/wDgxh/+Ko/4Tvwf/wBDXof/AIMYf/iqAD/hBPB//QqaH/4Lof8A4mj/AIQTwf8A9Cpof/guh/8AiaP+E78H/wDQ16H/AODGH/4qse++MHgHT7yS1m8RwPImMmCKSZDkA8OilT17Hjp1oA2P+EE8H/8AQqaH/wCC6H/4mj/hBPB//QqaH/4Lof8A4muf/wCF2/Dz/oYf/JK4/wDjdU9S+PPgOxt1lt7671By+0xWto6sBg/MfM2DHGOueRx1oA6z/hBPB/8A0Kmh/wDguh/+Jo/4QTwf/wBCpof/AILof/ia4/TPjjo+t+b/AGT4Y8V3/k48z7JYJLsznGdshxnB6+hrqPDnjT/hI9Rks/8AhGfEel7IjL52p2HkRtggbQ245bnOPQH0oAsf8IJ4P/6FTQ//AAXQ/wDxNH/CCeD/APoVND/8F0P/AMTXQUUAc/8A8IJ4P/6FTQ//AAXQ/wDxNH/CCeD/APoVND/8F0P/AMTXQUUAc/8A8IJ4P/6FTQ//AAXQ/wDxNfHnjOCG18deIbe3ijhgi1O5SOONQqoolYAADgADtX3HXxB47/5KH4m/7Ct1/wCjWoA+v/An/JPPDP8A2CrX/wBFLXQVz/gT/knnhn/sFWv/AKKWugoAKKKKACiiigAooooAK8/8Q2uu+L/Gi6Fb3GuaFoWmReddajZuITezOBsjifrtUFixGRkEEAhWrtNWs5tQ0a+sre7ks57i3kijuY87oWZSA4wQcgnPUdOteXw/CbxlA5dPixrJJRk+eKRxhlKnhpiM4PB6g4IwQDQBuf8ACrP+p98c/wDg4/8AsKP+FWf9T745/wDBx/8AYVn6Z8JtYi83+1viX4rus48v7Jdvb7euc7mfd26Yxg9c8aH/AApXwJJ+8vNKnvbpuZrq4vpzJM5+87kOAWJyTgDk9KAKepeAtN0a3W41T4m+LrGBn2LJda8sSlsE4BZQM4B49jWX/Y/g/wD6LPrn/hUQ/wCFdRY/B/wDp95HdQ+HIHkTOBPLJMhyCOUdip69xx161sf8IJ4P/wChU0P/AMF0P/xNAHn/APY/g/8A6LPrn/hUQ/4VHB4J+B8NvFE+oaNO6IFaWTXSGcgfeO2UDJ68AD0Ar0T/AIQTwf8A9Cpof/guh/8AiaP+EE8H/wDQqaH/AOC6H/4mgDz/AP4Q34Gf8/Wh/wDg+b/49XQZ+EZ5ln8GzyHlpbia2lkkPdndyWdj1LMSSeSSa6D/AIQTwf8A9Cpof/guh/8Aiakj8GeFYUmSLwzoyJMmyVVsIgHXcGw3y8jcqnB7gHtQBzf/ABaD/qRv/JSj/i0H/Ujf+SldB/wgng//AKFTQ/8AwXQ//E0f8IJ4P/6FTQ//AAXQ/wDxNAHD33iX4I6feSWs1v4ceRMZMGkiZDkA8OkZU9ex46dayPE/xF8Gp4Sm0rwH4hsdBup5dzvDYzW6bSu1j8tux3EYAK7WGAd3GD7Hpuk6bo1u1vpen2ljAz72jtYViUtgDJCgDOAOfYVcoA+SEstQMtrqOm+ENK8Ws2JpdStYtRuhJMGO4ThnUeYSNzKyAEODjDCva/Al58RLbVLbTNa8F6NpWghHG7TnjjEDcsDsWVsgtkEADls54OfTKKACiiigAooooAKKKKACviDx3/yUPxN/2Fbr/wBGtX2/XxB47/5KH4m/7Ct1/wCjWoA+v/An/JPPDP8A2CrX/wBFLXQVz/gT/knnhn/sFWv/AKKWugoAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAr4g8d/wDJQ/E3/YVuv/RrV9v18QeO/wDkofib/sK3X/o1qAPr/wACf8k88M/9gq1/9FLXQV84aF+0P/Ynh7TNJ/4RbzvsNpFbeb/aG3fsQLux5ZxnGcZNaH/DTX/Uo/8AlS/+1UAe/wBFeAf8NNf9Sj/5Uv8A7VR/w01/1KP/AJUv/tVAHv8ARXgH/DTX/Uo/+VL/AO1Uf8NNf9Sj/wCVL/7VQB7/AEV4B/w01/1KP/lS/wDtVH/DTX/Uo/8AlS/+1UAe/wBFeAf8NNf9Sj/5Uv8A7VR/w01/1KP/AJUv/tVAHv8ARXgH/DTX/Uo/+VL/AO1Uf8NNf9Sj/wCVL/7VQB7/AEV4B/w01/1KP/lS/wDtVH/DTX/Uo/8AlS/+1UAe/wBFeAf8NNf9Sj/5Uv8A7VR/w01/1KP/AJUv/tVAHv8ARXgH/DTX/Uo/+VL/AO1Uf8NNf9Sj/wCVL/7VQB7/AEV4B/w01/1KP/lS/wDtVH/DTX/Uo/8AlS/+1UAe/wBFeAf8NNf9Sj/5Uv8A7VR/w01/1KP/AJUv/tVAHv8ARXgH/DTX/Uo/+VL/AO1Uf8NNf9Sj/wCVL/7VQB7/AEV4B/w01/1KP/lS/wDtVH/DTX/Uo/8AlS/+1UAe/wBFeAf8NNf9Sj/5Uv8A7VR/w01/1KP/AJUv/tVAHv8ARXgH/DTX/Uo/+VL/AO1Uf8NNf9Sj/wCVL/7VQB7/AF8QeO/+Sh+Jv+wrdf8Ao1q9g/4aa/6lH/ypf/aq8P13U/7b8Q6nq3k+T9uu5bnyt27ZvcttzgZxnGcCgD//2Q==';
    }

    public static Apttus_Config2__AccountLocation__c createAccountLocation(Id accountId) {
        Apttus_Config2__AccountLocation__c al = new Apttus_Config2__AccountLocation__c();
        /*al.Shipping_PostalCode__c = 'postal';
        al.Shipping_Country_ISO__c = 'ISO';
        al.Shipping_City__c = 'City';
        al.Shipping_Street__c = 'St';
        al.Shipping_State__c = 'state';*/
        al.Apttus_Config2__AccountId__c = accountId;   
        //al.Customer_calendar_key__c = 'SAP_01';
        return al;
    }

    public static Apttus_Config2__AssetLineItem__c createAssetLineItem() {
        Apttus_Config2__AssetLineItem__c alt = new Apttus_Config2__AssetLineItem__c();
        return alt;
    }
    
    /**
    * @author         Marvin Gatchalian
    * @date           19.02.2018
    * @return         Country Settings Object
    * @description    This Method will called from the test class with the respective
    *                 parameters it will instantiate the object and return it to the
    *                 test class
    */
    public static CountrySetting__c createCountrySettings() {
        CountrySetting__c cs = new CountrySetting__c();
        cs.Name = 'Country Test';
        cs.Active__c = true;
        return cs;
    }
    
    /**
    * @author         Marvin Gatchalian
    * @date           19.02.2018
    * @return         Operating Schedules Object
    * @description    This Method will called from the test class with the respective
    *                 parameters it will instantiate the object and return it to the
    *                 test class
    */
    public static OperatingSchedule__c createOperatingSchedule() {
        OperatingSchedule__c os = new OperatingSchedule__c();
        os.Active__c = true;
        return os;
    }
    
    /**
    * @author         Marvin Gatchalian
    * @date           19.02.2018
    * @return         Physical Asset Object
    * @description    This Method will called from the test class with the respective
    *                 parameters it will instantiate the object and return it to the
    *                 test class
    */
    public static PhysicalAsset__c createPhysicalAsset() {
        PhysicalAsset__c pa = new PhysicalAsset__c();
        pa.Name = 'Physical Asset Test';
        return pa;
    }
    

    /**
    * @author         Ritesh Kumar
    * @date           10.09.2018
    * @return         Product Object
    * @description    This Method will called from the test class with the respective
    *                 parameters it will instantiate the object and return it to the
    *                 test class
    */
     public static Product2 createProductTest(String name, String materialType){
        
        Product2 product = new Product2();
        product.Name = name;
        product.APTS_Material_Type__c = materialType;
        product.isActive = true;
        product.APTS_Cross_plant_material_status__c ='PR';
        return product;
        
    }

    /**
    * @author         Ritesh Kumar
    * @date           10.09.2018
    * @return         Account Loaction Object
    * @description    This Method will called from the test class with the respective
    *                 parameters it will instantiate the object and return it to the
    *                 test class
    */    
    public static Apttus_Config2__AccountLocation__c createAccountLocationTest(String customerId, String accountId){
        
        Apttus_Config2__AccountLocation__c accountLocation = new Apttus_Config2__AccountLocation__c();
        accountLocation.SAP_Customer_ID__c = customerId;
        accountLocation.Apttus_Config2__AccountId__c = accountId;
        return accountLocation;
        
    }

    /**
    * @author         Ritesh Kumar
    * @date           10.09.2018
    * @return         Resource Object
    * @description    This Method will called from the test class with the respective
    *                 parameters it will instantiate the object and return it to the
    *                 test class
    */    
    public static Resource__c createResourceTest(String name){
        
        Resource__c resource = new Resource__c();
        resource.Name = name;
        return resource;
        
    }

    /**
    * @author         Ritesh Kumar
    * @date           10.09.2018
    * @return         Physical Asset Object
    * @description    This Method will called from the test class with the respective
    *                 parameters it will instantiate the object and return it to the
    *                 test class
    */    
    public static PhysicalAsset__c createPhysicalAssetTest(String recordType, String productID, String salesOrg, String soldTOId, String accLocationId, String building, String floor,String preferredOperatorId, String machineCare ){
        
        PhysicalAsset__c  physicalAsset  = new PhysicalAsset__c ();
        physicalAsset.RecordTypeId = recordType;
        physicalAsset.Product__c = productID;
        physicalAsset.SalesOrganization__c = salesOrg;
        physicalAsset.SoldTo__c = soldTOId;
        physicalAsset.AccountLocation__c = accLocationId;
        physicalAsset.Building__c = building;
        physicalAsset.floor__c = floor;
        physicalAsset.OP_PreferredOperator__c = preferredOperatorId;
        physicalAsset.Machine_Care__c = machineCare;
        physicalAsset.TypeOfContract__c = 'sales';
        physicalAsset.AssetStatus__c = 'Activated';
        physicalAsset.ActiveContract__c = true;
        physicalAsset.StartDate__c = date.today().addDays(-365);
        physicalAsset.EndDate__c = date.today().addDays(365);       
        return physicalAsset;
        
    }
    
    /**
    * @author         Ritesh Kumar
    * @date           10.09.2018
    * @return         Operating Schedule Object
    * @description    This Method will called from the test class with the respective
    *                 parameters it will instantiate the object and return it to the
    *                 test class
    */
    public static OperatingSchedule__c createOperatingScheduleTest(Boolean specificDaysinWeek, Boolean scheduleTasksForHoliday,String monday, String tuesday, String wednesday, String thursday, String friday, String saturday, String sunday){
        
        OperatingSchedule__c operatingSchedule = new OperatingSchedule__c();
        operatingSchedule.Active__c = true;
        operatingSchedule.Specific_Days_in_Week__c = specificDaysinWeek;
        operatingSchedule.Schedule_Tasks_for_Holiday__c = scheduleTasksForHoliday;
        operatingSchedule.SM_1_Monday__c = monday;
        operatingSchedule.SM_1_Tuesday__c = tuesday;   
        operatingSchedule.SM_1_Wednesday__c = wednesday;   
        operatingSchedule.SM_1_Thursday__c = thursday;   
        operatingSchedule.SM_1_Friday__c = friday;   
        operatingSchedule.SM_1_Saturday__c = saturday;   
        operatingSchedule.SM_1_Sunday__c = sunday;
        return operatingSchedule;
        
    }

    /**
    * @author         Ritesh Kumar
    * @date           10.09.2018
    * @return         PricebookEntry Object
    * @description    This Method will called from the test class with the respective
    *                 parameters it will instantiate the object and return it to the
    *                 test class
    */
    public static PricebookEntry createPricebookEntryTest(String productId, String pricebookId){
        PricebookEntry pricebookEntry_obj = new PricebookEntry();
        pricebookEntry_obj.Product2Id = productId;
        pricebookEntry_obj.Pricebook2Id  = pricebookId;
        pricebookEntry_obj.UnitPrice = 12000;
        return pricebookEntry_obj;
    }

    /**
    * @author         Karen Hung
    * @date           02.10.2019
    * @return         Route, Route Line Item and Holiday
    * @description    Route, Route Line Item and Holiday data
     */
    public static Route__c createRoute(String routeName, String accLocId){
        Route__c route = new Route__c();
        route.Name = 'Route Name';
        route.Account_Location__c = accLocId;
        return route;
    }

    public static Route_Line_Item__c createRouteLine(String lineName, String routeId){
        Route_Line_Item__c routeItem = new Route_Line_Item__c();
        routeItem.Name = 'Test Line Item';
        routeItem.RouteId__c = routeId;
        return routeItem;
    }
    
    public static Customer_Holiday__c createHoliday(String holidayName, String accLocId){
        Customer_Holiday__c holiday = new Customer_Holiday__c();
        holiday.Name = 'St. Green Day';
        holiday.Account_Location__c = accLocId;
        return holiday;
    }  

    public static Operating_Schedule_Rule__c createRule(String opSchedId){
        Operating_Schedule_Rule__c osr = new Operating_Schedule_Rule__c();
        osr.Operating_Schedule__c = opSchedId;
        osr.Active__c = true;
        return osr;
    }
    /*
    public static Knowledge__kav createKA(){
        Knowledge__kav ka = new Knowledge__kav();
        ka.Completion_Code__c = '100 - Completed, At Location';
        ka.CurrencyIsoCode = 'EUR';
        ka.Fault_Code__c = 'B06 - O - ring';
        ka.Fault_Location_Category__c = 'Brewing';
        ka.Defect_Code__c = 'T05 - Kinked / Bent / Squeezed';
        ka.Title = 'Kraantje zit vastgeroesTITLEE';
        ka.UrlName = 'jkhghfdfsdfdhg';
        ka.Language = 'en_US';
        ka.IsVisibleInCsp = false;
        ka.IsVisibleInPkb = false; 
        ka.IsVisibleInPrm = false;            
        ka.Fix_by_phone__c = false;
        return ka;
    }
    */

    // DOO-4653 Francis Allen Alindogan 06.20.2020
    public static OperatingHourAssociation__c createOperatingHourAssociation(Id accLoc){
        OperatingHourAssociation__c oha = new OperatingHourAssociation__c();
        oha.Active__c = true;
        oha.BusinessUnit__c = 'TCS';
        return oha;
    }
}