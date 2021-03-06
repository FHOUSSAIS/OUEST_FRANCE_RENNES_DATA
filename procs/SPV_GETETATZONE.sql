SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF


-----------------------------------------------------------------------------------------
-- Procédure		: SPV_GETETATZONE
-- Paramètre d'entrée	: @v_type :
--			    0 : Courant
--			    1 : Futur
--			  @v_iag_id : Identifiant de l'AGV
-- Paramètre de sortie	: @v_zon_etat : Etat de la zone
-- Descriptif 		: Calcul de l'état courant ou futur d'une zone
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[SPV_GETETATZONE]
	@v_type bit,
	@v_zon_idzone int,
	@v_zon_etat tinyint out
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

-- Déclaration des variables
DECLARE
	@v_zne_capaciteminimale tinyint,
	@v_zne_capacitemaximale tinyint,
	@v_zne_surreservation bit

-- Déclaration des constantes d'états et descriptions
DECLARE
	@ETAT_ENATTENTE tinyint,
	@DESC_ENVOYE tinyint,
	@ETAT_SOUS_CAPACITE tinyint,
	@ETAT_NORMAL tinyint,
	@ETAT_PLEIN tinyint,
	@ETAT_SUR_CAPACITE tinyint

-- Définition des constantes
	SET @ETAT_ENATTENTE = 1
	SET @DESC_ENVOYE = 13
	SET @ETAT_SOUS_CAPACITE = 0
	SET @ETAT_NORMAL = 1
	SET @ETAT_PLEIN = 2
	SET @ETAT_SUR_CAPACITE = 3

	SELECT @v_zon_etat = ISNULL(ZNE_OCCCRT, 0), @v_zne_capaciteminimale = ZNE_CAP_MIN, @v_zne_capacitemaximale = ZNE_CAP_MAX,
		@v_zne_surreservation = ZNE_BOOKING FROM ZONE WHERE ZNE_ID = @v_zon_idzone
	IF @v_type = 1
		SELECT @v_zon_etat = COUNT(*) FROM INFO_AGV WHERE IAG_OPERATIONNEL = 'O' AND ((IAG_BASE_DEST IN (SELECT CZO_ADR_KEY_BASE FROM ZONE_CONTENU WHERE CZO_ZONE = @v_zon_idzone)
			AND NOT EXISTS (SELECT 1 FROM ORDRE_AGV WHERE ORD_IDAGV = IAG_ID AND ORD_IDETAT = @ETAT_ENATTENTE AND ORD_DSCETAT = @DESC_ENVOYE))
			OR EXISTS (SELECT 1 FROM ORDRE_AGV, TACHE, (SELECT CZO_ADR_KEY_SYS, CZO_ADR_KEY_BASE FROM ZONE_CONTENU WHERE CZO_ZONE = @v_zon_idzone) ZONE_CONTENU
			WHERE ORD_IDAGV = IAG_ID AND TAC_IDORDRE = ORD_IDORDRE AND ORD_IDETAT = @ETAT_ENATTENTE AND ORD_DSCETAT = @DESC_ENVOYE
			AND TAC_IDADRSYS = CZO_ADR_KEY_SYS AND TAC_IDADRBASE = CZO_ADR_KEY_BASE))
	SET @v_zon_etat = CASE WHEN @v_zon_etat < @v_zne_capaciteminimale THEN @ETAT_SOUS_CAPACITE
		WHEN @v_zon_etat >= @v_zne_capaciteminimale AND @v_zon_etat < @v_zne_capacitemaximale THEN @ETAT_NORMAL
		WHEN @v_zon_etat = @v_zne_capacitemaximale THEN @ETAT_PLEIN
		WHEN @v_zon_etat > @v_zne_capacitemaximale THEN CASE @v_zne_surreservation WHEN 1 THEN @ETAT_PLEIN ELSE @ETAT_SUR_CAPACITE END END

