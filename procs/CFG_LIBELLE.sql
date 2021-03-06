SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF

-----------------------------------------------------------------------------------------
-- Procédure		: CFG_LIBELLE
-- Paramètre d'entrée	: @v_action : Action à mener
--			  @v_type : Type
--				0 : Traduction des libellés spécifiques
--				1 : Traduction des libellés standards
--				2 : Traduction des nouveaux libellés standards
--			  @v_lan_utilisateur : Identifiant langue utilisateur
--			  @v_lan_traduire : Identifiant langue à traduire
--			  @v_libelle : Libellé traduit ou à traduire
--			  @v_traduction : Identifiant traduit ou à traduire
-- Paramètre de sortie	: 
-- Descriptif		: Gestion de la traduction des libellés de traduction
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[CFG_LIBELLE]
	@v_action smallint,
	@v_type tinyint = 0,
	@v_lan_utilisateur varchar(3),
	@v_lan_traduire varchar(3),
	@v_libelle varchar(8000),
	@v_traduction varchar(8000)
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

DECLARE
	@v_tra_id int,
	@v_lib_traduction int,
	@v_lib_libelle varchar(8000)

	IF @v_action = 0
	BEGIN
		SELECT @v_traduction = NULL
		DECLARE @libelle TABLE (LIB_TRADUCTION varchar(3500), LIB_LIBELLE varchar(3500), TRA_ID int)
		DECLARE c_libelle CURSOR LOCAL FAST_FORWARD FOR SELECT LIB_LIBELLE, LIB_TRADUCTION
			FROM LIBELLE WHERE LIB_LANGUE = @v_lan_utilisateur
			AND (@v_type = 0 OR (LIB_TRADUCTION >= 0 AND @v_type >= 1))
			ORDER BY CONVERT(varbinary(8000), LIB_LIBELLE), CASE @v_type WHEN 0 THEN -LIB_TRADUCTION ELSE LIB_TRADUCTION END
		OPEN c_libelle
		FETCH NEXT FROM c_libelle INTO @v_lib_libelle, @v_lib_traduction
		IF @@FETCH_STATUS = 0
		BEGIN
			SELECT @v_tra_id = @v_lib_traduction
			SELECT @v_libelle = @v_lib_libelle
			WHILE @@FETCH_STATUS = 0
			BEGIN
				IF CONVERT(varbinary(8000), @v_libelle) <> CONVERT(varbinary(8000), @v_lib_libelle)
				BEGIN
					IF @v_traduction IS NOT NULL
						INSERT INTO @libelle (LIB_TRADUCTION, LIB_LIBELLE, TRA_ID)
							SELECT @v_traduction, LIB_LIBELLE, @v_tra_id FROM LIBELLE WHERE LIB_TRADUCTION = @v_tra_id AND LIB_LANGUE = @v_lan_traduire
					SELECT @v_tra_id = @v_lib_traduction
					SELECT @v_libelle = @v_lib_libelle
					IF ((@v_lib_traduction < 0 AND @v_type = 0) OR (@v_lib_traduction >= 0 AND @v_type >= 1))
						SELECT @v_traduction = CONVERT(varchar, @v_lib_traduction)
					ELSE
						SELECT @v_traduction = NULL
				END
				ELSE
				BEGIN
					IF ((@v_lib_traduction < 0 AND @v_type = 0) OR (@v_lib_traduction >= 0 AND @v_type >= 1))
					BEGIN
						IF @v_traduction IS NULL
							SELECT @v_traduction = CONVERT(varchar, @v_lib_traduction)
						ELSE
							SELECT @v_traduction = @v_traduction + ',' + CONVERT(varchar, @v_lib_traduction)
						IF @v_type IN (0, 1) AND @v_tra_id <> @v_lib_traduction AND EXISTS (SELECT 1 FROM LIBELLE WHERE LIB_TRADUCTION = @v_lib_traduction AND LIB_LANGUE = @v_lan_traduire
							AND (LIB_LIBELLE IS NULL OR LIB_LIBELLE = ''))
							UPDATE LIBELLE SET LIB_LIBELLE = (SELECT LIB_LIBELLE FROM LIBELLE WHERE LIB_TRADUCTION = @v_tra_id AND LIB_LANGUE = @v_lan_traduire)
								WHERE LIB_TRADUCTION = @v_lib_traduction AND LIB_LANGUE = @v_lan_traduire
					END
				END
				FETCH NEXT FROM c_libelle INTO @v_lib_libelle, @v_lib_traduction
			END
			IF @v_traduction IS NOT NULL
				INSERT INTO @libelle (LIB_TRADUCTION, LIB_LIBELLE, TRA_ID)
					SELECT @v_traduction, LIB_LIBELLE, @v_tra_id FROM LIBELLE WHERE LIB_TRADUCTION = @v_tra_id AND LIB_LANGUE = @v_lan_traduire
		END
		CLOSE c_libelle
		DEALLOCATE c_libelle
		IF @v_type = 0
			SELECT LIB_TRADUCTION, LIB_LIBELLE FROM @libelle
		ELSE IF @v_type = 1
			SELECT LIB_TRADUCTION + '=' + LIB_LIBELLE FROM @libelle
		ELSE IF @v_type = 2
			SELECT T.LIB_TRADUCTION + '=' + (SELECT U.LIB_LIBELLE FROM LIBELLE U WHERE U.LIB_TRADUCTION = T.TRA_ID AND U.LIB_LANGUE = @v_lan_utilisateur) COLLATE database_default
				FROM @libelle T WHERE (T.LIB_LIBELLE IS NULL) OR (T.LIB_LIBELLE = '')
	END
	ELSE IF @v_action = 1
		EXEC ('UPDATE LIBELLE SET LIB_LIBELLE = ''' + @v_libelle + ''' WHERE LIB_TRADUCTION IN (' + @v_traduction + ') AND LIB_LANGUE = ''' + @v_lan_traduire + '''')

