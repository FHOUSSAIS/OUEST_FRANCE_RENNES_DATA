SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER ON




-----------------------------------------------------------------------------------------
-- Procédure		: CFG_SOUSMENU
-- Paramètre d'entrées	:
--			  @v_action : Action à mener
--			  @v_men_id : identifiant du menu parent
--			  @v_smn_op : operation
--			  @v_lan_id : Identifiant langue
--			  @v_lib_libelle : Libellé
--			  @v_smn_ordre : Ordre d'affichage
-- Paramètre de sorties	:
--			  @v_retour : Code de retour
-- Descriptif		: Gestion des voyants
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[CFG_SOUSMENU]
	@v_action smallint,
	@v_men_id int,
	@v_smn_op int,
	@v_lan_id varchar(3),
	@v_lib_libelle varchar(8000),
	@v_smn_ordre tinyint,
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
	@ACTION_INSERT int,
	@ACTION_DELETE int,
	@ACTION_UPDATE int,
	@ACTION_ORDER int,
	@v_tra_id int,
	@v_old_smn_ordre int
		
	SET @ACTION_INSERT = 0
	SET @ACTION_UPDATE = 1
	SET @ACTION_DELETE = 2
	SET @ACTION_ORDER = 5
	

	BEGIN TRAN
	SELECT @v_retour = 113
	SELECT @v_error = 0
	
	IF @v_action = @ACTION_INSERT
	BEGIN
		EXEC @v_error = LIB_TRADUCTION @v_action, @v_lan_id, @v_lib_libelle, @v_tra_id out
		IF @v_error = 0
		BEGIN
			INSERT INTO SOUS_MENU (SMN_MENU, SMN_OPERATION, SMN_TRADUCTION, SMN_ORDRE)
				   VALUES (@v_men_id, @v_smn_op, @v_tra_id, @v_smn_ordre)

			SELECT @v_error = @@ERROR
			IF @v_error = 0
				SELECT @v_retour = 0
		END
	END
	ELSE IF @v_action = @ACTION_UPDATE
	BEGIN
		SELECT @v_tra_id = SMN_TRADUCTION FROM SOUS_MENU WHERE SMN_MENU = @v_men_id AND SMN_OPERATION = @v_smn_op
		UPDATE LIBELLE SET LIB_LIBELLE = @v_lib_libelle
					   WHERE LIB_TRADUCTION = @v_tra_id AND LIB_LANGUE = @v_lan_id

		SELECT @v_error = @@ERROR
		IF @v_error = 0
			SELECT @v_retour = 0
	END
	ELSE IF @v_action = @ACTION_DELETE
	BEGIN
		SELECT @v_smn_ordre = SMN_ORDRE, @v_tra_id = SMN_TRADUCTION FROM SOUS_MENU
			   WHERE SMN_MENU = @v_men_id AND SMN_OPERATION = @v_smn_op
		
		DELETE SOUS_MENU WHERE SMN_MENU = @v_men_id AND SMN_OPERATION = @v_smn_op
		SELECT @v_error = @@ERROR

		IF @v_error = 0
		BEGIN
			EXEC @v_error = LIB_TRADUCTION @v_action, NULL, NULL, @v_tra_id out
				
			IF @v_error = 0
			BEGIN
				-- on re-ordonne les autres sous menu
				UPDATE SOUS_MENU SET SMN_ORDRE = SMN_ORDRE - 1 WHERE SMN_ORDRE > @v_smn_ordre
				SELECT @v_error = @@ERROR
					
				IF @v_error = 0
					SELECT @v_retour = 0
			END
		END
	END
	ELSE IF @v_action = @ACTION_ORDER
	BEGIN
		SELECT @v_old_smn_ordre = SMN_ORDRE, @v_tra_id = SMN_TRADUCTION FROM SOUS_MENU
			   WHERE SMN_MENU = @v_men_id AND SMN_OPERATION = @v_smn_op
		
		IF @v_smn_ordre < @v_old_smn_ordre
		BEGIN
			UPDATE SOUS_MENU SET SMN_ORDRE = SMN_ORDRE + 1
				   WHERE SMN_MENU = @v_men_id AND SMN_OPERATION <> @v_smn_op
					     AND SMN_ORDRE >= @v_smn_ordre AND SMN_ORDRE < @v_old_smn_ordre
			SELECT @v_error = @@ERROR
		END
		ELSE IF @v_smn_ordre > @v_old_smn_ordre
		BEGIN
			UPDATE SOUS_MENU SET SMN_ORDRE = SMN_ORDRE - 1
				   WHERE SMN_MENU = @v_men_id AND SMN_OPERATION <> @v_smn_op
						 AND SMN_ORDRE > @v_old_smn_ordre AND SMN_ORDRE <= @v_smn_ordre
			SELECT @v_error = @@ERROR
		END

		IF @v_error = 0
		BEGIN
			UPDATE SOUS_MENU SET SMN_ORDRE = @v_smn_ordre
				   WHERE SMN_MENU = @v_men_id AND SMN_OPERATION = @v_smn_op
			
			SELECT @v_error = @@ERROR
			IF @v_error = 0
				SELECT @v_retour = 0
		END	
	END
	
	IF ((@v_error = 0) AND (@v_retour = 0))
		COMMIT TRAN
	ELSE
		ROLLBACK TRAN
	RETURN @v_error

