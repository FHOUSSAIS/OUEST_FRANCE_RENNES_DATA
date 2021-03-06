SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER ON




-----------------------------------------------------------------------------------------
-- Procédure		: CFG_PARAMETRESPEC
-- Paramètre d'entrées	:
--			  @v_action : Action à mener
--			  @v_par_nom : nom du parametre
--			  @v_par_val : valeur du parametre
--			  @v_lan_id : Identifiant langue
--			  @v_lib_libelle : Libellé
-- Paramètre de sorties	:
--			  @v_retour : Code de retour
-- Descriptif		: Gestion des parametres specifiques
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].CFG_PARAMETRESPEC
	@v_action smallint,
	@v_par_nom varchar(16),
	@v_par_val varchar(128),
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
	@ACTION_INSERT int,
	@ACTION_DELETE int,
	@ACTION_UPDATE int,
	@v_tra_id int
		
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
		INSERT INTO PARAMETRE
			(PAR_NOM, PAR_VAL, PAR_SYSTEME, PAR_MODIF, PAR_TYPE, PAR_UNITE, PAR_FORMAT, PAR_DEFAUT, PAR_IDTRADUCTION)
			VALUES(@v_par_nom, @v_par_val, 0, 1, 'S', NULL, NULL, '', @v_tra_id)

			SELECT @v_error = @@ERROR
			IF @v_error = 0
				SELECT @v_retour = 0
		END
	END
	ELSE IF @v_action = @ACTION_UPDATE
	BEGIN
		SELECT @v_tra_id = PAR_IDTRADUCTION FROM PARAMETRE WHERE PAR_NOM = @v_par_nom
		UPDATE LIBELLE SET LIB_LIBELLE = @v_lib_libelle
					   WHERE LIB_TRADUCTION = @v_tra_id AND LIB_LANGUE = @v_lan_id

		SELECT @v_error = @@ERROR
		IF @v_error = 0
		BEGIN
			UPDATE PARAMETRE SET PAR_VAL = @v_par_val WHERE PAR_NOM = @v_par_nom
			SELECT @v_error = @@ERROR
			IF @v_error = 0
				SELECT @v_retour = 0
		END
	END
	ELSE IF @v_action = @ACTION_DELETE
	BEGIN
		SELECT @v_tra_id = PAR_IDTRADUCTION FROM PARAMETRE WHERE PAR_NOM = @v_par_nom

		DELETE PARAMETRE WHERE PAR_NOM = @v_par_nom
		SELECT @v_error = @@ERROR

		IF @v_error = 0
		BEGIN
			EXEC @v_error = LIB_TRADUCTION @v_action, NULL, NULL, @v_tra_id out
				
			IF @v_error = 0
				SELECT @v_retour = 0
		END
	END
	
	IF ((@v_error = 0) AND (@v_retour = 0))
		COMMIT TRAN
	ELSE
		ROLLBACK TRAN
	RETURN @v_error

