SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER ON




-----------------------------------------------------------------------------------------
-- Procédure		: CFG_COULEUR
-- Paramètre d'entrées	:
--			  @v_action : Action à mener
--			  @v_vyt_id : Identifiant vue
--			  @v_lan_id : Identifiant langue
--			  @v_lib_libelle : Libellé
--			  @v_cou_valeur : valeur
--			  @v_cou_couleur : couleur
-- Paramètre de sorties	:
--			  @v_retour : Code de retour
-- Descriptif		: Gestion des couleurs des voyants
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[CFG_COULEUR]
	@v_action smallint,
	@v_cou_voyant int,
	@v_lan_id varchar(3) = NULL,
	@v_lib_libelle varchar(8000) = NULL,
	@v_cou_valeur varchar(32),
	@v_cou_couleur int = NULL,
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
	@v_tra_id int,
	@v_cou_trad int,
	@v_vyt_tmp int
	
	SET @ACTION_INSERT = 0
	SET @ACTION_UPDATE = 1
	SET @ACTION_DELETE = 2


	BEGIN TRAN
	SELECT @v_retour = 113
	SELECT @v_error = 0
	
	IF @v_action = @ACTION_INSERT
	BEGIN
		EXEC @v_error = LIB_TRADUCTION @v_action, @v_lan_id, @v_lib_libelle, @v_tra_id out
		IF @v_error = 0
		BEGIN
			INSERT INTO COULEUR (COU_VOYANT, COU_VALEUR, COU_COULEUR, COU_TRADUCTION)
				   VALUES (@v_cou_voyant, @v_cou_valeur, @v_cou_couleur, @v_tra_id)

			SELECT @v_error = @@ERROR
			IF @v_error = 0
				SELECT @v_retour = 0
		END
	END
	ELSE IF @v_action = @ACTION_UPDATE
	BEGIN
		SELECT @v_tra_id = COU_TRADUCTION, @v_vyt_tmp = COU_VOYANT
			   FROM COULEUR
			   WHERE COU_VOYANT = @v_cou_voyant AND COU_VALEUR = @v_cou_valeur
	
		IF @v_vyt_tmp IS NULL
			SELECT @v_retour = 0
		ELSE
		BEGIN
			IF @v_tra_id IS NULL
			BEGIN
				EXEC @v_error = LIB_TRADUCTION @ACTION_INSERT, @v_lan_id, @v_lib_libelle, @v_tra_id out
			END
			ELSE
			BEGIN
				UPDATE LIBELLE SET LIB_LIBELLE = @v_lib_libelle
							   WHERE LIB_TRADUCTION = @v_tra_id AND LIB_LANGUE = @v_lan_id
				SELECT @v_error = @@ERROR
			END
		
			IF @v_error = 0
			BEGIN
				UPDATE COULEUR SET COU_COULEUR = @v_cou_couleur, COU_TRADUCTION = @v_tra_id
							   WHERE COU_VOYANT = @v_cou_voyant AND COU_VALEUR = @v_cou_valeur
			   
				SELECT @v_error = @@ERROR
			END
			
			IF @v_error = 0
				SELECT @v_retour = 0
		END
	END
	ELSE IF @v_action = @ACTION_DELETE
	BEGIN
		SELECT @v_cou_trad = COU_TRADUCTION FROM COULEUR
			   WHERE COU_VOYANT = @v_cou_voyant AND COU_VALEUR = @v_cou_valeur
		
		DELETE COULEUR WHERE COU_VOYANT = @v_cou_voyant AND COU_VALEUR = @v_cou_valeur
		SELECT @v_error = @@ERROR

		IF @v_error = 0
		BEGIN
			IF @v_cou_trad IS NOT NULL
				EXEC @v_error = LIB_TRADUCTION @v_action, NULL, NULL, @v_cou_trad out
				
			IF @v_error = 0
				SELECT @v_retour = 0
		END
	END

	IF ((@v_error = 0) AND (@v_retour = 0))
		COMMIT TRAN
	ELSE
		ROLLBACK TRAN
	RETURN @v_error

