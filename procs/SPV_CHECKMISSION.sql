SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF


-----------------------------------------------------------------------------------------
-- Procédure		: SPV_CHECKMISSION
-- Paramétre d'entrée	: 
-- Paramétre de sortie	: 
-- Descriptif		: Gestion de l'état du portefeuille de missions en fonction
--			  de l'arrêt à distance demandé
-----------------------------------------------------------------------------------------
-- Révision
-----------------------------------------------------------------------------------------
-- Date			: 01/09/2006
-- Auteur		: Cédric LE FRINGERE
-- Libellé			: Création de la procédure
-----------------------------------------------------------------------------------------
-- Date			: 18/06/2007
-- Auteur		: Cédric LE FRINGERE
-- Libellé			: Standardisation Logistic Core
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[SPV_CHECKMISSION]
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

DECLARE
	@CODE_OK tinyint,
	@CODE_KO tinyint,
	@CODE_OUI tinyint,
	@CODE_NON tinyint,
	@v_retour smallint,
	@v_remotestop varchar(128),
	@ARRET_SANS_ENCOURS tinyint,
	@ARRET_PORTEFEUILLE_VIDE tinyint,
	@TRANSFERT_CHARGE tinyint

-- Déclaration des constantes d'états et descriptions
DECLARE
	@ETAT_ENATTENTE tinyint,
	@ETAT_TERMINE tinyint,
	@ETAT_ANNULE tinyint

-- Définition des constantes
	SELECT @CODE_OK = 0
	SELECT @CODE_KO = 1
	SELECT @CODE_OUI = 5
	SELECT @CODE_NON = 6
	SELECT @ARRET_SANS_ENCOURS = 2
	SELECT @ARRET_PORTEFEUILLE_VIDE = 3
	SELECT @ETAT_ENATTENTE = 1
	SELECT @ETAT_TERMINE = 5
	SELECT @ETAT_ANNULE = 6
	SELECT @TRANSFERT_CHARGE = 1
	SELECT @v_retour = @CODE_KO
	SELECT @v_remotestop = PAR_VAL FROM PARAMETRE WHERE PAR_NOM = 'REMOTE_STOP'
	IF @v_remotestop IN (@ARRET_SANS_ENCOURS, @ARRET_PORTEFEUILLE_VIDE)
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM INFO_AGV, MODE_EXPLOITATION WHERE MOD_IDMODE = IAG_MODE_EXPLOIT
			AND MOD_ARRET = 0)
		BEGIN
			IF NOT EXISTS (SELECT 1 FROM MISSION WHERE MIS_IDETAT NOT IN (@ETAT_ENATTENTE,
				@ETAT_TERMINE, @ETAT_ANNULE))
				SELECT @v_retour = @CODE_OK
		END
		ELSE IF (@v_remotestop = @ARRET_PORTEFEUILLE_VIDE)
		BEGIN
			SELECT @v_retour = @CODE_NON
			IF NOT EXISTS (SELECT 1 FROM MISSION WHERE MIS_IDETAT NOT IN (@ETAT_TERMINE, @ETAT_ANNULE)
					AND MIS_TYPEMISSION = @TRANSFERT_CHARGE)
					SELECT @v_retour = @CODE_OUI
		END
	END 
	RETURN @v_retour


