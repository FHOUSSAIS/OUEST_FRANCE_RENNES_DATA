SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER ON




-----------------------------------------------------------------------------------------
-- Procédure		: CFG_GRAPHIQUE
-- Paramètre d'entrées	: @v_action : Action à mener
--			  @v_vue_ordre : Ordre d'affichage
--			  @v_lan_id : Identifiant langue
--			  @v_lib_libelle : Libellé
--			  @v_gra_classe : Classe
-- Paramètre de sorties	: @v_retour : Code de retour
--			  @v_vue_id : Identifiant vue
--			  @v_tra_id : Identifiant traduction
-- Descriptif		: Gestion des graphiques
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[CFG_GRAPHIQUE]
	@v_action smallint,
	@v_vue_id int out,
	@v_vue_ordre tinyint,
	@v_tra_id int out,
	@v_lan_id varchar(3),
	@v_lib_libelle varchar(8000),
	@v_gra_classe varchar(32),
	@v_retour smallint out
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

DECLARE
	@v_error smallint,
	@v_vgr_id tinyint,
	@v_ope_id int

	BEGIN TRAN
	SELECT @v_retour = 113
	SELECT @v_error = 0
	IF @v_action = 0
	BEGIN
		EXEC @v_error = LIB_TRADUCTION @v_action, @v_lan_id, @v_lib_libelle, @v_tra_id out
		IF @v_error = 0
		BEGIN
			SELECT @v_vue_id = CASE SIGN(MIN(VUE_ID)) WHEN -1 THEN MIN(VUE_ID) - 1 ELSE -1 END FROM VUE
			INSERT INTO VUE (VUE_ID, VUE_TRADUCTION, VUE_TYPE_VUE, VUE_ORDRE, VUE_SYSTEME) VALUES (@v_vue_id, @v_tra_id, 1, @v_vue_ordre, 0)
			SELECT @v_error = @@ERROR
			IF @v_error = 0
			BEGIN
				SELECT @v_vgr_id = VGR_ID FROM VUE_GRAPHIQUE
				INSERT INTO GRAPHIQUE (GRA_VUE, GRA_VUE_GRAPHIQUE) VALUES (@v_vue_id, @v_vgr_id)
				SELECT @v_error = @@ERROR
				IF @v_error = 0
				BEGIN
					SELECT @v_ope_id = ISNULL(MIN(OPE_ID) - 1, -1) FROM OPERATION
					INSERT INTO OPERATION (OPE_ID, OPE_TYPE_OPERATION, OPE_TRADUCTION, OPE_VUE, OPE_VISIBLE, OPE_SYSTEME) VALUES (@v_ope_id, 1, @v_tra_id, @v_vue_id, 1, 0)
					SELECT @v_error = @@ERROR
					IF @v_error = 0
					BEGIN
						INSERT INTO ASSOCIATION_OPERATION_GROUPE (AOG_GROUPE, AOG_OPERATION) SELECT GRP_ID, @v_ope_id FROM GROUPE WHERE GRP_SYSTEME = 1
						SELECT @v_error = @@ERROR
						IF @v_error = 0
							SELECT @v_retour = 0
					END
				END
			END
		END
	END
	ELSE IF @v_action = 1
	BEGIN
		UPDATE GRAPHIQUE SET GRA_CLASSE = @v_gra_classe WHERE GRA_VUE = @v_vue_id
		SELECT @v_error = @@ERROR
		IF @v_error = 0
		BEGIN
			IF @v_gra_classe IN ('TFrmEnergie', 'TFrmMode')
			BEGIN
				IF NOT EXISTS (SELECT 1 FROM OPERATION WHERE ((OPE_ID = 0 AND @v_gra_classe = 'TFrmEnergie') OR (OPE_ID = 1 AND @v_gra_classe = 'TFrmMode')) AND OPE_VISIBLE = 1)
				BEGIN
					UPDATE OPERATION SET OPE_VISIBLE = 1 WHERE (OPE_ID = 0 AND @v_gra_classe = 'TFrmEnergie') OR (OPE_ID = 1 AND @v_gra_classe = 'TFrmMode')
					SELECT @v_error = @@ERROR
				END
				IF @v_error = 0
				BEGIN
					IF NOT EXISTS (SELECT 1 FROM ASSOCIATION_OPERATION_GROUPE, GROUPE WHERE AOG_OPERATION = CASE @v_gra_classe WHEN 'TFrmEnergie' THEN 0 WHEN 'TFrmMode' THEN 1 END AND GRP_ID = AOG_GROUPE AND GRP_ADMINISTRATEUR = 1)
					BEGIN
						INSERT INTO ASSOCIATION_OPERATION_GROUPE (AOG_GROUPE, AOG_OPERATION) SELECT GRP_ID, CASE @v_gra_classe WHEN 'TFrmEnergie' THEN 0 WHEN 'TFrmMode' THEN 1 END FROM GROUPE WHERE GRP_ADMINISTRATEUR = 1
						SELECT @v_error = @@ERROR
					END
					IF @v_error = 0
						SELECT @v_retour = 0
				END
			END
			ELSE
				SELECT @v_retour = 0
		END
	END
	ELSE IF @v_action = 2
	BEGIN
		DELETE GRAPHIQUE WHERE GRA_VUE = @v_vue_id
		SELECT @v_error = @@ERROR
		IF @v_error = 0
		BEGIN
			SELECT @v_ope_id = OPE_ID FROM OPERATION WHERE OPE_VUE = @v_vue_id
			DELETE ASSOCIATION_OPERATION_GROUPE WHERE AOG_OPERATION = @v_ope_id
			SELECT @v_error = @@ERROR
			IF @v_error = 0
			BEGIN
				DELETE OPERATION WHERE OPE_VUE = @v_vue_id
				SELECT @v_error = @@ERROR
				IF @v_error = 0
				BEGIN
					DELETE ASSOCIATION_VUE_UTILISATEUR WHERE AVU_VUE = @v_vue_id
					SELECT @v_error = @@ERROR
					IF @v_error = 0
					BEGIN
						DELETE ASSOCIATION_VUE_GROUPE WHERE AVG_VUE = @v_vue_id
						SELECT @v_error = @@ERROR
						IF @v_error = 0
						BEGIN
							DELETE VUE WHERE VUE_ID = @v_vue_id
							SELECT @v_error = @@ERROR
							IF @v_error = 0
							BEGIN
								UPDATE VUE SET VUE_ORDRE = VUE_ORDRE - 1 WHERE VUE_ORDRE > @v_vue_ordre
								SELECT @v_error = @@ERROR
								IF @v_error = 0
								BEGIN
									EXEC @v_error = LIB_TRADUCTION @v_action, NULL, NULL, @v_tra_id out
									IF @v_error = 0
									BEGIN
										IF @v_gra_classe IN ('TFrmEnergie', 'TFrmMode')
										BEGIN
											UPDATE OPERATION SET OPE_VISIBLE = 0 WHERE (OPE_ID = 0 AND @v_gra_classe = 'TFrmEnergie') OR (OPE_ID = 1 AND @v_gra_classe = 'TFrmMode')
											SELECT @v_error = @@ERROR
											IF @v_error = 0
											BEGIN
												DELETE ASSOCIATION_OPERATION_GROUPE WHERE AOG_GROUPE IN (SELECT GRP_ID FROM GROUPE WHERE GRP_ADMINISTRATEUR = 1) AND AOG_OPERATION = CASE @v_gra_classe WHEN 'TFrmEnergie' THEN 0 WHEN 'TFrmMode' THEN 1 END
												SELECT @v_error = @@ERROR
												IF @v_error = 0
													SELECT @v_retour = 0
											END
										END
										ELSE
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
	IF @v_error <> 0
		ROLLBACK TRAN
	ELSE
		COMMIT TRAN
	RETURN @v_error

