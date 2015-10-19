SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF


-----------------------------------------------------------------------------------------
-- Fonction		: DBG_TRACEENTREESORTIE
-- Paramètre d'entrée	: 
-- Paramètre de sortie	: 
-- Descriptif		: Consultation des traces entrée sortie
-----------------------------------------------------------------------------------------

CREATE FUNCTION [dbo].[DBG_TRACEENTREESORTIE] ()
	RETURNS TABLE
AS

	RETURN (SELECT TRE_ID, TRE_DATE, TRE_ENTREE_SORTIE, TRE_ETAT FROM TRACE_ENTREE_SORTIE (NOLOCK))


