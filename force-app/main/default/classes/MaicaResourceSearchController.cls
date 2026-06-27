/**
 * @description Controller class for MAICA Resource Search LWC
 * Provides search functionality for MAICA Resources based on name
 */
public with sharing class MaicaResourceSearchController {
    
    /**
     * @description Searches for MAICA Resources based on provided criteria
     * @param resourceName The resource name to search for (partial match)
     * @return List of matching maica_cc__Resource__c records
     */
    @AuraEnabled(cacheable=false)
    public static List<maica_cc__Resource__c> searchResources(String resourceName) {
        try {
            // Build dynamic SOQL query
            String query = 'SELECT Id, Name,maica_cc__Type__c,Supplier_Email__c FROM maica_cc__Resource__c WHERE Id != null';
            List<String> conditions = new List<String>();
            
            // Add resource name filter if provided
            if (String.isNotBlank(resourceName)) {
                conditions.add('Name LIKE \'%' + String.escapeSingleQuotes(resourceName) + '%\'');
            }
            
            // type and supplier email filters removed - search by resourceName only
            
            // Add conditions to query
            if (!conditions.isEmpty()) {
                query += ' AND ' + String.join(conditions, ' AND ');
            }
            
            // Add order by and limit
            query += ' ORDER BY Name ASC LIMIT 100';
            
            // Execute query and return results
            List<maica_cc__Resource__c> resources = Database.query(query);
            return resources;
            
        } catch (Exception e) {
            // Log the error
            System.debug('Error in searchResources: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
            
            // Throw AuraHandledException so LWC can catch it
            throw new AuraHandledException('Error searching resources: ' + e.getMessage());
        }
    }
}