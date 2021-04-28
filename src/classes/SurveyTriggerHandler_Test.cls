/**
* @author        Marvin Gatchalian
* @date          5.31.2018           
* @description   Test class for SurveyTriggerHandler
* @revision(s)   
*/


@isTest
private class SurveyTriggerHandler_Test {
	
	static Account acct;
    static Contact con;
    static PhysicalAsset__c pa;
    static Survey_Settings__c sSettings;
    static Survey__c parentSurvey;
	static User u;
	
	public static void dataSetup() {
		//Create Product
		product2 p = new product2();
		p.Name = 'KTS-1028';
		p.APTS_Material_Type__c = 'ZSPR';
		insert p;
		
		//Create sales org pricebook
		pricebook2 orgPB = new pricebook2();
		orgPB.name = 'BE Price Book';
		orgPB.IsActive = true;
		orgPB.Sales_Organization__c = 'SAP_0333';
		insert orgPB;
		
		u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
		u.Sales_Organization__c = 'SAP_0111';
		update u;
		
		Resource__c r = TS_TestDataFactory.createResourceSingle('Test Resource');
        insert r;
        
		pa = new PhysicalAsset__c(Name='Test', 
                 UniqueNumber__c='1234567-TestMachine', Product__c = p.id, OP_LastPerformingOperator__c = r.id,
                 RecordTypeId = Schema.SObjectType.PhysicalAsset__c.getRecordTypeInfosByName().get('Machine').getRecordTypeId());
        insert pa;

        acct = new Account(Name='Account', Phone='+31302979111');
        insert acct;
        
        con = TS_TestDataFactory.createContact();  
        con.Preferred_Language__c = 'SAP_EN';
        Insert con;

        
        List<Survey_Settings__c> sSettingsList = new List<Survey_Settings__c>();
        Id ssRT = Schema.SObjectType.Survey_Settings__c.getRecordTypeInfosByName().get('Health & Safety Fault Ranking').getRecordTypeId();
        sSettings = new Survey_Settings__c();
        sSettings.recordTypeId = ssRT;
        sSettings.SurveySetting__c = 'Fault Ranking';
        sSettings.Country__c = 'SAP_0111';
        sSettings.SurveyType__c = 'Freshbrew Check';
        sSettings.FaultRanking__c = 4;
        sSettings.Active__c = true;
        sSettings.Product__c = p.id;
        sSettingsList.add(sSettings);
        //
        sSettings = new Survey_Settings__c();
        sSettings.recordTypeId = ssRT;
        sSettings.SurveySetting__c = 'Fault Ranking';
        sSettings.Country__c = 'SAP_0111';
        sSettings.SurveyType__c = 'Non Coffee Machine Check';
        sSettings.FaultRanking__c = 1;
        sSettings.Active__c = true;
        //sSettings.Product__c = p.id;
        sSettingsList.add(sSettings);
        
        Id ssRTSM = Schema.SObjectType.Survey_Settings__c.getRecordTypeInfosByName().get('Health & Safety Score Matrix').getRecordTypeId();
        sSettings = new Survey_Settings__c();
        sSettings.recordTypeId = ssRTSM;
        sSettings.SurveySetting__c = 'Score Matrix';
        sSettings.Country__c = 'SAP_0111';
        sSettings.SurveyType__c = 'Freshbrew Check';
        sSettings.FaultRanking__c = 4;
        sSettings.Active__c = true;
        sSettings.NumberOfFalseResponses__c = 0;
        sSettings.Operator__c = 'Equals';
        sSettings.Score__c = 9;
        sSettingsList.add(sSettings);
        
        sSettings = new Survey_Settings__c();
        sSettings.recordTypeId = ssRTSM;
        sSettings.SurveySetting__c = 'Score Matrix';
        sSettings.Country__c = 'SAP_0111';
        sSettings.SurveyType__c = 'Freshbrew Check';
        sSettings.FaultRanking__c = 4;
        sSettings.Active__c = true;
        sSettings.NumberOfFalseResponses__c = 1;
        sSettings.Operator__c = 'Equals';
        sSettings.Score__c = 7.9;
        sSettingsList.add(sSettings);
        
        sSettings = new Survey_Settings__c();
        sSettings.recordTypeId = ssRTSM;
        sSettings.SurveySetting__c = 'Score Matrix';
        sSettings.Country__c = 'SAP_0111';
        sSettings.SurveyType__c = 'Non Coffee Machine Check';
        sSettings.FaultRanking__c = 1;
        sSettings.Active__c = true;
        sSettings.NumberOfFalseResponses__c = 1;
        sSettings.Operator__c = 'Equals';
        sSettings.Score__c = 7.9;
        sSettingsList.add(sSettings);
        
        sSettings = new Survey_Settings__c();
        sSettings.recordTypeId = ssRTSM;
        sSettings.SurveySetting__c = 'Score Matrix';
        sSettings.Country__c = 'SAP_0111';
        sSettings.SurveyType__c = 'Freshbrew Check';
        sSettings.FaultRanking__c = 4;
        sSettings.Active__c = true;
        sSettings.NumberOfFalseResponses__c = 2;
        sSettings.Operator__c = 'Greater than equals';
        sSettings.Score__c = 6.9;
        sSettingsList.add(sSettings);
        insert sSettingsList;
		        
    }

