SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF


-----------------------------------------------------------------------------------------
-- Fonction		: DBG_TRACEZONE
-- Paramètre d'entrée	: 
-- Paramètre de sortie	: 
-- Descriptif		: Consultation des traces zone
-----------------------------------------------------------------------------------------
-- Révisions	
-----------------------------------------------------------------------------------------
-- Date			: 18/06/2007
-- Auteur		: Cédric LE FRINGERE
-- Libellé			: Création de la procédure
-----------------------------------------------------------------------------------------

CREATE FUNCTION [dbo].[DBG_TRACEZONE] ()
	RETURNS TABLE
AS

	RETURN (SELECT TRZ_ID, TRZ_DATE, ISNULL(LIB_LIBELLE, '') TRZ_LIBELLE, TRZ_DSCTRC, TRZ_IDZONE
		FROM TRACE_ZONE (NOLOCK), TYPE_TRACE (NOLOCK), LIBELLE (NOLOCK) WHERE TRZ_TYPETRC = TTC_TYPE  AND LIB_TRADUCTION = TTC_IDTRADUCTION
		AND LIB_LANGUE = (SELECT PAR_VAL FROM PARAMETRE (NOLOCK) WHERE PAR_NOM = 'LANGUE'))


