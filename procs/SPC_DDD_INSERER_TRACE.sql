SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
/*=============================================
-- Description:	Création d'une trace d'appro démac
			@v_idDemande : Demande à tracer
-- =============================================*/
CREATE PROCEDURE [dbo].[SPC_DDD_INSERER_TRACE]
	@v_idDemande varchar(20)
AS
BEGIN

DECLARE @CODE_OK INT = 0
DECLARE	@CODE_KO INT = 1

DECLARE @retour INT = @CODE_OK
DECLARE @procStock VARCHAR(128) = OBJECT_NAME(@@PROCID)
DECLARE @moniteur VARCHAR(128) = 'Gestionnaire Demande Appro Demac'
DECLARE @trace VARCHAR(7500)
DECLARE @local INT = 0

DECLARE @dmd_idDemande varchar(20)
DECLARE @dmd_rotative int
DECLARE @dmd_idSysteme bigint
DECLARE @dmd_idBase bigint
DECLARE @dmd_idSousBase bigint
DECLARE @dmd_laize int
DECLARE @dmd_diametre int
DECLARE @dmd_grammage numeric(4,2)
DECLARE @dmd_idFournisseur int
DECLARE @dmd_priorite int
DECLARE @dateTrace datetime = GETDATE()

	INSERT INTO [dbo].[SPC_DMD_TRACE_APPRO_DEMAC]
           ([SDH_DATETRACE]
           ,[SDH_IDDEMANDE]
           ,[SDH_ROTATIVE]
           ,[SDH_LAIZE]
           ,[SDH_DIAMETRE]
           ,[SDH_GRAMMAGE]
           ,[SDH_IDFOURNISSEUR]
           ,[SDH_ETAT]
           ,[SDH_IDBOBINE]
           ,[SDH_DATE]
           ,[SDH_PRIORITE]
           ,[SDH_IDDEMANDE_EMETTRICE])
     SELECT
           @dateTrace
           ,SDD_IDDEMANDE
           ,SDD_ROTATIVE
           ,SDD_LAIZE
           ,SDD_DIAMETRE
           ,SDD_GRAMMAGE
           ,SDD_IDFOURNISSEUR
           ,SDD_ETAT
           ,SDD_IDBOBINE
           ,SDD_DATE
           ,SDD_PRIORITE
           ,SDD_IDDEMANDE_EMETTRICE
		FROM SPC_DMD_APPRO_DEMAC
		WHERE SDD_IDDEMANDE = @v_idDemande

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

