SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER ON

CREATE PROCEDURE [dbo].[INT_SETLIMITATIONVITESSE]
	@v_agv varchar(8000) = NULL,
	@v_iag_limitationvitesse bit,
	@v_iag_vitessemaximale smallint
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
	@v_sql varchar(8000)	

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
	SET @v_transaction = 'SETLIMITATIONVITESSE'
	SET @v_error = 0
	SET @v_retour = @CODE_KO

	IF @@TRANCOUNT > 0
		SELECT @v_local = 0
	ELSE
	BEGIN
		SELECT @v_local = 1
		BEGIN TRAN @v_transaction
	END
	SET CONCAT_NULL_YIELDS_NULL OFF
	IF @v_agv = ''
		SET @v_agv = NULL
	IF @v_agv IS NULL
		UPDATE INFO_AGV SET IAG_LIMITATIONVITESSE = @v_iag_limitationvitesse, IAG_VITESSEMAXIMALE = @v_iag_vitessemaximale
	ELSE
	BEGIN
		SET @v_sql = ('UPDATE INFO_AGV SET IAG_LIMITATIONVITESSE = ' + ISNULL(CONVERT(varchar, @v_iag_limitationvitesse), '1') + ' , IAG_VITESSEMAXIMALE = ' + ISNULL(CONVERT(varchar, @v_iag_vitessemaximale), '0') + ' WHERE IAG_ID IN (' + @v_agv + ')')
		EXEC (@v_sql)
	END
	SET @v_error = @@ERROR
	IF @v_error = 0
		SET @v_retour = @CODE_OK
	ELSE
		SELECT @v_retour = @CODE_KO_SQL
	SET CONCAT_NULL_YIELDS_NULL ON
	IF @v_local = 1
	BEGIN
		IF @v_retour <> @CODE_OK
			ROLLBACK TRAN @v_transaction
		ELSE
			COMMIT TRAN @v_transaction
	END
	RETURN @v_retour

