SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER ON


-----------------------------------------------------------------------------------------
-- Procédure		: PRF_UTILISATEUR
-- Paramètre d'entrées	: @v_action : Action à mener
--			  @v_ssaction : Sous action à mener
--			  @v_uti_id : Identifiant
--			  @v_uti_password : Mot de passe
--			  @v_uti_nom : Nom
--			  @v_uti_prenom : Prenom
--			  @v_uti_langue : Identifiant langue
--			  @v_aug_groupe : Identifiant groupe
--			  @v_aug_priorite : Priorité
--			  @v_uti_vue : Vue
--			  @v_uti_synoptique : Synoptique
-- Paramètre de sorties	: @v_retour : Code de retour
-- Descriptif		: Gestion des utilisateurs
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[PRF_UTILISATEUR]
	@v_action smallint,
	@v_ssaction smallint,
	@v_uti_id varchar(16),
	@v_uti_password varchar(16),
	@v_uti_nom varchar(32),
	@v_uti_prenom varchar(32),
	@v_uti_langue varchar(3),
	@v_aug_groupe int,
	@v_aug_priorite tinyint,
	@v_uti_vue tinyint,
	@v_uti_synoptique tinyint,
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
	@v_old_aug_priorite tinyint

	BEGIN TRAN
	SET @v_retour = 113
	SET @v_error = 0
	IF @v_action = 0
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM UTILISATEUR WHERE UTI_ID = @v_uti_id)
		BEGIN
			INSERT INTO UTILISATEUR (UTI_ID, UTI_PASSWORD, UTI_NOM, UTI_LANGUE, UTI_SYSTEME, UTI_VUE, UTI_SYNOPTIQUE)
				VALUES (@v_uti_id, @v_uti_id, @v_uti_id, @v_uti_langue, 0, 2, 1)
			SET @v_error = @@ERROR
			IF @v_error = 0
				SET @v_retour = 0
		END
		ELSE
			SELECT @v_retour = 117
	END
	ELSE IF @v_action = 1
	BEGIN
		IF @v_ssaction = 0
		BEGIN
			UPDATE UTILISATEUR SET UTI_PASSWORD = @v_uti_password WHERE UTI_ID = @v_uti_id
			SET @v_error = @@ERROR
			IF @v_error = 0
				SET @v_retour = 0
		END
		ELSE IF @v_ssaction = 1
		BEGIN
			UPDATE UTILISATEUR SET UTI_NOM = @v_uti_nom, UTI_PRENOM = @v_uti_prenom, UTI_LANGUE = @v_uti_langue,
				UTI_VUE = @v_uti_vue, UTI_SYNOPTIQUE = @v_uti_synoptique WHERE UTI_ID = @v_uti_id
			SET @v_error = @@ERROR
			IF @v_error = 0
				SET @v_retour = 0
		END
		ELSE IF @v_ssaction = 2
		BEGIN
			DELETE ASSOCIATION_UTILISATEUR_GROUPE WHERE AUG_UTILISATEUR = @v_uti_id AND AUG_GROUPE = @v_aug_groupe
			SET @v_error = @@ERROR
			IF @v_error = 0
			BEGIN
				UPDATE ASSOCIATION_UTILISATEUR_GROUPE SET AUG_PRIORITE = AUG_PRIORITE - 1 WHERE AUG_UTILISATEUR = @v_uti_id AND AUG_PRIORITE > @v_aug_priorite
				SET @v_error = @@ERROR
				IF @v_error = 0
					SET @v_retour = 0
			END
		END
		ELSE IF @v_ssaction = 3
		BEGIN
			IF NOT EXISTS (SELECT 1 FROM ASSOCIATION_UTILISATEUR_GROUPE WHERE AUG_UTILISATEUR = @v_uti_id AND AUG_GROUPE = @v_aug_groupe)
			BEGIN
				INSERT INTO ASSOCIATION_UTILISATEUR_GROUPE (AUG_UTILISATEUR, AUG_GROUPE, AUG_PRIORITE)
					VALUES (@v_uti_id, @v_aug_groupe, @v_aug_priorite)
				SET @v_error = @@ERROR
				IF @v_error = 0
					SET @v_retour = 0
			END
			ELSE
				SET @v_retour = 0
		END
		ELSE IF @v_ssaction = 4
		BEGIN
			SELECT @v_old_aug_priorite = AUG_PRIORITE FROM ASSOCIATION_UTILISATEUR_GROUPE WHERE AUG_UTILISATEUR = @v_uti_id AND AUG_GROUPE = @v_aug_groupe
			IF @v_aug_priorite < @v_old_aug_priorite
			BEGIN
				UPDATE ASSOCIATION_UTILISATEUR_GROUPE SET AUG_PRIORITE = AUG_PRIORITE + 1
					WHERE AUG_UTILISATEUR = @v_uti_id  AND AUG_GROUPE <> @v_aug_groupe AND AUG_PRIORITE >= @v_aug_priorite
					AND AUG_PRIORITE < @v_old_aug_priorite
				SET @v_error = @@ERROR
			END
			ELSE IF @v_aug_priorite > @v_old_aug_priorite
			BEGIN
				UPDATE ASSOCIATION_UTILISATEUR_GROUPE SET AUG_PRIORITE = AUG_PRIORITE - 1
					WHERE AUG_UTILISATEUR = @v_uti_id  AND AUG_GROUPE <> @v_aug_groupe AND AUG_PRIORITE > @v_old_aug_priorite
					AND AUG_PRIORITE <= @v_aug_priorite
				SET @v_error = @@ERROR
			END
			IF @v_error = 0
			BEGIN
				UPDATE ASSOCIATION_UTILISATEUR_GROUPE SET AUG_PRIORITE = @v_aug_priorite WHERE AUG_UTILISATEUR = @v_uti_id AND AUG_GROUPE = @v_aug_groupe
				SET @v_error = @@ERROR
				IF @v_error = 0
					SET @v_retour = 0
			END	
		END
	END
	ELSE IF @v_action = 2
	BEGIN
		UPDATE POSTE SET PST_UTILISATEUR = NULL WHERE PST_UTILISATEUR = @v_uti_id
		SET @v_error = @@ERROR
		IF @v_error = 0
		BEGIN
			DELETE ASSOCIATION_COLORIAGE_UTILISATEUR WHERE ALU_UTILISATEUR = @v_uti_id
			SET @v_error = @@ERROR
			IF @v_error = 0
			BEGIN
				DELETE ASSOCIATION_FILTRE_UTILISATEUR WHERE AFU_UTILISATEUR = @v_uti_id
				SET @v_error = @@ERROR
				IF @v_error = 0
				BEGIN
					DELETE ASSOCIATION_COLONNE_UTILISATEUR WHERE ACU_UTILISATEUR = @v_uti_id
					SET @v_error = @@ERROR
					IF @v_error = 0
					BEGIN
						DELETE ASSOCIATION_VUE_TABLEAU_UTILISATEUR WHERE ATU_UTILISATEUR = @v_uti_id
						SET @v_error = @@ERROR
						IF @v_error = 0
						BEGIN
							DELETE ASSOCIATION_VUE_UTILISATEUR WHERE AVU_UTILISATEUR = @v_uti_id
							SET @v_error = @@ERROR
							IF @v_error = 0
							BEGIN
								DELETE ASSOCIATION_UTILISATEUR_GROUPE WHERE AUG_UTILISATEUR = @v_uti_id
								SET @v_error = @@ERROR
								IF @v_error = 0
								BEGIN
									DELETE UTILISATEUR WHERE UTI_ID = @v_uti_id
									SET @v_error = @@ERROR
									IF @v_error = 0
										SET @v_retour = 0
								END
							END
						END
					END
				END
			END
		END
	END
	IF @v_error <> 0
		ROLLBACK TRAN
	ELSE
		COMMIT TRAN
	RETURN @v_error

