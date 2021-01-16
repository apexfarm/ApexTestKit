/**
 * Copyright 2018 Jeff Jin
 * https://github.com/apexfarm/ApexTestKit
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
public with sharing class ATKTest {

    @IsTest
    static void test_OneToMany() {
        ATK.SaveResult result = ATK.prepare(Account.SObjectType, 10)
            .withChildren(Case.SObjectType, Case.AccountId, 40)
            .also()
            .withChildren(Contact.SObjectType, Contact.AccountId, 20)
                .withChildren(Case.SObjectType, Case.ContactId)
            .save(false);

        for (Integer i = 0; i < 10; i++) {
            Account acc = (Account)result.get(Account.SObjectType)[i];
            Contact contact1 = (Contact)result.get(Contact.SObjectType)[i * 2];
            Contact contact2 = (Contact)result.get(Contact.SObjectType)[i * 2 + 1];
            Case case1 = (Case)result.get(Case.SObjectType)[i * 4];
            Case case2 = (Case)result.get(Case.SObjectType)[i * 4 + 1];
            Case case3 = (Case)result.get(Case.SObjectType)[i * 4 + 2];
            Case case4 = (Case)result.get(Case.SObjectType)[i * 4 + 3];

            System.assertEquals(acc, contact1.Account);
            System.assertEquals(acc, contact2.Account);
            System.assertEquals(acc, case1.Account);
            System.assertEquals(acc, case2.Account);
            System.assertEquals(acc, case3.Account);
            System.assertEquals(acc, case4.Account);
            System.assertEquals(contact1, case1.Contact);
            System.assertEquals(contact1, case2.Contact);
            System.assertEquals(contact2, case3.Contact);
            System.assertEquals(contact2, case4.Contact);
        }
    }

    @IsTest
    static void test_OneToMany_Mock() {
        ATK.SaveResult result = ATK.prepare(Account.SObjectType, 10)
            .withChildren(Case.SObjectType, Case.AccountId, 40)
            .also()
            .withChildren(Contact.SObjectType, Contact.AccountId, 20)
                .withChildren(Case.SObjectType, Case.ContactId)
            .mock();

        for (Integer i = 0; i < 10; i++) {
            Account acc = (Account)result.get(Account.SObjectType)[i];
            Contact contact1 = (Contact)result.get(Contact.SObjectType)[i * 2];
            Contact contact2 = (Contact)result.get(Contact.SObjectType)[i * 2 + 1];
            Case case1 = (Case)result.get(Case.SObjectType)[i * 4];
            Case case2 = (Case)result.get(Case.SObjectType)[i * 4 + 1];
            Case case3 = (Case)result.get(Case.SObjectType)[i * 4 + 2];
            Case case4 = (Case)result.get(Case.SObjectType)[i * 4 + 3];

            System.assertEquals(acc.Id, contact1.Account.Id);
            System.assertEquals(acc.Id, contact2.Account.Id);
            System.assertEquals(acc.Id, case1.Account.Id);
            System.assertEquals(acc.Id, case2.Account.Id);
            System.assertEquals(acc.Id, case3.Account.Id);
            System.assertEquals(acc.Id, case4.Account.Id);
            System.assertEquals(contact1.Id, case1.Contact.Id);
            System.assertEquals(contact1.Id, case2.Contact.Id);
            System.assertEquals(contact2.Id, case3.Contact.Id);
            System.assertEquals(contact2.Id, case4.Contact.Id);
        }
    }

    @IsTest
    static void test_OneToMany_Size() {
        ATK.SaveResult result = ATK.prepare(Account.SObjectType, 10)
            .withChildren(Contact.SObjectType, Contact.AccountId, 20)
            .save(false);

        for (Integer i = 0; i < 10; i++) {
            Account acc = (Account)result.get(Account.SObjectType)[i];
            Contact contact1 = (Contact)result.get(Contact.SObjectType)[i * 2];
            Contact contact2 = (Contact)result.get(Contact.SObjectType)[i * 2 + 1];

            System.assertEquals(acc, contact1.Account);
            System.assertEquals(acc, contact2.Account);
        }
    }

    @IsTest
    static void test_OneToMany_Size_Zero() {
        ATK.SaveResult result = ATK.prepare(Account.SObjectType, 0)
            .withChildren(Contact.SObjectType, Contact.AccountId, 0)
            .save(false);

        List<Account> accounts = result.get(Account.SObjectType);
        List<Contact> contacts = result.get(Contact.SObjectType);

        System.assertEquals(0, accounts.size());
        System.assertEquals(0, contacts.size());
    }

    @IsTest
    static void test_OneToMany_List() {
        List<Account> accounts = new List<Account>();
        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < 10; ++i) {
            accounts.add(new Account());
            contacts.add(new Contact());
            contacts.add(new Contact());
        }

        ATK.SaveResult result = ATK.prepare(Account.SObjectType, accounts)
            .withChildren(Contact.SObjectType, Contact.AccountId, contacts)
            .save(false);

        for (Integer i = 0; i < 10; i++) {
            Account acc = (Account)result.get(Account.SObjectType)[i];
            Contact contact1 = (Contact)result.get(Contact.SObjectType)[i * 2];
            Contact contact2 = (Contact)result.get(Contact.SObjectType)[i * 2 + 1];

            System.assertEquals(acc, contact1.Account);
            System.assertEquals(acc, contact2.Account);
        }
    }

    @IsTest
    static void test_OneToMany_List_Empty() {
        ATK.SaveResult result = ATK.prepare(Account.SObjectType, new List<Account>())
            .withChildren(Contact.SObjectType, Contact.AccountId, new List<Contact>())
            .save(false);

        List<Account> accounts = result.get(Account.SObjectType);
        List<Contact> contacts = result.get(Contact.SObjectType);

        System.assertEquals(0, accounts.size());
        System.assertEquals(0, contacts.size());
    }

    @IsTest
    static void test_ManyToOne() {
        ATK.SaveResult result = ATK.prepare(Account.SObjectType, 10)
            .withChildren(Contact.SObjectType, Contact.AccountId, 20)
                .withChildren(Case.SObjectType, Case.ContactId, 40)
                    // in order to test this method
                    .withParents(Account.SObjectType, Case.AccountId)
            .save(false);


        for (Integer i = 0; i < 10; i++) {
            Account acc = (Account)result.get(Account.SObjectType)[i];
            Contact contact1 = (Contact)result.get(Contact.SObjectType)[i * 2];
            Contact contact2 = (Contact)result.get(Contact.SObjectType)[i * 2 + 1];
            Case case1 = (Case)result.get(Case.SObjectType)[i * 4];
            Case case2 = (Case)result.get(Case.SObjectType)[i * 4 + 1];
            Case case3 = (Case)result.get(Case.SObjectType)[i * 4 + 2];
            Case case4 = (Case)result.get(Case.SObjectType)[i * 4 + 3];

            System.assertEquals(acc, contact1.Account);
            System.assertEquals(acc, contact2.Account);
            System.assertEquals(acc, case1.Account);
            System.assertEquals(acc, case2.Account);
            System.assertEquals(acc, case3.Account);
            System.assertEquals(acc, case4.Account);
            System.assertEquals(contact1, case1.Contact);
            System.assertEquals(contact1, case2.Contact);
            System.assertEquals(contact2, case3.Contact);
            System.assertEquals(contact2, case4.Contact);
        }
    }

    @IsTest
    static void test_ManyToOne_Mock() {
        ATK.SaveResult result = ATK.prepare(Account.SObjectType, 10)
            .withChildren(Contact.SObjectType, Contact.AccountId, 20)
                .withChildren(Case.SObjectType, Case.ContactId, 40)
                    // in order to test this method
                    .withParents(Account.SObjectType, Case.AccountId)
            .mock();


        for (Integer i = 0; i < 10; i++) {
            Account acc = (Account)result.get(Account.SObjectType)[i];
            Contact contact1 = (Contact)result.get(Contact.SObjectType)[i * 2];
            Contact contact2 = (Contact)result.get(Contact.SObjectType)[i * 2 + 1];
            Case case1 = (Case)result.get(Case.SObjectType)[i * 4];
            Case case2 = (Case)result.get(Case.SObjectType)[i * 4 + 1];
            Case case3 = (Case)result.get(Case.SObjectType)[i * 4 + 2];
            Case case4 = (Case)result.get(Case.SObjectType)[i * 4 + 3];

            System.assertEquals(acc.Id, contact1.Account.Id);
            System.assertEquals(acc.Id, contact2.Account.Id);
            System.assertEquals(acc.Id, case1.Account.Id);
            System.assertEquals(acc.Id, case2.Account.Id);
            System.assertEquals(acc.Id, case3.Account.Id);
            System.assertEquals(acc.Id, case4.Account.Id);
            System.assertEquals(contact1.Id, case1.Contact.Id);
            System.assertEquals(contact1.Id, case2.Contact.Id);
            System.assertEquals(contact2.Id, case3.Contact.Id);
            System.assertEquals(contact2.Id, case4.Contact.Id);
        }
    }

    @IsTest
    static void test_ManyToOne_Size() {
        ATK.SaveResult result = ATK.prepare(Contact.SObjectType, 20)
            .withParents(Account.SObjectType, Contact.AccountId, 10)
            .save(false);

        for (Integer i = 0; i < 10; i++) {
            Account acc = (Account)result.get(Account.SObjectType)[i];
            Contact contact1 = (Contact)result.get(Contact.SObjectType)[i * 2];
            Contact contact2 = (Contact)result.get(Contact.SObjectType)[i * 2 + 1];

            System.assertEquals(acc, contact1.Account);
            System.assertEquals(acc, contact2.Account);
        }
    }

    @IsTest
    static void test_ManyToOne_Size_Zero() {
        ATK.SaveResult result = ATK.prepare(Contact.SObjectType, new List<Contact>())
            .withParents(Account.SObjectType, Contact.AccountId, new List<Account>())
            .save(false);

        List<Account> accounts = result.get(Account.SObjectType);
        List<Contact> contacts = result.get(Contact.SObjectType);

        System.assertEquals(0, accounts.size());
        System.assertEquals(0, contacts.size());
    }

    @IsTest
    static void test_ManyToOne_List() {
        List<Account> accounts = new List<Account>();
        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < 10; ++i) {
            accounts.add(new Account());
            contacts.add(new Contact());
            contacts.add(new Contact());
        }

        ATK.SaveResult result = ATK.prepare(Contact.SObjectType, contacts)
            .withParents(Account.SObjectType, Contact.AccountId, accounts)
            .save(false);

        for (Integer i = 0; i < 10; i++) {
            Account acc = (Account)result.get(Account.SObjectType)[i];
            Contact contact1 = (Contact)result.get(Contact.SObjectType)[i * 2];
            Contact contact2 = (Contact)result.get(Contact.SObjectType)[i * 2 + 1];

            System.assertEquals(acc, contact1.Account);
            System.assertEquals(acc, contact2.Account);
        }
    }


    @IsTest
    static void test_ManyToOne_List_Empty() {
        ATK.SaveResult result = ATK.prepare(Contact.SObjectType, new List<Contact>())
            .withParents(Account.SObjectType, Contact.AccountId, new List<Account>())
            .save(false);

        List<Account> accounts = result.get(Account.SObjectType);
        List<Contact> contacts = result.get(Contact.SObjectType);

        System.assertEquals(0, accounts.size());
        System.assertEquals(0, contacts.size());
    }

    @IsTest
    static void test_SaveResult() {
        ATK.SaveResult result = ATK.prepare(Account.SObjectType, 1)
            .withChildren(Contact.SObjectType, Contact.AccountId, 2)
                .withChildren(Case.SObjectType, Case.ContactId, 3)
                    .withParents(Account.SObjectType, Case.AccountId, 4)
                        .withChildren(Contact.SObjectType, Contact.AccountId, 5)
            .save(false);

        System.assertEquals(1, result.get(Account.SObjectType).size());
        System.assertEquals(1, result.get(Account.SObjectType, 0).size());
        System.assertEquals(4, result.get(Account.SObjectType, 1).size());
        System.assertEquals(2, result.get(Contact.SObjectType).size());
        System.assertEquals(2, result.get(Contact.SObjectType, 0).size());
        System.assertEquals(5, result.get(Contact.SObjectType, 1).size());
        System.assertEquals(3, result.get(Case.SObjectType).size());

        System.assertEquals(5, result.getAll(Account.SObjectType).size());
        System.assertEquals(7, result.getAll(Contact.SObjectType).size());
        System.assertEquals(3, result.getAll(Case.SObjectType).size());
    }

    @IsTest
    static void test_SaveResult_Also() {
        ATK.SaveResult result = ATK.prepare(Account.SObjectType, 1)
            .withChildren(Contact.SObjectType, Contact.AccountId, 2)
                .withChildren(Case.SObjectType, Case.ContactId, 3)
                .also()
                .withChildren(Case.SObjectType, Case.ContactId, 4)
            .also(2)
            .withChildren(Contact.SObjectType, Contact.AccountId, 5)
            .save(false);

        System.assertEquals(1, result.getAll(Account.SObjectType).size());
        System.assertEquals(7, result.getAll(Contact.SObjectType).size());
        System.assertEquals(7, result.getAll(Case.SObjectType).size());

    }

    @IsTest
    static void test_Fields() {
        ATK.prepare(Account.SObjectType, 0)
            .recordType('==Fake Record Type==')
            .build(new AccountEntityBuilder())
            .field(Account.Name).index('Name-{0000}')
            .field(Account.Name).repeat('A')
            .field(Account.Name).repeat('A', 'B')
            .field(Account.Name).repeat('A', 'B', 'C')
            .field(Account.Name).repeat(new List<String> { 'A', 'B', 'C' })
            .field(Account.Name).add(1, 1)
            .field(Account.Name).substract(1, 1)
            .field(Account.Name).divide(1, 1)
            .field(Account.Name).multiply(1, 1)
            .field(Account.Name).addYears(Date.newInstance(2020, 1, 1), 1)
            .field(Account.Name).addMonths(Date.newInstance(2020, 1, 1), 1)
            .field(Account.Name).addDays(Date.newInstance(2020, 1, 1), 1)
            .field(Account.Name).addHours(Time.newInstance(0, 0, 0, 0), 1)
            .field(Account.Name).addMinutes(Time.newInstance(0, 0, 0, 0), 1)
            .field(Account.Name).addSeconds(Time.newInstance(0, 0, 0, 0), 1);

        ATK.prepare(User.SObjectType, 0)
            .profile('==Fake Profile==')
            .permissionSet('==Fake Permission Set==')
            .permissionSet('==Fake Permission Set 1==', '==Fake Permission Set 2==')
            .permissionSet('==Fake Permission Set 1==', '==Fake Permission Set 2==', '==Fake Permission Set 3==')
            .permissionSet(new List<String> {'==Fake Permission Set 1==', '==Fake Permission Set 2=='});
    }

    class AccountEntityBuilder implements ATK.EntityBuilder {
        public void build(ATK.Entity accountEneity, Integer size) {
        }
    }

    @IsTest
    static void test_Mock_SystemField() {
        ATKCore.batchSize = 3;

        Id fakeUserId = ATKCore.FakeId.get(User.SObjectType, 1);
        ATK.SaveResult result = ATK.prepare(Account.SObjectType, 9)
            .field(Account.CreatedById).repeat(fakeUserId)
            .field(Account.CreatedDate).repeat(Datetime.newInstance(2020, 1, 1))
            .field(Account.LastModifiedById).repeat(fakeUserId)
            .field(Account.LastModifiedDate).addDays(Datetime.newInstance(2020, 1, 1), 1)
            .mock();

        List<SObject> accounts = result.get(Account.SObjectType);
        System.assertEquals(9, accounts.size());
        for (SObject obj : accounts) {
            Account acc = (Account)obj;
            System.assertEquals(fakeUserId, acc.CreatedById);
            System.assertEquals(Datetime.newInstance(2020, 1, 1), acc.CreatedDate);
        }
    }
}
