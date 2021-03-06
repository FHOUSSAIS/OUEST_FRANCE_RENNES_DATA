SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF



-----------------------------------------------------------------------------------------
-- Procédure		: SPV_MODEARRET
-- Paramétre d'entrée	: 
-- Paramétre de sortie	: 
-- Descriptif		: Gestion du changement de mode d'exploitation
--			  vers le mode d'exploitation d'arrêt
-----------------------------------------------------------------------------------------
-- Révision
-----------------------------------------------------------------------------------------
-- Date			: 07/09/2006
-- Auteur		: Cédric LE FRINGERE
-- Libellé			: Création de la procÚdure
-----------------------------------------------------------------------------------------
-- Date			: 18/06/2007
-- Auteur		: Cédric LE FRINGERE
-- Libellé			: Standardisation Logistic Core
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[SPV_MODEARRET]
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

DECLARE
	@CODE_KO tinyint,
	@v_retour smallint,
	@v_mode tinyint

	SELECT @CODE_KO = 1
	SELECT @v_retour = @CODE_KO
	IF EXISTS (SELECT COUNT(*) FROM MODE_EXPLOITATION WHERE MOD_ARRET = 1
		HAVING COUNT(*) = 1)
	BEGIN
		SELECT @v_mode = MOD_IDMODE FROM MODE_EXPLOITATION WHERE MOD_ARRET = 1
		EXEC @v_retour = INT_SETMODEEXPLOITATION @v_mode, ''
	END
	RETURN @v_retour


