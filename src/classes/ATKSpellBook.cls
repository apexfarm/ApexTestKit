/**
 * Apex Test Kit
 */
public with sharing class ATKSpellBook implements Iterable<EntityNode> {
    private Map<String, List<EntityNode>> entityNodeMap { get; set; }
    private EntityNodeMatrix matrix { get; private set; }

	{
        entityNodeMap = new Map<String, List<EntityNode>>();
        matrix = new EntityNodeMatrix();
	}

    public Iterator<EntityNode> iterator() {
        this.matrix.reset();
        return matrix;
    }
    
	public void attach(EntityNode entityNode) {
        this.matrix.add(entityNode);
        addToEntityNodeMap(entityNode);
	}

	public void apply(IEntityAttribute attribute) {
		this.matrix.currentEntitNode.apply(attribute);
	}

    public void pop(Integer depth) {
        this.matrix.pop(depth);
    }

    public List<SObject> query(String entityName) {
        entityName = entityName.toUpperCase();
        List<EntityNode> entityNodeList = entityNodeMap.get(entityName);
        List<SObject> repository = new List<SObject>();
        if (entityNodeList != null) {
            for (EntityNode entityNode : entityNodeList) {
                repository.addAll(entityNode.repository);
            }
        }
        return repository;
    }

    private void addToEntityNodeMap(EntityNode entityNode) {
        String entityName = entityNode.name;
        if (entityNodeMap.get(entityName) == null) {
            entityNodeMap.put(entityName, new List<EntityNode>());
        }
        entityNodeMap.get(entityName).add(entityNode);
    }

	
	/*
	 * ENTITY NODE
	 */

	public enum EntityNodeType {
	   WantMany,
	   BelongsTo,
	   HasMany
	}

	public class EntityNode {
        private Integer rowIndex { get; set; }
	    private Integer colIndex { get; set; }
		private EntityNodeType type { get; set; }
		private EntityNode parentEntityNode { get; set; }

		public String name { get; set; }
		public Integer total { get; set; }
		public Map<String, Object> fieldInitMap { get; set; }
		public Map<String, Object> fieldRuleMap { get; set; }
		public Map<String, EntityNode> referenceToMap { get; set; }
		public List<SObject> repository { get; set; }

        // public List<EntityNode> convertAncestorsToList() {
        //     List<EntityNode> ancestorList = new List<EntityNode>();
        //     travelAncestorTree(this, ancestorList);
        //     return ancestorList;
        // }

        // private static void travelAncestorTree(EntityNode entityNode, List<EntityNode> ancestorList) {
        //     for (String key : entityNode.referenceToMap.keySet()) {
        //         EntityNode parentNode = entityNode.referenceToMap.get(key);
        //         parentNode.keyPaths = new List<String>(entityNode.keyPaths);
        //         parentNode.keyPaths.add(key);
        //         ancestorList.add(parentNode);
        //         travelAncestorTree(parentNode, ancestorList);
        //     }
        // }

		public EntityNode(String name, EntityNodeType type) {
			this.name = name.trim().toUpperCase();
			this.type = type;
			fieldRuleMap = new Map<String, Object>();
			fieldInitMap = new Map<String, Object>();
			referenceToMap = new Map<String, EntityNode>();
			repository = new List<SObject>();
		}

		private virtual void apply(IEntityAttribute attribute) {
			attribute.apply(this);
		}
	}

	/*
	 * ENTITY ATTRIBUTE
	 */
	public Interface IEntityAttribute {
		void apply(EntityNode entityNode);
	}

	public Interface IRelatedEntityAttribute extends IEntityAttribute {

	}

	public class TotalAttribute implements IEntityAttribute, IRelatedEntityAttribute {
		private Integer total { get; set; }
		public TotalAttribute(Integer total) {
			this.total = total;
		}

		public void apply(EntityNode entityNode) {            
			entityNode.total = total;
		}
	}

    public class FromListAttribute implements IEntityAttribute, IRelatedEntityAttribute {
		private List<SObject> repository { get; set; }

		public FromListAttribute(List<SObject> repository) {
			this.repository = repository;
		}

		public void apply(EntityNode entityNode) {
			entityNode.repository.addAll(repository);
            IEntityAttribute totalAttribute = new TotalAttribute(repository.size());
            totalAttribute.apply(entityNode);
		}
	}

	public class FieldAttribute implements IEntityAttribute, IRelatedEntityAttribute {
		private Map<String, Object> fieldRuleMap { get; set; }
		private Boolean isInit { get; set; }

		public FieldAttribute(Map<String, Object> fieldRuleMap) {
            this(fieldRuleMap, false);
		}

        public FieldAttribute(Map<String, Object> fieldRuleMap, Boolean isInit) {
            this.fieldRuleMap = new Map<String, Object>();
            this.isInit = isInit;
            for (String key : fieldRuleMap.keySet()) {
               this.fieldRuleMap.put(key.trim().toUpperCase(), fieldRuleMap.get(key));
            }
		}

		public void apply(EntityNode entityNode) {
            if (this.isInit) {
                entityNode.fieldInitMap.putAll(fieldRuleMap);
            } else {
			    entityNode.fieldRuleMap.putAll(fieldRuleMap);
            }
		}
	}

	public class ReferenceByAttribute implements IRelatedEntityAttribute {
		private String referenceBy { get; set; }
		public ReferenceByAttribute(String referenceBy) {
			this.referenceBy = referenceBy.trim().toUpperCase();
		}

		public void apply(EntityNode entityNode) {
			switch on entityNode.type {
			    when BelongsTo {
					entityNode.parentEntityNode.referenceToMap.put(referenceBy, entityNode);
			    }
				when HasMany {
					entityNode.referenceToMap.put(referenceBy, entityNode.parentEntityNode);
				}
			}
		}
	}
    
    private class EntityNodeMatrix implements Iterator<EntityNode> {
        private Integer rowIndex { get; set; }
	    private Integer colIndex { get; set; }
        private List<List<EntityNode>> entityNodeMatrix { get; set; }
        private List<EntityNode> entityNodeStack { get; set; }
	    private EntityNode currentEntitNode { get; set; }

        private EntityNodeMatrix() {
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

        private void reset() {
            rowIndex = 0;
            colIndex = -1;
        }

        private void pop(Integer depth) {
            while (depth > 0) {
                depth--;
                Integer size = this.entityNodeStack.size();
                if (size > 1) {
                    this.entityNodeStack.remove(size - 1);
                    this.currentEntitNode = this.entityNodeStack[size - 2];
                }
            }
            rowIndex = this.currentEntitNode.rowIndex;
            colIndex = this.currentEntitNode.colIndex;
        }

        private void add(EntityNode entityNode) {
            switch on entityNode.type {
                when WantMany {
                    rowIndex = 0;
                    colIndex = 0;
                    entityNodeMatrix.add(new List<EntityNode>());
                    entityNodeMatrix.get(rowIndex).add(entityNode);
                }
                when BelongsTo {
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
                when HasMany {
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
            entityNode.parentEntityNode = this.currentEntitNode;
            this.currentEntitNode = entityNode;
        }
    }
}
