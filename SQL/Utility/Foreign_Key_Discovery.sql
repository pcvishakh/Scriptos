
--List specific table foreign keys
select t.name as TableWithForeignKey, fk.constraint_column_id as FK_PartNo , c.name as ForeignKeyColumn 
from sys.foreign_key_columns as fk
inner join sys.tables as t on fk.parent_object_id = t.object_id
inner join sys.columns as c on fk.parent_object_id = c.object_id and fk.parent_column_id = c.column_id
where fk.referenced_object_id = (select object_id from sys.tables where name = 'tPayerCreditAccount')
order by TableWithForeignKey, FK_PartNo

--List all the foreign keys and their relations

SELECT  obj.name AS FK_NAME,
    sch.name AS [schema_name],
    tab1.name AS [table],
    col1.name AS [column],
    tab2.name AS [referenced_table],
    col2.name AS [referenced_column]
FROM sys.foreign_key_columns fkc
INNER JOIN sys.objects obj
    ON obj.object_id = fkc.constraint_object_id
INNER JOIN sys.tables tab1
    ON tab1.object_id = fkc.parent_object_id
INNER JOIN sys.schemas sch
    ON tab1.schema_id = sch.schema_id
INNER JOIN sys.columns col1
    ON col1.column_id = parent_column_id AND col1.object_id = tab1.object_id
INNER JOIN sys.tables tab2
    ON tab2.object_id = fkc.referenced_object_id
INNER JOIN sys.columns col2
    ON col2.column_id = referenced_column_id AND col2.object_id = tab2.object_id


--List all the foreign keys for all the tables in a database
SELECT
    o1.name AS FK_table,
    c1.name AS FK_column,
    fk.name AS FK_name,
    o2.name AS PK_table,
    c2.name AS PK_column,
    pk.name AS PK_name,
    fk.delete_referential_action_desc AS Delete_Action,
    fk.update_referential_action_desc AS Update_Action
FROM sys.objects o1
    INNER JOIN sys.foreign_keys fk
        ON o1.object_id = fk.parent_object_id
    INNER JOIN sys.foreign_key_columns fkc
        ON fk.object_id = fkc.constraint_object_id
    INNER JOIN sys.columns c1
        ON fkc.parent_object_id = c1.object_id
        AND fkc.parent_column_id = c1.column_id
    INNER JOIN sys.columns c2
        ON fkc.referenced_object_id = c2.object_id
        AND fkc.referenced_column_id = c2.column_id
    INNER JOIN sys.objects o2
        ON fk.referenced_object_id = o2.object_id
    INNER JOIN sys.key_constraints pk
        ON fk.referenced_object_id = pk.parent_object_id
        AND fk.key_index_id = pk.unique_index_id
ORDER BY o1.name, o2.name, fkc.constraint_column_id

--List all the foreign keys
SELECT 
    FK = OBJECT_NAME(pt.constraint_object_id),
    Referencing_table = QUOTENAME(OBJECT_SCHEMA_NAME(pt.parent_object_id))
            + '.' + QUOTENAME(OBJECT_NAME(pt.parent_object_id)),
    Referencing_col = QUOTENAME(pc.name), 
    Referenced_table = QUOTENAME(OBJECT_SCHEMA_NAME(pt.referenced_object_id)) 
            + '.' + QUOTENAME(OBJECT_NAME(pt.referenced_object_id)),
    Referenced_col = QUOTENAME(rc.name)
FROM sys.foreign_key_columns AS pt
INNER JOIN sys.columns AS pc
ON pt.parent_object_id = pc.[object_id]
AND pt.parent_column_id = pc.column_id
INNER JOIN sys.columns AS rc
ON pt.referenced_column_id = rc.column_id
AND pt.referenced_object_id = rc.[object_id]
ORDER BY Referencing_table, FK, pt.constraint_column_id;

--List all foreign keys
SELECT PKTABLE_QUALIFIER = CONVERT(SYSNAME,DB_NAME()),
       PKTABLE_OWNER = CONVERT(SYSNAME,SCHEMA_NAME(O1.SCHEMA_ID)),
       PKTABLE_NAME = CONVERT(SYSNAME,O1.NAME),
       PKCOLUMN_NAME = CONVERT(SYSNAME,C1.NAME),
       FKTABLE_QUALIFIER = CONVERT(SYSNAME,DB_NAME()),
       FKTABLE_OWNER = CONVERT(SYSNAME,SCHEMA_NAME(O2.SCHEMA_ID)),
       FKTABLE_NAME = CONVERT(SYSNAME,O2.NAME),
       FKCOLUMN_NAME = CONVERT(SYSNAME,C2.NAME),
       -- Force the column to be non-nullable (see SQL BU 325751)
       --KEY_SEQ             = isnull(convert(smallint,k.constraint_column_id), sysconv(smallint,0)),
       UPDATE_RULE = CONVERT(SMALLINT,CASE OBJECTPROPERTY(F.OBJECT_ID,'CnstIsUpdateCascade') 
                                        WHEN 1 THEN 0
                                        ELSE 1
                                      END),
       DELETE_RULE = CONVERT(SMALLINT,CASE OBJECTPROPERTY(F.OBJECT_ID,'CnstIsDeleteCascade') 
                                        WHEN 1 THEN 0
                                        ELSE 1
                                      END),
       FK_NAME = CONVERT(SYSNAME,OBJECT_NAME(F.OBJECT_ID)),
       PK_NAME = CONVERT(SYSNAME,I.NAME),
       DEFERRABILITY = CONVERT(SMALLINT,7)   -- SQL_NOT_DEFERRABLE
