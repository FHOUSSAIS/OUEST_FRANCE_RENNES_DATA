SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
-- =============================================
-- Description:	Supprimer une demande
-- @v_idDemande	: Id de demande 
-- =============================================
CREATE PROCEDURE [dbo].[SPC_DDD_SUPPRIMER_DEMANDE]
	@v_idDemande	int
AS
BEGIN

declare @CODE_OK int,
		@CODE_KO int
		
declare @retour      int
DECLARE @procStock VARCHAR(128) = OBJECT_NAME(@@PROCID)
DECLARE @moniteur VARCHAR(128) = 'Gestionnaire Demande Appro Demac'
DECLARE	@trace varchar(7500)

DECLARE @idEtat INT
DECLARE @libelleEtat VARCHAR(8000)

set @CODE_OK = 0
set @CODE_KO = 1

set @retour = @CODE_OK
set @procStock = 'SPC_DDD_SUPPRIMER_DEMANDE'

SET @trace = 'Suppression de la demande ' + ISNULL(CONVERT(VARCHAR, @v_idDemande), 'NULL')
SET @trace = @procStock + '/' + @trace
EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
							@v_log_idlog = 'DEBUG',
							@v_trace = @trace

-- Vérifcation Existance Demande
IF NOT EXISTS(SELECT 1 FROM dbo.SPC_DMD_APPRO_DEMAC WHERE dbo.SPC_DMD_APPRO_DEMAC.SDD_IDDEMANDE = @v_idDemande)
BEGIN
	SET @trace = 'Supprimer Demande, la demande n existe pas : ' + ISNULL(CONVERT(VARCHAR, @v_idDemande), 'NULL')
	SET @trace = @procStock + '/' + @trace
	EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
								@v_log_idlog = 'ERREUR',
								@v_trace = @trace
	SET @retour = @CODE_KO
END

-- Vérification Etat de la Demande - Interdiction de supprimer si Etat <> 3 Terminée, 12 Annulée, 13 Refusée
IF NOT EXISTS(SELECT 1 FROM dbo.SPC_DMD_APPRO_DEMAC WHERE dbo.SPC_DMD_APPRO_DEMAC.SDD_IDDEMANDE = @v_idDemande AND dbo.SPC_DMD_APPRO_DEMAC.SDD_ETAT IN (3, 12, 13))
BEGIN
	SELECT
		@idEtat = dbo.SPC_DMD_APPRO_DEMAC.SDD_ETAT,
		@libelleEtat = dbo.INT_GETLIBELLE(dbo.SPC_DMD_ETAT.SDE_IDTRADUCTION, 'fra')
	FROM dbo.SPC_DMD_APPRO_DEMAC
	JOIN dbo.SPC_DMD_ETAT
		ON dbo.SPC_DMD_APPRO_DEMAC.SDD_ETAT = dbo.SPC_DMD_ETAT.SDE_IDETAT
	WHERE dbo.SPC_DMD_APPRO_DEMAC.SDD_IDDEMANDE = @v_idDemande

	SET @trace = 'Supprimer Demande, l etat n est pas valide <>  3 Terminée, 12 Annulée, 13 Refusée : ' + ISNULL(CONVERT(VARCHAR, @v_idDemande), 'NULL')
				+ ', @idEtat = ' + ISNULL(CONVERT(VARCHAR, @idEtat), 'NULL')	
				+ ', @libelleEtat = ' + ISNULL(CONVERT(VARCHAR, @libelleEtat), 'NULL')	

	SET @trace = @procStock + '/' + @trace
	EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
								@v_log_idlog = 'ERREUR',
								@v_trace = @trace
	SET @retour = @CODE_KO
END

IF (@retour = @CODE_OK) 
BEGIN
	/*Mise à jour de la table de reorga*/
	DELETE FROM SPC_DMD_APPRO_DEMAC where SDD_IDDEMANDE = @v_idDemande
	SET @retour = @@ERROR
END

IF (@retour <> @CODE_OK) 
BEGIN
	SET @trace = 'Erreur a la suppression de la demande ' + ISNULL(CONVERT(VARCHAR, @retour), 'NULL')
	SET @trace = @procStock + '/' + @trace
	EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
								@v_log_idlog = 'ERREUR',
								@v_trace = @trace
END
ELSE
BEGIN
	SET @trace = 'la demande a été supprimée ' + ISNULL(CONVERT(VARCHAR, @retour), 'NULL')
			+ ', @v_idDemande = ' + ISNULL(CONVERT(VARCHAR, @v_idDemande), 'NULL')	
	SET @trace = @procStock + '/' + @trace
	EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
								@v_log_idlog = 'ERREUR',
								@v_trace = @trace
END

	return @retour
END

