SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER OFF

-----------------------------------------------------------------------------------------
-- Procédure		: SPV_GETETATAGV
-- Paramètre d'entrée	: @v_iag_id : Identifiant de l'AGV
-- Paramètre de sortie	: @v_iag_etat : Etat de l'AGV
-- Descriptif 		: Récupération de l'état de l'AGV
-----------------------------------------------------------------------------------------
-- Révision
-----------------------------------------------------------------------------------------
-- Date			: 19/01/2009
-- Auteur		: Cédric LE FRINGERE
-- Libellé			: Création de la procédure
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[SPV_GETETATAGV] @v_iag_id tinyint, @v_iag_etat bit out
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

--Déclaration des variables
DECLARE
	@v_nbChargeSurAgv tinyint,
	@v_nbChargeAOccuper tinyint,
	@v_nbChargeALiberer tinyint

-- Déclaration des constantes d'états
DECLARE
	@ETAT_ENCOURS tinyint,
	@ETAT_ANNULE tinyint,
	@ETAT_TERMINE tinyint

-- Déclaration des constantes de type d'adresse
DECLARe
	@TYPE_AGV tinyint

-- Déclaration des constantes d'actions et de types actions
DECLARE
	@ACTION_PRIMAIRE bit,
	@ACTION_AVANCE_AUTO_ZONE tinyint

-- Définition des constantes
	SET @ETAT_ENCOURS = 2
	SET @ETAT_TERMINE = 5
	SET @ETAT_ANNULE = 6
	SET @TYPE_AGV = 1
	SET @ACTION_PRIMAIRE = 0

	-- Calcul de l'état de l'AGV (chargé ou vide)
	-- On tient compte de l'état physique de l'AGV mais aussi de tous les ordres (calculés et à venir) susceptibles d'occuper des places
	-- supplémentaires sur l'AGV et des ordres (en cours uniquement) susceptibles de libérer des places sur l'AGV
	-- Nombre de charges sur l'AGV
	SELECT @v_nbChargeSurAgv = COUNT(*) from CHARGE, ADRESSE, BASE
		WHERE CHG_TODESTROY = 0 AND CHG_ADR_KEYSYS = ADR_SYSTEME AND CHG_ADR_KEYBASE = ADR_BASE AND CHG_ADR_KEYSSBASE = ADR_SOUSBASE
		AND BAS_SYSTEME = ADR_SYSTEME AND BAS_BASE = ADR_BASE
		AND BAS_TYPE_MAGASIN = @TYPE_AGV AND BAS_MAGASIN = @v_iag_id AND BAS_SYSTEME = (SELECT TOP 1 SYS_SYSTEME FROM SYSTEME)
	-- Nombre de charges supplémentaires qui vont être transférées sur l'AGV
	SELECT @v_nbChargeAOccuper = COUNT(*) FROM ORDRE_AGV, TACHE WHERE ORD_IDAGV = @v_iag_id
		AND ORD_IDETAT NOT IN (@ETAT_TERMINE, @ETAT_ANNULE)
		AND TAC_IDORDRE = ORD_IDORDRE AND EXISTS (SELECT 1 FROM ASSOCIATION_TACHE_ACTION_TACHE, ACTION WHERE ATA_IDTACHE = TAC_IDTACHE
		AND ATA_IDTYPEACTION = @ACTION_PRIMAIRE AND ACT_IDACTION = ATA_IDACTION AND ACT_OCCUPATION = 1)
	-- Nombre de charges qui vont être transférées de l'AGV
	SELECT @v_nbChargeALiberer = COUNT(*) FROM ORDRE_AGV, TACHE WHERE ORD_IDAGV = @v_iag_id
		AND TAC_IDORDRE = ORD_IDORDRE AND EXISTS (SELECT 1 FROM ASSOCIATION_TACHE_ACTION_TACHE, ACTION WHERE ATA_IDTACHE = TAC_IDTACHE
		AND ATA_IDTYPEACTION = @ACTION_PRIMAIRE AND ACT_IDACTION = ATA_IDACTION AND ACT_OCCUPATION = -1)
		AND ORD_IDETAT = @ETAT_ENCOURS
	IF (@v_nbChargeSurAgv + @v_nbChargeAOccuper) > @v_nbChargeALiberer
		SET @v_iag_etat = 1
	ELSE
		SET @v_iag_etat = 0


