SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF










-----------------------------------------------------------------------------------------
-- Procedure		: SPV_REVEILLEAGV
-- Paramètre d'entrée	: @v_cyclique : Réveille cyclique ou non
--			  @v_agv : Liste d'identifiants AGVs séparés par des virgules
--			  (une valeur nulle indique l'ensemble des AGVs)
-- Paramètre de sortie	: 
-- Descriptif		: Réveille des AGVs
-----------------------------------------------------------------------------------------
-- Révision									
-----------------------------------------------------------------------------------------
-- Date			: 07/09/2007
-- Auteur		: Cédric LE FRINGERE
-- Libellé			: Création de la procédure
-----------------------------------------------------------------------------------------
-- Date			: 01/10/2008
-- Auteur		: Cédric LE FRINGERE
-- Libellé			: Prise en compte des ordres stoppés
-----------------------------------------------------------------------------------------
-- Date			: 01/10/2008
-- Auteur		: Cédric LE FRINGERE
-- Libellé			: Fusion avec SPV_CHECKLISTAGVAREVEILLER
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[SPV_REVEILLEAGV]
	@v_cyclique bit = 0,
	@v_agv varchar(8000) = NULL
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

-- Déclaration des variables
DECLARE
	@v_sql varchar(8000),
	@v_par_valeur varchar(128)

-- Déclaration des constantes d'états et descriptions
DECLARE
	@ETAT_ENATTENTE tinyint,
	@ETAT_ENCOURS tinyint,
	@ETAT_STOPPE tinyint,
	@DESC_ENVOYE tinyint

-- Définition des constantes
	SET @ETAT_ENATTENTE = 1
	SET @ETAT_ENCOURS = 2
	SET @ETAT_STOPPE = 3
	SET @DESC_ENVOYE = 13

	SET @v_sql = 'SELECT IAG_ID FROM INFO_AGV WHERE IAG_MISSIONNABLE = ''O'''
		+ ' AND IAG_MODE = 1 AND NOT EXISTS (SELECT 1 FROM ORDRE_AGV WHERE ORD_IDAGV = IAG_ID AND ((ORD_IDETAT = ' + CONVERT(varchar, @ETAT_ENATTENTE) + ' AND ORD_DSCETAT = ' + CONVERT(varchar, @DESC_ENVOYE) + ')'
		+ ' OR (ORD_IDETAT IN (' + CONVERT(varchar, @ETAT_ENCOURS) + ',' + CONVERT(varchar, @ETAT_STOPPE) + '))))'
	IF @v_cyclique = 1
	BEGIN
		-- Récupération du délai du réveil des AGVs
		SELECT @v_par_valeur = PAR_VAL FROM PARAMETRE WHERE PAR_NOM = 'REVEIL'
		SET @v_sql = @v_sql + ' AND DATEDIFF(second, IAG_HORODATE_ATTRIBUTION, GETDATE()) > ISNULL(' + @v_par_valeur + ', 10)'
	END
	ELSE
	BEGIN
		IF @v_agv IS NOT NULL
			SET @v_sql = @v_sql + ' AND IAG_ID IN ('+ @v_agv +')'
	END
	EXEC (@v_sql)

