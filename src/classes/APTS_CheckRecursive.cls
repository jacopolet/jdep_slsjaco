/**Class to prevent recursion in Apex triggers.
E.g. to use - add the trigger event along with the handler name in the Set.
Check whether the set has the specific string before the execution and add the specific string to the set after the execution.
This ensures that the trigger events are called only once.
**/
public class APTS_CheckRecursive{
    public static Set<String> processedSet = new Set<String>();
    public static boolean skipTriggerLogic = false;
}