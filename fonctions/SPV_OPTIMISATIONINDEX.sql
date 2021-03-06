SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER ON


-----------------------------------------------------------------------------------------
-- Fonction		: SPV_OPTIMISATIONINDEX
-- Paramètre d'entrée	: 
-- Paramètre de sortie	: 
-- Descriptif		: Optimisation des index
-----------------------------------------------------------------------------------------

CREATE FUNCTION [dbo].[SPV_OPTIMISATIONINDEX]()
	RETURNS varchar(8000)
AS
BEGIN

-- Déclaration des variables
DECLARE
	@v_sql varchar(8000)

	SET @v_sql = '
		DECLARE
			@v_error int,
			@v_status int,
			@v_retour int,
			@v_commande varchar(8000),
			@v_schema sysname,
			@v_table sysname,
			@v_objectname char(255),
			@v_objectid int,
			@v_indexid int,
			@v_logicalfragmentation decimal

		DECLARE
			@CODE_OK tinyint,
			@CODE_KO tinyint

		DECLARE
			@DEFRAGMENTATION tinyint,
			@RECONSTRUCTION tinyint

			SET @CODE_OK = 0
			SET @CODE_KO = 1
			SET @DEFRAGMENTATION = 10
			SET @RECONSTRUCTION = 40

			SET @v_error = 0
			SET @v_status = @CODE_OK
			SET @v_retour = @CODE_KO

			CREATE TABLE #Tmp(OBJECTNAME char(255), OBJECTID int, INDEXNAME char(255), INDEXID int, LEVEL int, PAGES int,
				ROWS int, MINIMUMRECORDSIZE int, MAXIMUMRECORDSIZE int, AVERAGERECORDSIZE int, FORWARDEDRECORDS int, EXTENTS int, EXTENTSWITCHES int,
				AVERAGEFREEBYTES int, AVERAGEPAGEDENSITY int, SCANDENSITY decimal, BESTCOUNT int, ACTUALCOUNT int, LOGICALFRAGMENTATION decimal,
				EXTENTFRAGMENTATION decimal)
			DECLARE c_index CURSOR LOCAL FAST_FORWARD FOR SELECT s.name, t.name FROM sys.tables t INNER JOIN sys.schemas s ON s.schema_id = t.schema_id WHERE t.type = ''U'' AND t.is_ms_shipped = 0
			OPEN c_index
			FETCH NEXT FROM c_index INTO @v_schema, @v_table
			WHILE ((@@FETCH_STATUS = 0) AND (@v_status = @CODE_OK) AND (@v_error = 0))
			BEGIN
				INSERT INTO #Tmp EXEC (''DBCC SHOWCONTIG ('''''' + @v_schema + ''.'' + @v_table + '''''') WITH FAST, TABLERESULTS, ALL_INDEXES, NO_INFOMSGS'')
				FETCH NEXT FROM c_index INTO @v_schema, @v_table
			END
			CLOSE c_index
			DEALLOCATE c_index
			DECLARE c_index CURSOR LOCAL FAST_FORWARD FOR SELECT OBJECTNAME, OBJECTID, INDEXID, LOGICALFRAGMENTATION, s.name FROM #Tmp INNER JOIN sys.tables t ON t.object_id = OBJECTID
				INNER JOIN sys.schemas s ON s.schema_id = t.schema_id, sysindexes i, sysobjects o
				WHERE INDEXPROPERTY(OBJECTID, INDEXNAME, ''IndexDepth'') > 0 AND i.id = OBJECTID AND indid = INDEXID AND o.id = i.id
			OPEN c_index
			FETCH NEXT FROM c_index INTO @v_objectname, @v_objectid, @v_indexid, @v_logicalfragmentation, @v_schema
			WHILE @@FETCH_STATUS = 0
			BEGIN
				IF @v_logicalfragmentation > @DEFRAGMENTATION
				BEGIN
					IF @v_logicalfragmentation < @RECONSTRUCTION
						SET @v_commande = ''DBCC INDEXDEFRAG (0, '' + LTRIM(RTRIM(@v_objectid)) + '', '' + LTRIM(RTRIM(@v_indexid)) + '') WITH NO_INFOMSGS''
					ELSE
						SET @v_commande = ''DBCC DBREINDEX ('''''' + LTRIM(RTRIM(@v_schema)) + ''.'' + LTRIM(RTRIM(@v_objectname)) + '''''', '''''''') WITH NO_INFOMSGS''
					EXEC (@v_commande)
				END
				FETCH NEXT FROM c_index INTO @v_objectname, @v_objectid, @v_indexid, @v_logicalfragmentation, @v_schema
			END
			CLOSE c_index
			DEALLOCATE c_index
			DROP TABLE #Tmp'
	RETURN @v_sql
END

