SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF


-----------------------------------------------------------------------------------------
-- Fonction		: DBG_TRACESPECIFIQUE
-- Paramètre d'entrée	: 
-- Paramètre de sortie	: 
-- Descriptif		: Consultation des traces spécifiques
-----------------------------------------------------------------------------------------

CREATE FUNCTION [dbo].[DBG_TRACESPECIFIQUE] ()
	RETURNS TABLE
AS

	RETURN (SELECT TRS_ID, TRS_DATE, TRS_MONITEUR, TRS_LOG, TRS_TRACE FROM TRACE_SPECIFIQUE (NOLOCK))

