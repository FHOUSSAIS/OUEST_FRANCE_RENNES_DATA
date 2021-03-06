SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON



-----------------------------------------------------------------------------------------
-- Procédure		: SPV_LOADCRITERE
-- Paramètre d'entrée	:
-- Paramètre de sortie	: La liste des critères calculés
-- Descriptif		: Cette procédure est un accesseur en lecture de l'ensemble des critères 
--			  calculés de l'installation
-----------------------------------------------------------------------------------------
-- Révisions							
-----------------------------------------------------------------------------------------
-- Date			: 01/11/2004									
-- Auteur		: S.Loiseau									
-- Libellé			: Création de la procédure						
-----------------------------------------------------------------------------------------
-- Date			: 07/06/2005									
-- Auteur		: S. Loiseau									
-- Libellé			: Modification de la procédure suite à la gestion du multilangue
-----------------------------------------------------------------------------------------
-- Date			: 18/06/2007
-- Auteur		: Cédric LE FRINGERE
-- Libellé			: Standardisation Logistic Core
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[SPV_LOADCRITERE]
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

-- Déclaration des constantes d'évaluation
DECLARE
	@TYPE_CALCULE tinyint

-- Définition des constantes
	SELECT @TYPE_CALCULE = 1

	SELECT CRI_IDCRITERE, CRI_IMPLEMENTATION, CRI_PROCEDURE, CRI_PARAMETRE, LIB_LIBELLE
		FROM CRITERE, LIBELLE WHERE CRI_IDTYPE = @TYPE_CALCULE
		AND LIB_TRADUCTION = CRI_IDTRADUCTIONLIBELLE AND LIB_LANGUE = (SELECT PAR_VAL FROM PARAMETRE WHERE PAR_NOM = 'LANGUE')



