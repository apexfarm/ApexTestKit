/**
 * Copyright 2020 Jeff Jin
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

@IsTest
public with sharing class Demo {
    @IsTest
    static void test_ATK_Sales() {
        /*
            Acc1 - ODR1 - Con1
                 - ODR2 - Con2
            Acc2 - ODR3 - Con3
                 - ODR4 - Con4

            Acc1 - OPP1 - Con1
                 - OPP2 - Con2
            Acc2 - OPP3 - Con3
                 - OPP4 - Con4

            Con1 - OPC1 - OPP1
            Con1 - OPC2
            Con2 - OPC3 - OPP2
            Con2 - OPC4
            Con3 - OPC5 - OPP3
            Con3 - OPC6
            Con4 - OPC1 - OPP4
            Con4 - OPC8
        */
        Test.startTest();
        ATK.SaveResult result = ATK.prepare(Account.SObjectType, 200)
            .field(Account.RecordTypeId).recordType('Business_Account')
            .field(Account.Name).index('Name-{0000}')
            .withChildren(Contact.SObjectType, Contact.AccountId, 400)
                .field(Contact.LastName).index('Name-{0000}')
                .field(Contact.Email).index('test.user+{0000}@email.com')
                .field(Contact.MobilePhone).index('+86 186 7777 {0000}')
                .withChildren(OpportunityContactRole.SObjectType, OpportunityContactRole.ContactId, 800)
                    .field(OpportunityContactRole.Role).repeat('Business User', 'Decision Maker')
                    .withParents(Opportunity.SObjectType, OpportunityContactRole.OpportunityId, 400)
                        .field(Opportunity.Name).index('Name-{0000}')
                        .field(Opportunity.CloseDate).repeat(Date.today())
                        .field(Opportunity.ForecastCategoryName).repeat('Pipeline')
                        .field(Opportunity.Probability).repeat(0.9, 0.8, 0.7)
                        .field(Opportunity.StageName).repeat('Prospecting')
                        .field(Opportunity.TotalOpportunityQuantity).add(1000, 10)
                        .withParents(Account.SObjectType, Opportunity.AccountId)
            .also(4)
            .withChildren(Order.SObjectType, Order.AccountId, 400)
                .field(Order.Name).index('Name-{0000}')
                .field(Order.EffectiveDate).addDays(Date.today(), 1)
                .field(Order.Status).repeat('Draft')
                .withParents(Contact.SObjectType, Order.BillToContactId)
                .also()
                .withParents(Opportunity.SObjectType, Order.OpportunityId)
            .save(false);
        Test.stopTest();

        System.assertEquals(200, result.get(Account.SObjectType).size());
        System.assertEquals(400, result.get(Contact.SObjectType).size());
        System.assertEquals(800, result.get(OpportunityContactRole.SObjectType).size());
        System.assertEquals(400, result.get(Opportunity.SObjectType).size());
        System.assertEquals(400, result.get(Order.SObjectType).size());

        for (Integer i = 0; i < 200; i++) {
            Account acc = (Account)result.get(Account.SObjectType)[i];
            Contact contact1 = (Contact)result.get(Contact.SObjectType)[i * 2];
            Contact contact2 = (Contact)result.get(Contact.SObjectType)[i * 2 + 1];
            Order order1 = (Order)result.get(Order.SObjectType)[i * 2];
            Order order2 = (Order)result.get(Order.SObjectType)[i * 2 + 1];
            Opportunity opp1 = (Opportunity)result.get(Opportunity.SObjectType)[i * 2];
            Opportunity opp2 = (Opportunity)result.get(Opportunity.SObjectType)[i * 2 + 1];
            OpportunityContactRole opc1 = (OpportunityContactRole)result.get(OpportunityContactRole.SObjectType)[i * 4];
            OpportunityContactRole opc2 = (OpportunityContactRole)result.get(OpportunityContactRole.SObjectType)[i * 4 + 1];
            OpportunityContactRole opc3 = (OpportunityContactRole)result.get(OpportunityContactRole.SObjectType)[i * 4 + 2];
            OpportunityContactRole opc4 = (OpportunityContactRole)result.get(OpportunityContactRole.SObjectType)[i * 4 + 3];

            System.assert(acc.RecordTypeId != null);
            System.assertEquals(acc, contact1.Account);
            System.assertEquals(acc, contact2.Account);
            System.assertEquals(acc, order1.Account);
            System.assertEquals(acc, order2.Account);
            System.assertEquals(acc, opp1.Account);
            System.assertEquals(acc, opp2.Account);
            System.assertEquals(contact1, order1.BillToContact);
            System.assertEquals(contact2, order2.BillToContact);
            System.assertEquals(opp1, order1.Opportunity);
            System.assertEquals(opp2, order2.Opportunity);
            System.assertEquals(contact1, opc1.Contact);
            System.assertEquals(contact1, opc2.Contact);
            System.assertEquals(contact2, opc3.Contact);
            System.assertEquals(contact2, opc4.Contact);
            System.assertEquals(opp1, opc1.Opportunity);
            System.assertEquals(opp1, opc2.Opportunity);
            System.assertEquals(opp2, opc3.Opportunity);
            System.assertEquals(opp2, opc4.Opportunity);

            // Natural Numbers
            System.assertEquals(String.format('Name-{0}', new List<Object> { String.valueOf(i + 1).leftPad(4, '0') }), acc.Name);
            System.assertEquals(String.format('Name-{0}', new List<Object> { String.valueOf(i * 2 + 1 ).leftPad(4, '0') }), contact1.LastName);
            System.assertEquals(String.format('Name-{0}', new List<Object> { String.valueOf(i * 2 + 2 ).leftPad(4, '0') }), contact2.LastName);

            // Arithmetic
            System.assertEquals(Date.today().addDays((i * 2) * 1), order1.EffectiveDate);
            System.assertEquals(Date.today().addDays((i * 2 + 1) * 1), order2.EffectiveDate);
        }
    }

    @IsTest
    static void test_ATK_Users() {
        Test.startTest();
        ATK.SaveResult result = ATK.prepare(Account.SObjectType, 100)
            .field(Account.RecordTypeId).recordType('Business_Account')
            .field(Account.Name).index('Name-{000}')
            .withChildren(Contact.SObjectType, Contact.AccountId, 300)
                .field(Contact.LastName).index('Name-{000}')
                .withChildren(User.SObjectType, User.ContactId, 300)
                    .field(User.ProfileId).profile('Customer Community User')
                    .field(User.FirstName).repeat('FirstName')
                    .field(User.LastName).repeat('LastName')
                    .field(User.Email).index('test.user+{0000}@email.com')
                    .field(User.UserName).index('test.user+{0000}@email.com')
                    .field(User.Alias).index('test{0000}')
                    .field(User.EmailEncodingKey).repeat('UTF-8')
                    .field(User.LanguageLocaleKey).repeat('en_US')
                    .field(User.LocaleSidKey).repeat('en_US')
                    .field(User.TimeZoneSidKey).repeat('Pacific/Auckland')
            .save(false);
        Test.stopTest();

        for (Integer i = 0; i < 300; i++ ) {
            User user = (User)result.get(User.SObjectType)[i];
            Contact contact = (Contact)result.get(Contact.SObjectType)[i];

            System.assertEquals(contact, user.Contact);
        }
    }

    @IsTest
    static void test_ATK_Campaigns() {
        Test.startTest();
        ATK.SaveResult result = ATK.prepare(Campaign.SObjectType, 4)
            .field(campaignFieldBuilder)
            .withChildren(Campaign.SObjectType, Campaign.ParentId, 4)
                .field(campaignFieldBuilder)
                .withChildren(Campaign.SObjectType, Campaign.ParentId, 4)
                    .field(campaignFieldBuilder)
                    .withChildren(Campaign.SObjectType, Campaign.ParentId, 4)
                        .field(campaignFieldBuilder)
                        .withChildren(Campaign.SObjectType, Campaign.ParentId, 4)
                            .field(campaignFieldBuilder)
            .save(true);
        Test.stopTest();

        LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true LIMIT 1];

        for (Integer i = 4; i > -1; i--) {
            List<SObject> leads =  result.get(Lead.SObjectType, i);
            for (SObject obj : leads) {
                Lead lead = (Lead)obj;
                Database.LeadConvert lc = new Database.LeadConvert();
                lc.setLeadId(lead.Id);
                lc.setDoNotCreateOpportunity(true);
                lc.setConvertedStatus(convertStatus.MasterLabel);
                Database.LeadConvertResult lcr = Database.convertLead(lc);
                System.assert(lcr.isSuccess());
            }

            Map<Id, SObject> campaigns =  new Map<Id, SObject>(result.get(Campaign.SObjectType, i));
            for (Campaign camp : [
                SELECT NumberOfContacts, HierarchyNumberOfContacts
                FROM Campaign
                WHERE Id IN :campaigns.keySet()]) {
                System.assertEquals(2, camp.NumberOfContacts);
                System.assertEquals(2 * (5 - i), camp.HierarchyNumberOfContacts);
            }
        }
    }

    static CampaignFieldBuilder campaignFieldBuilder = new CampaignFieldBuilder();

    class CampaignFieldBuilder implements ATK.FieldBuilder {
        public ATK.Entity build(ATK.Entity campaignEntity, Integer size) {
            return campaignEntity
                .field(Campaign.Type).repeat('Partners')
                .field(Campaign.Name).index('Name-{0000}')
                .field(Campaign.StartDate).repeat(Date.today())
                .field(Campaign.EndDate).repeat(Date.today().addMonths(1))
                .withChildren(CampaignMember.SObjectType, CampaignMember.CampaignId, size * 2)
                    .withParents(Lead.SObjectType, CampaignMember.LeadId, size * 2)
                        .field(Lead.Company).index('Name-{0000}')
                        .field(Lead.LastName).index('Name-{0000}')
                        .field(Lead.Email).index('test.user+{0000}@email.com')
                        .field(Lead.MobilePhone).index('+86 186 7777 {0000}')
                .also(2);
        }
    }
}
