SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
/*=============================================
-- Description:	Modification du poids d'une charge
			@v_idBobine = Identifiant de la bobine,
			@v_poidsNet = poids Réel de la charge
-- =============================================*/
CREATE PROCEDURE [dbo].[SPC_CHG_MODIFIER_POIDS_NET]
	@v_idBobine INT,
	@v_poidsNet INT
AS
BEGIN

DECLARE @CODE_OK INT = 0
DECLARE	@CODE_KO INT = 1

DECLARE @retour INT = @CODE_OK
DECLARE @procStock VARCHAR(128) = OBJECT_NAME(@@PROCID)
DECLARE @moniteur VARCHAR(128) = 'Gestionnaire Charge'
DECLARE @trace VARCHAR(7500)
DECLARE @local INT = 0

SET @trace = 'Modification du poids net'  
			+ ' @v_idBobine  ' + ISNULL(CONVERT(VARCHAR, @v_idBobine), 'NULL')	
			+ ', @v_poidsNet = ' + ISNULL(CONVERT(VARCHAR, @v_poidsNet), 'NULL')
SET @trace = @procStock + '/' + @trace
EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
							@v_log_idlog = 'DEBUG',
							@v_trace = @trace

UPDATE dbo.SPC_CHARGE_BOBINE
SET SCB_POIDS_NET = @v_poidsNet
WHERE dbo.SPC_CHARGE_BOBINE.SCB_IDCHARGE = @v_idBobine
SET @retour = @@error

IF(@retour <> @CODE_OK)
BEGIN
	SET @trace = 'UPDATE dbo.SPC_CHARGE_BOBINE ' + ISNULL(CONVERT(VARCHAR, @retour), 'NULL')
			+ ' SCB_IDCHARGE  ' + ISNULL(CONVERT(VARCHAR, @v_idBobine), 'NULL')	
			+ ', SCB_POIDS_NET = ' + ISNULL(CONVERT(VARCHAR, @v_poidsNet), 'NULL')
	SET @trace = @procStock + '/' + @trace
	EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
								@v_log_idlog = 'ERREUR',
								@v_trace = @trace
END
ELSE
BEGIN
	SET @trace = 'Modification du poids net effectué'
	SET @trace = @procStock + '/' + @trace
	EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
								@v_log_idlog = 'DEBUG',
								@v_trace = @trace
END

IF(@retour = @CODE_OK)
BEGIN
	exec @retour = dbo.SPC_CHG_MODIFIER_POIDS @v_idBobine = @v_idBobine, @v_poids = @v_poidsNet
	IF(@retour <> @CODE_OK)
	BEGIN
		SET @trace = 'SPC_CHG_MODIFIER_POIDS ' + ISNULL(CONVERT(VARCHAR, @retour), 'NULL')
				+ ' @v_idBobine  ' + ISNULL(CONVERT(VARCHAR, @v_idBobine), 'NULL')	
				+ ', @v_poids = ' + ISNULL(CONVERT(VARCHAR, @v_poidsNet), 'NULL')
		SET @trace = @procStock + '/' + @trace
		EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
									@v_log_idlog = 'ERREUR',
									@v_trace = @trace
	END
END

END

