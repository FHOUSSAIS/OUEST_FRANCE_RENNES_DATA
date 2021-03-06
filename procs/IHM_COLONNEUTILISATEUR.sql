SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF



-----------------------------------------------------------------------------------------
-- Procédure		: IHM_COLONNEUTILISATEUR
-- Paramètre d'entrée	: @v_action : Action à mener
--			  @v_ssaction : Sous action à mener
--			  @v_acu_tableau : Tableau
--			  @v_acu_colonne : Colonne
--			  @v_acu_sens : Sens
--			  @v_acu_ordre : Ordre
--			  @v_acu_taille : Taille
--			  @v_utilisateur : Utilisateur
-- Paramètre de sortie	: @v_retour : Code de retour
-- Descriptif		: Gestion des colonnes des vues tableaux d'un utilisateur
-----------------------------------------------------------------------------------------
-- Révision
-----------------------------------------------------------------------------------------
-- Date			: 28/02/2006
-- Auteur		: Cédric LE FRINGERE
-- Libellé			: Création de la procédure
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[IHM_COLONNEUTILISATEUR]
	@v_action smallint,
	@v_ssaction smallint,
	@v_acu_tableau int,
	@v_acu_colonne varchar(32),
	@v_acu_sens tinyint,
	@v_acu_ordre tinyint,
	@v_acu_taille int,
	@v_utilisateur varchar(16),
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
	@v_old_acu_classement tinyint,
	@v_old_acu_ordre tinyint,
	@v_old_acu_sens tinyint

	BEGIN TRAN
	SET @v_retour = 113
	SET @v_error = 0
	IF @v_action = 0
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM ASSOCIATION_COLONNE_UTILISATEUR WHERE ACU_UTILISATEUR = @v_utilisateur AND ACU_TABLEAU = @v_acu_tableau AND ACU_COLONNE = @v_acu_colonne)
		BEGIN
			INSERT INTO ASSOCIATION_COLONNE_UTILISATEUR (ACU_UTILISATEUR, ACU_TABLEAU, ACU_COLONNE, ACU_ORDRE, ACU_CLASSEMENT, ACU_SENS)
				SELECT @v_utilisateur, @v_acu_tableau, @v_acu_colonne, ISNULL(MAX(ACU_ORDRE), 0) + 1, ISNULL(MAX(ACU_CLASSEMENT), 0) + 1, @v_acu_sens
				FROM ASSOCIATION_COLONNE_UTILISATEUR WHERE ACU_UTILISATEUR = @v_utilisateur AND ACU_TABLEAU = @v_acu_tableau
			SELECT @v_error = @@ERROR
			IF @v_error = 0
				SELECT @v_retour = 0
		END
		ELSE
			SELECT @v_retour = 0
	END
	ELSE IF @v_action IN (1, 2)
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM ASSOCIATION_COLONNE_UTILISATEUR WHERE ACU_UTILISATEUR = @v_utilisateur AND ACU_TABLEAU = @v_acu_tableau)
		BEGIN
			IF EXISTS (SELECT 1 FROM ASSOCIATION_COLONNE_GROUPE, ASSOCIATION_UTILISATEUR_GROUPE, GROUPE
				WHERE ACG_TABLEAU = @v_acu_tableau AND GRP_ID = ACG_GROUPE AND AUG_GROUPE = GRP_ID AND AUG_UTILISATEUR = @v_utilisateur)
				INSERT INTO ASSOCIATION_COLONNE_UTILISATEUR (ACU_UTILISATEUR, ACU_TABLEAU, ACU_COLONNE, ACU_ORDRE, ACU_TAILLE, ACU_CLASSEMENT, ACU_SENS)
					SELECT DISTINCT @v_utilisateur, @v_acu_tableau, ACG_COLONNE, COL_ORDRE, COL_TAILLE, COL_CLASSEMENT, COL_SENS
					FROM ASSOCIATION_COLONNE_GROUPE, COLONNE, ASSOCIATION_UTILISATEUR_GROUPE, GROUPE
					WHERE ACG_TABLEAU = @v_acu_tableau AND GRP_ID = ACG_GROUPE AND AUG_GROUPE = GRP_ID
					AND COL_ID = ACG_COLONNE AND COL_TABLEAU = ACG_TABLEAU AND COL_VISIBLE = 1
			ELSE
				INSERT INTO ASSOCIATION_COLONNE_UTILISATEUR (ACU_UTILISATEUR, ACU_TABLEAU, ACU_COLONNE, ACU_ORDRE, ACU_TAILLE, ACU_CLASSEMENT, ACU_SENS)
					SELECT @v_utilisateur, @v_acu_tableau, COL_ID, COL_ORDRE, COL_TAILLE, COL_CLASSEMENT, COL_SENS FROM COLONNE 
					WHERE COL_TABLEAU = @v_acu_tableau AND COL_VISIBLE = 1
			SELECT @v_error = @@ERROR
		END
		IF @v_error = 0
		BEGIN
			IF @v_action = 1
			BEGIN
				IF @v_ssaction = 0
				BEGIN
					SELECT @v_old_acu_classement = ACU_CLASSEMENT, @v_old_acu_sens = ACU_SENS FROM ASSOCIATION_COLONNE_UTILISATEUR
						WHERE ACU_UTILISATEUR = @v_utilisateur AND ACU_TABLEAU = @v_acu_tableau AND ACU_COLONNE = @v_acu_colonne
					IF @v_old_acu_classement = 1
					BEGIN
						IF @v_old_acu_sens = 0
							UPDATE ASSOCIATION_COLONNE_UTILISATEUR SET ACU_SENS = 1 WHERE ACU_TABLEAU = @v_acu_tableau AND ACU_UTILISATEUR = @v_utilisateur AND ACU_COLONNE = @v_acu_colonne
						ELSE
							UPDATE ASSOCIATION_COLONNE_UTILISATEUR SET ACU_SENS = 0 WHERE ACU_TABLEAU = @v_acu_tableau AND ACU_UTILISATEUR = @v_utilisateur AND ACU_COLONNE = @v_acu_colonne
						SELECT @v_error = @@ERROR
					END
					ELSE
					BEGIN
						UPDATE ASSOCIATION_COLONNE_UTILISATEUR SET ACU_CLASSEMENT = 1
							WHERE ACU_TABLEAU = @v_acu_tableau AND ACU_UTILISATEUR = @v_utilisateur AND ACU_COLONNE = @v_acu_colonne
						SELECT @v_error = @@ERROR
					END
					IF ((@v_error = 0) AND (@v_old_acu_classement <> 1))
					BEGIN
						UPDATE ASSOCIATION_COLONNE_UTILISATEUR SET ACU_CLASSEMENT = ACU_CLASSEMENT + 1
							WHERE ACU_UTILISATEUR = @v_utilisateur AND ACU_COLONNE <> @v_acu_colonne AND ACU_TABLEAU = @v_acu_tableau
							AND ACU_CLASSEMENT < @v_old_acu_classement
						SELECT @v_error = @@ERROR
					END
				END
				ELSE IF @v_ssaction = 1
				BEGIN
					SELECT @v_old_acu_ordre = ACU_ORDRE FROM ASSOCIATION_COLONNE_UTILISATEUR WHERE ACU_TABLEAU = @v_acu_tableau
						AND ACU_UTILISATEUR = @v_utilisateur AND ACU_COLONNE = @v_acu_colonne 
					IF @v_acu_ordre < @v_old_acu_ordre
					BEGIN
						UPDATE ASSOCIATION_COLONNE_UTILISATEUR SET ACU_ORDRE = ACU_ORDRE + 1
							WHERE ACU_TABLEAU = @v_acu_tableau AND ACU_COLONNE <> @v_acu_colonne AND ACU_UTILISATEUR = @v_utilisateur
							AND ACU_ORDRE >= @v_acu_ordre AND ACU_ORDRE < @v_old_acu_ordre
						SELECT @v_error = @@ERROR
					END
					ELSE IF @v_acu_ordre > @v_old_acu_ordre
					BEGIN
						UPDATE ASSOCIATION_COLONNE_UTILISATEUR SET ACU_ORDRE = ACU_ORDRE - 1
							WHERE ACU_TABLEAU = @v_acu_tableau AND ACU_COLONNE <> @v_acu_colonne AND ACU_UTILISATEUR = @v_utilisateur
							AND ACU_ORDRE > @v_old_acu_ordre AND ACU_ORDRE <= @v_acu_ordre
						SELECT @v_error = @@ERROR
					END
					IF @v_error = 0
					BEGIN
						UPDATE ASSOCIATION_COLONNE_UTILISATEUR SET ACU_ORDRE = @v_acu_ordre WHERE ACU_TABLEAU = @v_acu_tableau
							AND ACU_UTILISATEUR = @v_utilisateur AND ACU_COLONNE = @v_acu_colonne 
						SELECT @v_error = @@ERROR
					END
				END
				ELSE IF @v_ssaction = 2
				BEGIN
					UPDATE ASSOCIATION_COLONNE_UTILISATEUR SET ACU_TAILLE = @v_acu_taille WHERE ACU_TABLEAU = @v_acu_tableau
						AND ACU_UTILISATEUR = @v_utilisateur AND ACU_COLONNE = @v_acu_colonne
					SELECT @v_error = @@ERROR
				END
				IF @v_error = 0
					SELECT @v_retour = 0
			END
			ELSE IF @v_action = 2
			BEGIN
				SELECT @v_old_acu_classement = ACU_CLASSEMENT FROM ASSOCIATION_COLONNE_UTILISATEUR
					WHERE ACU_UTILISATEUR = @v_utilisateur AND ACU_TABLEAU = @v_acu_tableau AND ACU_COLONNE = @v_acu_colonne
				DELETE ASSOCIATION_COLONNE_UTILISATEUR WHERE ACU_TABLEAU = @v_acu_tableau AND ACU_COLONNE = @v_acu_colonne AND ACU_UTILISATEUR = @v_utilisateur
				SELECT @v_error = @@ERROR
				IF @v_error = 0
				BEGIN
					UPDATE ASSOCIATION_COLONNE_UTILISATEUR SET ACU_ORDRE = ACU_ORDRE - 1 WHERE ACU_UTILISATEUR = @v_utilisateur
						AND ACU_TABLEAU = @v_acu_tableau AND ACU_ORDRE > @v_acu_ordre
					SELECT @v_error = @@ERROR
					IF @v_error = 0
					BEGIN
						UPDATE ASSOCIATION_COLONNE_UTILISATEUR SET ACU_CLASSEMENT = ACU_CLASSEMENT - 1 WHERE ACU_UTILISATEUR = @v_utilisateur
							AND ACU_TABLEAU = @v_acu_tableau AND ACU_CLASSEMENT > @v_old_acu_classement
						SELECT @v_error = @@ERROR
						IF @v_error = 0
							SELECT @v_retour = 0
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


