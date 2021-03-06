SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER ON



-----------------------------------------------------------------------------------------
-- Procédure		: CFG_OPERATION
-- Paramètre d'entrées	: @v_action : Action à mener
--			  @v_top_id : Type d'opération
--			  @v_lan_id : Identifiant langue
--			  @v_lib_libelle : Libellé
--			  @v_lib_libelle_confirmation : Libellé
--			  @v_ope_traitement : Identifiant traitement
--			  @v_ope_dll : Identifiant dll
-- Paramètre de sorties	: @v_retour : Code de retour
--			  @v_ope_id : Identifiant
--			  @v_tra_id : Identifiant traduction
--			  @v_ope_confirmation : Identifiant traduction
-- Descriptif		: Gestion des opérations
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[CFG_OPERATION]
	@v_action smallint,
	@v_ope_id int out,
	@v_top_id tinyint,
	@v_tra_id int out,
	@v_lan_id varchar(3),
	@v_lib_libelle varchar(8000),
	@v_ope_confirmation int out,
	@v_lib_libelle_confirmation varchar(8000),
	@v_ope_traitement varchar(32),
	@v_ope_dll varchar(32),
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
	@v_ent_nom varchar(32),
	@v_ent_type varchar(64),
	@v_ent_direction int

	BEGIN TRAN
	SELECT @v_retour = 113
	SELECT @v_error = 0
	IF @v_action = 0
	BEGIN
		IF @v_top_id = 2
		BEGIN
			IF EXISTS (SELECT 1 FROM sysobjects WHERE xtype = 'P' AND name = PARSENAME(@v_ope_traitement, 1))
			BEGIN
				EXEC @v_error = LIB_TRADUCTION @v_action, @v_lan_id, @v_lib_libelle_confirmation, @v_ope_confirmation out
				IF @v_error = 0
				BEGIN
					EXEC @v_error = LIB_TRADUCTION @v_action, @v_lan_id, @v_lib_libelle, @v_tra_id out
					IF @v_error = 0
					BEGIN
						SELECT @v_ope_id = ISNULL(MIN(OPE_ID) - 1, -1) FROM OPERATION
						INSERT INTO OPERATION (OPE_ID, OPE_TYPE_OPERATION, OPE_TRADUCTION, OPE_TRAITEMENT, OPE_CONFIRMATION, OPE_VISIBLE, OPE_SYSTEME)
							VALUES (@v_ope_id, 2, @v_tra_id, @v_ope_traitement, @v_ope_confirmation, 1, 0)
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
									SELECT @v_retour = 0
							END
						END
					END
				END
			END
			ELSE
				SELECT @v_retour = 115
		END
		ELSE IF @v_top_id = 4
		BEGIN
			EXEC @v_error = LIB_TRADUCTION @v_action, @v_lan_id, @v_lib_libelle, @v_tra_id out
			IF @v_error = 0
			BEGIN
				SELECT @v_ope_id = ISNULL(MIN(OPE_ID) - 1, -1) FROM OPERATION
				INSERT INTO OPERATION (OPE_ID, OPE_TYPE_OPERATION, OPE_TRADUCTION, OPE_DLL, OPE_VISIBLE, OPE_SYSTEME)
					VALUES (@v_ope_id, 4, @v_tra_id, @v_ope_dll, 1, 0)
				SELECT @v_error = @@ERROR
				IF @v_error = 0
				BEGIN
					INSERT INTO ASSOCIATION_OPERATION_GROUPE (AOG_GROUPE, AOG_OPERATION) SELECT GRP_ID, @v_ope_id FROM GROUPE WHERE GRP_ADMINISTRATEUR = 1
					SELECT @v_error = @@ERROR
					IF @v_error = 0
						SELECT @v_retour = 0
				END
			END
		END
	END
	ELSE IF @v_action = 1
	BEGIN
		IF EXISTS (SELECT 1 FROM OPERATION WHERE OPE_ID = @v_ope_id AND ((OPE_TYPE_OPERATION = 2 AND @v_top_id = 2 AND OPE_TRAITEMENT <> @v_ope_traitement)
			OR (OPE_TYPE_OPERATION = 2 AND @v_top_id = 4)))
		BEGIN
			IF NOT EXISTS ((SELECT 1 FROM SOUS_MENU_CONTEXTUEL WHERE SMC_OPERATION = @v_ope_id)
				UNION (SELECT 1 FROM SAISIE WHERE SAI_OPERATION = @v_ope_id)
				UNION (SELECT 1 FROM SOUS_MENU WHERE SMN_OPERATION = @v_ope_id))
			BEGIN
				DELETE ENTREE WHERE ENT_OPERATION = @v_ope_id
				SELECT @v_error = @@ERROR
				IF @v_error = 0
				BEGIN
					IF @v_top_id = 4
					BEGIN
						UPDATE OPERATION SET OPE_CONFIRMATION = NULL WHERE OPE_ID = @v_ope_id
						SELECT @v_error = @@ERROR
						IF @v_error = 0
						BEGIN
							EXEC @v_error = LIB_TRADUCTION 2, NULL, NULL, @v_ope_confirmation out
							SELECT @v_retour = 0
						END
					END
					ELSE
						SELECT @v_retour = 0
				END
			END
			ELSE
				SELECT @v_retour = 114
		END
		ELSE
			SELECT @v_retour = 0
		IF ((@v_error = 0) AND (@v_retour = 0))
		BEGIN
			IF (((@v_top_id = 2) AND EXISTS (SELECT 1 FROM sysobjects WHERE xtype = 'P' AND name = PARSENAME(@v_ope_traitement, 1)))
				OR (@v_top_id = 4))
			BEGIN
				UPDATE OPERATION SET OPE_TYPE_OPERATION = @v_top_id, OPE_TRAITEMENT = @v_ope_traitement, OPE_DLL = @v_ope_dll
					WHERE OPE_ID = @v_ope_id
				SELECT @v_error = @@ERROR
				IF @v_error = 0
				BEGIN
					IF @v_top_id = 2 AND NOT EXISTS (SELECT 1 FROM ENTREE WHERE ENT_OPERATION = @v_ope_id)
					BEGIN
						INSERT INTO ENTREE (ENT_ID, ENT_NOM, ENT_TRAITEMENT, ENT_OPERATION, ENT_NULL, ENT_TYPE, ENT_DIRECTION)
							SELECT (SELECT CASE SIGN(MIN(ENT_ID)) WHEN -1 THEN MIN(ENT_ID) - ORDINAL_POSITION ELSE -ORDINAL_POSITION END FROM ENTREE),
							PARAMETER_NAME, @v_ope_traitement, @v_ope_id, 0, DATA_TYPE, CASE WHEN PARAMETER_MODE = 'IN' THEN 20 ELSE 21 END
							FROM INFORMATION_SCHEMA.PARAMETERS WHERE SPECIFIC_NAME = PARSENAME(@v_ope_traitement, 1) ORDER BY ORDINAL_POSITION
						SELECT @v_error = @@ERROR
					END
				END
			END
			ELSE
				SELECT @v_retour = 115
		END
		IF ((@v_error = 0) AND (@v_retour = 0) AND (@v_top_id = 2))
		BEGIN
			UPDATE LIBELLE SET LIB_LIBELLE = @v_lib_libelle_confirmation WHERE LIB_TRADUCTION = @v_ope_confirmation AND LIB_LANGUE = @v_lan_id
			SELECT @v_error = @@ERROR
			IF @v_error = 0
				SELECT @v_retour = 0
		END
		IF ((@v_error = 0) AND (@v_retour = 0))
		BEGIN
			UPDATE LIBELLE SET LIB_LIBELLE = @v_lib_libelle WHERE LIB_TRADUCTION = @v_tra_id AND LIB_LANGUE = @v_lan_id
			SELECT @v_error = @@ERROR
			IF @v_error = 0
				SELECT @v_retour = 0
		END
	END
	ELSE IF @v_action = 2
	BEGIN
		IF NOT EXISTS ((SELECT 1 FROM SOUS_MENU_CONTEXTUEL WHERE SMC_OPERATION = @v_ope_id)
			UNION (SELECT 1 FROM SAISIE WHERE SAI_OPERATION = @v_ope_id)
			UNION (SELECT 1 FROM SOUS_MENU WHERE SMN_OPERATION = @v_ope_id))
		BEGIN
			IF @v_top_id = 2
			BEGIN
				DELETE ENTREE WHERE ENT_OPERATION = @v_ope_id
				SELECT @v_error = @@ERROR
			END
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
						IF @v_top_id = 2
							EXEC @v_error = LIB_TRADUCTION @v_action, NULL, NULL, @v_ope_confirmation out
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
		ELSE
			SELECT @v_retour = 114
	END
	IF @v_error <> 0
		ROLLBACK TRAN
	ELSE
		COMMIT TRAN
	RETURN @v_error