FROM   SYS.ALL_OBJECTS O1,
       SYS.ALL_OBJECTS O2,
       SYS.ALL_COLUMNS C1,
       SYS.ALL_COLUMNS C2,
       SYS.FOREIGN_KEYS F
       INNER JOIN SYS.FOREIGN_KEY_COLUMNS K
         ON (K.CONSTRAINT_OBJECT_ID = F.OBJECT_ID)
       INNER JOIN SYS.INDEXES I
         ON (F.REFERENCED_OBJECT_ID = I.OBJECT_ID
             AND F.KEY_INDEX_ID = I.INDEX_ID)
WHERE  O1.OBJECT_ID = F.REFERENCED_OBJECT_ID
       AND O2.OBJECT_ID = F.PARENT_OBJECT_ID
       AND C1.OBJECT_ID = F.REFERENCED_OBJECT_ID
       AND C2.OBJECT_ID = F.PARENT_OBJECT_ID
       AND C1.COLUMN_ID = K.REFERENCED_COLUMN_ID
       AND C2.COLUMN_ID = K.PARENT_COLUMN_ID

--List all  the constraints
WITH   ALL_KEYS_IN_TABLE (CONSTRAINT_NAME,CONSTRAINT_TYPE,PARENT_TABLE_NAME,PARENT_COL_NAME,PARENT_COL_NAME_DATA_TYPE,REFERENCE_TABLE_NAME,REFERENCE_COL_NAME) 
AS
(
SELECT  CONSTRAINT_NAME= CAST (PKnUKEY.name AS VARCHAR(30)) ,
        CONSTRAINT_TYPE=CAST (PKnUKEY.type_desc AS VARCHAR(30)) ,
        PARENT_TABLE_NAME=CAST (PKnUTable.name AS VARCHAR(30)) ,
        PARENT_COL_NAME=CAST ( PKnUKEYCol.name AS VARCHAR(30)) ,
        PARENT_COL_NAME_DATA_TYPE=  oParentColDtl.DATA_TYPE,        
        REFERENCE_TABLE_NAME='' ,
        REFERENCE_COL_NAME='' 

FROM sys.key_constraints as PKnUKEY
    INNER JOIN sys.tables as PKnUTable
            ON PKnUTable.object_id = PKnUKEY.parent_object_id
    INNER JOIN sys.index_columns as PKnUColIdx
            ON PKnUColIdx.object_id = PKnUTable.object_id
            AND PKnUColIdx.index_id = PKnUKEY.unique_index_id
    INNER JOIN sys.columns as PKnUKEYCol
            ON PKnUKEYCol.object_id = PKnUTable.object_id
            AND PKnUKEYCol.column_id = PKnUColIdx.column_id
     INNER JOIN INFORMATION_SCHEMA.COLUMNS oParentColDtl
            ON oParentColDtl.TABLE_NAME=PKnUTable.name
            AND oParentColDtl.COLUMN_NAME=PKnUKEYCol.name
UNION ALL
SELECT  CONSTRAINT_NAME= CAST (oConstraint.name AS VARCHAR(30)) ,
        CONSTRAINT_TYPE='FK',
        PARENT_TABLE_NAME=CAST (oParent.name AS VARCHAR(30)) ,
        PARENT_COL_NAME=CAST ( oParentCol.name AS VARCHAR(30)) ,
        PARENT_COL_NAME_DATA_TYPE= oParentColDtl.DATA_TYPE,     
        REFERENCE_TABLE_NAME=CAST ( oReference.name AS VARCHAR(30)) ,
        REFERENCE_COL_NAME=CAST (oReferenceCol.name AS VARCHAR(30)) 
FROM sys.foreign_key_columns FKC
    INNER JOIN sys.sysobjects oConstraint
            ON FKC.constraint_object_id=oConstraint.id 
    INNER JOIN sys.sysobjects oParent
            ON FKC.parent_object_id=oParent.id
    INNER JOIN sys.all_columns oParentCol
            ON FKC.parent_object_id=oParentCol.object_id /* ID of the object to which this column belongs.*/
            AND FKC.parent_column_id=oParentCol.column_id/* ID of the column. Is unique within the object.Column IDs might not be sequential.*/
    INNER JOIN sys.sysobjects oReference
            ON FKC.referenced_object_id=oReference.id
    INNER JOIN INFORMATION_SCHEMA.COLUMNS oParentColDtl
            ON oParentColDtl.TABLE_NAME=oParent.name
            AND oParentColDtl.COLUMN_NAME=oParentCol.name
    INNER JOIN sys.all_columns oReferenceCol
            ON FKC.referenced_object_id=oReferenceCol.object_id /* ID of the object to which this column belongs.*/
            AND FKC.referenced_column_id=oReferenceCol.column_id/* ID of the column. Is unique within the object.Column IDs might not be sequential.*/

)

select * from   ALL_KEYS_IN_TABLE
where   
    PARENT_TABLE_NAME  in ('tPayerCreditAccount') 
    or REFERENCE_TABLE_NAME  in ('tPayerCreditAccount')
ORDER BY PARENT_TABLE_NAME,CONSTRAINT_NAME;
