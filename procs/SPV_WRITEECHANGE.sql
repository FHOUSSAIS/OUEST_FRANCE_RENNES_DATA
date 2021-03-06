SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON






-----------------------------------------------------------------------------------------
-- Procédure		: SPV_WRITEECHANGE
-- Paramètre d'entrée	: @v_type : Type
--						  @v_interface : Identifiant interface
--						  @v_ech_table : Table
-- Paramètre de sortie	: 
-- Descriptif		: Ecriture des échanges de données entre bases de données
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[SPV_WRITEECHANGE]
	@v_type bit,
	@v_interface int,
	@v_ech_table varchar(256)
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

--Déclaration des variables
DECLARE
	@v_error int,
	@v_status int,
	@v_retour int,
	@v_sql varchar(max),
	@v_declaresql varchar(max),
	@v_insertsql1 varchar(max),
	@v_insertsql2 varchar(max),
	@v_deletesql varchar(max),
	@v_updatesql varchar(max),
	@v_column_name sysname,
	@v_type_name sysname,
	@v_max_length smallint,
	@v_is_identity bit,
	@v_is_primary_key bit,
	@v_column_list varchar(max),
	@v_primary_key_column_list varchar(max),
	@v_type_column_list varchar(max),
	@v_ibl_serveurlie varchar(256),
	@v_ech_sens bit,
	@v_ecl_catalogue varchar(256),
	@v_ecl_schema varchar(256),
	@v_ecl_table varchar(256)

-- Déclaration des constantes de retour
DECLARE
	@CODE_OK int,
	@CODE_KO int,
	@CODE_KO_INEXISTANT int,
	@CODE_OUI int,
	@CODE_KO_INCONNU int,
	@CODE_KO_INCORRECT int,
	@CODE_KO_SQL int,
	@CODE_KO_INATTENDU int
	
-- Définition des constantes
	SET @CODE_OK = 0
	SET @CODE_KO = 1
	SET @CODE_KO_INEXISTANT = 4
	SET @CODE_OUI = 5
	SET @CODE_KO_INCONNU = 7
	SET @CODE_KO_INCORRECT = 11
	SET @CODE_KO_SQL = 13
	SET @CODE_KO_INATTENDU = 16

