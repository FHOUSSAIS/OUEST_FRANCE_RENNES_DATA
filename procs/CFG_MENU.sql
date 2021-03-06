SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER ON




-----------------------------------------------------------------------------------------
-- Procédure		: CFG_MENU
-- Paramètre d'entrées	:
--			  @v_action : Action à mener
--			  @v_men_ordre : Ordre d'affichage
--			  @v_lan_id : Identifiant langue
--			  @v_lib_libelle : Libellé
--			  @v_men_actif : menu actif ?
-- Paramètre de sorties	:
--			  @v_retour : Code de retour
--			  @v_men_id : Identifiant menu
-- Descriptif		: Gestion des voyants
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[CFG_MENU]
	@v_action smallint,
	@v_men_id int out,
	@v_men_ordre tinyint,
	@v_lan_id varchar(3),
	@v_lib_libelle varchar(8000),
	@v_men_actif bit,
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
	@v_old_men_ordre int,
	@v_smn_op int,
	@v_smn_trad int
	
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
			set @v_men_id = (select MAX(MEN_ID) FROM MENU) + 1
			IF @v_men_id IS NULL
				set @v_men_id = 0
			
			INSERT INTO MENU (MEN_ID, MEN_TRADUCTION, MEN_ACTIF, MEN_ORDRE, MEN_SYSTEME)
				   VALUES (@v_men_id, @v_tra_id, 1, @v_men_ordre, 0)

			SELECT @v_error = @@ERROR
			IF @v_error = 0
				SELECT @v_retour = 0
		END
	END
	ELSE IF @v_action = @ACTION_UPDATE
	BEGIN
		SELECT @v_tra_id = MEN_TRADUCTION FROM MENU WHERE MEN_ID = @v_men_id
		IF @v_tra_id IS NULL
			SELECT @v_retour = 0
		ELSE
		BEGIN
			UPDATE MENU SET MEN_ACTIF = @v_men_actif WHERE MEN_ID = @v_men_id
		   
			SELECT @v_error = @@ERROR
			IF @v_error = 0
			BEGIN
				UPDATE LIBELLE SET LIB_LIBELLE = @v_lib_libelle
							   WHERE LIB_TRADUCTION = @v_tra_id AND LIB_LANGUE = @v_lan_id
				SELECT @v_error = @@ERROR
				IF @v_error = 0
					SELECT @v_retour = 0
			END
		END
	END
	ELSE IF @v_action = @ACTION_DELETE
	BEGIN
		SELECT @v_tra_id = MEN_TRADUCTION, @v_men_ordre = MEN_ORDRE
			   FROM MENU WHERE MEN_ID = @v_men_id
		IF @v_tra_id IS NULL
			SELECT @v_retour = 0
		ELSE
		BEGIN
			DECLARE c_sousMenu CURSOR LOCAL
				FOR SELECT SMN_OPERATION, SMN_TRADUCTION
						   FROM SOUS_MENU WHERE SMN_MENU = @v_men_id
				FOR UPDATE
			OPEN c_sousMenu
			FETCH NEXT FROM c_sousMenu INTO @v_smn_op, @v_smn_trad
			
			WHILE ((@@FETCH_STATUS = 0) AND (@v_error = 0))
			BEGIN
				EXEC @v_error = CFG_SOUSMENU @v_action = @ACTION_DELETE, @v_men_id = @v_men_id,
										     @v_smn_op = @v_smn_op, @v_smn_trad = v_smn_trad,
										     @v_retour = @v_retour

				FETCH NEXT FROM c_sousMenu INTO @v_smn_op, @v_smn_trad
			END
	
			CLOSE c_sousMenu
			DEALLOCATE c_sousMenu
			
			IF @v_error = 0
			BEGIN
				DELETE MENU WHERE MEN_ID = @v_men_id
				SELECT @v_error = @@ERROR
				
				IF @v_error = 0
				BEGIN
					EXEC @v_error = LIB_TRADUCTION @ACTION_DELETE, NULL, NULL, @v_tra_id out
					
					IF @v_error = 0
					BEGIN
						-- on re-ordonne les autres menu
						UPDATE MENU SET MEN_ORDRE = MEN_ORDRE - 1 WHERE MEN_ORDRE > @v_men_ordre
						SELECT @v_error = @@ERROR
					
						IF @v_error = 0
							SELECT @v_retour = 0
					END
				END
			END
		END
	END
	ELSE IF @v_action = @ACTION_ORDER
	BEGIN
		SELECT @v_old_men_ordre = MEN_ORDRE FROM MENU WHERE MEN_ID = @v_men_id
		IF @v_men_ordre < @v_old_men_ordre
		BEGIN
			UPDATE MENU SET MEN_ORDRE = MEN_ORDRE + 1
				   WHERE MEN_ID <> @v_men_id AND MEN_ORDRE >= @v_men_ordre AND MEN_ORDRE < @v_old_men_ordre
			SELECT @v_error = @@ERROR
		END
		ELSE IF @v_men_ordre > @v_old_men_ordre
		BEGIN
			UPDATE MENU SET MEN_ORDRE = MEN_ORDRE - 1
				   WHERE MEN_ID <> @v_men_id AND MEN_ORDRE > @v_old_men_ordre AND MEN_ORDRE <= @v_men_ordre
			SELECT @v_error = @@ERROR
		END

		IF @v_error = 0
		BEGIN
			UPDATE MENU SET MEN_ORDRE = @v_men_ordre WHERE MEN_ID = @v_men_id
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

