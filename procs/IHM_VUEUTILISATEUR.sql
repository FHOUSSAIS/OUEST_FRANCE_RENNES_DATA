SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF




-----------------------------------------------------------------------------------------
-- Procédure		: IHM_VUEUTILISATEUR
-- Paramètre d'entrée	: @v_action : Action à mener
--			  @v_avu_vue : Vue
--			  @v_avu_ordre : Ordre
--			  @v_utilisateur : Utilisateur
-- Paramètre de sortie	: @v_retour : Code de retour
-- Descriptif		: Gestion des vues d'un utilisateur
-----------------------------------------------------------------------------------------
-- Révision
-----------------------------------------------------------------------------------------
-- Date			: 28/02/2006
-- Auteur		: Cédric LE FRINGERE
-- Libellé			: Création de la procédure
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[IHM_VUEUTILISATEUR]
	@v_action smallint,
	@v_avu_vue int,
	@v_avu_ordre tinyint,
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
	@v_old_avu_ordre tinyint

	BEGIN TRAN
	SET @v_retour = 113
	SET @v_error = 0
	IF @v_action = 0
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM ASSOCIATION_VUE_UTILISATEUR WHERE AVU_UTILISATEUR = @v_utilisateur AND AVU_VUE = @v_avu_vue)
		BEGIN
			INSERT INTO ASSOCIATION_VUE_UTILISATEUR (AVU_UTILISATEUR, AVU_VUE, AVU_ORDRE)
				SELECT @v_utilisateur, @v_avu_vue, ISNULL(MAX(AVU_ORDRE), 0) + 1 FROM ASSOCIATION_VUE_UTILISATEUR WHERE AVU_UTILISATEUR = @v_utilisateur
			SELECT @v_error = @@ERROR
			IF @v_error = 0
				SELECT @v_retour = 0
		END
		ELSE
			SELECT @v_retour = 0
	END
	ELSE IF @v_action IN (1, 2)
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM ASSOCIATION_VUE_UTILISATEUR WHERE AVU_UTILISATEUR = @v_utilisateur)
		BEGIN
			IF EXISTS (SELECT 1 FROM ASSOCIATION_VUE_GROUPE, ASSOCIATION_UTILISATEUR_GROUPE, GROUPE
				WHERE GRP_ID = AVG_GROUPE AND AUG_GROUPE = GRP_ID AND AUG_UTILISATEUR = @v_utilisateur)
				INSERT INTO ASSOCIATION_VUE_UTILISATEUR (AVU_UTILISATEUR, AVU_VUE, AVU_ORDRE)
					SELECT DISTINCT @v_utilisateur, AVG_VUE, AVG_ORDRE FROM ASSOCIATION_VUE_GROUPE, VUE,
						ASSOCIATION_UTILISATEUR_GROUPE, GROUPE WHERE GRP_ID = AVG_GROUPE AND AUG_GROUPE = GRP_ID
						AND VUE_ID = AVG_VUE AND VUE_TYPE_VUE <> 2
			ELSE
				INSERT INTO ASSOCIATION_VUE_UTILISATEUR (AVU_UTILISATEUR, AVU_VUE, AVU_ORDRE)
					SELECT DISTINCT @v_utilisateur, VUE_ID, VUE_ORDRE FROM VUE, OPERATION, ASSOCIATION_OPERATION_GROUPE, ASSOCIATION_UTILISATEUR_GROUPE
						WHERE OPE_VUE = VUE_ID AND AUG_UTILISATEUR = @v_utilisateur AND AOG_GROUPE = AUG_GROUPE AND AOG_OPERATION = OPE_ID AND VUE_TYPE_VUE <> 2
			SELECT @v_error = @@ERROR
		END
		IF @v_error = 0
		BEGIN
			IF @v_action = 1
			BEGIN
				SELECT @v_old_avu_ordre = AVU_ORDRE FROM ASSOCIATION_VUE_UTILISATEUR
					WHERE AVU_VUE = @v_avu_vue AND AVU_UTILISATEUR = @v_utilisateur 
				IF @v_avu_ordre < @v_old_avu_ordre
				BEGIN
					UPDATE ASSOCIATION_VUE_UTILISATEUR SET AVU_ORDRE = AVU_ORDRE + 1
						WHERE AVU_VUE <> @v_avu_vue AND AVU_UTILISATEUR = @v_utilisateur
						AND AVU_ORDRE >= @v_avu_ordre AND AVU_ORDRE < @v_old_avu_ordre
					SELECT @v_error = @@ERROR
				END
				ELSE IF @v_avu_ordre > @v_old_avu_ordre
				BEGIN
					UPDATE ASSOCIATION_VUE_UTILISATEUR SET AVU_ORDRE = AVU_ORDRE - 1
						WHERE AVU_VUE <> @v_avu_vue AND AVU_UTILISATEUR = @v_utilisateur
						AND AVU_ORDRE > @v_old_avu_ordre AND AVU_ORDRE <= @v_avu_ordre
					SELECT @v_error = @@ERROR
				END
				IF @v_error = 0
				BEGIN
					UPDATE ASSOCIATION_VUE_UTILISATEUR SET AVU_ORDRE = @v_avu_ordre
						WHERE AVU_VUE = @v_avu_vue AND AVU_UTILISATEUR = @v_utilisateur 
					SELECT @v_error = @@ERROR
					IF @v_error = 0
						SELECT @v_retour = 0
				END
			END
			ELSE IF @v_action = 2
			BEGIN
				DELETE ASSOCIATION_VUE_UTILISATEUR WHERE AVU_VUE = @v_avu_vue AND AVU_UTILISATEUR = @v_utilisateur
				SELECT @v_error = @@ERROR
				IF @v_error = 0
				BEGIN
					UPDATE ASSOCIATION_VUE_UTILISATEUR SET AVU_ORDRE = AVU_ORDRE - 1 WHERE AVU_UTILISATEUR = @v_utilisateur
						AND AVU_ORDRE > @v_avu_ordre
					SELECT @v_error = @@ERROR
					IF @v_error = 0
						SELECT @v_retour = 0
				END
			END
		END
	END
	IF @v_error <> 0
		ROLLBACK TRAN

	ELSE
		COMMIT TRAN
	RETURN @v_error


