SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON



-----------------------------------------------------------------------------------------
-- Procédure		: SPV_LOADREGLE
-- Paramètre d'entrée	:
-- Paramètre de sortie	: La liste des règles
-- Descriptif		: Cette procédure est un accesseur en lecture de l'ensemble des règles 
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

CREATE PROCEDURE [dbo].[SPV_LOADREGLE]
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

select REG_IdRegle,REG_IdType,LIB_Libelle,REG_Params,REG_Famille
from REGLE
join TRADUCTION on (REG_IdTraductionLibelle = TRA_Id) 
join LIBELLE on (LIB_Traduction = TRA_Id) and (LIB_Langue='FRA')






