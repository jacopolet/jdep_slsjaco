/**
* @author        Adrian Reyes
* @date          12.08.2017
* @description   Test class for TS_BusinessHour_Calculation
* @revision(s)
*/

@isTest
public class TS_BusinessHour_CalculationTest {
    /**
    * @author        Adrian Reyes
    * @date          12.08.2017           
    * @description   Test method to cover defaultSFBusinessHourBetweenDates
    * @revision(s)
    */
    static testMethod void testDefaultSFBusinessHourBetweenDates() {       
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
            DateTime startDateTime =  DateTime.newInstance(2017, 12, 25, 8, 0, 0);
            DateTime endDateTime = DateTime.newInstance(2017, 12, 26, 17, 0, 0);
            //Id businessHoursId = [SELECT Id FROM BusinessHours WHERE Name LIKE '%Belgium%' LIMIT 1].Id;
            Id businessHoursId = [SELECT Id FROM BusinessHours WHERE Name LIKE '%BE - Default%' LIMIT 1].Id;
            
            Test.startTest();
            Decimal differenceInHours = TS_BusinessHour_Calculation.defaultSFBusinessHourBetweenDates(startDateTime, endDateTime, businessHoursId);
            Test.stopTest();
            
            //Verify Results
            System.assertNotEquals(null, differenceInHours);
        }
    }
    
    /**
    * @author        Adrian Reyes
    * @date          12.08.2017           
    * @description   Test method to cover calculateBusinessHourBetweenDates
    * @revision(s)
    */
    static testMethod void testCalculateBusinessHourBetweenDates() {       
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
            DateTime startDateTime =  DateTime.newInstance(2017, 12, 25, 8, 0, 0);
            DateTime endDateTime = DateTime.newInstance(2017, 12, 26, 17, 0, 0);
            String serviceWindows = 'Standard Weekdays & Extended Weekend (Mon – Fri 8:00 – 17:00 & Sat – Sun 8:00 – 22:00)';
            //Id businessHoursId = [SELECT Id FROM BusinessHours WHERE Name LIKE '%Belgium%' LIMIT 1].Id;
            Id businessHoursId = [SELECT Id FROM BusinessHours WHERE Name LIKE '%BE - Default%' LIMIT 1].Id;
            
            Test.startTest();
            Decimal differenceInHours = TS_BusinessHour_Calculation.calculateBusinessHourBetweenDates(startDateTime, endDateTime, serviceWindows, businessHoursId);
            Test.stopTest();
            
            //Verify Results
            System.assertNotEquals(null, differenceInHours);
        }
    }
    
    /**
    * @author        Adrian Reyes
    * @date          12.08.2017           
    * @description   Test method to cover calculateBusinessHourBetweenDates 2
    * @revision(s)
    */
    static testMethod void testCalculateBusinessHourBetweenDates2() {       
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
            DateTime startDateTime =  DateTime.newInstance(2017, 12, 22, 8, 0, 0);
            DateTime endDateTime = DateTime.newInstance(2017, 12, 26, 17, 0, 0);
            String serviceWindows = 'Standard Weekdays & Extended Weekend (Mon – Fri 8:00 – 17:00 & Sat – Sun 8:00 – 22:00)';
            //Id businessHoursId = [SELECT Id FROM BusinessHours WHERE Name LIKE '%Belgium%' LIMIT 1].Id;
            Id businessHoursId = [SELECT Id FROM BusinessHours WHERE Name LIKE '%BE - Default%' LIMIT 1].Id;
            
            Test.startTest();
            Decimal differenceInHours = TS_BusinessHour_Calculation.calculateBusinessHourBetweenDates(startDateTime, endDateTime, serviceWindows, businessHoursId);
            Test.stopTest();
            
            //Verify Results
            System.assertNotEquals(null, differenceInHours);
        }
    }
    
    /**
    * @author        Adrian Reyes
    * @date          12.08.2017           
    * @description   Test method to cover calculateBusinessHourBetweenDates Same Day
    * @revision(s)
    */
    static testMethod void testCalculateBusinessHourBetweenDatesSameDay() {       
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
            DateTime startDateTime =  DateTime.newInstance(2017, 12, 26, 8, 0, 0);
            DateTime endDateTime = DateTime.newInstance(2017, 12, 26, 17, 0, 0);
            String serviceWindows = 'Standard Weekdays & Extended Weekend (Mon – Fri 8:00 – 17:00 & Sat – Sun 8:00 – 22:00)';
            //Id businessHoursId = [SELECT Id FROM BusinessHours WHERE Name LIKE '%Belgium%' LIMIT 1].Id;
            Id businessHoursId = [SELECT Id FROM BusinessHours WHERE Name LIKE '%BE - Default%' LIMIT 1].Id;
            
            Test.startTest();
            Decimal differenceInHours = TS_BusinessHour_Calculation.calculateBusinessHourBetweenDates(startDateTime, endDateTime, serviceWindows, businessHoursId);
            Test.stopTest();
            
            //Verify Results
            System.assertNotEquals(null, differenceInHours);
        }
    }
    
    /**
    * @author        Adrian Reyes
    * @date          12.08.2017           
    * @description   Test method to cover calculateBusinessHourBetweenDates Standard Weekend
    * @revision(s)
    */
    static testMethod void testCalculateBusinessHourBetweenDatesStandardWeekend() {       
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
            DateTime startDateTime =  DateTime.newInstance(2017, 12, 26, 7, 0, 0);
            DateTime endDateTime = DateTime.newInstance(2017, 12, 27, 7, 0, 0);
            String serviceWindows = 'Extended Weekdays & Weekend (Mon – Sun 8:00 – 22:00)';
            //Id businessHoursId = [SELECT Id FROM BusinessHours WHERE Name LIKE '%Belgium%' LIMIT 1].Id;
            Id businessHoursId = [SELECT Id FROM BusinessHours WHERE Name LIKE '%BE - Default%' LIMIT 1].Id;
            
            Test.startTest();
            Decimal differenceInHours = TS_BusinessHour_Calculation.calculateBusinessHourBetweenDates(startDateTime, endDateTime, serviceWindows, businessHoursId);
            Test.stopTest();
            
            //Verify Results
            System.assertNotEquals(null, differenceInHours);
        }
    }
    
    /**
    * @author        Adrian Reyes
    * @date          12.08.2017           
    * @description   Test method to cover calculateBusinessHourBetweenDates Standard Weekdays
    * @revision(s)
    */
    static testMethod void testCalculateBusinessHourBetweenDatesStandardWeekdays() {       
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
            DateTime startDateTime =  DateTime.newInstance(2017, 12, 26, 18, 0, 0);
            DateTime endDateTime = DateTime.newInstance(2017, 12, 27, 18, 0, 0);
            String serviceWindows = 'Standard Weekdays (Mon – Fri 8:00 – 17:00)';
            //Id businessHoursId = [SELECT Id FROM BusinessHours WHERE Name LIKE '%Belgium%' LIMIT 1].Id;
            Id businessHoursId = [SELECT Id FROM BusinessHours WHERE Name LIKE '%BE - Default%' LIMIT 1].Id;
            
            Test.startTest();
            Decimal differenceInHours = TS_BusinessHour_Calculation.calculateBusinessHourBetweenDates(startDateTime, endDateTime, serviceWindows, businessHoursId);
            Test.stopTest();
            
            //Verify Results
            System.assertNotEquals(null, differenceInHours);
        }
    }
}