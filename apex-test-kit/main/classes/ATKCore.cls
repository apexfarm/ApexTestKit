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

public with sharing class ATKCore {
    public static final Profiles PROFILES = new Profiles();
    public static final RecordTypes RECORD_TYPES = new RecordTypes();
    public static final PermissionSets PERMISSION_SETS = new PermissionSets();
    public static final FakeId FAKEID = new FakeId();
    
    public static final Generator GENERATOR = new Generator();
    @TestVisible
    private static final Converter CONVERTER = new Converter();
    @TestVisible
    private static final Distributor DISTRIBUTOR = new Distributor();
    @TestVisible
    private static Integer batchSize = 200;

    // ************************
    // #region SObject Creation
    // ************************

    public class Generator {
        public Map<Schema.SObjectType, Map<Schema.SObjectField, Integer>> indexes { get; set; }

        {
            indexes = new Map<Schema.SObjectType, Map<Schema.SObjectField, Integer>>();
        }

        public void generate(EntityNodeMatrix iterator, Boolean doInsert, Boolean doMock) {
            iterator.reset();
            while (iterator.hasNext()) {
                EntityNode entityNode = iterator.next();
                Boolean needUpsert = true;
                List<SObject> objects = entityNode.objects;
                if (objects.size() == 0) {
                    needUpsert = false;
                    objects.addAll(createObjects(entityNode, doMock));
                }

                if (entityNode.size > 0) {
                    assignWritableFields(entityNode);
                    assignReferences(entityNode);
                }

                // Ids should be assigned after reference assignments, because once Ids are
                // assigned some relationships are no longer updatable.
                if (doMock) {
                    List<Id> ids = FAKEID.generate(entityNode.objectType, objects.size());
                    for (Integer i = 0; i < objects.size(); i++) {
                        if (objects[i].Id == null) {
                            objects[i].Id = ids[i];
                        }
                    }
                }

                if (!doInsert || doMock) {
                    continue;
                }

                if (needUpsert) {
                    // upsert doesn't work on list of generic sObject types
                    List<SObject> updateList = new List<SObject>();
                    List<SObject> insertList = new List<SObject>();
                    for (SObject obj : entityNode.objects) {
                        if (obj.Id == null) {
                            insertList.add(obj);
                        } else {
                            updateList.add(obj);
                        }
                    }
                    if (updateList.size() > 0) {
                        Database.update(updateList);
                    }
                    if (insertList.size() > 0) {
                        Database.insert(insertList);
                    }
                } else {
                    Database.insert(entityNode.objects);
                }
            }
        }

        public List<SObject> createObjects(EntityNode entityNode, Boolean doMock) {
            List<SObject> objects = new List<SObject>();
            if (doMock && entityNode.readonlyFields.size() > 0) {
                objects = buildSObjectListByBatch(entityNode, batchSize);
            } else {
                Schema.SObjectType objectType = entityNode.objectType;
                for (Integer i = 0; i < entityNode.size; ++i) {
                    objects.add(objectType.newSObject());
                }
            }
            return objects;
        }

        private List<SObject> buildSObjectListByBatch(EntityNode entityNode, Integer numberPerBatch) {
            List<SObject> objects = new List<SObject>();
            for (Integer i = 0; i * numberPerBatch < entityNode.size; i++) {
                Integer endIndex = Math.min((i + 1) * numberPerBatch, entityNode.size);
                String objectArrayJSON = buildSObjectArrayJSON(entityNode, i * numberPerBatch, endIndex);
                // System.debug(objectArrayJSON);
                objects.addAll((List<SObject>)JSON.deserialize(objectArrayJSON, List<SObject>.class));
            }
            return objects;
        }

        private String buildSObjectArrayJSON(EntityNode entityNode, Integer startIndex, Integer endIndex) {

            List<Map<String, String>> fieldMaps = assignReadonlyFields(
                entityNode.objectType, entityNode.readonlyFields, startIndex, endIndex);

            StringBuilder builder = new StringBuilder();
            builder.append('[');
            for (Integer i = 0; i < endIndex - startIndex; ++i) {
                if (i > 0) {
                    builder.append(', ');
                }
                builder.append(buildSObjectJson(entityNode.dsr.getName(), fieldMaps[i]));
            }
            builder.append(']');
            return builder.toString();
        }

        private StringBuilder buildSObjectJson(String objectName, Map<String, String> fieldMap) {
            StringBuilder builder = new StringBuilder();
            builder.append('{');
            builder.append('"attributes":{"type":"'+ objectName +'"}');
            for (String key : fieldMap.keySet()) {
                String value = fieldMap.get(key);
                builder.append(String.format(', "{0}": "{1}"', new List<String> { key, value}));
            }
            builder.append('}');
            return builder;
        }

        public List<Map<String, String>> assignReadonlyFields(
            SObjectType objectType, List<EntityField> entityFields, Integer startIndex, Integer endIndex) {

            List<Map<String, String>> fieldMaps = new List<Map<String, String>>();
            for (Integer i = 0; i < endIndex - startIndex; ++i) {
                fieldMaps.add(new Map<String, String>());
            }

            for (EntityField entityField : entityFields) {
                if (entityField.isArithmetic) {
                    switch on entityField.dfr.getType() {
                        when DATE {
                            Date init = Converter.toDate(entityField.initValue);
                            Integer step = Converter.toInteger(entityField.stepVAlue);
                            for (Integer i = 0; i < endIndex - startIndex; ++i) {
                                fieldMaps[i].put(entityField.dfr.getName(), CONVERTER.toString(entityField.getValue(init, step, i + startIndex)));
                            }
                        }
                        when DATETIME {
                            Datetime init = Converter.toDatetime(entityField.initValue);
                            Integer step = Converter.toInteger(entityField.stepVAlue);
                            for (Integer i = 0; i < endIndex - startIndex; ++i) {
                                fieldMaps[i].put(entityField.dfr.getName(), CONVERTER.toString(entityField.getValue(init, step, i + startIndex)));
                            }
                        }
                        when TIME {
                            Time init = Converter.toTime(entityField.initValue);
                            Integer step = Converter.toInteger(entityField.stepVAlue);
                            for (Integer i = 0; i < endIndex - startIndex; ++i) {
                                fieldMaps[i].put(entityField.dfr.getName(), String.valueOf(entityField.getValue(init, step, i + startIndex)));
                            }
                        }
                        when DOUBLE, INTEGER, PERCENT, CURRENCY {
                            Decimal init = Converter.toDecimal(entityField.initValue);
                            Decimal step = Converter.toDecimal(entityField.stepVAlue);
                            for (Integer i = 0; i < endIndex - startIndex; ++i) {
                                fieldMaps[i].put(entityField.dfr.getName(), String.valueOf(entityField.getValue(init, step, i + startIndex)));
                            }
                        }
                    }
                } else {
                    Integer start = reserveIndex(objectType, entityField.field, endIndex - startIndex);
                    for (Integer i = 0; i < endIndex - startIndex; ++i) {
                        Object value = entityField.getValue(i + start);
                        fieldMaps[i].put(entityField.dfr.getName(), CONVERTER.toString(value));
                    }
                }
            }
            return fieldMaps;
        }

        public void assignWritableFields(EntityNode entityNode) {
            List<SObject> objects = entityNode.objects;
            Integer size = objects.size();

            for (EntityField entityField : entityNode.writableFields) {
                if (entityField.isArithmetic) {
                    switch on entityField.dfr.getType() {
                        when DATE {
                            Date init = Converter.toDate(entityField.initValue);
                            Integer step = Converter.toInteger(entityField.stepVAlue);
                            for (Integer i = 0; i < size; ++i) {
                                objects[i].put(entityField.field, entityField.getValue(init, step, i));
                            }
                        }
                        when DATETIME {
                            Datetime init = Converter.toDatetime(entityField.initValue);
                            Integer step = Converter.toInteger(entityField.stepVAlue);
                            for (Integer i = 0; i < size; ++i) {
                                objects[i].put(entityField.field, entityField.getValue(init, step, i));
                            }
                        }
                        when TIME {
                            Time init = Converter.toTime(entityField.initValue);
                            Integer step = Converter.toInteger(entityField.stepVAlue);
                            for (Integer i = 0; i < size; ++i) {
                                objects[i].put(entityField.field, entityField.getValue(init, step, i));
                            }
                        }
                        when DOUBLE, INTEGER, PERCENT, CURRENCY {
                            Decimal init = Converter.toDecimal(entityField.initValue);
                            Decimal step = Converter.toDecimal(entityField.stepVAlue);
                            for (Integer i = 0; i < size; ++i) {
                                objects[i].put(entityField.field, entityField.getValue(init, step, i));
                            }
                        }
                    }
                } else {
                    Integer index = reserveIndex(entityNode.objectType, entityField.field, size);
                    for (Integer i = 0; i < size; ++i) {
                        Object value = entityField.getValue(i + index);
                        objects[i].put(entityField.field, value);
                    }
                }
            }
        }

        public Integer reserveIndex(SObjectType objectType, SObjectField field, Integer size) {
            if(!indexes.containsKey(objectType)) {
                indexes.put(objectType, new Map<Schema.SObjectField, Integer> {
                    field => 0
                });
            } else if (!indexes.get(objectType).containsKey(field)) {
                indexes.get(objectType).put(field, 0);
            }
            Integer index = indexes.get(objectType).get(field);
            indexes.get(objectType).put(field, index + size);
            return index;
        }

        @TestVisible
        void assignReferences(EntityNode entityNode) {
            if (entityNode.referenceToMap != null
                && entityNode.referenceToMap.size() > 0
                && entityNode.objects != null) {

                List<SObject> childObjectList = entityNode.objects;

                for (Schema.SObjectField referenceField : entityNode.referenceFields) {
                    String relationshipName = referenceField.getDescribe().getRelationshipName();
                    List<SObject> parentObjectList = entityNode.referenceToMap.get(referenceField).objects;

                    // Open comment for debug purpose
                    // System.debug(String.format('{0} -> {1}', new List<Object> { entityNode.objectType, relationshipName }));
                    // System.debug(String.format('{0} -> {1}', new List<Object> { childObjectList.size(), parentObjectList.size() }));

                    for (List<SObject> pair : DISTRIBUTOR.distribute(childObjectList, parentObjectList)) {
                        // pair[0] = child
                        // pair[1] = parent
                        pair[0].put(referenceField, pair[1].Id);
                        pair[0].putSObject(relationshipName, pair[1]);
                    }
                }
            }
        }
    }

    public class Distributor {

        public List<List<SObject>> distribute(List<SObject> leftGroup, List<SObject> rightGroup) {
            List<List<SObject>> groups = new List<List<SObject>>();

            Integer l = leftGroup.size();
            Integer r = rightGroup.size();
            Integer s = l / r;
            Integer remainder = Math.mod(l, r);

            /*
             * Balanced Set Distribution
             * { i0, i1, i2, i3, i4 } => { j0, j1 }; then s = 2, reminder = 1
             *                       ↓↓↓
             *                     i0 - j0
             *                     i1 - j0
             *                     i2 - j0
             *                     i3 - j1
             *                     i4 - j1
             */
            for (Integer i = 0, j = 0; i < l; ++i) {
                if (j < remainder) {
                    j = i / (s + 1);
                } else {
                    j = (i - remainder) / s;
                }
                groups.add(new List<SObject>{
                    leftGroup[i], rightGroup[j]
                });
            }
            return groups;
        }
    }

    // #endregion
    // ************************

    // ************************
    // #region Graph Definition
    // ************************
    // Digraph g = new Digraph(6);
    // g.addEdge(0, 5);
    // g.addEdge(5, 4);
    // g.addEdge(4, 3);
    // g.addEdge(3, 0);

    // DirectedCycle dc = new DirectedCycle(g);
    // System.debug(dc.hasCycle());
    // System.debug(dc.cycle);

    public class Digraph {
        public final Integer V { get; private set; }
        public Integer E { get; private set; }
        private List<List<Integer>> adj { get; set; }

        public Digraph(Integer V) {
            this.V = V;
            this.E = 0;
            this.adj = new List<List<Integer>>();
            for (Integer i = 0; i < V; i ++) {
                this.adj.add(new List<Integer>());
            }
        }

        public void addEdge(Integer v, Integer w) {
            // System.debug(new List<Integer>{ v, w });
            adj[v].add(w);
            E++;
        }

        public List<Integer> adj(Integer v) {
            return adj[v];
        }
    }

    public class DirectedCycle {
        List<Boolean> marked { get; set; }
        List<Integer> edgeTo { get; set; }
        List<Boolean> onStack { get; set; }
        List<Integer> cycle { get; set; }

        public DirectedCycle(Digraph G) {
            onStack = new List<Boolean>();
            edgeTo = new List<Integer>(); 
            marked = new List<Boolean>(); 

            for (Integer v = 0; v < G.V; v++) {
                onStack.add(false);
                edgeTo.add(null);
                marked.add(false);
            }

            for (Integer v = 0; v < G.V; v++) {
                if (!marked[v]) dfs(G, v);
            }
        }

        private void dfs(Digraph G, Integer v) {
            onStack[v] = true;
            marked[v] = true;
            for (Integer w : G.adj(v)) {
                if (this.hasCycle()) {
                    return;
                } else if (!marked[w]) {  
                    edgeTo[w] = v; 
                    dfs(G, w);
                } else if (onStack[w]) {
                    cycle = new List<Integer>();
                    for (Integer x = v; x != w; x = edgeTo[x]) {
                        cycle.add(x);
                    }
                    cycle.add(w); 
                    cycle.add(v);
                }
            }
            onStack[v] = false;
        }

        public Boolean hasCycle() {
            return cycle != null; 
        }

        public List<Integer> cycle() {
            return cycle;
        }
    }

    public class DepthFirstOrder {
        private List<Boolean> marked;
        private List<Integer> pre; // Queue
        private List<Integer> post; // Queue
        private List<Integer> reversePost;

        public DepthFirstOrder(Digraph G) {
            pre = new List<Integer>(); 
            post = new List<Integer>(); 
            reversePost = new List<Integer>();
            marked = new List<Boolean>();

            for (Integer v = 0; v < G.V; v++) {
                marked.add(false);
            }
            
            for (Integer v = 0; v < G.V; v++) {
                if (!marked[v]) {
                    dfs(G, v);
                }
            }
        }

        private void dfs(Digraph G, Integer v) {
            pre.add(v);
            marked[v] = true;
            for (Integer w : G.adj(v)) {
                if (!marked[w]) {
                    dfs(G, w);
                }
            }
                    
            post.add(v);
            reversePost.add(v);
        }

        public List<Integer> pre() {  
            return pre;  
        }

        public List<Integer> post() {  
            return post;  
        }

        public List<Integer> reversePost(){  
            return reversePost;  
        }
    }

    public class Topological {
        private List<Integer> order;
        public Topological(Digraph G) {
            DirectedCycle cyclefinder = new DirectedCycle(G); 
            if (!cyclefinder.hasCycle()) {
                DepthFirstOrder dfs = new DepthFirstOrder(G);
                order = dfs.reversePost(); 
            }
        }

        public List<Integer> order(){  
            return order;  
        }

        public Boolean isDAG() {  
            return order == null;  
        }
    }

    public class SymbolDigraph {
        private Map<Object, Integer> st;
        private Digraph G;
     
        public SymbolDigraph(Integer V) {
            st = new Map<Object, Integer>(); 
            G = new Digraph(V);
        }

        public void addEdge(Object a, Object b) {
            G.addEdge(st.get(a), st.get(b)); 
        }

        public void addVertex(Object obj) {
            if (!this.st.containsKey(obj)) {
                this.st.put(obj, st.size());
            }
        }

        public Boolean contains(Object s) { 
            return st.containsKey(s); 
        }

        public Integer index(Object s) { 
            return st.get(s); 
        }

        public Digraph G() { 
            return G; 
        }
    }

    // #endregion
    // ************************

    // ************************
    // #region Matrix Definition
    // ************************
    public class EntityNodeMatrix implements Iterator<EntityNode> {
        public Integer rowIndex { get; set; }
        public Integer colIndex { get; set; }
        List<List<EntityNode>> entityNodeMatrix { get; set; }
        public List<EntityNode> entityNodeCache { get; set; }
        List<EntityNode> entityNodeStack { get; set; }
        public EntityNode currEntityNode { get; set; }

        public EntityNodeMatrix() {
            entityNodeMatrix = new List<List<EntityNode>>();
            entityNodeStack = new List<EntityNode>();
            entityNodeCache = new List<EntityNode>();
            this.reset();
        }

        public void reset() {
            rowIndex = 0;
            colIndex = -1;
        }

        public Boolean hasNext() {
            return rowIndex + 1 < entityNodeMatrix.size()
                || colIndex + 1 < entityNodeMatrix.get(rowIndex).size();
        }

        public EntityNode next() {
            if (hasNext()) {
                colIndex += 1;
                if (colIndex == entityNodeMatrix.get(rowIndex).size()) {
                    rowIndex += 1;
                    colIndex = 0;
                }
                return entityNodeMatrix.get(rowIndex).get(colIndex);
            }
            return null;
        }

        public void pop(Integer depth) {
            while (depth > 0) {
                depth--;
                Integer size = this.entityNodeStack.size();
                if (size > 1) {
                    this.entityNodeStack.remove(size - 1);
                    this.currEntityNode = this.entityNodeStack[size - 2];
                }
            }
            this.reset();
            while (this.hasNext()) {
                EntityNode entityNode = this.next();
                if (entityNode == this.currEntityNode) {
                    break;
                }
            }
        }

        public void add(EntityNodeType nodeType, EntityNode nextEntityNode, Schema.SObjectField referenceField) {
            switch on nodeType {
                when PREPARE {
                    rowIndex = 0;
                    colIndex = 0;
                    entityNodeMatrix.add(new List<EntityNode>());
                    entityNodeMatrix.get(rowIndex).add(nextEntityNode);
                }
                when MANY_TO_ONE {
                    if (rowIndex > 0) {
                        rowIndex -= 1;
                        entityNodeMatrix.get(rowIndex).add(nextEntityNode);
                        colIndex = entityNodeMatrix.get(rowIndex).size() - 1;
                    } else {
                        rowIndex = 0;
                        colIndex = 0;
                        entityNodeMatrix.add(rowIndex, new List<EntityNode>());
                        entityNodeMatrix.get(rowIndex).add(nextEntityNode);
                    }
                }
                when ONE_TO_MANY {
                    rowIndex += 1;
                    if (rowIndex == entityNodeMatrix.size()) {
                        colIndex = 0;
                        entityNodeMatrix.add(new List<EntityNode>());
                        entityNodeMatrix.get(rowIndex).add(nextEntityNode);
                    } else {
                        colIndex = entityNodeMatrix.get(rowIndex).size();
                        entityNodeMatrix.get(rowIndex).add(nextEntityNode);
                    }
                }
            }

            attach(nodeType, nextEntityNode, referenceField);
        }

        public void add(EntityNodeType nodeType, Schema.SObjectType objectType, Schema.SObjectField referenceField) {
            Integer currRowIndex = rowIndex;
            Integer currColIndex = colIndex;
            EntityNode nextEntityNode;
            this.reset();
            while (this.hasNext()) {
                nextEntityNode = this.next();
                if (nextEntityNode.objectType == objectType) {
                    break;
                }
            }

            if (nextEntityNode != null) {
                switch on nodeType {
                    when MANY_TO_ONE {
                        moveParentAboveChild(
                            nextEntityNode, rowIndex, colIndex,
                            currEntityNode, currRowIndex, currColIndex);
                        rowIndex = rowIndex;
                        colIndex = 0;
                    }
                    when ONE_TO_MANY {
                        moveParentAboveChild(
                            currEntityNode, currRowIndex, currColIndex,
                            nextEntityNode, rowIndex, colIndex);
                        rowIndex = rowIndex + 1;
                        colIndex = colIndex;
                    }
                }

                attach(nodeType, nextEntityNode, referenceField);
            }
        }

        public void moveParentAboveChild(
            EntityNode parentNode, Integer parentRow, Integer parentCol,
            EntityNode childNode, Integer childRow, Integer childCol) {

            // Open comment for debug purpose
            // System.debug(String.format('{0}({1}, {2})', new List<Object>{ parentNode.objectType, parentRow, parentCol }));
            // System.debug(String.format('{0}({1}, {2})', new List<Object>{ childNode.objectType, childRow, childCol }));

            if (childRow == parentRow && childCol < parentCol) {
                entityNodeMatrix.get(parentRow).remove(parentCol);
                entityNodeMatrix.add(parentRow, new List<EntityNode> { parentNode });
            }
        }

        void attach(EntityNodeType nodeType, EntityNode nextEntityNode, Schema.SObjectField referenceField) {
            entityNodeStack.add(nextEntityNode);
            entityNodeCache.add(nextEntityNode);

            switch on nodeType {
                when MANY_TO_ONE {
                    currEntityNode.referenceToMap.put(referenceField, nextEntityNode);
                    currEntityNode.referenceFields.add(referenceField);
                }
                when ONE_TO_MANY {
                    nextEntityNode.referenceToMap.put(referenceField, currEntityNode);
                    nextEntityNode.referenceFields.add(referenceField);
                }
            }
            this.currEntityNode = nextEntityNode;
        }
    }

    public enum EntityNodeType {
        PREPARE,
        MANY_TO_ONE,
        ONE_TO_MANY
    }

    public class EntityNode {
        public Schema.SObjectType objectType { get; set; }
        public Schema.DescribeSObjectResult dsr { get; set; }
        public Integer size { get; set; }
        public Map<Schema.SObjectField, EntityNode> referenceToMap { get; set; }
        public List<Schema.SObjectField> referenceFields { get; set; }
        public List<SObject> objects { get; set; }

        public EntityField currEntityField { get; set; }
        public Map<Schema.SObjectField, EntityField> fieldMap { get; set; }
        private List<EntityField> writableFields { get; set; }
        private List<EntityField> readonlyFields { get; set; }

        public EntityNode(Schema.SObjectType objectType) {
            this.objectType = objectType;
            this.dsr = objectType.getDescribe();

            this.referenceToMap = new Map<Schema.SObjectField, EntityNode>();
            this.referenceFields = new List<Schema.SObjectField>();
            this.fieldMap = new Map<Schema.SObjectField, EntityField>();
            this.writableFields = new List<EntityField>();
            this.readonlyFields = new List<EntityField>();
        }

        public EntityNode(Schema.SObjectType objectType, Integer size) {
            this(objectType);
            this.size = size;
            this.objects = new List<SObject>();
        }

        public EntityNode(Schema.SObjectType objectType, List<SObject> objects) {
            this(objectType);
            this.size = objects.size();
            this.objects = objects;
        }

        public void addField(SObjectField field) {
            EntityField entityField;
            if (this.fieldMap.containsKey(field)) {
                entityField = this.fieldMap.get(field);
            } else {
                entityField = new EntityField(field);
                this.fieldMap.put(field, entityField);
                if (!entityField.dfr.isCreateable()) {
                    this.readonlyFields.add(entityField);
                } else {
                    this.writableFields.add(entityField);
                }
            }
            this.currEntityField = entityField;
        }
    }

    public enum EntityFieldArithmetic {
        ADD,
        SUBSTRACT,
        DIVIDE,
        MULTIPLY,

        ADD_YEARS,
        ADD_MONTHS,
        ADD_DAYS,
        ADD_HOURS,
        ADD_MINUTES,
        ADD_SECONDS
    }

    static Pattern methodPattern = Pattern.compile('\\{(0+)\\}');

    public class EntityField  {
        public Schema.SObjectField field { get; set; }
        public Schema.DescribeFieldResult dfr { get; set; }

        // Fixed Value
        public Object fixedValue { get; set; }
        public Integer indexLength { get; set; }
        public String indexFormat { get;
            set {
                indexFormat = value;
                this.indexLength = 0;
                System.Matcher matcher = methodPattern.matcher(value);
                while(matcher.find()) {
                    this.indexLength = matcher.group(1).length();
                }
            }
        }
        public List<Object> repeatValues { get; set; }

        // Arithmetic
        public EntityFieldArithmetic arithmetic { get; set; }
        public Object initValue { get; set; }
        public Object stepValue { get; set; }

        public EntityField(Schema.SObjectField field) {
            this.field = field;
            this.dfr = this.field.getDescribe();
        }

        Boolean isIndexed {
            get {
                return indexFormat != null;
            }
        }

        Boolean isRepeated {
            get {
                return repeatValues != null && repeatValues.size() > 0;
            }
        }

        @TestVisible
        Boolean isArithmetic {
            get {
                return arithmetic != null;
            }
        }

        public Object getValue(Integer rowIndex) {
            if (isIndexed) {
                return String.format(this.indexFormat, new List<Object> {
                    String.valueOf(rowIndex + 1).leftPad(indexLength, '0')
                });
            } else if (isRepeated) {
                return this.repeatValues[Math.mod(rowIndex, this.repeatValues.size())];
            } else {
                return this.fixedValue;
            }
        }

        public Object getValue(Datetime init, Integer step, Integer rowIndex) {
            switch on this.arithmetic {
                when ADD_YEARS {
                    return init.addYears(step * rowIndex);
                }
                when ADD_MONTHS {
                    return init.addMonths(step * rowIndex);
                }
                when ADD_DAYS {
                    return init.addDays(step * rowIndex);
                }
                when ADD_HOURS{
                    return init.addHours(step * rowIndex);
                }
                when ADD_MINUTES{
                    return init.addMinutes(step * rowIndex);
                }
                when ADD_SECONDS {
                    return init.addSeconds(step * rowIndex);
                }
                when else {
                    return init;
                }
            }
        }

        public Object getValue(Date init, Integer step, Integer rowIndex) {
            switch on this.arithmetic {
                when ADD_YEARS {
                    return init.addYears(step * rowIndex);
                }
                when ADD_MONTHS {
                    return init.addMonths(step * rowIndex);
                }
                when ADD_DAYS {
                    return init.addDays(step * rowIndex);
                }
                when else {
                    return init;
                }
            }
        }

        public Object getValue(Time init, Integer step, Integer rowIndex) {
            switch on this.arithmetic {
                when ADD_HOURS{
                    return init.addHours(step * rowIndex);
                }
                when ADD_MINUTES{
                    return init.addMinutes(step * rowIndex);
                }
                when ADD_SECONDS {
                    return init.addSeconds(step * rowIndex);
                }
                when else {
                    return init;
                }
            }
        }

        public Object getValue(Decimal init, Decimal step, Integer rowIndex) {
            switch on this.arithmetic {
                when ADD {
                    return init + step * rowIndex;
                }
                when SUBSTRACT {
                    return init - step * rowIndex;
                }
                when DIVIDE {
                    return init / step.pow(rowIndex);
                }
                when MULTIPLY {
                    return init * step.pow(rowIndex);
                }
                when else {
                    return init;
                }
            }
        }
    }

    // #endregion
    // ************************

    // ***********************
    // #region Utility Classes
    // ***********************
    class Indexer {
        Integer i = 0;
    }

    public class StringBuilder {
        List<String> values { get; set; }

        public StringBuilder() {
            values = new List<String>();
        }

        public void addIndex(Integer index, String value) {
            values.add(index, value);
        }

        public void setIndex(Integer index, String value) {
            values.set(index, value);
        }

        public String getIndex(Integer index) {
            return values.get(index);
        }

        public void append(Decimal value) {
            values.add(CONVERTER.toString(value));
        }

        public void append(String value) {
            values.add(value);
        }

        public void append(List<String> values) {
            this.values.addAll(values);
        }

        public void append(StringBuilder builder) {
            values.addAll(builder.values);
        }

        public override String toString() {
            return String.join(values, '');
        }

        public String toString(String separator) {
            return String.join(values, separator);
        }
    }

    public class Converter {
        @TestVisible
        private Converter() {
        }

        public Boolean toBoolean(Object input) {
            if (input == null) {
                return null;
            } else if (input instanceof Boolean) {
                return (Boolean)input;
            } else {
                try {
                    return Boolean.valueOf(input);
                } catch (Exception e) {
                    return null;
                }
            }
        }

        public Integer toInteger(Object input) {
            if (input == null) {
                return null;
            } else if (input instanceof Integer) {
                return (Integer)input;
            } else {
                try {
                    return Integer.valueOf(input);
                } catch (Exception e) {
                    return null;
                }
            }
        }

        public Long toLong(Object input) {
            if (input == null) {
                return null;
            } else if (input instanceof Long) {
                return (Long)input;
            } else {
                try {
                    return Long.valueOf(toString(input));
                } catch (Exception e) {
                    return null;
                }
            }
        }

        public Double toDouble(Object input) {
            if (input == null) {
                return null;
            } else if (input instanceof Double) {
                return (Double)input;
            } else {
                try {
                    return Double.valueOf(input);
                } catch (Exception e) {
                    return null;
                }
            }
        }

        public Decimal toDecimal(Object input) {
            if (input == null) {
                return null;
            } else if (input instanceof Decimal) {
                return (Decimal)input;
            } else {
                try {
                    String inputString;
                    if (input instanceOf String) {
                        inputString = (String)input;
                    } else {
                        inputString = String.valueOf(input);
                    }
                    return Decimal.valueOf(inputString);
                } catch (Exception e) {
                    return null;
                }
            }
        }

        public String toString(Object input) {
            if (input == null) {
                return null;
            } else if (input instanceof String) {
                return (String)input;
            } else if (input instanceof Date) {
                return ((Datetime)input).format('yyyy-MM-dd');
            } else if (input instanceof Datetime) {
                return ((Datetime)input).formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
            } else {
                return String.valueOf(input);
            }
        }

        public Date toDate(Object input) {
            if (input instanceof Date) {
                return (Date)input;
            } else if (input instanceof Datetime){
                return ((Datetime)input).date();
            } else if (input instanceof String) {
                try {
                    return (Date)JSON.deserialize(
                        String.format('"{0}"', new List<String> { (String)input }),
                        Date.class);
                } catch (Exception e) {
                    return null;
                }
            }
            return null;
        }

        public Datetime toDatetime(Object input) {
            if (input instanceof Datetime) {
                return (Datetime)input;
            } else if (input instanceof String) {
                try {
                    return (Datetime)JSON.deserialize(
                        String.format('"{0}"', new List<String> { (String)input }),
                        Datetime.class);
                } catch (Exception e) {
                    return null;
                }
            }
            return null;
        }

        public Time toTime(Object input) {
            if (input == null) {
                return null;
            } else if (input instanceof Time) {
                return (Time)input;
            } else if (input instanceof Datetime){
                return ((Datetime)input).time();
            }
            return null;
        }
    }

    public class PermissionSets {
        @TestVisible
        Map<String, Id> permissionSetIdByName {
            get {
                if (permissionSetIdByName == null) {
                    permissionSetIdByName = new Map<String, Id>();
                    for (PermissionSet permissionSet : [
                        SELECT Id, Label, Name
                        FROM PermissionSet
                        WHERE ProfileId = null]) {
                        permissionSetIdByName.put(permissionSet.Name.toUpperCase(), permissionSet.Id);
                        permissionSetIdByName.put(permissionSet.Label.toUpperCase(), permissionSet.Id);
                    }
                }
                return permissionSetIdByName;
            }
            set;
        }

        public Id getId(String name) {
            return permissionSetIdByName.get(name.toUpperCase());
        }

        public List<Id> getIds(List<String> names) {
            List<Id> ids = new List<Id>();
            for (String name : names) {
                Id id = this.getId(name);
                if (id != null) {
                    ids.add(id);
                }
            }
            return ids;
        }
    }

    public class Profiles {
        @TestVisible
        Map<String, Id> profileIdByName {
            get {
                if (profileIdByName == null) {
                    profileIdByName = new Map<String, Id>();
                    for (Profile profile : [SELECT Id, Name FROM Profile]) {
                        profileIdByName.put(profile.Name.toUpperCase(), profile.Id);
                    }
                }
                return profileIdByName;
            }
            set;
        }

        public Id getId(String name) {
            return profileIdByName.get(name.toUpperCase());
        }
    }

    public class RecordTypes {
        public Id getId(DescribeSObjectResult dsr, String developerName) {
            RecordTypeInfo recordTypeInfo = dsr.getRecordTypeInfosByDeveloperName().get(developerName);
            if (recordTypeInfo != null) {
                return recordTypeInfo.getRecordTypeId();
            }
            return null;
        }
    }

    public class FakeId {
        Map<Schema.SObjectType, Indexer> objectIdIndexes { get; set; }

        {
            objectIdIndexes = new Map<Schema.SObjectType, Indexer>();
        }

        public String get(Schema.SObjectType objectType, Integer i) {
            return objectType.getDescribe().getKeyPrefix()
                + '000zzzz'
                + String.valueOf(i).leftPad(5, '0');
        }

        public List<String> generate(Schema.SObjectType objectType, Integer size) {
            List<String> ids = new List<String>();
            if (!objectIdIndexes.containsKey(objectType)) {
                objectIdIndexes.put(objectType, new Indexer());
            }

            Indexer idx = objectIdIndexes.get(objectType);
            String prefix = objectType.getDescribe().getKeyPrefix() + '000zzzz';
            for (Integer i = 0; i < size; i++) {
                ids.add(prefix + String.valueOf(++idx.i).leftPad(5, '0'));
            }
            return ids;
        }
    }

    // #endregion
    // ***********************
}
