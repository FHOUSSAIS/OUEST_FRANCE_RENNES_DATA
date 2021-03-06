SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF

CREATE PROCEDURE [dbo].[INT_SETEVENEMENTENERGIE]
	@v_iag_idagv tinyint,
	@v_evc_actif bit
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
	@CODE_KO_SQL tinyint

-- Déclaration des constantes d'état d'événement d'énergie
DECLARE
	@ETAT_TERMINE tinyint

-- Déclaration des constantes de type d'événement d'énergie
DECLARE
	@TYPE_CHANGEMENT_BATTERIE int

-- Définition des constantes
	SET @CODE_OK = 0
	SET @CODE_KO = 1
	SET @CODE_KO_SQL = 13
	SET @ETAT_TERMINE = 3
	SET @TYPE_CHANGEMENT_BATTERIE = 1

-- Initialisation des variables
	SET @v_transaction = 'SETEVENEMENTENERGIE'
	SET @v_error = 0
	SET @v_retour = @CODE_KO
	
	IF @@TRANCOUNT > 0
		SET @v_local = 0
	ELSE
	BEGIN
		SET @v_local = 1
		BEGIN TRAN @v_transaction
	END
	UPDATE CONFIG_EVT_ENERGIE SET EVC_ACTIF = @v_evc_actif WHERE EVC_AGV = @v_iag_idagv
	SET @v_error = @@ERROR
	IF @v_error = 0
		SET @v_retour = @CODE_OK
	ELSE
		SET @v_retour = @CODE_KO_SQL
	IF @v_local = 1
	BEGIN
		IF @v_retour <> @CODE_OK
			ROLLBACK TRAN @v_transaction
		ELSE
			COMMIT TRAN @v_transaction
	END
	RETURN @v_retour

