SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER ON



-----------------------------------------------------------------------------------------
-- Procédure		: PRF_GROUPE
-- Paramètre d'entrées	: @v_action : Action à mener
--			  @v_ssaction : Sous action à mener
--			  @v_lan_id : Identifiant langue
--			  @v_lib_libelle : Libellé
--			  @v_aug_utilisateur : Utilisateur
--			  @v_aog_operation : Operation
--			  @v_top_id : Type opération
--			  @v_ope_vue : Vue
-- Paramètre de sorties	: @v_retour : Code de retour
--			  @v_grp_id : Identifiant
--			  @v_tra_id : Identifiant traduction
-- Descriptif		: Gestion des groupes
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[PRF_GROUPE]
	@v_action smallint,
	@v_ssaction int,
	@v_grp_id int out,
	@v_tra_id int out,
	@v_lan_id varchar(3),
	@v_lib_libelle varchar(8000),
	@v_aug_utilisateur varchar(16),
	@v_aog_operation int,
	@v_top_id tinyint,
	@v_ope_vue int,
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
	@v_augutilisateur varchar(16),
	@v_augpriorite tinyint,
	@v_avgordre tinyint,
	@v_avuutlisateur varchar(16),
	@v_avuordre tinyint

	BEGIN TRAN
	SELECT @v_retour = 113
	SELECT @v_error = 0
	IF @v_action = 0
	BEGIN
		SELECT @v_tra_id = MIN(TRA_ID) - 1 FROM TRADUCTION
		INSERT INTO TRADUCTION (TRA_ID, TRA_SYSTEME) VALUES (@v_tra_id, 0)
		SELECT @v_error = @@ERROR
		IF @v_error = 0
		BEGIN
			INSERT INTO LIBELLE (LIB_TRADUCTION, LIB_LANGUE, LIB_LIBELLE)
				SELECT @v_tra_id, LAN_ID, @v_lib_libelle FROM LANGUE WHERE LAN_ACTIF = 1
			SELECT @v_error = @@ERROR
			IF @v_error = 0
			BEGIN
				SELECT @v_grp_id = CASE SIGN(MIN(GRP_ID)) WHEN -1 THEN MIN(GRP_ID) - 1 ELSE -1 END FROM GROUPE
				INSERT INTO GROUPE (GRP_ID, GRP_TRADUCTION, GRP_SYSTEME, GRP_ADMINISTRATEUR) VALUES (@v_grp_id, @v_tra_id, 0, 0)
				SELECT @v_error = @@ERROR
				IF @v_error = 0
					SELECT @v_retour = 0
			END
		END
	END
	ELSE IF @v_action = 1
	BEGIN
		IF @v_ssaction = 0
		BEGIN
			IF NOT EXISTS (SELECT 1 FROM ASSOCIATION_UTILISATEUR_GROUPE WHERE AUG_UTILISATEUR = @v_aug_utilisateur AND AUG_GROUPE = @v_grp_id)
			BEGIN
				INSERT INTO ASSOCIATION_UTILISATEUR_GROUPE (AUG_GROUPE, AUG_UTILISATEUR, AUG_PRIORITE)
					SELECT @v_grp_id, @v_aug_utilisateur, ISNULL(MAX(AUG_PRIORITE), 0) + 1 FROM ASSOCIATION_UTILISATEUR_GROUPE WHERE AUG_UTILISATEUR = @v_aug_utilisateur
				SELECT @v_error = @@ERROR
				IF @v_error = 0
					SELECT @v_retour = 0
			END
			ELSE
				SELECT @v_retour = 0
		END
		ELSE IF @v_ssaction = 1
		BEGIN
			SELECT @v_augpriorite = AUG_PRIORITE FROM ASSOCIATION_UTILISATEUR_GROUPE WHERE AUG_UTILISATEUR = @v_aug_utilisateur AND AUG_GROUPE = @v_grp_id
			UPDATE ASSOCIATION_UTILISATEUR_GROUPE SET AUG_PRIORITE = AUG_PRIORITE - 1
					WHERE AUG_UTILISATEUR = @v_aug_utilisateur  AND AUG_GROUPE <> @v_grp_id AND AUG_PRIORITE > @v_augpriorite
			SELECT @v_error = @@ERROR
			IF @v_error = 0
			BEGIN
				DELETE ASSOCIATION_UTILISATEUR_GROUPE WHERE AUG_UTILISATEUR = @v_aug_utilisateur AND AUG_GROUPE = @v_grp_id
				SELECT @v_error = @@ERROR
				IF @v_error = 0
					SELECT @v_retour = 0
			END	
		END
		ELSE IF @v_ssaction = 2
		BEGIN
			INSERT INTO ASSOCIATION_OPERATION_GROUPE (AOG_GROUPE, AOG_OPERATION) VALUES (@v_grp_id, @v_aog_operation)
			SELECT @v_error = @@ERROR
			IF @v_error = 0
				SELECT @v_retour = 0
		END
		ELSE IF @v_ssaction = 3
		BEGIN
			IF ((@v_top_id = 1) AND EXISTS (SELECT 1 FROM ASSOCIATION_VUE_GROUPE WHERE AVG_GROUPE = @v_grp_id AND AVG_VUE = @v_ope_vue))
			BEGIN
				SELECT @v_avgordre = AVG_ORDRE FROM ASSOCIATION_VUE_GROUPE WHERE AVG_GROUPE = @v_grp_id AND AVG_VUE = @v_ope_vue
				UPDATE ASSOCIATION_VUE_GROUPE SET AVG_ORDRE = AVG_ORDRE - 1 WHERE AVG_GROUPE = @v_grp_id AND AVG_VUE <> @v_ope_vue
					AND AVG_ORDRE > @v_avgordre
				SELECT @v_error = @@ERROR
				IF @v_error = 0
				BEGIN
					DELETE ASSOCIATION_VUE_GROUPE WHERE AVG_GROUPE = @v_grp_id AND AVG_VUE = @v_ope_vue
					SELECT @v_error = @@ERROR
				END
			END
			IF @v_error = 0
			BEGIN
				DELETE ASSOCIATION_OPERATION_GROUPE WHERE AOG_GROUPE = @v_grp_id AND AOG_OPERATION = @v_aog_operation
				SELECT @v_error = @@ERROR
				IF @v_error = 0
				BEGIN
					DECLARE c_assocation_vue_utilisateur CURSOR LOCAL FOR SELECT AVU_UTILISATEUR, AVU_ORDRE FROM ASSOCIATION_VUE_UTILISATEUR
						WHERE AVU_VUE = @v_ope_vue
					OPEN c_assocation_vue_utilisateur
					FETCH NEXT FROM c_assocation_vue_utilisateur INTO @v_avuutlisateur, @v_avuordre
					WHILE ((@@FETCH_STATUS = 0) AND (@v_error = 0))
					BEGIN
						IF NOT EXISTS (SELECT 1 FROM ASSOCIATION_UTILISATEUR_GROUPE, ASSOCIATION_OPERATION_GROUPE
							WHERE AUG_UTILISATEUR = @v_avuutlisateur AND AOG_GROUPE = AUG_GROUPE AND AOG_OPERATION = @v_aog_operation)
						BEGIN
							UPDATE ASSOCIATION_VUE_UTILISATEUR SET AVU_ORDRE = AVU_ORDRE - 1 WHERE AVU_UTILISATEUR = @v_avuutlisateur
								AND AVU_VUE <> @v_ope_vue AND AVU_ORDRE > @v_avuordre
							SELECT @v_error = @@ERROR
							IF @v_error = 0
							BEGIN
								DELETE ASSOCIATION_VUE_UTILISATEUR WHERE AVU_UTILISATEUR = @v_avuutlisateur AND AVU_VUE = @v_ope_vue
								SELECT @v_error = @@ERROR
							END
						END
						FETCH NEXT FROM c_assocation_vue_utilisateur INTO @v_avuutlisateur, @v_avuordre
					END
					IF @v_error = 0
						SELECT @v_retour = 0
				END
			END
		END
	END
	ELSE IF @v_action = 2
	BEGIN
		DELETE ASSOCIATION_COLORIAGE_GROUPE WHERE ALG_GROUPE = @v_grp_id
		SELECT @v_error = @@ERROR
		IF @v_error = 0
		BEGIN
			DELETE ASSOCIATION_COLONNE_GROUPE WHERE ACG_GROUPE = @v_grp_id
			SELECT @v_error = @@ERROR
			IF @v_error = 0
			BEGIN
				DELETE ASSOCIATION_VUE_TABLEAU_GROUPE WHERE ATG_GROUPE = @v_grp_id
				SELECT @v_error = @@ERROR
				IF @v_error = 0
				BEGIN
					DELETE ASSOCIATION_VUE_GROUPE WHERE AVG_GROUPE = @v_grp_id
					SELECT @v_error = @@ERROR
					IF @v_error = 0
					BEGIN
						DECLARE c_association_utilisateur_groupe CURSOR LOCAL FOR SELECT AUG_UTILISATEUR, AUG_PRIORITE
							FROM ASSOCIATION_UTILISATEUR_GROUPE WHERE AUG_GROUPE = @v_grp_id
						OPEN c_association_utilisateur_groupe
						FETCH NEXT FROM c_association_utilisateur_groupe INTO @v_augutilisateur, @v_augpriorite
						WHILE ((@@FETCH_STATUS = 0) AND (@v_error = 0))
						BEGIN
							UPDATE ASSOCIATION_UTILISATEUR_GROUPE SET AUG_PRIORITE = AUG_PRIORITE - 1
								WHERE AUG_UTILISATEUR = @v_augutilisateur AND AUG_PRIORITE > @v_augpriorite
							SELECT @v_error = @@ERROR
							FETCH NEXT FROM c_association_utilisateur_groupe INTO @v_augutilisateur, @v_augpriorite
						END
						CLOSE c_association_utilisateur_groupe
						DEALLOCATE c_association_utilisateur_groupe
						IF @v_error = 0
						BEGIN
							DELETE ASSOCIATION_UTILISATEUR_GROUPE WHERE AUG_GROUPE = @v_grp_id
							SELECT @v_error = @@ERROR
							IF @v_error = 0
							BEGIN
								DELETE ASSOCIATION_OPERATION_GROUPE WHERE AOG_GROUPE = @v_grp_id
								SELECT @v_error = @@ERROR
								IF @v_error = 0
								BEGIN
									DELETE GROUPE WHERE GRP_ID = @v_grp_id
									SELECT @v_error = @@ERROR
									IF @v_error = 0
									BEGIN
										DELETE LIBELLE WHERE LIB_TRADUCTION = @v_tra_id
										SELECT @v_error = @@ERROR
										IF @v_error = 0
										BEGIN
											DELETE TRADUCTION WHERE TRA_ID = @v_tra_id
											SELECT @v_error = @@ERROR
											IF @v_error = 0
												SELECT @v_retour = 0
										END
									END
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

