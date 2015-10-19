SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF


-----------------------------------------------------------------------------------------
-- Fonction		: DBG_TRACEVARIABLEAUTOMATE
-- Paramètre d'entrée	: 
-- Paramètre de sortie	: 
-- Descriptif		: Consultation des traces variable automate
-----------------------------------------------------------------------------------------

CREATE FUNCTION [dbo].[DBG_TRACEVARIABLEAUTOMATE] ()
	RETURNS TABLE
AS

	RETURN (SELECT TRV_ID, TRV_DATE, TRV_VARIABLE_AUTOMATE, TRV_VALEUR FROM TRACE_VARIABLE_AUTOMATE (NOLOCK))


