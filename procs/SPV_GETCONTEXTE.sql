SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON



-----------------------------------------------------------------------------------------
-- Procédure		: SPV_GETCONTEXTE
-- Paramètre d'entrée	: @v_idAgv : Identifiant de l'AGV pour lequel on recherche un contexte
-- Paramètre de sortie	: @v_idContexte : Identifiant du contexte de règle sélectionné
-- Descriptif		: Cette procédure renvoie le contexte de règle le plus approprié pour un agv.
--			  Pour cela elle tient compte de la position de l'agv de l'adresse la plus fine.
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[SPV_GETCONTEXTE]
	@v_idAgv tinyint,
	@v_idJeu int,
	@v_idContexte int out
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

--Déclaration des variables
DECLARE
	@v_bas_type_magasin tinyint,
	@v_bas_magasin smallint,
	@v_bas_allee tinyint,
	@v_bas_couloir smallint,
	@v_bas_cote tinyint

	-- Vérification s'il existe un contexte correspondant à l'adresse fine de l'AGV
	SELECT @v_idContexte = COT_ID FROM CONTEXTE INNER JOIN INFO_AGV ON IAG_BASE_DEST = COT_BASE_BASE
		INNER JOIN COMBINAISON ON COB_IDCONTEXTE = COT_ID
		WHERE IAG_ID = @v_idAgv AND COT_BASE_SYS = (SELECT TOP 1 SYS_SYSTEME FROM SYSTEME)
		AND COB_IDJEU = @v_idJeu
	IF (@v_idContexte = 0)
	BEGIN
		-- Il n'existe pas de contexte correspondant à l'adresse fine de la position AGV
		-- Il faut désormais rechercher un contexte correspondant à une adresse globale
		
		-- Récupération de toutes les composantes de l'adresse de l'AGV
		SELECT @v_bas_type_magasin = BAS_TYPE_MAGASIN, @v_bas_magasin = BAS_MAGASIN, @v_bas_allee = BAS_ALLEE, @v_bas_couloir = BAS_COULOIR,
			@v_bas_cote = BAS_COTE FROM INFO_AGV INNER JOIN BASE ON IAG_BASE_DEST = BAS_BASE
			WHERE IAG_ID = @v_idAgv AND (BAS_SYSTEME = (SELECT TOP 1 SYS_SYSTEME FROM SYSTEME))

		SELECT TOP 1 @v_idContexte = COT_ID FROM CONTEXTE INNER JOIN BASE ON BAS_SYSTEME = COT_BASE_SYS AND BAS_BASE = COT_BASE_BASE
			INNER JOIN COMBINAISON ON COB_IDCONTEXTE = COT_ID
			WHERE COT_BASE_SYS = (SELECT TOP 1 SYS_SYSTEME FROM SYSTEME) AND COB_IDJEU = @v_idJeu
			AND BAS_TYPE = 0 AND BAS_TYPE_MAGASIN = @v_bas_type_magasin AND (BAS_MAGASIN = @v_bas_magasin OR BAS_MAGASIN = 0)
			AND (BAS_ALLEE = @v_bas_allee OR BAS_ALLEE = 0) AND (BAS_COULOIR = @v_bas_couloir OR BAS_COULOIR = 0) AND (BAS_COTE = @v_bas_cote OR BAS_COTE = 0)
			ORDER BY BAS_ALLEE DESC, BAS_COULOIR DESC, BAS_COTE DESC
	END
	
	SET @v_idContexte = ISNULL(@v_idContexte, 0)
