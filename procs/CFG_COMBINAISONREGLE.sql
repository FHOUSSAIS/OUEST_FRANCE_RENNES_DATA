SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF



-----------------------------------------------------------------------------------------
-- Procédure		: CFG_COMBINAISONREGLE
-- Paramètre d'entrées	: @v_action : Action à mener
--			  @v_ssaction : Sous action à mener
--			  @v_cdr_idcombinaison : Combinaison
--			  @v_cdr_idregle : Règle
--			  @v_cdr_position_regle : Position
--			  @v_cdr_idaction : Action
--			  @v_cdr_actif : Actif
-- Paramètre de sorties	: @v_retour : Code de retour
-- Descriptif		: Gestion des combinaisons
-----------------------------------------------------------------------------------------
-- Révision
-----------------------------------------------------------------------------------------
-- Date			: 12/07/2004
-- Auteur		: Cédric LE FRINGERE
-- Libellé			: Création de la procédure
-----------------------------------------------------------------------------------------
-- Date			: 08/04/2005
-- Auteur		: Cédric LE FRINGERE
-- Libellé			: Mise à jour code de retour
-----------------------------------------------------------------------------------------
-- Date			: 05/09/2005
-- Auteur		: Cédric LE FRINGERE
-- Libellé			: Correction position règle
-----------------------------------------------------------------------------------------
-- Date			: 25/08/2008
-- Auteur		: Cédric LE FRINGERE
-- Libellé			: Gestion de l'état actif/inactif
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[CFG_COMBINAISONREGLE]
	@v_action smallint,
	@v_ssaction smallint,
	@v_cdr_idcombinaison int,
	@v_cdr_idregle int,
	@v_cdr_position_regle tinyint,
	@v_cdr_idaction int,
	@v_cdr_actif bit,
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
	@v_old_cdr_position_regle tinyint

	BEGIN TRAN
	SET @v_retour = 113
	SET @v_error = 0
	IF @v_action = 0
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM COMBINAISON_DE_REGLE WHERE CDR_IDCOMBINAISON = @v_cdr_idcombinaison AND CDR_IDREGLE = @v_cdr_idregle)
		BEGIN
			INSERT INTO COMBINAISON_DE_REGLE (CDR_IDCOMBINAISON, CDR_IDREGLE, CDR_POSITION_REGLE, CDR_IDACTION, CDR_ACTIF)
				SELECT @v_cdr_idcombinaison, @v_cdr_idregle, ISNULL(MAX(CDR_POSITION_REGLE), 0) + 1, @v_cdr_idaction, 1 FROM COMBINAISON_DE_REGLE
				WHERE CDR_IDCOMBINAISON = @v_cdr_idcombinaison
			SET @v_error = @@ERROR
			IF @v_error = 0
				SET @v_retour = 0
		END
		ELSE
			SET @v_retour = 117
	END
	ELSE IF @v_action = 1
	BEGIN
		IF @v_ssaction = 0
		BEGIN
			SELECT @v_old_cdr_position_regle = CDR_POSITION_REGLE FROM COMBINAISON_DE_REGLE
				WHERE CDR_IDCOMBINAISON = @v_cdr_idcombinaison AND CDR_IDREGLE = @v_cdr_idregle
			IF @v_cdr_position_regle < @v_old_cdr_position_regle
			BEGIN
				UPDATE COMBINAISON_DE_REGLE SET CDR_POSITION_REGLE = CDR_POSITION_REGLE + 1
					WHERE CDR_IDCOMBINAISON = @v_cdr_idcombinaison AND CDR_POSITION_REGLE >= @v_cdr_position_regle
					AND CDR_POSITION_REGLE < @v_old_cdr_position_regle AND CDR_IDREGLE <> @v_cdr_idregle
				SET @v_error = @@ERROR
			END
			ELSE IF @v_cdr_position_regle > @v_old_cdr_position_regle
			BEGIN
				UPDATE COMBINAISON_DE_REGLE SET CDR_POSITION_REGLE = CDR_POSITION_REGLE - 1
					WHERE CDR_IDCOMBINAISON = @v_cdr_idcombinaison AND CDR_POSITION_REGLE > @v_old_cdr_position_regle
					AND CDR_POSITION_REGLE <= @v_cdr_position_regle AND CDR_IDREGLE <> @v_cdr_idregle
				SET @v_error = @@ERROR
			END
			IF @v_error = 0
			BEGIN
				IF NOT EXISTS (SELECT 1 FROM ACTION_REGLE, TYPE_ACTION_REGLE WHERE ARE_IDACTION = @v_cdr_idaction
					AND TAR_IDTYPE = ARE_IDTYPE AND TAR_IDTYPE = 4
					AND ARE_PARAMS = (SELECT COT_BASE_BASE FROM COMBINAISON, CONTEXTE WHERE COB_IDCOMBINAISON = @v_cdr_idcombinaison
					AND COT_ID = COB_IDCONTEXTE))
				BEGIN
					UPDATE COMBINAISON_DE_REGLE SET CDR_POSITION_REGLE = @v_cdr_position_regle, CDR_IDACTION = @v_cdr_idaction
						WHERE CDR_IDCOMBINAISON = @v_cdr_idcombinaison AND CDR_IDREGLE = @v_cdr_idregle
					SET @v_error = @@ERROR
					IF @v_error = 0
						SET @v_retour = 0
				END
				ELSE
					SET @v_retour = 793
			END
		END
		ELSE IF @v_ssaction = 1
		BEGIN
			UPDATE COMBINAISON_DE_REGLE SET CDR_ACTIF = @v_cdr_actif
				WHERE CDR_IDCOMBINAISON = @v_cdr_idcombinaison AND CDR_IDREGLE = @v_cdr_idregle
			SET @v_error = @@ERROR
			IF @v_error = 0
				SET @v_retour = 0
		END
	END
	ELSE IF @v_action = 2
	BEGIN
		DELETE COMBINAISON_DE_REGLE WHERE CDR_IDCOMBINAISON = @v_cdr_idcombinaison AND CDR_IDREGLE = @v_cdr_idregle
		SET @v_error = @@ERROR
		IF @v_error = 0
		BEGIN
			UPDATE COMBINAISON_DE_REGLE SET CDR_POSITION_REGLE = CDR_POSITION_REGLE - 1
				WHERE CDR_IDCOMBINAISON = @v_cdr_idcombinaison AND CDR_POSITION_REGLE > @v_cdr_position_regle
			SET @v_error = @@ERROR
			IF @v_error = 0
				SET @v_retour = 0
		END
	END
	IF @v_error <> 0
		ROLLBACK TRAN
	ELSE
		COMMIT TRAN
	RETURN @v_error

