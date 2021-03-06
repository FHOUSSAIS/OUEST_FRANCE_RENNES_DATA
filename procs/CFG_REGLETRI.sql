SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF


-----------------------------------------------------------------------------------------
-- Procédure		: CFG_REGLETRI
-- Paramètre d'entrées	: @v_action : Action à mener
--			  @v_reg_idregle : Règle
--			  @v_lan_id : Identifiant langue
-- Paramètre de sorties	: @v_retour : Code de retour
--			  @v_sql : SQL
-- Descriptif		: Gestion du texte SQL d'un tri
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[CFG_REGLETRI]
	@v_action smallint,
	@v_reg_idregle int,
	@v_sql varchar(8000) out,
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
	@v_error int,
	@v_tri_idtri int,
	@v_tri varchar(8000),
	@v_cri_idcritere int,
	@v_cri_libelle varchar(8000),
	@v_sen_idsens tinyint,
	@v_sen_libelle varchar(10),
	@v_charindex int,
	@v_art_position tinyint

	SELECT @v_retour = 113
	SELECT @v_error = 0
	IF @v_action = 0
	BEGIN
		SELECT @v_sql = ''
		DECLARE c_tri CURSOR LOCAL FOR SELECT '"' + LIB_LIBELLE + '"' + ' ' + SEN_LIBELLE
			FROM ASSOCIATION_REGLE_TRI, TRI, CRITERE, LIBELLE, SENS
			WHERE ART_IDREGLE = @v_reg_idregle AND TRI_IDTRI = ART_IDTRI AND CRI_IDCRITERE = TRI_IDCRITERE
			AND SEN_IDSENS = TRI_IDSENS AND LIB_LANGUE = @v_lan_id AND LIB_TRADUCTION = CRI_IDTRADUCTIONLIBELLE
			ORDER BY ART_POSITION
		OPEN c_tri
		FETCH NEXT FROM c_tri INTO @v_tri
		WHILE @@FETCH_STATUS = 0
		BEGIN
			IF @v_sql <> ''
				SELECT @v_sql = @v_sql + ', ' + @v_tri
			ELSE
				SELECT @v_sql = @v_tri
			FETCH NEXT FROM c_tri INTO @v_tri
		END
		CLOSE c_tri
		DEALLOCATE c_tri
		IF @v_sql = ''
			SELECT @v_sql = '...'
		SELECT @v_retour = 0
	END
	ELSE IF @v_action = 1
	BEGIN
		BEGIN TRAN
		IF @v_sql = '...'
			SELECT @v_sql = ''
		DELETE ASSOCIATION_REGLE_TRI WHERE ART_IDREGLE = @v_reg_idregle
		IF @v_sql <> ''
		BEGIN
			SELECT @v_art_position = 1
			SELECT @v_charindex = CHARINDEX(',', @v_sql)
			WHILE (((@v_charindex <> 0) OR (@v_sql <> '')) AND (@v_error = 0) AND (@v_retour = 113))
			BEGIN
				SELECT @v_cri_libelle = ''
				SELECT @v_sen_libelle = ''
				IF @v_charindex <> 0
				BEGIN
					SELECT @v_tri = SUBSTRING(@v_sql, 1, @v_charindex - 1)
					SELECT @v_sql = SUBSTRING(@v_sql, @v_charindex + 2, LEN(@v_sql) - @v_charindex)
				END
				ELSE
				BEGIN
					SELECT @v_tri = @v_sql
					SELECT @v_sql = ''
				END
				DECLARE c_sens CURSOR LOCAL FOR SELECT SEN_IDSENS, SEN_LIBELLE FROM SENS
				OPEN c_sens
				FETCH NEXT FROM c_sens INTO @v_sen_idsens, @v_sen_libelle
				WHILE @@FETCH_STATUS = 0
				BEGIN
					SELECT @v_charindex = CHARINDEX(' ' + @v_sen_libelle, @v_tri)
					IF @v_charindex <> 0
					BEGIN
						SELECT @v_cri_libelle = SUBSTRING(@v_tri, 2, @v_charindex - 3)
						BREAK
					END
					FETCH NEXT FROM c_sens INTO @v_sen_idsens, @v_sen_libelle
				END
				CLOSE c_sens
				DEALLOCATE c_sens
				SELECT TOP 1 @v_cri_idcritere = CRI_IDCRITERE FROM CRITERE, LIBELLE WHERE LIB_LANGUE = @v_lan_id AND LIB_LIBELLE = @v_cri_libelle AND CRI_IDTRADUCTIONLIBELLE = LIB_TRADUCTION
				IF @@ROWCOUNT <> 0
				BEGIN
					SELECT @v_tri_idtri = TRI_IDTRI FROM TRI WHERE TRI_IDCRITERE = @v_cri_idcritere AND TRI_IDSENS = @v_sen_idsens
					IF @@ROWCOUNT <> 0

					BEGIN
						IF NOT EXISTS (SELECT 1 FROM ASSOCIATION_REGLE_TRI WHERE ART_IDREGLE = @v_reg_idregle AND ART_IDTRI = @v_tri_idtri)
						BEGIN
							INSERT INTO ASSOCIATION_REGLE_TRI (ART_IDREGLE, ART_IDTRI, ART_POSITION, ART_SYSTEME) VALUES (@v_reg_idregle, @v_tri_idtri, @v_art_position, 0)
							SELECT @v_error = @@ERROR
							IF @v_error = 0
								SELECT @v_art_position = @v_art_position + 1
						END
						ELSE
							SELECT @v_retour = 117
					END
					ELSE
						SELECT @v_retour = 116
				END
				ELSE
					SELECT @v_retour = 116
				SELECT @v_charindex = CHARINDEX(',', @v_sql)
			END
		END
		IF ((@v_retour = 113) AND (@v_error = 0))
			SELECT @v_retour = 0
		IF ((@v_retour <> 0) OR (@v_error <> 0))
			ROLLBACK TRAN
		ELSE
			COMMIT TRAN
	END
	RETURN @v_error

