/**
* @author        Archi Delphinanto
* @date          12.04.2017
* @description   Contains methods to calculate business hours between two dates
* @revision(s)
12.08.2017   Adrian Reyes: Made improvements to the code (Logic remains the same)
*/

public class TS_BusinessHour_Calculation {
	/**
    * @author        Archi Delphinanto
    * @date          12.04.2017           
    * @description   Method to calculate number of business hours between two dates, with busines hours defined in businesshoursID
    * @revision(s)	 12.08.2017   Adrian Reyes: Made improvements to the code (Logic remains the same)
    */
    public static Decimal defaultSFBusinessHourBetweenDates (DateTime startDateTime, DateTime endDateTime, String businessHoursId){
        Decimal totalHours = 0.00;
		
        if(startDateTime != null && endDateTime != null && String.isNotBlank(businessHoursId)){
            totalHours = BusinessHours.diff(businessHoursId, startDateTime, endDateTime);	//in milliseconds
            totalHours = totalHours.divide((3600000), 2);	//in hours
        }
        
        return totalHours;
    }
	

	/**
    * @author        Archi Delphinanto
    * @date          12.04.2017           
    * @description   Method to calculate number of business hours between two dates, with busines hours defined in servicewindows, and the holiday defined in businesshourID
					 Note: the business hour id should have business hours of 24/7 otherwise it cannot take only the holidays.
    * @revision(s)	 12.08.2017   Adrian Reyes: Made improvements to the code (Logic remains the same)
    */
    public static Decimal calculateBusinessHourBetweenDates (DateTime startDateTime, Datetime endDateTime, String serviceWindows, String businessHoursId){
        //businessHoursId is to define list of holidays

    	//generate map of start and end time of business hour of the customer from service windows.
    	Map<String, Time> BHstartTimeMap = new Map<String, Time>();
        Map<String, Time> BHendTimeMap = new Map<String, Time>();
    	//generateStartAndEndMap(BHstartTimeMap, BHendTimeMap, serviceWindows);
        
		generateBusinessHourMapFromServiceWindows(BHstartTimeMap, BHendTimeMap,  serviceWindows);

    	Map<String, Decimal> totalbusinesshourperday_Map = generateTotalbusinesshourperday(BHstartTimeMap, BHendTimeMap) ;


    	Datetime currentdatetime = startDateTime;
    	Decimal totalbusinesshours = 0;
    	Decimal todaybusinesshours = 0;
    	String thedayintheweek;
    	//Integer thedayintheweek_int;
    	Time TodayBHstarttime;
		Time TodayBHendtime;
		Boolean isHoliday ;
		decimal totalminute ;
        
        try {

            while (currentdatetime <= endDateTime) {
                
                thedayintheweek = currentdatetime.format('u'); // define which day on the week

                //thedayintheweek_int = Integer.valueOf(thedayintheweek);
                totalminute = 0;
                TodayBHstarttime = BHstartTimeMap.get(thedayintheweek);
                TodayBHendtime = BHEndTimeMap.get(thedayintheweek);
                //system.debug(' TodayBHstarttime   :'  + TodayBHstarttime );	
                //system.debug(' TodayBHendtime   :'  + TodayBHendtime);	
               // system.debug('test business hour: ' + businessHoursId);
                isHoliday = !BusinessHours.isWithin(businessHoursId, currentdatetime);
                //System.debug(isHoliday);
                //isholiday = false;
                if (isHoliday ){// if today is holiday  isTodayAHoliday(currentdatetime, holidayList)
                    todaybusinesshours = 0;
                }
                
                else if (currentdatetime.date() == startDateTime.date()) { //starting date
                    if ((currentdatetime.hour()>= TodayBHstarttime.hour()) && (currentdatetime.hour() <= TodayBHendtime.hour()) ){
                        
                        if (currentdatetime.date() == endDateTime.date()){
                            todaybusinesshours = endDateTime.hour() -  currentdatetime.hour();
                            totalminute = endDateTime.minute() - currentdatetime.minute();
                            totalminute = totalminute.divide(60,4); //calculate the minute in hour scale
                            todaybusinesshours = todaybusinesshours +totalminute;	
                        }
                        else {
                            todaybusinesshours = TodayBHendtime.hour() -  currentdatetime.hour();
                            totalminute = TodayBHendtime.minute() - currentdatetime.minute();
                            totalminute = totalminute.divide(60,4); //calculate the minute in hour scale
                            todaybusinesshours = todaybusinesshours +totalminute;	
                        }
                        
                        //System.debug('iswithin businsss hour, totalbusinesshours :  '+todaybusinesshours );
                    }
                    else if (currentdatetime.hour() < TodayBHstarttime.hour()) { //before business hours
                        todaybusinesshours = totalbusinesshourperday_Map.get(thedayintheweek) ;// getTodayBusinessHour(currentdatetime)
                    }
                    else if (currentdatetime.hour() > TodayBHendtime.hour()){ //after business hours
                        todaybusinesshours = 0;
                    }
                    //system.debug(' first day  :'  + todaybusinesshours);		
                }
                
                else if (currentdatetime.date() == endDateTime.date() ) { // ending date
                    if ((endDateTime.hour() >= TodayBHstarttime.hour()) && (endDateTime.hour() <= TodayBHendtime.hour())){  //  is withinbusinesshours
                        todaybusinesshours = endDateTime.hour() - TodayBHstarttime.hour();
                        totalminute = endDateTime.minute() - TodayBHstarttime.minute()  ;
                        totalminute = totalminute.divide(60,4); //calculate the minute in hour scale
                        todaybusinesshours = todaybusinesshours +totalminute;				
                    }
                    else if (endDateTime.hour() > TodayBHendtime.hour()) { //after business hours
                        todaybusinesshours = totalbusinesshourperday_Map.get(thedayintheweek) ;
                    }
                    else {
                        todaybusinesshours = 0;
                        
                    }	
                    //system.debug(' last day  :'  + todaybusinesshours);							 	 
                }
                
                else { // date between starting and ending
                    todaybusinesshours = totalbusinesshourperday_Map.get(thedayintheweek); 		
                    //system.debug(' normal day  :'  + todaybusinesshours);		
                }
                system.debug(' todaybusinesshours  :'  + todaybusinesshours);	
                totalbusinesshours = totalbusinesshours + todaybusinesshours;
                currentdatetime = currentdatetime.adddays(1);
                
            }

        } catch (Exception ex) {
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
        //system.debug(casestarttime);
        //system.debug(caseendtime);
        //system.debug('start time map:  '+BHstartTimeMap);
        //system.debug('end time map:  ' + BHendTimeMap);
        //system.debug('Totalbhperday map:  '+ totalbusinesshourperday_Map);
        
        
        return totalbusinesshours;
        
    }
	
    /**
    * @author        Archi Delphinanto
    * @date          12.04.2017           
    * @description   Method responsible for generating the business hours Map
    * @revision(s)	 12.08.2017   Adrian Reyes: Made improvements to the code (Logic remains the same)
    */
	static void generateBusinessHourMapFromServiceWindows(Map<String,Time> startTimeMap, Map<String,Time> endTimeMap, String serviceWindows) {
        CustomLogging.push('generateBusinessHourMapFromServiceWindows', 'TS_BusinessHour_Calculation');
        String[] weekDayArray = (serviceWindows != null)? serviceWindows.split(' ') : null;
        Time weekDayStart;
        Time weekDayFinish;
        Time weekEndStart;
        Time weekEndFinish;

        Boolean hasWeekend = false;
        
        if (weekDayArray != null && !weekDayArray.isEmpty()) {
            if (serviceWindows.contains('Extended Weekend')) {
                weekDayStart = convertStringToTime ( weekDayArray[8] ) ;//+ ':00';
                weekDayFinish = convertStringToTime (weekDayArray[10] );// + ':00';
                weekEndStart = convertStringToTime (weekDayArray[15] );//+ ':00';
                weekEndFinish = convertStringToTime (weekDayArray[17].remove(')')  );//+ ':00';
                hasWeekend = true;
            } else if (serviceWindows.contains('Weekend')) {
                weekDayStart = convertStringToTime (weekDayArray[7] );//+ ':00';
                weekDayFinish = convertStringToTime (weekDayArray[9].remove(')') );//+ ':00';
                weekEndStart = convertStringToTime (weekDayArray[7] );//+ ':00';
                weekEndFinish = convertStringToTime (weekDayArray[9].remove(')')  );// + ':00';
                hasWeekend = true;
            } else {
                weekDayStart = convertStringToTime (weekDayArray[5] );//+ ':00';
                weekDayFinish = convertStringToTime (weekDayArray[7].remove(')') ) ;//+ ':00';
            }
        }
        
        for (Integer ctr = 1; ctr <= 7; ctr++) {
            String mapId = String.valueOf(ctr);
            //Weekday
            if (ctr < 6) {
                startTimeMap.put(mapId, weekDayStart);
                endTimeMap.put(mapId, weekDayFinish);
            }
            //with weekend 
            else if (hasWeekend) {
                startTimeMap.put(mapId, weekEndStart);
                endTimeMap.put(mapId, weekEndFinish);
            } 
            //weekday without weekend
            else {
                startTimeMap.put(mapId,  convertStringToTime ('00:00') );
                endTimeMap.put(mapId, convertStringToTime ('00:00') );
            }
        }
        CustomLogging.pop();
    }
	
    /**
    * @author        Archi Delphinanto
    * @date          12.04.2017           
    * @description   Method responsible for generating a map that contains the number of minutes the client/customer is open per day
    * @revision(s)	 12.08.2017   Adrian Reyes: Made improvements to the code (Logic remains the same)
    */
	static Map<String,Decimal> generateTotalbusinesshourperday(Map<String,Time> startTimeMap, Map<String,Time> endTimeMap) {
        CustomLogging.push('generateTotalbusinesshourperday', 'TS_BusinessHour_Calculation');
        Map<String, Decimal> hoursPerDaysMap = new Map<String, Decimal>();
        Decimal totalhourcomponent;
        Decimal totalminutecomponent;
        
        for (Integer ctr = 1; ctr <= 7; ctr++) {
            String mapId = String.valueOf(ctr);      
            if (startTimeMap.get(mapId)!=null) {
                totalhourcomponent = endTimeMap.get(mapId).hour() - startTimeMap.get(mapId).hour() ;
                totalminutecomponent = endTimeMap.get(mapId).minute() - startTimeMap.get(mapId).minute();
                totalminutecomponent = totalminutecomponent.divide(60,2);
                totalhourcomponent = totalhourcomponent + totalminutecomponent;
            }
            
            hoursPerDaysMap.put(mapId, totalhourcomponent);
        }
        //  system.debug();
        CustomLogging.pop();
        return hoursPerDaysMap;
    }
    
	/**
    * @author        Archi Delphinanto
    * @date          12.04.2017           
    * @description   Method to convert String to Time
    * @revision(s)	 12.08.2017   Adrian Reyes: Made improvements to the code (Logic remains the same)
    */
    static Time convertStringToTime(String input){
        String[] timecomponent = input.split(':');
        Integer hourcomponent = Integer.valueOf(timecomponent[0].deleteWhitespace());
        Integer minutecomponent = Integer.valueOf(timecomponent[1].deleteWhitespace());
        return Time.newInstance(hourcomponent, minutecomponent, 0, 0);
    }
}