SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF

-----------------------------------------------------------------------------------------
-- Procédure		: CFG_FILTRE
-- Paramètre d'entrées	: @v_action : Action à mener
--			  @v_fil_id : Identifiant
--			  @v_fil_tableau : Identifiant du tableau
--			  @v_col_visible : Visibilité de la colonne
--			  @v_lan_id : Identifiant langue
--			  @v_lib_libelle : Libellé
--			  @v_fil_champ : Champ
--			  @v_fil_sql : SQL
-- Paramètre de sorties	: @v_retour : Code de retour
--			  @v_tra_id : Identifiant traduction
-- Descriptif		: Gestion des filtres des vues tableaux
-----------------------------------------------------------------------------------------
-- Révision
-----------------------------------------------------------------------------------------
-- Date			: 27/09/2004
-- Auteur		: Cédric LE FRINGERE
-- Libellé			: Création de la procédure
-----------------------------------------------------------------------------------------
-- Date			: 08/04/2005
-- Auteur		: Cédric LE FRINGERE
-- Libellé			: Mise à jour code de retour
-----------------------------------------------------------------------------------------
-- Date			: 23/05/2005
-- Auteur		: Cédric LE FRINGERE
-- Libellé			: Distinction données standards/spécifiques
--			  Gestion du multi-langue
--			  Utilisation de LIB_TRADUCTION
-----------------------------------------------------------------------------------------
-- Date			: 06/10/2005
-- Auteur		: Cédric LE FRINGERE
-- Libellé			: Ordre des colonnes valeur et texte d'une liste déroulante
--			  Nom obligatoire des colonnes
-----------------------------------------------------------------------------------------
-- Date			: 08/09/2008
-- Auteur		: Cédric LE FRINGERE
-- Libellé			: Correction de la suppression d'un filtre d'une colonne
--			  non visible
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[CFG_FILTRE]
	@v_action smallint,
	@v_fil_id varchar(32),
	@v_fil_tableau int,
	@v_col_visible bit,
	@v_tra_id int out,
	@v_lan_id varchar(3),
	@v_lib_libelle varchar(8000),	
	@v_fil_champ int,
	@v_fil_sql varchar(7000),
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
	@v_fil_valeur varchar(32),
	@v_fil_texte varchar(32),
	@v_ordre int

	BEGIN TRAN
	SET @v_retour = 113
	SET @v_error = 0
	IF @v_action = 0
	BEGIN
		IF @v_tra_id IS NULL
		BEGIN
			EXEC @v_error = LIB_TRADUCTION @v_action, @v_lan_id, @v_fil_id, @v_tra_id out
			IF @v_error = 0
			BEGIN
				UPDATE COLONNE SET COL_TRADUCTION = @v_tra_id WHERE COL_ID = @v_fil_id AND COL_TABLEAU = @v_fil_tableau
				SET @v_error = @@ERROR
			END
		END
		IF @v_error = 0
		BEGIN
			INSERT INTO FILTRE (FIL_ID, FIL_TABLEAU, FIL_CHAMP) VALUES (@v_fil_id, @v_fil_tableau, 1)
			SET @v_error = @@ERROR
			IF @v_error = 0
				SET @v_retour = 0
		END
	END
	ELSE IF @v_action = 1
	BEGIN
		SELECT @v_don_id = CHA_DONNEE, @v_com_id = CHA_COMPOSANT FROM CHAMP WHERE CHA_ID = @v_fil_champ
		IF @v_com_id = 4
		BEGIN
			SET @v_cursor = 'DECLARE c_sql CURSOR GLOBAL FOR ' + @v_fil_sql
			EXEC (@v_cursor)
			SET @v_error = @@ERROR
			IF @v_error = 0
			BEGIN
				OPEN c_sql
				DECLARE c_colonne CURSOR LOCAL FOR SELECT DISTINCT column_name, ordinal_position FROM master.dbo.syscursorrefs scr, master.dbo.syscursorcolumns scc
					WHERE scr.cursor_scope = 2 AND scr.reference_name = 'c_sql' AND scr.cursor_handl = scc.cursor_handle ORDER BY ordinal_position DESC
				OPEN c_colonne
				FETCH NEXT FROM c_colonne INTO @v_fil_texte, @v_ordre
				IF @@FETCH_STATUS = 0
				BEGIN
					FETCH NEXT FROM c_colonne INTO @v_fil_valeur, @v_ordre
					IF @@FETCH_STATUS <> 0
						SET @v_fil_valeur = @v_fil_texte
				END
				IF ((@v_fil_texte IS NULL) OR (@v_fil_valeur IS NULL))
					SET @v_retour = 915
				ELSE
					UPDATE FILTRE SET FIL_CHAMP = @v_fil_champ, FIL_VALEUR = @v_fil_valeur, FIL_TEXTE = @v_fil_texte, FIL_SQL = @v_fil_sql, FIL_0 = NULL, FIL_1 = NULL, FIL_FORMAT = NULL WHERE FIL_ID = @v_fil_id AND FIL_TABLEAU = @v_fil_tableau
			END
			DEALLOCATE c_sql
		END
		ELSE IF @v_com_id = 2
		BEGIN
			UPDATE FILTRE SET FIL_CHAMP = @v_fil_champ, FIL_VALEUR = NULL, FIL_TEXTE = NULL, FIL_SQL = NULL, FIL_0 = NULL, FIL_1 = NULL, FIL_FORMAT = '!00/00/00 00:00:00;1;_' WHERE FIL_ID = @v_fil_id AND FIL_TABLEAU = @v_fil_tableau
			SET @v_error = @@ERROR
		END
		ELSE IF @v_com_id = 3
		BEGIN
			UPDATE FILTRE SET FIL_CHAMP = @v_fil_champ, FIL_VALEUR = NULL, FIL_TEXTE = NULL, FIL_SQL = NULL, FIL_0 = 19, FIL_1 = 18, FIL_FORMAT = NULL WHERE FIL_ID = @v_fil_id AND FIL_TABLEAU = @v_fil_tableau
			SET @v_error = @@ERROR
		END
		ELSE
		BEGIN
			UPDATE FILTRE SET FIL_CHAMP = @v_fil_champ, FIL_VALEUR = NULL, FIL_TEXTE = NULL, FIL_SQL = NULL, FIL_0 = NULL, FIL_1 = NULL, FIL_FORMAT = NULL WHERE FIL_ID = @v_fil_id AND FIL_TABLEAU = @v_fil_tableau
			SET @v_error = @@ERROR
		END
		IF ((@v_error = 0) AND (@v_retour <> 915))
		BEGIN
			IF @v_col_visible = 0
			BEGIN
				UPDATE LIBELLE SET LIB_LIBELLE = @v_lib_libelle WHERE LIB_TRADUCTION = @v_tra_id AND LIB_LANGUE = @v_lan_id
				SET @v_error = @@ERROR
				IF @v_error = 0
					SET @v_retour = 0
			END
			ELSE
				SET @v_retour = 0
		END
	END
	ELSE IF @v_action = 2
	BEGIN
		DELETE ASSOCIATION_FILTRE_UTILISATEUR WHERE AFU_FILTRE = @v_fil_id AND AFU_TABLEAU = @v_fil_tableau
		SET @v_error = @@ERROR
		IF @v_error = 0
		BEGIN
			DELETE FILTRE WHERE FIL_ID = @v_fil_id AND FIL_TABLEAU = @v_fil_tableau
			SET @v_error = @@ERROR
			IF @v_error = 0
			BEGIN
				IF @v_col_visible = 0
				BEGIN
					UPDATE COLONNE SET COL_TRADUCTION = NULL WHERE COL_ID = @v_fil_id AND COL_TABLEAU = @v_fil_tableau
					SET @v_error = @@ERROR
					IF @v_error = 0
					BEGIN
						EXEC @v_error = LIB_TRADUCTION @v_action, NULL, NULL, @v_tra_id out
						IF @v_error = 0
							SET @v_retour = 0
					END
				END
				ELSE
					SET @v_retour = 0
			END
		END
	END
	IF @v_error <> 0
		ROLLBACK TRAN
	ELSE
		COMMIT TRAN
	RETURN @v_error

