SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON



-----------------------------------------------------------------------------------------
-- Procédure		: SPV_LOADVARIABLE
-- Paramètre d'entrée	:
-- Paramètre de sortie	: La liste des varaibles calculées
-- Descriptif		: Cette procédure est un accesseur en lecture de l'ensemble des variables
--			  calculées de règles
-----------------------------------------------------------------------------------------
-- Révisions							
-----------------------------------------------------------------------------------------
-- Date			: 03/11/2004									
-- Auteur		: S. Loiseau									
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

CREATE PROCEDURE [dbo].[SPV_LOADVARIABLE]
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

	SELECT VAR_ID, VAR_TYPE_VARIABLE, VAR_IMPLEMENTATION, VAR_PROCEDURE, VAR_PARAMETRE, LIB_LIBELLE
		FROM VARIABLE, LIBELLE WHERE VAR_TYPE = @TYPE_CALCULE
		AND LIB_TRADUCTION = VAR_IDTRADUCTIONLIBELLE AND LIB_LANGUE = (SELECT PAR_VAL FROM PARAMETRE WHERE PAR_NOM = 'LANGUE')



