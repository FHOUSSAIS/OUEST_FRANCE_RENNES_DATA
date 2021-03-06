SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
/*=============================================
-- Description:	Création d'une trace de reorga de stock
			@v_idDemande : Demande à tracer
-- =============================================*/
CREATE PROCEDURE [dbo].[SPC_DDG_INSERER_TRACE]
	@v_idDemande varchar(20)
AS
BEGIN

DECLARE @CODE_OK INT = 0
DECLARE	@CODE_KO INT = 1

DECLARE @retour INT = @CODE_OK
DECLARE @procStock VARCHAR(128) = OBJECT_NAME(@@PROCID)
DECLARE @moniteur VARCHAR(128) = 'Gestionnaire Demande Reorganisation'
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

INSERT INTO [dbo].[SPC_DMD_TRACE_REORGA_STOCK_GENERAL]
           ([SGH_DATETRACE]
           ,[SGH_IDDEMANDE]
           ,[SGH_IDSYSTEME_PRISE]
           ,[SGH_IDBASE_PRISE]
           ,[SGH_IDSOUSBASE_PRISE]
           ,[SGH_IDSYSTEME_DEPOSE]
           ,[SGH_IDBASE_DEPOSE]
           ,[SGH_IDSOUSBASE_DEPOSE]
           ,[SGH_NBADEPLACER]
           ,[SGH_NBRESTANT]
           ,[SGH_ETAT]
           ,[SGH_DATE]
           ,[SGH_PRIORITE])
     SELECT
			@dateTrace
           ,SDG_IDDEMANDE
           ,SDG_IDSYSTEME_PRISE
           ,SDG_IDBASE_PRISE
           ,SDG_IDSOUSBASE_PRISE
           ,SDG_IDSYSTEME_DEPOSE
           ,SDG_IDBASE_DEPOSE
           ,SDG_IDSOUSBASE_DEPOSE
           ,SDG_NBADEPLACER
           ,SDG_NBRESTANT
           ,SDG_ETAT
           ,SDG_DATE
           ,SDG_PRIORITE
		FROM SPC_DMD_REORGA_STOCK_GENERAL
		WHERE SDG_IDDEMANDE = @v_idDemande

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

