SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER ON





-----------------------------------------------------------------------------------------
-- Procédure		: CFG_MENUCONTEXTUEL
-- Paramètre d'entrées	: @v_action : Action à mener
--			  @v_ssaction : Sous action à mener
--			  @v_type : Type
--			    0 : Tableau
--			    1 : Synoptique
--			  @v_cat_id : Catégorie
--			  @v_smc_id : Sous-menu contextuel
--			  @v_smc_operation : Opération
--			  @v_amm_ordre : Ordre
--			  @v_lan_id : Identifiant langue
--			  @v_lib_libelle : Libellé
-- Paramètre de sorties	: @v_retour : Code de retour
--			  @v_mnc_id : Identifiant
--			  @v_tra_id : Identifiant traduction
-- Descriptif		: Gestion des menus contextuels des vues tableaux
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[CFG_MENUCONTEXTUEL]
	@v_action smallint,
	@v_ssaction smallint,
	@v_mnc_id int out,
	@v_type tinyint,
	@v_cat_id tinyint,
	@v_smc_id int,
	@v_smc_operation int,
	@v_amm_ordre tinyint,
	@v_tra_id int out,
	@v_lan_id varchar(3),
	@v_lib_libelle varchar(8000),
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
	@v_old_amm_ordre tinyint,
	@v_local bit

	IF @@TRANCOUNT > 0
		SELECT @v_local = 0
	ELSE
	BEGIN
		SELECT @v_local = 1
		BEGIN TRAN MENUCONTEXTUEL
	END
	SELECT @v_retour = 113
	SELECT @v_error = 0
	IF @v_action = 0
	BEGIN
		IF @v_ssaction = 0
		BEGIN
			EXEC @v_error = LIB_TRADUCTION @v_action, @v_lan_id, @v_lib_libelle, @v_tra_id out
			IF @v_error = 0
			BEGIN
				SELECT @v_mnc_id = CASE SIGN(MIN(MNC_ID)) WHEN -1 THEN MIN(MNC_ID) - 1 ELSE -1 END FROM MENU_CONTEXTUEL
				INSERT INTO MENU_CONTEXTUEL (MNC_ID, MNC_TYPE, MNC_CATEGORIE, MNC_TRADUCTION, MNC_SYSTEME)
					VALUES (@v_mnc_id , @v_type, @v_cat_id, @v_tra_id, 0)
				SELECT @v_error = @@ERROR
				IF @v_error = 0
					SELECT @v_retour = 0
			END
		END
		ELSE IF @v_ssaction = 1
		BEGIN
			EXEC @v_error = LIB_TRADUCTION @v_action, @v_lan_id, @v_lib_libelle, @v_tra_id out
			IF @v_error = 0
			BEGIN
				SELECT @v_smc_id = CASE SIGN(MIN(SMC_ID)) WHEN -1 THEN MIN(SMC_ID) - 1 ELSE -1 END FROM SOUS_MENU_CONTEXTUEL
				INSERT INTO SOUS_MENU_CONTEXTUEL (SMC_ID, SMC_TYPE, SMC_OPERATION, SMC_TRADUCTION, SMC_SYSTEME)
					VALUES (@v_smc_id, @v_type, @v_smc_operation, @v_tra_id, 0)
				SELECT @v_error = @@ERROR
				IF @v_error = 0
				BEGIN
					IF @v_type = 0
					BEGIN
						INSERT INTO ASSOCIATION_SOUS_MENU_CONTEXTUEL_MENU_CONTEXTUEL (AMM_MENU_CONTEXTUEL, AMM_SOUS_MENU_CONTEXTUEL, AMM_ORDRE)
							VALUES (@v_mnc_id, @v_smc_id, @v_amm_ordre)
						SELECT @v_error = @@ERROR
						IF @v_error = 0
						BEGIN
							UPDATE ASSOCIATION_SOUS_MENU_CONTEXTUEL_MENU_CONTEXTUEL SET AMM_ORDRE = AMM_ORDRE + 1
								WHERE AMM_MENU_CONTEXTUEL = @v_mnc_id AND AMM_SOUS_MENU_CONTEXTUEL <> @v_smc_id
								AND AMM_ORDRE >= @v_amm_ordre
							SELECT @v_error = @@ERROR
						END
					END
					ELSE IF @v_type = 1
					BEGIN
						INSERT INTO ASSOCIATION_CATEGORIE_SOUS_MENU_CONTEXTUEL (ACS_SOUS_MENU_CONTEXTUEL, ACS_CATEGORIE)
							VALUES (@v_smc_id, @v_cat_id)
						SELECT @v_error = @@ERROR
					END
					IF @v_error = 0
						EXEC @v_error = CFG_MENUCONTEXTUEL 1, 1, @v_mnc_id, 0, @v_cat_id, @v_smc_id, @v_smc_operation, NULL, NULL, NULL, NULL, @v_retour out
				END
			END
		END
		ELSE IF @v_ssaction = 2
		BEGIN
			INSERT INTO ASSOCIATION_SOUS_MENU_CONTEXTUEL_MENU_CONTEXTUEL (AMM_MENU_CONTEXTUEL, AMM_SOUS_MENU_CONTEXTUEL, AMM_ORDRE)
				SELECT @v_mnc_id, @v_smc_id, ISNULL(MAX(AMM_ORDRE), 0) + 1 FROM ASSOCIATION_SOUS_MENU_CONTEXTUEL_MENU_CONTEXTUEL
				WHERE AMM_MENU_CONTEXTUEL = @v_mnc_id
			SELECT @v_error = @@ERROR
			IF @v_error = 0
			BEGIN
				UPDATE OPERATION SET OPE_VISIBLE = 1 WHERE OPE_ID = @v_smc_operation AND OPE_VISIBLE = 0 AND OPE_SYSTEME = 1
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
			SELECT @v_old_amm_ordre = AMM_ORDRE FROM ASSOCIATION_SOUS_MENU_CONTEXTUEL_MENU_CONTEXTUEL
				WHERE AMM_MENU_CONTEXTUEL = @v_mnc_id AND AMM_SOUS_MENU_CONTEXTUEL = @v_smc_id
			IF @v_amm_ordre < @v_old_amm_ordre
			BEGIN
				UPDATE ASSOCIATION_SOUS_MENU_CONTEXTUEL_MENU_CONTEXTUEL SET AMM_ORDRE = AMM_ORDRE + 1
					WHERE AMM_MENU_CONTEXTUEL = @v_mnc_id AND AMM_SOUS_MENU_CONTEXTUEL <> @v_smc_id
					AND AMM_ORDRE >= @v_amm_ordre AND AMM_ORDRE < @v_old_amm_ordre
				SELECT @v_error = @@ERROR
			END
			ELSE IF @v_amm_ordre > @v_old_amm_ordre
			BEGIN
				UPDATE ASSOCIATION_SOUS_MENU_CONTEXTUEL_MENU_CONTEXTUEL SET AMM_ORDRE = AMM_ORDRE - 1
					WHERE AMM_MENU_CONTEXTUEL = @v_mnc_id AND AMM_SOUS_MENU_CONTEXTUEL <> @v_smc_id
					AND AMM_ORDRE > @v_old_amm_ordre AND AMM_ORDRE <= @v_amm_ordre
				SELECT @v_error = @@ERROR
			END
			IF @v_error = 0
			BEGIN
				UPDATE ASSOCIATION_SOUS_MENU_CONTEXTUEL_MENU_CONTEXTUEL SET AMM_ORDRE = @v_amm_ordre
					WHERE AMM_MENU_CONTEXTUEL = @v_mnc_id AND AMM_SOUS_MENU_CONTEXTUEL = @v_smc_id
				SELECT @v_error = @@ERROR
				IF @v_error = 0
					SELECT @v_retour = 0
			END
		END
		ELSE IF @v_ssaction = 1
		BEGIN
			UPDATE LIBELLE SET LIB_LIBELLE = @v_lib_libelle WHERE LIB_TRADUCTION = @v_tra_id AND LIB_LANGUE = @v_lan_id
			SELECT @v_error = @@ERROR
			IF @v_error = 0
			BEGIN
				DELETE VALEUR WHERE VAL_SOUS_MENU_CONTEXTUEL = @v_smc_id
				SELECT @v_error = @@ERROR
				IF @v_error = 0
				BEGIN
					INSERT INTO VALEUR (VAL_ENTREE, VAL_SOUS_MENU_CONTEXTUEL, VAL_INFORMATION)
						SELECT ENT_ID, @v_smc_id, NULL FROM ENTREE WHERE ENT_OPERATION = @v_smc_operation AND ENT_NULL = 0 AND ENT_VALEUR IS NULL
						AND NOT EXISTS (SELECT 1 FROM INFORMATION WHERE INF_ENTREE = ENT_ID)
					SELECT @v_error = @@ERROR
					IF @v_error = 0
					BEGIN
						UPDATE SOUS_MENU_CONTEXTUEL SET SMC_OPERATION = @v_smc_operation WHERE SMC_ID = @v_smc_id
						SELECT @v_error = @@ERROR
						IF @v_error = 0
						BEGIN
							UPDATE OPERATION SET OPE_VISIBLE = 1 WHERE OPE_ID = @v_smc_operation AND OPE_VISIBLE = 0 AND OPE_SYSTEME = 1
							SELECT @v_error = @@ERROR
							IF @v_error = 0
								SELECT @v_retour = 0
						END
					END
				END
			END
		END
		ELSE IF @v_ssaction = 2
		BEGIN
			DELETE ASSOCIATION_SOUS_MENU_CONTEXTUEL_MENU_CONTEXTUEL WHERE AMM_MENU_CONTEXTUEL = @v_mnc_id AND AMM_SOUS_MENU_CONTEXTUEL = @v_smc_id
			SELECT @v_error = @@ERROR
			IF @v_error = 0
			BEGIN
				UPDATE ASSOCIATION_SOUS_MENU_CONTEXTUEL_MENU_CONTEXTUEL SET AMM_ORDRE = AMM_ORDRE - 1
					WHERE AMM_MENU_CONTEXTUEL = @v_mnc_id AND AMM_ORDRE > @v_amm_ordre
				SELECT @v_error = @@ERROR
				IF @v_error = 0
					SELECT @v_retour = 0
			END
		END
		ELSE IF @v_ssaction = 3
		BEGIN
			UPDATE LIBELLE SET LIB_LIBELLE = @v_lib_libelle WHERE LIB_TRADUCTION = @v_tra_id AND LIB_LANGUE = @v_lan_id
			SELECT @v_error = @@ERROR
			IF @v_error = 0
				SELECT @v_retour = 0
		END
	END
	ELSE IF @v_action = 2
	BEGIN
		IF @v_ssaction = 0
		BEGIN
			IF NOT EXISTS ((SELECT 1 FROM TYPE_AGV WHERE TAG_MENU_CONTEXTUEL = @v_mnc_id)
				UNION (SELECT 1 FROM BASE WHERE BAS_MENU_CONTEXTUEL = @v_mnc_id)
				UNION (SELECT 1 FROM ITEM WHERE ITE_MENU_CONTEXTUEL = @v_mnc_id)
				UNION (SELECT 1 FROM CHARGE WHERE CHG_MENU_CONTEXTUEL = @v_mnc_id))
			BEGIN
				DELETE ASSOCIATION_SOUS_MENU_CONTEXTUEL_MENU_CONTEXTUEL WHERE AMM_MENU_CONTEXTUEL = @v_mnc_id
				SELECT @v_error = @@ERROR
				IF @v_error = 0
				BEGIN
					DELETE MENU_CONTEXTUEL WHERE MNC_ID = @v_mnc_id
					SELECT @v_error = @@ERROR
					IF @v_error = 0
					BEGIN
						EXEC @v_error = LIB_TRADUCTION @v_action, NULL, NULL, @v_tra_id out
						IF @v_error = 0
							SELECT @v_retour = 0
					END
				END
			END
			ELSE
				SELECT @v_retour = 114
		END
		ELSE IF @v_ssaction = 1
		BEGIN
			IF NOT EXISTS (SELECT 1 FROM ASSOCIATION_SOUS_MENU_CONTEXTUEL_MENU_CONTEXTUEL
				WHERE ((AMM_MENU_CONTEXTUEL <> @v_mnc_id AND @v_mnc_id IS NOT NULL)
				OR (@v_mnc_id IS NULL)) AND AMM_SOUS_MENU_CONTEXTUEL = @v_smc_id)
			BEGIN
				DELETE VALEUR WHERE VAL_SOUS_MENU_CONTEXTUEL = @v_smc_id
				SELECT @v_error = @@ERROR
				IF @v_error = 0
				BEGIN
					IF @v_type = 0
						DELETE ASSOCIATION_SOUS_MENU_CONTEXTUEL_MENU_CONTEXTUEL WHERE AMM_SOUS_MENU_CONTEXTUEL = @v_smc_id
					ELSE IF @v_type = 1
						DELETE ASSOCIATION_CATEGORIE_SOUS_MENU_CONTEXTUEL WHERE ACS_SOUS_MENU_CONTEXTUEL = @v_smc_id
					SELECT @v_error = @@ERROR
					IF @v_error = 0
					BEGIN
						DELETE SOUS_MENU_CONTEXTUEL WHERE SMC_ID = @v_smc_id
						SELECT @v_error = @@ERROR
						IF @v_error = 0
						BEGIN
							EXEC @v_error = LIB_TRADUCTION @v_action, NULL, NULL, @v_tra_id out
							IF @v_error = 0
							BEGIN
								IF @v_mnc_id IS NOT NULL
								BEGIN
									UPDATE ASSOCIATION_SOUS_MENU_CONTEXTUEL_MENU_CONTEXTUEL SET AMM_ORDRE = AMM_ORDRE - 1
										WHERE AMM_MENU_CONTEXTUEL = @v_mnc_id AND AMM_ORDRE > @v_amm_ordre
									SELECT @v_error = @@ERROR
									IF @v_error = 0
										SELECT @v_retour = 0
								END
								ELSE
									SELECT @v_retour = 0
							END
						END
					END
				END
			END
			ELSE
				SELECT @v_retour = 114
		END
	END
	IF @v_error = 0 AND @v_retour = 0
	BEGIN
		UPDATE OPERATION SET OPE_VISIBLE = 0 WHERE OPE_SYSTEME = 1 AND OPE_VISIBLE = 1
			AND NOT EXISTS (SELECT 1 FROM SOUS_MENU_CONTEXTUEL, ASSOCIATION_SOUS_MENU_CONTEXTUEL_MENU_CONTEXTUEL WHERE SMC_OPERATION = OPE_ID AND AMM_SOUS_MENU_CONTEXTUEL = SMC_ID)
			AND NOT EXISTS (SELECT 1 FROM SOUS_MENU, MENU WHERE SMN_OPERATION = OPE_ID AND MEN_ID = SMN_MENU AND MEN_ACTIF = 1)
			AND OPE_ID NOT IN (28, 30) AND OPE_TYPE_OPERATION IN (2, 4)
		SELECT @v_error = @@ERROR
		IF @v_error = 0
			SELECT @v_retour = 0
	END
	IF @v_local = 1
	BEGIN
		IF ((@v_error = 0) AND (@v_retour = 0))
			COMMIT TRAN MENUCONTEXTUEL
		ELSE
			ROLLBACK TRAN MENUCONTEXTUEL
	END
	RETURN @v_error

