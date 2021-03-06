SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER ON

-----------------------------------------------------------------------------------------
-- Procédure		: CFG_COMBINAISON
-- Paramètre d'entrées	: @v_action : Action à mener
--			  @v_cob_idcombinaison : Identifiant
--			  @v_cob_idjeu : Jeu
--			  @v_cob_idcontexte : Contexte
--			  @v_cob_action : Action
--			  @v_cob_ordre : Ordre d'affichage
-- Paramètre de sorties	: @v_retour : Code de retour
-- Descriptif		: Gestion des combinaisons
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[CFG_COMBINAISON]
	@v_action smallint,
	@v_ssaction smallint,
	@v_cob_idcombinaison int out,
	@v_cob_idjeu int,
	@v_cob_idcontexte int,
	@v_cob_action int,
	@v_cob_ordre tinyint,
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
	@v_cot_base_sys bigint,
	@v_cot_base_base bigint,
	@v_old_cob_idjeu int,
	@v_old_cob_ordre tinyint

	BEGIN TRAN
	SET @v_retour = 113
	SET @v_error = 0
	IF @v_action = 0
	BEGIN
		SELECT @v_cot_base_sys = COT_BASE_SYS, @v_cot_base_base = COT_BASE_BASE
			FROM CONTEXTE WHERE COT_ID = @v_cob_idcontexte
		IF NOT EXISTS (SELECT 1 FROM COMBINAISON, CONTEXTE WHERE COB_IDJEU = @v_cob_idjeu AND COT_ID = COB_IDCONTEXTE
			AND COT_BASE_SYS = @v_cot_base_sys AND COT_BASE_BASE = @v_cot_base_base)
		BEGIN
			SELECT @v_cob_ordre = MAX(COB_ORDRE) + 1 FROM COMBINAISON WHERE COB_IDJEU = @v_cob_idjeu
			INSERT INTO COMBINAISON (COB_IDJEU, COB_IDCONTEXTE, COB_ORDRE) VALUES (@v_cob_idjeu, @v_cob_idcontexte, ISNULL(@v_cob_ordre, 1))
			SET @v_error = @@ERROR
			IF @v_error = 0
			BEGIN
				SET @v_cob_idcombinaison = SCOPE_IDENTITY()
				SET @v_retour = 0
			END
		END
		ELSE
			SET @v_retour = 792
	END
	ELSE IF @v_action = 1
	BEGIN
		SELECT @v_cot_base_sys = COT_BASE_SYS, @v_cot_base_base = COT_BASE_BASE
			FROM COMBINAISON, CONTEXTE WHERE COB_IDCOMBINAISON = @v_cob_idcombinaison AND COT_ID = COB_IDCONTEXTE
		IF NOT EXISTS (SELECT 1 FROM COMBINAISON, CONTEXTE WHERE COB_IDCOMBINAISON <> @v_cob_idcombinaison AND COB_IDJEU = @v_cob_idjeu AND COT_ID = COB_IDCONTEXTE
			AND COT_BASE_SYS = @v_cot_base_sys AND COT_BASE_BASE = @v_cot_base_base)
		BEGIN
			IF NOT EXISTS (SELECT 1 FROM ACTION_REGLE, TYPE_ACTION_REGLE WHERE ARE_IDACTION = @v_cob_action
				AND TAR_IDTYPE = ARE_IDTYPE AND ((TAR_FAMILLE IS NOT NULL) OR (TAR_IDTYPE = 4 AND ARE_PARAMS = @v_cot_base_base)))
			BEGIN
				IF @v_ssaction = 0
					SELECT @v_cob_ordre = COB_ORDRE FROM COMBINAISON WHERE COB_IDCOMBINAISON = @v_cob_idcombinaison
				ELSE IF @v_ssaction IN (1, 2)
				BEGIN
					IF @v_ssaction = 1
					BEGIN
						SELECT @v_old_cob_idjeu = COB_IDJEU, @v_old_cob_ordre = COB_ORDRE FROM COMBINAISON WHERE COB_IDCOMBINAISON = @v_cob_idcombinaison
						UPDATE COMBINAISON SET COB_ORDRE = COB_ORDRE - 1 WHERE COB_IDJEU = @v_old_cob_idjeu AND COB_ORDRE > @v_old_cob_ordre
						SET @v_error = @@ERROR
						SELECT @v_cob_ordre = MAX(COB_ORDRE) + 1 FROM COMBINAISON WHERE COB_IDJEU = @v_cob_idjeu
					END
					ELSE
					BEGIN
						SELECT @v_old_cob_ordre = COB_ORDRE FROM COMBINAISON WHERE COB_IDCOMBINAISON = @v_cob_idcombinaison
						IF @v_cob_ordre < @v_old_cob_ordre
							UPDATE COMBINAISON SET COB_ORDRE = COB_ORDRE + 1 WHERE COB_IDCOMBINAISON <> @v_cob_idcombinaison AND COB_IDJEU = @v_cob_idjeu
								AND COB_ORDRE >= @v_cob_ordre AND COB_ORDRE < @v_old_cob_ordre
						ELSE IF @v_cob_ordre > @v_old_cob_ordre
							UPDATE COMBINAISON SET COB_ORDRE = COB_ORDRE - 1 WHERE COB_IDCOMBINAISON <> @v_cob_idcombinaison AND COB_IDJEU = @v_cob_idjeu
								AND COB_ORDRE > @v_old_cob_ordre AND COB_ORDRE <= @v_cob_ordre
					END
					SET @v_error = @@ERROR
				END
				IF @v_error = 0
				BEGIN
					UPDATE COMBINAISON SET COB_IDJEU = @v_cob_idjeu, COB_ACTION = @v_cob_action, COB_ORDRE = ISNULL(@v_cob_ordre, 1) WHERE COB_IDCOMBINAISON = @v_cob_idcombinaison
					SET @v_error = @@ERROR
					IF @v_error = 0
						SET @v_retour = 0
				END
			END
			ELSE
				SET @v_retour = 793
		END
		ELSE
			SET @v_retour = 792
	END
	ELSE IF @v_action = 2
	BEGIN
		SELECT @v_old_cob_ordre = COB_ORDRE FROM COMBINAISON WHERE COB_IDCOMBINAISON = @v_cob_idcombinaison
		DELETE COMBINAISON_DE_REGLE WHERE CDR_IDCOMBINAISON = @v_cob_idcombinaison
		IF @@ERROR <> 0
			SET @v_error = @@ERROR
		ELSE
		BEGIN
			DELETE COMBINAISON WHERE COB_IDCOMBINAISON = @v_cob_idcombinaison
			SET @v_error = @@ERROR
			IF @v_error = 0
			BEGIN
				UPDATE COMBINAISON SET COB_ORDRE = COB_ORDRE - 1 WHERE COB_IDJEU = @v_cob_idjeu AND COB_ORDRE > @v_old_cob_ordre
				SET @v_error = @@ERROR
				IF @v_error = 0
					SET @v_retour = 0
			END
		END
	END
	IF @v_error <> 0
		ROLLBACK TRAN
	ELSE
		COMMIT TRAN
	RETURN @v_error

