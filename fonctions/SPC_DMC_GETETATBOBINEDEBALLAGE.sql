SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
-- =============================================
-- Description:	Récupère l'état de la bobine en station de déballage
-- Description:	Renvoie l'information bobine inconnue(1) ou connue(0)
-- =============================================
CREATE FUNCTION [dbo].[SPC_DMC_GETETATBOBINEDEBALLAGE]
(
	@v_idLigne INT
)
RETURNS int
AS
BEGIN
	DECLARE @val_newBobine INT
	DECLARE @simulation_demaculeuse INT = (SELECT CONVERT(INT, dbo.PARAMETRE.PAR_VAL) FROM dbo.PARAMETRE WHERE dbo.PARAMETRE.PAR_NOM = 'SPC_SIMU_DEMAC')

	SELECT
		@val_newBobine = dbo.INT_VARIABLE_AUTOMATE.VAU_VALEUR
	FROM dbo.SPC_ASSOCIATION_LIGNE_VARIABLEAUTOMATE
	JOIN dbo.INT_VARIABLE_AUTOMATE ON dbo.INT_VARIABLE_AUTOMATE.VAU_IDVARIABLEAUTOMATE = dbo.SPC_ASSOCIATION_LIGNE_VARIABLEAUTOMATE.SLV_NEWBOBINE
	WHERE dbo.SPC_ASSOCIATION_LIGNE_VARIABLEAUTOMATE.SLV_ACTION = 31
	AND dbo.SPC_ASSOCIATION_LIGNE_VARIABLEAUTOMATE.SLV_IDLIGNE = @v_idLigne
	AND ( dbo.INT_VARIABLE_AUTOMATE.VAU_QUALITE = 1 OR @simulation_demaculeuse = 1)
	
	RETURN ISNULL(@val_newBobine, 0)
	
END


