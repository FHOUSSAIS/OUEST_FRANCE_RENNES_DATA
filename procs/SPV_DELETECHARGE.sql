SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF


-----------------------------------------------------------------------------------------
-- Procedure		: SPV_DELETECHARGE
-- Paramètre d'entrée	: @v_chg_idcharge : Identifiant charge
-- Paramètres de sortie	: Valeur de retour :
--			    @CODE_OK : Réussite
--			    @CODE_KO : Echec
--			    @CODE_KO_SQL : Erreur SQL
-- Descriptif		: Suppression d'une charge
-----------------------------------------------------------------------------------------
-- Révision									
-----------------------------------------------------------------------------------------
-- Date			: 18/06/2007
-- Auteur		: Cédric LE FRINGERE
-- Libellé			: Création de la procédure
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[SPV_DELETECHARGE]
	@v_chg_idcharge int
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

-- Définition des constantes
	SELECT @CODE_OK = 0
	SELECT @CODE_KO = 1
	SELECT @CODE_KO_SQL = 13

-- Initialisation des variables
	SELECT @v_error = 0
	SELECT @v_retour = @CODE_KO

	DELETE CHARGE WHERE CHG_ID = @v_chg_idcharge
	SELECT @v_error = @@ERROR
	IF @v_error = 0
		SELECT @v_retour = @CODE_OK
	ELSE
		SELECT @v_retour = @CODE_KO_SQL
	RETURN @v_retour