-- Initialisation de la variable de retour
	SET @v_error = 0
	SET @v_status = @CODE_OK
	SET @v_retour = @CODE_KO

	IF @v_type = 0
	BEGIN
		SET ANSI_NULLS ON
		SET ANSI_WARNINGS ON
		SET XACT_ABORT ON
		SET TRANSACTION ISOLATION LEVEL READ COMMITTED
		SELECT @v_ibl_serveurlie = IBL_SERVEUR_LIE FROM INTERFACE_BDD_LS WHERE IBL_ID = @v_interface
		IF @v_ibl_serveurlie IS NOT NULL
		BEGIN
			DECLARE c_echange CURSOR LOCAL FAST_FORWARD FOR SELECT ECH_TABLE, ECH_SENS, ISNULL(ECL_CATALOGUE, ''), ISNULL(ECL_SCHEMA, ''), ISNULL(ECL_TABLE, ECH_TABLE) FROM ECHANGE_LS
				INNER JOIN ECHANGE ON ECH_TABLE = ECL_ECHANGE
				WHERE ECL_INTERFACE = @v_interface AND ((ECH_SENS = 0) OR (ECH_SENS = 1 AND ECH_WRITE = 1))
			OPEN c_echange
			FETCH NEXT FROM c_echange INTO @v_ech_table, @v_ech_sens, @v_ecl_catalogue, @v_ecl_schema, @v_ecl_table
			WHILE ((@@FETCH_STATUS = 0) AND (@v_status = @CODE_OK) AND (@v_error = 0))
			BEGIN
				IF EXISTS (SELECT 1 FROM sys.objects WHERE name = PARSENAME(@v_ech_table, 1) AND type = 'U')
				BEGIN
					SET @v_sql = 'IF EXISTS(SELECT 1 FROM '
					SET @v_declaresql = 'DECLARE @v_table table ('
					SET @v_insertsql1 = 'INSERT INTO @v_table ('
					IF @v_ech_sens = 0
					BEGIN
						SET @v_sql = @v_sql + '"' + @v_ibl_serveurlie + '".' + @v_ecl_catalogue + '.' + @v_ecl_schema + '.' + @v_ecl_table + ')
							BEGIN
							'
						SET @v_insertsql2 = 'INSERT INTO ' + @v_ech_table + '('
						SET @v_deletesql = 'DELETE "' + @v_ibl_serveurlie + '".' + @v_ecl_catalogue + '.' + @v_ecl_schema + '.' + @v_ecl_table + ' FROM "' + @v_ibl_serveurlie + '".' + @v_ecl_catalogue + '.' + @v_ecl_schema + '.' + @v_ecl_table + ' e INNER JOIN @v_table t ON '
						SET @v_updatesql = 'UPDATE ECHANGE SET ECH_READ = 1 WHERE ECH_TABLE = ''' + @v_ech_table + ''''
					END
					ELSE
					BEGIN
						SET @v_sql = @v_sql + @v_ech_table + ')
							BEGIN
							'
						SET @v_insertsql2 = 'INSERT INTO "' + @v_ibl_serveurlie + '".' + @v_ecl_catalogue + '.' + @v_ecl_schema + '.' + @v_ecl_table + '('
						SET @v_deletesql = 'DELETE FROM ' + @v_ech_table + ' FROM ' + @v_ech_table + ' e INNER JOIN @v_table t ON '
						SET @v_updatesql = 'UPDATE ECHANGE SET ECH_WRITE = 0 WHERE ECH_TABLE = ''' + @v_ech_table + ''''
					END
					SET @v_column_list = ''
					SET @v_primary_key_column_list = ''
					SET @v_type_column_list = ''
					DECLARE c_column CURSOR LOCAL FAST_FORWARD FOR SELECT c.name, c.is_identity, t.name, c.max_length, i.is_primary_key
						FROM sys.columns c JOIN sys.types t ON t.user_type_id = c.user_type_id LEFT OUTER JOIN sys.index_columns ic ON ic.object_id = c.object_id AND ic.column_id = c.column_id
						LEFT OUTER JOIN sys.indexes i ON i.object_id = ic.object_id AND i.index_id = ic.index_id
						WHERE c.object_id = (SELECT object_id FROM sys.objects WHERE name = PARSENAME(@v_ech_table, 1) AND type = 'U') AND c.is_computed = 0
					OPEN c_column
					FETCH NEXT FROM c_column INTO @v_column_name, @v_is_identity, @v_type_name, @v_max_length, @v_is_primary_key
					WHILE ((@@FETCH_STATUS = 0) AND (@v_status = @CODE_OK) AND (@v_error = 0))
					BEGIN
						IF (@v_is_identity = 1)
						BEGIN
							SET @v_status = @CODE_KO_INATTENDU
							BREAK
						END
						SET @v_column_list = @v_column_list + '[' + @v_column_name + '], '
						IF @v_is_primary_key = 1
							SET @v_primary_key_column_list = @v_primary_key_column_list + 'e.[' + @v_column_name + '] = t.[' + @v_column_name + '] AND '
						IF @v_type_name = 'varchar'
							SET @v_type_column_list = @v_type_column_list + '[' + @v_column_name + '] ' + @v_type_name + '(' + CONVERT(varchar, @v_max_length) + '), '
						ELSE
							SET @v_type_column_list = @v_type_column_list + '[' + @v_column_name + '] ' + @v_type_name + ', '
						FETCH NEXT FROM c_column INTO @v_column_name, @v_is_identity, @v_type_name, @v_max_length, @v_is_primary_key
					END
					CLOSE c_column
					DEALLOCATE c_column
					IF ((@v_status = @CODE_OK) AND (@v_error = 0))
					BEGIN
						IF ((@v_column_list <> '') AND (@v_primary_key_column_list <> ''))
						BEGIN
							SET @v_column_list = LEFT(@v_column_list, LEN(@v_column_list) - 1)
							SET @v_primary_key_column_list = LEFT(@v_primary_key_column_list, LEN(@v_primary_key_column_list) - 4)
							SET @v_type_column_list = LEFT(@v_type_column_list, LEN(@v_type_column_list) - 1)
							SET @v_declaresql = @v_declaresql + @v_type_column_list + ')'
							SET @v_insertsql1 = @v_insertsql1 + @v_column_list + ') SELECT '
							IF @v_ech_sens = 0
								SET @v_insertsql1 = @v_insertsql1 + @v_column_list + ' FROM "' + @v_ibl_serveurlie + '".' + @v_ecl_catalogue + '.' + @v_ecl_schema + '.' + @v_ecl_table
							ELSE
								SET @v_insertsql1 = @v_insertsql1 + @v_column_list + ' FROM ' + @v_ech_table
							SET @v_insertsql2 = @v_insertsql2 + @v_column_list + ') SELECT ' + @v_column_list + ' FROM @v_table'
							SET @v_deletesql = @v_deletesql + @v_primary_key_column_list
							SET @v_sql = @v_sql + '
								' + @v_declaresql + '
								' + @v_insertsql1 + '
								' + @v_insertsql2 + '
								' + @v_deletesql + '
								' + @v_updatesql + '
								' + 'END'
							BEGIN TRAN
							EXEC (@v_sql)
							SET @v_error = @@ERROR
							IF @v_error = 0
								COMMIT TRAN
							ELSE
							BEGIN
								SET @v_status = @CODE_KO_SQL
								ROLLBACK TRAN
							END
						END
						ELSE
							SET @v_status = @CODE_KO_INCORRECT
					END
				END
				ELSE
					SET @v_status = @CODE_KO_INCONNU
				FETCH NEXT FROM c_echange INTO @v_ech_table, @v_ech_sens, @v_ecl_catalogue, @v_ecl_schema, @v_ecl_table
			END
			CLOSE c_echange
			DEALLOCATE c_echange
		END
		ELSE
			SET @v_status = @CODE_KO_INEXISTANT
	END
	ELSE IF @v_type = 1
	BEGIN
		IF EXISTS (SELECT 1 FROM ECHANGE WHERE ECH_TABLE = @v_ech_table AND ECH_INTERFACE = @v_interface)
		BEGIN
			UPDATE ECHANGE SET ECH_WRITE = 1 WHERE ECH_TABLE = @v_ech_table AND ECH_INTERFACE = @v_interface
				AND ECH_SENS = 1
			SELECT @v_error = @@ERROR
			IF @v_error = 0
				SET @v_status = @CODE_OK
			ELSE
				SET @v_status = @CODE_KO_SQL
		END
		ELSE
			SET @v_status = @CODE_KO_INCONNU
	END
	IF @v_status = @CODE_OK AND @v_error = 0
	BEGIN
		IF @v_type = 0 AND EXISTS (SELECT 1 FROM ECHANGE INNER JOIN ECHANGE_LS ON ECL_ECHANGE = ECH_TABLE
			WHERE ECL_INTERFACE = @v_interface AND ECH_READ = 1)
			SET @v_retour = @CODE_OUI
		ELSE
			SET @v_retour = @CODE_OK
	END
	ELSE
		SET @v_retour = CASE @v_status WHEN @CODE_OK THEN @v_error ELSE @v_status END
	RETURN @v_retour


