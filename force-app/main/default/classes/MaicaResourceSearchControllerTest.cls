@IsTest
public class MaicaResourceSearchControllerTest {

    private static List<Database.SaveResult> insertWithoutDuplicateCheck(List<maica_cc__Resource__c> records) {
        Database.DMLOptions dml = new Database.DMLOptions();
        dml.DuplicateRuleHeader.allowSave = true;
        dml.DuplicateRuleHeader.runAsCurrentUser = true;
        return Database.insert(records, dml);
    }

    @TestSetup
    static void setupTestData() {
        String unique = String.valueOf(DateTime.now().getTime());
        List<maica_cc__Resource__c> testResources = new List<maica_cc__Resource__c>();

        testResources.add(new maica_cc__Resource__c(
            Name = 'Alpha Support Worker ' + unique,
            maica_cc__Type__c = 'Support Worker',
            Supplier_Email__c = 'alpha' + unique + '@test.com',
            maica_cc__Roster_Mode__c = 'Appointment'
        ));

        testResources.add(new maica_cc__Resource__c(
            Name = 'Beta Therapist ' + unique,
            maica_cc__Type__c = 'Therapist',
            Supplier_Email__c = 'beta' + unique + '@test.com',
            maica_cc__Roster_Mode__c = 'Appointment'
        ));

        testResources.add(new maica_cc__Resource__c(
            Name = 'Gamma Support Worker ' + unique,
            maica_cc__Type__c = 'Support Worker',
            Supplier_Email__c = 'gamma' + unique + '@test.com',
            maica_cc__Roster_Mode__c = 'Appointment'
        ));

        testResources.add(new maica_cc__Resource__c(
            Name = 'Delta Nurse ' + unique,
            maica_cc__Type__c = 'Nurse',
            Supplier_Email__c = 'delta' + unique + '@test.com',
            maica_cc__Roster_Mode__c = 'Appointment'
        ));

        insertWithoutDuplicateCheck(testResources);
    }

    // ─── Happy Path Tests ──────────────────────────────────────────────────────

    @IsTest
    static void testSearchResources_NoFilters_ReturnsAll() {
        Test.startTest();
        List<maica_cc__Resource__c> results = MaicaResourceSearchController.searchResources(null);
        Test.stopTest();

        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertEquals(4, results.size(), 'Should return all 4 test resources');
    }

    @IsTest
    static void testSearchResources_BlankName_ReturnsAll() {
        Test.startTest();
        List<maica_cc__Resource__c> results = MaicaResourceSearchController.searchResources('');
        Test.stopTest();

        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertEquals(4, results.size(), 'Blank name filter should return all resources');
    }

    @IsTest
    static void testSearchResources_ExactName_ReturnsMatch() {
        maica_cc__Resource__c inserted = [
            SELECT Id, Name FROM maica_cc__Resource__c
            WHERE Name LIKE 'Alpha Support Worker%'
            LIMIT 1
        ];

        Test.startTest();
        List<maica_cc__Resource__c> results = MaicaResourceSearchController.searchResources(inserted.Name);
        Test.stopTest();

        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertEquals(1, results.size(), 'Should return exactly 1 matching resource');
        System.assertEquals(inserted.Name, results[0].Name, 'Resource name should match');
    }

    @IsTest
    static void testSearchResources_PartialName_ReturnsMatches() {
        Test.startTest();
        List<maica_cc__Resource__c> results = MaicaResourceSearchController.searchResources('Support Worker');
        Test.stopTest();

        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertEquals(2, results.size(), 'Should return 2 resources matching partial name');
    }

    @IsTest
    static void testSearchResources_PartialNamePrefix_ReturnsMatch() {
        Test.startTest();
        List<maica_cc__Resource__c> results = MaicaResourceSearchController.searchResources('Beta Therapist');
        Test.stopTest();

        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertEquals(1, results.size(), 'Should return 1 resource matching prefix');
        System.assert(results[0].Name.startsWith('Beta Therapist'), 'Should return Beta Therapist record');
    }

