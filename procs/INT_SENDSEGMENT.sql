SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF

CREATE PROCEDURE [dbo].[INT_SENDSEGMENT]
	@v_cnx_idconnexion int,
	@v_seg_data varbinary(max)
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
	@CODE_KO_INCONNU tinyint
	
-- Définition des constantes
	SET @CODE_OK = 0
	SET @CODE_KO = 1
	SET @CODE_KO_SQL = 13
	SET @CODE_KO_INCONNU = 7

-- Initialisation des variables
	SET @v_transaction = 'SENDSEGMENT'
	SET @v_error = 0
	SET @v_retour = @CODE_KO
	
	IF @@TRANCOUNT > 0
		SET @v_local = 0
	ELSE
	BEGIN
		SET @v_local = 1
		BEGIN TRAN @v_transaction
	END
	IF EXISTS (SELECT 1 FROM CONNEXION WHERE CNX_ID = @v_cnx_idconnexion)
	BEGIN
		INSERT INTO SEGMENT (SEG_CONNEXION, SEG_DATA) VALUES (@v_cnx_idconnexion, @v_seg_data)
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



