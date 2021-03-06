SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER OFF

CREATE PROCEDURE [dbo].[INT_REPORTSERVICEADRESSEENERGIE]
	@v_adr_idsysteme bigint,
	@v_adr_idbase bigint,
	@v_adr_idsousbase bigint,
	@v_service bit
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
	@v_coe_id smallint,
	@v_coe_type tinyint,
	@v_coe_rack tinyint

-- Déclaration des constantes de retour
DECLARE
	@CODE_OK tinyint,
	@CODE_KO tinyint,
	@CODE_KO_SQL tinyint,
	@CODE_KO_ADR_INCONNUE tinyint

-- Déclaration des constantes de type d'objet énergie
DECLARE
	@TYPE_CHANGEMENT_BATTERIE_AUTOMATIQUE_AUTONOME int

-- Définition des constantes
	SET @CODE_OK = 0
	SET @CODE_KO = 1
	SET @CODE_KO_SQL = 13
	SET @CODE_KO_ADR_INCONNUE = 28
	SET @TYPE_CHANGEMENT_BATTERIE_AUTOMATIQUE_AUTONOME = 3

-- Initialisation des variables
	SET @v_transaction = 'REPORTSERVICEADRESSEENERGIE'
	SET @v_error = 0
	SET @v_retour = @CODE_KO

	IF @@TRANCOUNT > 0
		SELECT @v_local = 0
	ELSE
	BEGIN
		SELECT @v_local = 1
		BEGIN TRAN @v_transaction
	END
	SELECT @v_coe_id = COE_ID, @v_coe_type = COE_TYPE, @v_coe_rack = COE_RACK FROM INT_ADRESSE INNER JOIN CONFIG_OBJ_ENERGIE ON COE_ADRSYS = ADR_IDSYSTEME AND COE_ADRBASE = ADR_IDBASE AND COE_ADRSSBASE = ADR_IDSOUSBASE WHERE ADR_IDSYSTEME = @v_adr_idsysteme AND ADR_IDBASE = @v_adr_idbase AND ADR_IDSOUSBASE = @v_adr_idsousbase
	IF (@v_coe_id IS NOT NULL)
	BEGIN
		IF @v_coe_type = @TYPE_CHANGEMENT_BATTERIE_AUTOMATIQUE_AUTONOME
			UPDATE CONFIG_OBJ_ENERGIE SET COE_ENSERVICE = @v_service WHERE COE_RACK = @v_coe_rack
		ELSE
			UPDATE CONFIG_OBJ_ENERGIE SET COE_ENSERVICE = @v_service WHERE COE_ID = @v_coe_id
		SET @v_error = @@ERROR
		IF @v_error = 0
			SET @v_retour = @CODE_OK
		ELSE
			SET @v_retour = @CODE_KO_SQL
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

