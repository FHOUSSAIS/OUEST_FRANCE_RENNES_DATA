SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
-- =============================================
-- Description:	Supprimer les Demandes mouvement TRR
-- @v_idDemande	: Id de demande 
-- =============================================
CREATE PROCEDURE [dbo].[SPC_DMR_SUPPRIMER_DEMANDE]
	@v_idDemande	VARCHAR(20)
AS
BEGIN

DECLARE @CODE_OK INT = 0
DECLARE	@CODE_KO INT = 1

DECLARE @ETAT_DMD_NOUVELLE		INT = 0
DECLARE @ETAT_DMD_EN_ATTENTE	INT = 1
DECLARE @ETAT_DMD_EN_COURS		INT = 2
DECLARE @ETAT_DMD_TERMINEE		INT = 3
DECLARE @ETAT_DMD_SUSPENDUE		INT = 11
DECLARE @ETAT_DMD_ANNULEE		INT = 12

DECLARE @retour INT = @CODE_OK
DECLARE @procStock VARCHAR(128) = OBJECT_NAME(@@PROCID)
DECLARE @moniteur VARCHAR(128) = 'Gestionnaire Demande Mouvement TRR'
DECLARE @trace VARCHAR(7500)
DECLARE @local INT = 0

DECLARE @idEtat INT
DECLARE @libelleEtat VARCHAR(8000)

SET @trace = 'Suppression de la demande ' + ISNULL(CONVERT(VARCHAR, @v_idDemande), 'NULL')
SET @trace = @procStock + '/' + @trace
EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
							@v_log_idlog = 'DEBUG',
							@v_trace = @trace

-- Vérification Données d'entrée
-- Vérifcation Existance Demande
IF NOT EXISTS(SELECT 1 FROM dbo.SPC_DMD_MOUVEMENT_TRR WHERE dbo.SPC_DMD_MOUVEMENT_TRR.SDM_IDDEMANDE = @v_idDemande)
BEGIN
	SET @trace = 'Supprimer Demande, la demande n existe pas : ' + ISNULL(CONVERT(VARCHAR, @v_idDemande), 'NULL')
	SET @trace = @procStock + '/' + @trace
	EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
								@v_log_idlog = 'ERREUR',
								@v_trace = @trace
	SET @retour = @CODE_KO
END

SELECT
	@idEtat = dbo.SPC_DMD_MOUVEMENT_TRR.SDM_ETAT,
	@libelleEtat = dbo.INT_GETLIBELLE(dbo.SPC_DMD_ETAT.SDE_IDTRADUCTION, 'fra')
FROM dbo.SPC_DMD_MOUVEMENT_TRR
JOIN dbo.SPC_DMD_ETAT
	ON dbo.SPC_DMD_MOUVEMENT_TRR.SDM_ETAT = dbo.SPC_DMD_ETAT.SDE_IDETAT
WHERE dbo.SPC_DMD_MOUVEMENT_TRR.SDM_IDDEMANDE = @v_idDemande

-- Vérification Etat de la Demande - Interdiction de supprimer si Etat <> 3 Terminée, 12 Annulée, 13 Refusée
IF NOT EXISTS(SELECT 1 FROM dbo.SPC_DMD_MOUVEMENT_TRR WHERE dbo.SPC_DMD_MOUVEMENT_TRR.SDM_IDDEMANDE = @v_idDemande AND dbo.SPC_DMD_MOUVEMENT_TRR.SDM_ETAT IN (3, 12, 13))
BEGIN
	SET @trace = 'Supprimer Demande, l etat n est pas valide <>  3 Terminée, 12 Annulée, 13 Refusée : ' + ISNULL(CONVERT(VARCHAR, @v_idDemande), 'NULL')
				+ ', @idEtat = ' + ISNULL(CONVERT(VARCHAR, @idEtat), 'NULL')	
				+ ', @libelleEtat = ' + ISNULL(CONVERT(VARCHAR, @libelleEtat), 'NULL')	

	SET @trace = @procStock + '/' + @trace
	EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
								@v_log_idlog = 'ERREUR',
								@v_trace = @trace
	SET @retour = @CODE_KO
END

IF(@retour = @CODE_OK)
BEGIN
	DELETE FROM dbo.SPC_DMD_MOUVEMENT_TRR
	WHERE dbo.SPC_DMD_MOUVEMENT_TRR.SDM_IDDEMANDE = @v_idDemande

	-- tester le code erreur est inutile car pas de try/catch
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
			+ ', @idEtat = ' + ISNULL(CONVERT(VARCHAR, @idEtat), 'NULL')	
			+ ', @libelleEtat = ' + ISNULL(CONVERT(VARCHAR, @libelleEtat), 'NULL')
	SET @trace = @procStock + '/' + @trace
	EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
								@v_log_idlog = 'DEBUG',
								@v_trace = @trace
END

RETURN @retour
END
