SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF

-----------------------------------------------------------------------------------------
-- Procédure		: SPV_SETMARQUEMISSION
-- Paramètre d'entrée	: @v_mis_idmission : Identifiant mission
-- Paramètre de sortie	: 
-- Descriptif		: Marque une mission
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[SPV_SETMARQUEMISSION]
	@v_mis_idmission int
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

-- Déclaration des variables
DECLARE
	@v_error int,
	@v_retour int

-- Déclaration des constantes de retour
DECLARE
	@CODE_OK tinyint,
	@CODE_KO tinyint,
	@CODE_KO_SQL tinyint

-- Déclaration des constantes d'états et descriptions
DECLARE
	@ETAT_ENATTENTE tinyint

-- Définition des constantes
	SET @CODE_OK = 0
	SET @CODE_KO = 1
	SET @CODE_KO_SQL = 13
	SET @ETAT_ENATTENTE = 1

-- Initialisation des variables
	SET @v_error = 0
	SET @v_retour = @CODE_KO

	UPDATE MISSION SET MIS_MARQUE = 1 WHERE MIS_IDMISSION = @v_mis_idmission
	SET @v_error = @@ERROR
	IF @v_error = 0
		SET @v_retour = @CODE_OK
	ELSE
		SET @v_retour = @CODE_KO_SQL
	RETURN @v_retour

