SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER ON

CREATE  PROCEDURE [dbo].[INT_SETCRITEREMISSION]
	@v_cri_idcritere int,
	@v_mis_idmission int,
	@v_crm_valeur varchar(8000)
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
	@CODE_KO_INCONNU tinyint,
	@CODE_KO_SQL tinyint

-- Déclaration des constantes de familles
DECLARE
	@FAMI_MISSION tinyint

-- Définition des constantes
	SET @CODE_OK = 0
	SET @CODE_KO = 1
	SET @CODE_KO_INCONNU = 7
	SET @CODE_KO_SQL = 13
	SET @FAMI_MISSION = 0

-- Initialisation des variables
	SET @v_transaction = 'SETCRITEREMISSION'
	SET @v_error = 0
	SET @v_retour = @CODE_KO

	IF @@TRANCOUNT > 0
		SET @v_local = 0
	ELSE
	BEGIN
		SET @v_local = 1
		BEGIN TRAN @v_transaction
	END
	-- Contrôle de l'existence du critère de mission
	IF EXISTS (SELECT 1 FROM CRITERE WHERE CRI_IDCRITERE = @v_cri_idcritere AND CRI_FAMILLE = @FAMI_MISSION)
	BEGIN
		UPDATE CRITERE_MISSION SET CRM_VALUE = @v_crm_valeur WHERE CRM_IDCRITERE = @v_cri_idcritere
			AND CRM_IDMISSION = @v_mis_idmission
		SET @v_error = @@ERROR
		IF @v_error = 0
			SET @v_retour = @CODE_OK
		ELSE
			SET @v_retour = @CODE_KO_SQL
	END
	ELSE
		SET @v_retour = @CODE_KO_INCONNU
	IF @v_local = 1
	BEGIN
		IF @v_retour <> @CODE_OK
			ROLLBACK TRAN @v_transaction
		ELSE
			COMMIT TRAN @v_transaction
	END
	RETURN @v_retour


