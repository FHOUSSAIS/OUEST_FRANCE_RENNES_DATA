SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF

CREATE PROCEDURE [dbo].[INT_REPORTEVENEMENTENERGIE]
	@v_iag_idagv tinyint
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
	@v_mis_idmission int,
	@v_dsp_iddefaut int,
	@v_dsp_information varchar(8000)

-- Déclaration des constantes de retour
DECLARE
	@CODE_OK tinyint,
	@CODE_KO tinyint,
	@CODE_KO_SQL tinyint

-- Déclaration des constantes d'état d'événement d'énergie
DECLARE
	@ETAT_ENATTENTE tinyint,
	@ETAT_SUSPENDU tinyint,
	@ETAT_TERMINE tinyint

-- Déclaration des constantes de types de missions
DECLARE
	@TYPE_BATTERIE tinyint

-- Définition des constantes
	SET @CODE_OK = 0
	SET @CODE_KO = 1
	SET @CODE_KO_SQL = 13
	SET @ETAT_ENATTENTE = 1
	SET @ETAT_SUSPENDU = 4
	SET @ETAT_TERMINE = 3
	SET @TYPE_BATTERIE = 2

-- Initialisation des variables
	SET @v_transaction = 'REPORTEVENEMENTENERGIE'
	SET @v_error = 0
	SET @v_status = @CODE_OK
	SET @v_retour = @CODE_KO
	
	IF @@TRANCOUNT > 0
		SET @v_local = 0
	ELSE
	BEGIN
		SET @v_local = 1
		BEGIN TRAN @v_transaction
	END
	EXEC @v_status = SPV_EVENEMENTENERGIE 0, @v_iag_idagv, NULL, NULL, NULL, @v_dsp_iddefaut out, @v_dsp_information out
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
		BEGIN
			IF @v_dsp_iddefaut <> 0
				SELECT @v_retour = DSP_IDTRADUCTIONINFORMATION FROM DEFAUT_SPV WHERE DSP_ID = @v_dsp_iddefaut
			COMMIT TRAN @v_transaction
		END
	END
	RETURN @v_retour

