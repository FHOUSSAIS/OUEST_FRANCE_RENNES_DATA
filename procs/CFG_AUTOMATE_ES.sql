SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER ON

-----------------------------------------------------------------------------------------
-- Procédure		: CFG_AUTOMATE_ES
-- Paramètre d'entrées	:
--			@v_action : 0 -> import, 1 -> export
--			@v_int_id_phys : identifiant de l'interface physique
--			@v_file : Fichier contenant les informations (pour l'import)
--			@v_lan_id : Langue
-- Paramètre de sorties	:
--			@v_retour : Code de retour
--			@v_nb_inserted : nombre de donnees inserees
--			@v_nb_deleted : nombre de donnees supprimees
--			@v_nb_modified : nombre de donnees modifiees
--			@v_error_line_nb : numero de la ligne ou il y a une erreur
-- Descriptif		: Import de la configuration des automates et entrees/sorties
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[CFG_AUTOMATE_ES]
	@v_action int,
	@v_int_id_phys int,
	@v_file varchar(8000),
	@v_lan_id varchar(3),
	@v_retour smallint out,
	@v_nb_inserted int out,
	@v_nb_deleted int out,
	@v_nb_modified int out,
	@v_error_line_nb int out
AS

DECLARE
	@v_error smallint,
	@v_fileError smallint,
	@v_fileFound bit,
	@v_exists int,
	@v_lineFeed varchar(1),
	@v_line varchar(8000),
	@v_charindex int,
	@v_i int,
	@v_str varchar(150),
	@v_num varchar(150),
	@v_code varchar(150),
	@v_direction varchar(150),
	@v_event varchar(150),
	@v_delai varchar(150),
	@v_entete bit,
	@v_enteteFound bit,
	@v_libelle varchar(8000) = '',
	@v_trad int,
	@v_int_id_log int,
	@v_data_id int,
	@v_type tinyint,
	@TYPE_AUTOMATE tinyint,
	@TYPE_ES tinyint,
	@NB_EXIST smallint,
	@FORMAT_INCORRECT smallint,
	@ACT_IMPORT int,
	@ACT_EXPORT int,
	@FILE_HEADER varchar(8000)

	BEGIN TRAN
	SET @v_retour = 113
	SET @v_nb_inserted = 0
	SET @v_nb_inserted = 0
	SET @v_nb_modified = 0
	SET @v_error_line_nb = 0
	SET @v_error = 0
	SET @v_fileError = 0
	SET @v_exists = 0
	SET @v_fileFound = 0
	SET @v_enteteFound = 0
	SET @TYPE_AUTOMATE = 104
	SET @TYPE_ES = 105
	SET @NB_EXIST = 3299
	SET @FORMAT_INCORRECT = 3298
	SET @ACT_IMPORT = 0
	SET @ACT_EXPORT = 1
	SET @FILE_HEADER = 'Number;Label;Code;Direction (I / O / IO);Event (0/1);Delay (sec.)'
	
	SELECT @v_type = INT_TYPE_PHYS FROM INTERFACE WHERE INT_ID_PHYS = @v_int_id_phys
	
	IF @v_action = @ACT_IMPORT
	BEGIN
		IF @v_type = @TYPE_AUTOMATE
		BEGIN
			-- Backup des id des automates pour savoir lesquels ont ete supprimes
			SELECT VAO_ID AS DATA_ID INTO DATA_ID_TABLE FROM VARIABLE_AUTOMATE_OPC WHERE VAO_INTERFACE = @v_int_id_phys
		END
		ELSE IF @v_type = @TYPE_ES
		BEGIN
			-- Backup des id des ES pour savoir lesquels ont ete supprimes
			SELECT ESP_ID AS DATA_ID INTO DATA_ID_TABLE FROM ENTREE_SORTIE_OPC WHERE ESP_INTERFACE = @v_int_id_phys
		END
		
		EXEC master.dbo.xp_fileexist @v_file, @v_exists out
		IF @v_exists = 1
		BEGIN
			SET @v_fileFound = 1
			CREATE TABLE #DATA_FILE (LINE varchar(8000))
			SET @v_lineFeed = CHAR(10)
			
			EXEC ('BULK INSERT #DATA_FILE FROM "' + @v_file + '" WITH (ROWTERMINATOR = ''' + @v_lineFeed + ''', CODEPAGE = ''ACP'')')
			SET @v_error = @@ERROR
			IF @v_error = 0
			BEGIN
				DECLARE c_data_file CURSOR LOCAL FOR SELECT LINE FROM #DATA_FILE
				OPEN c_data_file
				FETCH NEXT FROM c_data_file INTO @v_line
				
				WHILE ((@@FETCH_STATUS = 0) AND (@v_error = 0) AND @v_fileError = 0)
				BEGIN
					SET @v_error_line_nb = @v_error_line_nb + 1
					SET @v_i = 1
					SET @v_entete = 0
					SET @v_str = NULL
					SET @v_num = NULL
					SET @v_libelle = ''
					SET @v_code = NULL
					SET @v_direction = NULL
					SET @v_event = NULL
					SET @v_delai = NULL
					SET @v_trad = NULL
					
					SET @v_charindex = CHARINDEX(';', @v_line)
					
					WHILE ((@v_entete = 0) AND (@v_fileError <> 1) AND ( (@v_charindex <> 0) OR LEN(@v_line) > 0) )
					BEGIN

						IF @v_i <> 6 AND @v_charindex <> 0
							SET @v_str = LTRIM(RTRIM(SUBSTRING(@v_line, 1, @v_charindex - 1)))
						ELSE
							SET @v_str = SUBSTRING(@v_line, 1, LEN(@v_line) - 1)
						
						IF @v_str = '' AND @v_i <> 2 -- le libelle peut etre vide
							SET @v_fileError = 1 -- pas de donnees
						ELSE IF @v_i = 1
						BEGIN
							IF ISNUMERIC( @v_str ) <> 1 
							BEGIN
								IF @v_enteteFound = 0
								BEGIN
									SET @v_entete = 1 -- entete des colonnes
									SET @v_enteteFound = 1
								END
								ELSE
									SET @v_fileError = 1 -- numero incorrect
							END
							ELSE
								SET @v_num = @v_str
						END
						ELSE IF @v_i = 2
						BEGIN
							SET @v_libelle = @v_str
						END
						ELSE IF @v_i = 3
						BEGIN
							SET @v_code = @v_str
						END
						ELSE IF @v_i = 4
						BEGIN
							SET @v_direction = UPPER( @v_str )
							IF @v_direction <> 'I' AND @v_direction <> 'O'
								AND ( @v_type <> @TYPE_AUTOMATE OR @v_direction <> 'IO' )
								SET @v_direction = NULL
						END
						ELSE IF @v_i = 5
						BEGIN
							IF @v_str = '0' OR @v_str = '1'
								SET @v_event = @v_str
						END
						ELSE IF @v_i = 6
						BEGIN
							SET @v_line = ''
							
							IF ISNUMERIC(@v_str) = 1
								SET @v_delai = @v_str
						END
						
						SET @v_line = SUBSTRING(@v_line, @v_charindex + 1, LEN(@v_line) - @v_charindex)
						SET @v_i = @v_i + 1
						SET @v_charindex = CHARINDEX(';', @v_line)
					END
						
					-- ajout / modification de la variable
					IF @v_entete = 0
					BEGIN
						IF @v_num IS NULL OR
							@v_code IS NULL OR
							@v_direction IS NULL OR
							@v_event IS NULL OR
							@v_delai IS NULL
						BEGIN
							SET @v_retour = @FORMAT_INCORRECT
							SET @v_fileError = 1
						END
						ELSE
						BEGIN
							DELETE DATA_ID_TABLE WHERE DATA_ID = @v_num
							
							IF @v_type = @TYPE_AUTOMATE
							BEGIN
								IF EXISTS (SELECT 1 FROM VARIABLE_AUTOMATE_OPC WHERE VAO_ID = @v_num AND VAO_INTERFACE <> @v_int_id_phys)
								BEGIN
									SET @v_retour = @NB_EXIST
									SET @v_fileError = 1
								END
								ELSE
								BEGIN
									IF NOT EXISTS ( SELECT 1 FROM VARIABLE_AUTOMATE
													LEFT OUTER JOIN VARIABLE_AUTOMATE_OPC ON VAO_ID = VAU_ID
													LEFT OUTER JOIN LIBELLE ON LIB_TRADUCTION = VAU_IdTraduction
													WHERE VAU_ID = @v_num AND VAU_SENS LIKE @v_direction AND VAU_EVENT = @v_event AND VAU_DELAI = @v_delai
													AND VAO_CODE = @v_code
													AND LIB_LANGUE LIKE @v_lan_id AND LIB_LIBELLE = @v_libelle)
									BEGIN
										SELECT @v_trad = VAU_IdTraduction FROM VARIABLE_AUTOMATE WHERE VAU_ID = @v_num;
										IF @v_trad IS NOT NULL
										BEGIN
											-- modification de variable
											SET @v_nb_modified = @v_nb_modified + 1
											
											UPDATE VARIABLE_AUTOMATE
												SET VAU_SENS = @v_direction, VAU_EVENT = @v_event, VAU_DELAI = @v_delai
												WHERE VAU_ID = @v_num
											
											SET @v_error = @@ERROR
											IF @v_error = 0
											BEGIN
												UPDATE VARIABLE_AUTOMATE_OPC SET VAO_CODE = @v_code WHERE VAO_ID = @v_num
												SET @v_error = @@ERROR
												IF @v_error = 0
												BEGIN
													UPDATE LIBELLE SET LIB_LIBELLE = @v_libelle
														WHERE LIB_TRADUCTION = @v_trad AND LIB_LANGUE = @v_lan_id
													SET @v_error = @@ERROR
												END
											END
										END
										ELSE
										BEGIN
											-- nouvelle variable
											SET @v_nb_inserted = @v_nb_inserted + 1
											SELECT @v_int_id_log = INT_ID_LOG FROM INTERFACE WHERE INT_ID_PHYS = @v_int_id_phys
											
											EXEC @v_error = LIB_TRADUCTION 0, @v_lan_id, @v_libelle, @v_trad out
											IF @v_error = 0
											BEGIN
												INSERT INTO VARIABLE_AUTOMATE
													(VAU_ID, VAU_VALEUR, VAU_AECRIRE, VAU_ALIRE, VAU_SENS, VAU_IDINTERFACE, VAU_EVENT,
													 VAU_IdTraduction, VAU_DELAI, VAU_DATE)
													VALUES (@v_num, '', 0, 0, @v_direction,
															@v_int_id_log, @v_event, @v_trad, @v_delai, NULL)
												SET @v_error = @@ERROR
												
												IF @v_error = 0
												BEGIN
													INSERT INTO VARIABLE_AUTOMATE_OPC (VAO_ID, VAO_CODE, VAO_INTERFACE, VAO_QUALITE)
														VALUES(@v_num, @v_code, @v_int_id_phys, CASE @v_direction WHEN 'I' THEN 0 ELSE 192 END)
													SET @v_error = @@ERROR
												END
											END
										END
									END
								END
							END
							ELSE IF @v_type = @TYPE_ES
							BEGIN
								IF EXISTS (SELECT 1 FROM ENTREE_SORTIE_OPC WHERE ESP_ID = @v_num AND ESP_INTERFACE <> @v_int_id_phys)
								BEGIN
									SET @v_retour = @NB_EXIST
									SET @v_fileError = 1
								END
								ELSE
								BEGIN
									IF NOT EXISTS ( SELECT * FROM ENTREE_SORTIE
													LEFT OUTER JOIN ENTREE_SORTIE_OPC ON ESL_ID = ESP_ID
													LEFT OUTER JOIN LIBELLE ON LIB_TRADUCTION = ESL_IDTRADUCTION
													WHERE ESL_ID = @v_num AND ESL_SENS LIKE @v_direction AND ESL_ALARM = @v_event AND ESL_DELAI = @v_delai
													AND ESP_CODE = @v_code
													AND LIB_LANGUE LIKE @v_lan_id AND LIB_LIBELLE = @v_libelle)
									BEGIN
										
										SELECT @v_trad = ESL_IDTRADUCTION FROM ENTREE_SORTIE WHERE ESL_ID = @v_num
										IF @v_trad IS NOT NULL
										BEGIN
											-- modification de l'ES
											SET @v_nb_modified = @v_nb_modified + 1
											
											UPDATE ENTREE_SORTIE
												SET ESL_SENS = @v_direction, ESL_ALARM = @v_event, ESL_DELAI = @v_delai
												WHERE ESL_ID = @v_num
											
											SET @v_error = @@ERROR
											IF @v_error = 0
											BEGIN
												UPDATE ENTREE_SORTIE_OPC SET ESP_CODE = @v_code WHERE ESP_ID = @v_num
												
												SET @v_error = @@ERROR
												IF @v_error = 0
												BEGIN
													UPDATE LIBELLE SET LIB_LIBELLE = @v_libelle
														WHERE LIB_TRADUCTION = @v_trad AND LIB_LANGUE = @v_lan_id
													SET @v_error = @@ERROR
												END
											END
										END
										ELSE
										BEGIN
											-- nouvelle ES
											SET @v_nb_inserted = @v_nb_inserted + 1
											SELECT @v_int_id_log = INT_ID_LOG FROM INTERFACE WHERE INT_ID_PHYS = @v_int_id_phys
											
											EXEC @v_error = LIB_TRADUCTION 0, @v_lan_id, @v_libelle, @v_trad out
											IF @v_error = 0
											BEGIN
												INSERT INTO ENTREE_SORTIE
													(ESL_ID, ESL_INTERFACE, ESL_ETAT, ESL_CHANGED, ESL_ALARM, ESL_SENS,
													 ESL_IDTRADUCTION, ESL_DELAI, ESL_DATE)
													VALUES (@v_num, @v_int_id_log, 0, 0, @v_event,
															@v_direction, @v_trad, @v_delai, NULL)
												SET @v_error = @@ERROR
												
												IF @v_error = 0
												BEGIN
													INSERT INTO ENTREE_SORTIE_OPC
														(ESP_ID, ESP_CODE, ESP_INTERFACE, ESP_QUALITE)
														VALUES(@v_num, @v_code, @v_int_id_phys, CASE @v_direction WHEN 'O' THEN 192 ELSE 0 END)
													SET @v_error = @@ERROR
												END
											END
										END
									END
								END
							END
						END
					END
						
					FETCH NEXT FROM c_data_file INTO @v_line
				END
				CLOSE c_data_file
				DEALLOCATE c_data_file
			END
			
			DROP TABLE #DATA_FILE
		END
				
		IF @v_fileError = 0
		BEGIN
			IF @v_fileFound = 0
				SET @v_retour = 907
			ELSE IF @v_error = 0
			BEGIN
				-- suppression de la BDD des variables / ES supprimees
				SELECT @v_nb_deleted = COUNT(DATA_ID) FROM DATA_ID_TABLE
				
				DECLARE c_data_opc CURSOR LOCAL FOR SELECT DATA_ID FROM DATA_ID_TABLE FOR UPDATE
				OPEN c_data_opc
				FETCH NEXT FROM c_data_opc INTO @v_data_id
				WHILE ((@@FETCH_STATUS = 0) AND (@v_error = 0))
				BEGIN
					
					IF @v_type = @TYPE_AUTOMATE
					BEGIN
						SELECT @v_trad = VAU_IdTraduction FROM VARIABLE_AUTOMATE WHERE VAU_ID = @v_data_id
					
						DELETE VARIABLE_AUTOMATE_OPC WHERE VAO_ID = @v_data_id
						
						SET @v_error = @@ERROR
						IF @v_error = 0
							DELETE VARIABLE_AUTOMATE WHERE VAU_ID = @v_data_id
					END
					ELSE IF @v_type = @TYPE_ES
					BEGIN
						SELECT @v_trad = ESL_IDTRADUCTION FROM ENTREE_SORTIE WHERE ESL_ID = @v_data_id
					
						DELETE ENTREE_SORTIE_OPC WHERE ESP_ID = @v_data_id
						
						SET @v_error = @@ERROR
						IF @v_error = 0
							DELETE ENTREE_SORTIE WHERE ESL_ID = @v_data_id
					END
					
					SET @v_error = @@ERROR
						
					IF @v_error = 0
						EXEC @v_error = LIB_TRADUCTION 2, NULL, NULL, @v_trad out

					FETCH NEXT FROM c_data_opc INTO @v_data_id
				END
				CLOSE c_data_opc
				DEALLOCATE c_data_opc
			END
		END
		
		DROP TABLE DATA_ID_TABLE
	END -- fin import
	
	ELSE IF @v_action = @ACT_EXPORT
	BEGIN
		CREATE TABLE #RESULT (LINE varchar(8000))
		
		IF @v_type = @TYPE_AUTOMATE
		BEGIN
			DECLARE c_data_opc CURSOR LOCAL FOR 
				SELECT VAU_ID, VAU_SENS, VAU_EVENT, VAU_DELAI, VAO_CODE, LIB_LIBELLE
				FROM VARIABLE_AUTOMATE_OPC
				LEFT OUTER JOIN VARIABLE_AUTOMATE ON VAO_ID = VAU_ID
				LEFT OUTER JOIN LIBELLE ON LIB_TRADUCTION = VAU_IdTraduction AND LIB_LANGUE = @v_lan_id
				WHERE VAO_INTERFACE = @v_int_id_phys
			FOR UPDATE
		END
		ELSE IF @v_type = @TYPE_ES
		BEGIN
			DECLARE c_data_opc CURSOR LOCAL FOR 
				SELECT ESL_ID, ESL_SENS, ESL_ALARM, ESL_DELAI, ESP_CODE, LIB_LIBELLE
				FROM ENTREE_SORTIE_OPC
				LEFT OUTER JOIN ENTREE_SORTIE ON ESP_ID = ESL_ID
				LEFT OUTER JOIN LIBELLE ON LIB_TRADUCTION = ESL_IDTRADUCTION AND LIB_LANGUE = @v_lan_id
				WHERE ESP_INTERFACE = @v_int_id_phys
			FOR UPDATE
		END

		INSERT INTO #RESULT (LINE) VALUES(@FILE_HEADER)
		SET @v_error = @@ERROR
		
		OPEN c_data_opc
		FETCH NEXT FROM c_data_opc INTO @v_num, @v_direction, @v_event, @v_delai, @v_code, @v_libelle
		
		WHILE ((@@FETCH_STATUS = 0) AND (@v_error = 0))
		BEGIN
			SET @v_line =	@v_num + ';' +
							@v_libelle + ';' +
							@v_code + ';' +
							@v_direction + ';' +
							@v_event + ';' +
							@v_delai;

			SET @v_error = @@ERROR

			IF @v_error = 0
			BEGIN
				INSERT INTO #RESULT (LINE) VALUES(@v_line)
				SET @v_error = @@ERROR
			END
			
			FETCH NEXT FROM c_data_opc INTO @v_num, @v_direction, @v_event, @v_delai, @v_code, @v_libelle
		END

		CLOSE c_data_opc
		DEALLOCATE c_data_opc
		
		SELECT LINE FROM #RESULT
		
		DROP TABLE #RESULT
	END


	IF @v_error = 0 AND @v_fileError = 0
		SET @v_retour = 0
		
	IF @v_error <> 0 OR @v_fileError <> 0
		ROLLBACK TRAN
	ELSE
		COMMIT TRAN
	RETURN @v_error

