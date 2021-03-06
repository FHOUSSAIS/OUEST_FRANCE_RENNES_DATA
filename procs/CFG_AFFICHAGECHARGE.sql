SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF


-----------------------------------------------------------------------------------------
-- Procédure		: CFG_AFFICHAGECHARGE
-- Paramètre d'entrée	: @v_action : Action à mener
--			  @v_ssaction : Sous action à mener
--			  @v_afc_id : Identifiant affichage charge
--			  @v_afc_actif : Actif
--			  @v_afc_sql : SQL
--			  @v_afc_ordre : Ordre
--			  @v_lib_libelle : Libellé
--			  @v_lan_id : Identifiant langue
--			  @v_tra_id : Identifiant traduction
-- Paramètre de sortie	: @v_retour : Code de retour
-- Descriptif		: Gestion de l'affichage des informations liées aux charges transportées
--			  sur l'AGV
-----------------------------------------------------------------------------------------
-- Révision
-----------------------------------------------------------------------------------------
-- Date			: 15/12/2005
-- Auteur		: Cédric LE FRINGERE
-- Libellé			: Création de la procédure
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[CFG_AFFICHAGECHARGE]
	@v_action smallint,
	@v_ssaction smallint,
	@v_afc_id int,
	@v_afc_actif bit,
	@v_afc_sql varchar(8000),
	@v_afc_ordre tinyint,
	@v_lib_libelle varchar(8000),
	@v_lan_id varchar(3),
	@v_tra_id int,
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
	@v_sql varchar(8000),
	@v_cursor varchar(8000),
	@v_old_afc_ordre tinyint

	BEGIN TRAN
	SELECT @v_retour = 113
	SELECT @v_error = 0
	IF @v_action = 0
	BEGIN
		SELECT @v_sql = REPLACE(@v_afc_sql, ':[Charge]', 0)
		SELECT @v_cursor = 'DECLARE c_sql CURSOR GLOBAL FOR ' + @v_sql
		EXEC (@v_cursor)
		SELECT @v_error = @@ERROR
		IF @v_error = 0
		BEGIN
			OPEN c_sql
			IF EXISTS (SELECT COUNT(*) FROM master.dbo.syscursorrefs scr, master.dbo.syscursorcolumns scc
				WHERE scr.cursor_scope = 2 AND scr.reference_name = 'c_sql' AND scr.cursor_handl = scc.cursor_handle
				HAVING COUNT(*) = 1)
			BEGIN
				EXEC @v_error = LIB_TRADUCTION @v_action, @v_lan_id, @v_lib_libelle, @v_tra_id out
				IF @v_error = 0
				BEGIN
					INSERT INTO AFFICHAGE_CHARGE (AFC_ID, AFC_TRADUCTION, AFC_ACTIF, AFC_SQL, AFC_SYSTEME)
						SELECT (SELECT CASE SIGN(MIN(AFC_ID)) WHEN -1 THEN MIN(AFC_ID) - 1 ELSE -1 END FROM AFFICHAGE_CHARGE),
						@v_tra_id, 0, @v_afc_sql, 0
					SELECT @v_error = @@ERROR
					IF @v_error = 0
						SELECT @v_retour = 0
				END
			END
			ELSE
				SELECT @v_retour = 976
			CLOSE c_sql
			DEALLOCATE c_sql
		END
	END
	ELSE IF @v_action = 1
	BEGIN
		IF @v_ssaction = 0
		BEGIN
			SELECT @v_sql = REPLACE(@v_afc_sql, ':[Charge]', 0)
			SELECT @v_cursor = 'DECLARE c_sql CURSOR GLOBAL FOR ' + @v_sql
			EXEC (@v_cursor)
			SELECT @v_error = @@ERROR
			IF @v_error = 0
			BEGIN
				OPEN c_sql
				IF EXISTS (SELECT COUNT(*) FROM master.dbo.syscursorrefs scr, master.dbo.syscursorcolumns scc
					WHERE scr.cursor_scope = 2 AND scr.reference_name = 'c_sql' AND scr.cursor_handl = scc.cursor_handle
					HAVING COUNT(*) = 1)
				BEGIN
					EXEC @v_error = LIB_LIBELLE @v_tra_id, @v_lan_id, @v_lib_libelle, @v_retour out
					IF ((@v_error = 0) AND (@v_retour = 0))
					BEGIN
						UPDATE AFFICHAGE_CHARGE SET AFC_SQL = @v_afc_sql WHERE AFC_ID = @v_afc_id
						SELECT @v_error = @@ERROR
						IF @v_error = 0
							SELECT @v_retour = 0
					END
				END
				ELSE
					SELECT @v_retour = 976
				CLOSE c_sql
				DEALLOCATE c_sql
			END
		END
		ELSE IF @v_ssaction = 1
		BEGIN
			IF @v_afc_actif = 0
			BEGIN
				UPDATE AFFICHAGE_CHARGE SET AFC_ACTIF = @v_afc_actif, AFC_ORDRE = NULL WHERE AFC_ID = @v_afc_id
				SELECT @v_error = @@ERROR
				IF @v_error = 0
				BEGIN
					UPDATE AFFICHAGE_CHARGE SET AFC_ORDRE = AFC_ORDRE - 1 WHERE AFC_ACTIF = 1 AND AFC_ORDRE > @v_afc_ordre
					SELECT @v_error = @@ERROR
					IF @v_error = 0
						SELECT @v_retour = 0
				END
			END
			ELSE IF @v_afc_actif = 1
			BEGIN
				IF NOT EXISTS (SELECT 1 FROM AFFICHAGE_CHARGE WHERE AFC_ID = @v_afc_id AND AFC_ACTIF = 1)
				BEGIN
					UPDATE AFFICHAGE_CHARGE SET AFC_ACTIF = @v_afc_actif, AFC_ORDRE = (SELECT ISNULL(MAX(AFC_ORDRE), 0) + 1 FROM AFFICHAGE_CHARGE)
						WHERE AFC_ID = @v_afc_id
					SELECT @v_error = @@ERROR
					IF @v_error = 0
						SELECT @v_retour = 0
				END
				ELSE
					SELECT @v_retour = 117
			END
		END
		ELSE IF @v_ssaction = 2
		BEGIN
			SELECT @v_old_afc_ordre = AFC_ORDRE FROM AFFICHAGE_CHARGE WHERE AFC_ID = @v_afc_id
			IF @v_afc_ordre < @v_old_afc_ordre
			BEGIN
				UPDATE AFFICHAGE_CHARGE SET AFC_ORDRE = AFC_ORDRE + 1
					WHERE AFC_ID <> @v_afc_id AND AFC_ORDRE >= @v_afc_ordre
					AND AFC_ORDRE < @v_old_afc_ordre
				SELECT @v_error = @@ERROR
			END
			ELSE IF @v_afc_ordre > @v_old_afc_ordre
			BEGIN
				UPDATE AFFICHAGE_CHARGE SET AFC_ORDRE = AFC_ORDRE - 1
					WHERE AFC_ID <> @v_afc_id AND AFC_ORDRE > @v_old_afc_ordre
					AND AFC_ORDRE <= @v_afc_ordre
				SELECT @v_error = @@ERROR
			END
			IF @v_error = 0
			BEGIN
				UPDATE AFFICHAGE_CHARGE SET AFC_ORDRE = @v_afc_ordre WHERE AFC_ID = @v_afc_id
				SELECT @v_error = @@ERROR
				IF @v_error = 0
					SELECT @v_retour = 0
			END
		END
	END
	ELSE IF @v_action = 2
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM AFFICHAGE_CHARGE WHERE AFC_ID = @v_afc_id AND AFC_ACTIF = 1)
		BEGIN
			DELETE AFFICHAGE_CHARGE WHERE AFC_ID = @v_afc_id
			SELECT @v_error = @@ERROR
			IF @v_error = 0
			BEGIN
				EXEC @v_error = LIB_TRADUCTION @v_action, NULL, NULL, @v_tra_id out
				IF @v_error = 0
					SELECT @v_retour = 0
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

