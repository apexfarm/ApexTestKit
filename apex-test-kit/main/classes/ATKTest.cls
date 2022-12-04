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
    // ****************
    // #region Junction
    // ****************

    @IsTest
    static void test_Junction_LCA() {
        // Account(10) --|------------------|--> Case(40)
        //               |--> Contact(20) --|
        // prettier-ignore
        ATK.SaveResult result = ATK.prepare(Account.SObjectType, 10)
            .withChildren(Case.SObjectType, Case.AccountId, 40)
                .junctionOf(Case.AccountId, Case.ContactId)
            .also()
            .withChildren(Contact.SObjectType, Contact.AccountId, 20)
                .withChildren(Case.SObjectType, Case.ContactId)
            .mock();
    }

    @IsTest
    static void test_Junction_Size_Prepare() {
        // prettier-ignore
        ATK.SaveResult result = ATK.prepare(Case.SObjectType, 20)
            .junctionOf(Case.AccountId, Case.ContactId)
            .withParents(Account.SObjectType, Case.AccountId, 10)
            .also()
            .withParents(Contact.SObjectType, Case.ContactId, 10)
            .save(false);
        ((ATKCore.SaveResult) result).debug();
        ((ATKCore.SaveResult) result).debug(Account.SObjectType);

        List<Account> accounts = result.get(Account.SObjectType);
        List<Case> cases = result.get(Case.SObjectType);
        List<Contact> contacts = result.get(Contact.SObjectType);

        System.Assert.areEqual(10, accounts.size());
        System.Assert.areEqual(20, cases.size());
        System.Assert.areEqual(10, contacts.size());

        System.Assert.areEqual(accounts[0], cases[0].Account);
        System.Assert.areEqual(contacts[0], cases[0].Contact);
        System.Assert.areEqual(accounts[0], cases[1].Account);
        System.Assert.areEqual(contacts[1], cases[1].Contact);
        System.Assert.areEqual(accounts[1], cases[2].Account);
        System.Assert.areEqual(contacts[2], cases[2].Contact);
        System.Assert.areEqual(accounts[1], cases[3].Account);
        System.Assert.areEqual(contacts[3], cases[3].Contact);

        System.Assert.areEqual(accounts[5], cases[10].Account);
        System.Assert.areEqual(contacts[0], cases[11].Contact);
        System.Assert.areEqual(accounts[5], cases[12].Account);
        System.Assert.areEqual(contacts[1], cases[13].Contact);
        System.Assert.areEqual(accounts[6], cases[14].Account);
        System.Assert.areEqual(contacts[2], cases[15].Contact);
        System.Assert.areEqual(accounts[6], cases[16].Account);
        System.Assert.areEqual(contacts[3], cases[17].Contact);
    }

    @IsTest
    static void test_Junction_Size_Children() {
        // prettier-ignore
        ATK.SaveResult result = ATK.prepare(Account.SObjectType, 10)
            .withChildren(Case.SObjectType, Case.AccountId, 20)
                .junctionOf(Case.AccountId, Case.ContactId)
                .withParents(Contact.SObjectType, Case.ContactId, 10)
            .save(false);
        ((ATKCore.SaveResult) result).debug();
        ((ATKCore.SaveResult) result).debug(Account.SObjectType);

        List<Account> accounts = result.get(Account.SObjectType);
        List<Case> cases = result.get(Case.SObjectType);
        List<Contact> contacts = result.get(Contact.SObjectType);

        System.Assert.areEqual(10, accounts.size());
        System.Assert.areEqual(20, cases.size());
        System.Assert.areEqual(10, contacts.size());

        System.Assert.areEqual(accounts[0], cases[0].Account);
        System.Assert.areEqual(contacts[0], cases[0].Contact);
        System.Assert.areEqual(accounts[0], cases[1].Account);
        System.Assert.areEqual(contacts[1], cases[1].Contact);
        System.Assert.areEqual(accounts[1], cases[2].Account);
        System.Assert.areEqual(contacts[2], cases[2].Contact);
        System.Assert.areEqual(accounts[1], cases[3].Account);
        System.Assert.areEqual(contacts[3], cases[3].Contact);

        System.Assert.areEqual(accounts[5], cases[10].Account);
        System.Assert.areEqual(contacts[0], cases[11].Contact);
        System.Assert.areEqual(accounts[5], cases[12].Account);
        System.Assert.areEqual(contacts[1], cases[13].Contact);
        System.Assert.areEqual(accounts[6], cases[14].Account);
        System.Assert.areEqual(contacts[2], cases[15].Contact);
        System.Assert.areEqual(accounts[6], cases[16].Account);
        System.Assert.areEqual(contacts[3], cases[17].Contact);
    }

    @IsTest
    static void test_Junction_Size_Children2() {
        // prettier-ignore
        ATK.SaveResult result = ATK.prepare(Contact.SObjectType, 10)
            .withChildren(Case.SObjectType, Case.ContactId, 20)
                .junctionOf(Case.ContactId, Case.AccountId)
                .withParents(Account.SObjectType, Case.AccountId, 10)
            .save(false);
        List<Account> accounts = result.get(Account.SObjectType);
        List<Case> cases = result.get(Case.SObjectType);
        List<Contact> contacts = result.get(Contact.SObjectType);

        System.Assert.areEqual(10, accounts.size());
        System.Assert.areEqual(20, cases.size());
        System.Assert.areEqual(10, contacts.size());

        System.Assert.areEqual(contacts[0], cases[0].Contact);
        System.Assert.areEqual(accounts[0], cases[0].Account);
        System.Assert.areEqual(contacts[0], cases[1].Contact);
        System.Assert.areEqual(accounts[1], cases[1].Account);
        System.Assert.areEqual(contacts[1], cases[2].Contact);
        System.Assert.areEqual(accounts[2], cases[2].Account);
        System.Assert.areEqual(contacts[1], cases[3].Contact);
        System.Assert.areEqual(accounts[3], cases[3].Account);

        System.Assert.areEqual(contacts[5], cases[10].Contact);
        System.Assert.areEqual(accounts[0], cases[11].Account);
        System.Assert.areEqual(contacts[5], cases[12].Contact);
        System.Assert.areEqual(accounts[1], cases[13].Account);
        System.Assert.areEqual(contacts[6], cases[14].Contact);
        System.Assert.areEqual(accounts[2], cases[15].Account);
        System.Assert.areEqual(contacts[6], cases[16].Contact);
        System.Assert.areEqual(accounts[3], cases[17].Account);
    }

    @IsTest
    static void test_Junction_Size_Zero() {
        // prettier-ignore
        ATK.SaveResult result = ATK.prepare(Account.SObjectType, 0)
            .withChildren(Case.SObjectType, Case.AccountId, 0)
                .junctionOf(Case.AccountId, Case.ContactId)
                .withParents(Contact.SObjectType, Case.ContactId, 0)
            .save(false);
        List<Account> accounts = result.get(Account.SObjectType);
        List<Case> cases = result.get(Case.SObjectType);
        List<Contact> contacts = result.get(Contact.SObjectType);

        System.Assert.areEqual(0, accounts.size());
        System.Assert.areEqual(0, cases.size());
        System.Assert.areEqual(0, contacts.size());
    }

    @IsTest
    static void test_Junction_List() {
        List<Account> accounts = new List<Account>();
        List<Case> cases = new List<Case>();
        List<Contact> contacts = new List<Contact>();

        for (Integer i = 0; i < 10; ++i) {
            accounts.add(new Account());
            cases.add(new Case());
            cases.add(new Case());
            contacts.add(new Contact());
        }

        // prettier-ignore
        ATK.SaveResult result = ATK.prepare(Account.SObjectType, accounts)
            .withChildren(Case.SObjectType, Case.AccountId, cases)
                .junctionOf(Case.AccountId, Case.ContactId)
                .withParents(Contact.SObjectType, Case.ContactId, contacts)
            .save(false);
        System.Assert.areEqual(10, accounts.size());
        System.Assert.areEqual(20, cases.size());
        System.Assert.areEqual(10, contacts.size());

        System.Assert.areEqual(accounts[0], cases[0].Account);
        System.Assert.areEqual(contacts[0], cases[0].Contact);
        System.Assert.areEqual(accounts[0], cases[1].Account);
        System.Assert.areEqual(contacts[1], cases[1].Contact);
        System.Assert.areEqual(accounts[1], cases[2].Account);
        System.Assert.areEqual(contacts[2], cases[2].Contact);
        System.Assert.areEqual(accounts[1], cases[3].Account);
        System.Assert.areEqual(contacts[3], cases[3].Contact);

        System.Assert.areEqual(accounts[6], cases[0].Account);
        System.Assert.areEqual(contacts[0], cases[0].Contact);
        System.Assert.areEqual(accounts[6], cases[1].Account);
        System.Assert.areEqual(contacts[1], cases[1].Contact);
        System.Assert.areEqual(accounts[7], cases[2].Account);
        System.Assert.areEqual(contacts[2], cases[2].Contact);
        System.Assert.areEqual(accounts[7], cases[3].Account);
        System.Assert.areEqual(contacts[3], cases[3].Contact);
    }

    @IsTest
    static void test_Junction_Partial() {
        // prettier-ignore
        ATK.SaveResult result = ATK.prepare(Account.SObjectType, 10)
        .withChildren(Case.SObjectType, Case.AccountId, 20)
        .save(false);
        List<Account> accounts = result.get(Account.SObjectType);
        List<Case> cases = result.get(Case.SObjectType);

        System.Assert.areEqual(10, accounts.size());
        System.Assert.areEqual(20, cases.size());
        System.Assert.areEqual(accounts[0], cases[0].Account);
        System.Assert.areEqual(accounts[0], cases[1].Account);
        System.Assert.areEqual(accounts[1], cases[2].Account);
        System.Assert.areEqual(accounts[1], cases[3].Account);
    }

    @IsTest
    static void test_Junction_Tripple() {
        // TODO: need assersions
        {
            // prettier-ignore
            ATK.SaveResult result = ATK.prepare(Account.SObjectType, 10)
            .withChildren(Case.SObjectType, Case.AccountId, 20)
                .junctionOf(Case.AccountId, Case.ContactId, Case.OwnerId)
                .withParents(Contact.SObjectType, Case.ContactId, 10)
                .also()
                .withParents(User.SObjectType, Case.OwnerId, 10)
            .mock();
            List<Account> accounts = result.get(Account.SObjectType);
            List<Case> cases = result.get(Case.SObjectType);
            List<Contact> contacts = result.get(Contact.SObjectType);
            List<User> users = result.get(User.SObjectType);
        }

        {
            // prettier-ignore
            ATK.SaveResult result = ATK.prepare(Account.SObjectType, 10)
            .withChildren(Case.SObjectType, Case.AccountId, 20)
                .junctionOf(Case.AccountId, Case.ContactId, Case.OwnerId)
                .withParents(Contact.SObjectType, Case.ContactId, 10)
                .also()
                .withParents(User.SObjectType, Case.OwnerId, 10)
            .save(false);

            List<Account> accounts = result.get(Account.SObjectType);
            List<Case> cases = result.get(Case.SObjectType);
            List<Contact> contacts = result.get(Contact.SObjectType);
            List<User> users = result.get(User.SObjectType);
        }
    }

    // #endregion
    // ********************

    // *******************
    // #region One To Many
    // *******************
    @IsTest
    static void test_OneToMany_Save() {
        // Account(10) --|------------------|--> Case(40)
        //               |--> Contact(20) --|
        // prettier-ignore
        ATK.SaveResult result = ATK.prepare(Account.SObjectType, 10)
            .withChildren(Case.SObjectType, Case.AccountId, 40)
            .also()
            .withChildren(Contact.SObjectType, Contact.AccountId, 20)
                .withChildren(Case.SObjectType, Case.ContactId)
            .save(false);
        for (Integer i = 0; i < 10; i++) {
            Account acc = (Account) result.get(Account.SObjectType)[i];
            Contact contact1 = (Contact) result.get(Contact.SObjectType)[i * 2];
            Contact contact2 = (Contact) result.get(Contact.SObjectType)[i * 2 + 1];
            Case case1 = (Case) result.get(Case.SObjectType)[i * 4];
            Case case2 = (Case) result.get(Case.SObjectType)[i * 4 + 1];
            Case case3 = (Case) result.get(Case.SObjectType)[i * 4 + 2];
            Case case4 = (Case) result.get(Case.SObjectType)[i * 4 + 3];

            System.Assert.areEqual(acc, contact1.Account);
            System.Assert.areEqual(acc, contact2.Account);
            System.Assert.areEqual(acc, case1.Account);
            System.Assert.areEqual(acc, case2.Account);
            System.Assert.areEqual(acc, case3.Account);
            System.Assert.areEqual(acc, case4.Account);
            System.Assert.areEqual(contact1, case1.Contact);
            System.Assert.areEqual(contact1, case2.Contact);
            System.Assert.areEqual(contact2, case3.Contact);
            System.Assert.areEqual(contact2, case4.Contact);
        }
    }

    @IsTest
    static void test_OneToMany_Size() {
        ATK.SaveResult result = ATK.prepare(Account.SObjectType, 10).withChildren(Contact.SObjectType, Contact.AccountId, 20).save(false);

        for (Integer i = 0; i < 10; i++) {
            Account acc = (Account) result.get(Account.SObjectType)[i];
            Contact contact1 = (Contact) result.get(Contact.SObjectType)[i * 2];
            Contact contact2 = (Contact) result.get(Contact.SObjectType)[i * 2 + 1];

            System.Assert.areEqual(acc, contact1.Account);
            System.Assert.areEqual(acc, contact2.Account);
        }
    }

    @IsTest
    static void test_OneToMany_Size_Zero() {
        ATK.SaveResult result = ATK.prepare(Account.SObjectType, 0).withChildren(Contact.SObjectType, Contact.AccountId, 0).save(false);

        List<Account> accounts = result.get(Account.SObjectType);
        List<Contact> contacts = result.get(Contact.SObjectType);

        System.Assert.areEqual(0, accounts.size());
        System.Assert.areEqual(0, contacts.size());
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

        ATK.SaveResult result = ATK.prepare(Account.SObjectType, accounts).withChildren(Contact.SObjectType, Contact.AccountId, contacts).save(false);

        for (Integer i = 0; i < 10; i++) {
            Account acc = (Account) result.get(Account.SObjectType)[i];
            Contact contact1 = (Contact) result.get(Contact.SObjectType)[i * 2];
            Contact contact2 = (Contact) result.get(Contact.SObjectType)[i * 2 + 1];

            System.Assert.areEqual(acc, contact1.Account);
            System.Assert.areEqual(acc, contact2.Account);
        }
    }

    @IsTest
    static void test_OneToMany_List_Empty() {
        ATK.SaveResult result = ATK.prepare(Account.SObjectType, new List<Account>()).withChildren(Contact.SObjectType, Contact.AccountId, new List<Contact>()).save(false);

        List<Account> accounts = result.get(Account.SObjectType);
        List<Contact> contacts = result.get(Contact.SObjectType);

        System.Assert.areEqual(0, accounts.size());
        System.Assert.areEqual(0, contacts.size());
    }

    // #endregion
    // *******************

    // *******************
    // #region Many to One
    // *******************
    @IsTest
    static void test_ManyToOne() {
        // Account(10) --|------------------|--> Case(40)
        //               |--> Contact(20) --|
        // prettier-ignore
        ATK.SaveResult result = ATK.prepare(Case.SObjectType, 40)
            .withParents(Contact.SObjectType, Case.ContactId, 20)
                .withParents(Account.SObjectType, Contact.AccountId, 10)
            .also(2)
            .withParents(Account.SObjectType, Case.AccountId)
            .save(false);
        for (Integer i = 0; i < 10; i++) {
            Account acc = (Account) result.get(Account.SObjectType)[i];
            Contact contact1 = (Contact) result.get(Contact.SObjectType)[i * 2];
            Contact contact2 = (Contact) result.get(Contact.SObjectType)[i * 2 + 1];
            Case case1 = (Case) result.get(Case.SObjectType)[i * 4];
            Case case2 = (Case) result.get(Case.SObjectType)[i * 4 + 1];
            Case case3 = (Case) result.get(Case.SObjectType)[i * 4 + 2];
            Case case4 = (Case) result.get(Case.SObjectType)[i * 4 + 3];

            System.Assert.areEqual(acc, contact1.Account);
            System.Assert.areEqual(acc, contact2.Account);
            System.Assert.areEqual(acc, case1.Account);
            System.Assert.areEqual(acc, case2.Account);
            System.Assert.areEqual(acc, case3.Account);
            System.Assert.areEqual(acc, case4.Account);
            System.Assert.areEqual(contact1, case1.Contact);
            System.Assert.areEqual(contact1, case2.Contact);
            System.Assert.areEqual(contact2, case3.Contact);
            System.Assert.areEqual(contact2, case4.Contact);
        }
    }

    @IsTest
    static void test_ManyToOne_Size() {
        ATK.SaveResult result = ATK.prepare(Contact.SObjectType, 20).withParents(Account.SObjectType, Contact.AccountId, 10).save(false);

        for (Integer i = 0; i < 10; i++) {
            Account acc = (Account) result.get(Account.SObjectType)[i];
            Contact contact1 = (Contact) result.get(Contact.SObjectType)[i * 2];
            Contact contact2 = (Contact) result.get(Contact.SObjectType)[i * 2 + 1];

            System.Assert.areEqual(acc, contact1.Account);
            System.Assert.areEqual(acc, contact2.Account);
        }
    }

    @IsTest
    static void test_ManyToOne_Size_Zero() {
        ATK.SaveResult result = ATK.prepare(Contact.SObjectType, new List<Contact>()).withParents(Account.SObjectType, Contact.AccountId, new List<Account>()).save(false);

        List<Account> accounts = result.get(Account.SObjectType);
        List<Contact> contacts = result.get(Contact.SObjectType);

        System.Assert.areEqual(0, accounts.size());
        System.Assert.areEqual(0, contacts.size());
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

        ATK.SaveResult result = ATK.prepare(Contact.SObjectType, contacts).withParents(Account.SObjectType, Contact.AccountId, accounts).save(false);

        for (Integer i = 0; i < 10; i++) {
            Account acc = (Account) result.get(Account.SObjectType)[i];
            Contact contact1 = (Contact) result.get(Contact.SObjectType)[i * 2];
            Contact contact2 = (Contact) result.get(Contact.SObjectType)[i * 2 + 1];

            System.Assert.areEqual(acc, contact1.Account);
            System.Assert.areEqual(acc, contact2.Account);
        }
    }

    @IsTest
    static void test_ManyToOne_List_Empty() {
        ATK.SaveResult result = ATK.prepare(Contact.SObjectType, new List<Contact>()).withParents(Account.SObjectType, Contact.AccountId, new List<Account>()).save(false);

        List<Account> accounts = result.get(Account.SObjectType);
        List<Contact> contacts = result.get(Contact.SObjectType);

        System.Assert.areEqual(0, accounts.size());
        System.Assert.areEqual(0, contacts.size());
    }
    // #endregion
    // *******************

    // ************
    // #region Mock
    // ************
    @IsTest
    static void test_Mock_OneToMany() {
        //   User(10)
        //     |
        // Account(10) --|------------------|--> Case(40)
        //               |--> Contact(20) --|
        // prettier-ignore
        ATK.SaveResult result = ATK.prepare(Account.SObjectType, 10)
            .withChildren(Case.SObjectType, Case.AccountId, 40)
            .also()
            .withChildren(Contact.SObjectType, Contact.AccountId, 20)
                .withChildren(Case.SObjectType, Case.ContactId)
            .also(2)
            .withParents(User.SObjectType, Account.OwnerId, 10)
            .mock();
        for (Integer i = 0; i < 10; i++) {
            User owner = (User) result.get(User.SObjectType)[i];
            Account acc = (Account) result.get(Account.SObjectType)[i];
            Contact contact1 = (Contact) result.get(Contact.SObjectType)[i * 2];
            Contact contact2 = (Contact) result.get(Contact.SObjectType)[i * 2 + 1];
            Case case1 = (Case) result.get(Case.SObjectType)[i * 4];
            Case case2 = (Case) result.get(Case.SObjectType)[i * 4 + 1];
            Case case3 = (Case) result.get(Case.SObjectType)[i * 4 + 2];
            Case case4 = (Case) result.get(Case.SObjectType)[i * 4 + 3];

            System.Assert.areEqual(2, acc.Contacts.size());
            System.Assert.areEqual(4, acc.Cases.size());

            System.Assert.areNotEqual(null, owner.Id);
            System.Assert.areNotEqual(null, acc.Id);
            System.Assert.areNotEqual(null, contact1.Id);
            System.Assert.areNotEqual(null, contact2.Id);

            System.Assert.areEqual(owner.Id, acc.OwnerId);
            System.Assert.areEqual(contact1.Id, case1.Contact.Id);
            System.Assert.areEqual(contact1.Id, case2.Contact.Id);
            System.Assert.areEqual(contact2.Id, case3.Contact.Id);
            System.Assert.areEqual(contact2.Id, case4.Contact.Id);

            System.Assert.areEqual(owner.Id, acc.Owner.Id);
            System.Assert.areEqual(acc.Id, contact1.AccountId);
            System.Assert.areEqual(acc.Id, contact2.AccountId);
            System.Assert.areEqual(acc.Id, case1.AccountId);
            System.Assert.areEqual(acc.Id, case2.AccountId);
            System.Assert.areEqual(acc.Id, case3.AccountId);
            System.Assert.areEqual(acc.Id, case4.AccountId);
            System.Assert.areEqual(contact1.Id, case1.ContactId);
            System.Assert.areEqual(contact1.Id, case2.ContactId);
            System.Assert.areEqual(contact2.Id, case3.ContactId);
            System.Assert.areEqual(contact2.Id, case4.ContactId);

            System.Assert.areEqual(owner, acc.Owner);
            System.Assert.areEqual(contact1, case1.Contact);
            System.Assert.areEqual(contact1, case2.Contact);
            System.Assert.areEqual(contact2, case3.Contact);
            System.Assert.areEqual(contact2, case4.Contact);
        }
    }

    @IsTest
    static void test_Mock_ManyToOne() {
        //                                       User(40)
        //                                         |
        // Account(10) --|------------------|--> Case(40)
        //               |--> Contact(20) --|
        // prettier-ignore
        ATK.SaveResult result = ATK.prepare(Account.SObjectType, 10)
            .withChildren(Case.SObjectType, Case.AccountId, 40)
                .withParents(User.SObjectType, Case.OwnerId, 40)
                    .field(Account.CreatedDate).repeat(Datetime.newInstance(2020, 1, 1))
                .also()
                .withParents(Contact.SObjectType, Case.ContactId, 20)
                    .withParents(Account.SObjectType, Contact.AccountId)
            .mock();
        for (Integer i = 0; i < 10; i++) {
            Account acc = (Account) result.get(Account.SObjectType)[i];
            Contact contact1 = (Contact) result.get(Contact.SObjectType)[i * 2];
            Contact contact2 = (Contact) result.get(Contact.SObjectType)[i * 2 + 1];
            Case case1 = (Case) result.get(Case.SObjectType)[i * 4];
            Case case2 = (Case) result.get(Case.SObjectType)[i * 4 + 1];
            Case case3 = (Case) result.get(Case.SObjectType)[i * 4 + 2];
            Case case4 = (Case) result.get(Case.SObjectType)[i * 4 + 3];
            User owner1 = (User) result.get(User.SObjectType)[i * 4];
            User owner2 = (User) result.get(User.SObjectType)[i * 4 + 1];
            User owner3 = (User) result.get(User.SObjectType)[i * 4 + 2];
            User owner4 = (User) result.get(User.SObjectType)[i * 4 + 3];

            System.Assert.areEqual(2, acc.Contacts.size());
            System.Assert.areEqual(4, acc.Cases.size());

            System.Assert.areNotEqual(null, owner1.Id);
            System.Assert.areNotEqual(null, owner2.Id);
            System.Assert.areNotEqual(null, owner3.Id);
            System.Assert.areNotEqual(null, owner4.Id);
            System.Assert.areNotEqual(null, acc.Id);
            System.Assert.areNotEqual(null, contact1.Id);
            System.Assert.areNotEqual(null, contact2.Id);

            System.Assert.areEqual(contact1.Id, case1.Contact.Id);
            System.Assert.areEqual(contact1.Id, case2.Contact.Id);
            System.Assert.areEqual(contact2.Id, case3.Contact.Id);
            System.Assert.areEqual(contact2.Id, case4.Contact.Id);
            System.Assert.areEqual(owner1.Id, case1.Owner.Id);
            System.Assert.areEqual(owner2.Id, case2.Owner.Id);
            System.Assert.areEqual(owner3.Id, case3.Owner.Id);
            System.Assert.areEqual(owner4.Id, case4.Owner.Id);

            System.Assert.areEqual(acc.Id, contact1.AccountId);
            System.Assert.areEqual(acc.Id, contact2.AccountId);
            System.Assert.areEqual(acc.Id, case1.AccountId);
            System.Assert.areEqual(acc.Id, case2.AccountId);
            System.Assert.areEqual(acc.Id, case3.AccountId);
            System.Assert.areEqual(acc.Id, case4.AccountId);
            System.Assert.areEqual(contact1.Id, case1.ContactId);
            System.Assert.areEqual(contact1.Id, case2.ContactId);
            System.Assert.areEqual(contact2.Id, case3.ContactId);
            System.Assert.areEqual(contact2.Id, case4.ContactId);
            System.Assert.areEqual(owner1.Id, case1.OwnerId);
            System.Assert.areEqual(owner2.Id, case2.OwnerId);
            System.Assert.areEqual(owner3.Id, case3.OwnerId);
            System.Assert.areEqual(owner4.Id, case4.OwnerId);

            System.Assert.areEqual(contact1, case1.Contact);
            System.Assert.areEqual(contact1, case2.Contact);
            System.Assert.areEqual(contact2, case3.Contact);
            System.Assert.areEqual(contact2, case4.Contact);
            System.Assert.areEqual(owner1, (User) case1.Owner);
            System.Assert.areEqual(owner2, (User) case2.Owner);
            System.Assert.areEqual(owner3, (User) case3.Owner);
            System.Assert.areEqual(owner4, (User) case4.Owner);
        }
    }

    @IsTest
    static void test_Mock_SystemField() {
        Id fakeUserId = ATKCore.FakeId.get(User.SObjectType, 1);
        // prettier-ignore
        ATK.SaveResult result = ATK.prepare(Account.SObjectType, 9)
            .field(Account.CreatedById).repeat(fakeUserId)
            .field(Account.CreatedDate).repeat(Datetime.newInstance(2020, 1, 1))
            .field(Account.LastModifiedById).repeat(fakeUserId)
            .field(Account.LastModifiedDate).addDays(Datetime.newInstance(2020, 1, 1), 1)
            .mock();
        List<SObject> accounts = result.get(Account.SObjectType);
        System.Assert.areEqual(9, accounts.size());
        for (SObject obj : accounts) {
            Account acc = (Account) obj;
            System.Assert.areEqual(fakeUserId, acc.CreatedById);
            System.Assert.areEqual(Datetime.newInstance(2020, 1, 1), acc.CreatedDate);
        }
    }

    @IsTest
    static void test_Mock_PredefinedId() {
        Id accountId0 = ATK.fakeId(Account.SObjectType);
        Id accountId1 = ATK.fakeId(Account.SObjectType);
        Id contactId0 = ATK.fakeId(Contact.SObjectType);
        Id contactId1 = ATK.fakeId(Contact.SObjectType);

        // prettier-ignore
        ATK.SaveResult result = ATK.prepare(Account.SObjectType, 2)
            .field(Account.Id)
            .repeat(accountId0, (String) accountId1)
            .withChildren(Contact.SObjectType, Contact.AccountId, 2)
            .field(Contact.Id)
            .repeat(contactId0, (String) contactId1)
            .mock();
        System.Assert.areEqual(accountId0, result.get(Account.SObjectType)[0].Id);
        System.Assert.areEqual(accountId1, result.get(Account.SObjectType)[1].Id);
        System.Assert.areEqual(contactId0, result.get(Contact.SObjectType)[0].Id);
        System.Assert.areEqual(contactId1, result.get(Contact.SObjectType)[1].Id);
        System.Assert.areEqual(accountId0, ((Contact) result.get(Contact.SObjectType)[0]).AccountId);
        System.Assert.areEqual(accountId1, ((Contact) result.get(Contact.SObjectType)[1]).AccountId);
    }
    // #endregion
    // ************

    @IsTest
    static void test_SaveResult() {
        // prettier-ignore
        ATK.SaveResult result = ATK.prepare(Account.SObjectType, 1)
            .withChildren(Contact.SObjectType, Contact.AccountId, 2)
            .withChildren(Case.SObjectType, Case.ContactId, 3)
            .withParents(Account.SObjectType, Case.AccountId, 4)
            .withChildren(Contact.SObjectType, Contact.AccountId, 5)
            .save(false);
        System.Assert.areEqual(1, result.get(Account.SObjectType).size());
        System.Assert.areEqual(1, result.get(Account.SObjectType, 0).size());
        System.Assert.areEqual(4, result.get(Account.SObjectType, 1).size());
        System.Assert.areEqual(2, result.get(Contact.SObjectType).size());
        System.Assert.areEqual(2, result.get(Contact.SObjectType, 0).size());
        System.Assert.areEqual(5, result.get(Contact.SObjectType, 1).size());
        System.Assert.areEqual(3, result.get(Case.SObjectType).size());

        System.Assert.areEqual(5, result.getAll(Account.SObjectType).size());
        System.Assert.areEqual(7, result.getAll(Contact.SObjectType).size());
        System.Assert.areEqual(3, result.getAll(Case.SObjectType).size());
    }

    @IsTest
    static void test_SaveResult_Also() {
        // prettier-ignore
        ATK.SaveResult result = ATK.prepare(Account.SObjectType, 1)
            .withChildren(Contact.SObjectType, Contact.AccountId, 2)
            .withChildren(Case.SObjectType, Case.ContactId, 3)
            .also()
            .withChildren(Case.SObjectType, Case.ContactId, 4)
            .also(2)
            .withChildren(Contact.SObjectType, Contact.AccountId, 5)
            .save(false);
        System.Assert.areEqual(1, result.getAll(Account.SObjectType).size());
        System.Assert.areEqual(7, result.getAll(Contact.SObjectType).size());
        System.Assert.areEqual(7, result.getAll(Case.SObjectType).size());
    }

    @IsTest
    static void test_Fields() {
        // prettier-ignore
        ATK.prepare(Account.SObjectType, 0)
            .recordType('==Fake Record Type==')
            .build(new AccountEntityBuilder())
            .field(Account.Name).index('Name-{0000}')
            .field(Account.Name).repeat('A')
            .field(Account.Name).repeat('A', 'B')
            .field(Account.Name).repeat('A', 'B', 'C')
            .field(Account.Name).repeat('A', 'B', 'C', 'D')
            .field(Account.Name).repeat('A', 'B', 'C', 'D', 'E')
            .field(Account.Name).repeat(new List<String> { 'A', 'B', 'C' })
            .field(Account.Name).repeatX('A', 2, 'B', 2)
            .field(Account.Name).repeatX('A', 2, 'B', 2, 'C', 2)
            .field(Account.Name).repeatX('A', 2, 'B', 2, 'C', 2, 'D', 2)
            .field(Account.Name).repeatX('A', 2, 'B', 2, 'C', 2, 'D', 2, 'E', 2)
            .field(Account.Name).repeatX(new List<String> { 'A', 'B', 'C' }, new List<Integer> { 2, 2, 2})
            .field(Account.Name).repeatX(null, null)
            .field(Account.Name).add(1, 1)
            .field(Account.Name).substract(1, 1)
            .field(Account.Name).divide(1, 1)
            .field(Account.Name).multiply(1, 1)
            .field(Account.Name).addYears(Date.newInstance(2020, 1, 1), 1)
            .field(Account.Name).addMonths(Date.newInstance(2020, 1, 1), 1)
            .field(Account.Name).addDays(Date.newInstance(2020, 1, 1), 1)
            .field(Account.Name).addHours(Time.newInstance(0, 0, 0, 0), 1)
            .field(Account.Name).addMinutes(Time.newInstance(0, 0, 0, 0), 1)
            .field(Account.Name).addSeconds(Time.newInstance(0, 0, 0, 0), 1)
            .withParents(Contact.SObjectType, Contact.AccountId, 0)
            .junctionOf(Contact.AccountId, Contact.AccountId)
            .also()
            .withParents(Contact.SObjectType, Contact.AccountId, 0)
            .junctionOf(Contact.AccountId, Contact.AccountId, Contact.AccountId)
            .also()
            .withParents(Contact.SObjectType, Contact.AccountId, 0)
            .junctionOf(Contact.AccountId, Contact.AccountId, Contact.AccountId, Contact.AccountId)
            .also()
            .withParents(Contact.SObjectType, Contact.AccountId, 0)
            .junctionOf(Contact.AccountId, Contact.AccountId, Contact.AccountId, Contact.AccountId, Contact.AccountId)
            .also()
            .withParents(Contact.SObjectType, Contact.AccountId, 0)
            .junctionOf(new List<Schema.SObjectField>());
        // prettier-ignore
        ATK.prepare(User.SObjectType, 0)
            .profile('==Fake Profile==')
            .permissionSet('==Fake Permission Set==')
            .permissionSet('==Fake Permission Set 1==', '==Fake Permission Set 2==')
            .permissionSet('==Fake Permission Set 1==', '==Fake Permission Set 2==', '==Fake Permission Set 3==')
            .permissionSet(new List<String>{ '==Fake Permission Set 1==', '==Fake Permission Set 2==' });
    }

    class AccountEntityBuilder implements ATK.EntityBuilder {
        public void build(ATK.Entity accountEneity, Integer size) {
        }
    }

    @IsTest
    static void test_FakeId() {
        System.Assert.areEqual(ATK.fakeId(Account.SObjectType, 1), ATK.fakeId(Account.SObjectType));
        System.Assert.areEqual(ATK.fakeId(Account.SObjectType, 2), ATK.fakeId(Account.SObjectType));
        System.Assert.areEqual(ATK.fakeId(Account.SObjectType, 3), ATK.fakeId(Account.SObjectType));
    }

    @IsTest
    static void test_Save_True() {
        Exception exp;
        try {
            ATK.prepare(Account.SObjectType, 1).save();
        } catch (Exception ex) {
            exp = ex;
        }
    }
}
