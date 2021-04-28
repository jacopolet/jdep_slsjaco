/******************************************************************************
* @author         Rey Austral
* @date           03.27.2017
* @description    

This class is part of the Loggin Framework. The class handles the necessary 
Logging methods that stores the debug and exception information on the Log 
object in Salesforce. 
******************************************************************************/


public without sharing class CustomLogging {
    
    
    //This public class should be used for creating excpetions form logical faults in the application
    public class CustomException extends Exception{}
    public static final string DEBUGTYPE = 'Debug';
    public static final string EXCEPTIONTYPE = 'Exception';
    public static final string LOGRECTYPE = 'Custom_Log__c';
    public static final string STACKSTR = ' stack: ';
    private static boolean inPageConstructor = false;
    
    public static void setInConstuctor(){
        inPageConstructor = true;
    }
    
    public static void unsetInConstuctor(){
        currentLevel = 0;
        inPageConstructor = false;
        debugList = new List<Custom_Log__c>();
        exceptionList = new List<Custom_Log__c>(); 
    }
    
    public class StackTrace{
        public integer level{get; private set;}
        private string function;
        private string objectName;
        
        public string getEntry(){
            return (objectName + ' : ' + function);
        }
        
        public StackTrace(integer level, string function, string objectName){
            this.level = level;
            this.function = function;
            this.objectName = objectName;
        }
    }
    
    static integer currentLevel = 0;
    static integer sequence = 0;
    static List<StackTrace> stack = new List<StackTrace>();
    static List<Custom_Log__c> debugList = new List<Custom_Log__c>();
    static List<Custom_Log__c> exceptionList = new List<Custom_Log__c>();
    static boolean debugLogEnabled = true;//AppConfigSupport.loggingEnabled();
    static boolean exceptionLogEnabled = true;//AppConfigSupport.diagnosticsEnabled();
    static List<RecordType> recordTypes = [SELECT Id, Name from RecordType 
                                           WHERE SobjectType =: LOGRECTYPE];
    
    /******************************************************************************
    * @author         Rey Austral
    * @date           03.27.2017
    * @param          functionName-String denoting the name of the method from which this method was called
    * @param          objectName-String denoting the name of the class from which the method was called
    * @return         null
    * @description    
    This method should be called when entering every method in a class. The method 
    will initiate a stacktrace which will have the level of debug info along with 
    the function name and object name
    ******************************************************************************/
    
    static public void push(string functionName, string objectName){        
        stack.add(new StackTrace(currentLevel, functionName, objectName));
        currentLevel++;       
    }
    
    
    /******************************************************************************
    * @author         Rey Austral
    * @date           03.27.2017
    * @param          null
    * @return         null
    * @description    
    This method should be called when exiting every method in a class. This method 
    will remove the debuginfo along with the functionName and objectName
    ******************************************************************************/
    static public void pop(){       
        if(currentLevel > 0){
            currentLevel--;
            if(stack.size() > 0){
                stack.remove(stack.size() -1);
            }
        }
        
        if(currentLevel==0){
            String debugListString = JSON.serialize(debugList);
            String exptListString = JSON.serialize(exceptionList);
            writeLogsToDatabase(exptListString, debugListString);
            debugList = new List<Custom_Log__c>();
            exceptionList = new List<Custom_Log__c>(); 
        }        
    }  

    /******************************************************************************
    * @author         Rey Austral
    * @date           03.27.2017
    * @param          exptListString - list string which contains the exception data
    * @param          debugListString - list string which contains the debug data
    * @return         null
    * @description    
    This method will fire asynchronously as it uses future call. The method will 
    insert the Log record with debug info and exception info (if necessary) 
    depending on the custom setting of the current user profile. 
    ******************************************************************************/
    
    static private void writeLogsToDatabase(string exptListString, string debugListString){
        
        List<Custom_Log__c> debugListParsed = (List<Custom_Log__c>)JSON.deserialize(debugListString,  List<Custom_Log__c>.class);
        List<Custom_Log__c> exceptListParsed = (List<Custom_Log__c>)JSON.deserialize(exptListString,  List<Custom_Log__c>.class);
        
        //Added try/catch as we were getting mixed DML exceptions when updating
        //the User record and the Log in the same transaction. Was easier to fix here than identify
        //all locations where this might occur
        try{
            //Cannot make DML calls in a constructor of a visualforce page so if statement to prevent this from happening
            if(!inPageConstructor){
                //if debug custom setting is on  
                if(debugLogEnabled){
                    insert debugListParsed;
                }
                //if exception custom setting is on
                if(exceptionLogEnabled){
                    insert exceptListParsed;
                }
            } 
        } catch (Exception e) {
            //Usually caused by a MIXED_DML_OPERATION
            System.debug('Logging Exception : ' + e.getMessage());
        }
        
    }
    
    
    /******************************************************************************
    * @author         Rey Austral
    * @date           03.27.2017
    * @param          debug string is passed from the method that calls the 
    ShGlLogger.debug method
    * @return         null
    * @description    
    This method is called by methods which needs to capture a debug statment into 
    Salesforce. The string that needs to be displayed in the debug log is passed to 
    this method and is added to the list of debug logs that will be inserted into 
    Salesforce
    ******************************************************************************/
    static public void debug(string debugString){
        Custom_Log__c log = new Custom_Log__c(
            StackTrace__c = getStackTrace(),
            Limits__c = getLimits(),
            Message__c = debugString,
            LogType__c = DEBUGTYPE,           
            Sequence__c = sequence);
        debugList.add(log);
        sequence++;
    }
    
    /******************************************************************************
    * @author         Rey Austral
    * @date           03.27.2017
    * @param          exception string is passed from the method that calls the 
    Logger.debug method
    * @return         null
    * @description    
    Similar to the debug method, this method is called by methods which needs to 
    capture a exception statment into Salesforce. The string that needs to be 
    displayed in the debug log is passed to this method and is added to the list of 
    exception logs that will be inserted into Salesforce
    ******************************************************************************/
    static public void debugException(Exception ex){        
        string exceptionInfo = ex.getMessage() + STACKSTR + ex.getStackTraceString();
        Custom_Log__c log = new Custom_Log__c(
            StackTrace__c = getStackTrace(),
            Limits__c = getLimits(),
            Message__c = exceptionInfo,
            LogType__c = EXCEPTIONTYPE,                   
            ExceptionLine__c = ex.getLineNumber(),
            ExceptionType__c = ex.getTypeName(),
            Sequence__c = sequence);
        exceptionList.add(log);
        sequence++;
    }
    
    /******************************************************************************
    * @author         Rey Austral
    * @date           03.27.2017
    * @param          string
    * @return         null
    * @description    
    This method takes a string exception parameter and then passes it to the standard
    debug excpeption method after translating the exception to an exception type.
    ******************************************************************************/  
    static public void debugException(string exStr){
        CustomException ex = new CustomException(exStr);
        debugException(ex);
    }
    
    /******************************************************************************
    * @author         Rey Austral
    * @date           03.27.2017
    * @param          null
    * @return         limit string - string that will contains the actual values of 
    the limits reached by the execution against the governor limits 
    set by Salesforce.
    * @description    
    This methods uses the Limit() method in Salesforce to call all the limits 
    reached in the current execution context againsts the governor limits set by 
    Salesforce. 
	******************************************************************************/  
    static private string getLimits(){        
        string limitstring = '';        
        limitstring += 'Query Limits: '+ Limits.getQueries() + '/' + Limits.getLimitQueries() +'\n';
        limitstring += 'DML Rows Limits: '+Limits.getDMLRows()+'/' + Limits.getLimitDMLRows()+'\n';
        limitstring += 'Heap Size Limits: '+Limits.getHeapSize()+'/' +Limits.getLimitHeapSize()+'\n';
        limitstring += 'Query Return Limits: '+Limits.getQueryRows()+'/' + Limits.getLimitQueryRows()+'\n';      
        limitstring += 'Aggregate Queries: '+Limits.getAggregateQueries()+'/' + Limits.getLimitAggregateQueries();
        limitstring += 'Callouts: '+Limits.getCallouts()+'/' +Limits.getLimitCallouts();    
        limitstring += 'CPU Time: '+Limits.getCpuTime()+'/' +Limits.getLimitCpuTime();
        limitstring += 'DML Statements: '+Limits.getDMLStatements()+'/' +Limits.getLimitDMLStatements();
        limitstring += 'Email Invocations: '+Limits.getEmailInvocations()+'/' +Limits.getLimitEmailInvocations();    
        limitstring += 'Future Calls: '+Limits.getFutureCalls()+'/' +Limits.getLimitFutureCalls();     
        limitstring += 'Query Locator Rows: '+Limits.getQueryLocatorRows() +'/'+Limits.getLimitQueryLocatorRows();     
        
        return limitstring.left(254);
        
    }
    
    /******************************************************************************
    * @author         Rey Austral
    * @date           03.27.2017
    * @param          null
    * @return         returns the stacktrace string that will contain the stack 
    				  trace entries along with the trace level
    ******************************************************************************/  
    static public string getStackTrace(){
        
        string retVal ='';
        
        if (stack != null && stack.size() >0){
            String spaces='                                                                ';       
            for (StackTrace se : stack)   {
                
                Integer endIndex = 3 * se.level;
                if (endIndex >= spaces.length())
                    endIndex = spaces.length()-1;
                retVal += spaces.substring(0,endIndex)+se.getEntry()+'\n';
            }
        }
        return retVal;
    }
}