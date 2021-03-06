SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
/*=============================================
-- Description:	Menu de création d'une Demande de Rangement
			@v_idDemande : Demande à tracer
-- =============================================*/
CREATE PROCEDURE [dbo].[SPC_DRR_INSERER_TRACE]
	@v_idDemande varchar(20)
AS
BEGIN

DECLARE @CODE_OK INT = 0
DECLARE	@CODE_KO INT = 1

DECLARE @retour INT = @CODE_OK
DECLARE @procStock VARCHAR(128) = OBJECT_NAME(@@PROCID)
DECLARE @moniteur VARCHAR(128) = 'Gestionnaire Demande Appro Rack Rotative'
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

	INSERT INTO [dbo].[SPC_DMD_TRACE_APPRO_RACK_ROTATIVE] ([SRH_DATETRACE]
	, [SRH_IDDEMANDE]
	, [SRH_ROTATIVE]
	, [SRH_IDSYSTEME]
	, [SRH_IDBASE]
	, [SRH_IDSOUSBASE]
	, [SRH_LAIZE]
	, [SRH_DIAMETRE]
	, [SRH_GRAMMAGE]
	, [SRH_IDFOURNISSEUR]
	, [SRH_ETAT]
	, [SRH_DATE]
	, [SRH_PRIORITE])
		SELECT
			@dateTrace,
			SDR_IDDEMANDE,
			SDR_ROTATIVE,
			SDR_IDSYSTEME,
			SDR_IDBASE,
			SDR_IDSOUSBASE,
			SDR_LAIZE,
			SDR_DIAMETRE,
			SDR_GRAMMAGE,
			SDR_IDFOURNISSEUR,
			SDR_ETAT,
			SDR_DATE,
			SDR_PRIORITE
		FROM SPC_DMD_APPRO_RACK_ROTATIVE
		WHERE SDR_IDDEMANDE = @v_idDemande

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

