SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER ON




-----------------------------------------------------------------------------------------
-- Procédure		: CFG_SAISIE
-- Paramètre d'entrées	: @v_action : Action à mener
--			  @v_lib_libelle : Libellé
--			  @v_lib_libelle_operation : Libellé opération
--			  @v_lib_libelle_confirmation : Libellé confirmation
--			  @v_lan_id : Identifiant langue
--			  @v_ope_traitement : Procédure stockée
-- Paramètre de sorties	: @v_retour : Code de retour
--			  @v_vue_id : Identifiant vue
--			  @v_tra_id : Identifiant traduction
--			  @v_ope_traduction : Identifiant traduction opération
--			  @v_ope_confirmation : Identifiant traduction confirmation
--			  @v_ope_id : Identifiant opération
-- Descriptif		: Gestion des saisies
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[CFG_SAISIE]
	@v_action smallint,
	@v_vue_id int out,
	@v_tra_id int out,
	@v_ope_traduction int out,
	@v_ope_confirmation int out,
	@v_ope_id int out,
	@v_lan_id varchar(3),
	@v_lib_libelle varchar(8000),
	@v_lib_libelle_operation varchar(8000),
	@v_lib_libelle_confirmation varchar(8000),
	@v_ope_traitement varchar(32),
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
	@v_vsa_id int,
	@v_inf_traduction int

	BEGIN TRAN
	SELECT @v_retour = 113
	SELECT @v_error = 0
	IF @v_action = 0
	BEGIN
		IF EXISTS (SELECT 1 FROM sysobjects WHERE xtype = 'P' AND name = PARSENAME(@v_ope_traitement, 1))
		BEGIN
			SELECT @v_lib_libelle_confirmation = @v_lib_libelle_operation
			EXEC @v_error = LIB_TRADUCTION @v_action, @v_lan_id, @v_lib_libelle_confirmation, @v_ope_confirmation out
			IF @v_error = 0
			BEGIN
				EXEC @v_error = LIB_TRADUCTION @v_action, @v_lan_id, @v_lib_libelle_operation, @v_ope_traduction out
				IF @v_error = 0
				BEGIN
					SELECT @v_ope_id = ISNULL(MIN(OPE_ID) - 1, -1) FROM OPERATION
					INSERT INTO OPERATION (OPE_ID, OPE_TYPE_OPERATION, OPE_TRADUCTION, OPE_TRAITEMENT, OPE_CONFIRMATION, OPE_VISIBLE, OPE_SYSTEME) VALUES (@v_ope_id, 2, @v_ope_traduction, @v_ope_traitement, @v_ope_confirmation, 1, 0)
					SELECT @v_error = @@ERROR
					IF @v_error = 0
					BEGIN
						INSERT INTO ASSOCIATION_OPERATION_GROUPE (AOG_GROUPE, AOG_OPERATION) SELECT GRP_ID, @v_ope_id FROM GROUPE WHERE GRP_ADMINISTRATEUR = 1
						SELECT @v_error = @@ERROR
						IF @v_error = 0
						BEGIN
							INSERT INTO ENTREE (ENT_ID, ENT_NOM, ENT_TRAITEMENT, ENT_OPERATION, ENT_NULL, ENT_TYPE, ENT_DIRECTION)
								SELECT (SELECT CASE SIGN(MIN(ENT_ID)) WHEN -1 THEN MIN(ENT_ID) - ORDINAL_POSITION ELSE -ORDINAL_POSITION END FROM ENTREE),
								PARAMETER_NAME, @v_ope_traitement, @v_ope_id, 0, DATA_TYPE, CASE WHEN PARAMETER_MODE = 'IN' THEN 20 ELSE 21 END
								FROM INFORMATION_SCHEMA.PARAMETERS WHERE SPECIFIC_NAME = PARSENAME(@v_ope_traitement, 1) ORDER BY ORDINAL_POSITION
							SELECT @v_error = @@ERROR
							IF @v_error = 0
							BEGIN
								EXEC @v_error = LIB_TRADUCTION @v_action, @v_lan_id, @v_lib_libelle, @v_tra_id out
								IF @v_error = 0
								BEGIN
									SELECT @v_vue_id = CASE SIGN(MIN(VUE_ID)) WHEN -1 THEN MIN(VUE_ID) - 1 ELSE -1 END FROM VUE
									INSERT INTO VUE (VUE_ID, VUE_TRADUCTION, VUE_TYPE_VUE, VUE_SYSTEME) VALUES (@v_vue_id, @v_tra_id, 2, 0)
									SELECT @v_error = @@ERROR
									IF @v_error = 0
									BEGIN
										SELECT @v_vsa_id = VSA_ID FROM VUE_SAISIE
										INSERT INTO SAISIE (SAI_VUE, SAI_VUE_SAISIE, SAI_OPERATION) VALUES (@v_vue_id, @v_vsa_id, @v_ope_id)
										SELECT @v_error = @@ERROR
										IF @v_error = 0
										BEGIN
											UPDATE OPERATION SET OPE_VUE = @v_vue_id WHERE OPE_ID = @v_ope_id
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
		ELSE
			SELECT @v_retour = 115
	END
	ELSE IF @v_action = 1
	BEGIN
		UPDATE LIBELLE SET LIB_LIBELLE = @v_lib_libelle_operation WHERE LIB_TRADUCTION = @v_ope_traduction AND LIB_LANGUE = @v_lan_id
		SELECT @v_error = @@ERROR
		IF @v_error = 0
		BEGIN
			UPDATE LIBELLE SET LIB_LIBELLE = @v_lib_libelle_confirmation WHERE LIB_TRADUCTION = @v_ope_confirmation AND LIB_LANGUE = @v_lan_id
			SELECT @v_error = @@ERROR
			IF @v_error = 0
				SELECT @v_retour = 0
		END
	END
	ELSE IF @v_action = 2
	BEGIN
		IF NOT EXISTS ((SELECT 1 FROM SOUS_MENU_CONTEXTUEL WHERE SMC_OPERATION = @v_ope_id)
			UNION (SELECT 1 FROM SOUS_MENU WHERE SMN_OPERATION = @v_ope_id))
		BEGIN
			UPDATE OPERATION SET OPE_VUE = NULL WHERE OPE_ID = @v_ope_id
			SELECT @v_error = @@ERROR
			IF @v_error = 0
			BEGIN
				DECLARE c_information CURSOR LOCAL FOR SELECT INF_TRADUCTION FROM INFORMATION WHERE INF_SAISIE = @v_vue_id FOR UPDATE
				OPEN c_information
				FETCH NEXT FROM c_information INTO @v_inf_traduction
				WHILE ((@@FETCH_STATUS = 0) AND (@v_error = 0))
				BEGIN
					DELETE INFORMATION WHERE CURRENT OF c_information
					SELECT @v_error = @@ERROR
					IF @v_error = 0
						EXEC @v_error = LIB_TRADUCTION @v_action, NULL, NULL, @v_inf_traduction out
					FETCH NEXT FROM c_information INTO @v_inf_traduction
				END
				CLOSE c_information
				DEALLOCATE c_information
				IF @v_error = 0
				BEGIN
					DELETE SAISIE WHERE SAI_VUE = @v_vue_id
					SELECT @v_error = @@ERROR
					IF @v_error = 0
					BEGIN
						DELETE VUE WHERE VUE_ID = @v_vue_id
						SELECT @v_error = @@ERROR
						IF @v_error = 0
						BEGIN
							EXEC @v_error = LIB_TRADUCTION @v_action, NULL, NULL, @v_tra_id out
							IF @v_error = 0
							BEGIN
								DELETE ENTREE WHERE ENT_OPERATION = @v_ope_id
								SELECT @v_error = @@ERROR
								IF @v_error = 0
								BEGIN
									DELETE ASSOCIATION_OPERATION_GROUPE WHERE AOG_OPERATION = @v_ope_id
									SELECT @v_error = @@ERROR
									IF @v_error = 0
									BEGIN
										DELETE OPERATION WHERE OPE_ID = @v_ope_id
										SELECT @v_error = @@ERROR
										IF @v_error = 0
										BEGIN
											EXEC @v_error = LIB_TRADUCTION @v_action, NULL, NULL, @v_ope_confirmation out
											IF @v_error = 0
											BEGIN
												EXEC @v_error = LIB_TRADUCTION @v_action, NULL, NULL, @v_ope_traduction out
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
		ELSE
			SELECT @v_retour = 114
	END
	IF @v_error <> 0
		ROLLBACK TRAN
	ELSE
		COMMIT TRAN
	RETURN @v_error

