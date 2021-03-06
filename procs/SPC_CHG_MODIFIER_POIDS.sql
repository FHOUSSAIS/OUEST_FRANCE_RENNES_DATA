SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
/*=============================================
-- Description:	Modification du poids d'une charge
			@v_idBobine = Identifiant de la bobine,
			@v_poids = poids de la charge
-- =============================================*/
create PROCEDURE [dbo].[SPC_CHG_MODIFIER_POIDS]
	@v_idBobine INT,
	@v_poids INT
AS
BEGIN

DECLARE @CODE_OK INT = 0
DECLARE	@CODE_KO INT = 1

DECLARE @retour INT = @CODE_OK
DECLARE @procStock VARCHAR(128) = OBJECT_NAME(@@PROCID)
DECLARE @moniteur VARCHAR(128) = 'Gestionnaire Charge'
DECLARE @trace VARCHAR(7500)
DECLARE @local INT = 0

SET @trace = 'Modification du poids'
			+ ' @v_idBobine  ' + ISNULL(CONVERT(VARCHAR, @v_idBobine), 'NULL')	
			+ ', @v_poids = ' + ISNULL(CONVERT(VARCHAR, @v_poids), 'NULL')
SET @trace = @procStock + '/' + @trace
EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
							@v_log_idlog = 'DEBUG',
							@v_trace = @trace

EXEC @retour = dbo.INT_SETCARACTERISTIQUECHARGE @v_chg_idcharge = @v_idBobine, @v_chg_poids = @v_poids
IF(@retour <> @CODE_OK)
BEGIN
	SET @trace = 'INT_SETCARACTERISTIQUECHARGE ' + ISNULL(CONVERT(VARCHAR, @retour), 'NULL')
			+ ' @v_chg_idcharge  ' + ISNULL(CONVERT(VARCHAR, @v_idBobine), 'NULL')	
			+ ', @v_chg_poids = ' + ISNULL(CONVERT(VARCHAR, @v_poids), 'NULL')
	SET @trace = @procStock + '/' + @trace
	EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
								@v_log_idlog = 'ERREUR',
								@v_trace = @trace
END
ELSE
BEGIN
	SET @trace = 'Modification du poids effectué'
	SET @trace = @procStock + '/' + @trace
	EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
								@v_log_idlog = 'DEBUG',
								@v_trace = @trace
END

END

