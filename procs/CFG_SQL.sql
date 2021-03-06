SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER ON



-----------------------------------------------------------------------------------------
-- Procédure		: CFG_SQL
-- Paramètre d'entrées	: @v_tab_vue : Identifiant
--			  @v_tab_sql : SQL
--			  @v_tab_menu_contextuel : Menu contextuel
--			  @v_lan_id : Identifiant langue
-- Paramètre de sorties	: @v_retour : Code de retour
-- Descriptif		: Gestion des requêtes SQL des vues tableaux
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[CFG_SQL]
	@v_tab_vue int,
	@v_tab_sql varchar(8000),
	@v_tab_menu_contextuel int,
	@v_lan_id varchar(3),
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
	@v_cursor varchar(8000),
	@v_column_exists bit,
	@v_col_id varchar(32),
	@v_col_traduction int,
	@v_col_ordre tinyint,
	@v_col_classement tinyint,
	@v_col_visible bit

	BEGIN TRAN
	SELECT @v_retour = 113
	SELECT @v_error = 0
	SELECT @v_cursor = 'DECLARE c_sql CURSOR GLOBAL FOR ' + @v_tab_sql
	EXEC (@v_cursor)
	SELECT @v_error = @@ERROR
	IF @v_error = 0
	BEGIN
		UPDATE TABLEAU SET TAB_SQL = @v_tab_sql WHERE TAB_VUE = @v_tab_vue
		SELECT @v_error = @@ERROR
		IF @v_error = 0
		BEGIN
			SELECT * INTO #Tmp FROM COLONNE WHERE COL_TABLEAU = @v_tab_vue
			SELECT @v_column_exists = CASE WHEN EXISTS (SELECT 1 FROM #Tmp) THEN 1 ELSE 0 END
			OPEN c_sql
			DECLARE c_colonne CURSOR LOCAL FOR SELECT DISTINCT column_name, ordinal_position
				FROM master.dbo.syscursorrefs scr, master.dbo.syscursorcolumns scc
				WHERE scr.cursor_scope = 2 AND scr.reference_name = 'c_sql' AND scr.cursor_handl = scc.cursor_handle ORDER BY ordinal_position
			OPEN c_colonne
			FETCH NEXT FROM c_colonne INTO @v_col_id, @v_col_ordre
			WHILE ((@@FETCH_STATUS = 0) AND (@v_error = 0))
			BEGIN
				IF @v_col_id IS NULL
				BEGIN
					SELECT @v_retour = 915
					BREAK
				END
				ELSE
				BEGIN
					IF @v_column_exists = 0
					BEGIN
						EXEC @v_error = LIB_TRADUCTION 0, @v_lan_id, @v_col_id, @v_col_traduction out
						IF @v_error = 0
						BEGIN
							INSERT INTO COLONNE (COL_ID, COL_TABLEAU, COL_TRADUCTION, COL_ORDRE, COL_CLASSEMENT, COL_SENS, COL_VISIBLE, COL_FIXE)
								SELECT @v_col_id, @v_tab_vue, @v_col_traduction, ISNULL(MAX(COL_ORDRE), 0) + 1, ISNULL(MAX(COL_CLASSEMENT), 0) + 1, 0, 1, 0
								FROM COLONNE WHERE COL_TABLEAU = @v_tab_vue
							SELECT @v_error = @@ERROR
						END
					END
					ELSE
					BEGIN
						IF NOT EXISTS (SELECT 1 FROM #Tmp WHERE COL_ID = @v_col_id)
						BEGIN
							INSERT INTO COLONNE (COL_ID, COL_TABLEAU, COL_TRADUCTION, COL_ORDRE, COL_CLASSEMENT, COL_SENS, COL_VISIBLE, COL_FIXE)
								VALUES (@v_col_id, @v_tab_vue, NULL, NULL, NULL, NULL, 0, 0)
							SELECT @v_error = @@ERROR
						END
						ELSE
						BEGIN
							DELETE #Tmp WHERE COL_ID = @v_col_id
							SELECT @v_error = @@ERROR
						END
					END
					FETCH NEXT FROM c_colonne INTO @v_col_id, @v_col_ordre
				END
			END
			CLOSE c_colonne
			DEALLOCATE c_colonne
			CLOSE c_sql
			IF ((@v_error = 0) AND (@v_retour <> 915))
			BEGIN
				IF ((@v_column_exists = 1) AND EXISTS (SELECT 1 FROM #Tmp))
				BEGIN
					DECLARE c_colonne CURSOR LOCAL FOR SELECT COL_ID, COL_TRADUCTION, COL_ORDRE,
						COL_CLASSEMENT, COL_VISIBLE FROM #Tmp ORDER BY COL_ORDRE DESC
					OPEN c_colonne
					FETCH NEXT FROM c_colonne INTO @v_col_id, @v_col_traduction, @v_col_ordre, @v_col_classement, @v_col_visible
					WHILE ((@@FETCH_STATUS = 0) AND (@v_error = 0))
					BEGIN
						IF @v_col_visible = 1
							UPDATE COLONNE SET COL_ORDRE = COL_ORDRE - 1 WHERE COL_ID <> @v_col_id AND COL_TABLEAU = @v_tab_vue
								AND COL_ORDRE > @v_col_ordre AND COL_VISIBLE = 1
						SELECT @v_error = @@ERROR
						IF @v_error = 0
						BEGIN
							IF @v_col_visible = 1
								UPDATE COLONNE SET COL_CLASSEMENT = COL_CLASSEMENT - 1 WHERE COL_ID <> @v_col_id AND COL_TABLEAU = @v_tab_vue
									AND COL_CLASSEMENT > @v_col_classement AND COL_VISIBLE = 1
							SELECT @v_error = @@ERROR
							IF @v_error = 0
							BEGIN
								DELETE ASSOCIATION_FILTRE_UTILISATEUR WHERE AFU_FILTRE = @v_col_id AND AFU_TABLEAU = @v_tab_vue
								SELECT @v_error = @@ERROR
								IF @v_error = 0
								BEGIN
									DELETE FILTRE WHERE FIL_ID = @v_col_id AND FIL_TABLEAU = @v_tab_vue
									SELECT @v_error = @@ERROR
									IF @v_error = 0
									BEGIN
										UPDATE VALEUR SET VAL_INFORMATION = NULL WHERE VAL_INFORMATION = @v_col_id AND VAL_SOUS_MENU_CONTEXTUEL IN (
											SELECT AMM_SOUS_MENU_CONTEXTUEL FROM ASSOCIATION_SOUS_MENU_CONTEXTUEL_MENU_CONTEXTUEL WHERE AMM_MENU_CONTEXTUEL = @v_tab_menu_contextuel)
										SELECT @v_error = @@ERROR
										IF @v_error = 0
										BEGIN
											DELETE ASSOCIATION_COLONNE_UTILISATEUR WHERE ACU_COLONNE = @v_col_id AND ACU_TABLEAU = @v_tab_vue
											SELECT @v_error = @@ERROR
											IF @v_error = 0
											BEGIN
												DELETE ASSOCIATION_COLONNE_GROUPE WHERE ACG_COLONNE = @v_col_id AND ACG_TABLEAU = @v_tab_vue
												SELECT @v_error = @@ERROR
												IF @v_error = 0
												BEGIN
													DELETE COLONNE WHERE COL_ID = @v_col_id AND COL_TABLEAU = @v_tab_vue
													SELECT @v_error = @@ERROR
													IF ((@v_col_traduction IS NOT NULL) AND (@v_error = 0))
														EXEC @v_error = LIB_TRADUCTION 2, NULL, NULL, @v_col_traduction out
												END
											END
										END
									END
								END
							END
						END
						FETCH NEXT FROM c_colonne INTO @v_col_id, @v_col_traduction, @v_col_ordre, @v_col_classement, @v_col_visible
					END
					IF @v_error = 0
						SELECT @v_retour = 0
					CLOSE c_colonne
					DEALLOCATE c_colonne
				END
				ELSE
					SELECT @v_retour = 0
			END
			DROP TABLE #Tmp
		END
	END
	DEALLOCATE c_sql
	IF @v_error <> 0
		ROLLBACK TRAN
	ELSE
		COMMIT TRAN
	RETURN @v_error

