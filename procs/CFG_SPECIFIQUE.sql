SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER ON




-----------------------------------------------------------------------------------------
-- Procédure		: CFG_SPECIFIQUE
-- Paramètre d'entrées	: @v_action : Action à mener
--			  @v_vue_ordre : Ordre d'affichage
--			  @v_lan_id : Identifiant langue
--			  @v_lib_libelle : Libellé
--			  @v_spe_dll : Dll
-- Paramètre de sorties	: @v_retour : Code de retour
--			  @v_vue_id : Identifiant vue
--			  @v_tra_id : Identifiant traduction
-- Descriptif		: Gestion des spécifiques
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[CFG_SPECIFIQUE]
	@v_action smallint,
	@v_vue_id int out,
	@v_vue_ordre tinyint,
	@v_tra_id int out,
	@v_lan_id varchar(3),
	@v_lib_libelle varchar(8000),
	@v_spe_dll varchar(32),
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
	@v_vsp_id tinyint,
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
			INSERT INTO VUE (VUE_ID, VUE_TRADUCTION, VUE_TYPE_VUE, VUE_ORDRE, VUE_SYSTEME) VALUES (@v_vue_id, @v_tra_id, 3, @v_vue_ordre, 0)
			SELECT @v_error = @@ERROR
			IF @v_error = 0
			BEGIN
				SELECT @v_vsp_id = VSP_ID FROM VUE_SPECIFIQUE
				INSERT INTO SPECIFIQUE (SPE_VUE, SPE_VUE_SPECIFIQUE) VALUES (@v_vue_id, @v_vsp_id)
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
		UPDATE SPECIFIQUE SET SPE_DLL = @v_spe_dll WHERE SPE_VUE = @v_vue_id
		SELECT @v_error = @@ERROR
		IF @v_error = 0
			SELECT @v_retour = 0
	END
	ELSE IF @v_action = 2
	BEGIN
		DELETE SPECIFIQUE WHERE SPE_VUE = @v_vue_id
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
										SELECT @v_retour = 0
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

