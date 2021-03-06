SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF




-----------------------------------------------------------------------------------------
-- Procédure		: PRF_POSTE
-- Paramètre d'entrées	: @v_action : Action à mener
--			  @v_pst_id : Identifiant poste
--			  @v_pst_utilisateur : Utilisateur par défaut
-- Paramètre de sorties	: @v_retour : Code de retour
-- Descriptif		: Gestion des postes
-----------------------------------------------------------------------------------------
-- Révision
-----------------------------------------------------------------------------------------
-- Date			: 10/09/2008
-- Auteur		: Cédric LE FRINGERE
-- Libellé			: Création de la procédure
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[PRF_POSTE]
	@v_action smallint,
	@v_pst_id varchar(256),
	@v_pst_utilisateur varchar(16),
	@v_retour smallint out
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

DECLARE
	@v_error int

	BEGIN TRAN
	SET @v_retour = 113
	SET @v_error = 0
	IF @v_action = 0
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM POSTE WHERE PST_ID = @v_pst_id)
		BEGIN
			INSERT INTO POSTE (PST_ID) VALUES (@v_pst_id)
			SET @v_error = @@ERROR
			IF @v_error = 0
				SET @v_retour = 0
		END
		ELSE
			SELECT @v_retour = 117
	END
	ELSE IF @v_action = 1
	BEGIN
		UPDATE POSTE SET PST_UTILISATEUR = @v_pst_utilisateur WHERE PST_ID = @v_pst_id
		SET @v_error = @@ERROR
		IF @v_error = 0
			SET @v_retour = 0
	END
	ELSE IF @v_action = 2
	BEGIN
		DELETE POSTE WHERE PST_ID = @v_pst_id
		SET @v_error = @@ERROR
		IF @v_error = 0
			SET @v_retour = 0
	END
	IF @v_error <> 0
		ROLLBACK TRAN
	ELSE
		COMMIT TRAN
	RETURN @v_error

