SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF





-----------------------------------------------------------------------------------------
-- Procédure		: IHM_FILTREUTILISATEUR
-- Paramètre d'entrée	: @v_action : Action à mener
--			  @v_afu_tableau : Tableau
--			  @v_afu_filtre : Ordre
--			  @v_utilisateur : Utilisateur
-- Paramètre de sortie	: @v_retour : Code de retour
-- Descriptif		: Gestion des filtres des vues tableaux d'un utilisateur
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[IHM_FILTREUTILISATEUR]
	@v_action smallint,
	@v_afu_tableau int,
	@v_afu_filtre varchar(32),
	@v_afu_operateur tinyint,
	@v_afu_valeur varchar(4000),
	@v_afu_texte varchar(4000),
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
	@v_cursor varchar(8000),
	@v_sqlSelect nvarchar(4000),
	@v_type_name sysname,
	@v_old_avu_ordre tinyint

	BEGIN TRAN
	SET @v_retour = 113
	SET @v_error = 0
	IF @v_action = 0
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM ASSOCIATION_FILTRE_UTILISATEUR WHERE AFU_UTILISATEUR = @v_utilisateur AND AFU_TABLEAU = @v_afu_tableau
			AND AFU_FILTRE = @v_afu_filtre AND AFU_OPERATEUR = @v_afu_operateur AND AFU_VALEUR = @v_afu_valeur)
		BEGIN
			SELECT @v_cursor = 'DECLARE c_sql CURSOR GLOBAL FOR ' + TAB_SQL FROM TABLEAU WHERE TAB_VUE = @v_afu_tableau
			EXEC (@v_cursor)
			SET @v_error = @@ERROR
			IF @v_error = 0
			BEGIN
				SET @v_sqlSelect = 'SELECT @v_type_name = st.name FROM master.dbo.syscursorrefs scr INNER JOIN master.dbo.syscursorcolumns scc
					ON scr.cursor_handl = scc.cursor_handle INNER JOIN master.dbo.systypes st ON st.xtype = data_type_sql
					WHERE scr.cursor_scope = 2 AND scr.reference_name = ''c_sql'' AND column_name = ''' + @v_afu_filtre + ''''
				EXEC sp_executesql @v_sqlSelect, N'@v_type_name sysname out', @v_type_name = @v_type_name out
				SET @v_error = @@ERROR
				IF @v_error = 0
				BEGIN
					SET @v_sqlSelect = 'SELECT CONVERT(''' + @v_type_name + ''', ' + @v_afu_valeur + ')'
					BEGIN TRY
						EXEC('SELECT CONVERT(' + @v_type_name + ', ''' + @v_afu_valeur + ''')')
						SET @v_error = @@ERROR
						IF @v_error = 0
						BEGIN
							INSERT INTO ASSOCIATION_FILTRE_UTILISATEUR (AFU_UTILISATEUR, AFU_TABLEAU, AFU_FILTRE, AFU_OPERATEUR, AFU_VALEUR, AFU_TEXTE) 
								VALUES (@v_utilisateur, @v_afu_tableau, @v_afu_filtre, @v_afu_operateur, @v_afu_valeur, @v_afu_texte)
							SET @v_error = @@ERROR
							IF @v_error = 0
								SET @v_retour = 0
						END
					END TRY
					BEGIN CATCH
						SET @v_error = @@ERROR
						IF @v_error IN (220, 244)
							SET @v_retour = 2039
						SET @v_error = 0
					END CATCH	
				END
			END
			DEALLOCATE c_sql
		END
		ELSE
			SET @v_retour = 0
	END
	ELSE IF @v_action = 2
	BEGIN
		DELETE ASSOCIATION_FILTRE_UTILISATEUR WHERE AFU_UTILISATEUR = @v_utilisateur AND AFU_TABLEAU = @v_afu_tableau
		SET @v_error = @@ERROR
		IF @v_error = 0
			SET @v_retour = 0
	END
	IF @v_error <> 0
		ROLLBACK TRAN
	ELSE
		COMMIT TRAN

	RETURN @v_error

