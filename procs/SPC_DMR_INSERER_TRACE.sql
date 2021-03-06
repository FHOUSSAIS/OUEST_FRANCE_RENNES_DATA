SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
/*=============================================
-- Description:	Menu de création d'une Demande de Mouvement de TRR
			@v_idDemande : Demande à tracer
-- =============================================*/
CREATE PROCEDURE [dbo].[SPC_DMR_INSERER_TRACE]
	@v_idDemande varchar(20)
AS
BEGIN

DECLARE @CODE_OK INT = 0
DECLARE	@CODE_KO INT = 1

DECLARE @retour INT = @CODE_OK
DECLARE @procStock VARCHAR(128) = OBJECT_NAME(@@PROCID)
DECLARE @moniteur VARCHAR(128) = 'Gestionnaire Demande Mouvement TRR'
DECLARE @trace VARCHAR(7500)
DECLARE @local INT = 0

DECLARE @dateTrace datetime = GETDATE()


	INSERT INTO [dbo].[SPC_DMD_TRACE_MOUVEMENT_TRR]
           ([STM_DATETRACE]
           ,[STM_IDDEMANDE]
           ,[STM_IDSYSTEME_PRISE]
           ,[STM_IDBASE_PRISE]
           ,[STM_IDSOUSBASE_PRISE]
           ,[STM_IDSYSTEME_DEPOSE]
           ,[STM_IDBASE_DEPOSE]
           ,[STM_IDSOUSBASE_DEPOSE]
           ,[STM_ETAT]
           ,[STM_DATE]
           ,[STM_PRIORITE]
		   ,[STM_IDDEMANDE_EMETTRICE])
		SELECT
			@dateTrace,
			dbo.SPC_DMD_MOUVEMENT_TRR.SDM_IDDEMANDE,
			dbo.SPC_DMD_MOUVEMENT_TRR.SDM_IDSYSTEME_PRISE,
			dbo.SPC_DMD_MOUVEMENT_TRR.SDM_IDBASE_PRISE,
			dbo.SPC_DMD_MOUVEMENT_TRR.SDM_IDSOUSBASE_PRISE,
			dbo.SPC_DMD_MOUVEMENT_TRR.SDM_IDSYSTEME_DEPOSE,
			dbo.SPC_DMD_MOUVEMENT_TRR.SDM_IDBASE_DEPOSE,
			dbo.SPC_DMD_MOUVEMENT_TRR.SDM_IDSOUSBASE_DEPOSE,
			dbo.SPC_DMD_MOUVEMENT_TRR.SDM_ETAT,
			dbo.SPC_DMD_MOUVEMENT_TRR.SDM_DATE,
			dbo.SPC_DMD_MOUVEMENT_TRR.SDM_PRIORITE,
			dbo.SPC_DMD_MOUVEMENT_TRR.SDM_IDDEMANDE_EMETTRICE
			FROM dbo.SPC_DMD_MOUVEMENT_TRR
			WHERE dbo.SPC_DMD_MOUVEMENT_TRR.SDM_IDDEMANDE = @v_idDemande

	SET @retour = @@ERROR
	
	IF(@retour <> @CODE_OK)
	BEGIN
		SET @trace = 'Erreur lors de la trace de la demande : ' + ISNULL(CONVERT(VARCHAR, @retour), 'NULL')
		SET @trace = @procStock + '/' + @trace
		EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
									@v_log_idlog = 'ERREUR',
									@v_trace = @trace
	END
	ELSE
	BEGIN
		SET @trace = 'La modification de la demande a été tracée : '
		SET @trace = @procStock + '/' + @trace
		EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
									@v_log_idlog = 'DEBUG',
									@v_trace = @trace
	END

	RETURN @retour
 	

END

