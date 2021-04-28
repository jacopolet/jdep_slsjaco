/*
* @author        Aditya
* @date          11.12.2018           
* @description   This class cover code coverage for all the class which is calling for the UpdateAccountCallList
* @revision(s)
* @class         Secdhular class :SalescallScheduleforSpain,SalescallScheduleforBelgium,SalescallScheduleforIrland,SalescallScheduleforNetherlands,SalescallScheduleforBrition,SalescallScheduleforDenmark,SalescallScheduleforNorway ,SalescallScheduleforSwedan,SalescallScheduleforNorway,SalescallScheduleforFrance.  Batch class: UpdateAccountCallList
*/

@isTest
public class Salescall_Scheduleclass_Test {
    public static testMethod void testschedule() {
        Test.StartTest();
        // code start for netherlands
        //SalescallScheduleforNetherlands Neth= new SalescallScheduleforNetherlands();
       // String sch = '0 0 0 * * ?'; 
        //system.schedule('Netherlands', sch, Neth);
        // code End
        
        // code start for Britain
      //  SalescallScheduleforBritain britain= new SalescallScheduleforBritain();
      //  String sch1 = '0 0 0 * * ?'; 
      //  system.schedule('Britain', sch1, britain);
        // code End
        
        // code start for Denmark
        SalescallScheduleforDenmark denmark= new SalescallScheduleforDenmark();
        String sch2 = '0 0 0 * * ?'; 
        system.schedule('Denmark', sch2, denmark);
        // code End
        
        // code start for Swedan
       // SalescallScheduleforSwedan swedan= new SalescallScheduleforSwedan();
       // String sch3 = '0 0 0 * * ?'; 
       // system.schedule('swedan', sch3, swedan);
        // code End
        
         // code start for Norway
        // SalescallScheduleforNorway Norway= new SalescallScheduleforNorway();
        // String sch4 = '0 0 0 * * ?'; 
        // system.schedule('Norway', sch4, Norway);
        // code End
        
         // code start for France
       // SalescallScheduleforFrance france= new SalescallScheduleforFrance();
       // String sch5 = '0 0 0 * * ?'; 
       // system.schedule('france', sch5, france);
        // code End
        
         // code start for Spain
        //SalescallScheduleforSpain spain= new SalescallScheduleforSpain();
       // String sch6 = '0 0 0 * * ?'; 
       // system.schedule('spain', sch6, spain);
        // code End
        
         // code start for Belgium
        SalescallScheduleforBelgium belgium= new SalescallScheduleforBelgium();
        String sch7 = '0 0 0 * * ?'; 
        system.schedule('Belgium', sch7, belgium);
        // code End
        
         // code start for Ireland
       // SalescallScheduleforIreland ireland= new SalescallScheduleforIreland();
       // String sch8 = '0 0 0 * * ?'; 
       // system.schedule('Ireland', sch8, ireland);
        // code End
        
        // code start for Germany
        SalescallScheduleforGermany germany= new SalescallScheduleforGermany();
        String sch8 = '0 0 0 * * ?'; 
        system.schedule('Germany', sch8, germany);
        // code End
        Test.stopTest(); 
    }
}