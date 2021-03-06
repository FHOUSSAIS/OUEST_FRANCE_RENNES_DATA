SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF

-----------------------------------------------------------------------------------------
-- Procédure		: IHM_ENERGIE
-- Paramètre d'entrée	: 
-- Paramètre de sortie	: 
-- Descriptif		: Visualisation de l'énergie
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[IHM_ENERGIE]
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

DECLARE
	@v_monday datetime

	SET @v_monday = DATEADD(day, -((@@DATEFIRST + DATEPART(dw, GETDATE()) - 2) % 7), GETDATE())

	SELECT A.EVC_ID, CASE WHEN A.EVC_JOUR IS NULL THEN ((@@DATEFIRST + DATEPART(dw, A.EVC_DATE) - 2) % 7) + 1 ELSE A.EVC_JOUR END EVC_JOUR, A.EVC_DATE, A.EVC_HEURE, A.EVC_TYPEACT, A.EVC_AGV 
	FROM CONFIG_EVT_ENERGIE	A
	WHERE (A.EVC_JOUR IS NOT NULL AND NOT EXISTS (SELECT 1 FROM CONFIG_EVT_ENERGIE B WHERE B.EVC_AGV = A.EVC_AGV AND B.EVC_DATE IS NOT NULL AND DATEDIFF(day, @v_monday, B.EVC_DATE) > -1 AND DATEDIFF(day, @v_monday, B.EVC_DATE) < 7 AND ((@@DATEFIRST + DATEPART(dw, B.EVC_DATE) - 2) % 7) + 1 = A.EVC_JOUR))
		OR (A.EVC_DATE IS NOT NULL AND DATEDIFF(day, @v_monday, A.EVC_DATE) > -1 AND DATEDIFF(day, @v_monday, A.EVC_DATE) < 7 )
	ORDER BY A.EVC_AGV, EVC_JOUR, A.EVC_HEURE, A.EVC_DATE, A.EVC_TYPEACT

