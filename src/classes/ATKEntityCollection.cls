public with sharing class ATKEntityCollection implements Iterable<EntityNode> {
    static final ParamEvaluator PARAM_EVALUATOR = new ParamEvaluator();

    @TestVisible
    EntityNodeMatrix matrix { get; set; }

    {
        matrix = new EntityNodeMatrix();
    }

    public Iterator<EntityNode> iterator() {
        this.matrix.reset();
        return matrix;
    }

    public void attach(EntityNode entityNode) {
        this.matrix.add(entityNode);
    }

    public void apply(IAttribute attribute) {
        if (attribute instanceOf IEntityAttribute) {
            ((IEntityAttribute)attribute).apply(this.matrix.currentEntityNode);
        } else if (attribute instanceOf IEvalFieldAttribute) {
            ((IEvalFieldAttribute)attribute).apply(this.matrix.currentEntityNode,
            (EvalEntityField)this.matrix.currentEntityNode.currentEntityField);
        } else if (attribute instanceOf IXrefFieldAttribute) {
            ((IXrefFieldAttribute)attribute).apply(this.matrix.currentEntityNode,
            (XrefEntityField)this.matrix.currentEntityNode.currentEntityField);
        }
    }

    public void pop(Integer depth) {
        this.matrix.pop(depth);
    }

    @TestVisible
    class EntityNodeMatrix implements Iterator<EntityNode> {
        Integer rowIndex { get; set; }
        Integer colIndex { get; set; }
        @TestVisible
        List<List<EntityNode>> entityNodeMatrix { get; set; }
        List<EntityNode> entityNodeStack { get; set; }
        EntityNode currentEntityNode { get; set; }

        EntityNodeMatrix() {
            entityNodeMatrix = new List<List<EntityNode>>();
            entityNodeStack = new List<EntityNode>();
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

        void reset() {
            rowIndex = 0;
            colIndex = -1;
        }

        void pop(Integer depth) {
            while (depth > 0) {
                depth--;
                Integer size = this.entityNodeStack.size();
                if (size > 1) {
                    this.entityNodeStack.remove(size - 1);
                    this.currentEntityNode = this.entityNodeStack[size - 2];
                }
            }
            rowIndex = this.currentEntityNode.rowIndex;
            colIndex = this.currentEntityNode.colIndex;
        }

        void add(EntityNode entityNode) {
            switch on entityNode.nodeType {
                when Prepare {
                    rowIndex = 0;
                    colIndex = 0;
                    entityNodeMatrix.add(new List<EntityNode>());
                    entityNodeMatrix.get(rowIndex).add(entityNode);
                }
                when BelongTo {
                    if (rowIndex > 0) {
                        rowIndex -= 1;
                        entityNodeMatrix.get(rowIndex).add(entityNode);
                        colIndex = entityNodeMatrix.get(rowIndex).size() - 1;
                    } else {
                        rowIndex = 0;
                        colIndex = 0;
                        entityNodeMatrix.add(rowIndex, new List<EntityNode>());
                        entityNodeMatrix.get(rowIndex).add(entityNode);
                    }
                }
                when HaveMany {
                    rowIndex += 1;
                    if (rowIndex == entityNodeMatrix.size()) {
                        colIndex = 0;
                        entityNodeMatrix.add(new List<EntityNode>());
                        entityNodeMatrix.get(rowIndex).add(entityNode);
                    } else {
                        colIndex += 1;
                        entityNodeMatrix.get(rowIndex).add(entityNode);
                    }
                }
            }
            entityNode.rowIndex = rowIndex;
            entityNode.colIndex = colIndex;
            entityNodeStack.add(entityNode);
            entityNode.parentEntityNode = this.currentEntityNode;
            this.currentEntityNode = entityNode;
        }
    }

    /*
    * ENTITY NODE
    */
    public enum EntityNodeType {
        Prepare,
        BelongTo,
        HaveMany,
        Template
    }

    public class EntityNode {
        // Graph Properties
        Integer rowIndex { get; set; }
        Integer colIndex { get; set; }
        EntityNodeType nodeType { get; set; }
        EntityNode parentEntityNode {
            get;
            set {
                parentEntityNode = value;
                switch on nodeType {
                    when BelongTo {
                        parentEntityNode.referenceToMap.put(this.name, this);
                    }
                    when HaveMany {
                        referenceToMap.put(parentEntityNode.name, parentEntityNode);
                    }
                }
            }
        }
        public List<SObject> repository { get; set; }

        // Entity Attributes
        public Schema.SObjectType objectType { get; set; }
        public Schema.DescribeSObjectResult dsr { get; set; }
        public String name { get; set; }
        public Integer total { get; set; }
        public Map<String, EntityNode> referenceToMap { get; set; }

        // Field Attributes
        public Boolean guardEnabled { get; set; }
        public Map<Schema.SObjectField, EvalEntityField> evalFieldMap { get; set; }
        public Map<Schema.SObjectField, XrefEntityField> xrefFieldMap { get; set; }
        public List<EvalEntityField> evalFieldCache { get; set; }
        public List<XrefEntityField> xrefFieldCache { get; set; }
        EntityField currentEntityField { get; set; }

        public EntityNode(Schema.SObjectType objectType, EntityNodeType nodeType) {
            this.objectType = objectType;
            this.dsr = objectType.getDescribe();
            this.name = dsr.getName();
            this.nodeType = nodeType;

            this.referenceToMap = new Map<String, EntityNode>();
            this.repository = new List<SObject>();

            this.guardEnabled = true;
            this.evalFieldMap = new Map<Schema.SObjectField, EvalEntityField>();
            this.xrefFieldMap = new Map<Schema.SObjectField, XrefEntityField>();
            this.evalFieldCache = new List<EvalEntityField>();
            this.xrefFieldCache = new List<XrefEntityField>();
        }
    }

    /*
     * ENTITY FIELD
     */

    public abstract class EntityField  {
        public Schema.SObjectField field { get; set; }
        public Schema.DescribeFieldResult dfr { get; set; }
        public String name { get; set; }
        public Boolean needGuess { get; set; }
        protected ATKCommon.Method method { get; set; }

        {
            needGuess = false;
        }

        EntityField(Schema.SObjectField field) {
            this.field = field;
            this.dfr = this.field.getDescribe();
            this.name = this.dfr.getName();
        }

        public virtual Object getValue(EntityNode entityNode, Integer recordIndex) {
            return null;
        }
    }

    public class EvalEntityField extends EntityField {
        Object value { get; set; }
        String indexFormat { get; set; }
        String fakerRule { get; set; }
        List<Object> repeatValues { get; set; }

        EvalEntityField(Schema.SObjectField field) {
            super(field);
        }

        public EvalEntityField(Schema.SObjectField field, Boolean needGuess) {
            super(field);
            this.needGuess = needGuess;
        }

        public override Object getValue(EntityNode entityNode, Integer recordIndex) {
            if (fakerRule != null) {
                return ATKFaker.fake(fakerRule);
            } else if (indexFormat != null) {
                return String.format(indexFormat, new List<String> { String.valueOf(recordIndex) });
            } else if (repeatValues != null && repeatValues.size() > 0) {
                Integer mod = Math.mod(recordIndex, repeatValues.size());
                return repeatValues[mod];
            } else if (method != null) {
                return method.evaluate(ATKFaker.helpers);
            }
            return this.value;
        }
    }

    public class XrefEntityField extends EntityField implements Comparable {
        public ATKCommon.XrefMethod method { get; set; }
        public EvalEntityField origin { get; set; }

        XrefEntityField(Schema.SObjectField field) {
            super(field);
        }

        public override Object getValue(EntityNode entityNode, Integer recordIndex) {
            if (recordIndex < method.level) {
                return origin.getValue(entityNode, recordIndex);
            }
            PARAM_EVALUATOR.entityNode = entityNode;
            PARAM_EVALUATOR.recordIndex = recordIndex;
            method.loadParams(PARAM_EVALUATOR);
            return method.evaluate(ATKFaker.helpers);
        }

        public Integer compareTo(Object toObj) {
            XrefEntityField field = this;
            XrefEntityField toField = (XrefEntityField)toObj;

            Integer returnValue = 0; // The return value of 0 indicates that both elements are equal.
            if (field.method.level < toField.method.level) {
                returnValue = 1;
            } else if (field.method.level > toField.method.level) {
                returnValue = -1;
            }
            return returnValue;
        }
    }

    class ParamEvaluator implements ATKCommon.IParamEvaluator {
        EntityNode entityNode { get; set; }
        Integer recordIndex { get; set; }

        public Object evaluateParam(String fieldName, Integer level) {
            if (entityNode == null) {
                return null;
            }

            if (level <= recordIndex) {
                SObject record = entityNode.repository[recordIndex - level];
                return record.get(fieldName);
            }
            return null;
        }
    }

    /*
     * ATTRIBUTES
     */

    public interface IAttribute {

    }

    public interface IEntityAttribute extends IAttribute {
        void apply(EntityNode entityNode);
    }

    public interface IFieldAttribute extends IAttribute {

    }

    public interface IEvalFieldAttribute extends IFieldAttribute {
        void apply(EntityNode entityNode, EvalEntityField entityField);
    }

    public interface IXrefFieldAttribute extends IFieldAttribute {
        void apply(EntityNode entityNode, XrefEntityField entityField);
    }

    public class ReferenceByAttribute implements IEntityAttribute {
        String referenceBy { get; set; }
        public ReferenceByAttribute(Schema.SObjectField referenceBy) {
            this.referenceBy = referenceBy.getDescribe().getName();
        }

        public void apply(EntityNode entityNode) {
            switch on entityNode.nodeType {
                when BelongTo {
                    entityNode.parentEntityNode.referenceToMap.remove(entityNode.name);
                    entityNode.parentEntityNode.referenceToMap.put(referenceBy, entityNode);
                }
                when HaveMany {
                    entityNode.referenceToMap.remove(entityNode.parentEntityNode.name);
                    entityNode.referenceToMap.put(referenceBy, entityNode.parentEntityNode);
                }
            }
        }
    }

    public class TotalAttribute implements IEntityAttribute {
        Integer total { get; set; }
        public TotalAttribute(Integer total) {
            this.total = total;
        }

        public void apply(EntityNode entityNode) {
            if (entityNode.repository.size() == 0) {
                entityNode.total = total;
            } else {
                entityNode.total = entityNode.repository.size();
            }
        }
    }

    public class UseListAttribute implements IEntityAttribute {
        List<SObject> repository { get; set; }

        public UseListAttribute(List<SObject> repository) {
            this.repository = repository;
        }

        public void apply(EntityNode entityNode) {
            entityNode.repository.addAll(repository);
            IEntityAttribute totalAttribute = new TotalAttribute(repository.size());
            totalAttribute.apply(entityNode);
        }
    }

    public class GuardAttribute implements IEntityAttribute {
        Boolean guardEnabled { get; set; }

        public GuardAttribute(Boolean guardEnabled) {
            this.guardEnabled = guardEnabled;
        }

        public void apply(EntityNode entityNode) {
            if (this.guardEnabled != null) {
                entityNode.guardEnabled = this.guardEnabled;
            }
        }
    }

    public virtual class EvalAttribute implements IEntityAttribute {
        public Schema.SObjectField field { get; set; }

        public void apply(EntityNode entityNode) {
            EvalEntityField entityField;

            if (entityNode.xrefFieldMap.containsKey(this.field)) {
                XrefEntityField xrefEntityField = entityNode.xrefFieldMap.get(this.field);
                if (xrefEntityField.origin == null) {
                    entityField = new EvalEntityField(this.field);
                    xrefEntityField.origin = entityField;
                } else {
                    entityField = xrefEntityField.origin;
                }
            }

            if (entityField == null) {
                if (entityNode.evalFieldMap.containsKey(this.field)) {
                    entityField = entityNode.evalFieldMap.get(this.field);
                } else {
                    entityField = new EvalEntityField(this.field);
                    entityNode.evalFieldMap.put(this.field, entityField);
                    entityNode.evalFieldCache.add(entityField);
                }
            }

            entityNode.currentEntityField = entityField;
        }
    }

    public class XrefAttribute implements IEntityAttribute  {
        public Schema.SObjectField field { get; set; }

        public void apply(EntityNode entityNode) {
            XrefEntityField entityField;
            if (entityNode.xrefFieldMap.containsKey(this.field)) {
                entityField = entityNode.xrefFieldMap.get(this.field);
            } else {
                entityField = new XrefEntityField(this.field);
                entityNode.xrefFieldMap.put(this.field, entityField);
                entityNode.xrefFieldCache.add(entityField);
            }

            if (entityNode.evalFieldMap.containsKey(this.field)) {
                EvalEntityField evalEntityField = entityNode.evalFieldMap.get(this.field);
                entityNode.evalFieldMap.remove(this.field);
                entityNode.evalFieldCache.remove(entityNode.evalFieldCache.indexOf(evalEntityField));
                entityField.origin = evalEntityField;
            }

            entityNode.currentEntityField = entityField;
        }
    }

    public class EvalGuessAttribute implements IEvalFieldAttribute {
        public void apply(EntityNode entityNode, EvalEntityField entityField) {
            entityField.needGuess = true;
        }
    }

    public class EvalValueAttribute implements IEvalFieldAttribute {
        Object value { get; set; }

        public EvalValueAttribute(Object value) {
            this.value = value;
        }

        public void apply(EntityNode entityNode, EvalEntityField entityField) {
            entityField.value = this.value;
        }
    }

    public class EvalIndexAttribute implements IEvalFieldAttribute {
        String format { get; set; }

        public EvalIndexAttribute(String format) {
            this.format = format;
        }

        public void apply(EntityNode entityNode, EvalEntityField entityField) {
            entityField.indexFormat = this.format;
        }
    }

    public class EvalRepeatAttribute implements IEvalFieldAttribute {
        List<Object> values { get; set; }

        public EvalRepeatAttribute(List<Object> values) {
            this.values = values;
        }

        public void apply(EntityNode entityNode, EvalEntityField entityField) {
            entityField.repeatValues = this.values;
        }
    }

    public class EvalFakerAttribute implements IEvalFieldAttribute {
        String rule { get; set; }

        public EvalFakerAttribute(String rule) {
            this.rule = rule;
        }

        public void apply(EntityNode entityNode, EvalEntityField entityField) {
            entityField.fakerRule = this.rule;
        }
    }

    public class EvalMethodAttribute implements IEvalFieldAttribute {
        String helperName { get; set; }
        String methodName { get; set; }
        public List<Object> params { get; set; }

        public  EvalMethodAttribute(String helperName, String methodName) {
            this.helperName = helperName;
            this.methodName = methodName;
        }

        public void apply(EntityNode entityNode, EvalEntityField entityField) {
            ATKCommon.Method method = new ATKCommon.Method();
            method.helperName = this.helperName;
            method.name = this.methodName;
            method.params = this.params;
            entityField.method = method;
        }
    }

    public class XrefMethodAttribute implements IXrefFieldAttribute {
        public String helperName { get; set; }
        public String methodName { get; set; }
        public List<Object> params { get; set; }

        public  XrefMethodAttribute() {

        }

        public  XrefMethodAttribute(String helperName, String methodName) {
            this.helperName = helperName;
            this.methodName = methodName;
        }

        public void apply(EntityNode entityNode, XrefEntityField entityField) {
            List<ATKCommon.XrefParam> xrefParams = new List<ATKCommon.XrefParam>();
            List<Object> newParams = new List<Object>();
            for (Integer i = 0; i < this.params.size(); i++) {
                Object param = this.params[i];
                if (param instanceOf String) {
                    String input = (String)param;
                    if (input.startsWith('$')) {
                        String fieldName = input.substring(3).toUpperCase();
                        Integer level = ATKCommon.converter.toInteger(input.substring(1, 2));
                        ATKCommon.XrefParam xrefParam = new ATKCommon.XrefParam(fieldName, i, level);

                        xrefParams.add(xrefParam);
                        newParams.add(null);
                    } else {
                        newParams.add(param);
                    }
                } else {
                    newParams.add(param);
                }
            }

            ATKCommon.XrefMethod method = new ATKCommon.XrefMethod(xrefParams);
            method.helperName = this.helperName;
            method.name = this.methodName;
            method.params = newParams;
            entityField.method = method;
        }
    }
}
