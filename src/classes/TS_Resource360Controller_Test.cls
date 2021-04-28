/*
* @author        Ritesh Kumar
* @date          22.08.2018
* @description   TO test he TS_Resource360 controller class.
*/

@isTest
public class TS_Resource360Controller_Test{

	@isTest static void test_GetSuggestedEngineers(){
		CountrySetting__c cs = TS_TestDataFactory.createCountrySettings();
		cs.RecordTypeId= Schema.SObjectType.CountrySetting__c.getRecordTypeInfosByName().get('Country Postal Code Trim').getRecordTypeId();
		cs.NumberofCharacters__c =2;
		cs.Country__c = 'SAP_0333';
		Insert cs;

		Resource__c resourceTest1 = TS_TestDataFactory.createResourceSingle('Resource test 1');
        resourceTest1.Team__c='test team';
        resourceTest1.EmployeeFirstName__c='Test First Name 1';
        resourceTest1.EmployeeLastName__c='Test Last Name 1';
        resourceTest1.EmailAddress__c='test@email.com';
        resourceTest1.Sales_Organization__c=cs.Country__c;
        resourceTest1.CompanyCode__c = '0202';
        Insert resourceTest1;

        Resource__c resourceTest2 = TS_TestDataFactory.createResourceSingle('Resource test 2');
        resourceTest2.EmployeeFirstName__c='Test First Name 2';
        resourceTest2.EmployeeLastName__c='Test Last Name 2';
        resourceTest2.EmailAddress__c='test2@email.com';
        resourceTest2.Sales_Organization__c=cs.Country__c;
        resourceTest2.CompanyCode__c = '0202';
        Insert resourceTest2;

        Resource__c resourceTest3 = TS_TestDataFactory.createResourceSingle('Resource test 3');
        resourceTest3.Team__c='test team3';
        resourceTest3.EmployeeFirstName__c='Test First Name 3';
        resourceTest3.EmployeeLastName__c='Test Last Name 3';
        resourceTest3.EmailAddress__c='test@email.com';
        resourceTest3.Sales_Organization__c=cs.Country__c;
        resourceTest3.CompanyCode__c ='0202';
        Insert resourceTest3;

        Resource__c resourceTest4 = TS_TestDataFactory.createResourceSingle('Resource test 4');
        resourceTest4.Team__c='test team4';
        resourceTest4.EmployeeFirstName__c='Test First Name 4';
        resourceTest4.EmployeeLastName__c='Test Last Name 4';
        resourceTest4.EmailAddress__c='test@email.com';
        resourceTest4.CompanyCode__c='0202';
        Insert resourceTest4;

        EngineerRouting__c er1 = new EngineerRouting__c();
        er1.Resource__c = resourceTest1.Id;
        er1.Priority__c = 1;
        er1.PostalCode__c='10';
        er1.Active__c =true;
        er1.SalesOrganization__c =cs.Country__c;
        Insert er1;

        EngineerRouting__c er2 = new EngineerRouting__c();
        er2.Resource__c = resourceTest2.Id;
        er2.Priority__c = 1;
        er2.PostalCode__c='10';
        er2.SalesOrganization__c =cs.Country__c;
        er2.Active__c =true;
        Insert er2;

        EngineerRouting__c er3 = new EngineerRouting__c();
        er3.Resource__c = resourceTest3.Id;
        er3.Priority__c = 3;
        er3.PostalCode__c='10';
        er3.Active__c =true;
        er3.SalesOrganization__c =cs.Country__c;
        Insert er3;

		EngineerRouting__c er4 = new EngineerRouting__c();
        er4.Resource__c = resourceTest4.Id;
        er4.PostalCode__c='10';
        er4.Active__c =true;
        er4.SalesOrganization__c =cs.Country__c;
        Insert er4;

        Test.startTest();
        TS_Resource360Controller.getSuggestedEngineers('1000','SAP_0333');
        Test.stopTest();

	}

}