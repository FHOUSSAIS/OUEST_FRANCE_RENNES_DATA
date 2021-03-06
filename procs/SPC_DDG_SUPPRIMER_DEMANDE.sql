SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
-- =============================================
-- Description:	Supprimer une demande
-- @v_idDemande	: Id de demande 
-- =============================================
CREATE PROCEDURE [dbo].[SPC_DDG_SUPPRIMER_DEMANDE]
	@v_idDemande	int
AS
BEGIN

declare @CODE_OK int = 0
declare	@CODE_KO int = 1

declare @ETAT_DMD_NOUVELLE		int = 0

declare @retour int = @CODE_OK
declare @procStock varchar(128) = OBJECT_NAME(@@PROCID)
declare @moniteur varchar(128) = 'Gestionnaire Demande Reorganisation'
declare @trace varchar(7500)

DECLARE @idEtat INT
DECLARE @libelleEtat VARCHAR(8000)

SET @trace = 'Suppression de la demande ' + ISNULL(CONVERT(VARCHAR, @v_idDemande), 'NULL')
SET @trace = @procStock + '/' + @trace
EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
							@v_log_idlog = 'DEBUG',
							@v_trace = @trace


-- Vérifcation Existance Demande
IF NOT EXISTS(SELECT 1 FROM dbo.SPC_DMD_REORGA_STOCK_GENERAL WHERE dbo.SPC_DMD_REORGA_STOCK_GENERAL.SDG_IDDEMANDE = @v_idDemande)
BEGIN
	SET @trace = 'Supprimer Demande, la demande n existe pas : ' + ISNULL(CONVERT(VARCHAR, @v_idDemande), 'NULL')
	SET @trace = @procStock + '/' + @trace
	EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
								@v_log_idlog = 'ERREUR',
								@v_trace = @trace
	SET @retour = @CODE_KO
END

-- Vérification Etat de la Demande - Interdiction de supprimer si Etat <> 3 Terminée, 12 Annulée, 13 Refusée
IF NOT EXISTS(SELECT 1 FROM dbo.SPC_DMD_REORGA_STOCK_GENERAL WHERE dbo.SPC_DMD_REORGA_STOCK_GENERAL.SDG_IDDEMANDE = @v_idDemande AND dbo.SPC_DMD_REORGA_STOCK_GENERAL.SDG_ETAT IN (3, 12, 13))
BEGIN
	SELECT
		@idEtat = dbo.SPC_DMD_REORGA_STOCK_GENERAL.SDG_ETAT,
		@libelleEtat = dbo.INT_GETLIBELLE(dbo.SPC_DMD_ETAT.SDE_IDTRADUCTION, 'fra')
	FROM dbo.SPC_DMD_REORGA_STOCK_GENERAL
	JOIN dbo.SPC_DMD_ETAT
		ON dbo.SPC_DMD_REORGA_STOCK_GENERAL.SDG_ETAT = dbo.SPC_DMD_ETAT.SDE_IDETAT
	WHERE dbo.SPC_DMD_REORGA_STOCK_GENERAL.SDG_IDDEMANDE = @v_idDemande

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
	DELETE FROM SPC_DMD_REORGA_STOCK_GENERAL
	WHERE SDG_IDDEMANDE = @v_idDemande
END

	-- tester le code erreur est inutile car pas de try/catch
	SET @retour = @@ERROR

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


RETURN @retour
END
