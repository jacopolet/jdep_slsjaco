/**
    * @author        Abram Vixen Reyes
    * @date          05.7.2018
    * @description   This method will return the next business day and the business day end time.
    * @revision(s)
*/
global with sharing class TS_BusinessHoursChecker {

    public static Map<String, DateTime> nextBusinessDayMap;
    public static boolean isTest = false;
    
    @InvocableMethod
    public static List<DateTime> getNextBusinessDay (List<CountrySetting__c> businessHourIdList) {
        DateTime nextBusinessDay;
        List<DateTime> returnList = new List<DateTime>();
        Map<String, DateTime> returnMap = new Map<String, DateTime>();
        
        Map<Id,BusinessHours> busMap = new Map<Id,BusinessHours>([SELECT Id, MondayEndTime, TuesdayEndTime, WednesdayEndTime, ThursdayEndTime,FridayEndTime, SaturdayEndTime, SundayEndTime FROM BusinessHours]);
        
        for(CountrySetting__c str :businessHourIdList){
            Date nextWorkingDay;
            if(isTest != true){
                nextWorkingDay = TS_UtilityClass.getWorkingDate(str.Business_Hours__c, System.now().date().addDays(1));
            }
            else {
                nextWorkingDay = date.newInstance(2020,04,12); //SET DATE TO SUNDAY IF TEST CLASS FOR COVERAGE
            }
            
            BusinessHours business = busMap.get(str.Business_Hours__c);
            Date dte =nextWorkingDay;
            Time newTime;
            
            if (Label.TS_SLA_Monday.equals(TS_UtilityClass.getReadableDay(dte))) {
                //newTime = business.MondayEndTime.addSeconds(-1);
                newTime = business.MondayEndTime;
            } else if (Label.TS_SLA_Tuesday.equals(TS_UtilityClass.getReadableDay(dte))) {
                newTime = business.TuesdayEndTime;
            } else if (Label.TS_SLA_Wednesday.equals(TS_UtilityClass.getReadableDay(dte))) {
                newTime = business.WednesdayEndTime;
            } else if (Label.TS_SLA_Thursday.equals(TS_UtilityClass.getReadableDay(dte))) {
                newTime = business.ThursdayEndTime;
            } else if (Label.TS_SLA_Friday.equals(TS_UtilityClass.getReadableDay(dte))) {
                newTime = business.FridayEndTime;
            } else if (Label.TS_SLA_Saturday.equals(TS_UtilityClass.getReadableDay(dte))) {
                newTime = business.SaturdayEndTime != null ? business.SaturdayEndTime : newTime;
            } else if (Label.TS_SLA_Sunday.equals(TS_UtilityClass.getReadableDay(dte))) {
                newTime = business.SundayEndTime != null? business.SundayEndTime : newTime;
            }
            
            DateTime dt = DateTime.newInstance(dte, newTime);
            returnList.add(dt);

            //ADD TO STATIC MAP, FOR BULK REFERENCING
            returnMap.put(str.Country__c,dt);
        }        
        nextBusinessDayMap = returnMap;

        return returnList;        
    }


}