SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
/*=============================================
-- Description:	Traitement de l'évènement Horloge
			@v_emetteurInterne = Emetteur Interne
			@v_emetteurExterne = Emetteur Externe
			@v_intervalle	   = Intervalle de l'horloge
-- =============================================*/
CREATE PROCEDURE [dbo].[SPC_DRR_EVT_HORLOGE]
	@v_emetteurInterne INT,
	@v_emetteurExterne INT,
	@v_intervalle INT
AS
BEGIN

DECLARE @CODE_OK INT = 0
DECLARE	@CODE_KO INT = 1

DECLARE @retour INT = @CODE_OK
DECLARE @procStock VARCHAR(128) = OBJECT_NAME(@@PROCID)
DECLARE @moniteur VARCHAR(128) = 'Gestionnaire Demande Appro Rack Rotative'
DECLARE @trace VARCHAR(7500)
DECLARE @local INT = 0

	IF(@v_emetteurInterne = -8)
	BEGIN
		-- Gestion des Demandes
		EXEC @retour = dbo.SPC_DRR_GESTION

		IF(@retour <> @CODE_OK)
		BEGIN
			SET @trace = 'Erreur dans la gestion des demande Appro Rack Rotative : '
								+ ', @v_idDemande:' + ISNULL(CONVERT(VARCHAR, @retour), 'NULL')
			SET @trace = @procStock + '/' + @trace
			EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
										@v_log_idlog = 'ERREUR',
										@v_trace = @trace
		END	
	END
	RETURN @retour
 	

END

