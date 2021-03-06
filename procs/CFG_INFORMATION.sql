SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF

-----------------------------------------------------------------------------------------
-- Procédure		: CFG_INFORMATION
-- Paramètre d'entrées	: @v_action : Action à mener
--			  @v_ssaction : Sous action à mener
--			  @v_inf_saisie : Saisie
--			  @v_inf_entree : Entrée
--			  @v_inf_ordre : Ordre
--			  @v_lib_libelle : Libellé
--			  @v_lan_id : Identifiant langue
--			  @v_inf_liaison : Entrée liée
--			  @v_inf_champ : Champ
--			  @v_inf_valeur : Valeur
--			  @v_inf_valeur : SQL
--			  @v_inf_null : Nullable
-- Paramètre de sorties	: @v_retour : Code de retour
--			  @v_tra_id : Identifiant traduction
-- Descriptif		: Gestion des informations de saisies
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[CFG_INFORMATION]
	@v_action smallint,	
	@v_ssaction smallint,
	@v_inf_saisie int,
	@v_inf_entree int,
	@v_tra_id int out,
	@v_inf_ordre tinyint,
	@v_lan_id varchar(3),
	@v_lib_libelle varchar(8000),
	@v_inf_champ int,
	@v_inf_valeur varchar(32),
	@v_inf_sql varchar(7000),
	@v_inf_liaison int,
	@v_inf_null bit,
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
	@v_don_id tinyint,
	@v_com_id tinyint,
	@v_cursor varchar(8000),
	@v_inf_texte varchar(32),
	@v_old_inf_ordre tinyint,
	@v_ordre int

	BEGIN TRAN
	SELECT @v_retour = 113
	SELECT @v_error = 0
	IF @v_action = 0
	BEGIN
		SELECT @v_lib_libelle = CONVERT(varchar, @v_inf_entree)
		EXEC @v_error = LIB_TRADUCTION @v_action, @v_lan_id, @v_lib_libelle, @v_tra_id out
		IF @v_error = 0
		BEGIN
			INSERT INTO INFORMATION (INF_SAISIE, INF_ENTREE, INF_TRADUCTION, INF_CHAMP, INF_ORDRE, INF_NULL)
				VALUES (@v_inf_saisie, @v_inf_entree, @v_tra_id, 1, @v_inf_ordre, 0)
			SELECT @v_error = @@ERROR
			IF @v_error = 0
			BEGIN
				DELETE VALEUR WHERE VAL_ENTREE = @v_inf_entree
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
			SELECT @v_don_id = CHA_DONNEE, @v_com_id = CHA_COMPOSANT FROM CHAMP WHERE CHA_ID = @v_inf_champ
			IF @v_com_id = 4
			BEGIN
				IF @v_inf_liaison IS NULL
				BEGIN
					SELECT @v_cursor = 'DECLARE c_sql CURSOR GLOBAL FOR ' + @v_inf_sql
					EXEC (@v_cursor)
					SELECT @v_error = @@ERROR
					IF @v_error = 0
					BEGIN
						OPEN c_sql
						DECLARE c_colonne CURSOR LOCAL FOR SELECT DISTINCT column_name, ordinal_position FROM master.dbo.syscursorrefs scr, master.dbo.syscursorcolumns scc
							WHERE scr.cursor_scope = 2 AND scr.reference_name = 'c_sql' AND scr.cursor_handl = scc.cursor_handle ORDER BY ordinal_position DESC
						OPEN c_colonne
						FETCH NEXT FROM c_colonne INTO @v_inf_texte, @v_ordre
						IF @@FETCH_STATUS = 0
						BEGIN
							WHILE @@FETCH_STATUS = 0
							BEGIN
								FETCH NEXT FROM c_colonne INTO @v_inf_valeur, @v_ordre
							END
							IF @v_inf_valeur IS NULL
								SELECT @v_inf_valeur = @v_inf_texte
						END
						IF ((@v_inf_texte IS NULL) OR (@v_inf_valeur IS NULL))
							SELECT @v_retour = 915
						ELSE
						BEGIN
							UPDATE INFORMATION SET INF_CHAMP = @v_inf_champ, INF_VALEUR = @v_inf_valeur, INF_TEXTE = @v_inf_texte, INF_SQL = @v_inf_sql, INF_0 = NULL, INF_1 = NULL, INF_FORMAT = NULL, INF_LIAISON = NULL
								WHERE INF_ENTREE = @v_inf_entree AND INF_SAISIE = @v_inf_saisie
							SELECT @v_error = @@ERROR
						END
					END
					CLOSE c_sql
					DEALLOCATE c_sql
				END
				ELSE
				BEGIN
					UPDATE INFORMATION SET INF_CHAMP = @v_inf_champ, INF_VALEUR = @v_inf_valeur, INF_TEXTE = NULL, INF_SQL = NULL, INF_0 = NULL, INF_1 = NULL, INF_FORMAT = NULL, INF_LIAISON = @v_inf_liaison
						WHERE INF_ENTREE = @v_inf_entree AND INF_SAISIE = @v_inf_saisie
					SELECT @v_error = @@ERROR
				END
			END
			ELSE IF @v_com_id = 2
			BEGIN
				UPDATE INFORMATION SET INF_CHAMP = @v_inf_champ, INF_VALEUR = NULL, INF_TEXTE = NULL, INF_SQL = NULL, INF_0 = NULL, INF_1 = NULL, INF_FORMAT = '!00/00/00 00:00:00;1;_'
					WHERE INF_ENTREE = @v_inf_entree AND INF_SAISIE = @v_inf_saisie
				SELECT @v_error = @@ERROR
			END
			ELSE IF @v_com_id = 3
			BEGIN
				UPDATE INFORMATION SET INF_CHAMP = @v_inf_champ, INF_VALEUR = NULL, INF_TEXTE = NULL, INF_SQL = NULL, INF_0 = 19, INF_1 = 18, INF_FORMAT = NULL
					WHERE INF_ENTREE = @v_inf_entree AND INF_SAISIE = @v_inf_saisie
				SELECT @v_error = @@ERROR
			END
			ELSE
			BEGIN
				UPDATE INFORMATION SET INF_CHAMP = @v_inf_champ, INF_VALEUR = NULL, INF_TEXTE = NULL, INF_SQL = NULL, INF_0 = NULL, INF_1 = NULL, INF_FORMAT = NULL, INF_NULL = @v_inf_null
					WHERE INF_ENTREE = @v_inf_entree AND INF_SAISIE = @v_inf_saisie
				SELECT @v_error = @@ERROR
			END
			IF ((@v_error = 0) AND (@v_retour <> 915))
			BEGIN
				UPDATE LIBELLE SET LIB_LIBELLE = @v_lib_libelle WHERE LIB_TRADUCTION = @v_tra_id AND LIB_LANGUE = @v_lan_id
				SELECT @v_error = @@ERROR
				IF @v_error = 0
					SELECT @v_retour = 0
			END
		END
		ELSE IF @v_ssaction = 1
		BEGIN
			SELECT @v_old_inf_ordre = INF_ORDRE FROM INFORMATION WHERE INF_ENTREE = @v_inf_entree AND INF_SAISIE = @v_inf_saisie
			IF @v_inf_ordre < @v_old_inf_ordre
			BEGIN
				UPDATE INFORMATION SET INF_ORDRE = INF_ORDRE + 1 WHERE INF_ENTREE <> @v_inf_entree AND INF_SAISIE = @v_inf_saisie AND INF_ORDRE >= @v_inf_ordre
					AND INF_ORDRE < @v_old_inf_ordre
				SELECT @v_error = @@ERROR
			END
			ELSE IF @v_inf_ordre > @v_old_inf_ordre
			BEGIN
				UPDATE INFORMATION SET INF_ORDRE = INF_ORDRE - 1 WHERE INF_ENTREE = @v_inf_entree AND INF_SAISIE = @v_inf_saisie AND INF_ORDRE > @v_old_inf_ordre
					AND INF_ORDRE <= @v_inf_ordre
				SELECT @v_error = @@ERROR
			END
			IF @v_error = 0
			BEGIN
				UPDATE INFORMATION SET INF_ORDRE = @v_inf_ordre WHERE INF_ENTREE = @v_inf_entree AND INF_SAISIE = @v_inf_saisie
				SELECT @v_error = @@ERROR
				IF @v_error = 0
					SELECT @v_retour = 0
			END
		END
	END
	ELSE IF @v_action = 2
	BEGIN
		DELETE INFORMATION WHERE INF_SAISIE = @v_inf_saisie AND INF_ENTREE = @v_inf_entree
		SELECT @v_error = @@ERROR
		IF @v_error = 0
		BEGIN
			UPDATE INFORMATION SET INF_ORDRE = INF_ORDRE - 1 WHERE INF_SAISIE = @v_inf_saisie AND INF_ORDRE > @v_inf_ordre
			SELECT @v_error = @@ERROR
			IF @v_error = 0
			BEGIN
				INSERT INTO VALEUR (VAL_ENTREE, VAL_SOUS_MENU_CONTEXTUEL, VAL_INFORMATION)
					SELECT @v_inf_entree, SMC_ID, NULL FROM ENTREE, SOUS_MENU_CONTEXTUEL
					WHERE ENT_ID = @v_inf_entree AND SMC_OPERATION = ENT_OPERATION
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
	IF @v_error <> 0
		ROLLBACK TRAN
	ELSE
		COMMIT TRAN
	RETURN @v_error

