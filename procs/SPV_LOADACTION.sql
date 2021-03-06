SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER OFF




-----------------------------------------------------------------------------------------
-- Procédure		: SPV_LOADACTION
-- Paramètre d'entrée	:
-- Paramètre de sortie	: La liste des actions
-- Descriptif		: Cette procédure est un accesseur en lecture de la liste des actions
--			  de l'installation
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

CREATE PROCEDURE [dbo].[SPV_LOADACTION]
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

	SELECT ARE_IDACTION, ARE_IDTYPE, ARE_IMPLEMENTATION, ARE_PROCEDURE, ARE_PARAMS, LIB_LIBELLE
		FROM ACTION_REGLE, LIBELLE
		WHERE LIB_TRADUCTION = ARE_IDTRADUCTIONLIBELLE AND LIB_LANGUE = (SELECT PAR_VAL FROM PARAMETRE WHERE PAR_NOM = 'LANGUE')



