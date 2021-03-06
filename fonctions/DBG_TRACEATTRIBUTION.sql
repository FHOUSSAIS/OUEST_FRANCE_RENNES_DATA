SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF



-----------------------------------------------------------------------------------------
-- Fonction		: DBG_TRACEATTRIBUTION
-- Paramètre d'entrée	: 
-- Paramètre de sortie	: 
-- Descriptif		: Consultation des traces attribution
-----------------------------------------------------------------------------------------

CREATE FUNCTION [dbo].[DBG_TRACEATTRIBUTION] ()
	RETURNS TABLE
AS

	RETURN (SELECT TAT_ID, TAT_DATE, ISNULL(LIB_LIBELLE, '') TAT_LIBELLE
		FROM TRACE_ATTRIBUTION (NOLOCK), TYPE_TRACE (NOLOCK), LIBELLE (NOLOCK) WHERE TAT_TYPETRC = TTC_TYPE AND LIB_TRADUCTION = TTC_IDTRADUCTION
		AND LIB_LANGUE = (SELECT PAR_VAL FROM PARAMETRE (NOLOCK) WHERE PAR_NOM = 'LANGUE'))


