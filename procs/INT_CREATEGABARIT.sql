SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER ON

CREATE PROCEDURE [dbo].[INT_CREATEGABARIT]
	@v_gbr_idgabarit tinyint out,
	@v_gbr_hauteur smallint,
	@v_gbr_largeur smallint,
	@v_gbr_longueur smallint,
	@v_gbr_gabarit varchar(8000)
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
	@v_tra_idtraduction int,
	@v_par_valeur varchar(128)

-- Déclaration des constantes de retour
DECLARE
	@CODE_OK tinyint,
	@CODE_KO tinyint,
	@CODE_KO_SQL tinyint

-- Définition des constantes
	SET @CODE_OK = 0
	SET @CODE_KO = 1
	SET @CODE_KO_SQL = 13

-- Initialisation des variables
	SET @v_transaction = 'CREATEGABARIT'
	SET @v_error = 0
	SET @v_retour = @CODE_KO

	IF @@TRANCOUNT > 0
		SET @v_local = 0
	ELSE
	BEGIN
		SET @v_local = 1
		BEGIN TRAN @v_transaction
	END
	SELECT @v_par_valeur = PAR_VALEUR FROM INT_PARAMETRE WHERE PAR_IDPARAMETRE = 'LANGUE'
	EXEC @v_status = LIB_TRADUCTION 0, @v_par_valeur, @v_gbr_gabarit, @v_tra_idtraduction out
	SET @v_error = @@ERROR
	IF @v_status = @CODE_OK AND @v_error = 0
	BEGIN
		SELECT @v_gbr_idgabarit = ISNULL(MAX(GBR_IDGABARIT), 0) + 1 FROM INT_GABARIT
		INSERT INTO GABARIT (GBR_ID, GBR_TRADUCTION, GBR_HAUTEUR, GBR_LARGEUR, GBR_LONGUEUR)
			VALUES (@v_gbr_idgabarit, @v_tra_idtraduction, @v_gbr_hauteur, @v_gbr_largeur, @v_gbr_longueur)
		SET @v_error = @@ERROR
		IF @v_error = 0
			SET @v_retour = @CODE_OK
		ELSE
			SET @v_retour = @CODE_KO_SQL
	END
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

