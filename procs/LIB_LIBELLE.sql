SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF


-----------------------------------------------------------------------------------------
-- Procédure		: LIB_LIBELLE
-- Paramètre d'entrées	: @v_tra_id : Identifiant traduction
--			  @v_lan_id : Identifiant langue
--			  @v_lib_libelle : Libellé
-- Paramètre de sorties	: @v_retour : Code de retour
-- Descriptif		: Gestion des libellés de traduction
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[LIB_LIBELLE]
	@v_tra_id int,
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
	@v_error int,
	@v_local bit

	IF @@TRANCOUNT > 0
		SELECT @v_local = 0
	ELSE
	BEGIN
		SELECT @v_local = 1
		BEGIN TRAN LIBELLE
	END
	SELECT @v_retour = 113
	SELECT @v_error = 0
	UPDATE LIBELLE SET LIB_LIBELLE = @v_lib_libelle WHERE LIB_TRADUCTION = @v_tra_id AND LIB_LANGUE = @v_lan_id
	SELECT @v_error = @@ERROR
	IF @v_error = 0
		SELECT @v_retour = 0
	IF @v_local = 1
	BEGIN
		IF @v_error = 0
			COMMIT TRAN LIBELLE
		ELSE
		BEGIN
			SELECT @v_error = 0
			ROLLBACK TRAN LIBELLE
		END
	END
	RETURN @v_error

