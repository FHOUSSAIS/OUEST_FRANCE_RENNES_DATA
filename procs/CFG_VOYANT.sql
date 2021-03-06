SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER ON




-----------------------------------------------------------------------------------------
-- Procédure		: CFG_VOYANT
-- Paramètre d'entrées	:
--			  @v_action : Action à mener
--			  @v_vyt_ordre : Ordre d'affichage
--			  @v_lan_id : Identifiant langue
--			  @v_lib_libelle : Libellé
--			  @v_vyt_sql : requete sql
--			  @v_vyt_actif : voyant actif ?
-- Paramètre de sorties	:
--			  @v_retour : Code de retour
--			  @v_vyt_id : Identifiant vue
-- Descriptif		: Gestion des voyants
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[CFG_VOYANT]
	@v_action smallint,
	@v_vyt_id int out,
	@v_vyt_ordre tinyint,
	@v_lan_id varchar(3),
	@v_lib_libelle varchar(8000),
	@v_vyt_sql varchar(8000),
	@v_vyt_actif bit,
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
	@v_cou_valeur int,
	@v_old_vyt_ordre int
	
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
			set @v_vyt_id = (select MAX(VYT_ID) FROM VOYANT) + 1
			INSERT INTO VOYANT (VYT_ID, VYT_TRADUCTION, VYT_ACTIF, VYT_SQL, VYT_ORDRE, VYT_SYSTEME)
				   VALUES (@v_vyt_id, @v_tra_id, 1, '', @v_vyt_ordre, 0)

			SELECT @v_error = @@ERROR
			IF @v_error = 0
				SELECT @v_retour = 0
		END
	END
	ELSE IF @v_action = @ACTION_UPDATE
	BEGIN
		SELECT @v_tra_id = VYT_TRADUCTION FROM VOYANT WHERE VYT_ID = @v_vyt_id
		IF @v_tra_id IS NULL
			SELECT @v_retour = 0
		ELSE
		BEGIN
			IF @v_vyt_sql IS NOT NULL
			BEGIN
				EXEC (@v_vyt_sql)
				SELECT @v_error = @@ERROR
			END
			
			IF @v_error = 0
			BEGIN
				UPDATE VOYANT SET VYT_SQL = @v_vyt_sql, VYT_ACTIF = @v_vyt_actif
							  WHERE VYT_ID = @v_vyt_id
			   
				SELECT @v_error = @@ERROR
				IF @v_error = 0
				BEGIN
					UPDATE LIBELLE SET LIB_LIBELLE = @v_lib_libelle
								   WHERE LIB_TRADUCTION = @v_tra_id AND LIB_LANGUE = @v_lan_id
					IF @v_error = 0
						SELECT @v_retour = 0
				END
			END
		END
	END
	ELSE IF @v_action = @ACTION_DELETE
	BEGIN
		SELECT @v_tra_id = VYT_TRADUCTION, @v_vyt_ordre = VYT_ORDRE FROM VOYANT WHERE VYT_ID = @v_vyt_id
		IF @v_tra_id IS NULL
			SELECT @v_retour = 0
		ELSE
		BEGIN
			DECLARE c_couleur CURSOR LOCAL
				FOR SELECT COU_VALEUR FROM COULEUR WHERE COU_VOYANT = @v_vyt_id
				FOR UPDATE
			OPEN c_couleur
			FETCH NEXT FROM c_couleur INTO @v_cou_valeur
			
			WHILE ((@@FETCH_STATUS = 0) AND (@v_error = 0))
			BEGIN
				EXEC @v_error = CFG_COULEUR @v_action = @ACTION_DELETE, @v_cou_voyant = @v_vyt_id,
										    @v_cou_valeur = @v_cou_valeur, @v_retour = @v_retour

				FETCH NEXT FROM c_couleur INTO @v_cou_valeur
			END
	
			CLOSE c_couleur
			DEALLOCATE c_couleur
			
			IF @v_error = 0
			BEGIN
				DELETE VOYANT WHERE VYT_ID = @v_vyt_id
				SELECT @v_error = @@ERROR
				
				IF @v_error = 0
				BEGIN
					EXEC @v_error = LIB_TRADUCTION @ACTION_DELETE, NULL, NULL, @v_tra_id out
					
					IF @v_error = 0
					BEGIN
						-- on re-ordonne les autres voyants
						UPDATE VOYANT SET VYT_ORDRE = VYT_ORDRE - 1 WHERE VYT_ORDRE > @v_vyt_ordre
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
		SELECT @v_old_vyt_ordre = VYT_ORDRE FROM VOYANT WHERE VYT_ID = @v_vyt_id
		IF @v_vyt_ordre < @v_old_vyt_ordre
		BEGIN
			UPDATE VOYANT SET VYT_ORDRE = VYT_ORDRE + 1
				   WHERE VYT_ID <> @v_vyt_id AND VYT_ORDRE >= @v_vyt_ordre AND VYT_ORDRE < @v_old_vyt_ordre
			SELECT @v_error = @@ERROR
		END
		ELSE IF @v_vyt_ordre > @v_old_vyt_ordre
		BEGIN
			UPDATE VOYANT SET VYT_ORDRE = VYT_ORDRE - 1
				   WHERE VYT_ID <> @v_vyt_id AND VYT_ORDRE > @v_old_vyt_ordre AND VYT_ORDRE <= @v_vyt_ordre
			SELECT @v_error = @@ERROR
		END
		IF @v_error = 0
		BEGIN
			UPDATE VOYANT SET VYT_ORDRE = @v_vyt_ordre WHERE VYT_ID = @v_vyt_id
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

