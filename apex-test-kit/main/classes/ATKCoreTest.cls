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
public with sharing class ATKCoreTest {
    // **********************
    // #region Generator Save
    // **********************
    @IsTest
    static void test_Generator_Save_AssignFields() {
        ATKCore.SaveGenerator generator = new ATKCore.SaveGenerator();
        {
            ATKCore.EntityNode entity = new ATKCore.EntityNode(Account.SObjectType, 10);
            entity.objects.add(new Account());
            entity.addField(Account.Name);
            entity.currEntityField.fixedValue = 'Name';
            generator.assignFields(entity);
        }

        {
            ATKCore.EntityNode entity = new ATKCore.EntityNode(Account.SObjectType, 10);
            entity.objects.add(new Account());
            entity.addField(Account.Name);
            entity.currEntityField.Type = Schema.DisplayType.DOUBLE;
            entity.currEntityField.arithmetic = ATKCore.EntityFieldArithmetic.ADD;
            entity.currEntityField.initValue = 0.1;
            entity.currEntityField.stepValue = 0.1;
            try {
                generator.assignFields(entity);
            } catch (Exception ex) {
            }
        }

        {
            ATKCore.EntityNode entity = new ATKCore.EntityNode(Account.SObjectType, 10);
            entity.objects.add(new Account());
            entity.addField(Account.Name);
            entity.currEntityField.Type = Schema.DisplayType.INTEGER;
            entity.currEntityField.arithmetic = ATKCore.EntityFieldArithmetic.ADD;
            entity.currEntityField.initValue = 1;
            entity.currEntityField.stepValue = 1;
            try {
                generator.assignFields(entity);
            } catch (Exception ex) {
            }
        }

        {
            ATKCore.EntityNode entity = new ATKCore.EntityNode(Account.SObjectType, 10);
            entity.objects.add(new Account());
            entity.addField(Account.Name);
            entity.currEntityField.Type = Schema.DisplayType.DATE;
            entity.currEntityField.arithmetic = ATKCore.EntityFieldArithmetic.ADD_DAYS;
            entity.currEntityField.initValue = Date.newInstance(2020, 1, 1);
            entity.currEntityField.stepValue = 1;
            try {
                generator.assignFields(entity);
            } catch (Exception ex) {
            }
        }

        {
            ATKCore.EntityNode entity = new ATKCore.EntityNode(Account.SObjectType, 10);
            entity.objects.add(new Account());
            entity.addField(Account.Name);
            entity.currEntityField.Type = Schema.DisplayType.TIME;
            entity.currEntityField.arithmetic = ATKCore.EntityFieldArithmetic.ADD_SECONDS;
            entity.currEntityField.initValue = Time.newInstance(0, 0, 0, 0);
            entity.currEntityField.stepValue = 1;
            try {
                generator.assignFields(entity);
            } catch (Exception ex) {
            }
        }

        {
            ATKCore.EntityNode entity = new ATKCore.EntityNode(Account.SObjectType, 10);
            entity.objects.add(new Account());
            entity.addField(Account.Name);
            entity.currEntityField.Type = Schema.DisplayType.DATETIME;
            entity.currEntityField.arithmetic = ATKCore.EntityFieldArithmetic.ADD_DAYS;
            entity.currEntityField.initValue = DateTime.newInstance(2020, 1, 1, 0, 0, 0);
            entity.currEntityField.stepValue = 1;
            try {
                generator.assignFields(entity);
            } catch (Exception ex) {
            }
        }
    }

    @IsTest
    static void test_Generator_Save_AssignReference() {
        ATKCore.SaveGenerator generator = new ATKCore.SaveGenerator();
        {
            ATKCore.EntityNodeMatrix matrix = new ATKCore.EntityNodeMatrix();
            matrix.add(ATKCore.EntityNodeType.PREPARE, new ATKCore.EntityNode(Account.SObjectType, new List<Account>{ new Account(), new Account(), new Account() }), null);
            matrix.add(ATKCore.EntityNodeType.ONE_TO_MANY, new ATKCore.EntityNode(Contact.SObjectType, new List<Contact>{ new Contact(), new Contact(), new Contact() }), Contact.AccountId);
            generator.assignReferences(matrix.currEntityNode);
        }

        {
            ATKCore.EntityNodeMatrix matrix = new ATKCore.EntityNodeMatrix();
            matrix.add(ATKCore.EntityNodeType.PREPARE, new ATKCore.EntityNode(Account.SObjectType, new List<Account>()), null);
            matrix.add(ATKCore.EntityNodeType.ONE_TO_MANY, new ATKCore.EntityNode(Contact.SObjectType, new List<Contact>{ new Contact(), new Contact(), new Contact() }), Contact.AccountId);
            generator.assignReferences(matrix.currEntityNode);
        }
    }

    @IsTest
    static void test_Generator_Save_Generate() {
        ATKCore.SaveGenerator generator = new ATKCore.SaveGenerator();
        {
            ATKCore.EntityNodeMatrix matrix = new ATKCore.EntityNodeMatrix();
            matrix.add(ATKCore.EntityNodeType.PREPARE, new ATKCore.EntityNode(Account.SObjectType, new List<Account>{ new Account(), new Account(), new Account() }), null);
            matrix.add(ATKCore.EntityNodeType.ONE_TO_MANY, new ATKCore.EntityNode(Contact.SObjectType, 3), Contact.AccountId);
            generator.generate(matrix, false);
        }
    }

    @IsTest
    static void test_Generator_Save_doInsert() {
        ATKCore.SaveGenerator generator = new ATKCore.SaveGenerator();
        {
            ATKCore.EntityNodeMatrix matrix = new ATKCore.EntityNodeMatrix();
            matrix.add(ATKCore.EntityNodeType.PREPARE, new ATKCore.EntityNode(Account.SObjectType, new List<Account>{ new Account(), new Account(), new Account() }), null);
            matrix.add(ATKCore.EntityNodeType.ONE_TO_MANY, new ATKCore.EntityNode(Contact.SObjectType, 3), Contact.AccountId);
            try {
                generator.generate(matrix, true);
            } catch (Exception ex) {
            }
        }
    }

    // #endregion
    // **********************

    // **********************
    // #region Generator Mock
    // **********************
    @IsTest
    static void test_Generator_Mock_AssignReference() {
        ATKCore.MockGenerator generator = new ATKCore.MockGenerator();
        {
            ATKCore.EntityNodeMatrix matrix = new ATKCore.EntityNodeMatrix();
            matrix.add(ATKCore.EntityNodeType.PREPARE, new ATKCore.EntityNode(Account.SObjectType, new List<Account>{ new Account(), new Account(), new Account() }), null);
            matrix.add(ATKCore.EntityNodeType.ONE_TO_MANY, new ATKCore.EntityNode(Contact.SObjectType, new List<Contact>{ new Contact(), new Contact(), new Contact() }), Contact.AccountId);
            generator.assignReferencesForMock(matrix, matrix.currEntityNode);
        }

        {
            ATKCore.EntityNodeMatrix matrix = new ATKCore.EntityNodeMatrix();
            matrix.add(ATKCore.EntityNodeType.PREPARE, new ATKCore.EntityNode(Account.SObjectType, new List<Account>()), null);
            matrix.add(ATKCore.EntityNodeType.ONE_TO_MANY, new ATKCore.EntityNode(Contact.SObjectType, new List<Contact>{ new Contact(), new Contact(), new Contact() }), Contact.AccountId);
            generator.assignReferencesForMock(matrix, matrix.currEntityNode);
        }
    }

    @IsTest
    static void test_Generator_Mock_AssignFields() {
        ATKCore.MockGenerator generator = new ATKCore.MockGenerator();
        {
            ATKCore.EntityNode entity = new ATKCore.EntityNode(Account.SObjectType, 10);
            generator.createMockObjects(entity);

            assignReadonlyField(entity, Account.Name);
            entity.currEntityField.fixedValue = 'Name';
            generator.assignFieldsForMock(entity);
        }

        {
            ATKCore.EntityNode entity = new ATKCore.EntityNode(Account.SObjectType, 10);
            generator.createMockObjects(entity);

            assignReadonlyField(entity, Account.Name);
            entity.currEntityField.type = Schema.DisplayType.DOUBLE;
            entity.currEntityField.arithmetic = ATKCore.EntityFieldArithmetic.ADD;
            entity.currEntityField.initValue = 0.1;
            entity.currEntityField.stepValue = 0.1;
            try {
                generator.assignFieldsForMock(entity);
            } catch (Exception ex) {
            }
        }

        {
            ATKCore.EntityNode entity = new ATKCore.EntityNode(Account.SObjectType, 10);
            generator.createMockObjects(entity);

            assignReadonlyField(entity, Account.Name);
            entity.currEntityField.type = Schema.DisplayType.DATE;
            entity.currEntityField.arithmetic = ATKCore.EntityFieldArithmetic.ADD_DAYS;
            entity.currEntityField.initValue = Date.newInstance(2020, 1, 1);
            entity.currEntityField.stepValue = 1;
            try {
                generator.assignFieldsForMock(entity);
            } catch (Exception ex) {
            }
        }

        {
            ATKCore.EntityNode entity = new ATKCore.EntityNode(Account.SObjectType, 10);
            generator.createMockObjects(entity);

            assignReadonlyField(entity, Account.Name);
            entity.currEntityField.type = Schema.DisplayType.TIME;
            entity.currEntityField.arithmetic = ATKCore.EntityFieldArithmetic.ADD_SECONDS;
            entity.currEntityField.initValue = Time.newInstance(0, 0, 0, 0);
            entity.currEntityField.stepValue = 1;
            try {
                generator.assignFieldsForMock(entity);
            } catch (Exception ex) {
            }
        }

        {
            ATKCore.EntityNode entity = new ATKCore.EntityNode(Account.SObjectType, 10);
            generator.createMockObjects(entity);

            assignReadonlyField(entity, Account.Name);
            entity.currEntityField.type = Schema.DisplayType.DATETIME;
            entity.currEntityField.arithmetic = ATKCore.EntityFieldArithmetic.ADD_DAYS;
            entity.currEntityField.initValue = DateTime.newInstance(2020, 1, 1, 0, 0, 0);
            entity.currEntityField.stepValue = 1;
            try {
                generator.assignFieldsForMock(entity);
            } catch (Exception ex) {
            }
        }
    }

    static void assignReadonlyField(ATKCore.EntityNode entity, Schema.SObjectField field) {
        ATKCore.EntityField entityField = new ATKCore.EntityField(field);
        entity.fieldMap.put(field, entityField);
        entity.readonlyFields.add(entityField);
        entity.currEntityField = entityField;
    }

    @IsTest
    static void test_Generator_Mock_Empty() {
        ATKCore.EntityNodeMatrix matrix = new ATKCore.EntityNodeMatrix();
        matrix.add(ATKCore.EntityNodeType.PREPARE, new ATKCore.EntityNode(Account.SObjectType, new List<Account>{ new Account(), new Account(), new Account() }), null);
        matrix.add(ATKCore.EntityNodeType.ONE_TO_MANY, new ATKCore.EntityNode(Contact.SObjectType, 3), Contact.AccountId);

        ATKCore.MockGenerator generator = new ATKCore.MockGenerator();
        generator.generate(matrix, false);

        System.Assert.areEqual(2, matrix.entityNodeCache.size());
        for (ATKCore.EntityNode node : matrix.entityNodeCache) {
            System.Assert.areEqual(3, node.objects.size());
            for (SObject obj : node.objects) {
                System.Assert.areNotEqual(null, obj.Id);
            }
        }
    }

    @IsTest
    static void test_Generator_Mock_SystemField() {
        Id fakeUserId = ATKCore.FakeId.get(User.SObjectType, 1);

        ATKCore.EntityNodeMatrix matrix = new ATKCore.EntityNodeMatrix();
        matrix.add(ATKCore.EntityNodeType.PREPARE, new ATKCore.EntityNode(Account.SObjectType, 3), null);
        matrix.currEntityNode.addField(Account.CreatedDate);
        matrix.currEntityNode.currEntityField.fixedValue = Datetime.newInstance(2020, 1, 1);
        matrix.currEntityNode.addField(Account.CreatedById);
        matrix.currEntityNode.currEntityField.fixedValue = fakeUserId;
        matrix.add(ATKCore.EntityNodeType.ONE_TO_MANY, new ATKCore.EntityNode(Contact.SObjectType, 3), Contact.AccountId);
        matrix.currEntityNode.addField(Contact.CreatedDate);
        matrix.currEntityNode.currEntityField.fixedValue = Datetime.newInstance(2020, 1, 1);
        matrix.currEntityNode.addField(Contact.CreatedById);
        matrix.currEntityNode.currEntityField.fixedValue = fakeUserId;

        ATKCore.MockGenerator generator = new ATKCore.MockGenerator();
        generator.generate(matrix, false);
        System.Assert.areEqual(2, matrix.entityNodeCache.size());

        Datetime expectedDatetime = Datetime.newInstance(2020, 1, 1);
        for (ATKCore.EntityNode node : matrix.entityNodeCache) {
            System.Assert.areEqual(3, node.objects.size());
            for (SObject obj : node.objects) {
                if (node.objectType == Account.SObjectType) {
                    Account acc = (Account) obj;
                    System.Assert.areEqual(expectedDatetime, acc.CreatedDate);
                    System.Assert.areEqual(fakeUserId, acc.CreatedById);
                    System.Assert.areEqual(1, acc.Contacts.size());
                }
                if (node.objectType == Contact.SObjectType) {
                    Contact con = (Contact) obj;
                    System.Assert.areEqual(expectedDatetime, con.CreatedDate);
                    System.Assert.areEqual(fakeUserId, con.CreatedById);
                    // System.Assert.areEqual(con.AccountId, con.Account.Id);
                }
            }
        }
    }

    @IsTest
    static void test_Generator_Mock_Off_Main_Stem() {
        //              |-- Contact(3) --|
        // Account(3) --|----------------|-- Case(3)
        //     |        |-- Contact(3)
        //   User(3)           |
        //                   User(3)
        ATKCore.MockGenerator generator = new ATKCore.MockGenerator();
        ATKCore.EntityNodeMatrix matrix = new ATKCore.EntityNodeMatrix();
        matrix.add(ATKCore.EntityNodeType.PREPARE, new ATKCore.EntityNode(Account.SObjectType, 3), null);
        matrix.add(ATKCore.EntityNodeType.MANY_TO_ONE, new ATKCore.EntityNode(User.SObjectType, 3), Account.OwnerId);
        matrix.pop(1);
        matrix.add(
            ATKCore.EntityNodeType.ONE_TO_MANY,
            new ATKCore.EntityNode(Contact.SObjectType, new List<Contact>{ new Contact(LastName = 'LastName'), new Contact(LastName = 'LastName'), new Contact(LastName = 'LastName') }),
            Contact.AccountId
        );
        matrix.add(ATKCore.EntityNodeType.ONE_TO_MANY, new ATKCore.EntityNode(Case.SObjectType, 3), Case.ContactId);
        matrix.add(ATKCore.EntityNodeType.MANY_TO_ONE, Account.SObjectType, Case.AccountId);
        matrix.add(ATKCore.EntityNodeType.ONE_TO_MANY, new ATKCore.EntityNode(Contact.SObjectType, 3), Contact.AccountId);
        matrix.add(ATKCore.EntityNodeType.MANY_TO_ONE, new ATKCore.EntityNode(User.SObjectType, 3), Contact.OwnerId);
        matrix.currEntityNode.addField(Contact.CreatedDate);
        matrix.currEntityNode.currEntityField.fixedValue = Datetime.newInstance(2020, 1, 1);

        generator.generate(matrix, false);
        System.Assert.areEqual(6, matrix.entityNodeCache.size());

        matrix.reset();
        matrix.next(); // User
        matrix.next(); // User

        ATKCore.EntityNode accountNode = matrix.next();
        System.Assert.areEqual(3, accountNode.objects.size());
        System.Assert.areEqual(Account.SObjectType, accountNode.objectType);
        for (SObject obj : accountNode.objects) {
            Account acc = (Account) obj;
            System.Assert.areEqual(2, acc.Contacts.size());
            System.Assert.areEqual(1, acc.Cases.size());
            System.Assert.areNotEqual(null, acc.OwnerId);
        }

        ATKCore.EntityNode contactNode1 = matrix.next();
        System.Assert.areEqual(3, contactNode1.objects.size());
        System.Assert.areEqual(Contact.SObjectType, contactNode1.objectType);
        for (SObject obj : contactNode1.objects) {
            Contact con = (Contact) obj;
            System.Assert.areEqual(null, con.Account);
            System.Assert.areNotEqual(null, con.OwnerId);
        }

        ATKCore.EntityNode contactNode2 = matrix.next();
        System.Assert.areEqual(3, contactNode2.objects.size());
        System.Assert.areEqual(Contact.SObjectType, contactNode2.objectType);
        for (SObject obj : contactNode2.objects) {
            Contact con = (Contact) obj;
            System.Assert.areEqual(null, con.Account);
            System.Assert.areEqual(null, con.OwnerId);
        }

        ATKCore.EntityNode caseNode = matrix.next();
        System.Assert.areEqual(3, caseNode.objects.size());
        System.Assert.areEqual(Case.SObjectType, caseNode.objectType);
        for (SObject obj : caseNode.objects) {
            if (caseNode.objectType == Contact.SObjectType) {
                Case cas = (Case) obj;
                System.Assert.areEqual(null, cas.Account);
                System.Assert.areNotEqual(null, cas.Contact);
            }
        }
    }
    // #endregion
    // **********************

    // ********************
    // #region Distribution
    // ********************

    @IsTest
    static void test_Distributor() {
        List<Account> leftList = new List<Account>{ new Account(Name = 'i0'), new Account(Name = 'i1'), new Account(Name = 'i2'), new Account(Name = 'i3'), new Account(Name = 'i4') };
        List<Account> rightList = new List<Account>{ new Account(Name = 'j0'), new Account(Name = 'j1') };

        List<List<Object>> pairs = ATKCore.DISTRIBUTOR.distribute(leftList, rightList);
        System.Assert.areEqual(5, pairs.size());
        System.Assert.areEqual('i0j0', String.valueOf(((Account) pairs[0][0]).Name) + String.valueOf(((Account) pairs[0][1]).Name));
        System.Assert.areEqual('i1j0', String.valueOf(((Account) pairs[1][0]).Name) + String.valueOf(((Account) pairs[1][1]).Name));
        System.Assert.areEqual('i2j0', String.valueOf(((Account) pairs[2][0]).Name) + String.valueOf(((Account) pairs[2][1]).Name));
        System.Assert.areEqual('i3j1', String.valueOf(((Account) pairs[3][0]).Name) + String.valueOf(((Account) pairs[3][1]).Name));
        System.Assert.areEqual('i4j1', String.valueOf(((Account) pairs[4][0]).Name) + String.valueOf(((Account) pairs[4][1]).Name));
    }

    // #endregion
    // ********************

    // *************************
    // #region Matrix Definition
    // *************************
    @IsTest
    static void test_Model_EntityNodeMatrix() {
        ATKCore.EntityNodeMatrix matrix = new ATKCore.EntityNodeMatrix();
        matrix.add(ATKCore.EntityNodeType.PREPARE, new ATKCore.EntityNode(Account.SObjectType, new List<Account>{ new Account() }), null);
        matrix.currEntityNode.currEntityField = new ATKCore.EntityField(Account.Name);
        matrix.add(ATKCore.EntityNodeType.ONE_TO_MANY, new ATKCore.EntityNode(Contact.SObjectType, 1), Contact.AccountId);
        matrix.pop(1);
        matrix.add(ATKCore.EntityNodeType.ONE_TO_MANY, new ATKCore.EntityNode(Contact.SObjectType, 1), Contact.AccountId);
        matrix.add(ATKCore.EntityNodeType.ONE_TO_MANY, new ATKCore.EntityNode(Case.SObjectType, 1), Case.ContactId);
        matrix.add(ATKCore.EntityNodeType.MANY_TO_ONE, Account.SObjectType, Case.AccountId);

        //                |-- 2. Contact
        //  1. Account <--|-- 3. Contact <--|
        //                |-----------------|-- 4. Case

        matrix.generateDAG();
        matrix.reset();

        System.Assert.areEqual(Account.SObjectType, matrix.next().objectType);
        System.Assert.areEqual(Contact.SObjectType, matrix.next().objectType);
        System.Assert.areEqual(Case.SObjectType, matrix.next().objectType);
        System.Assert.areEqual(Contact.SObjectType, matrix.next().objectType);

        System.Assert.isFalse(matrix.hasNext());
        System.Assert.areEqual(null, matrix.next());

        matrix.pop(2);
        System.Assert.areEqual(Contact.SObjectType, matrix.currEntityNode.objectType);

        matrix.pop(1);
        System.Assert.areEqual(Account.SObjectType, matrix.currEntityNode.objectType);
    }

    @IsTest
    static void test_Model_EntityNodeMatrix_None_DAG() {
        ATKCore.EntityNodeMatrix matrix = new ATKCore.EntityNodeMatrix();
        matrix.add(ATKCore.EntityNodeType.PREPARE, new ATKCore.EntityNode(Account.SObjectType, 1), null);
        matrix.add(ATKCore.EntityNodeType.ONE_TO_MANY, new ATKCore.EntityNode(Contact.SObjectType, 1), Contact.AccountId);
        matrix.add(ATKCore.EntityNodeType.ONE_TO_MANY, new ATKCore.EntityNode(User.SObjectType, 1), User.ContactId);
        matrix.add(ATKCore.EntityNodeType.ONE_TO_MANY, Account.SObjectType, Account.OwnerId);

        matrix.generateDAG();

        Exception exp;
        try {
            matrix.reset();
        } catch (Exception ex) {
            exp = ex;
        }
        System.Assert.areNotEqual(null, exp);
        System.Assert.isInstanceOfType(exp, ATKCore.NoneDAGException.class);
    }

    @IsTest
    static void test_Model_EntityNodeMatrix_SaveResult() {
        ATKCore.EntityNodeMatrix matrix = new ATKCore.EntityNodeMatrix();
        matrix.add(ATKCore.EntityNodeType.PREPARE, new ATKCore.EntityNode(Account.SObjectType, new List<Account>{ new Account() }), null);

        matrix.generateDAG();

        ATKCore.SaveResult result = new ATKCore.SaveResult(matrix);
        ATKCore.ObjectTypeIterator keys = result.keys();
        System.Assert.areEqual(Account.SObjectType, keys.next());
        System.Assert.areEqual(null, keys.next());

        ATKCore.ObjectListIterator values = result.values();
        System.Assert.areEqual(1, values.next().size());
        System.Assert.areEqual(null, values.next());
    }

    @IsTest
    static void test_Model_EntityNode() {
        ATKCore.EntityNode entity1 = new ATKCore.EntityNode(Account.SObjectType, 1);
        ATKCore.EntityNode entity2 = new ATKCore.EntityNode(Account.SObjectType, new List<Account>{ new Account() });
        entity1.addField(Account.Name);
        System.Assert.areEqual(Account.Name, entity1.currEntityField.field);
        System.Assert.areEqual(1, entity1.fieldMap.keySet().size());
        entity1.addField(Account.Name);
        System.Assert.areEqual(Account.Name, entity1.currEntityField.field);
        System.Assert.areEqual(1, entity1.fieldMap.keySet().size());
    }

    @IsTest
    static void test_Model_EntityNode_AddRelationships() {
        {
            ATKCore.EntityNode entity = new ATKCore.EntityNode(Account.SObjectType, 1);
            entity.addRelationship(new ATKCore.EntityNodeRelationship(Contact.AccountId));
            entity.junctionFields = new List<Schema.SObjectField>{ Contact.AccountId, Case.ContactId, Case.AccountId };
            entity.addRelationship(new ATKCore.EntityNodeRelationship(Case.ContactId));
            entity.addRelationship(new ATKCore.EntityNodeRelationship(Case.AccountId));

            System.Assert.areEqual(Contact.AccountId, entity.relationships[0].parentIdField);
            System.Assert.areEqual(Case.ContactId, entity.relationships[1].parentIdField);
            System.Assert.areEqual(Case.AccountId, entity.relationships[2].parentIdField);
        }

        {
            ATKCore.EntityNode entity = new ATKCore.EntityNode(Account.SObjectType, 1);
            entity.addRelationship(new ATKCore.EntityNodeRelationship(Contact.AccountId));
            entity.junctionFields = new List<Schema.SObjectField>{ Contact.AccountId, Case.ContactId, Case.AccountId };
            entity.addRelationship(new ATKCore.EntityNodeRelationship(Case.AccountId));
            entity.addRelationship(new ATKCore.EntityNodeRelationship(Case.ContactId));

            System.Assert.areEqual(Contact.AccountId, entity.relationships[0].parentIdField);
            System.Assert.areEqual(Case.ContactId, entity.relationships[1].parentIdField);
            System.Assert.areEqual(Case.AccountId, entity.relationships[2].parentIdField);
        }

        {
            ATKCore.EntityNode entity = new ATKCore.EntityNode(Account.SObjectType, 1);
            entity.addRelationship(new ATKCore.EntityNodeRelationship(Case.ContactId));
            entity.junctionFields = new List<Schema.SObjectField>{ Contact.AccountId, Case.ContactId, Case.AccountId };
            entity.addRelationship(new ATKCore.EntityNodeRelationship(Contact.AccountId));
            entity.addRelationship(new ATKCore.EntityNodeRelationship(Case.AccountId));

            System.Assert.areEqual(Contact.AccountId, entity.relationships[0].parentIdField);
            System.Assert.areEqual(Case.ContactId, entity.relationships[1].parentIdField);
            System.Assert.areEqual(Case.AccountId, entity.relationships[2].parentIdField);
        }

        {
            ATKCore.EntityNode entity = new ATKCore.EntityNode(Account.SObjectType, 1);
            entity.addRelationship(new ATKCore.EntityNodeRelationship(Case.ContactId));
            entity.junctionFields = new List<Schema.SObjectField>{ Contact.AccountId, Case.ContactId, Case.AccountId };
            entity.addRelationship(new ATKCore.EntityNodeRelationship(Case.AccountId));
            entity.addRelationship(new ATKCore.EntityNodeRelationship(Contact.AccountId));

            System.Assert.areEqual(Contact.AccountId, entity.relationships[0].parentIdField);
            System.Assert.areEqual(Case.ContactId, entity.relationships[1].parentIdField);
            System.Assert.areEqual(Case.AccountId, entity.relationships[2].parentIdField);
        }

        {
            ATKCore.EntityNode entity = new ATKCore.EntityNode(Account.SObjectType, 1);
            entity.addRelationship(new ATKCore.EntityNodeRelationship(Case.AccountId));
            entity.junctionFields = new List<Schema.SObjectField>{ Contact.AccountId, Case.ContactId, Case.AccountId };
            entity.addRelationship(new ATKCore.EntityNodeRelationship(Contact.AccountId));
            entity.addRelationship(new ATKCore.EntityNodeRelationship(Case.ContactId));

            System.Assert.areEqual(Contact.AccountId, entity.relationships[0].parentIdField);
            System.Assert.areEqual(Case.ContactId, entity.relationships[1].parentIdField);
            System.Assert.areEqual(Case.AccountId, entity.relationships[2].parentIdField);
        }

        {
            ATKCore.EntityNode entity = new ATKCore.EntityNode(Account.SObjectType, 1);
            entity.addRelationship(new ATKCore.EntityNodeRelationship(Case.AccountId));
            entity.junctionFields = new List<Schema.SObjectField>{ Contact.AccountId, Case.ContactId, Case.AccountId };
            entity.addRelationship(new ATKCore.EntityNodeRelationship(Case.ContactId));
            entity.addRelationship(new ATKCore.EntityNodeRelationship(Contact.AccountId));

            System.Assert.areEqual(Contact.AccountId, entity.relationships[0].parentIdField);
            System.Assert.areEqual(Case.ContactId, entity.relationships[1].parentIdField);
            System.Assert.areEqual(Case.AccountId, entity.relationships[2].parentIdField);
        }
    }

    @IsTest
    static void test_Model_EntityNode_AddRelationships2() {
        {
            ATKCore.EntityNode entity = new ATKCore.EntityNode(Account.SObjectType, 1);
            entity.addRelationship(new ATKCore.EntityNodeRelationship(Case.ContactId));
            entity.junctionFields = new List<Schema.SObjectField>{ Contact.AccountId, Case.ContactId, Contact.AccountId, Case.AccountId };
            entity.addRelationship(new ATKCore.EntityNodeRelationship(Case.AccountId));
            entity.addRelationship(new ATKCore.EntityNodeRelationship(Contact.AccountId));
            entity.addRelationship(new ATKCore.EntityNodeRelationship(Contact.AccountId));

            System.Assert.areEqual(Contact.AccountId, entity.relationships[0].parentIdField);
            System.Assert.areEqual(Case.ContactId, entity.relationships[1].parentIdField);
            System.Assert.areEqual(Contact.AccountId, entity.relationships[2].parentIdField);
            System.Assert.areEqual(Case.AccountId, entity.relationships[3].parentIdField);
        }

        {
            ATKCore.EntityNode entity = new ATKCore.EntityNode(Account.SObjectType, 1);
            entity.addRelationship(new ATKCore.EntityNodeRelationship(Case.ContactId));
            entity.junctionFields = new List<Schema.SObjectField>{ Case.ContactId, Case.AccountId };

            Exception exp;
            try {
                entity.addRelationship(new ATKCore.EntityNodeRelationship(Contact.AccountId));
            } catch (Exception ex) {
                exp = ex;
            }
            System.Assert.areNotEqual(null, exp);
            System.Assert.isInstanceOfType(exp, ATKCore.JunctionOfException.class);
        }

        {
            ATKCore.EntityNode entity = new ATKCore.EntityNode(Account.SObjectType, 1);
            entity.addRelationship(new ATKCore.EntityNodeRelationship(Contact.AccountId));

            Exception exp;
            try {
                entity.junctionFields = new List<Schema.SObjectField>{ Case.ContactId, Case.AccountId };
                // entity.addRelationship(new ATKCore.EntityNodeRelationship(Case.ContactId));
            } catch (Exception ex) {
                exp = ex;
            }
            System.Assert.areNotEqual(null, exp);
            System.Assert.isInstanceOfType(exp, ATKCore.JunctionOfException.class);
        }
    }

    @IsTest
    static void test_Model_EntityField() {
        {
            ATKCore.EntityField field = new ATKCore.EntityField(Account.Name);
            field.fixedValue = 'Name';
            System.Assert.areEqual('Name', field.getValue(0));
            System.Assert.areEqual('Name', field.getValue(1));
            System.Assert.areEqual('Name', field.getValue(2));
        }

        {
            ATKCore.EntityField field = new ATKCore.EntityField(Account.Name);
            field.fixedValue = 'Name';
            System.Assert.areEqual('Name', field.getValue(0));
            System.Assert.areEqual('Name', field.getValue(1));
            System.Assert.areEqual('Name', field.getValue(2));
        }

        {
            ATKCore.EntityField field = new ATKCore.EntityField(Account.Name);
            field.indexFormat = 'Name-{000}';
            System.Assert.areEqual('Name-001', field.getValue(0));
            System.Assert.areEqual('Name-002', field.getValue(1));
            System.Assert.areEqual('Name-003', field.getValue(2));
        }

        {
            ATKCore.EntityField field = new ATKCore.EntityField(Account.Name);
            field.repeatValues = new List<Object>{ 'Name1', 'Name2' };
            System.Assert.areEqual('Name1', field.getValue(0));
            System.Assert.areEqual('Name2', field.getValue(1));
            System.Assert.areEqual('Name1', field.getValue(2));
            System.Assert.areEqual('Name2', field.getValue(3));
        }

        {
            ATKCore.EntityField field = new ATKCore.EntityField(Account.Name);
            field.arithmetic = ATKCore.EntityFieldArithmetic.ADD_YEARS;
            field.initValue = 100;
            field.stepValue = 10;
            System.Assert.areEqual(100, field.getValue(100, 10, 0));
            System.Assert.areEqual(100, field.getValue(100, 10, 1));
            System.Assert.areEqual(100, field.getValue(100, 10, 2));
        }

        {
            ATKCore.EntityField field = new ATKCore.EntityField(Account.Name);
            field.arithmetic = ATKCore.EntityFieldArithmetic.ADD;
            field.initValue = 100;
            field.stepValue = 10;
            System.Assert.isTrue(field.isArithmetic);
            System.Assert.areEqual(100, field.getValue(100, 10, 0));
            System.Assert.areEqual(110, field.getValue(100, 10, 1));
            System.Assert.areEqual(120, field.getValue(100, 10, 2));
        }

        {
            ATKCore.EntityField field = new ATKCore.EntityField(Account.Name);
            field.arithmetic = ATKCore.EntityFieldArithmetic.SUBSTRACT;
            field.initValue = 100;
            field.stepValue = 10;
            System.Assert.areEqual(100, field.getValue(100, 10, 0));
            System.Assert.areEqual(90, field.getValue(100, 10, 1));
            System.Assert.areEqual(80, field.getValue(100, 10, 2));
        }

        {
            ATKCore.EntityField field = new ATKCore.EntityField(Account.Name);
            field.arithmetic = ATKCore.EntityFieldArithmetic.DIVIDE;
            field.initValue = 100;
            field.stepValue = 10;
            System.Assert.areEqual(100, field.getValue(100, 10, 0));
            System.Assert.areEqual(10, field.getValue(100, 10, 1));
            System.Assert.areEqual(1, field.getValue(100, 10, 2));
            System.Assert.areEqual(0.1, field.getValue(100, 10, 3));
        }

        {
            ATKCore.EntityField field = new ATKCore.EntityField(Account.Name);
            field.arithmetic = ATKCore.EntityFieldArithmetic.MULTIPLY;
            field.initValue = 100;
            field.stepValue = 10;
            System.Assert.areEqual(100, field.getValue(100, 10, 0));
            System.Assert.areEqual(1000, field.getValue(100, 10, 1));
            System.Assert.areEqual(10000, field.getValue(100, 10, 2));
        }

        {
            ATKCore.EntityField field = new ATKCore.EntityField(Account.Name);
            field.arithmetic = ATKCore.EntityFieldArithmetic.ADD;
            field.initValue = Date.newInstance(2020, 1, 1);
            field.stepValue = 1;
            System.Assert.areEqual(Date.newInstance(2020, 1, 1), field.getValue(Date.newInstance(2020, 1, 1), 1, 0));
            System.Assert.areEqual(Date.newInstance(2020, 1, 1), field.getValue(Date.newInstance(2020, 1, 1), 1, 1));
            System.Assert.areEqual(Date.newInstance(2020, 1, 1), field.getValue(Date.newInstance(2020, 1, 1), 1, 2));
        }

        {
            ATKCore.EntityField field = new ATKCore.EntityField(Account.Name);
            field.arithmetic = ATKCore.EntityFieldArithmetic.ADD_YEARS;
            field.initValue = Date.newInstance(2020, 1, 1);
            field.stepValue = 1;
            System.Assert.areEqual(Date.newInstance(2020, 1, 1), field.getValue(Date.newInstance(2020, 1, 1), 1, 0));
            System.Assert.areEqual(Date.newInstance(2021, 1, 1), field.getValue(Date.newInstance(2020, 1, 1), 1, 1));
            System.Assert.areEqual(Date.newInstance(2022, 1, 1), field.getValue(Date.newInstance(2020, 1, 1), 1, 2));
        }

        {
            ATKCore.EntityField field = new ATKCore.EntityField(Account.Name);
            field.arithmetic = ATKCore.EntityFieldArithmetic.ADD_MONTHS;
            field.initValue = Date.newInstance(2020, 1, 1);
            field.stepValue = 1;
            System.Assert.areEqual(Date.newInstance(2020, 1, 1), field.getValue(Date.newInstance(2020, 1, 1), 1, 0));
            System.Assert.areEqual(Date.newInstance(2020, 2, 1), field.getValue(Date.newInstance(2020, 1, 1), 1, 1));
            System.Assert.areEqual(Date.newInstance(2020, 3, 1), field.getValue(Date.newInstance(2020, 1, 1), 1, 2));
        }

        {
            ATKCore.EntityField field = new ATKCore.EntityField(Account.Name);
            field.arithmetic = ATKCore.EntityFieldArithmetic.ADD_DAYS;
            field.initValue = Date.newInstance(2020, 1, 1);
            field.stepValue = 1;
            System.Assert.areEqual(Date.newInstance(2020, 1, 1), field.getValue(Date.newInstance(2020, 1, 1), 1, 0));
            System.Assert.areEqual(Date.newInstance(2020, 1, 2), field.getValue(Date.newInstance(2020, 1, 1), 1, 1));
            System.Assert.areEqual(Date.newInstance(2020, 1, 3), field.getValue(Date.newInstance(2020, 1, 1), 1, 2));
        }

        {
            ATKCore.EntityField field = new ATKCore.EntityField(Account.Name);
            field.arithmetic = ATKCore.EntityFieldArithmetic.ADD;
            field.initValue = Time.newInstance(0, 0, 0, 0);
            field.stepValue = 1;
            System.Assert.areEqual(Time.newInstance(0, 0, 0, 0), field.getValue(Time.newInstance(0, 0, 0, 0), 1, 0));
            System.Assert.areEqual(Time.newInstance(0, 0, 0, 0), field.getValue(Time.newInstance(0, 0, 0, 0), 1, 1));
            System.Assert.areEqual(Time.newInstance(0, 0, 0, 0), field.getValue(Time.newInstance(0, 0, 0, 0), 1, 2));
        }

        {
            ATKCore.EntityField field = new ATKCore.EntityField(Account.Name);
            field.arithmetic = ATKCore.EntityFieldArithmetic.ADD_HOURS;
            field.initValue = Time.newInstance(0, 0, 0, 0);
            field.stepValue = 1;
            System.Assert.areEqual(Time.newInstance(0, 0, 0, 0), field.getValue(Time.newInstance(0, 0, 0, 0), 1, 0));
            System.Assert.areEqual(Time.newInstance(1, 0, 0, 0), field.getValue(Time.newInstance(0, 0, 0, 0), 1, 1));
            System.Assert.areEqual(Time.newInstance(2, 0, 0, 0), field.getValue(Time.newInstance(0, 0, 0, 0), 1, 2));
        }

        {
            ATKCore.EntityField field = new ATKCore.EntityField(Account.Name);
            field.arithmetic = ATKCore.EntityFieldArithmetic.ADD_MINUTES;
            field.initValue = Time.newInstance(0, 0, 0, 0);
            field.stepValue = 1;
            System.Assert.areEqual(Time.newInstance(0, 0, 0, 0), field.getValue(Time.newInstance(0, 0, 0, 0), 1, 0));
            System.Assert.areEqual(Time.newInstance(0, 1, 0, 0), field.getValue(Time.newInstance(0, 0, 0, 0), 1, 1));
            System.Assert.areEqual(Time.newInstance(0, 2, 0, 0), field.getValue(Time.newInstance(0, 0, 0, 0), 1, 2));
        }

        {
            ATKCore.EntityField field = new ATKCore.EntityField(Account.Name);
            field.arithmetic = ATKCore.EntityFieldArithmetic.ADD_SECONDS;
            field.initValue = Time.newInstance(0, 0, 0, 0);
            field.stepValue = 1;
            System.Assert.areEqual(Time.newInstance(0, 0, 0, 0), field.getValue(Time.newInstance(0, 0, 0, 0), 1, 0));
            System.Assert.areEqual(Time.newInstance(0, 0, 1, 0), field.getValue(Time.newInstance(0, 0, 0, 0), 1, 1));
            System.Assert.areEqual(Time.newInstance(0, 0, 2, 0), field.getValue(Time.newInstance(0, 0, 0, 0), 1, 2));
        }

        {
            ATKCore.EntityField field = new ATKCore.EntityField(Account.Name);
            field.arithmetic = ATKCore.EntityFieldArithmetic.ADD;
            field.initValue = DateTime.newInstance(2020, 1, 1, 0, 0, 0);
            field.stepValue = 1;
            System.Assert.areEqual(DateTime.newInstance(2020, 1, 1, 0, 0, 0), field.getValue(DateTime.newInstance(2020, 1, 1, 0, 0, 0), 1, 0));
            System.Assert.areEqual(DateTime.newInstance(2020, 1, 1, 0, 0, 0), field.getValue(DateTime.newInstance(2020, 1, 1, 0, 0, 0), 1, 1));
            System.Assert.areEqual(DateTime.newInstance(2020, 1, 1, 0, 0, 0), field.getValue(DateTime.newInstance(2020, 1, 1, 0, 0, 0), 1, 2));
        }

        {
            ATKCore.EntityField field = new ATKCore.EntityField(Account.Name);
            field.arithmetic = ATKCore.EntityFieldArithmetic.ADD_YEARS;
            field.initValue = DateTime.newInstance(2020, 1, 1, 0, 0, 0);
            field.stepValue = 1;
            System.Assert.areEqual(DateTime.newInstance(2020, 1, 1, 0, 0, 0), field.getValue(DateTime.newInstance(2020, 1, 1, 0, 0, 0), 1, 0));
            System.Assert.areEqual(DateTime.newInstance(2021, 1, 1, 0, 0, 0), field.getValue(DateTime.newInstance(2020, 1, 1, 0, 0, 0), 1, 1));
            System.Assert.areEqual(DateTime.newInstance(2022, 1, 1, 0, 0, 0), field.getValue(DateTime.newInstance(2020, 1, 1, 0, 0, 0), 1, 2));
        }

        {
            ATKCore.EntityField field = new ATKCore.EntityField(Account.Name);
            field.arithmetic = ATKCore.EntityFieldArithmetic.ADD_MONTHS;
            field.initValue = DateTime.newInstance(2020, 1, 1, 0, 0, 0);
            field.stepValue = 1;
            System.Assert.areEqual(DateTime.newInstance(2020, 1, 1, 0, 0, 0), field.getValue(DateTime.newInstance(2020, 1, 1, 0, 0, 0), 1, 0));
            System.Assert.areEqual(DateTime.newInstance(2020, 2, 1, 0, 0, 0), field.getValue(DateTime.newInstance(2020, 1, 1, 0, 0, 0), 1, 1));
            System.Assert.areEqual(DateTime.newInstance(2020, 3, 1, 0, 0, 0), field.getValue(DateTime.newInstance(2020, 1, 1, 0, 0, 0), 1, 2));
        }

        {
            ATKCore.EntityField field = new ATKCore.EntityField(Account.Name);
            field.arithmetic = ATKCore.EntityFieldArithmetic.ADD_DAYS;
            field.initValue = DateTime.newInstance(2020, 1, 1, 0, 0, 0);
            field.stepValue = 1;
            System.Assert.areEqual(DateTime.newInstance(2020, 1, 1, 0, 0, 0), field.getValue(DateTime.newInstance(2020, 1, 1, 0, 0, 0), 1, 0));
            System.Assert.areEqual(DateTime.newInstance(2020, 1, 2, 0, 0, 0), field.getValue(DateTime.newInstance(2020, 1, 1, 0, 0, 0), 1, 1));
            System.Assert.areEqual(DateTime.newInstance(2020, 1, 3, 0, 0, 0), field.getValue(DateTime.newInstance(2020, 1, 1, 0, 0, 0), 1, 2));
        }

        {
            ATKCore.EntityField field = new ATKCore.EntityField(Account.Name);
            field.arithmetic = ATKCore.EntityFieldArithmetic.ADD_HOURS;
            field.initValue = DateTime.newInstance(2020, 1, 1, 0, 0, 0);
            field.stepValue = 1;
            System.Assert.areEqual(DateTime.newInstance(2020, 1, 1, 0, 0, 0), field.getValue(DateTime.newInstance(2020, 1, 1, 0, 0, 0), 1, 0));
            System.Assert.areEqual(DateTime.newInstance(2020, 1, 1, 1, 0, 0), field.getValue(DateTime.newInstance(2020, 1, 1, 0, 0, 0), 1, 1));
            System.Assert.areEqual(DateTime.newInstance(2020, 1, 1, 2, 0, 0), field.getValue(DateTime.newInstance(2020, 1, 1, 0, 0, 0), 1, 2));
        }

        {
            ATKCore.EntityField field = new ATKCore.EntityField(Account.Name);
            field.arithmetic = ATKCore.EntityFieldArithmetic.ADD_MINUTES;
            field.initValue = DateTime.newInstance(2020, 1, 1, 0, 0, 0);
            field.stepValue = 1;
            System.Assert.areEqual(DateTime.newInstance(2020, 1, 1, 0, 0, 0), field.getValue(DateTime.newInstance(2020, 1, 1, 0, 0, 0), 1, 0));
            System.Assert.areEqual(DateTime.newInstance(2020, 1, 1, 0, 1, 0), field.getValue(DateTime.newInstance(2020, 1, 1, 0, 0, 0), 1, 1));
            System.Assert.areEqual(DateTime.newInstance(2020, 1, 1, 0, 2, 0), field.getValue(DateTime.newInstance(2020, 1, 1, 0, 0, 0), 1, 2));
        }

        {
            ATKCore.EntityField field = new ATKCore.EntityField(Account.Name);
            field.arithmetic = ATKCore.EntityFieldArithmetic.ADD_SECONDS;
            field.initValue = DateTime.newInstance(2020, 1, 1, 0, 0, 0);
            field.stepValue = 1;
            System.Assert.areEqual(DateTime.newInstance(2020, 1, 1, 0, 0, 0), field.getValue(DateTime.newInstance(2020, 1, 1, 0, 0, 0), 1, 0));
            System.Assert.areEqual(DateTime.newInstance(2020, 1, 1, 0, 0, 1), field.getValue(DateTime.newInstance(2020, 1, 1, 0, 0, 0), 1, 1));
            System.Assert.areEqual(DateTime.newInstance(2020, 1, 1, 0, 0, 2), field.getValue(DateTime.newInstance(2020, 1, 1, 0, 0, 0), 1, 2));
        }
    }

    // #endregion
    // *************************

    // ***********************
    // #region Utility Classes
    // ***********************

    @isTest
    static void test_Util_StringBuilder() {
        {
            ATKCore.StringBuilder builder = new ATKCore.StringBuilder();
            for (Integer i = 0; i < 10; i++) {
                if (Math.mod(i, 2) == 0) {
                    builder.append('a');
                } else {
                    builder.append(1);
                }
            }
            String s = builder.toString();
            System.Assert.areEqual(10, s.length());
            System.Assert.areEqual('a1a1a1a1a1', s);
            String ss = builder.toString(',');
            System.Assert.areEqual(19, ss.length());
            System.Assert.areEqual('a,1,a,1,a,1,a,1,a,1', ss);
        }

        {
            ATKCore.StringBuilder builder = new ATKCore.StringBuilder();
            for (Integer i = 0; i < 100; i++) {
                ATKCore.StringBuilder builder2 = new ATKCore.StringBuilder();
                builder2.append(new List<String>{ 'a', 'b' });
                builder.append(builder2);
            }
            String s = builder.toString();
            System.Assert.areEqual(200, s.length());
        }

        {
            ATKCore.StringBuilder builder = new ATKCore.StringBuilder();
            builder.append('abc');
            builder.append('def');
            String first = builder.getIndex(0);
            builder.setIndex(0, first.substring(1));
            builder.addIndex(0, 'A');
            builder.append('.');
            System.Assert.areEqual('Abcdef.', builder.toString());
        }
    }

    @isTest
    static void test_Util_Converter() {
        Datetime now = Datetime.now();

        System.Assert.areEqual(null, ATKCore.Converter.toBoolean(now));
        System.Assert.areEqual(null, ATKCore.Converter.toBoolean(null));
        System.Assert.areEqual(null, ATKCore.Converter.toBoolean(123));
        System.Assert.isTrue(ATKCore.Converter.toBoolean(true));
        System.Assert.isTrue(ATKCore.Converter.toBoolean('true'));
        System.Assert.isTrue(ATKCore.Converter.toBoolean('tRUe'));
        System.Assert.isFalse(ATKCore.Converter.toBoolean('false'));
        System.Assert.isFalse(ATKCore.Converter.toBoolean('fAlSe'));
        System.Assert.isFalse(ATKCore.Converter.toBoolean('abc'));

        System.Assert.areEqual(null, ATKCore.Converter.toInteger(now));
        System.Assert.areEqual(null, ATKCore.Converter.toInteger(null));
        System.Assert.areEqual(null, ATKCore.Converter.toInteger('abc'));
        System.Assert.areEqual(123, ATKCore.Converter.toInteger(123));
        System.Assert.areEqual(123, ATKCore.Converter.toInteger(123.00));
        System.Assert.areEqual(123, ATKCore.Converter.toInteger('123'));
        System.Assert.areEqual(123, ATKCore.Converter.toInteger('123.00'));

        System.Assert.areEqual(null, ATKCore.Converter.toLong(now));
        System.Assert.areEqual(null, ATKCore.Converter.toLong(null));
        System.Assert.areEqual(null, ATKCore.Converter.toLong('abc'));
        System.Assert.areEqual(123, ATKCore.Converter.toLong(123));
        System.Assert.areEqual(123, ATKCore.Converter.toLong(123.00));
        System.Assert.areEqual(123, ATKCore.Converter.toLong('123'));
        System.Assert.areEqual(123, ATKCore.Converter.toLong('123.00'));

        System.Assert.areEqual(null, ATKCore.Converter.toDouble(now));
        System.Assert.areEqual(null, ATKCore.Converter.toDouble(null));
        System.Assert.areEqual(null, ATKCore.Converter.toDouble('abc'));
        System.Assert.areEqual(123, ATKCore.Converter.toDouble(123));
        System.Assert.areEqual(123, ATKCore.Converter.toDouble(123.00));
        System.Assert.areEqual(123.45, ATKCore.Converter.toDouble(123.45));
        System.Assert.areEqual(123, ATKCore.Converter.toDouble('123'));
        System.Assert.areEqual(123, ATKCore.Converter.toDouble('123.00'));
        System.Assert.areEqual(123.45, ATKCore.Converter.toDouble('123.45'));

        System.Assert.areEqual(null, ATKCore.Converter.toDecimal(now));
        System.Assert.areEqual(null, ATKCore.Converter.toDecimal(null));
        System.Assert.areEqual(null, ATKCore.Converter.toDecimal('abc'));
        System.Assert.areEqual(123, ATKCore.Converter.toDecimal(123));
        System.Assert.areEqual(123, ATKCore.Converter.toDecimal(123.00));
        System.Assert.areEqual(123.45, ATKCore.Converter.toDecimal(123.45));
        System.Assert.areEqual(123, ATKCore.Converter.toDecimal('123'));
        System.Assert.areEqual(123, ATKCore.Converter.toDecimal('123.00'));
        System.Assert.areEqual(123.45, ATKCore.Converter.toDecimal('123.45'));

        System.Assert.areEqual(null, ATKCore.Converter.toString(null));
        System.Assert.areEqual('abc', ATKCore.Converter.toString('abc'));
        System.Assert.areEqual('123', ATKCore.Converter.toString(123));
        System.Assert.areEqual('true', ATKCore.Converter.toString(true));
        System.Assert.areEqual('2021-01-16', ATKCore.Converter.toString(Date.newInstance(2021, 1, 16)));
        System.Assert.areEqual('(0, 1, 2)', ATKCore.Converter.toString(new List<Integer>{ 0, 1, 2 }));

        System.Assert.areEqual(null, ATKCore.Converter.toDate(null));
        System.Assert.areEqual(Date.today(), ATKCore.Converter.toDate(Date.today()));
        System.Assert.areEqual(Date.today(), ATKCore.Converter.toDate(now));
        System.Assert.areEqual(Date.newInstance(2018, 8, 28), ATKCore.Converter.toDate('2018-8-28'));
        System.Assert.areEqual(null, ATKCore.Converter.toDate('2018-08-28T14:24:22Z'));
        System.Assert.areEqual(null, ATKCore.Converter.toDate('abc'));

        System.Assert.areEqual(null, ATKCore.Converter.toDatetime(null));
        System.Assert.areEqual(now, ATKCore.Converter.toDatetime(now));
        System.Assert.areEqual(Datetime.valueOfGmt('2018-08-28 14:24:22'), ATKCore.Converter.toDatetime('2018-08-28T14:24:22Z'));
        System.Assert.areEqual(Datetime.valueOfGmt('2018-08-28 14:24:22'), ATKCore.Converter.toDatetime('2018-08-28T22:24:22+08:00'));
        System.Assert.areEqual(null, ATKCore.Converter.toDatetime('abc'));

        System.Assert.areEqual(null, ATKCore.Converter.toTime(null));
        System.Assert.areEqual(Time.newInstance(8, 28, 36, 0), ATKCore.Converter.toTime(Time.newInstance(8, 28, 36, 0)));
        System.Assert.areEqual(Time.newInstance(8, 28, 36, 0), ATKCore.Converter.toTime(Datetime.newInstance(2018, 8, 28, 8, 28, 36)));
        System.Assert.areEqual(null, ATKCore.Converter.toTime('2018-08-28T14:24:22Z'));
        System.Assert.areEqual(null, ATKCore.Converter.toTime('abc'));
    }

    @IsTest
    static void test_Util_PermissionSets() {
        {
            Id permissionSetId = ATKCore.PERMISSION_SETS.getId('==Fake Permission Set==');
            System.Assert.areEqual(null, permissionSetId);
        }

        {
            List<Id> permissionSetIds = ATKCore.PERMISSION_SETS.getIds(new List<String>{ '==Fake Permission Set 1==', '==Fake Permission Set 2==', '==Fake Permission Set 3==' });
            System.Assert.areEqual(0, permissionSetIds.size());
        }
    }

    @IsTest
    static void test_Util_Profiles() {
        {
            Id profileId = ATKCore.PROFILES.getId('==Fake Profile==');
            System.Assert.areEqual(null, profileId);
        }

        try {
            Profile profile = [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator' WITH SECURITY_ENFORCED];
            if (profile != null) {
                Id profileId = ATKCore.PROFILES.getId('System Administrator');
                System.Assert.areEqual(profile.Id, profileId);
            }
        } catch (System.QueryException ex) {
        }
    }

    @IsTest
    static void test_Util_RecordTypes() {
        {
            Id recordTypeId = ATKCore.RECORD_TYPES.getId(Account.SObjectType.getDescribe(), '==Fake Record Type==');
            System.Assert.areEqual(null, recordTypeId);
        }
    }

    @IsTest
    static void test_Util_FakeId() {
        System.Assert.areEqual('00001', ((String) ATKCore.FAKEID.get(Account.SObjectType, 1)).subString(10, 15));
        System.Assert.areEqual('00001', ((String) ATKCore.FAKEID.get(Account.SObjectType, 1)).subString(10, 15));
        System.Assert.areEqual('00002', ((String) ATKCore.FAKEID.get(Account.SObjectType, 2)).subString(10, 15));
        System.Assert.areEqual('00002', ((String) ATKCore.FAKEID.get(Contact.SObjectType, 2)).subString(10, 15));

        System.Assert.areEqual('00001', ((String) ATKCore.FAKEID.get(Account.SObjectType)).subString(10, 15));
        System.Assert.areEqual('00002', ((String) ATKCore.FAKEID.get(Account.SObjectType)).subString(10, 15));
        System.Assert.areEqual('00003', ((String) ATKCore.FAKEID.get(Account.SObjectType)).subString(10, 15));
    }

    // #endregion
    // ***********************

    // ************************
    // #region Graph Definition
    // ************************
    static ATKCore.Digraph makeDigraph() {
        ATKCore.Digraph g = new ATKCore.Digraph(13);
        g.addEdge(0, 5);
        g.addEdge(0, 1);
        g.addEdge(0, 6);
        g.addEdge(2, 0);
        g.addEdge(2, 3);
        g.addEdge(3, 5);
        g.addEdge(5, 4);
        g.addEdge(6, 9);
        g.addEdge(7, 6);
        g.addEdge(8, 7);
        g.addEdge(9, 10);
        g.addEdge(9, 11);
        g.addEdge(9, 12);
        g.addEdge(11, 12);
        return g;
    }

    @IsTest
    static void test_Digraph_DirectedCycle() {
        {
            ATKCore.Digraph g = makeDigraph();
            ATKCore.DirectedCycle dc = new ATKCore.DirectedCycle(g);
            System.Assert.isFalse(dc.hasCycle());
        }

        {
            ATKCore.Digraph g = makeDigraph();
            g.addEdge(4, 3);
            ATKCore.DirectedCycle dc = new ATKCore.DirectedCycle(g);
            System.Assert.isTrue(dc.hasCycle());
        }
    }

    @IsTest
    static void test_Digraph_Topological() {
        ATKCore.Digraph g = makeDigraph();
        ATKCore.Topological top = new ATKCore.Topological(g);
        System.Assert.isTrue(top.isDAG());
    }

    @IsTest
    static void test_Digraph_SymbolDigraph() {
        ATKCore.SymbolDigraph g = new ATKCore.SymbolDigraph(new List<String>{ '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12' });

        g.addEdge('0', '5');
        g.addEdge('0', '1');
        g.addEdge('0', '6');
        g.addEdge('2', '0');
        g.addEdge('2', '3');
        g.addEdge('3', '5');
        g.addEdge('5', '4');
        g.addEdge('6', '9');
        g.addEdge('7', '6');
        g.addEdge('8', '7');
        g.addEdge('9', '10');
        g.addEdge('9', '11');
        g.addEdge('9', '12');
        g.addEdge('11', '12');

        ATKCore.Topological top = new ATKCore.Topological(g.G());

        System.Assert.isTrue(top.isDAG());
        for (Integer v : top.order()) {
            System.Assert.areEqual(String.valueOf(v), g.keyAt(v));
        }
    }

    // #endregion
    // ************************
}