    @IsTest
    static void testSearchResources_CaseInsensitive_ReturnsMatch() {
        Test.startTest();
        List<maica_cc__Resource__c> results = MaicaResourceSearchController.searchResources('alpha support worker');
        Test.stopTest();

        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertEquals(1, results.size(), 'LIKE search should be case-insensitive');
        System.assert(results[0].Name.startsWith('Alpha Support Worker'), 'Should return Alpha Support Worker record');
    }

    @IsTest
    static void testSearchResources_ReturnsCorrectFields() {
        Test.startTest();
        List<maica_cc__Resource__c> results = MaicaResourceSearchController.searchResources('Alpha Support Worker');
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return 1 resource');
        maica_cc__Resource__c resource = results[0];

        System.assertNotEquals(null, resource.Id,                'Id should be populated');
        System.assertNotEquals(null, resource.Name,              'Name should be populated');
        System.assertNotEquals(null, resource.maica_cc__Type__c, 'Type should be populated');
        System.assertNotEquals(null, resource.Supplier_Email__c, 'Supplier Email should be populated');
    }

    @IsTest
    static void testSearchResources_ResultsOrderedByName() {
        Test.startTest();
        List<maica_cc__Resource__c> results = MaicaResourceSearchController.searchResources(null);
        Test.stopTest();

        System.assertEquals(4, results.size(), 'Should return all resources');
        for (Integer i = 0; i < results.size() - 1; i++) {
            System.assert(
                results[i].Name <= results[i + 1].Name,
                'Results should be ordered by Name ASC. Found: ' + results[i].Name + ' before ' + results[i + 1].Name
            );
        }
    }

    // ─── No Results Tests ──────────────────────────────────────────────────────

    @IsTest
    static void testSearchResources_NoMatch_ReturnsEmpty() {
        Test.startTest();
        List<maica_cc__Resource__c> results = MaicaResourceSearchController.searchResources('ZZZNoMatchXXX');
        Test.stopTest();

        System.assertNotEquals(null, results, 'Result list should not be null even with no matches');
        System.assertEquals(0, results.size(), 'Should return empty list when no resources match');
    }

    // ─── Special Character / Injection Tests ──────────────────────────────────

    @IsTest
    static void testSearchResources_SingleQuoteInName_DoesNotThrow() {
        Test.startTest();
        List<maica_cc__Resource__c> results;
        try {
            results = MaicaResourceSearchController.searchResources('Brien');
            System.assertNotEquals(null, results, 'Should return a list (possibly empty)');
        } catch (AuraHandledException e) {
            System.assert(false, 'Single quote input should not throw an exception due to escapeSingleQuotes');
        }
        Test.stopTest();
    }

    @IsTest
    static void testSearchResources_SpecialCharacters_HandledGracefully() {
        Test.startTest();
        List<maica_cc__Resource__c> results;
        try {
            results = MaicaResourceSearchController.searchResources('%test%');
            System.assertNotEquals(null, results, 'Special characters should be handled gracefully');
        } catch (AuraHandledException e) {
            System.assert(false, 'Special characters should not cause an exception');
        }
        Test.stopTest();
    }

    // ─── Limit Test ───────────────────────────────────────────────────────────

    @IsTest
    static void testSearchResources_RespectsLimit() {
        String unique = String.valueOf(DateTime.now().getTime());
        List<maica_cc__Resource__c> bulkResources = new List<maica_cc__Resource__c>();

        for (Integer i = 0; i < 100; i++) {
            bulkResources.add(new maica_cc__Resource__c(
                Name = 'Bulk Resource ' + unique + '_' + i,
                maica_cc__Type__c = 'Support Worker',
                Supplier_Email__c = 'bulk' + unique + i + '@test.com',
                maica_cc__Roster_Mode__c = 'Appointment'
            ));
        }
        insertWithoutDuplicateCheck(bulkResources);

        Test.startTest();
        List<maica_cc__Resource__c> results = MaicaResourceSearchController.searchResources(null);
        Test.stopTest();

        System.assert(results.size() <= 100, 'Results should be capped at the LIMIT 100');
    }
}