SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF


-----------------------------------------------------------------------------------------
-- Procédure		: CFG_VUE
-- Paramètre d'entrées	: @v_vue_id : Identifiant
--			  @v_vue_ordre : Ordre
-- Paramètre de sorties	: @v_retour : Code de retour
-- Descriptif		: Gestion des vues
-----------------------------------------------------------------------------------------
-- Révision
-----------------------------------------------------------------------------------------
-- Version/ révision	: 1.00
-- Date			: 17/09/2004
-- Auteur		: Cédric LE FRINGERE
-- Libellé			: Création de la procédure
-----------------------------------------------------------------------------------------
-- Version/ révision	: 2.00
-- Date			: 08/04/2005
-- Auteur		: Cédric LE FRINGERE
-- Libellé			: Mise à jour code de retour
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[CFG_VUE]
	@v_vue_id int,
	@v_vue_ordre tinyint,
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
	@v_old_vue_ordre tinyint

	BEGIN TRAN
	SELECT @v_retour = 113
	SELECT @v_error = 0
	SELECT @v_old_vue_ordre = VUE_ORDRE FROM VUE WHERE VUE_ID = @v_vue_id
	IF @v_vue_ordre < @v_old_vue_ordre
	BEGIN
		UPDATE VUE SET VUE_ORDRE = VUE_ORDRE + 1 WHERE VUE_ID <> @v_vue_id AND VUE_ORDRE >= @v_vue_ordre AND VUE_TYPE_VUE IN (1, 3, 4)
			AND VUE_ORDRE < @v_old_vue_ordre
		SELECT @v_error = @@ERROR
	END
	ELSE IF @v_vue_ordre > @v_old_vue_ordre
	BEGIN
		UPDATE VUE SET VUE_ORDRE = VUE_ORDRE - 1 WHERE VUE_ID <> @v_vue_id AND VUE_ORDRE > @v_old_vue_ordre AND VUE_TYPE_VUE IN (1, 3, 4)
			AND VUE_ORDRE <= @v_vue_ordre
		SELECT @v_error = @@ERROR
	END
	IF @v_error = 0
	BEGIN
		UPDATE VUE SET VUE_ORDRE = @v_vue_ordre WHERE VUE_ID = @v_vue_id
		SELECT @v_error = @@ERROR
		IF @v_error = 0
			SELECT @v_retour = 0
	END
	IF @v_error <> 0
		ROLLBACK TRAN
	ELSE
		COMMIT TRAN
	RETURN @v_error

