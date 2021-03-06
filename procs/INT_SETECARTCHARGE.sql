SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF

CREATE PROCEDURE [dbo].[INT_SETECARTCHARGE]
	@v_adr_idsysteme bigint,
	@v_adr_idbase bigint,
	@v_adr_idsousbase bigint,
	@v_adr_niveau tinyint = NULL,
	@v_str_ecart_exploitation smallint
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
	@v_retour int,
	@v_mis_idetatmission tinyint

-- Déclaration des constantes de retour
DECLARE
	@CODE_OK tinyint,
	@CODE_KO tinyint,
	@CODE_KO_INCORRECT tinyint,
	@CODE_KO_SQL tinyint,
	@CODE_KO_ADR_INCONNUE tinyint

-- Définition des constantes
	SET @CODE_OK = 0
	SET @CODE_KO = 1
	SET @CODE_KO_INCORRECT = 11
	SET @CODE_KO_SQL = 13 
	SET @CODE_KO_ADR_INCONNUE = 28

-- Initialisation des variables
	SET @v_transaction = 'SETECARTCHARGE'
	SET @v_error = 0
	SET @v_retour = @CODE_KO
	
	IF @@TRANCOUNT > 0
		SET @v_local = 0
	ELSE
	BEGIN
		SET @v_local = 1
		BEGIN TRAN @v_transaction
	END
	-- Contrôle de l'existence de l'adresse et de la structure
	IF EXISTS (SELECT 1 FROM INT_ADRESSE WHERE ADR_IDSYSTEME = @v_adr_idsysteme AND ADR_IDBASE = @v_adr_idbase AND ADR_IDSOUSBASE = @v_adr_idsousbase)
		AND EXISTS (SELECT 1 FROM STRUCTURE WHERE STR_SYSTEME = @v_adr_idsysteme AND STR_BASE = @v_adr_idbase AND STR_SOUSBASE = @v_adr_idsousbase
		AND ((STR_COUCHE = @v_adr_niveau AND @v_adr_niveau IS NOT NULL) OR (@v_adr_niveau IS NULL)))
	BEGIN
		IF EXISTS (SELECT 1 FROM STRUCTURE WHERE STR_SYSTEME = @v_adr_idsysteme AND STR_BASE = @v_adr_idbase AND STR_SOUSBASE = @v_adr_idsousbase
			AND ((STR_COUCHE = @v_adr_niveau AND @v_adr_niveau IS NOT NULL) OR (@v_adr_niveau IS NULL))
			AND STR_ECART_INDUSTRIEL < @v_str_ecart_exploitation)
		BEGIN
			UPDATE STRUCTURE SET STR_ECART_EXPLOITATION = @v_str_ecart_exploitation
				WHERE STR_SYSTEME = @v_adr_idsysteme AND STR_BASE = @v_adr_idbase AND STR_SOUSBASE = @v_adr_idsousbase
				AND ((STR_COUCHE = @v_adr_niveau AND @v_adr_niveau IS NOT NULL) OR (@v_adr_niveau IS NULL))
			SET @v_error = @@ERROR
			IF @v_error = 0
				SET @v_retour = @CODE_OK
			ELSE
				SET @v_retour = @CODE_KO_SQL
		END
		ELSE
			SET @v_retour = @CODE_KO_INCORRECT		
	END
	ELSE
		SET @v_retour = @CODE_KO_ADR_INCONNUE
	IF @v_local = 1
	BEGIN
		IF @v_retour <> @CODE_OK
			ROLLBACK TRAN @v_transaction
		ELSE
			COMMIT TRAN @v_transaction
	END
	RETURN @v_retour

