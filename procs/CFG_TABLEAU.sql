SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER ON




-----------------------------------------------------------------------------------------
-- Procédure		: CFG_TABLEAU
-- Paramètre d'entrées	: @v_action : Action à mener
--			  @v_tab_sql : SQL
--			  @v_vue_ordre : Ordre d'affichage
--			  @v_lan_id : Identifiant langue
--			  @v_lib_libelle : Libellé
-- Paramètre de sorties	: @v_retour : Code de retour
--			  @v_vue_id : Identifiant vue
--			  @v_tra_id : Identifiant traduction
-- Descriptif		: Gestion des tableaux
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[CFG_TABLEAU]
	@v_action smallint,
	@v_vue_id int out,
	@v_tab_sql varchar(8000),
	@v_tab_menu_contextuel int,
	@v_mnc_traduction int,
	@v_vue_ordre tinyint,
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
	@v_vta_id tinyint,
	@v_col_id varchar(32),
	@v_col_traduction int,
	@v_smc_id int,
	@v_amm_ordre tinyint,
	@v_smc_traduction int,
	@v_ope_id int,
	@v_ope_traduction int,
	@v_ope_confirmation int,
	@v_clr_id int,
	@v_clr_ordre tinyint,
	@v_clr_traduction int

	BEGIN TRAN
	SELECT @v_retour = 113
	SELECT @v_error = 0
	IF @v_action = 0
	BEGIN
		EXEC @v_error = CFG_MENUCONTEXTUEL @v_action, 0, @v_tab_menu_contextuel out, 0, NULL, NULL, NULL, NULL, @v_tra_id, @v_lan_id, @v_lib_libelle, @v_retour out
		IF @v_error = 0 AND @v_retour = 0
		BEGIN
			EXEC @v_error = LIB_TRADUCTION @v_action, @v_lan_id, @v_lib_libelle, @v_tra_id out
			IF @v_error = 0
			BEGIN
				SELECT @v_vue_id = CASE SIGN(MIN(VUE_ID)) WHEN -1 THEN MIN(VUE_ID) - 1 ELSE -1 END FROM VUE
				INSERT INTO VUE (VUE_ID, VUE_TRADUCTION, VUE_TYPE_VUE, VUE_ORDRE, VUE_SYSTEME) VALUES (@v_vue_id, @v_tra_id, 4, @v_vue_ordre, 0)
				SELECT @v_error = @@ERROR
				IF @v_error = 0
				BEGIN
					SELECT @v_vta_id = VTA_ID FROM VUE_TABLEAU
					INSERT INTO TABLEAU (TAB_VUE, TAB_VUE_TABLEAU, TAB_MENU_CONTEXTUEL) VALUES (@v_vue_id, @v_vta_id, @v_tab_menu_contextuel)
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
	END
	ELSE IF @v_action = 2
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM COLORIAGE WHERE CLR_TABLEAU = @v_vue_id)
			SELECT @v_retour = 0
		ELSE
		BEGIN
			DECLARE c_coloriage CURSOR LOCAL FOR SELECT CLR_ID, CLR_ORDRE, CLR_TRADUCTION FROM COLORIAGE WHERE CLR_TABLEAU = @v_vue_id
			OPEN c_coloriage
			FETCH NEXT FROM c_coloriage INTO @v_clr_id, @v_clr_ordre, @v_clr_traduction
			WHILE ((@@FETCH_STATUS = 0) AND (@v_error = 0))
			BEGIN
				EXEC @v_error = CFG_COLORIAGE @v_action, @v_vue_id, @v_clr_id, @v_clr_traduction, NULL, NULL, @v_clr_ordre, NULL, NULL, @v_retour out
				IF @v_retour <> 0
					BREAK
				FETCH NEXT FROM c_coloriage INTO @v_clr_id, @v_clr_ordre, @v_clr_traduction
			END
			CLOSE c_coloriage
			DEALLOCATE c_coloriage
		END
		IF ((@v_error = 0) AND (@v_retour = 0))
		BEGIN
			DECLARE c_colonne CURSOR LOCAL FOR SELECT COL_ID, COL_TRADUCTION FROM COLONNE WHERE COL_TABLEAU = @v_vue_id FOR UPDATE
			OPEN c_colonne
			FETCH NEXT FROM c_colonne INTO @v_col_id, @v_col_traduction
			WHILE ((@@FETCH_STATUS = 0) AND (@v_error = 0))
			BEGIN
				DELETE ASSOCIATION_FILTRE_UTILISATEUR WHERE AFU_TABLEAU = @v_vue_id AND AFU_FILTRE = @v_col_id
				SELECT @v_error = @@ERROR
				IF @v_error = 0
				BEGIN
					DELETE FILTRE WHERE FIL_ID = @v_col_id AND FIL_TABLEAU = @v_vue_id
					SELECT @v_error = @@ERROR
					IF @v_error = 0
					BEGIN			
						DELETE ASSOCIATION_COLONNE_UTILISATEUR WHERE ACU_TABLEAU = @v_vue_id AND ACU_COLONNE = @v_col_id
						SELECT @v_error = @@ERROR
						IF @v_error = 0
						BEGIN
							DELETE ASSOCIATION_COLONNE_GROUPE WHERE ACG_TABLEAU = @v_vue_id AND ACG_COLONNE = @v_col_id
							SELECT @v_error = @@ERROR
							IF @v_error = 0
							BEGIN
								DELETE COLONNE WHERE CURRENT OF c_colonne
								SELECT @v_error = @@ERROR
								IF ((@v_col_traduction IS NOT NULL) AND (@v_error = 0))
									EXEC @v_error = LIB_TRADUCTION @v_action, NULL, NULL, @v_col_traduction out
							END
						END
					END
				END
				FETCH NEXT FROM c_colonne INTO @v_col_id, @v_col_traduction
			END
			CLOSE c_colonne
			DEALLOCATE c_colonne
		END
		IF @v_error = 0
		BEGIN
			DELETE TABLEAU WHERE TAB_VUE = @v_vue_id
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
		IF ((@v_error = 0) AND (@v_retour = 0))
		BEGIN
			DECLARE c_sous_contextuel CURSOR LOCAL FOR SELECT SMC_ID, AMM_ORDRE, SMC_TRADUCTION, SMC_OPERATION FROM ASSOCIATION_SOUS_MENU_CONTEXTUEL_MENU_CONTEXTUEL, SOUS_MENU_CONTEXTUEL
				WHERE AMM_MENU_CONTEXTUEL = @v_tab_menu_contextuel AND SMC_ID = AMM_SOUS_MENU_CONTEXTUEL
			OPEN c_sous_contextuel
			FETCH NEXT FROM c_sous_contextuel INTO @v_smc_id, @v_amm_ordre, @v_smc_traduction, @v_ope_id
			WHILE ((@@FETCH_STATUS = 0) AND (@v_error = 0))
			BEGIN
				EXEC @v_error = CFG_MENUCONTEXTUEL @v_action, 1, @v_tab_menu_contextuel, 0, NULL, @v_smc_id, @v_ope_id, @v_amm_ordre, @v_smc_traduction, NULL, NULL, @v_retour out
				IF @v_retour <> 0
					BREAK
				FETCH NEXT FROM c_sous_contextuel INTO @v_smc_id, @v_amm_ordre, @v_smc_traduction, @v_ope_id
			END
			CLOSE c_sous_contextuel
			DEALLOCATE c_sous_contextuel
			IF ((@v_error = 0) AND (@v_retour = 0))
				EXEC @v_error = CFG_MENUCONTEXTUEL @v_action, 0, @v_tab_menu_contextuel, 0, NULL, NULL, NULL, NULL, @v_mnc_traduction, NULL, NULL, @v_retour out
		END
	END
	IF ((@v_error = 0) AND (@v_retour = 0))
		COMMIT TRAN
	ELSE
		ROLLBACK TRAN
	RETURN @v_error

