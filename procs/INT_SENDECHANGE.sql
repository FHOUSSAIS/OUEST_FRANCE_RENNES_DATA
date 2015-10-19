SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF

CREATE PROCEDURE [dbo].[INT_SENDECHANGE]
	@v_ech_table varchar(256)
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
	@v_ech_interface int

-- Déclaration des constantes de retour
DECLARE
	@CODE_OK tinyint,
	@CODE_KO tinyint

-- Définition des constantes
	SET @CODE_OK = 0
	SET @CODE_KO = 1

-- Initialisation des variables
	SET @v_transaction = 'SENDECHANGE'
	SET @v_error = 0
	SET @v_status = @CODE_KO
	SET @v_retour = @CODE_KO
	
	IF @@TRANCOUNT > 0
		SET @v_local = 0
	ELSE
	BEGIN
		SET @v_local = 1
		BEGIN TRAN @v_transaction
	END
	SELECT @v_ech_interface = ECH_INTERFACE FROM ECHANGE WHERE ECH_TABLE = @v_ech_table
	EXEC @v_status = SPV_WRITEECHANGE 1, @v_ech_interface, @v_ech_table
	SET @v_error = @@ERROR
	IF @v_status = @CODE_OK AND @v_error = 0
		SET @v_retour = @CODE_OK
	ELSE
		SET @v_retour = CASE @v_status WHEN @CODE_OK THEN @v_error ELSE @v_status END
	IF @v_local = 1
	BEGIN
		IF @v_retour <> @CODE_OK
			ROLLBACK TRAN @v_transaction
		ELSE
			COMMIT TRAN @v_transaction
	END
	RETURN @v_retour



