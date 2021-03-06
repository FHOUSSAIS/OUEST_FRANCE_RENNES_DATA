SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF


-----------------------------------------------------------------------------------------
-- Procédure		: LIB_TRADUCTION
-- Paramètre d'entrées	: @v_action : Action à mener (0 : Ajouter, 2 : Supprimer, 3 : Tout supprimer)
--			  @v_lan_id : Identifiant langue
--			  @v_lib_libelle : Libellé
-- Paramètre de sorties	: @v_tra_id : Identifiant traduction
-- Descriptif		: Gestion des libellés de traduction
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[LIB_TRADUCTION]
	@v_action smallint,
	@v_lan_id varchar(3),
	@v_lib_libelle varchar(8000),
	@v_tra_id int out,
	@v_retour smallint = NULL out
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

DECLARE
	@v_error int,
	@v_local bit

	IF @@TRANCOUNT > 0
		SELECT @v_local = 0
	ELSE
	BEGIN
		SELECT @v_local = 1
		BEGIN TRAN TRADUCTION
	END
	SELECT @v_retour = 114
	SELECT @v_error = 0
	IF @v_action = 0
	BEGIN
		SELECT @v_tra_id = CASE SIGN(MIN(TRA_ID)) WHEN -1 THEN MIN(TRA_ID) - 1 ELSE -1 END FROM TRADUCTION
		INSERT INTO TRADUCTION (TRA_ID, TRA_SYSTEME) VALUES (@v_tra_id, 0)
		SELECT @v_error = @@ERROR
		IF @v_error = 0
		BEGIN
			INSERT INTO LIBELLE (LIB_TRADUCTION, LIB_LANGUE, LIB_LIBELLE)
				SELECT @v_tra_id, LAN_ID, CASE LAN_ID WHEN @v_lan_id THEN @v_lib_libelle ELSE '' END FROM LANGUE WHERE LAN_ACTIF = 1
			SELECT @v_error = @@ERROR
		END
	END
	ELSE IF @v_action IN (2, 3)
	BEGIN
		DELETE LIBELLE WHERE LIB_TRADUCTION = @v_tra_id
		SELECT @v_error = @@ERROR
		IF @v_error = 0
		BEGIN
			DELETE TRADUCTION WHERE TRA_ID = @v_tra_id
			SELECT @v_error = @@ERROR
		END
	END
	IF @v_error = 0
		SELECT @v_retour = 0
	IF @v_local = 1
	BEGIN
		IF @v_error = 0
			COMMIT TRAN TRADUCTION
		ELSE
		BEGIN
			SELECT @v_error = 0
			ROLLBACK TRAN TRADUCTION
		END
	END
	RETURN @v_error

