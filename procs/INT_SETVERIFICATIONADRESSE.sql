SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF

CREATE PROCEDURE [dbo].[INT_SETVERIFICATIONADRESSE]
	@v_adr_idsysteme bigint,
	@v_adr_idbase bigint,
	@v_adr_idsousbase bigint,
	@v_adr_verification bit
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
	@v_retour int

-- Déclaration des constantes de retour
DECLARE
	@CODE_OK tinyint,
	@CODE_KO tinyint,
	@CODE_KO_SQL tinyint,
	@CODE_KO_ADR_INCONNUE tinyint

-- Définition des constantes
	SELECT @CODE_OK = 0
	SELECT @CODE_KO = 1
	SELECT @CODE_KO_SQL = 13
	SELECT @CODE_KO_ADR_INCONNUE = 28

-- Initialisation des variables
	SELECT @v_transaction = 'SETVERIFICATIONADRESSE'
	SELECT @v_error = 0
	SELECT @v_retour = @CODE_KO

	IF @@TRANCOUNT > 0
		SELECT @v_local = 0
	ELSE
	BEGIN
		SELECT @v_local = 1
		BEGIN TRAN @v_transaction
	END
	-- Contrôle de l'existence de l'adresse
	IF EXISTS (SELECT 1 FROM INT_ADRESSE WHERE ADR_IDSYSTEME = @v_adr_idsysteme AND ADR_IDBASE = @v_adr_idbase AND ADR_IDSOUSBASE = @v_adr_idsousbase)
	BEGIN
		UPDATE ADRESSE SET ADR_AVERIFIER = @v_adr_verification WHERE ADR_SYSTEME = @v_adr_idsysteme AND ADR_BASE = @v_adr_idbase AND ADR_SOUSBASE = @v_adr_idsousbase
		SELECT @v_error = @@ERROR
		IF @v_error = 0
			SELECT @v_retour = @CODE_OK
		ELSE
			SELECT @v_retour = @CODE_KO_SQL
	END
	ELSE
		SELECT @v_retour = @CODE_KO_ADR_INCONNUE
	IF @v_local = 1
	BEGIN
		IF @v_retour <> @CODE_OK
			ROLLBACK TRAN @v_transaction
		ELSE
			COMMIT TRAN @v_transaction
	END
	RETURN @v_retour




