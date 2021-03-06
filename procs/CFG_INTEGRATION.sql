SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF

-----------------------------------------------------------------------------------------
-- Procédure		: CFG_INTEGRATION
-- Paramètre d'entrée	: @v_action : Action à mener
--			  @v_ssaction : Sous action à mener
--			  @v_itg_table : Table
--			  @v_itg_colonne : Colonne
--			  @v_itg_type : Type
--			  @v_itg_view : Vue
--			  @v_lan_id : Identifiant langue
--			  @v_lib_libelle : Libellé
-- Paramètre de sortie	: @v_retour : Code de retour
--			  @v_tra_id : Identifiant traduction
-- Descriptif		: Gestion des données spécifiques
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[CFG_INTEGRATION]
	@v_action smallint,
	@v_ssaction smallint,
	@v_itg_table varchar(32),
	@v_itg_colonne varchar(32),
	@v_itg_type varchar(32),
	@v_itg_view varchar(32),
	@v_tra_id int out,
	@v_lan_id varchar(3),
	@v_lib_libelle varchar(8000),
	@v_retour smallint out
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

DECLARE
	@v_error smallint,
	@v_local bit,
	@v_sql varchar(max),
	@v_sqlColonne varchar(max),
	@v_sqlCreate varchar(max),
	@v_sqlDrop varchar(max),
	@v_text nvarchar(4000),
	@v_tmpText nvarchar(4000),
	@v_lineFeed varchar(1),
	@v_carriageReturn varchar(1),
	@v_charindex int,
	@v_tmpCharindex int

	IF @@TRANCOUNT > 0
		SET @v_local = 0
	ELSE
	BEGIN
		SET @v_local = 1
		BEGIN TRAN AGV
	END
	SET @v_retour = 113
	SET @v_error = 0
	IF @v_action = 0
	BEGIN
		IF @v_ssaction = 0
		BEGIN
			IF NOT EXISTS (SELECT 1 FROM INTEGRATION WHERE ITG_TABLE = @v_itg_table AND ITG_COLONNE = @v_itg_colonne)
			BEGIN
				SET @v_sql = 'ALTER TABLE ' + @v_itg_table + ' ADD ' + @v_itg_colonne + ' ' + @v_itg_type + ' NULL'
				EXEC (@v_sql)
				SET @v_error = @@ERROR
				IF @v_error = 0
				BEGIN
					EXEC @v_error = CFG_INTEGRATION 1, 0, @v_itg_table, @v_itg_colonne, NULL, @v_itg_view, @v_tra_id out, NULL, NULL, @v_retour out
					IF ((@v_retour = 0) AND (@v_error = 0))
					BEGIN
						EXEC @v_error = LIB_TRADUCTION @v_action, @v_lan_id, @v_lib_libelle, @v_tra_id out
						IF @v_error = 0
						BEGIN
							INSERT INTO INTEGRATION (ITG_TABLE, ITG_COLONNE, ITG_TRADUCTION, ITG_TYPE) VALUES (@v_itg_table, @v_itg_colonne, @v_tra_id, @v_itg_type)
							SET @v_error = @@ERROR
							IF @v_error = 0
								SET @v_retour = 0
						END
					END
				END
			END
			ELSE
				SET @v_retour = 117
		END
		ELSE IF @v_ssaction = 1
		BEGIN
			DECLARE c_integration CURSOR LOCAL FAST_FORWARD FOR SELECT ITG_TABLE, ITG_COLONNE FROM INTEGRATION
			OPEN c_integration
			FETCH NEXT FROM c_integration INTO @v_itg_table, @v_itg_colonne
			WHILE @@FETCH_STATUS = 0
			BEGIN
				SET @v_itg_view = CASE @v_itg_table WHEN 'CHARGE' THEN 'INT_CHARGE_VIVANTE' WHEN 'MISSION' THEN 'INT_MISSION_VIVANTE' ELSE 'INT_' + @v_itg_table END
				IF NOT EXISTS (SELECT 1 FROM sys.objects o INNER JOIN sys.syscolumns c ON c.id = o.object_id WHERE o.type = 'V' AND o.name = @v_itg_view and c.name = @v_itg_colonne)
				BEGIN
					EXEC @v_error = CFG_INTEGRATION 1, 0, @v_itg_table, @v_itg_colonne, NULL, @v_itg_view, @v_tra_id out, NULL, NULL, @v_retour out
					IF NOT ((@v_retour = 0) AND (@v_error = 0))
						BREAK
				END
				FETCH NEXT FROM c_integration INTO @v_itg_table, @v_itg_colonne
			END
			CLOSE c_integration
			DEALLOCATE c_integration
			SET @v_error = CASE @v_retour WHEN 0 THEN @v_error ELSE @v_retour END
		END
	END
	ELSE IF @v_action = 1
	BEGIN
		IF @v_ssaction IN (0, 2)
		BEGIN
			SET @v_sqlColonne = ', ' + @v_itg_colonne + ' '
			SET @v_tmpCharindex = 0
			SET @v_sqlDrop = 'DROP VIEW ' + @v_itg_view
			SET @v_lineFeed = CHAR(10)
			SET @v_carriageReturn = CHAR(13)
			DECLARE c_comments CURSOR LOCAL FAST_FORWARD FOR SELECT c.text FROM sys.objects o INNER JOIN sys.syscomments c ON c.id = o.object_id WHERE type = 'V' AND name = @v_itg_view
			OPEN c_comments
			FETCH NEXT FROM c_comments INTO @v_text
			WHILE @@FETCH_STATUS = 0
			BEGIN
				IF (((@v_ssaction = 0) AND (@v_tmpCharindex <> 1))
					OR ((@v_ssaction = 2) AND (@v_tmpCharindex = 0)))
				BEGIN
					IF @v_ssaction = 0
					BEGIN
						SET @v_charindex = CHARINDEX('FROM', @v_text)
						WHILE @v_charindex <> 0
						BEGIN
							SET @v_tmpText = REPLACE(REPLACE(REPLACE(REPLACE(SUBSTRING(@v_text, @v_charindex, LEN(@v_text) - @v_charindex + 1), ' ', ''), @v_lineFeed, ''), @v_carriageReturn, ''), 'dbo.', '')
							SET @v_tmpCharindex = CHARINDEX('FROM' + @v_itg_table, @v_tmpText)
							IF @v_tmpCharindex = 1
							BEGIN
								SET @v_sqlCreate = ISNULL(@v_sqlCreate, '') + SUBSTRING(@v_text, 1, @v_charindex - 1) + @v_sqlColonne + SUBSTRING(@v_text, @v_charindex, LEN(@v_text) - @v_charindex + 1)
								BREAK
							END
							ELSE
								SET @v_charindex = CHARINDEX('FROM', @v_text, @v_charindex + 4)
						END
						IF @v_tmpCharindex <> 1
							SET @v_sqlCreate = ISNULL(@v_sqlCreate, '') + @v_text
					END
					ELSE IF @v_ssaction = 2
					BEGIN
						SET @v_tmpCharindex = CHARINDEX(@v_sqlColonne, @v_text)
						IF @v_tmpCharindex <> 0
							SET @v_sqlCreate = ISNULL(@v_sqlCreate, '') + SUBSTRING(@v_text, 1, @v_tmpCharindex - 1) + SUBSTRING(@v_text, @v_tmpCharindex + LEN(@v_sqlColonne), LEN(@v_text) - @v_tmpCharindex - LEN(@v_sqlColonne) + 1)
						ELSE
							SET @v_sqlCreate = ISNULL(@v_sqlCreate, '') + @v_text
					END
				END
				ELSE
					SET @v_sqlCreate = ISNULL(@v_sqlCreate, '') + @v_text
				FETCH NEXT FROM c_comments INTO @v_text
			END
			CLOSE c_comments
			DEALLOCATE c_comments
			SET @v_sql = @v_sqlDrop + ';' + 'EXEC dbo.sp_executesql @statement = N''' + REPLACE(@v_sqlCreate, '''', '''''') + ''''
			EXEC (@v_sql)
			SET @v_error = @@ERROR
			IF @v_error = 0
				SET @v_retour = 0
		END
		ELSE IF @v_ssaction = 1
		BEGIN
			IF EXISTS (SELECT 1 FROM INTEGRATION WHERE ITG_TABLE = @v_itg_table AND ITG_COLONNE = @v_itg_colonne)
			BEGIN
				IF EXISTS (SELECT 1 FROM INTEGRATION WHERE ITG_TABLE = @v_itg_table AND ITG_COLONNE = @v_itg_colonne AND ITG_TYPE != @v_itg_type)
				BEGIN
					SET @v_sql = 'ALTER TABLE ' + @v_itg_table + ' ALTER COLUMN ' + @v_itg_colonne + ' ' + @v_itg_type + ' NULL'
					EXEC (@v_sql)
					SET @v_error = @@ERROR
				END
				IF (@v_error = 0)
				BEGIN
					UPDATE LIBELLE SET LIB_LIBELLE = @v_lib_libelle WHERE LIB_LANGUE = @v_lan_id AND LIB_TRADUCTION = @v_tra_id
					SET @v_error = @@ERROR
					IF @v_error = 0
					BEGIN
						UPDATE INTEGRATION SET ITG_TYPE = @v_itg_type WHERE ITG_TABLE = @v_itg_table AND ITG_COLONNE = @v_itg_colonne
						SET @v_error = @@ERROR
						IF @v_error = 0
							SET @v_retour = 0
					END
				END
			END
		END
	END
	ELSE IF @v_action = 2
	BEGIN
		DELETE INTEGRATION WHERE ITG_TABLE = @v_itg_table AND ITG_COLONNE  = @v_itg_colonne
		SET @v_error = @@ERROR
		IF @v_error = 0
		BEGIN
			EXEC @v_error = CFG_INTEGRATION 1, 2, @v_itg_table, @v_itg_colonne, NULL, @v_itg_view, @v_tra_id out, NULL, NULL, @v_retour out
			IF ((@v_retour = 0) AND (@v_error = 0))
			BEGIN
				SET @v_sql = 'ALTER TABLE ' + @v_itg_table + ' DROP COLUMN ' + @v_itg_colonne
				EXEC (@v_sql)
				SET @v_error = @@ERROR
				IF @v_error = 0
				BEGIN
					EXEC @v_error = LIB_TRADUCTION @v_action, NULL, NULL, @v_tra_id out
					IF @v_error = 0
						SELECT @v_retour = 0
				END
			END
		END
	END
	IF @v_local = 1
	BEGIN
		IF @v_error <> 0
			ROLLBACK TRAN AGV
		ELSE
			COMMIT TRAN AGV
	END
	RETURN @v_error

