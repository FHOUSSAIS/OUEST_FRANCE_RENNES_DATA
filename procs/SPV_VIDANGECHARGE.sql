SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF


-----------------------------------------------------------------------------------------
-- Procédure		: SPV_VIDANGECHARGE
-- Paramètre d'entrée	: @v_chg_id : Identifiant de la charge
-- Paramètre de sortie	: Code de retour par défaut
--			    - @CODE_OK : La vidange a eu lieu
--			    - @CODE_KO : La vidange n'a pas eu lieu
--			    - @CODE_KO_INEXISTANT : La charge n'existe pas
--			    - @CODE_KO_SQL : Une erreur SQL a eu lieu
-- Descriptif		: Cette procédure vidange une charge
-----------------------------------------------------------------------------------------
-- Révisions											
-----------------------------------------------------------------------------------------
-- Date			: 04/12/2006
-- Auteur		: Cédric LE FRINGERE
-- Libellé			: Création de la procédure
-----------------------------------------------------------------------------------------
-- Date			: 18/06/2007
-- Auteur		: Cédric LE FRINGERE
-- Libellé			: Standardisation Logistic Core
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[SPV_VIDANGECHARGE]
	@v_chg_id int
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

--Déclaration des variables
DECLARE
	@v_retour integer

-- Déclaration des constantes de retour
DECLARE
	@CODE_OK tinyint,
	@CODE_KO tinyint,
	@CODE_KO_INEXISTANT tinyint,
	@CODE_KO_SQL tinyint

-- Définition des constantes
	SELECT @CODE_OK = 0
	SELECT @CODE_KO = 1
	SELECT @CODE_KO_INEXISTANT = 4
	SELECT @CODE_KO_SQL = 13

-- Initialisation de la variable de retour
	SELECT @v_retour = @CODE_KO

	IF EXISTS (SELECT 1 FROM CHARGE WHERE CHG_ID = @v_chg_id AND CHG_TODESTROY = 0)
	BEGIN
		UPDATE CHARGE SET CHG_PRODUIT = NULL WHERE CHG_ID = @v_chg_id
		IF @@ERROR <> 0
			SELECT @v_retour = @CODE_KO_SQL
		ELSE
			SELECT @v_retour = @CODE_OK
	END
	ELSE
		SELECT @v_retour = @CODE_KO_INEXISTANT

	RETURN @v_retour