    static testMethod void newFreshBrew() {
        // TO DO: implement unit test
		dataSetup();
	    System.runAs(u) {
	    	
	    	test.startTest();
	        //Create Parent Survey
	        //Update the Record Type name. By Ritesh Kumar.
			Id rtParent = Schema.SObjectType.Survey__c.getRecordTypeInfosByName().get('Health & Safety: Customer Check').getRecordTypeId();
			parentSurvey = new Survey__c();
			parentSurvey.Date_of_interview__c = system.now();
			parentSurvey.SurveyType__c = 'Health & Safety Customer Check';
			parentSurvey.RecordTypeId = rtParent;
			insert parentSurvey;
			
			//Expecting score is 6.9
	        Id rt = Schema.SObjectType.Survey__c.getRecordTypeInfosByName().get('Health & Safety: Freshbrew').getRecordTypeId();
	        Survey__c freshBrewSurveyA = new Survey__c();
	        freshBrewSurveyA.RecordTypeID = rt;
	        freshBrewSurveyA.Machine__c = pa.id;
	        freshBrewSurveyA.Allergy_Information__c = 'False';
	        freshBrewSurveyA.Cylinder__c = 'False';
	        freshBrewSurveyA.ParentSurvey__c = parentSurvey.id;
	        insert	freshBrewSurveyA;
	        
	        //Expecting score is 7.9
	        Survey__c freshBrewSurveyB = new Survey__c();
	        freshBrewSurveyB.RecordTypeID = rt;
	        freshBrewSurveyB.Machine__c = pa.id;
	        freshBrewSurveyB.Allergy_Information__c = 'False';
	        freshBrewSurveyB.ParentSurvey__c = parentSurvey.id;
			insert	freshBrewSurveyB;
			
			//Expecting average score is (6.9 + 7.9) / 2 , so it is 7.4
			system.assertEquals(7.4, [Select id, Average_Score__c From Survey__c Where id = :parentSurvey.id].Average_Score__c);
			
			//Updating /reducing false count.
			//Expecting score is 9
			freshBrewSurveyB.Allergy_Information__c = 'Good';
			update freshBrewSurveyB;
			
			//Expecting average score is (6.9 + 9) / 2 , so it is 7.95 or 8 (rounded up)
			system.assertEquals(7.95, [Select id, Average_Score__c From Survey__c Where id = :parentSurvey.id].Average_Score__c);

            //Cancel the freshBrewSurveyB(9), Expecting the parent average score to be 6.9
            freshBrewSurveyB.Status__c = TS_Constants.ORDER_CANCELED;
            update freshBrewSurveyB;
            system.assertEquals(6.9, [Select id, Average_Score__c From Survey__c Where id = :parentSurvey.id].Average_Score__c);

			test.stopTest(); 
		}
         
    }
   
    //Karen Hung 12/14/2018
   static testMethod void nonCoffee() {
        // TO DO: implement unit test
		dataSetup();
	    System.runAs(u) {
	    	
	    	test.startTest();
	        //Create Parent Survey
			Id rtParent = Schema.SObjectType.Survey__c.getRecordTypeInfosByName().get('Health & Safety: Customer Check').getRecordTypeId();
			parentSurvey = new Survey__c();
			parentSurvey.Date_of_interview__c = system.now();
			parentSurvey.SurveyType__c = 'Health & Safety Customer Check';
			parentSurvey.RecordTypeId = rtParent;
			insert parentSurvey;
			
	        Id rt = Schema.SObjectType.Survey__c.getRecordTypeInfosByName().get('Health & Safety: Non Coffee Machines').getRecordTypeId();
	        Survey__c nonCoffeeSurvey = new Survey__c();
	        nonCoffeeSurvey.RecordTypeID = rt;
            nonCoffeeSurvey.Country__c = 'SAP_0111';
	        nonCoffeeSurvey.ParentSurvey__c = parentSurvey.id;
            nonCoffeeSurvey.SurveyType__c = 'Non Coffee Machine Check';
            nonCoffeeSurvey.Best_before_date_drum_6__c = 'False';
	        insert nonCoffeeSurvey;
			nonCoffeeSurvey.Status__c = 'Re-Opened';
            update nonCoffeeSurvey;
            delete nonCoffeeSurvey;
            undelete nonCoffeeSurvey;
			system.assert(nonCoffeeSurvey !=null);
			test.stopTest(); 
		}        
    }
}