SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER ON


-----------------------------------------------------------------------------------------
-- Procédure		: CFG_TRI
-- Paramètre d'entrées	: @v_action : Action à mener
--			  @v_tri_idtri : Identifiant
--			  @v_tri_idcritere : Critère
--			  @v_tri_idsens : Sens
-- Paramètre de sorties	: @v_retour : Code de retour
-- Descriptif		: Gestion des tris
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[CFG_TRI]
	@v_action smallint,
	@v_tri_idtri int,
	@v_tri_idcritere int,
	@v_tri_idsens tinyint,
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
	@v_triidtri int

	BEGIN TRAN
	SELECT @v_retour = 113
	SELECT @v_error = 0
	IF @v_action = 0
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM TRI WHERE TRI_IDCRITERE = @v_tri_idcritere AND TRI_IDSENS = @v_tri_idsens)
		BEGIN
			INSERT INTO TRI (TRI_IDTRI, TRI_IDCRITERE, TRI_IDSENS, TRI_SYSTEME) SELECT (SELECT CASE SIGN(MIN(TRI_IDTRI)) WHEN -1 THEN MIN(TRI_IDTRI) - 1 ELSE -1 END FROM TRI),
				@v_tri_idcritere, @v_tri_idsens, 0
			SELECT @v_error = @@ERROR
			IF @v_error = 0
				SELECT @v_retour = 0
		END
		ELSE
			SELECT @v_retour = 117
	END
	ELSE IF @v_action = 1
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM TRI WHERE TRI_IDTRI <> @v_tri_idtri AND TRI_IDCRITERE = @v_tri_idcritere AND TRI_IDSENS = @v_tri_idsens)
		BEGIN
			UPDATE TRI SET TRI_IDCRITERE = @v_tri_idcritere, TRI_IDSENS = @v_tri_idsens
				WHERE TRI_IDTRI = @v_tri_idtri
			SELECT @v_error = @@ERROR
			IF @v_error = 0
				SELECT @v_retour = 0
		END
		ELSE
			SELECT @v_retour = 117
	END
	ELSE IF @v_action = 2
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM ASSOCIATION_REGLE_TRI WHERE ART_IDTRI = @v_tri_idtri)
		BEGIN
			DELETE TRI WHERE TRI_IDTRI = @v_tri_idtri
			SELECT @v_error = @@ERROR
			IF @v_error =0
				SELECT @v_retour = 0
		END
		ELSE
			SELECT @v_retour = 114
	END
	ELSE IF @v_action = 3
	BEGIN
		DECLARE c_tri CURSOR LOCAL FOR SELECT TRI_IDTRI FROM TRI WHERE TRI_SYSTEME = 0 FOR UPDATE
		OPEN c_tri
		FETCH NEXT FROM c_tri INTO @v_triidtri
		WHILE ((@@FETCH_STATUS = 0) AND (@v_error = 0))
		BEGIN
			IF NOT EXISTS (SELECT 1 FROM ASSOCIATION_REGLE_TRI WHERE ART_IDTRI = @v_triidtri)
			BEGIN
				DELETE TRI WHERE CURRENT OF c_tri
				SELECT @v_error = @@ERROR
			END
			FETCH NEXT FROM c_tri INTO @v_triidtri
		END
		CLOSE c_tri
		DEALLOCATE c_tri
		SELECT @v_retour = 0
	END
	IF @v_error <> 0
		ROLLBACK TRAN
	ELSE
		COMMIT TRAN
	RETURN @v_error

