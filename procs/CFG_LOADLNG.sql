SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF

-----------------------------------------------------------------------------------------
-- Procédure		: CFG_LOADLNG
-- Paramètre d'entrée	:
--				@v_file : path du fichier
-- Descriptif		: charge le fichier donne, cherche la section [IHM]
--					et charge toutes les traductions qui suivent pour la langue donnee
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[CFG_LOADLNG]
	@v_file varchar(8000)
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

-- Déclaration des variables
DECLARE
	@v_lang varchar(3),
	@v_error smallint,
	@v_exists int,
	@v_lineFeed varchar(1) = CHAR(10),
	@v_line varchar(8000),
	@v_str varchar(8000),
	@v_idTrad varchar(8000),
	@v_libelle varchar(8000),
	@v_globalSection bit = 0,
	@v_ihmSection bit = 0,
	@v_charindex int,
	@v_langExists bit = 0

	EXEC master.dbo.xp_fileexist @v_file, @v_exists out
	IF @v_exists = 1
	BEGIN

		CREATE TABLE #DATA_FILE (LINE varchar(8000))

		
		EXEC ('BULK INSERT #DATA_FILE FROM "' + @v_file + '" WITH (ROWTERMINATOR = ''' + @v_lineFeed + ''', CODEPAGE = ''ACP'')')
		SET @v_error = @@ERROR
		IF @v_error = 0
		BEGIN
			DECLARE c_data_file CURSOR LOCAL FAST_FORWARD FOR SELECT LINE FROM #DATA_FILE
			OPEN c_data_file
			FETCH NEXT FROM c_data_file INTO @v_line
			
			WHILE (@@FETCH_STATUS = 0) AND (@v_error = 0)
			BEGIN
				SET @v_str = LTRIM(RTRIM(@v_line))
				IF @v_str NOT LIKE ''
				BEGIN
					-- recherche de la section (ecriture speciale car [ est un caractere reserve)
					IF @v_str LIKE '[[]GLOBAL]'
						SET @v_globalSection = 1
					ELSE IF @v_str LIKE '[[]IHM]'
						SET @v_ihmSection = 1
					ELSE IF @v_str LIKE '[[]%'
					BEGIN
						SET @v_globalSection = 0
						SET @v_ihmSection = 0
					END
					ELSE
					BEGIN
						-- lecture de la section [Global]
						IF @v_globalSection = 1
						BEGIN
							SET @v_charindex = CHARINDEX('=', @v_str)
							IF @v_charindex <> 0
							BEGIN
								IF SUBSTRING(@v_str, 1, @v_charindex - 1) LIKE 'LANGUE'
								BEGIN
									SET @v_lang = SUBSTRING(@v_str, @v_charindex + 1, LEN(@v_str) - @v_charindex)
									SET @v_globalSection = 0
									
									SELECT @v_langExists = LAN_ACTIF from LANGUE WHERE LAN_ID = @v_lang
									IF @v_langExists <> 1
										SET @v_error = 1
								END
							END
						END

						-- lecture de la section [IHM]
						IF @v_ihmSection = 1
						BEGIN
							SET @v_charindex = CHARINDEX('=', @v_str)
							IF @v_charindex <> 0
							BEGIN
								SET @v_idTrad = SUBSTRING(@v_str, 1, @v_charindex - 1)
								SET @v_libelle = REPLACE( SUBSTRING(@v_str, @v_charindex + 1, LEN(@v_str) - @v_charindex), '''', '''''' )
								EXEC CFG_LIBELLE @v_action = 1,
												 @v_type = NULL,
												 @v_lan_utilisateur = NULL,
												 @v_lan_traduire = @v_lang,
												 @v_libelle = @v_libelle,
												 @v_traduction = @v_idTrad
								SET @v_error = @@ERROR
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

	
	RETURN 0

