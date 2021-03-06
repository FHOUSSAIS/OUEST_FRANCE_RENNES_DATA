SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF

-----------------------------------------------------------------------------------------
-- Procédure		: SPV_SETOCCUPATIONZONE
-- Paramètre d'entrée	: @v_iag_idagv : Identifiant de l'AGV
--						  @v_sens : Sens
--						  @v_zne_idzone : Identifiant de la zone
-- Paramètre de sortie	:
-- Descriptif		: Gestion de l'occupation des zones
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[SPV_SETOCCUPATIONZONE]
	@v_iag_idagv tinyint,
	@v_sens bit,
	@v_zne_idzone int
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

	IF @v_sens = 1 AND NOT EXISTS (SELECT 1 FROM OCCUPATION_ZONE WHERE OZO_IDZONE = @v_zne_idzone AND OZO_IDAGV = @v_iag_idagv)
		AND EXISTS (SELECT 1 FROM ZONE WHERE ZNE_ID = @v_zne_idzone)
		INSERT INTO OCCUPATION_ZONE (OZO_IDZONE, OZO_IDAGV) VALUES (@v_zne_idzone, @v_iag_idagv)
	ELSE IF @v_sens = 0
		DELETE OCCUPATION_ZONE WHERE OZO_IDZONE = @v_zne_idzone AND OZO_IDAGV = @v_iag_idagv

