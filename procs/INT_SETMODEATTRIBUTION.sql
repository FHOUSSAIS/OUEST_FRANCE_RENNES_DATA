SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF

CREATE  PROCEDURE [dbo].[INT_SETMODEATTRIBUTION]
	@v_mode bit
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

-- Déclaration des variables
DECLARE
	@v_local bit,
	@v_transaction varchar(32),
	@v_error int,
	@v_status int,
	@v_retour int,
	@v_par_valeur varchar(128)

-- Déclaration des constantes de retour
DECLARE
	@CODE_OK tinyint,
	@CODE_KO tinyint,
	@CODE_KO_SQL tinyint

-- Définition des constantes
	SELECT @CODE_OK = 0
	SELECT @CODE_KO = 1
	SELECT @CODE_KO_SQL = 13

-- Initialisation des variables
	SELECT @v_transaction = 'SETMODEATTRIBUTION'
	SELECT @v_error = 0
	SELECT @v_status = @CODE_KO
	SELECT @v_retour = @CODE_KO

	IF @@TRANCOUNT > 0
		SELECT @v_local = 0
	ELSE
	BEGIN
		SELECT @v_local = 1
		BEGIN TRAN @v_transaction
	END
	SELECT @v_par_valeur = CASE @v_mode WHEN 0 THEN 'TRUE' ELSE 'FALSE' END
	EXEC @v_status = INT_SETPARAMETRE 'STOP_ATTRIB', @v_par_valeur
	SELECT @v_error = @@ERROR
	IF @v_status = @CODE_OK AND @v_error = 0
		SELECT @v_retour = @CODE_OK
	ELSE
		SELECT @v_retour = CASE @v_status WHEN @CODE_OK THEN @v_error ELSE @v_status END
	IF @v_local = 1
	BEGIN
		IF @v_retour <> @CODE_OK
			ROLLBACK TRAN @v_transaction
		ELSE
			COMMIT TRAN @v_transaction
	END
	RETURN @v_retour



