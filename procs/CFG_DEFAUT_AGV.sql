SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER ON

-----------------------------------------------------------------------------------------
-- Procédure		: CFG_DEFAUT_AGV
-- Paramètre d'entrées	: @v_action : Action à mener
--			  @v_file : Fichier des défauts
--			  @v_lan_id : Langue
-- Paramètre de sorties	: @v_retour : Code de retour
-- Descriptif		: Gestion des défauts
-- Note		: La variable @v_arretOutil permet la gestion de la compatibilité du fichier ba-dysf
--			  en version 15.02 et 15.03
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[CFG_DEFAUT_AGV]
	@v_action smallint,
	@v_dir varchar(8000),
	@v_lan_id varchar(3),
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
	@v_fileFound bit,
	@v_lineFeed varchar(1),
	@v_line varchar(8000),
	@v_file varchar(8000),
	@v_charindex int,
	@v_i int,
	@v_dag_id varchar(80),
	@v_dag_resolution varchar(8000),
	@v_dag_libelle varchar(8000),
	@v_tra_resolution int,
	@v_tra_libelle int,
	@v_exists int,
	@v_arretOutil bit,
	@v_dag_type varchar(6),
	@v_dag_arrettraction bit,
	@v_dag_arretoutil bit,
	@v_dag_signalisation bit,
	@v_dag_dialogue bit,
	@v_dag_rearmement bit,
	@v_dag_depannage bit,
	@v_dag_famille tinyint,
	@v_tag_id tinyint

	BEGIN TRAN
	SET @v_retour = 113
	SET @v_error = 0
	SET @v_exists = 0
	SET @v_arretOutil = 0
	SET @v_fileFound = 0
	
	-- Backup des id de defaut pour savoir lesquels ont ete supprimes
	SELECT DAG_ID INTO DEFAUT_AGV_TMP FROM DEFAUT_AGV
	
	
	--Boucle sur les fichiers du repertoire donne
	DECLARE c_typeAgv CURSOR LOCAL FOR SELECT TAG_ID FROM TYPE_AGV
	OPEN c_typeAgv
	FETCH NEXT FROM c_typeAgv INTO @v_tag_id
	WHILE ((@@FETCH_STATUS = 0) AND (@v_error = 0))
	BEGIN
	
		SET @v_file = @v_dir + '\ba-dysf_' + CONVERT(varchar, @v_tag_id)

		EXEC master.dbo.xp_fileexist @v_file, @v_exists out
		IF @v_exists = 1
		BEGIN
			SET @v_fileFound = 1
			CREATE TABLE #DEFAUT (LINE varchar(8000))
			SET @v_lineFeed = CHAR(10)
			EXEC ('BULK INSERT #DEFAUT FROM "' + @v_file + '" WITH (ROWTERMINATOR = ''' + @v_lineFeed + ''', CODEPAGE = ''ACP'')')
			SET @v_error = @@ERROR
			IF @v_error = 0
			BEGIN
				DECLARE c_defaut CURSOR LOCAL FOR SELECT LINE FROM #DEFAUT
				OPEN c_defaut
				FETCH NEXT FROM c_defaut INTO @v_line
				WHILE ((@@FETCH_STATUS = 0) AND (@v_error = 0))
				BEGIN
					IF SUBSTRING(@v_line, 1, 1) <> '#'
					BEGIN
						SET @v_i = 1
						SET @v_dag_id = NULL
						SET @v_dag_resolution = NULL
						SET @v_dag_libelle = NULL
						SET @v_tra_libelle = NULL
						SET @v_tra_resolution = NULL
						SET @v_charindex = CHARINDEX(CHAR(9), @v_line)
						
						WHILE ((@v_charindex <> 0) AND (@v_i <= 5))
						BEGIN
							IF @v_i = 1
							BEGIN
								SET @v_dag_id = SUBSTRING(@v_line, 2, @v_charindex - 3)
								SET @v_line = SUBSTRING(@v_line, @v_charindex + 1, LEN(@v_line) - @v_charindex)
							END
							ELSE
							BEGIN
								IF @v_i = 3
									SET @v_dag_libelle = SUBSTRING(@v_line, 2, @v_charindex - 3)
								ELSE IF @v_i = 4
									SET @v_dag_resolution = SUBSTRING(@v_line, 2, @v_charindex - 3)
								ELSE IF @v_i = 5
								BEGIN
									SET @v_dag_famille = CASE SUBSTRING(@v_line, 2, @v_charindex - 3) WHEN 'TRAJET' THEN 0
										WHEN 'INTERFACE' THEN 1
										WHEN 'INTRINSEQUE' THEN 2
										WHEN 'CHARGE' THEN 3 END
									IF @v_arretOutil = 1
										SET @v_dag_type = SUBSTRING(CONVERT(varchar, CONVERT(int, SUBSTRING(@v_line, @v_charindex + 1, LEN(@v_line) - @v_charindex)) + 1000000), 2, 6)
									ELSE
										SET @v_dag_type = SUBSTRING(CONVERT(varchar, CONVERT(int, SUBSTRING(@v_line, @v_charindex + 1, LEN(@v_line) - @v_charindex)) + 100000), 2, 5)
									SET @v_dag_arrettraction = SUBSTRING(@v_dag_type, 1, 1)
									IF @v_arretOutil = 1
										SET @v_dag_arretOutil = SUBSTRING(@v_dag_type, 2, 1)
									ELSE
										SET @v_dag_arretoutil = NULL
									SET @v_dag_signalisation = SUBSTRING(@v_dag_type, 2 + @v_arretOutil, 1)
									SET @v_dag_dialogue = SUBSTRING(@v_dag_type, 3 + @v_arretOutil, 1)
									SET @v_dag_rearmement = SUBSTRING(@v_dag_type, 4 + @v_arretOutil, 1)
									SET @v_dag_depannage = SUBSTRING(@v_dag_type, 5 + @v_arretOutil, 1)
								END
								SET @v_line = SUBSTRING(@v_line, @v_charindex + 1, LEN(@v_line) - @v_charindex)
							END
							SET @v_i = @v_i + 1
							SET @v_charindex = CHARINDEX(CHAR(9), @v_line)
						END
						
						
						-- ajout / modification du defaut
						IF ((@v_dag_id IS NOT NULL) AND (@v_dag_resolution IS NOT NULL) AND (@v_dag_libelle IS NOT NULL))
						BEGIN
							DELETE FROM DEFAUT_AGV_TMP WHERE DAG_ID = @v_dag_id
							
							SELECT @v_tra_libelle = DAG_IDTRADUCTIONLIBELLE, @v_tra_resolution = DAG_IDTRADUCTIONRESOLUTION FROM DEFAUT_AGV WHERE DAG_ID = @v_dag_id
							
							IF ( (@v_tra_libelle IS NOT NULL) AND (@v_tra_resolution IS NOT NULL) )
							BEGIN
								-- defaut deja existant, on update
								UPDATE DEFAUT_AGV
									SET DAG_ARRETTRACTION = @v_dag_arrettraction,
										DAG_ARRETOUTIL = @v_dag_arretoutil,
										DAG_SIGNALISATION = @v_dag_signalisation,
										DAG_DIALOGUE = @v_dag_dialogue,
										DAG_REARMEMENT = @v_dag_rearmement,
										DAG_DEPANNAGE = @v_dag_depannage,
										DAG_FAMILLE = @v_dag_famille
									WHERE DAG_ID = @v_dag_id
								
								UPDATE LIBELLE SET LIB_LIBELLE = @v_dag_libelle
										WHERE LIB_TRADUCTION = @v_tra_libelle AND LIB_LANGUE = @v_lan_id
								SET @v_error = @@ERROR
								IF @v_error = 0
								BEGIN
									UPDATE LIBELLE SET LIB_LIBELLE = @v_dag_resolution WHERE LIB_TRADUCTION = @v_tra_resolution
										AND LIB_LANGUE = @v_lan_id
									SET @v_error = @@ERROR
								END
							END
							ELSE
							BEGIN
								-- nouveau defaut, on insert
								EXEC @v_error = LIB_TRADUCTION 0, @v_lan_id, @v_dag_resolution, @v_tra_resolution out
								IF @v_error = 0
								BEGIN
									EXEC @v_error = LIB_TRADUCTION 0, @v_lan_id, @v_dag_libelle, @v_tra_libelle out
									IF @v_error = 0
									BEGIN
										INSERT INTO DEFAUT_AGV (DAG_ID, DAG_IDTRADUCTIONLIBELLE, DAG_IDTRADUCTIONRESOLUTION,
											DAG_ARRETTRACTION, DAG_ARRETOUTIL, DAG_SIGNALISATION, DAG_DIALOGUE, DAG_REARMEMENT, DAG_DEPANNAGE, DAG_FAMILLE, DAG_REBOND, DAG_FURTIF)
											VALUES (@v_dag_id, @v_tra_libelle, @v_tra_resolution,
											@v_dag_arrettraction, @v_dag_arretoutil, @v_dag_signalisation, @v_dag_dialogue, @v_dag_rearmement, @v_dag_depannage, @v_dag_famille, 5, 5)
										SET @v_error = @@ERROR
									END
								END
							END
						END
					END
					ELSE IF CHARINDEX('arretOutil', @v_line) <> 0
						SET @v_arretOutil = 1
					FETCH NEXT FROM c_defaut INTO @v_line
				END
				CLOSE c_defaut
				DEALLOCATE c_defaut
			END
			DROP TABLE #DEFAUT
			IF @v_error = 0
				SET @v_retour = 0
		END
			
	FETCH NEXT FROM c_typeAgv INTO @v_tag_id
	END
	CLOSE c_typeAgv
	DEALLOCATE c_typeAgv

	IF @v_fileFound = 0
		SET @v_retour = 907
	ELSE IF @v_action = 0
	BEGIN
		-- suppression de la BDD des defaut supprimes
		DECLARE c_defaut CURSOR LOCAL FOR SELECT DAG_ID FROM DEFAUT_AGV_TMP FOR UPDATE
		OPEN c_defaut
		FETCH NEXT FROM c_defaut INTO @v_dag_id
		WHILE ((@@FETCH_STATUS = 0) AND (@v_error = 0))
		BEGIN
			SELECT @v_dag_libelle = DAG_IDTRADUCTIONLIBELLE, @v_dag_resolution = DAG_IDTRADUCTIONRESOLUTION FROM DEFAUT_AGV WHERE DAG_ID = @v_dag_id
		
			DELETE DEFAUT_AGV WHERE DAG_ID = @v_dag_id
			SET @v_error = @@ERROR
			IF @v_error = 0
			BEGIN
				EXEC @v_error = LIB_TRADUCTION 2, NULL, NULL, @v_dag_resolution out
				IF @v_error = 0
					EXEC @v_error = LIB_TRADUCTION 2, NULL, NULL, @v_dag_libelle out
			END
			FETCH NEXT FROM c_defaut INTO @v_dag_id
		END
		CLOSE c_defaut
		DEALLOCATE c_defaut
	END
	
	DROP TABLE DEFAUT_AGV_TMP
		
	IF @v_error <> 0
		ROLLBACK TRAN
	ELSE
		COMMIT TRAN
	RETURN @v_error

